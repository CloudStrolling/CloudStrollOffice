# 代码查询报告（TASK-005 新增 deploy-start-all.ps1 / .sh 后端服务按序一键启动）

## 1. 查询范围与结论摘要

本任务为**新增** `deploy/scripts/deploy-start-all.ps1` 与 `deploy/scripts/deploy-start-all.sh`（F-008 后端服务按序一键启动总入口），不修改既有脚本。经本地查询确认：

- deploy 目录下 4 个 jar 包**实际存在**（文件名与任务定义一致），可直接按 `deploy/{jar 名}` 引用；
- 现有单服务启动脚本（deploy-start-gateway/auth/biz/system.ps1/.sh）为**前台阻塞启动**（`exec java` / 直接 `java`），无后台化、无健康确认、无失败即停，本任务必须采用 TASK-004 已确立的 `Start-Process` / `nohup &` 后台化模式；
- TASK-002/003/004 交付的 load-env 模块与 Write-Result/print_result、Test-TcpPort/tcp_port_open、Wait-ServiceUp/wait_for_service 等函数模式均可直接复用（行号见 §4）；
- 健康检查端点契约：各服务 `GET /api/v1/{module}/health`（直连自身端口）；`/api/v1/auth/health` 在网关白名单内（经网关 9000 无 Token 可访问），**biz/system 的 health 不在网关白名单**（经网关需 Token），故本任务应**直连各服务端口探测**；
- `.gitignore` 治理属于 TASK-007 边界，本任务仅记录现状参考（§8）。

## 2. deploy 目录资产清单（实际文件，glob 确认）

| 项目 | 实际路径/内容 | 说明 |
| --- | --- | --- |
| 网关 jar | `deploy/cloudoffice-gateway.jar`（55,688,267 字节） | 端口 9000，统一入口 |
| 认证 jar | `deploy/cloudoffice-auth-service.jar`（75,562,020 字节） | 端口 9100 |
| 企业 jar | `deploy/cloudoffice-biz-service.jar`（58,579,312 字节） | 端口 9200 |
| 系统 jar | `deploy/cloudoffice-system-service.jar`（58,579,748 字节） | 端口 9400 |
| 环境配置 | `deploy/env.json`（实际，2,923 字节）/ `deploy/env.example.json`（841 字节） | load-env 统一加载；env.example.json 共 25 项键 |
| RSA 密钥 | `deploy/keys/`（private_key.der/.pem/_base64.txt、public_key.der/.pem/_base64.txt） | 敏感，不入库（.gitignore 已排除 keys/） |
| 脚本目录 | `deploy/scripts/`（28 个 .ps1/.sh + .gitkeep） | 含 load-env、deploy-check-env、deploy-start-services、4 个单服务启动脚本等 |
| 日志 | `deploy/logs/`（TASK-004 启动时创建，如 nacos-start.log） | .gitignore 已排除 logs/ |
| 部署文档 | `deploy/deploy.md`（17,591 字节）、`deploy/build.md` | 部署顺序/健康检查契约见 §3 |

**env.example.json 键清单**（25 项）：NACOS_ADDR、NACOS_HOME、DB_SERVICE_NAME、DB_PROCESS_NAME、REDIS_SERVICE_NAME、REDIS_PROCESS_NAME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、DB_USER、REDIS_HOST、REDIS_PORT、REDIS_PASSWORD、REDIS_DATABASE、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY、VERIFICATION_CODE_MOCK、VERIFICATION_CODE_EXPIRE_SECONDS、VERIFICATION_CODE_SEND_INTERVAL、VERIFICATION_CODE_LENGTH、PASSWORD_MIN_LENGTH、PASSWORD_MAX_LENGTH、MARIADB_ROOT_PASSWORD、TZ。

## 3. deploy.md 部署顺序 / 健康检查端点契约（本任务编码直接依据）

