# 网络查询结果（TASK-003 重构 deploy-check-env.ps1 / .sh 环境可用性检查与运行状态检测）

## 0. 查询结论摘要

本任务重构 `deploy/scripts/deploy-check-env.ps1` / `.sh`，需要查询并核对的官方资料包括：JDK 21 版本检测命令、MariaDB `SELECT 1` 健康检查、Redis `redis-cli ping` PONG、Nacos 2.x 健康检查接口与 startup 脚本、PowerShell/Bash 进程与 TCP 端口检测方法、口令掩码处理最佳实践。经查询 Redis 官方文档（redis.io / redis/docs）、Nacos 官方文档（nacos.io / alibaba/nacos）、MariaDB 官方文档（mariadb.com）、MySQL 官方参考手册（dev.mysql.com）、Oracle JDK 21 官方文档、Microsoft Learn PowerShell 文档及 nixCraft/Stack Overflow 等权威资料，确认：

- **全部检测手段均有官方依据且与项目版本（JDK 21 / MariaDB 10.6 / Redis 7.2 / Nacos 2.3）兼容**；
- **口令掩码存在官方推荐做法**：Redis 官方明确推荐用 `REDISCLI_AUTH` 环境变量而非 `-a` 参数；MySQL 官方明确警告命令行传口令不安全（MYSQL_PWD 已废弃不推荐）；部署脚本应在日志中掩码显示、避免 eval 拼接；
- **Nacos 健康检查接口有版本差异**：`/nacos/v2/core/cluster/node/self/health`（2.x 官方 OpenAPI，返回 UP）与 `/nacos/` 控制台页面 HTML（含 "Nacos"）；issue-list 已指出 `/nacos/v1/console/health/readiness` 在 2.3 部分 404，本任务以 PRD/任务定义为准使用 `http://NACOS_ADDR/nacos/` 含 "Nacos" 判定，两种方式均应识别"运行中"；
- **PowerShell 5.1 / Bash 进程、服务、TCP 端口检测均有成熟命令**，需注意 Windows PowerShell 5.1 与 PowerShell 7 的 `CommandLine` 属性差异。

---

## 1. 查询范围与资料来源（版本核对）

| 主题 | 权威来源 | 关键版本/兼容性结论 |
| --- | --- | --- |
| JDK 21 版本检测 | Oracle JDK 21 官方文档（docs.oracle.com/en/java/javase/21）、OpenJDK 项目页 | JDK 21 GA 于 2023-09-19；`java -version` 首行含 `version "21`（OpenJDK 为 `openjdk version "21`）；版本字符串格式符合 JEP 223（$FEATURE.$INTERIM.$UPDATE） |
| MariaDB `SELECT 1` | MariaDB 官方文档（mariadb.com）、runebook MariaDB healthcheck、Debian manpages mysqladmin(1)（mariadb-client-10.6） | MariaDB 10.6 提供 `mariadb`/`mariadb-admin`（mysql/mysqladmin 为兼容符号链接）；`mysqladmin ping` 退出码 0=服务存活（**注意：Access denied 也返回 0**，因服务在运行）；`mysql -N -B -e "SELECT 1"` 可验证连接 |
| Redis `redis-cli ping` | Redis 官方文档（redis.io/docs/latest/develop/tools/cli）、redis/docs GitHub | `redis-cli -h host -p port PING` 返回 `PONG`；口令认证推荐 `REDISCLI_AUTH` 环境变量（官方原文：For security reasons, provide the password to redis-cli automatically via the REDISCLI_AUTH environment variable） |
| Nacos 2.x 健康检查 | Nacos 官方 OpenAPI 指南（nacos.io/docs/latest/open-api）、alibaba/nacos README、阿里云 SAE 文档 | Nacos 2.x 兼容 1.x OpenAPI；`/nacos/v2/core/cluster/node/self/health` 返回 `{"code":0,"data":"UP"}`；启动脚本 `startup.cmd -m standalone`（Windows）/ `sh startup.sh -m standalone`（Linux）；默认集群模式需显式 `-m standalone` |
| PowerShell 进程/服务/端口 | Microsoft Learn（Get-Service / Get-Process / Test-NetConnection / Get-CimInstance） | Get-Service 仅 Windows；Test-NetConnection 自 PowerShell 4.0 / Windows 8 提供；`Get-CimInstance Win32_Process` 取 CommandLine 需管理员权限（Windows PowerShell 5.1 无 Get-Process 的 CommandLine 属性，PS 7.1+ 才有） |
| Bash 进程/服务/端口 | nixCraft（cyberciti.biz）、Stack Overflow、man7.org | `pgrep -x` / `pidof` / `ps -C` 检测进程；`systemctl is-active` 检测 systemd 服务；`timeout 1 bash -c "</dev/tcp/HOST/PORT"` 或 `nc -vz` 检测 TCP 端口 |
| 口令掩码最佳实践 | Redis 官方文档、MySQL 官方参考手册（环境变量表）、unix.stackexchange | Redis 用 REDISCLI_AUTH 环境变量；MySQL 官方不推荐 MYSQL_PWD（8.0 起标记废弃、ps 可泄露环境）；命令行 `-p密码` 会在 Linux /proc 中暴露；部署脚本应避免 eval 拼接、日志掩码 `****` |

