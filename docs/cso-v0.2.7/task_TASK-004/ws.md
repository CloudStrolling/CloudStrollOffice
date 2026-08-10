# 网络资料查询结果（TASK-004 重构 deploy-start-services.ps1 / .sh 基础设施运行状态检查与一键启动）

## 0. 查询结论摘要

本任务为 v0.2.7 部署脚本重构的 **F-006（运行状态检测）与 F-007（未启动基础设施一键启动）落地任务**。经查询 PowerShell Start-Service / Start-Process（Microsoft Learn 官方）、systemctl（freedesktop systemd 官方）、MariaDB（MariaDB 官方 / MySQL 官方）、Redis（redis.io 官方 / MSOpenTech Windows 移植）、Nacos 2.x（nacos.io 官方）、nohup（man7 官方）等权威资料，确认：

- **Windows 系统服务启动**：`Start-Service -Name <服务名>` 是官方标准方式，仅 Windows 平台，需管理员权限，服务已运行时不报错（天然幂等）；`Start-Process` 官方支持 `-PassThru/-RedirectStandardOutput/-WindowStyle` 等参数，可用于可执行文件后台启动与 Nacos `startup.cmd` 静默启动；
- **Linux 系统服务启动**：`systemctl start <服务名>` 为标准方式，需 root/sudo；**关键坑**：systemd `Type=simple` 服务即使二进制启动失败 `systemctl start` 也可能返回成功——官方文档明确说明，这正是"启动后再次探测确认、不得报假成功"的必要性依据；
- **MariaDB/Redis Windows 服务**：`mysqld.exe --install`（MariaDB 10.4+ 默认服务名 "MariaDB"、10.3- 为 "MySQL"）与 `redis-server --service-install` 注册为系统服务后，均可用 `Start-Service` / `sc start` 启动；启动命令需管理员权限；
- **Redis 后台启动**：Linux 官方支持 `redis-server --daemonize yes` 后台守护；Windows 无官方原生版（社区 tporadowski/redis 5.0.x / Memurai），脚本依赖 env.json 服务/进程名清单检测，不绑定具体发行版；
- **Nacos 2.x 启动**：官方标准命令为 Linux `sh startup.sh -m standalone`（或 `bash startup.sh -m standalone`）、Windows `startup.cmd -m standalone`；`-m standalone` 为单机模式参数；依赖 JDK 1.8+（本项目 Java 21 满足）；需配置 `JAVA_HOME`；启动成功标志为日志输出 "Nacos started successfully in stand alone mode."；官方推荐 2C4G 60G 机器配置；
- **后台进程与日志落盘**：Linux 用 `nohup <cmd> > <日志文件> 2>&1 &` 免疫 SIGHUP 并留存日志；Windows 用 `Start-Process` 的 `-RedirectStandardOutput/-RedirectStandardError` 将 Nacos/可执行文件日志重定向到 `deploy/logs/`，便于失败定位且不阻塞主流程；
- **循环探测 + 超时上限**：启动后进入 30 秒上限、每 2 秒一次的循环探测（进程/TCP/HTTP），任一命中即确认成功输出"通过"；超时输出"警告/失败"并给出处理建议（等待重试/手动检查/权限提示），不报假成功。

**版本兼容性总体结论**：所查询官方资料与当前项目版本（PowerShell 5.1/7.x、MariaDB 10.6、Redis 7.2.x、Nacos 2.3、Java 21）均兼容，无阻断性差异；详细核对见第 6 节。

---

## 1. 查询范围与资料清单