### 3.1 组件端口表（deploy.md 第 23-28 行）
- cloudoffice-gateway → deploy/cloudoffice-gateway.jar → 9000（统一入口，客户端全部请求经网关转发）
- cloudoffice-auth-service → deploy/cloudoffice-auth-service.jar → 9100
- cloudoffice-biz-service → deploy/cloudoffice-biz-service.jar → 9200
- cloudoffice-system-service → deploy/cloudoffice-system-service.jar → 9400

### 3.2 启动命令与顺序契约（deploy.md 5.6 节，第 141-165 行）
- 启动命令统一 `java -Xms256m -Xmx512m -jar <jar>`（第 158-161 行）；
- 网关统一入口**建议最先启动**（第 146-147 行）；v0.2.6 已验证 4 服务（9000/9100/9200/9400）全部启动成功并注册 Nacos（第 165 行）；
- 命令汇总表（第 194-209 行）：前置检查 deploy-check-env → 基础设施 deploy-start-services → 单服务 deploy-start-gateway/auth/biz/system；**当前无 deploy-start-all 总入口**（本任务新增后 deploy.md 后续由文档任务补充）。

### 3.3 健康检查端点契约（deploy.md 第 8 节，第 211-222 行）
| 检查项 | 方式 | 预期 |
| --- | --- | --- |
| 网关存活 | GET http://<主机>:9000/ | 返回网关响应（404/401 均说明服务在运行） |
| 服务健康检查 | GET http://<主机>:9000/api/v1/auth/health（经网关） | 返回服务名/状态/版本/时间戳，状态正常（v0.2.6 回归 TC-045/TC-046-3 已验证） |

### 3.4 健康端点源码确认（HealthController + 网关白名单）
| 服务 | 完整健康端点（直连自身端口） | 源码位置 | 网关白名单 |
| --- | --- | --- | --- |
| gateway | GET http://localhost:9000/（根路径响应即存活；无 /api/v1/gateway/health） | —— | —— |
| auth | GET http://localhost:9100/api/v1/auth/health | auth-service HealthController.java 类映射第 22 行 @RequestMapping("/api/v1/auth")、第 37-38 行 @GetMapping("/health") | **在**白名单（gateway application.yml 第 57 行 `/api/v1/auth/health`） |
| biz | GET http://localhost:9200/api/v1/biz/health | biz-service HealthController.java 第 28 行 /api/v1/biz、第 41-42 行 /health | **不在**白名单（application.yml 白名单 50-60 行仅 auth 相关） |
| system | GET http://localhost:9400/api/v1/system/health | system-service HealthController.java 第 31 行 /api/v1/system、第 52-54 行 /health | **不在**白名单 |

> **重要提示**：biz/system 的 health 端点经网关（9000）访问需带 Token（网关 AuthFilter 全局认证，白名单外放行需登录态），**本任务健康确认应直连各服务自身端口**（auth/biz/system 探测 `http://localhost:{port}/api/v1/{module}/health`，gateway 探测 `http://localhost:9000/` 根路径返回即可），或端口探测（Test-TcpPort / tcp_port_open）作为备用。

## 4. 可复用模块与函数（含行号）

### 4.1 load-env.ps1 / load-env.sh（TASK-002 已完成，直接复用，不重复实现）
- `deploy/scripts/load-env.ps1`（75 行）：param `[string]$EnvFile = "env.json"`（第 19-21 行）；env.json 缺失提示复制 env.example.json 并 exit 1（第 29-33 行）；ConvertFrom-Json 注入会话环境变量（第 35-45 行）；关键 8 项（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT）缺失逐个列出键名 exit 1（第 47-71 行）；成功仅输出路径与数量（第 74-75 行）。
- **PowerShell 调用方式（dot-source）**：`. "$PSScriptRoot\load-env.ps1"`（各脚本第 15 行一致用法；load-env 内部已兜底 env.json 缺失与关键配置缺失，下游无需重复校验）。
- `deploy/scripts/load-env.sh`（84 行）：`ENV_FILE="${1:-env.json}"`（第 23 行）；缺失 return 1（第 30-34 行）；jq 优先/python3 回退解析并 export（第 37-63 行）；关键 8 项校验（第 67-82 行）。
- **Bash 调用方式（source）**：`source "$SCRIPT_DIR/load-env.sh" || exit $?`（deploy-start-services.sh 第 28 行写法，在 `set -euo pipefail` 下必须 `|| exit $?` 显式透传，load-env 失败用 return 1）。

