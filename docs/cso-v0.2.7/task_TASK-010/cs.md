# 代码查询报告（#TASK-010 全量脚本契约与双平台行为总体验证）

> 由 impm-task-coding-cs 技能执行（CS），查询时间 2026-08-10。查询范围：deploy/scripts 全部 24 个脚本（12 对 .ps1/.sh）+ .gitkeep、deploy 目录资产、PRD v0.2.7 第 7 章、SAD ADR-015/016、.gitignore 现状。

## 1. 查询结论速览

| 核对项 | 结论 | 说明 |
| --- | --- | --- |
| 脚本最终清单 | 24 个脚本（12 对）+ .gitkeep | 与 context.md 第 4 章清单完全一致；无弃用脚本残留（grep deploy-env 全目录 0 命中，TASK-008 已闭环） |
| load-env 调用 | 全部业务脚本均引用 load-env | .ps1 点源 `. "$PSScriptRoot\load-env.ps1"`；.sh `source "$SCRIPT_DIR/load-env.sh"`（多数带 `\|\| exit $?`，deploy-check-env.sh 依赖 set -e 兜底） |
| 输出分级函数 | 核心脚本双平台一致 | `[通过]`/`[警告]`/`[失败]` 三级前缀 + 汇总行；**deploy-rsa-keygen.ps1 无分级前缀**（.sh 有），见潜在问题 P3 |
| 退出码约定 | 双平台一致 | 全部通过 0 / 存在失败 1 / 仅警告 0（check-env、start-services）；start-all 失败即停退出 1 |
| 密钥契约（ADR-015） | 双平台一致 | DER 单行 Base64（PKCS#8 / X.509），5 道自校验 + 脱敏（前 24 字符） |
| SPDX 头 | 18/24 个脚本有 | **deploy-db-init/build-backend/build-client 6 个历史脚本无 SPDX 头**，见潜在问题 P2 |
| 硬编码地址 | 核心脚本 0 命中 | **deploy-db-init.ps1/.sh 存在硬编码默认值 192.168.1.101/3306/root/\<DB_PASSWORD\>**，见潜在问题 P1 |
| .gitignore | 已治理（376 行） | TASK-009 已完成：JVM 调试产物/构建中间产物/测试产物/工具残留等规则齐全 |

## 2. deploy/scripts 脚本最终清单（glob 扫描实况，2026-08-10）

共 24 个脚本（12 对）+ `.gitkeep`，无弃用残留：

| # | 脚本对 | 版本 | 能力归属 | 上游任务 | load-env 调用 |
| --- | --- | --- | --- | --- | --- |
| 1 | load-env.ps1 / load-env.sh | v0.2.7 | 统一配置加载（F-001） | TASK-002 | 模块本身（被调用方） |
| 2 | deploy-check-env.ps1 / .sh | v0.2.7 | 可用性检查+运行状态（F-002~F-006、F-010） | TASK-003 | `.`/`source` |
| 3 | deploy-start-services.ps1 / .sh | v0.2.7 | 基础设施一键启动（F-006、F-007） | TASK-004 | `.`/`source \|\| exit $?` |
| 4 | deploy-start-all.ps1 / .sh | v0.2.7 | 后端按序一键启动（F-008） | TASK-005 | `.`/`source \|\| exit $?` |
| 5 | deploy-start-gateway.ps1 / .sh | v0.2.7 | 单服务启动（F-009） | TASK-006 | `.`/`source \|\| exit $?` |
| 6 | deploy-start-auth.ps1 / .sh | v0.2.7 | 单服务启动（F-009） | TASK-006 | `.`/`source \|\| exit $?` |
| 7 | deploy-start-biz.ps1 / .sh | v0.2.7 | 单服务启动（F-009） | TASK-006 | `.`/`source \|\| exit $?` |
| 8 | deploy-start-system.ps1 / .sh | v0.2.7 | 单服务启动（F-009） | TASK-006 | `.`/`source \|\| exit $?` |
| 9 | deploy-rsa-keygen.ps1 / .sh | v0.2.7 | RSA 密钥生成（F-011、ADR-015） | TASK-007 | 不依赖（独立工具） |
| 10 | deploy-db-init.ps1 / .sh | v0.1.7 | 数据库初始化（历史资产） | 历史 | `. $PSScriptRoot\load-env.ps1`（无引号）/ `source` |
| 11 | build-backend.ps1 / .sh | 历史 | 后端构建（历史资产） | 历史 | 不依赖（构建脚本） |
| 12 | build-client.ps1 / .sh | 历史 | 客户端构建（历史资产） | 历史 | 不依赖（构建脚本） |

