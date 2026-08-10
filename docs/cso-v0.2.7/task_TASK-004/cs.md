# 代码查询结果（TASK-004 重构 deploy-start-services.ps1 / .sh 基础设施运行状态检查与一键启动）

## 0. 查询结论摘要

本任务为 v0.2.7 部署脚本重构的 **F-006（运行状态检测）与 F-007（未启动基础设施一键启动）落地任务**。经实际读取 `deploy/scripts/deploy-start-services.ps1`（219 行）与 `deploy-start-services.sh`（239 行）完整源码、TASK-003 已重构交付的 `deploy-check-env.ps1`（280 行）/`deploy-check-env.sh`（277 行，可复用检测函数基线）、TASK-002 已交付的 `load-env.ps1`（75 行）/`load-env.sh`（84 行）调用契约、`deploy/env.json`（27 键）与 `env.example.json` 全量键值、`deploy/deploy.md` 部署方案及 PRD F-006/F-007/F-011 业务规则、TASK-001 issue-list（P5/P6/P7 相关定位），确认：

- **现有 deploy-start-services 双版本脚本整体需重构而非增量修改**：已有「安装三重检测 → 运行检测 → 未运行启动 → 探测确认」框架可作基础；但存在 JDK 可用性缺失（F-006 要求输出）、Nacos 启动后固定等待 8 秒（非循环轮询 + 超时上限，P7-12）、.ps1 输出 icon 为空字符 / .sh 用 emoji + ANSI（P5，双平台风格不一致）、有警告仍 exit 0（P5）、.sh 版本号 v0.2.0 陈旧（P7-13）、.sh set -e 下 source load-env.sh 返回值处理、Redis 启动确认未带口令、.sh 硬编码 systemctl 服务名 "redis"、文件头无 SPDX 声明等问题；
- **必须复用的基线**：TASK-003 已重构的 `deploy-check-env.ps1`/`.sh` 检测函数（`Write-Result`/`print_result` 三级输出、`Test-Installed` 三重安装检测、`Test-TcpPort`/`tcp_port_open` TCP 探测、`Test-NacosHttp`/`nacos_http_ok` HTTP 探测、`Test-NacosJavaProcess`/`pgrep -f nacos`、`Split-Csv`/`split_csv`、env.json 服务/进程名清单解析、口令掩码方案）；TASK-002 的 `load-env.ps1`/`load-env.sh`（F-001 契约）；
- **启动方式契约（F-007，PRD 4.7）**：MariaDB → Redis → Nacos；MariaDB/Redis 系统服务优先（Start-Service / systemctl start）→ 可执行文件（mysqld/mariadbd/redis-server）；Nacos 执行 `NACOS_HOME/bin/startup.cmd`（Windows，standalone 模式）/ `bash NACOS_HOME/bin/startup.sh`（Linux）；每次启动后再次探测确认（进程/TCP/HTTP），不报假成功；启动超时输出警告并给处理建议；未安装服务不尝试启动、输出"未安装，请先安装"计入失败；JDK 仅输出可用性结论不执行启动；口令掩码不打印明文（DB_PASSWORD/REDIS_PASSWORD）；
- **验收红线（F-006/F-007/acceptanceCriteria）**：三场景（未运行→自动启动并探测确认输出"通过" / 已运行→幂等跳过输出"已运行" / 未安装→不尝试启动输出"未安装，请先安装"计入失败）；JDK 不启动；启动超时输出"警告"不报假成功；日志不泄露口令明文；输出「通过/警告/失败」三级（双平台一致，[通过]/[警告]/[失败] 文本 + 颜色，不用 emoji）；退出码全部通过 0 / 存在失败非零（1）/ 仅警告 0；.ps1/.sh 行为一致且可独立语法校验。

---

## 1. 查询范围与文件清单

### 1.1 本任务直接改造的目标文件（重构对象）

| 文件 | 定位/作用 | 现状（v0.2.7 基线） |
| --- | --- | --- |
| `deploy/scripts/deploy-start-services.ps1` | Windows 基础设施安装检测 + 运行检测 + 一键启动（MariaDB/Redis/Nacos） | 219 行；已有「三重检测 → 运行检测 → 启动 → 探测确认」框架；JDK 未纳入；Write-Result icon 为空字符；Nacos 启动固定 sleep 8；有警告仍 exit 0；无 SPDX 头 |
| `deploy/scripts/deploy-start-services.sh` | Linux 基础设施安装检测 + 运行检测 + 一键启动（MariaDB/Redis/Nacos） | 239 行；同上框架；版本号 v0.2.0（P7-13 陈旧）；emoji + ANSI 输出；set -e 下 source load-env.sh 返回值处理；systemctl 启动硬编码服务名 "redis"；无 SPDX 头 |

> 两者均被 git 跟踪（TASK-001 已确认），重构后仍须保留双平台一一对应（UT-143 契约）。

### 1.2 依赖与可复用模块（TASK-002/TASK-003 已交付，本任务直接复用）

| 文件 | 定位/作用 | 调用契约（重构脚本必须遵守） |
| --- | --- | --- |
| `deploy/scripts/load-env.ps1` | 统一配置加载（Windows，dot-source） | `. $PSScriptRoot\load-env.ps1`；env.json 缺失/解析失败/关键配置 8 项缺失均 `exit 1`；成功输出绿色提示；口令不打印明文 |
| `deploy/scripts/load-env.sh` | 统一配置加载（Linux，source） | `source "$SCRIPT_DIR/load-env.sh"`；失败用 `return 1`（调用方 `set -e` 时 source 返回 1 会退出，符合「配置缺失即退出」预期，但需注意提示输出）；依赖 jq 或 python3 |
| `deploy/scripts/deploy-check-env.ps1` | TASK-003 已重构：环境可用性 + 运行状态检测（仅检查不启动） | 检测函数与输出模式可直接复制复用于 start-services（见第 3 节逐函数行号） |
| `deploy/scripts/deploy-check-env.sh` | TASK-003 已重构：环境可用性 + 运行状态检测（仅检查不启动） | 同上 |
| `deploy/env.json` | 唯一配置源 | 27 键全部为字符串类型；含 DB_PASSWORD/REDIS_PASSWORD/RSA_* 等敏感值（git 已忽略） |
| `deploy/env.example.json` | 配置模板（必须入库） | 错误提示的指引目标文案统一为「复制 env.example.json 为 env.json 并填写配置」 |