| 编号 | 主题 | 资料源 | 权威性 | 本任务用途 |
| --- | --- | --- | --- | --- |
| R1 | PowerShell `Start-Service` | Microsoft Learn（PowerShell 7.7 文档） | 官方 | .ps1 系统服务启动 MariaDB/Redis |
| R2 | PowerShell `Start-Process` | Microsoft Learn（PowerShell 7.7 文档） | 官方 | .ps1 可执行文件后台启动、Nacos startup.cmd 启动、日志重定向 |
| R3 | `systemctl` 服务管理 | freedesktop.org systemd 官方手册 | 官方 | .sh 系统服务启动 MariaDB/Redis、is-active 判定 |
| R4 | MariaDB Windows 服务注册/启动 | MariaDB 官方 + MySQL 8.1/8.4 官方 Reference Manual | 官方 | Windows 服务名约定（MariaDB/MySQL）、mysqld --install、sc start |
| R5 | MariaDB Linux 启动 | MariaDB 官方 Starting & Stopping / systemd | 官方 | systemctl start mariadb、mariadbd-safe、sysVinit service 命令 |
| R6 | Redis Windows 服务 | MSOpenTech/ServiceStack 文档（Redis Windows 移植） | 官方移植文档 | `redis-server --service-install/--service-start` 等 |
| R7 | Redis `daemonize` 后台启动 | redis.io 官方文档 + 官方 redis.conf | 官方 | Linux `redis-server --daemonize yes` |
| R8 | Nacos 2.x 启动命令 | nacos.io 官方快速开始 | 官方 | `startup.sh/startup.cmd -m standalone` 启动参数 |
| R9 | nohup 后台运行 | man7.org nohup(1) 官方手册 | 官方 | .sh 后台启动 Nacos/可执行文件并留日志 |
| R10 | 健康探测/启动超时 | systemd 官方（Type=simple 语义）+ 综合资料 | 官方/经验 | 启动后再探测、循环轮询 + 超时上限设计依据 |

---

## 2. PowerShell Start-Service 与 Start-Process（R1/R2，Microsoft Learn 官方）

### 2.1 Start-Service

- **语法**：`Start-Service [-Name] <String[]> [-PassThru]`（亦支持 `-InputObject` / `-DisplayName`）；
- **平台**：仅 Windows 平台可用；
- **权限**：需要管理员（elevated）权限，非管理员执行会报 "Cannot start service"；
- **幂等性**：若服务已在运行，启动消息被忽略且不报错——满足"已运行幂等跳过"需求；
- **输出**：默认无输出，加 `-PassThru` 返回服务对象（可用 `(Start-Service -Name X -PassThru).Status` 确认状态）；
- **已确认的失败场景**：服务启动类型为 Disabled 时启动失败（需先 `Set-Service <name> -StartupType manual`）；此场景可在脚本中捕获并给出处理建议；
- **推荐写法**（官方 Example 1/3）：
  ```powershell
  Start-Service -Name "eventlog"                        # 按服务名启动
  Get-Service -Name w32time | Start-Service -PassThru   # 管道 + 返回对象
  ```
- **与 `Get-Service` 配合**：`Get-Service -Name <svc>` 返回 `Status`（Running/Stopped）、`StartType` 等，用于启动前/后判定。

### 2.2 Start-Process

- **语法**（Default 参数集）：
  ```powershell
  Start-Process [-FilePath] <string> [[-ArgumentList] <string[]>]
    [-WorkingDirectory <string>] [-NoNewWindow] [-PassThru]
    [-RedirectStandardError <string>] [-RedirectStandardOutput <string>]
    [-WindowStyle <ProcessWindowStyle>] [-Wait] [-Environment <hashtable>]
  ```