## 3. 各脚本关键实现（验证核对基准）

### 3.1 load-env.ps1（75 行） / load-env.sh（84 行）——统一配置加载（F-001）

- **调用方式**：`.ps1` 点源（`dot-source`），`param([string]$EnvFile = "env.json")`；`.sh` source 型，`ENV_FILE="${1:-env.json}"`。
- **env.json 定位**：`$PSScriptRoot` 的父目录（deploy）/ `SCRIPT_DIR` 的父目录（deploy），即 `deploy/env.json`。
- **缺失处理**：`.ps1` `Write-Error 提示复制 env.example.json + exit 1`；`.sh` `echo >&2 + return 1`（source 型不 exit 避免终止父 shell）。
- **JSON 解析**：`.ps1` `ConvertFrom-Json` 后逐键 `Set-Item env:`；`.sh` 依赖 jq（优先）或 python3（回退），`eval` 注入 export。
- **关键配置校验（8 项，仅列键名不打印值）**：`NACOS_ADDR`、`NACOS_HOME`、`DB_HOST`、`DB_PORT`、`DB_USERNAME`、`DB_PASSWORD`、`REDIS_HOST`、`REDIS_PORT`——缺失逐项列出并退出/返回非零。
- **安全约定**：DB_PASSWORD / RSA_PRIVATE_KEY 等仅注入会话环境变量，输出仅打印键数量与文件路径，不打印任何值明文。
- **SPDX 头**：均有（.ps1 第 1 行 / .sh 第 2 行）。

### 3.2 deploy-check-env.ps1（280 行） / .sh（277 行）——可用性检查 + 运行状态（F-002~F-006、F-010）

- **阶段一（可用性）**：
  - JDK：`java` 命令可执行 + `JAVA_HOME` 有效 + 版本匹配 `version "21`（合并一项结论）；
  - MariaDB：命令/系统服务/进程三重安装检测（`Test-Installed`，默认清单 MySQL/MariaDB、mysqld/mariadbd，可被 env.json 的 DB_SERVICE_NAME/DB_PROCESS_NAME 覆盖）+ `SELECT 1` 连通（口令掩码 `****`）；
  - Redis：三重检测 + `redis-cli ping` 返回 PONG（口令经 `REDISCLI_AUTH` 环境变量传递，命令与日志无明文）；
  - Nacos：`NACOS_ADDR` 格式校验（`^[^:]+:\d+$`）+ `NACOS_HOME/bin/startup.cmd`（.sh 为 startup.sh）存在 + HTTP 探测 `http://NACOS_ADDR/nacos/` 含 "Nacos"；**已安装未启动计「警告（未运行）」**。
- **阶段二（运行状态）**：JDK 复用可用性结论；MariaDB/Redis 进程/服务 Running/TCP 端口任一命中即运行中；Nacos HTTP 为主 + java 进程命令行含 nacos 辅助。
- **汇总与退出码（F-011）**：汇总行「通过 N 项 | 警告 M 项 | 失败 K 项」；fail>0 → exit 1；warn>0 无 fail → exit 0 并提示；全通过 → exit 0。
- **load-env 调用**：`.ps1` 点源（无显式退出码检查，load-env 内部 exit 兜底）；`.sh` `source`（无 `|| exit $?`，靠 `set -euo pipefail` 兜底，见潜在问题 P6）。

### 3.3 deploy-start-services.ps1（347 行） / .sh（343 行）——基础设施一键启动（F-006、F-007）

- **JDK**：仅检查可用性输出结论，不执行启动（R-11）。
- **顺序**：MariaDB → Redis → Nacos（R-07 基础设施序）。
- **未安装**：不尝试启动，输出「未安装，请先安装」计入失败（R-12）。
- **已运行**：幂等跳过，输出「已运行」（R-10）。
- **启动方式优先级**：系统服务（Windows `Start-Service` / Linux `systemctl start` 回退 `service start`）→ 可执行文件（mysqld/mariadbd/redis-server；.sh 侧 mysqld_safe 优先）→ Nacos `startup.cmd/.sh -m standalone`（日志落 deploy/logs/nacos-start.log）。
- **启动后确认**：`Wait-ServiceUp`/`wait_for_service` 循环探测（超时上限 30s、间隔 2s，进程/TCP/ping/HTTP 任一命中），不报假成功（R-08）。
- **退出码**：fail>0 → exit 1；warn>0 无 fail → exit 0；全通过 → exit 0。