### 1.3 参考文件

- `deploy/deploy.md`（v0.2.6）：第 5.5 节「启动基础设施」调用 `deploy-start-services.ps1`；第 2 节端口映射（MariaDB 3306 / Redis 6379 / Nacos 8848）；第 11 节常见问题（服务启动报 Nacos 连接失败 → 先执行 deploy-start-services 启动基础设施）。
- TASK-001 issue-list：P5（输出分级与退出码不统一）、P6（deploy-start-services 未纳入 JDK、Nacos 启动后固定等 8 秒）、P7（双平台启动方式差异、输出 emoji/ANSI、敏感信息）。
- PRD F-006/F-007/F-011（见第 7 节摘录）。

---

## 2. 现有 deploy-start-services.ps1 源码详细分析（219 行）

### 2.1 整体结构（行号对照）

| 段 | 行号 | 内容 |
| --- | --- | --- |
| 文件头 | L1-12 | `<# .SYNOPSIS ... #>` 注释块；**无 SPDX-License-Identifier 与版权声明**（P7-14，重构需补充） |
| 加载环境 | L14-23 | `$ProjectDir = Split-Path -Parent $PSScriptRoot`（= deploy）；L17-21 自行检查 env.json 缺失并 `exit 1`；L23 `. $PSScriptRoot\load-env.ps1` |
| 关键配置校验 | L25-37 | 重复实现 load-env 的 8 项关键配置校验（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失 `exit 1`——**与 load-env 重复，重构时可移除（load-env 已兜底）** |
| 全局计数 | L44 | `$pass = 0; $fail = 0; $warn = 0` |
| 输出函数 | L46-50 | `Write-Result`：L48 icon 为空字符（`""` emoji 不显示），仅用 ForegroundColor 分级——**不满足双平台统一"文本前缀 + 颜色"规范（P5）** |
| 安装检测 | L52-73 | `Test-Installed`：命令 → 服务 → 进程三重检测，返回命中方式字符串 |
| 检测清单解析 | L76-80 | `$env:DB_SERVICE_NAME -split '\s*,\s*'` 逗号转数组（含默认值 `MySQL,MariaDB` / `mysqld,mariadbd` / `Redis` / `redis-server`） |
| 阶段一安装检测 | L82-113 | MariaDB（L86-91）/ Nacos（L94-100）/ Redis（L103-108）；任一未安装 `$fail++` 并 L110-113 `exit 1` 提前退出——**不符合 F-007「未安装不尝试启动、计入失败、可继续后续服务」** |
| 阶段二运行检测与启动 | L115-209 | MariaDB（L118-147）/ Nacos（L149-178）/ Redis（L180-209） |
| 汇总与退出码 | L211-219 | L213 `$totalResult` 有警告显示"完成 (有警告)"；L219 `if ($fail -gt 0) { exit 1 } else { exit 0 }`——**有警告仍 exit 0（P5，与 F-011 约定不一致）** |

### 2.2 硬编码地址残留

- **本脚本（deploy-start-services.ps1）内未发现 192.168.1.x 等硬编码连接地址**（已 grep 全 deploy 目录，残留硬编码仅在 `deploy-db-init.ps1` L20/L32 与 `deploy-db-init.sh` L21，均属 TASK-005 范围，本任务不处理）。
- L136-137 有可执行文件名默认兜底 `mysqld`/`mariadbd`（此为启动可执行文件探测，非连接地址，允许保留作检测默认值）。

### 2.3 运行检测与启动逻辑逐段分析（重点：现状启动方式与缺陷）

**3.1 MariaDB（L118-147）**
- 运行检测：`Get-Process $dbProcName`（L119）或 `Get-Service $dbSvcName` Status='Running'（L120/L124-125）——**缺 TCP 端口探测**（F-006 要求进程/服务/TCP 任一命中）。
- 启动：
  - 系统服务分支（L129-134）：`Start-Service $mysqlSvc.Name` → `Start-Sleep -Seconds 2` → 再查服务状态，Running 记"通过"、否则记"警告 启动超时"。
  - 可执行文件分支（L135-144）：取 `mysqld`/`mariadbd` 的 Source → `Start-Process -FilePath $mysqlExe -NoNewWindow` → `Start-Sleep -Seconds 3` → `Get-Process` 确认。
  - **缺陷**：无「系统服务名/可执行文件不存在」时多服务名依次尝试（只取第一个命中的服务）；确认仅查进程不查 TCP 端口；无循环轮询 + 超时上限（固定 sleep 2/3 秒）；Start-Process 无 -WindowStyle Hidden 等处理。

**3.2 Nacos（L149-178）**
- 运行检测：HTTP 探测 `http://$env:NACOS_ADDR/nacos/`（L152-153，`Invoke-WebRequest` 内容 match "Nacos"）；失败再查 `Get-Process java` 命令行 match nacos（L159）。
- 启动：L167 `Start-Job` + `cmd /c "start ... startup.cmd -m standalone"` → **L168 固定 `Start-Sleep -Seconds 8`** → 再 HTTP 探测（L170-174）。
- **缺陷（P7-12）**：固定等 8 秒非循环轮询 + 超时上限（任务定义要求如 30s 内每 2s 探测）；`Start-Job` 方式在部分 PowerShell 版本下 `cmd /c start` 窗口交互行为不稳定；启动确认仅一次 HTTP 探测。