- **默认行为**：异步启动（立即返回控制权）——适合"启动后进入循环探测"；
- **-PassThru**：返回进程对象（可记录 PID 供后续探测）；
- **-RedirectStandardOutput / -RedirectStandardError**：将 stdout/stderr 重定向到文件——适合将 Nacos `startup.cmd` 与可执行文件启动日志落盘到 `deploy/logs/`；
- **-WindowStyle Hidden**：隐藏启动窗口（避免 Nacos 启动黑框），注意不能与 `-NoNewWindow` 同时使用；
- **-Environment**（PS 7.x）：为子进程设置环境变量（如 `REDISCLI_AUTH`、`JAVA_HOME`）；
- **执行 .cmd/.bat 的注意事项**（排错经验）：
  - `Start-Process -FilePath "xxx.cmd"` 在部分场景下会新开窗口/一闪而过，且 .cmd 文件可能报 "not a valid Win32 application"；
  - 稳妥做法：`Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"<NACOS_HOME>\bin\startup.cmd`" -m standalone" -WindowStyle Hidden -RedirectStandardOutput <日志> -RedirectStandardError <日志> -PassThru`；
  - 需要管理员权限执行时可用 `-Verb RunAs`（.cmd 支持 RunAs verb），但会触发 UAC 弹窗，脚本内需提示用户以管理员身份运行。

---

## 3. systemctl 服务启动（R3，freedesktop systemd 官方）

- **启动服务**：`systemctl start <unit>`（unit 可省略 `.service` 后缀），需 root 权限（脚本中 `sudo systemctl start <unit>`）；
- **状态判定（适合脚本）**：
  - `systemctl is-active <unit>` → 输出 `active` / `inactive` / `failed`，可用 `systemctl is-active --quiet <unit>` + `$?` 判定；
  - `systemctl list-units --type=service --all` 检查服务是否存在；
  - `systemctl is-enabled <unit>` 检查是否开机自启；
- **⚠️ 关键坑（官方文档明确）**：systemd `Type=simple`（默认）的服务，`systemctl start` 在进程 `fork()` 后即视为已启动并返回成功——**即使服务二进制实际无法运行（如 User 不存在、可执行文件缺失），`systemctl start` 也可能返回成功**。这直接佐证本任务"启动后必须再次探测确认（进程/TCP/HTTP），不得仅凭 systemctl 返回码报成功"的设计；
- **Type=forking / notify** 的服务则等主进程 fork 退出 / 收到 READY=1 才返回，但对 MariaDB/Redis 常见 Type 不统一，统一采用"启动 + 再探测"最稳妥；
- **旧版 sysVinit 兼容**：无 systemd 的发行版用 `service <name> start` / `chkconfig`；脚本可先 `command -v systemctl` 探测，无 systemctl 时回退 `service` 命令；
- **日志查看**：`journalctl -u <unit>`（启动失败排查）；
- **权限**：`sudo systemctl start` 失败常见原因为当前用户不在 sudoers / 服务被 mask；脚本应保留 `2>&1` 错误输出供用户定位，并提示 `sudo` 权限。

---

## 4. MariaDB / Redis 启动方式（R4-R7）

### 4.1 MariaDB Windows（R4，MariaDB 官方 + MySQL 官方）

- **服务名约定**：
  - MSI 安装：MariaDB 10.4+ 默认服务名 **"MariaDB"**；10.3 及以前为 **"MySQL"**；
  - `mysqld.exe --install` 安装的服务默认名在所有版本均为 **"MySQL"**（可 `--install <自定义名>` 指定）；
  - 本项目 env.json 默认服务名清单 `DB_SERVICE_NAME = "MySQL, MariaDB"` 正好覆盖两种情形；
- **注册为服务**（不启动）：`"C:\Program Files\MariaDB 10.x\bin\mysqld" --install [服务名]`；`--install-manual` 为手动启动类型；`--remove` 移除服务；
- **启动服务**（三选一）：`Start-Service <服务名>` / `sc start <服务名>` / `NET START <服务名>`（均需管理员）；
- **前台/调试启动**：`mysqld --console`（控制台直接运行，前台占用窗口）；
- **后台启动（非服务模式）**：`Start-Process -FilePath "<bin>\mysqld.exe" -ArgumentList "--defaults-file=<my.ini>" -PassThru`（Windows）/ `start /B mysqld --defaults-file=...`（cmd）；
- **失败排查**：服务方式启动失败查看数据目录下 `*.err` 日志文件；常见原因端口被占用（`netstat -ano | findstr "3306"`）；
- **权限**：安装/启动服务必须在管理员 shell；非管理员执行报 `OpenSCManager failed (5)`（ERROR_ACCESS_DENIED）。

### 4.2 MariaDB Linux（R5，MariaDB 官方）

- **systemd 发行版**（RHEL/CentOS 7+、Debian 8+、Ubuntu 15.04+）：
  - 服务名：`mariadb`（yum/apt 安装）或 `mysql`（老命名）；
  - `sudo systemctl start mariadb` / `sudo systemctl is-active mariadb`；
  - 启用自启：`sudo systemctl enable mariadb`；
- **sysVinit 发行版**（CentOS 6-、Debian 7-）：`service mariadb start`（或 `service mysql start`）；
- **可执行文件直接启动（兜底）**：`mariadbd`（新名）或 `mysqld`（旧名），推荐用 `mariadbd-safe` 包装脚本（具备崩溃自动重启、日志落 syslog 等保护）：`mysqld_safe --datadir=/var/lib/mysql &`；
- **本项目 .sh 兜底分支**：遍历 env.json `DB_PROCESS_NAME` 清单（`mysqld, mariadbd`），找到可执行文件后用 `nohup <exe> &` 或 `mysqld_safe ... &` 后台启动，随后循环探测 TCP 3306。

### 4.3 Redis Windows（R6，MSOpenTech/ServiceStack 文档）

- **注意**：Redis 官方不提供 Windows 原生支持（推荐 WSL 或 Memurai）；Windows 常见发行版为 MicrosoftArchive/redis（3.2）、tporadowski/redis（5.0.x）等，均支持以下服务参数；
- **注册服务**（不启动，需管理员）：`redis-server --service-install redis.windows.conf --loglevel verbose`；服务以 `NT AUTHORITY\NetworkService` 运行、Autostart；
- **启动服务**：`redis-server --service-start`（PowerShell 中亦可 `Start-Service Redis`）；
- **停止/卸载**：`redis-server --service-stop` / `redis-server --service-uninstall`；
- **多实例命名**：`--service-name <name>`（可配合 `--port`）；
- **普通后台启动**：`Start-Process -FilePath "<bin>\redis-server.exe" -ArgumentList "<redis.windows.conf>" -WindowStyle Hidden -PassThru`；
- **确认**：`redis-cli -h <host> -p <port> ping` 返回 `PONG`（有口令时经 `REDISCLI_AUTH` 环境变量传递，见第 8 节口令掩码）；
- **权限**：服务参数命令需要 elevated context（非管理员会触发 UAC）。

### 4.4 Redis Linux daemonize（R7，redis.io 官方）

- **后台守护启动**：`redis-server --daemonize yes`（命令行参数）或配置文件 `daemonize yes`；
- **默认端口**：6379；默认非后台（前台运行）；
- **⚠️ 与 systemd 的冲突**：systemd 托管下应保持 `daemonize no`（官方 redis.conf 注释明确："When Redis is supervised by upstart or systemd, this parameter has no impact"；且 Type=notify 服务 daemonize yes 会导致 `Failed with result 'protocol'`）；
- **本任务 .sh 兜底分支**：在非 systemd 服务（systemctl 无该服务）场景用 `nohup redis-server --daemonize yes >/dev/null 2>&1 &`（daemonize 后主进程退出，nohup 仅保护守护进程不受 SIGHUP）或 `redis-server --daemonize yes`；
- **确认**：`redis-cli -h <host> -p <port> ping` 返回 `PONG`。

---

## 5. Nacos 2.x 启动（R8，nacos.io 官方）

- **Windows**：进入 `$NACOS_HOME\bin` 执行 `startup.cmd -m standalone`（standalone 代表单机模式，非集群）；
- **Linux/Unix/Mac**：`sh startup.sh -m standalone`；Ubuntu 或符号链接报错时用 `bash startup.sh -m standalone`；
- **集群模式**：不带 `-m` 直接执行 `startup.sh`（需要 cluster.conf，本项目单机部署用 standalone）；
- **关闭**：`shutdown.sh` / `shutdown.cmd`；
- **前置依赖**：
  - JDK 1.8+，**必须配置 `JAVA_HOME` 环境变量**（startup 脚本按 JAVA_HOME 定位 java）；本项目 Java 21 满足"1.8+"要求；
  - 官方建议至少 2C4G 60G 机器配置（开发机可适当降低）；
  - Nacos 2.2.0.1/2.2.1 及 2.3 建议配置 `nacos.core.auth.plugin.nacos.token.secret.key`（生产必改，测试可用默认值）；
- **启动成功标志**：日志输出 "Nacos started successfully in stand alone mode."；控制台 `http://<host>:8848/nacos`（默认账号 nacos/nacos）；
- **启动日志位置**：`$NACOS_HOME/logs/start.out`（Windows 亦为 logs/start.out）；
- **HTTP 健康探测**：访问 `http://<NACOS_ADDR>/nacos/` 页面响应含 "Nacos" 即视为可用（本任务沿用 TASK-003 `Test-NacosHttp` / `nacos_http_ok` 契约）；
- **常见失败**：端口 8848 被占用（改 `conf/application.properties` 的 `server.port`）、JAVA_HOME 未配置、内存不足（JVM 参数在 startup 脚本 `JVM_XMS/JVM_XMX`）。