### 3.4 deploy-start-all.ps1（221 行） / .sh（196 行）——后端按序一键启动（F-008）

- **前置校验**：JDK java 命令 + 4 个 jar 包存在（deploy/cloudoffice-gateway.jar、cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar）+ 各服务关键环境变量（缺失只列键名不打印值）；任一缺失列出缺失项+提示，**退出 1 且不启动任何服务**。
- **服务清单契约**（数组顺序即启动顺序）：
  - gateway：cloudoffice-gateway.jar / 9000 / `http://localhost:9000/` / 需 NACOS_ADDR、RSA_PUBLIC_KEY；
  - auth：cloudoffice-auth-service.jar / 9100 / `http://localhost:9100/api/v1/auth/health` / 需 NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD；
  - biz：cloudoffice-biz-service.jar / 9200 / `http://localhost:9200/api/v1/biz/health` / 需 NACOS_ADDR、DB_PASSWORD；
  - system：cloudoffice-system-service.jar / 9400 / `http://localhost:9400/api/v1/system/health` / 需 NACOS_ADDR、DB_PASSWORD。
- **启动方式**：`java -Xms256m -Xmx512m -jar`；.ps1 `Start-Process` 隐藏窗口 + stdout/stderr 重定向 `deploy/logs/{module}-start.log/.err` + PID 落 `deploy/logs/{module}.pid`；.sh `nohup ... &` + `$!` 记 PID。
- **健康确认**：`Wait-HealthUp`/`wait_health_up` 轮询（默认 30 次/2 秒/3 秒，.ps1 参数 -RetryCount/-RetryInterval/-ProbeTimeout，.sh 环境变量 RETRY_COUNT/RETRY_INTERVAL/PROBE_TIMEOUT），HTTP 优先（任一 HTTP 响应含 404/401/500 即存活）、TCP 备用；确认成功后再启动下一个（R-09 失败即停 break）。
- **退出码**：全部成功 exit 0；任一失败 exit 1。

### 3.5 单服务启动脚本 4 对（deploy-start-gateway/auth/biz/system，各 184 行左右）——F-009

- 结构与 deploy-start-all 对应服务子块一致（前置校验 → 后台启动 → 健康确认 → 汇总退出），服务标识/jar/端口/健康 URL/关键变量与 3.4 表一致（已 grep 核对 4 对 8 个脚本参数行：gateway 9000、auth 9100、biz 9200、system 9400 全部正确）。
- auth 脚本注释注明：DB_USERNAME 已由 load-env 的 8 项关键配置兜底校验，不再重复校验（契约表差异 DB_USER 与 DB_USERNAME 保持现状一致）。

### 3.6 deploy-rsa-keygen.ps1（133 行） / .sh（212 行）——RSA 密钥契约（F-011、ADR-015）

- **输出契约（双平台一致）**：DER 编码单行 Base64——私钥 PKCS#8 PrivateKeyInfo（`openssl pkcs8 -topk8 -nocrypt -outform DER`）、公钥 X.509 SubjectPublicKeyInfo（`openssl pkey -pubout -outform DER`）；无 PEM 头尾、无换行（.ps1 `[Convert]::ToBase64String` + `WriteAllText`；.sh `base64 -w0` 作用于 .der 文件 + `printf '%s'`）。
- **契约自校验（双平台同标准）**：①无 `-----BEGIN/END-----`；②无 \r\n 换行；③严格 Base64（字符集正则 + 长度 4 倍数 + 实际解码）；④DER 结构偏移（私钥 [0]=0x30 且 [7]=0x30 且长度≥16；公钥 [0]=0x30 且 [4]=0x30 且 [19]=0x03 且长度≥24）；⑤公私钥成对（.sh 由私钥 DER 派生公钥比对；.ps1 v0.2.6 版无成对校验，.sh 有——差异点）。
- **脱敏（NFR-004）**：完整私钥绝不打印，仅显示前 24 字符前缀，完整值提示从 *_base64.txt 拷贝。
- **输出文件 6 个**：private_key.pem / public_key.pem（审计用）、private_key.der / public_key.der（契约字节来源）、private_key_base64.txt / public_key_base64.txt（env.json 注入值来源）。
- **退出码**：全部通过 exit 0，失败 exit 1。
- **注意**：.sh 有 `print_result` 分级函数（[通过]/[失败]）与汇总行；**.ps1 无分级前缀与汇总行**（直接 Write-Host/Write-Error），见潜在问题 P3。