**3.3 Redis（L180-209）**
- 运行检测：`Get-Process $redisProcName`（L181）或 `Get-Service` Running（L182/L186-187）——**缺 TCP 端口探测与 redis-cli ping 确认**（虽然启动后确认用了 ping）。
- 启动：
  - 系统服务分支（L191-196）：`Start-Service` → sleep 2 → 查服务状态。
  - 可执行文件分支（L197-207）：`Start-Process redis-server` → sleep 2 → `& redis-cli ping`（L202）返回 PONG 确认。
  - **缺陷**：L202 `& redis-cli ping` **未带 `-h $env:REDIS_HOST -p $env:REDIS_PORT` 与 REDISCLI_AUTH 口令**（本机 127.0.0.1 无口令可通，但不符合 F-001 契约与口令掩码约定）；确认逻辑用 `$ping -eq "PONG"` 但 `2>&1` 可能混入错误文本。

**口令掩码（本脚本）**：启动命令本身不传口令（系统服务/可执行文件启动），但 Redis ping 确认未处理 REDIS_PASSWORD；日志无口令明文打印（现状 OK，重构继续保持）。

---

## 3. 现有 deploy-start-services.sh 源码详细分析（239 行）

### 3.1 整体结构（行号对照）

| 段 | 行号 | 内容 |
| --- | --- | --- |
| 文件头 | L1-12 | 注释块；**版本 v0.2.0（P7-13 陈旧，重构统一 v0.2.7）；无 SPDX 声明（P7-14）** |
| 严格模式 | L14 | `set -euo pipefail` |
| 加载环境 | L16-29 | `SCRIPT_DIR`/`PROJECT_DIR`；L23-27 自行检查 env.json 缺失 `exit 1`；L29 `source "$SCRIPT_DIR/load-env.sh"`——**在 set -e 下，load-env.sh return 1（配置缺失）时脚本随即退出非零，符合预期但错误提示可能被 pipefail 中断，重构需确认输出完整** |
| 关键配置校验 | L31-41 | 重复 load-env 的 8 项校验 |
| 辅助函数 | L44-82 | `split_csv`（L44，tr/xargs）、`print_result`（L57-64，emoji + ANSI）、`has_cmd`（L67）、`has_svc`（L70，systemctl list-units grep）、`has_proc`（L73，pgrep -x）、`svc_active`（L78，systemctl is-active） |
| 检测清单解析 | L46-49 | `${DB_SERVICE_NAME:-MySQL,MariaDB}` 默认清单 |
| 阶段一安装检测 | L84-140 | 与 .ps1 对称；任一未安装 L137-140 `exit 1` 提前退出 |
| 阶段二运行检测与启动 | L142-223 | MariaDB（L146-171）/ Nacos（L173-195）/ Redis（L197-223） |
| 汇总与退出码 | L225-239 | L239 `if [ "$FAIL" -gt 0 ]; then exit 1; else exit 0; fi`——有警告仍 0 |

### 3.2 运行检测与启动逻辑逐段分析（重点：与 .ps1 的差异）

**3.1 MariaDB（L146-171）**
- 运行检测：`has_proc` → `svc_active`（L147-149）——**缺 TCP 端口探测（F-006）**。
- 启动：L153-159 若 systemd 有 mysql|mariadb 服务则 `sudo systemctl start`（用 `grep -oE "mysql|mariadb" | head -1` 取服务名——**硬编码服务名匹配，未用 $DB_SERVICES 清单**）；L160-167 `mysqld_safe --user=mysql &` 后台 + sleep 3 + `has_proc` 确认；L168-170 兜底"无法自动启动"。
- **缺陷**：`sudo systemctl start` 未捕获失败原因（`2>/dev/null` 吞错误，用户无法定位权限问题）；服务名匹配硬编码 "mysql|mariadb" 而非 `DB_SERVICES` 数组；确认无 TCP 端口探测、无循环轮询 + 超时上限。

**3.2 Nacos（L173-195）**
- 运行检测：`curl http://$NACOS_ADDR/nacos/ | grep -q "Nacos"`（L175）+ `pgrep -f nacos`（L180）。
- 启动：L185 `bash "$NACOS_HOME/bin/startup.sh" &>/dev/null &` → **L186 固定 sleep 8** → 一次 curl 探测（L187-191）。
- **缺陷（P7-12）**：固定等 8 秒非循环轮询 + 超时上限；`&>/dev/null &` 完全吞掉启动日志（无法判断 Nacos 启动错误原因）；启动确认仅一次。

**3.3 Redis（L197-223）**
- 运行检测：`has_proc` → `svc_active` → `redis-cli ping`（L198-203，此处有 ping 探测但**未带 -h/-p/REDISCLI_AUTH 口令**）。
- 启动：L206-211 `sudo systemctl start redis`（**服务名硬编码 "redis"，未用 $REDIS_SERVICES**）；L212-219 `redis-server --daemonize yes` 后台 + sleep 2 + `redis-cli ping` 确认；L220-222 兜底。
- **缺陷**：同 MariaDB——服务名硬编码、`2>/dev/null` 吞权限错误、ping 未带口令、无循环轮询 + 超时上限。

### 3.3 口令掩码与敏感信息（.sh）

- 本脚本启动命令不传口令（系统服务/可执行文件），Redis ping 未带 REDIS_PASSWORD；`redis-server --daemonize yes` 为无口令模式启动——**重构后 Redis ping 确认必须带 `-h/-p` 且经 `REDISCLI_AUTH` 传递口令（对齐 check-env L179）**；无 eval 拼接（现状 OK）。