---

## 2. JDK 21 版本检测（F-002）

### 2.1 `java -version` 输出格式（官方）

- **Oracle JDK**：`java version "21.0.1" 2023-10-17 ...`
- **OpenJDK / Temurin / 各家发行版**：`openjdk version "21.0.1" 2023-10-17 ...`
- 任务要求匹配 `version "21` 或 `openjdk version "21` 即可（**注意引号是输出的一部分**，正则需匹配 `version "21`）。

```bash
# Bash 检测示例（2>&1 合并 stderr，java -version 输出到 stderr）
java -version 2>&1 | grep -E 'version "21'
```

```powershell
# PowerShell 检测示例
$javaVer = & java -version 2>&1 | Out-String
$javaVer -match 'version "21'
```

### 2.2 JAVA_HOME 判定

- 官方安装指南（JDK Installation Guide, Release 21）要求设置 `JAVA_HOME` 指向 JDK 安装根目录并加入 `PATH`。
- 判定方式：
  - Bash：`test -n "$JAVA_HOME" && test -d "$JAVA_HOME"`（目录有效且非空）
  - PowerShell：`$env:JAVA_HOME` 非空且 `Test-Path $env:JAVA_HOME`

### 2.3 版本兼容性结论

项目后端使用 **JDK 21**（Spring Boot 3.2.5 / Spring Cloud 2023.0.1 均要求 JDK 17+，21 完全兼容）。检测匹配 `version "21` 与本任务目标一致。

---

## 3. MariaDB `SELECT 1` 健康检查（F-003）

### 3.1 命令选择（MariaDB 10.6）

- MariaDB 10.6 客户端提供 `mariadb`（等价 `mysql`）与 `mariadb-admin`（等价 `mysqladmin`）。检测命令时应同时探测 `mariadb` 与 `mysql`（兼容 MySQL 安装）。
- `mysqladmin ping`（mariadb-admin ping）：**退出码 0 = 服务存活**；官方 manpage 明确：「return status from mysqladmin is 0 if the server is running, 1 if it is not. This is 0 even in case of an error such as Access denied」——即即使认证失败也返回 0，因为服务在运行。**注意**：本任务已通过 env.json 提供 DB_USERNAME/DB_PASSWORD，应使用带凭据的 `SELECT 1` 验证真实连通性，而非裸 `mysqladmin ping`（Access denied 会被误判为通过）。

### 3.2 `SELECT 1` 命令示例

```bash
# Bash：-N 无列名、-B 批处理模式、-e 执行语句；$DB_PASSWORD 通过数组参数传入避免注入
cmd=(mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -N -B -e "SELECT 1")
if "${cmd[@]}" >/dev/null 2>&1; then
  echo "通过"
fi
```

```powershell
# PowerShell：& 调用命令
$out = & mariadb -h $env:DB_HOST -P $env:DB_PORT -u $env:DB_USERNAME -p"$env:DB_PASSWORD" -N -B -e "SELECT 1" 2>&1
if ($LASTEXITCODE -eq 0) { "通过" }
```