### 4.2 deploy-check-env.ps1（TASK-003，检测函数模式）
| 函数 | 行号 | 签名/作用 |
| --- | --- | --- |
| Write-Result | 33-40 | `param([string]$Status, [string]$Message)`：按 通过/警告/失败 输出 `[通过]` 绿 / `[警告]` 黄 / `[失败]` 红 并累计 `$script:pass/$script:warn/$script:fail`（F-011 输出分级，不用 emoji） |
| Split-Csv | 43-47 | 逗号分隔字符串转数组（服务名/进程名清单） |
| Test-Installed | 50-62 | 命令/系统服务/进程三重安装检测 |
| Test-TcpPort | 65-78 | `param([string]$HostName, [string]$Port, [int]$TimeoutMs = 1000)`：TcpClient BeginConnect + WaitOne 超时可控端口探测（**本任务端口探测式健康确认可复用**） |
| Test-NacosHttp | 81-86 | Invoke-WebRequest -TimeoutSec 5 响应含 Nacos（**本任务 HTTP 健康探测可参照改造**） |
| Test-NacosJavaProcess | 89-95 | java.exe 命令行含 nacos 辅助判断 |

### 4.3 deploy-check-env.sh（TASK-003，Bash 版对应函数）
| 函数 | 行号 | 签名/作用 |
| --- | --- | --- |
| print_result | 38-45 | `print_result "通过|警告|失败" "message"`：累计 PASS/WARN/FAIL（颜色转义 GREEN/YELLOW/RED，第 35 行定义） |
| split_csv | 48-50 | 逗号分隔转数组 |
| has_cmd | 53 | 命令是否存在 |
| has_svc / has_proc / svc_active | 56-62 / 65-71 / 74-80 | systemd 服务存在 / 进程存在 / 服务活跃 |
| tcp_port_open | 83-95 | `tcp_port_open host port`：/dev/tcp + timeout 1 防挂起（**端口探测备用方案**） |
| nacos_http_ok | 98-100 | `curl -s --max-time 5` 响应含 Nacos（**HTTP 健康探测参照**） |

### 4.4 deploy-start-services.ps1（TASK-004，启动函数模式，与 .sh 同名函数行为一致）
| 函数/模式 | 行号 | 说明 |
| --- | --- | --- |
| Write-Result / Split-Csv / Test-Installed / Test-TcpPort / Test-NacosHttp / Test-NacosJavaProcess | 33-95 | 与 deploy-check-env 相同实现（同源复用） |
| Test-MariaDbUp | 98-105 | 进程/服务/TCP 任一命中 |
| Test-RedisPing | 108-116 | **口令经 REDISCLI_AUTH 传递**（第 109-110 行），命令与日志不出现明文 |
| Test-RedisUp / Test-NacosUp | 117-125 / 128-131 | 运行状态探测 |
| **Wait-ServiceUp（循环探测 + 超时上限）** | 134-143 | `param([scriptblock]$Probe, [int]$TimeoutSeconds = 30, [int]$IntervalSeconds = 2)`：超时上限内每间隔探测，任一命中返回 $true，**不报假成功**；**本任务每服务启动后健康轮询应参照此模式（建议默认重试 30 次、间隔 2 秒、单次超时 3 秒）** |
| Nacos 后台启动（日志落盘） | 309-316 | 先建 `deploy/logs`（New-Item -Force），`Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "`"$nacosStartup`" -m standalone" -WindowStyle Hidden -RedirectStandardOutput $nacosLog -RedirectStandardError $nacosErr -PassThru`（**本任务 .ps1 后台启动 java 的参照：Start-Process -RedirectStandardOutput/-RedirectStandardError**） |
| 汇总与退出码 | 328-347 | 汇总颜色按 fail>0 红 / warn>0 黄 / 否则绿；fail>0 exit 1，warn>0 exit 0 并提示，全过 exit 0（F-011） |