---

## 4. TASK-003 已重构的 deploy-check-env 检测函数（可直接复用，含精确行号）

### 4.1 deploy-check-env.ps1（280 行，TASK-003 已完成）

| 函数/逻辑 | 行号 | 签名/行为 | 复用建议（start-services 直接复制） |
| --- | --- | --- | --- |
| `Write-Result` | L33-40 | `param([string]$Status, [string]$Message)`；输出 `  [通过]/[警告]/[失败]` 文本前缀 + 颜色（Green/Yellow/Red）并累计 `$script:pass/$script:warn/$script:fail` | ✅ 直接复制作为统一三级输出（F-011）；与 .sh `print_result` 行为一致 |
| `Split-Csv` | L43-47 | `param([string]$Value)`；逗号分隔转数组（去空白、去空项），空值返回 @() | ✅ 直接复制解析 `DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME` |
| `Test-Installed` | L50-62 | `param([string[]]$Commands, [string[]]$Services, [string[]]$Processes)`；命令→服务→进程三重检测，命中返回命中方式（如"命令 mariadb"），未命中返回 $null | ✅ 直接复制用于安装检测（F-007 未安装判定） |
| `Test-TcpPort` | L65-78 | `param([string]$HostName, [string]$Port, [int]$TimeoutMs = 1000)`；TcpClient BeginConnect + WaitOne 超时探测 | ✅ 直接复制用于运行状态 TCP 探测 + 启动后确认（MariaDB 3306 / Redis 6379） |
| `Test-NacosHttp` | L81-86 | `Invoke-WebRequest http://$env:NACOS_ADDR/nacos/ -TimeoutSec 5`，Content match "Nacos" | ✅ 直接复制用于 Nacos 运行检测与启动后 HTTP 确认 |
| `Test-NacosJavaProcess` | L89-95 | `Get-CimInstance Win32_Process -Filter "Name = 'java.exe'"` 过滤 CommandLine match 'nacos' | ✅ 直接复制用于 Nacos 辅助判定 |
| env.json 服务/进程名清单解析 | L98-101 | `$dbSvcName = if ($env:DB_SERVICE_NAME) { Split-Csv ... } else { @("MySQL","MariaDB") }` 等 4 组 | ✅ 直接复制 |
| JDK 可用性检查 | L116-130 | `java -version 2>&1` match `version "21` + `JAVA_HOME` 非空且 Test-Path | ✅ 复用逻辑（start-services 仅输出可用性结论，不启动） |
| MariaDB 运行状态检测 | L212-229 | 进程 `Get-Process -Name $dbProcName` / 服务 Running 循环 / `Test-TcpPort -HostName $env:DB_HOST -Port $env:DB_PORT` 任一命中即运行中 | ✅ 直接复制为「已运行幂等跳过」判定 |
| Redis 运行状态检测 | L231-248 | 同上（REDIS_HOST/REDIS_PORT） | ✅ 直接复制 |
| Nacos 运行状态检测 | L250-262 | `Test-NacosHttp` 为主 + `Test-NacosJavaProcess` 辅助 | ✅ 直接复制 |
| 口令掩码方案 | L146 / L169 | MariaDB：`-p"$env:DB_PASSWORD"` 参数、命令结果 `2>&1` 重定向不打印；Redis：`if (-not [string]::IsNullOrEmpty($env:REDIS_PASSWORD)) { $env:REDISCLI_AUTH = $env:REDIS_PASSWORD }` + `redis-cli -h ... -p ... ping` | ✅ 直接复用（启动后确认阶段使用） |
| 汇总与退出码 | L264-280 | `fail>0 → exit 1`；`warn>0 → exit 0` 并提示警告；全通过 → exit 0 | ✅ 对齐 F-011 |

### 4.2 deploy-check-env.sh（277 行，TASK-003 已完成）

| 函数/逻辑 | 行号 | 签名/行为 | 复用建议 |
| --- | --- | --- | --- |
| `print_result` | L38-45 | `local status="$1" message="$2"`；`case` 输出 `  [通过]/[警告]/[失败]`（GREEN/YELLOW/RED ANSI）+ `PASS/WARN/FAIL` 自增 | ✅ 直接复制 |
| `split_csv` | L48-50 | `echo "$1" \| tr ',' '\n' \| sed 去空白 \| grep -v '^$' \|\| true` | ✅ 直接复制 |
| `has_cmd` | L53 | `command -v "$1" &>/dev/null` | ✅ 直接复制 |
| `has_svc` | L56-62 | 循环 `systemctl list-units --type=service --all \| grep -qw "$s"` | ✅ 直接复制 |
| `has_proc` | L65-71 | 循环 `pgrep -x "$p"` | ✅ 直接复制 |
| `svc_active` | L74-80 | 循环 `systemctl is-active --quiet "$s"` | ✅ 直接复制（运行检测 + 启动后确认） |
| `tcp_port_open` | L83-95 | `timeout 1 bash -c "cat < /dev/null > /dev/tcp/$hostname/$port"`（无 timeout 命令时回退） | ✅ 直接复制 |
| `nacos_http_ok` | L98-100 | `curl -s --max-time 5 http://$NACOS_ADDR/nacos/ \| grep -q "Nacos"` | ✅ 直接复制 |
| env.json 服务/进程名清单解析 | L103-106 | `mapfile -t DB_SERVICES < <(split_csv "${DB_SERVICE_NAME:-MySQL,MariaDB}")` 等 4 组 | ✅ 直接复制 |
| JDK 可用性检查 | L121-132 | `java -version 2>&1 \| grep -q 'version "21'` + JAVA_HOME 非空且 -d | ✅ 复用逻辑 |
| MariaDB/Redis 运行状态 | L220-246 | `has_proc` → `svc_active` → `tcp_port_open` 任一命中 | ✅ 直接复制 |
| Nacos 运行状态 | L248-260 | `nacos_http_ok` 为主 + `pgrep -f nacos` 辅助 | ✅ 直接复制 |
| 口令掩码方案 | L154 / L179 | MariaDB：数组参数 `cmd=("$DB_CLIENT" -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" -N -B -e "SELECT 1"); "${cmd[@]}" >/dev/null 2>&1`；Redis：`if [ -n "${REDIS_PASSWORD:-}" ]; then export REDISCLI_AUTH="$REDIS_PASSWORD"; fi` + `redis-cli -h ... -p ... ping` | ✅ 直接复用 |
| 汇总与退出码 | L262-277 | `FAIL>0 → exit 1`；`WARN>0 → exit 0`；全通过 → exit 0 | ✅ 对齐 F-011 |