### 3.3 版本兼容性结论

项目数据库为 **MariaDB 10.6**，`mariadb`/`mysql` 命令行 `SELECT 1` 健康检查在 10.6 上完全兼容。`mysqladmin ping` 可作为安装检测补充，但连通性判定以 `SELECT 1` 为准。

---

## 4. Redis `redis-cli ping`（F-004）

### 4.1 官方用法（Redis 官方文档）

```bash
# 无口令
redis-cli -h redis15.localnet.org -p 6390 PING   # 返回 PONG

# 带口令（-a 参数，官方不推荐显式传参）
redis-cli -a myUnguessablePazzzzzword123 PING    # 返回 PONG
```

### 4.2 口令安全（官方推荐）

Redis 官方文档原文：**「For security reasons, provide the password to redis-cli automatically via the `REDISCLI_AUTH` environment variable.」**

```bash
export REDISCLI_AUTH="$REDIS_PASSWORD"
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" PING
```

> 本项目 `deploy-check-env.sh` 重构时应优先使用 `REDISCLI_AUTH` 环境变量方式（Bash 中 export 后子进程继承，日志不打印明文）；若环境不支持再用 `-a` 且日志掩码。PowerShell 中可用 `$env:REDISCLI_AUTH = $env:REDIS_PASSWORD` 后调用。

### 4.3 版本兼容性结论

项目 Redis 为 **7.2.x**，`redis-cli ping` 返回 `PONG` 及 `REDISCLI_AUTH` 机制均兼容（该机制自 redis-cli 6.2 起可用）。

---

## 5. Nacos 2.x 健康检查与 startup 脚本（F-005/F-006）

### 5.1 健康检查接口（2.x 官方 OpenAPI）

| 接口 | 返回 | 说明 |
| --- | --- | --- |
| `GET /nacos/v2/core/cluster/node/self/health` | `{"code":0,"data":"UP"}` | 2.x 官方节点健康接口，data 为 UP/STARTING/DOWN 等 |
| `GET /nacos/`（控制台页面） | HTML 含 "Nacos" | 任务定义/PRD 指定的探测方式（响应含 "Nacos" 视为连通） |
| `GET /nacos/v1/console/health/readiness` | 2.3 部分版本 404 | issue-list P7-11 建议项，**2.3 兼容性不稳定，不采用** |

### 5.2 本任务采用方案（以 PRD/任务定义为准）

- 可用性/运行状态探测统一使用 **`http://NACOS_ADDR/nacos/` 响应内容含 "Nacos"** 判定（cs.md G2 明确：任务定义/PRD 要求，两种方式均应识别"运行中"）；
- 若 `NACOS_ADDR` 为 `127.0.0.1:8848`，则探测 URL 为 `http://127.0.0.1:8848/nacos/`；
- 补充方案：`curl -s http://$NACOS_ADDR/nacos/v2/core/cluster/node/self/health` 返回 `"data":"UP"` 亦可作辅助识别（2.x 官方接口，与 PRD 不冲突时可用）。

### 5.3 startup 脚本（安装检测依据）

- **Windows**：`NACOS_HOME\bin\startup.cmd` 存在；启动命令 `startup.cmd -m standalone`（官方 README）；
- **Linux**：`NACOS_HOME/bin/startup.sh` 存在；启动命令 `sh startup.sh -m standalone`；
- **重要**：Nacos 默认以集群模式启动，单机部署必须加 `-m standalone`（阿里云 SAE 官方文档确认：直接双击 startup.cmd 会因默认集群模式启动失败）；
- Nacos 需 **JDK 1.8+** 并正确配置 `JAVA_HOME`（本项目 JDK 21 满足）。

### 5.4 版本兼容性结论

项目 Nacos 为 **2.3**。`/nacos/` 控制台页面 HTML 含 "Nacos" 在 2.x 全版本可用（控制台默认开启）；`/nacos/v2/core/cluster/node/self/health` 为 2.2.0+ 官方接口（本任务 PRD 未要求，可选辅助）。`bin/startup.cmd`/`bin/startup.sh` 结构在 2.x 稳定。

---

## 6. PowerShell 进程/服务/TCP 端口检测（F-006 .ps1 版）