### 4.5 deploy-start-services.sh（TASK-004，Bash 版对应模式）
| 函数/模式 | 行号 | 说明 |
| --- | --- | --- |
| print_result / tcp_port_open / nacos_http_ok | 37-44 / 82-94 / 97-99 | 同 deploy-check-env.sh |
| redis_ping_ok | 102-105 | REDISCLI_AUTH 口令传递 |
| probe_mariadb_up / probe_redis_up / probe_nacos_up | 108-113 / 116-122 / 125-129 | 运行状态探测 |
| **wait_for_service（循环探测 + 超时上限）** | 132-140 | `wait_for_service <函数名> [timeout=30] [interval=2]`：`while [ "$elapsed" -lt "$timeout" ]` 循环调用探测函数（**本任务 .sh 健康轮询参照**） |
| Nacos 后台启动 | 313-317 | `LOG_DIR="$PROJECT_DIR/logs"; mkdir -p "$LOG_DIR"`；`nohup bash "$NACOS_STARTUP" -m standalone >"$LOG_DIR/nacos-start.log" 2>&1 &`（**本任务 .sh 后台启动 java 的参照：nohup ... > log 2>&1 &，并应 echo $! 记录 PID**） |
| 汇总与退出码 | 325-343 | 同 .ps1 约定 |

## 5. 现有单服务启动脚本现状（deploy-start-gateway/auth/biz/system，TASK-010 才重构，本任务仅读取参考）

> 均为**前台阻塞启动**（.ps1 直接 `java`、.sh `exec java`），无后台化、无健康确认、无失败即停；本任务必须在总入口中自行后台化启动并健康确认。可参考其关键变量校验项清单。

### 5.1 deploy-start-gateway（Windows / Linux）
- .ps1（52 行）：JarPath 第 12 行；dot-source load-env 第 15 行；校验 NACOS_ADDR（18-22）、RSA_PUBLIC_KEY（24-28）、jar 存在（30-34）；启动 `java -Xms256m -Xmx512m -jar "$JarPath"`（第 49 行，前台）。
- .sh（61 行）：JAR_PATH 第 14 行；source load-env 第 17 行；校验 NACOS_ADDR（20-23）、RSA_PUBLIC_KEY（25-29）、jar（31-35）；`exec java -Xms256m -Xmx512m -jar`（59-61，前台阻塞）。
- **gateway 关键校验项：NACOS_ADDR、RSA_PUBLIC_KEY**（与任务定义一致）。

### 5.2 deploy-start-auth（Windows / Linux）
- .ps1（59 行）：JarPath 第 12 行；requiredVars 数组（18-19）：NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY；缺失逐个列出（22-35）；jar 校验（37-41）；启动第 57 行。
- .sh（75 行）：REQUIRED_VARS（21-22）同左；缺失校验（25-39）；jar（41-45）；exec java（73-75）。
- **auth 关键校验项：NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD**（与任务定义一致）。

### 5.3 deploy-start-biz（Windows / Linux）
- .ps1（43 行）：JarPath 第 12 行；校验 NACOS_ADDR（18-22）、jar（24-28）；启动第 41 行。
- .sh（60 行）：校验 NACOS_ADDR（21-24）、**DB_PASSWORD（26-29）**；jar（31-35）；exec java（58-60）；注释第 20、49-54 行明确 **biz 使用 DB_USER 环境变量（非 DB_USERNAME）**。
- **biz 关键校验项：NACOS_ADDR、DB_PASSWORD**（与任务定义一致）。

### 5.4 deploy-start-system（Windows / Linux）
- .ps1（43 行）：结构同 biz（JarPath 12；NACOS_ADDR 18-22；jar 24-28；启动 41）。
- .sh（58 行）：校验 NACOS_ADDR（20-23）、**DB_PASSWORD（25-28）**；jar（30-34）；exec java（56-58）；结构同 biz（第 48 行注释）。
- **system 关键校验项：NACOS_ADDR、DB_PASSWORD**（与任务定义一致）。