---

## 5. load-env 调用契约（TASK-002 已交付，直接复用依据）

### 5.1 load-env.ps1（PowerShell，dot-source 调用）

- 用法：`. .\deploy\scripts\load-env.ps1 [-EnvFile env.json]`；
- env.json 缺失：Write-Error 提示「复制 env.example.json 为 env.json 并填写配置」并 `exit 1`；解析失败 `exit 1`；
- 关键配置校验 8 项（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT），缺失逐个列出键名并 `exit 1`；
- 加载成功输出「环境变量已从 ... 加载，共 N 项」（绿色）；**任何输出不含 DB_PASSWORD/RSA_PRIVATE_KEY 明文**；
- 本脚本（deploy-start-services.ps1）调用后**无需重复实现关键配置校验**（load-env 已兜底；现状 L25-37 重复代码可移除）。

### 5.2 load-env.sh（Bash，source 调用）

- 用法：`source deploy/scripts/load-env.sh [env.json]`；
- 依赖 jq（优先）或 python3（回退）解析 env.json 并 export 键值对；
- env.json 缺失/解析失败/关键配置缺失均 `return 1` 并输出错误提示（含 env.example.json 指引）；
- **调用方注意事项**：本脚本（deploy-start-services.sh）保留 `set -euo pipefail`（L14）时，source 返回 1 会使脚本随即退出非零——符合「配置缺失即退出」预期，但需确认 load-env.sh 的错误提示在 `set -e`/pipefail 下完整输出（现状 L29 source 后无显式 `|| exit`，重构可改为 `source ... || exit $?` 保证退出码透传）；
- 加载成功后可直接使用 `$NACOS_ADDR/$NACOS_HOME/$DB_*/$REDIS_*` 环境变量。

### 5.3 本脚本（deploy-start-services）所需关键配置（load-env 8 项已覆盖）

| 配置键 | 用途 | 使用场景 |
| --- | --- | --- |
| NACOS_ADDR | Nacos 地址 host:port | F-006 运行检测 HTTP 探测 / F-007 启动后 HTTP 确认 |
| NACOS_HOME | Nacos 安装目录 | F-007 启动（bin/startup.cmd 或 startup.sh） |
| DB_HOST / DB_PORT | MariaDB 连接 | 运行状态 TCP 探测（3306） |
| DB_SERVICE_NAME / DB_PROCESS_NAME | MariaDB 服务/进程名清单（逗号分隔多值） | 三重安装检测 / 运行状态检测 / 系统服务启动 |
| REDIS_HOST / REDIS_PORT / REDIS_PASSWORD | Redis 连接 | 运行状态 TCP 探测（6379）/ ping 确认（REDISCLI_AUTH） |
| REDIS_SERVICE_NAME / REDIS_PROCESS_NAME | Redis 服务/进程名清单 | 三重安装检测 / 运行状态检测 / 系统服务启动 |
| JAVA_HOME（系统环境变量，非 env.json） | JDK 检测 | F-006 JDK 可用性结论 |

> env.json 的 DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME 为可选键（load-env 不强制），start-services 使用时应做空值防御（默认 `MySQL, MariaDB` / `mysqld, mariadbd` / `Redis` / `redis-server` 作为检测名清单——这是检测默认值而非连接地址，允许保留）。

---

## 6. deploy/env.json 配置结构（27 键，全部字符串类型）

| 键 | 值示例（本机） | 敏感 | 本任务使用 |
| --- | --- | --- | --- |
| NACOS_ADDR | `127.0.0.1:8848` | 否 | ✅ F-006/F-007 |
| NACOS_HOME | `D:\jenemy\develop\nacos`（Windows）/ `/opt/nacos`（模板） | 否 | ✅ F-007 启动脚本路径 |
| DB_SERVICE_NAME | `MySQL, MariaDB` | 否 | ✅ 安装/运行检测 + 系统服务启动 |
| DB_PROCESS_NAME | `mysqld, mariadbd` | 否 | ✅ 安装/运行检测 + 可执行文件启动 |
| REDIS_SERVICE_NAME | `Redis` | 否 | ✅ 安装/运行检测 + 系统服务启动 |
| REDIS_PROCESS_NAME | `redis-server` | 否 | ✅ 安装/运行检测 + 可执行文件启动 |
| DB_HOST | `127.0.0.1` | 否 | ✅ TCP 探测 |
| DB_PORT | `3306` | 否 | ✅ TCP 探测 |
| DB_USERNAME | `root` | 否 | ✅ （启动后确认如需 SELECT 1） |
| DB_PASSWORD | 真实口令 | **是** | ⭕ 本脚本启动不传口令；确认探测若用到须掩码 `****` |
| DB_USER | `root` | 否 | ⭕ 兼容项（本任务不用） |
| REDIS_HOST | `127.0.0.1` | 否 | ✅ TCP 探测 / ping |
| REDIS_PORT | `6379` | 否 | ✅ TCP 探测 / ping |
| REDIS_PASSWORD | 空 | **是** | ✅ ping 确认经 REDISCLI_AUTH 传递（掩码） |
| REDIS_DATABASE | `0` | 否 | ⭕ 本任务不用 |
| RSA_PRIVATE_KEY / RSA_PUBLIC_KEY | DER 单行 Base64 | **是** | ⭕ 本任务不用（不打印） |
| VERIFICATION_CODE_* / PASSWORD_* / MARIADB_ROOT_PASSWORD / TZ | 应用参数 | 部分 | ⭕ 本任务不用 |