### 6.1 进程检测

```powershell
# 进程存在（-ErrorAction SilentlyContinue 避免未找到报错）
if (Get-Process -Name "mysqld" -ErrorAction SilentlyContinue) { "运行中" }

# 按进程名列表（逗号分隔转数组后逐个判断）
$procs = ($env:DB_PROCESS_NAME -split '\s*,\s*')
foreach ($p in $procs) { if (Get-Process -Name $p -ErrorAction SilentlyContinue) { return $true } }
```

### 6.2 服务检测

```powershell
$svc = Get-Service -Name "MySQL" -ErrorAction SilentlyContinue
if ($svc -and $svc.Status -eq 'Running') { "运行中" }
```

> Get-Service 官方文档确认仅 Windows 平台可用；Windows PowerShell 5.1 内置。

### 6.3 TCP 端口检测

```powershell
# 方法一：Test-NetConnection（PowerShell 4.0+，Windows 8/Server 2012 R2+）
$tnc = Test-NetConnection -ComputerName "127.0.0.1" -Port 3306 -WarningAction SilentlyContinue
if ($tnc.TcpTestSucceeded) { "端口可达" }

# 方法二：TcpClient（更轻量，超时可控，推荐用于脚本）
function Test-TcpPort {
  param([string]$HostName, [int]$Port, [int]$TimeoutMs = 1000)
  $client = New-Object System.Net.Sockets.TcpClient
  try {
    $iar = $client.BeginConnect($HostName, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) { return $false }
    $client.EndConnect($iar); return $true
  } catch { return $false }
  finally { $client.Dispose() }
}
```

### 6.4 Nacos java 进程辅助判断（F-006）

```powershell
# 检测 java.exe 进程命令行含 nacos（Windows PowerShell 5.1 用 CIM）
$nacosProc = Get-CimInstance Win32_Process -Filter "Name = 'java.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -match 'nacos' }
if ($nacosProc) { "运行中（java 进程含 nacos）" }
```

> 注意：`Get-CimInstance Win32_Process` 读取 CommandLine 需要管理员权限（Stack Overflow 权威确认）；非管理员时该属性可能为 $null，因此 Nacos 判定**以 HTTP 探测为主、java 进程为辅助**。PowerShell 7.1+ 才支持 `Get-Process` 的 CommandLine 属性（Windows PowerShell 5.1 无），本项目脚本运行在 5.1 时应使用 CIM。

---

## 7. Bash 进程/服务/TCP 端口检测（F-006 .sh 版）

### 7.1 进程检测

```bash
# pgrep 按精确名（-x）
if pgrep -x "mysqld" >/dev/null 2>&1; then echo "运行中"; fi

# 多进程名循环
IFS=',' read -ra PROCS <<< "$DB_PROCESS_NAME"
for p in "${PROCS[@]}"; do
  p=$(echo "$p" | xargs)  # 去空格
  if pgrep -x "$p" >/dev/null 2>&1; then RUNNING=1; break; fi
done
```

### 7.2 服务检测（systemd）

```bash
# systemctl is-active 返回 "active" 时为运行中
if [ "$(systemctl is-active "$svc" 2>/dev/null)" = "active" ]; then echo "运行中"; fi
```

> 也可用 `systemctl status` 判断；nixCraft 确认 `systemctl` 是现代 systemd 发行版最可靠方式。非 systemd 环境可降级 `service $svc status` 或跳过服务检测只靠进程/端口。

### 7.3 TCP 端口检测（bash 内置 /dev/tcp，推荐）

```bash
# 内置 /dev/tcp，无需额外工具；timeout 防止长时间挂起
if timeout 1 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null; then
  echo "端口可达"
else
  echo "端口不可达"
fi
```

> Stack Overflow 权威方案：`(echo >/dev/tcp/localhost/3306) &>/dev/null && echo open || echo closed`。注意 `${HOST}`/`${PORT}` 必须带花括号（`$HOST` 在 bash 中是特殊变量）。备选 `nc -vz -w5 $HOST $PORT`（需安装 nc）。

### 7.4 Nacos java 进程辅助判断

```bash
if pgrep -f "nacos" >/dev/null 2>&1; then echo "运行中（java 进程含 nacos）"; fi
```