### 3.7 历史资产脚本（deploy-db-init、build-backend、build-client）

- **deploy-db-init.ps1（112 行，v0.1.7）/.sh（93 行）**：`mariadb < SQL 文件` 初始化 auth 库（auth-init-v0.1.5.sql / v0.1.6.sql 位于 scripts/sql/）。经 load-env 加载配置，但 **param/默认值硬编码 `192.168.1.101`、`3306`、`root`、`<DB_PASSWORD>`**（见 P1）；输出用 ✅/❌ emoji 非 [通过]/[警告]/[失败] 分级（见 P4）；口令以 `-p"$DbPassword"` 命令行参数传递（进程列表可见，见 P8）；无 SPDX 头（见 P2）。
- **build-backend.ps1（67 行）/.sh（72 行）**：`mvn -f pom.xml clean package [-DskipTests]` 构建 4 服务，校验 jar 落位 deploy。无 SPDX 头（P2）；输出 `[错误]` 前缀；不依赖 load-env（构建脚本无需环境配置，合规）。
- **build-client.ps1（79 行）/.sh**：调用 cloudoffice-flutter-app/build-release.ps1，产物落位 deploy/cloudoffice-flutter-app/。无 SPDX 头（P2）。

## 4. PRD v0.2.7 第 7 章验收标准原文（docs/cso-v0.2.7/cso-prd-v0.2.7.md 第 281-290 行）

1. 全部脚本（.ps1/.sh）均通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内无硬编码环境地址（192.168.1.100 等）与凭据；env.json 缺失或关键配置缺失时输出明确错误并以非零码退出。
2. `deploy-check-env.ps1`/`.sh` 基于 env.json 完成 JDK（命令 + JAVA_HOME + 版本 21）、MariaDB（命令/服务/进程 + SELECT 1）、Redis（命令/服务/进程 + ping）、Nacos（NACOS_HOME/startup 脚本 + HTTP 探测）可用性检查，并输出运行状态；存在失败项时给出处理提示并退出非零。
3. `deploy-start-services.ps1`/`.sh` 检测到未运行的 MariaDB/Redis/Nacos 时自动启动（系统服务优先，其次可执行文件/NACOS_HOME 启动脚本），启动后再次探测确认，无假成功；JDK 仅检查可用性不执行启动。
4. `deploy-start-all.ps1`/`.sh` 按 gateway → auth → biz → system 顺序一键启动 4 个后端服务，启动前校验 jar 包与关键环境变量，每服务启动后健康确认，任一步骤失败时停止并给出明确错误提示。
5. 单服务启动脚本（deploy-start-gateway/auth/biz/system）各自独立可用，行为与一键启动对应服务一致。
6. `deploy-rsa-keygen.sh` 与 `.ps1` 输出契约一致（DER 编码单行 Base64，公钥 X.509 / 私钥 PKCS#8），与 Java 端解码契约一致；弃用脚本（deploy-env.ps1 / deploy-env-template.ps1）已移除或明确弃用。
7. 脚本输出统一分级（通过/警告/失败）与退出码约定（失败非零）；.ps1 与 .sh 双平台行为一致，通过语法与契约自校验。
8. `.gitignore` 已补充生成、测试、调试过程中的临时/中间文件排除规则（JVM 调试产物、测试缓存、构建中间产物、工具残留等），`git status` 不再出现此类文件，且不误伤 env.example.json、.gitkeep、源码与文档等应入库文件。

## 5. SAD ADR-015 / ADR-016 契约原文（docs/sad.md 第 305-306 行）