> env.example.json 与 env.json 键一致，仅敏感值替换为占位符（`<DB_PASSWORD>` 等）、NACOS_HOME 为 Linux 风格 `/opt/nacos`。

---

## 7. F-006/F-007/F-011 业务规则摘录（PRD v0.2.7，重构实现依据）

### 7.1 F-006 运行状态检测（PRD 4.6）
- JDK：不执行"启动"检查，仅复用 F-002 可用性检查结论（可用即视为"就绪"）；
- MariaDB/Redis：进程（DB_PROCESS_NAME/REDIS_PROCESS_NAME）存在、系统服务（DB_SERVICE_NAME/REDIS_SERVICE_NAME）为 Running、或 TCP 端口（3306/6379）可达，任一命中即视为运行中；
- Nacos：HTTP 探测 `http://NACOS_ADDR/nacos/` 返回含 "Nacos" 内容视为运行中；探测失败时再检测 java 进程命令行含 nacos 关键字作辅助；
- 运行状态与可用性状态分开输出：已安装但未运行 → "未运行"（供 F-007 启动），已安装且运行 → "运行中"，未安装 → "未安装"（不可启动）。

### 7.2 F-007 未启动基础设施一键启动（PRD 4.7）
- 启动顺序：**MariaDB → Redis → Nacos**（数据库与缓存先于注册中心）；
- MariaDB/Redis 启动方式优先级：**系统服务（Start-Service / systemctl start）→ 可执行文件（mysqld/mariadbd/redis-server，Start-Process / 后台启动）**；
- Nacos 启动方式：执行 **`NACOS_HOME/bin/startup.cmd`（Windows，standalone 模式）/ `bash NACOS_HOME/bin/startup.sh`（Linux）**；
- 每次启动后必须再次探测确认（进程/TCP/HTTP），确认成功输出"通过"；启动超时或失败输出"警告/失败"并给出处理建议，**不得报假成功**；
- 启动过程输出口令掩码处理，不得泄露 DB_PASSWORD/REDIS_PASSWORD 明文；
- 未安装的服务不得尝试启动，输出"未安装，请先安装"并计入失败（若存在未安装项，按脚本约定决定是否继续执行后续服务）。

### 7.3 F-011 脚本契约与输出规范（PRD 4.11）
- 输出分级约定：成功项前缀"通过"（绿色）、警告项"警告"（黄色）、失败项"失败"（红色）；汇总显示通过/警告/失败计数；
- 退出码约定：全部通过退出 0；存在失败项退出非零（1）；存在警告但无失败退出 0 并提示警告；
- 脚本文件保留 SPDX-License-Identifier（Apache-2.0）与版权声明，简体中文注释；
- .ps1 与 .sh 同名脚本行为一致、可独立验证。

---

## 8. 可复用模块与遗留问题（供 code 步骤直接使用）

### 8.1 可复用资产

| 可复用资产 | 位置 | 复用建议 |
| --- | --- | --- |
| load-env.ps1 / load-env.sh | TASK-002 已交付 | 脚本开头调用（`. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh"`，.sh 建议 `source ... \|\| exit $?`）；env.json 缺失/关键配置缺失提示与退出由 load-env 兜底，**删除现状重复的关键配置校验块（.ps1 L25-37 / .sh L31-41）** |
| `Write-Result`（ps1） | deploy-check-env.ps1 L33-40 | 直接复制为「通过/警告/失败」三级输出 + 计数（F-011） |
| `print_result`（sh） | deploy-check-env.sh L38-45 | 直接复制（文本前缀 + ANSI 颜色，不用 emoji） |
| `Split-Csv`（ps1）/ `split_csv`（sh） | L43-47 / L48-50 | 解析 DB_*/REDIS_* 服务名/进程名清单 |
| `Test-Installed`（ps1）/ `has_cmd`+`has_svc`+`has_proc`（sh） | L50-62 / L53-71 | 安装三重检测（F-007 未安装判定） |
| `Test-TcpPort`（ps1）/ `tcp_port_open`（sh） | L65-78 / L83-95 | 运行状态 TCP 探测 + 启动后确认（3306/6379） |
| `Test-NacosHttp`（ps1）/ `nacos_http_ok`（sh） | L81-86 / L98-100 | Nacos 运行检测 + 启动后 HTTP 确认 |
| `Test-NacosJavaProcess`（ps1）/ `pgrep -f nacos`（sh） | L89-95 / check-env.sh L250 | Nacos 辅助判定 |
| `svc_active`（sh） | deploy-check-env.sh L74-80 | systemd 服务活跃判定 + 启动后确认 |
| 口令掩码方案 | check-env.ps1 L146/L169 / .sh L154/L179 | MariaDB `-p"$env:DB_PASSWORD"`/数组参数；Redis `REDISCLI_AUTH` 环境变量 |
| env.example.json | deploy/env.example.json | 错误提示的指引目标文案统一为「复制 env.example.json 为 env.json 并填写配置」 |
| 启动方式参考（现状可改造） | deploy-start-services.ps1 L129-144/L167/L191-206；.sh L153-169/L185/L206-219 | 系统服务优先 → 可执行文件；Nacos startup 脚本 |