> `pgrep -f` 匹配完整命令行（含 jar 路径 / nacos 关键字），用于 Nacos HTTP 探测失败的辅助判断。

---

## 8. 口令掩码处理最佳实践（F-003/F-004/P7-10）

### 8.1 官方依据

| 场景 | 官方/权威建议 | 来源 |
| --- | --- | --- |
| Redis 口令 | **使用 `REDISCLI_AUTH` 环境变量**，而非 `-a` 参数 | Redis 官方文档（redis.io/docs/latest/develop/tools/cli） |
| MySQL/MariaDB 口令 | **不要放在命令行**（Linux /proc 可被读取）；`MYSQL_PWD` 官方标记「极其不安全」且 8.0 起废弃，**不推荐** | MySQL 官方参考手册、unix.stackexchange |
| Bash 命令拼接 | 避免 `eval "$cmd"`（注入/引号风险，`set -x` 调试泄露口令）；改用**数组参数** `cmd=(...); "${cmd[@]}"` | cs.md P5/P7-10 问题定位 + Stack Overflow 通用实践 |
| 日志输出 | 口令一律掩码显示 `****`，不打印 DB_PASSWORD/REDIS_PASSWORD 明文 | 项目规范 F-001/F-011 + 业界通用 |

### 8.2 本任务落地建议

1. **Bash（.sh）**：
   - MariaDB：`cmd=(mariadb -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -N -B -e "SELECT 1"); "${cmd[@]}"`——口令仅存在于数组元素，不拼接字符串、不 eval、不打印；日志提示时显示 `-p****`；
   - Redis：优先 `export REDISCLI_AUTH="$REDIS_PASSWORD"` 后 `redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" PING`，命令中无口令；
   - 避免 `set -x`（脚本默认不开）。
2. **PowerShell（.ps1）**：
   - 命令参数直接传给 `&`，PowerShell 不把参数写入进程表（比 Linux 命令行相对安全），但**日志输出必须掩码**；
   - `$env:REDISCLI_AUTH = $env:REDIS_PASSWORD` 后调用 redis-cli（同官方推荐）；
   - 删除旧脚本中 `$connStr` 明文密码死代码与 `New-Object System.Data.Common.DbProviderFactory`（P7-06）。

---

## 9. 其他相关任务资料（步骤 6）

### 9.1 Nacos 已安装未启动 → "警告（未运行）"（F-005 关键规则）

- 判定链：`NACOS_HOME` 存在且 `bin/startup.cmd|sh` 存在 = **已安装**；HTTP 探测失败 = **未运行**；
- 输出分级：已安装未启动 → **警告（未运行）**（黄色），**不计失败、不计未安装**；与 F-006 运行状态衔接（供 TASK-008 启动）；
- 退出码：有警告无失败 → 退出 0 并提示警告（F-011 约定）。

### 9.2 Nacos 2.3 兼容性注意（issue-list P7-11）

- `/nacos/v1/console/health/readiness` 在 Nacos 2.3 部分环境 404，**不作为唯一判定**；
- 以 `http://NACOS_ADDR/nacos/` 含 "Nacos" 为主（PRD/任务定义要求），`/nacos/v2/core/cluster/node/self/health` 返回 `"data":"UP"` 为 2.x 官方辅助接口。

### 9.3 JDK 为运行时环境，不执行启动（F-002/F-006）

- JDK 可用性结论复用为运行状态"就绪"（无需启动检查），与 MariaDB/Redis/Nacos 的"未运行可启动"语义区分。

### 9.4 无关检查项移除（F-010）

- 移除 Maven/Git 版本检查、pom.xml/SQL 脚本存在性检查、Maven settings 检查（均与"可用性+运行状态"无关）；如需保留可作为可选信息输出（不参与计数）。

---

## 10. 编码要点速查（供 code 步骤参考）