- **ADR-015（RSA 密钥格式契约，2026-08-09）**：统一 RSA 密钥格式为 DER 编码单行 Base64：deploy-rsa-keygen.ps1 输出/env.json 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）解码逻辑严格一致；禁止多行 PEM 整体 Base64 直接注入。
- **ADR-016（部署脚本体系重构与配置驱动，2026-08-10）**：v0.2.7 系统性重构 deploy/scripts 全部脚本：以 deploy/env.json 为唯一配置源（load-env.ps1/.sh 统一加载，脚本不硬编码地址与凭据）；能力划分为可用性检查（deploy-check-env）、基础设施一键启动（deploy-start-services）、后端服务按序一键启动（deploy-start-all）与单服务启动（deploy-start-{svc}）四类；.ps1 与 .sh 双平台行为对齐，输出分级（通过/警告/失败）与退出码约定（失败非零）统一；删除弃用脚本残留（deploy-env 等），.sh 与 .ps1 密钥输出契约对齐（不破坏 ADR-015）；同时治理 .gitignore 排除生成/测试/调试临时与中间文件。仅涉及部署运维层，不改变后端架构、接口契约与数据库设计。

## 6. .gitignore 现状（376 行，TASK-009 已治理，v0.2.7 验收标准 8 对应）

- 分区结构：操作系统 / 通用 IDE / AI 工具 / 前端 Node / Python / Java Maven / **JVM 调试产物**（*.hprof、hs_err_pid*.log、replay_pid*、heapdump.*、*.dmp、dump/、*.dump、derby.log）/ **构建测试中间产物**（*.flattened-pom.xml、*.lastUpdated、maven-status/、dependency-reduced-pom.xml、surefire-reports/、test-output/、test-results/、scripts/API-TEST/*.tmp、*.token.json）/ C/C++ / Rust / Go / PHP / Dart Flutter / 客户端构建产物 / 数据库日志临时（*.log、logs/、*.err、*.pid、work/、*.db、tmp/、temp/）/ 工具残留（*.saz、*.chls、*.har、*.history、*.session、*.trace）/ 环境密钥（env.json、keys/、.env.*）。
- 保护性规则：`!env.example.json`（存在，键名清单见 §7）、`deploy/cloudoffice-flutter-app/web/*` 与 `!.../.gitkeep`（不误伤客户端源码）。
- 待核对（TASK-010 验证时执行 `git status --porcelain`）：待提交清单不应出现上述任何过程文件；TASK-009 回归已确认 21 种治理类型模式 0 命中（FT-149-1 PASS）。

## 7. deploy/env.json 与 env.example.json 键名清单（仅键名，不读敏感值）

env.example.json（deploy/env.example.json，33 键）与 load-env 8 项关键校验键名对应关系：
`NACOS_ADDR`、`NACOS_HOME`、`DB_SERVICE_NAME`、`DB_PROCESS_NAME`、`REDIS_SERVICE_NAME`、`REDIS_PROCESS_NAME`、`DB_HOST`、`DB_PORT`、`DB_USERNAME`、`DB_PASSWORD`、`DB_USER`、`REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD`、`REDIS_DATABASE`、`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`、`VERIFICATION_CODE_*`（MOCK/EXPIRE_SECONDS/SEND_INTERVAL/LENGTH）、`PASSWORD_MIN_LENGTH`/`PASSWORD_MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ`。
注：模板默认值含 127.0.0.1:8848 / 127.0.0.1:3306 等——属 env.example.json 模板（应入库文件），非脚本硬编码，合规；脚本侧 grep 192.168.x 仅 deploy-db-init 命中（P1）。

## 8. 可复用测试资产（scripts/API-TEST，TASK-010 验证阶段可复用）

- v0.2.7 单元测试脚本：cso-unit-test-load-env-v0.2.7.ps1、cso-unit-test-check-env-v0.2.7.ps1、cso-unit-test-start-services-v0.2.7.ps1、cso-unit-test-start-all-v0.2.7.ps1、cso-unit-test-start-single-v0.2.7.ps1、cso-unit-test-rsa-key-contract-v0.2.7.ps1、cso-unit-test-deploy-scripts-cleanup-v0.2.7.ps1、cso-unit-test-gitignore-v0.2.7.ps1（分别覆盖 TASK-002~009 的语法/契约校验，可作为 TASK-010 总体验证的基础脚本）；
- 接口测试：cso-api-test-v0.2.7.py。

## 9. 验证要点与潜在问题（TASK-010 验证阶段核对清单）

### 验证要点（对照 context.md 第 7 节）
1. **语法校验**：12 对脚本——.ps1 用 `[System.Management.Automation.Language.Parser]::ParseFile` 解析；.sh 用 `bash -n`（Windows 无 bash 时可用 git-bash/wsl 或静态核对，需记录校验环境）。
2. **契约自校验**：deploy-rsa-keygen 输出（无 BEGIN/END、无换行、严格 Base64 解码、DER 结构偏移、公私钥配对）；[通过]/[警告]/[失败] 前缀与汇总行存在；退出码失败非零。
3. **硬编码检查**：grep 全脚本 192.168.x —— **仅 deploy-db-init 命中（P1）**；DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY 无明文打印路径（deploy-db-init 的 -p"$DbPassword" 命令行参数为进程级可见，见 P8）。
4. **load-env 依赖检查**：全部业务脚本（2~8 号对 + db-init）均引用 load-env 后才使用配置（已验证）；build-backend/build-client 为构建脚本不依赖（合理）。
5. **弃用残留检查**：deploy-env / deploy-env-template 全目录 grep 0 命中（已验证）。
6. **文件头检查**：18/24 个脚本有 SPDX 头，**6 个历史脚本缺失（P2）**。
7. **git status 验证**：无生成/测试/调试过程文件（验收标准 8）。

### 潜在问题清单（供验证报告输出）
- **P1（高，验收标准 1 红线）**：deploy-db-init.ps1 第 20-23 行 param 默认值 `192.168.1.101 / 3306 / root / <DB_PASSWORD>`；deploy-db-init.sh 第 21-24 行 `${DB_HOST:-192.168.1.101}` 等。虽经 load-env 覆盖，但存在硬编码环境地址与默认凭据占位，违反「脚本内无硬编码环境地址与凭据」。
- **P2（中，US-004 验收标准 4）**：deploy-db-init/build-backend/build-client 的 .ps1/.sh 共 6 个脚本无 SPDX-License-Identifier 头与版权声明。
- **P3（中，验收标准 7 双平台一致性）**：deploy-rsa-keygen.ps1 无 [通过]/[失败] 分级前缀与汇总行，与 .sh（print_result 分级 + 汇总）不一致；退出码约定一致（失败 exit 1）。
- **P4（中，验收标准 7 输出分级）**：deploy-db-init 双平台输出用 ✅/❌ emoji 与「错误:」文本，无 [通过]/[警告]/[失败] 分级与汇总行。
- **P5（低，健壮性）**：deploy-db-init.ps1 第 30 行 `. $PSScriptRoot\load-env.ps1` 无引号包裹路径，脚本目录含空格时点源失败；其余 .ps1 均为 `". \"$PSScriptRoot\load-env.ps1\""`。
- **P6（低，一致性）**：deploy-check-env.sh 第 29 行 `source "$SCRIPT_DIR/load-env.sh"` 无 `|| exit $?`，依赖 set -e 兜底（行为等效）；其余 .sh 均显式 `|| exit $?`。
- **P7（观察项，非缺陷）**：deploy-rsa-keygen.ps1 无「公私钥成对」自校验（.sh 第 186-189 行有）；密钥输出契约本身一致，不影响 ADR-015 验收。
- **P8（低，安全边界）**：deploy-db-init 口令以 `-p"$DbPassword"` 命令行参数传给 mariadb（进程列表可见），未采用 load-env/check-env 的掩码通道机制；日志打印已掩码（`-p'****'`）。
- **P9（确认项）**：.gitignore 治理完整（验收标准 8），需在验证时以 `git status --porcelain` 复核过程文件 0 命中且 env.example.json/.gitkeep/pom.xml/bootstrap.yml 等应入库文件未误伤。

## 10. 数据来源

- deploy/scripts 全部 24 个脚本：glob 扫描 + read 逐文件核对（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen、deploy-db-init、build-backend、build-client）
- PRD：docs/cso-v0.2.7/cso-prd-v0.2.7.md 第 281-290 行（第 7 章验收标准原文）
- SAD：docs/sad.md 第 305-306 行（ADR-015/016 原文）、第 25/217 行（脚本体系约束）
- context：docs/cso-v0.2.7/task_TASK-010/context.md（TASK-010 任务上下文）
- 配置：deploy/env.example.json（键名清单）、deploy/env.json（未读敏感值）
- .gitignore：项目根目录（376 行现状）
- 测试资产：scripts/API-TEST/*.ps1（v0.2.7 各任务单元测试脚本）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