### 8.2 遗留问题与重构处置（本任务 code 步骤实现依据）

| 编号 | 问题 | 现状定位 | 重构处置 |
| --- | --- | --- | --- |
| S1 | JDK 可用性缺失（P6） | .ps1/.sh 均无 JDK 检查 | 新增 JDK 可用性输出（复用 check-env 逻辑：java 命令 + JAVA_HOME + 版本 21），**仅输出就绪/缺失结论，不执行启动**；JDK 缺失计入失败但不阻断基础设施启动流程（按 F-007 业务规则） |
| S2 | 启动后确认非循环轮询 + 超时上限（P7-12） | .ps1 Nacos L168 固定 sleep 8 / Redis L193 sleep 2 / MariaDB L131 sleep 2；.sh 同 | 启动后进入循环探测（如 30s 上限内每 2s 探测一次，可用 `Start-Sleep -Seconds 2` + 循环变量 / `for` 循环），任一探测命中即确认成功输出"通过"；超时输出"警告/失败"并给出等待重试/手动检查建议 |
| S3 | 运行检测缺 TCP 端口（F-006） | .ps1 MariaDB L119-120 / Redis L181-182；.sh L147-149/L198-200 | 运行检测统一为「进程 / 系统服务 Running / TCP 端口可达 任一命中即运行中」（直接复制 check-env 对应逻辑），已运行幂等跳过输出"已运行" |
| S4 | 启动失败不给出处理建议、吞错误（P5/P7） | .sh `sudo systemctl start ... 2>/dev/null`；.ps1 `Start-Process` 后仅 sleep 查状态 | 启动命令保留 `2>&1` 捕获错误信息（口令除外），失败输出"警告/失败" + 处理建议（权限提示 `以管理员身份运行 / sudo`、等待重试、手动检查） |
| S5 | 系统服务名/可执行文件硬编码匹配（F-001/F-007） | .sh L153-154 grep "mysql|mariadb"、L207 `systemctl start redis` | 使用 env.json 清单数组依次尝试：遍历 `$DB_SERVICES`/`$REDIS_SERVICES` 找存在的系统服务启动；可执行文件遍历 `$DB_PROCESSES`/`$REDIS_PROCESSES`（mysqld/mariadbd/redis-server） |
| S6 | Redis ping 确认未带口令（口令掩码 F-007） | .ps1 L202 `& redis-cli ping`；.sh L202/L215 `redis-cli ping` | 确认命令带 `-h $env:REDIS_HOST -p $env:REDIS_PORT` 且 `REDISCLI_AUTH` 传 REDIS_PASSWORD（对齐 check-env）；日志只显示 `****` |
| S7 | 输出分级与退出码不统一（P5） | .ps1 L48 icon 空字符 + L219 有警告 exit 0；.sh emoji + L239 | 统一 `[通过]/[警告]/[失败]` 文本前缀 + 颜色（双平台一致，不用 emoji）；退出码：fail>0 → exit 1；warn>0 → exit 0 并提示警告；全通过 → exit 0 |
| S8 | 未安装服务导致整体提前退出（F-007） | .ps1 L110-113 / .sh L137-140 `if fail>0 exit 1` | 未安装服务不尝试启动，输出"未安装，请先安装"计入失败，**继续执行后续服务**；全部结束后汇总（存在失败项退出 1） |
| S9 | 版本号陈旧（P7-13） | .sh L4 v0.2.0 | 统一标注 v0.2.7（.ps1/.sh 一致） |
| S10 | 无 SPDX 头（P7-14） | 双版本均无 | 文件头保留 `# SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com>`；简体中文注释 |
| S11 | 关键配置校验重复（F-001） | .ps1 L25-37 / .sh L31-41 | 删除重复校验块，由 load-env 兜底（load-env 已校验 8 项关键配置） |
| S12 | .sh set -e 下 source load-env 返回值 | .sh L29 `source "$SCRIPT_DIR/load-env.sh"` | 改为 `source "$SCRIPT_DIR/load-env.sh" || exit $?` 保证配置缺失时退出码透传、错误提示完整 |
| S13 | Nacos 启动日志完全吞掉（P7） | .sh L185 `&>/dev/null &`；.ps1 L167 Start-Job | 启动命令保留日志输出（可重定向到 `$PROJECT_DIR/logs/nacos-start.log` 或前台输出摘要），便于失败定位；口令类内容不得写入 |
| S14 | 汇总输出（F-007） | 现状汇总仅计数 | 输出各服务状态汇总（已运行/已启动/未安装/失败），全部可达提示"可启动后端服务" |

### 8.3 明确不在本任务范围（避免越界）

- **后端服务按序一键启动（F-008）** 属 TASK-008（deploy-start-all 新增），本任务仅输出"基础设施全部可达 → 可启动后端服务"提示，不启动后端服务；
- **单服务启动脚本（deploy-start-gateway/auth/biz/system）重构（F-009）** 属 TASK-010，本任务不改；
- **deploy-check-env 检查脚本** 已由 TASK-003 完成，本任务不修改（仅复用其检测函数）；
- **.gitignore 治理（F-012）** 属 TASK-007（用户输入第 4 点），本任务不执行；当前 .gitignore 332 行已覆盖日志/临时/env.json/客户端产物，缺口清单见 TASK-001 issue-list 4.3；
- **deploy-db-init 硬编码地址（192.168.1.101）** 与 **弃用脚本清理** 属 TASK-005 范围，本任务不处理。