---

## 6. 版本兼容性核对（步骤 5 结论）

| 组件 | 项目版本（env.json/SAD） | 资料版本 | 兼容性结论 | 备注 |
| --- | --- | --- | --- | --- |
| PowerShell | Windows 平台（系统自带 5.1，脚本兼容 5.1+/7.x） | 官方 7.7 文档 | ✅ 兼容 | `Start-Service -PassThru`、`Start-Process -RedirectStandardOutput/-WindowStyle/-PassThru` 均为 5.1 已支持参数；避免使用 7.x 独有语法（如 `-Environment` 7.4+，可用 `$env:REDISCLI_AUTH=` 替代） |
| MariaDB | 10.6 | MariaDB 当前官方 + MySQL 8.1/8.4 | ✅ 兼容 | 10.4+ 默认服务名 "MariaDB"；`mysqld --install` 默认名 "MySQL"；进程名 `mysqld`/`mariadbd` 均可能出现——env.json 默认清单已覆盖 |
| Redis | 7.2.x（Linux）；Windows 端无官方原生版 | redis.io 官方（daemonize）；MSOpenTech Windows 移植 | ⚠️ 注意 | Linux 7.2 支持 `--daemonize yes`；Windows 端实际部署为社区版（tporadowski 5.0.x 等）仍支持 `--service-install/--service-start`；脚本不绑定具体版本，仅按 env.json 服务/进程名清单检测启动 |
| Nacos | 2.3 | nacos.io 快速开始（2.X） | ✅ 兼容 | `-m standalone` 参数在 1.x/2.x 一致；2.3 依赖 JDK 1.8+，本项目 Java 21 满足；官方快速开始推荐稳定版 2.2.3，2.3.x 属受支持范围 |
| Java | 21（后端） | Nacos 要求 JDK 1.8+ | ✅ 兼容 | JDK 仅做可用性检查不启动（F-006）；Nacos 需 JAVA_HOME 已配置 |
| systemd | Linux 部署主机 | freedesktop 官方手册 | ✅ 兼容 | `systemctl start/is-active` 为各发行版通用接口；脚本需兼容无 systemd 的 sysVinit（`service` 命令回退） |