## 6. 本任务新增脚本（deploy-start-all.ps1 / .sh）复用要点与注意事项

### 6.1 核心流程（对照 F-008 业务规则与 TASK-004 模式）
1. **加载配置**：.ps1 `. "$PSScriptRoot\load-env.ps1"`；.sh `source "$SCRIPT_DIR/load-env.sh" || exit $?`（set -e 下显式透传）。
2. **前置校验（任一缺失→列出缺失项+处理提示→非零退出→不启动任何服务）**：
   - 4 个 jar：`deploy/cloudoffice-gateway.jar`、`deploy/cloudoffice-auth-service.jar`、`deploy/cloudoffice-biz-service.jar`、`deploy/cloudoffice-system-service.jar`（Test-Path / [ -f ]，可参考单服务脚本 30-34 行模式）；
   - 关键变量：gateway → NACOS_ADDR、RSA_PUBLIC_KEY；auth → NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD；biz/system → NACOS_ADDR、DB_PASSWORD（可参考 auth 脚本 requiredVars 数组模式，第 18-35 行）。
3. **按序启动 + 逐服务健康确认**（gateway → auth → biz → system）：
   - 启动命令 `java -Xms256m -Xmx512m -jar <jar>`（可从 JarPath 同目录 `java`，无需绝对路径；JAVA_HOME 已由 load-env/环境就绪）；
   - **Windows**：`Start-Process -FilePath "java" -ArgumentList "-Xms256m","-Xmx512m","-jar","$JarPath" -WindowStyle Hidden -RedirectStandardOutput $log -RedirectStandardError $err -PassThru`（参照 deploy-start-services.ps1 第 316 行 cmd 后台化写法，注意 -ArgumentList 数组传参避免引号问题）；日志落位 `deploy/logs/{module}-start.{log,err}`（目录 New-Item -Force，参照第 310-313 行）；
   - **Linux**：`nohup java -Xms256m -Xmx512m -jar "$JAR_PATH" >"$LOG_DIR/{module}-start.log" 2>&1 &`，紧跟 `echo $!` 记录 PID（参照 deploy-start-services.sh 第 317 行）；
   - **健康确认**（首选 HTTP 直连各服务端口，端口探测备用）：
     - gateway：`http://localhost:9000/` 返回任何 HTTP 响应（Invoke-WebRequest 不抛错 / curl 返回码 0）即存活；或 Test-TcpPort 9000；
     - auth/biz/system：`http://localhost:{9100|9200|9400}/api/v1/{auth|biz|system}/health`（Invoke-WebRequest -TimeoutSec 3 / curl -s --max-time 3，参照 Test-NacosHttp / nacos_http_ok，第 81-86 行 / 98-100 行）；
     - 循环轮询：Wait-ServiceUp / wait_for_service 模式（**建议默认重试 30 次、间隔 2 秒、单次超时 3 秒，可配置**，参照 §4.4/§4.5）。
4. **失败即停**：任一服务前置校验失败或启动后健康确认超时 → 输出明确错误提示（端口被占用提示"请检查 9000/9100/9200/9400"，gateway 失败提示"请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置"，auth 失败提示"请检查 RSA 密钥对/DB_PASSWORD 配置"）→ 停止后续启动 → 退出非零（exit 1）。
5. **汇总输出**：4 个服务的启动结果与健康状态汇总（[通过]/[警告]/[失败] + 颜色 + 计数），全部成功退出 0。