### 8.4 双平台行为一致性要求（SAD 1.2 / F-006 / F-007 / F-011）

- 检测/启动流程一一对应：加载环境 → 安装检测（未安装不启动计入失败）→ JDK 可用性（就绪/缺失）→ MariaDB（运行检测 → 已运行跳过 / 未运行按系统服务→可执行文件启动 → 循环探测确认）→ Redis（同上）→ Nacos（HTTP/进程检测 → startup.cmd/sh 启动 → 循环 HTTP 探测确认）→ 汇总（通过/警告/失败计数 + 退出码）；
- 输出分级与退出码一致（[通过]/[警告]/[失败] 文本 + 颜色；全部通过 0 / 失败非零 / 仅警告 0）；
- 口令掩码一致（DB_PASSWORD 不打印明文；Redis 经 REDISCLI_AUTH）；
- 语法校验：.ps1 经 PowerShell Parser、.sh 经 `bash -n`（UT-142 契约）；.sh 为普通执行脚本可保留 `set -euo pipefail`（source load-env 处用 `|| exit $?` 保证语义）。

---

## 9. 编码建议（供 code 步骤参考，非本任务执行）

1. **整体结构**：文件头 SPDX + 版权声明 + 版本 v0.2.7；脚本开头调用 load-env（`. $PSScriptRoot\load-env.ps1` / `source "$SCRIPT_DIR/load-env.sh" || exit $?`）；无 param 块、无硬编码连接地址；
2. **可复用函数**：直接复制 TASK-003 check-env 的 `Write-Result`/`print_result`、`Split-Csv`/`split_csv`、`Test-Installed`/`has_cmd`+`has_svc`+`has_proc`、`Test-TcpPort`/`tcp_port_open`、`Test-NacosHttp`/`nacos_http_ok`、`Test-NacosJavaProcess`/`pgrep -f nacos`、`svc_active`、口令掩码方案（见第 4 节行号）；
3. **执行顺序（F-007）**：① JDK 可用性（仅输出结论，不启动）→ ② MariaDB 运行检测（进程/服务/TCP 任一命中 → "已运行"幂等跳过；否则按 系统服务 Start-Service → 可执行文件 Start-Process 启动 → 循环探测确认 30s/2s）→ ③ Redis 同样处理（系统服务 → redis-server；确认用 redis-cli -h/-p + REDISCLI_AUTH ping PONG）→ ④ Nacos（Test-NacosHttp/Test-NacosJavaProcess → 未运行执行 `$env:NACOS_HOME\bin\startup.cmd`（.ps1，standalone）/ `bash "$NACOS_HOME/bin/startup.sh"`（.sh）→ 循环 HTTP 探测确认 30s/2s）→ ⑤ 汇总输出各服务状态 + 通过/警告/失败计数，全部可达提示"可启动后端服务"；
4. **未安装服务**：不尝试启动，输出"未安装，请先安装"计入失败，继续执行后续服务（不提前退出）；
5. **启动超时/失败**：输出"警告/失败" + 处理建议（权限提示：以管理员身份运行 / sudo；等待重试；手动检查服务状态与日志），不报假成功；
6. **口令掩码**：所有命令与日志不出现 DB_PASSWORD/REDIS_PASSWORD 明文（Redis 用 REDISCLI_AUTH 环境变量）；
7. **汇总与退出码（F-011）**：`失败 > 0 → exit 1`；`警告 > 0 且失败 = 0 → exit 0` 并提示警告；全通过 → exit 0；输出统一 `[通过]/[警告]/[失败]` 文本前缀 + 颜色（不用 emoji）；
8. **验证提示（testMethod）**：.ps1 经 Parser 校验、.sh 经 `bash -n`；grep 192.168.1.1xx 不得命中 start-services；口令掩码输出检查（脚本输出不含 DB_PASSWORD/REDIS_PASSWORD 明文）；三场景验证（未运行→启动并探测确认 / 已运行→幂等跳过 / 未安装→不尝试启动计入失败）；JDK 不启动验证；启动超时输出警告不报假成功验证。

---

## 10. 相关文档要点摘录（供后续步骤引用）

- **deploy/deploy.md（v0.2.6）**：第 5.5 节调用 `deploy-start-services.ps1` 启动基础设施（MariaDB/Redis/Nacos）；第 7 节命令汇总；第 11 节「服务启动报 Nacos 连接失败 → 先执行 deploy-start-services 启动基础设施，核对 env.json」。
- **SAD G-A7 / 脚本体系约束（v0.2.7 起）**：能力划分 可用性检查 → 基础设施一键启动（本任务）→ 后端按序一键启动 → 单服务启动；.ps1/.sh 双平台一致；输出分级与退出码统一。
- **部署顺序与端口（SAD）**：基础设施 MariaDB 3306 / Redis 6379 / Nacos 8848，启动顺序 MariaDB → Redis → Nacos；后端 gateway 9000 → auth 9100 → biz 9200 → system 9400（下游 TASK-008）。
- **issue-list（TASK-001 交付物）**：P5（输出分级与退出码不统一：start-services .ps1 有警告仍 exit 0、icon 空字符；.sh emoji+ANSI）、P6（start-services 未纳入 JDK、Nacos 启动后固定等 8 秒）、P7（双平台启动方式差异：Get-Service/Start-Service vs systemctl/mysqld_safe/redis-server --daemonize；NACOS_HOME 空时错误提示不统一；.sh 第 66 行 `-p'$DB_PASSWORD'` 明文传参在调试模式泄露风险——本任务启动路径不含该命令，但 ping 确认需口令掩码）。
- **PRD F-006/F-007/F-011**：见第 7 节。
- **测试基线**：UT-142-1/2（语法校验）、UT-143-1（双平台成对）重构后须继续满足。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