1. **头部**：`.ps1`/`.sh` 文件头保留 `# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>`，简体中文注释，版本标注 v0.2.7（G9/G10）；
2. **配置加载**：`.ps1` 开头 `. $PSScriptRoot\load-env.ps1`；`.sh` 开头 `source "$SCRIPT_DIR/load-env.sh"`；无 param 块、无 `192.168.1.x` 默认地址（G1）；
3. **输出分级**：通过（绿）/警告（黄）/失败（红）三级；.ps1 用 Write-Host -ForegroundColor，.sh 用 printf + ANSI（F-011）；
4. **退出码**：全部通过 0；存在失败 1；警告无失败 0 并提示（F-011）；
5. **JDK**：`java -version` 含 `version "21`（或 `openjdk version "21`）+ JAVA_HOME 非空且目录有效，任一失败 → 失败并提示安装 JDK 21 / 配置 JAVA_HOME；
6. **MariaDB**：安装三重（命令 mariadb/mysql/mysqld/mariadbd → 服务 DB_SERVICE_NAME → 进程 DB_PROCESS_NAME）；连通 `SELECT 1`（口令掩码/数组参数）；
7. **Redis**：安装三重（命令 redis-cli/redis-server → 服务 REDIS_SERVICE_NAME → 进程 REDIS_PROCESS_NAME）；`ping` 返回 PONG（REDIS_PASSWORD 非空用 REDISCLI_AUTH，掩码）；
8. **Nacos**：安装检测（NACOS_HOME + bin/startup.cmd|sh）；HTTP 探测 `http://NACOS_ADDR/nacos/` 含 "Nacos"；已安装未启动 → 警告（未运行）；未安装 → 失败并提示安装/配置 NACOS_HOME；NACOS_ADDR 缺失/非法 → 失败提示检查 env.json；
9. **运行状态**：JDK 复用可用性（就绪）；MariaDB/Redis 进程/服务/TCP 任一命中=运行中；Nacos HTTP 含 "Nacos"=运行中，失败再查 java 进程命令行含 nacos（.ps1 用 Get-CimInstance Win32_Process，.sh 用 pgrep -f nacos）；
10. **安全**：不 eval、口令掩码 `****`、日志不打印 DB_PASSWORD/REDIS_PASSWORD 明文、删除死代码（P7-05/06）。

---

## 11. 参考链接清单

- Redis CLI 官方文档：https://redis.io/docs/latest/develop/tools/cli
- Redis PING 命令：https://redis.io/docs/latest/commands/ping/
- Nacos Open API 指南（2.x）：https://nacos.io/docs/latest/open-api
- Nacos README（startup.cmd/-m standalone）：https://github.com/alibaba/nacos
- Nacos 2.3 控制台手册：https://nacos-group.github.io/en/docs/v2.3/guide/admin/console-guide/
- MariaDB healthcheck.sh 指南与 mysqladmin ping：https://runebook.dev/en/docs/mariadb/using-healthcheck-sh-script/index
- MariaDB mysqladmin(1) manpage（mariadb-client-10.6）：https://manpages.debian.org/unstable/mariadb-client-10.6/mysqladmin.1
- MySQL mysqladmin 官方文档：https://dev.mysql.com/doc/en/mysqladmin.html
- MySQL 环境变量（MYSQL_PWD 警告）：https://dev.mysql.com/doc/refman/8.0/en/environment-variables.html
- JDK 21 官方文档：https://docs.oracle.com/en/java/javase/21/
- OpenJDK 项目页（版本时间线）：https://openjdk.org/projects/jdk/
- Microsoft Learn Get-Service：https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service
- Microsoft Learn Test-NetConnection：https://learn.microsoft.com/en-us/powershell/module/nettcpip/test-netconnection
- Microsoft Learn Get-CimInstance：https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance
- nixCraft Bash 进程检测：https://www.cyberciti.biz/faq/bash-check-if-process-is-running-or-notonlinuxunix/
- Stack Overflow /dev/tcp 端口检测：https://stackoverflow.com/questions/4922943/test-if-remote-tcp-port-is-open-from-a-shell-script
- Stack Overflow 获取进程 CommandLine（Get-CimInstance）：https://stackoverflow.com/questions/77204817/getting-commandline-of-a-process-by-passing-process-id-pid-in-powershell
- Stack Overflow mysql 命令行口令安全：https://unix.stackexchange.com/questions/205180/how-to-pass-password-to-mysql-command-line

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