---

## 7. 启动后健康探测轮询与超时处理（R10，设计依据）

### 7.1 轮询探测模式（推荐：超时上限 30s、间隔 2s）

- **PowerShell 参考**：
  ```powershell
  $timeout = 30; $interval = 2; $elapsed = 0
  $started = $false
  while ($elapsed -lt $timeout) {
      if (Test-TcpPort -HostName $env:DB_HOST -Port $env:DB_PORT) { $started = $true; break }
      Start-Sleep -Seconds $interval
      $elapsed += $interval
  }
  if ($started) { Write-Result "通过" "..." } else { Write-Result "警告" "启动超时..." }
  ```
- **Bash 参考**：
  ```bash
  timeout=30; interval=2; elapsed=0
  started=false
  while [ "$elapsed" -lt "$timeout" ]; do
      if tcp_port_open "$DB_HOST" "$DB_PORT"; then started=true; break; fi
      sleep "$interval"; elapsed=$((elapsed + interval))
  done
  ```
- **探测方式与目标对应**（沿用 TASK-003 函数）：
  - MariaDB：进程（`Get-Process $dbProcName` / `pgrep -x`）→ 系统服务 Running（`Get-Service` / `svc_active`）→ TCP 3306（`Test-TcpPort` / `tcp_port_open`）任一命中；
  - Redis：进程 / 服务 / TCP 6379 → 再以 `redis-cli ping` 返回 PONG 为准（带 `-h/-p` 与 REDISCLI_AUTH）；
  - Nacos：HTTP `http://NACOS_ADDR/nacos/` 含 "Nacos"（`Test-NacosHttp` / `nacos_http_ok`）为主 + java 进程含 nacos（`Test-NacosJavaProcess` / `pgrep -f nacos`）辅助。

### 7.2 超时/失败处理（不报假成功）

- **输出"警告/失败"** 并给出处理建议：
  - 权限问题：提示"请以管理员身份运行（Windows）/ 使用 sudo（Linux）"；
  - 超时：提示"等待数秒后重试，或手动检查服务状态与日志"（MariaDB `*.err`、Redis 日志、Nacos `logs/start.out`、systemd `journalctl -u <unit>`）；
  - 端口占用：提示 `netstat -ano | findstr <端口>` / `ss -ltnp | grep <端口>` 排查；
- **不报假成功**：仅凭 `Start-Service`/`systemctl start` 命令返回码不足以判定成功（尤其 systemd Type=simple，见 R3 关键坑），必须经"再探测"确认后才输出"通过"；
- **幂等**：已运行服务直接跳过输出"已运行"，不重复启动。

---

## 8. 口令掩码与敏感信息规范（F-007 / F-001 契约）