### 6.2 注意事项（安全与规范，F-011 / project.md）
- **口令/密钥不得打印明文**：DB_PASSWORD、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY 等仅校验非空，缺失校验只输出键名（load-env 与既有脚本一致做法）；不输出 java 启动命令行到日志（或日志仅掩码）。
- 输出分级不用 emoji：`[通过]`（绿）/`[警告]`（黄）/`[失败]`（红），颜色仅 .ps1 用 -ForegroundColor、.sh 用转义序列（第 35 行 GREEN/YELLOW/RED）。
- 退出码约定：全部通过 0；失败 1；参数错误可细化 2。
- 文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明；版本号统一 v0.2.7；简体中文注释；.ps1 加 .SYNOPSIS/.DESCRIPTION 注释块（参照 deploy-start-services.ps1 第 1-21 行）。
- 日志与 PID 落位 `deploy/logs/`（.gitignore 已排除 logs/、*.log），PID 文件（如 *.pid）如生成需注意 .gitignore（现状无 *.pid 规则，TASK-007 治理范畴）。
- .ps1 与 .sh 行为一致、可独立验证（语法校验 + 契约自校验）。

## 7. 其他相关代码（供参考）
- 网关白名单：`cloudoffice-gateway/src/main/resources/application.yml` 第 50-60 行（white-list：login/register/refresh/logout/health/verification-code/password 等）；第 24-32 行路由 Path=/api/v1/{auth|biz|system}/**。
- 各服务 HealthController：auth `@RequestMapping("/api/v1/auth")`（第 22 行）+ `@GetMapping("/health")`（37-38 行）；biz `/api/v1/biz`（28 行）+ `/health`（41-42 行）；system `/api/v1/system`（31 行）+ `/health`（52-54 行）。健康响应体为 ApiResult<Map>（服务名/状态/版本/时间戳）。
- 前端 API 基址：`http://localhost:9000`（main.dart.js 编译产物，网关统一入口，佐证 gateway 最先启动契约）。

## 8. .gitignore 现状（参考；治理任务归 TASK-007，本任务不修改）

根目录 `.gitignore`（332 行）已有：
- Java/Maven：`target/`（224 行）、`*.class`、`*.jar`、`*.war`（232-234 行）——**deploy 下 4 个 jar 已被 *.jar 排除**；
- 日志/临时：`*.log`、`logs/`、`log/`（290-292 行）——**deploy/logs/ 已被 logs/ 排除**；`tmp/`、`temp/`、`.cache/`（298-300 行）；
- 环境密钥：`keys/`（319 行）、`env.json`（320 行）；
- 客户端产物：`deploy/cloudoffice-flutter-app/web/*`、`windows/*`（283-286 行，保留 .gitkeep）；
- 数据库：`*.db`、`*.sqlite`、`*.sqlite3`（294-296 行）。

**与本任务相关的注意点**：本任务生成的后端服务日志（deploy/logs/*.log）与 *.jar 已在忽略范围；若新增 PID 文件（*.pid）或临时探测文件，需由 TASK-007 补充规则；当前无 *.pid 条目。

## 9. 查询结论（供编码直接使用）
1. **新增文件**：`deploy/scripts/deploy-start-all.ps1`、`deploy/scripts/deploy-start-all.sh`，不修改任何既有脚本。
2. **jar 引用**：`$ProjectDir/cloudoffice-gateway.jar` 等（`$ProjectDir = Split-Path -Parent $PSScriptRoot` / `PROJECT_DIR="$(dirname "$SCRIPT_DIR")"`，deploy 即 scripts 的父目录）。
3. **加载配置**：.ps1 dot-source load-env.ps1；.sh `source load-env.sh || exit $?`（set -euo pipefail）。
4. **启动**：Windows `Start-Process java -ArgumentList ... -RedirectStandardOutput/-RedirectStandardError`；Linux `nohup java -Xms256m -Xmx512m -jar <jar> > logs/{module}-start.log 2>&1 &` + PID 记录。
5. **健康确认**：gateway GET http://localhost:9000/；auth/biz/system GET http://localhost:{port}/api/v1/{module}/health；循环轮询参照 Wait-ServiceUp / wait_for_service（默认重试 30 次、间隔 2 秒、单次超时 3 秒，可配置参数）。
6. **输出与退出码**：Write-Result / print_result 三级输出；全部成功 exit 0，任一失败即停 exit 1。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