- **DB_PASSWORD**：启动路径本身不传口令（系统服务/可执行文件启动不需要）；若检测命令用到，采用数组参数方式 `-p"$env:DB_PASSWORD"`（PowerShell）/ 数组 `cmd=(... -p"$DB_PASSWORD" ...); "${cmd[@]}"`（Bash），命令输出 `2>&1` 重定向不落屏，日志只显示 `****`；
- **REDIS_PASSWORD**：redis-cli 连接一律经环境变量传递——PowerShell `if (-not [string]::IsNullOrEmpty($env:REDIS_PASSWORD)) { $env:REDISCLI_AUTH = $env:REDIS_PASSWORD }`；Bash `if [ -n "${REDIS_PASSWORD:-}" ]; then export REDISCLI_AUTH="$REDIS_PASSWORD"; fi`；命令与日志均不得出现明文；
- **日志落盘**：Nacos 启动日志重定向到 `deploy/logs/` 时，确保启动命令不含明文口令（startup.cmd 不接收口令参数，无泄露风险）；
- **禁止**：不得在输出/日志/调试回显中打印 DB_PASSWORD、REDIS_PASSWORD、RSA_PRIVATE_KEY 等敏感值。

---

## 9. 对本任务编码的落地建议（供 code 步骤使用）

1. **.ps1 服务启动**：MariaDB/Redis 遍历 env.json 服务名清单（`Split-Csv $env:DB_SERVICE_NAME`），先 `Get-Service -Name <svc>` 判存在与 Running，未运行 `Start-Service -Name <svc>`（管理员权限，失败捕获错误并提示）；
2. **.ps1 可执行文件启动**：遍历 `DB_PROCESS_NAME`/`REDIS_PROCESS_NAME` 清单，`Start-Process -FilePath <exe> -PassThru`（Redis 可用 `-WindowStyle Hidden`），随后循环探测；
3. **.ps1 Nacos 启动**：`Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$env:NACOS_HOME\bin\startup.cmd`" -m standalone" -WindowStyle Hidden -RedirectStandardOutput <logs\nacos-start.log> -RedirectStandardError <logs\nacos-start.err> -PassThru`，随后循环 HTTP 探测（30s/2s）；
4. **.sh 服务启动**：遍历 `DB_SERVICES`/`REDIS_SERVICES` 数组，`sudo systemctl start <svc>`（捕获 `2>&1` 错误，失败提示权限），无 systemctl 时回退 `service <svc> start`；
5. **.sh 可执行文件启动**：MariaDB `nohup <exe> >/dev/null 2>&1 &`（或 `mysqld_safe ... &`）；Redis `redis-server --daemonize yes`（`nohup` 包裹防 SIGHUP）；
6. **.sh Nacos 启动**：`nohup bash "$NACOS_HOME/bin/startup.sh" >"$PROJECT_DIR/logs/nacos-start.log" 2>&1 &`（保留日志便于定位），随后循环 HTTP 探测；
7. **JDK**：仅输出可用性结论（`java -version` + `JAVA_HOME` + 版本 21），不执行启动（F-006）；
8. **启动顺序**：MariaDB → Redis → Nacos（SAD 契约）；未安装服务不启动、输出"未安装，请先安装"计入失败、继续后续服务（F-007）；
9. **汇总与退出码（F-011）**：`[通过]/[警告]/[失败]` 文本前缀 + 颜色（不用 emoji）；fail>0 → exit 1；warn>0 → exit 0 并提示；全通过 → exit 0；全部可达输出"可启动后端服务"；
10. **文件头**：SPDX-License-Identifier（Apache-2.0）+ 版权声明 + 版本 v0.2.7；简体中文注释。

---

## 10. 参考链接汇总

- PowerShell Start-Service：https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-service
- PowerShell Start-Process：https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process
- systemd.service 手册：https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html
- systemd 手册首页：https://www.freedesktop.org/software/systemd/man/
- MariaDB Starting & Stopping：https://mariadb.com/docs/server/server-management/starting-and-stopping-mariadb/
- MariaDB Windows MSI 安装（服务名约定）：https://mariadb.com/docs/server/server-management/install-and-upgrade-mariadb/installing-mariadb/binary-packages/installing-mariadb-msi-packages-on-windows
- MySQL Starting as Windows Service：https://dev.mysql.com/doc/refman/8.1/en/windows-start-service.html
- Redis 官方文档（Linux 安装/WSL）：https://redis.io/docs/latest/operate/oss_and_stack/install/
- Redis Windows 服务（MSOpenTech 移植文档）：https://docs.servicestack.net/install-redis-windows
- Nacos 快速开始：https://nacos.io/zh-cn/docs/quickstart/quick-start
- Nacos 部署手册（standalone）：https://nacos.io/docs/latest/guide/admin/deployment/
- nohup(1) 官方手册：https://man7.org/linux/man-pages/man1/nohup.1.html

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
