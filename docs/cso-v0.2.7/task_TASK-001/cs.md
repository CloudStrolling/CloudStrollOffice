# 代码查询结果（TASK-001 梳理 deploy/scripts 现有脚本与 .gitignore 现状并输出问题清单）

## 0. 查询结论摘要

本任务为 v0.2.7「部署脚本体系重构与仓库清洁度治理」的先行梳理任务，无代码修改。经对 `deploy/scripts` 全部 26 个文件（含 .gitkeep）、根目录 `.gitignore`（332 行）、`deploy/env.example.json`、`deploy/deploy.md`、`deploy/build.md` 及版本文档（URS/PRD/LLD/SAD/ADR-015/ADR-016）逐项核对，确认 context.md 初步识别的 6 类历史遗留问题**全部属实**，并补充若干细节。本 cs.md 输出的问题清单可作为 TASK-002/003/004/005/007 重构的直接依据。

---

## 1. 查询范围与文件清单

### 1.1 deploy/scripts 脚本（26 个条目，25 个脚本文件 + .gitkeep）

| 脚本（.ps1/.sh） | 定位/作用 | 现状（v0.2.7 基线） |
| --- | --- | --- |
| load-env.ps1 / load-env.sh | 统一配置加载：从 `deploy/env.json` 将键值对注入会话环境变量 | 已双版本存在，结构清晰；.sh 依赖 jq/python3 二选一 |
| deploy-check-env.ps1 / .sh | 部署前置检查（中间件可用性 + 开发环境 + 连通性 + 项目代码） | 硬编码默认地址为主、env.json 为辅；检查范围与 F-002~F-006 不对齐；.ps1 与 .sh 检查项数量不一致（ps1 12 项 / sh 13 项） |
| deploy-start-services.ps1 / .sh | 基础设施安装三重检测 + 运行检测 + 未运行自动启动（MariaDB/Redis/Nacos） | 已有"检测+启动+探测确认"框架；但 JDK 未纳入；Nacos 启动用 cmd/c 与 Bash 启动方式差异；输出分级与退出码约定与 check-env 不统一 |
| deploy-start-gateway.ps1 / .sh | 单服务启动（Gateway） | 前台 `java -jar` 阻塞式启动；校验 NACOS_ADDR/RSA_PUBLIC_KEY/jar 存在；.sh 用 `exec java`，.ps1 直接 `java`；biz/system 用 DB_USER 而 auth 用 DB_USERNAME，变量校验范围不一致 |
| deploy-start-auth.ps1 / .sh | 单服务启动（Auth） | 校验 9 个变量（NACOS_ADDR/DB_*/REDIS_*/RSA_*）；.sh 显示 `$DB_AUTH_NAME` 但 env.json 无此键（显示层不一致） |
| deploy-start-biz.ps1 / .sh | 单服务启动（Biz） | 仅校验 NACOS_ADDR/DB_PASSWORD；.sh 显示 DB_URL 默认 `localhost` 硬编码；.ps1 无对应 DB_URL 显示 |
| deploy-start-system.ps1 / .sh | 单服务启动（System） | 同 biz 结构；.sh 显示 DB_URL 默认 `localhost` 硬编码 |
| deploy-rsa-keygen.ps1 | RSA 2048 密钥生成（DER 单行 Base64 契约，ADR-015 已对齐） | v0.2.6 已更新：PKCS#8/X.509 DER → 单行 Base64；含契约自校验（无 PEM/无换行/严格 Base64/DER 结构）；输出脱敏（仅前 24 字符） |
| deploy-rsa-keygen.sh | RSA 密钥生成 | **契约不一致**：对 PEM 文件整体 `base64 -w0`（含 BEGIN/END 头尾），非 DER 单行 Base64；输出不脱敏（直接打印完整私钥到日志）；无契约自校验（仅 openssl 文本验证） |
| deploy-db-init.ps1 / .sh | 数据库初始化（执行 scripts/sql/auth-init-v0.1.5/6.sql） | 硬编码默认 DB_HOST=192.168.1.101（env 为辅）；SQL 文件版本号（v0.1.5/v0.1.6）在脚本内硬编码，未读取目录清单 |
| build-backend.ps1 / .sh | 后端一键编译（mvn clean package，jar 落位 deploy） | 已规范（无硬编码、产物校验齐全），重构基本无需改动 |
| build-client.ps1 / .sh | 客户端一键编译（调用 cloudoffice-flutter-app/build-release.*） | 已规范（无硬编码、产物校验齐全），重构基本无需改动 |
| deploy-env.ps1 | 环境注入脚本【已弃用】 | 弃用残留（无 .sh 对版本）；doc 注释自称"兼容保留"，与 load-env 双份配置逻辑混淆 |
| deploy-env-template.ps1 / .sh | 环境变量模板【已弃用】 | 弃用残留；与 env.example.json 模板功能重复 |
| .gitkeep | 占位文件 | 保留 |

### 1.2 其他相关文件

- `.gitignore`（根目录，332 行）：已有 10+ 分区，详见第 4 节。
- `deploy/env.example.json`：唯一配置模板（27 键），NACOS_ADDR=127.0.0.1:8848、DB_HOST=127.0.0.1 等模板值（非硬编码，是模板占位）。
- `deploy/deploy.md`（v0.2.6）：部署方案；第 72-73 行目录树宣称存在 `deploy-env.sh` 与 `deploy-env-template.sh`，**实际目录中无 deploy-env.sh**（文档与事实不符）。
- `deploy/build.md`（v0.2.6）：编译方案。
- `docs/sad.md`：G-A7、脚本体系约束（v0.2.7 起）、ADR-016 描述目标脚本体系。
- `docs/cso-v0.2.7/cso-urs-v0.2.7.md` / `cso-prd-v0.2.7.md` / `cso-lld-v0.2.7.md`：本版本需求/设计依据（F-001~F-012，US-001~US-005，R-01~R-16）。

### 1.3 已核对的 git 跟踪情况

- `git ls-files` 确认：deploy/scripts 下 25 个脚本全部被 git 跟踪（含弃用的 deploy-env.ps1、deploy-env-template.ps1/.sh）；`deploy/env.json`、`deploy/keys/`、jar 产物、客户端产物均未跟踪（符合 .gitignore 预期）。
- `scripts/` 根下仍存在旧路径脚本 `scripts/deploy-rsa-keygen.ps1/.sh`、`scripts/deployment-guide.md`（git 已跟踪，属历史遗留路径；本轮 TASK-001 范围仅 deploy/scripts 与 .gitignore，此路径残留列入问题清单提示）。

---

## 2. deploy/scripts 现有脚本详细分析（逐文件关键代码定位）

### 2.1 load-env.ps1 / load-env.sh（可复用模块）
- `load-env.ps1`（35 行）：`param([string]$EnvFile = "env.json")`；`$ProjectDir = Split-Path -Parent $PSScriptRoot`（= deploy）；`ConvertFrom-Json` 后 `Set-Item -Path "env:$($_.Name)"` 注入；失败 `exit 1`。
  - **问题点（低）**：第 35 行 `$MyInvocation.MyCommand.ScriptBlock.Module.SessionState.Path.CurrentFileSystemDrive` 为孤立死代码（无赋值、无输出）。
- `load-env.sh`（39 行）：jq 优先、python3 回退；`eval "$(jq -r 'to_entries | .[] | "export \(.key)=\(.value | @sh)"')"`；失败 `return 1`。
  - **可复用**：全部重构脚本应继续统一调用二者，不重复实现加载逻辑。

### 2.2 deploy-check-env.ps1 / .sh（环境检查，问题集中）
- .ps1（160 行）：
  - **P1 硬编码默认地址**（第 25-31 行）：`param` 默认值 `NacosAddr="192.168.1.100:8848"`、`DbHost="192.168.1.101"`、`RedisHost="192.168.1.102"`；第 41-46 行以"默认值等于硬编码值"判断是否回退 env——语义脆弱（env 未设置时静默回退到错误地址）。
  - **P2 能力分散/错位**：① Nacos 可用性检查在第 81-84 行（1.1），与第 129-132 行"连通性检查"重复 HTTP 探测；② 检查范围包含 Maven/Git/JAVA_HOME/SQL 文件等开发环境项，与 F-002~F-006（JDK/MariaDB/Redis/Nacos 可用性+运行状态）不对齐；③ "运行状态检查"能力完全缺失。
  - **P3 代码死逻辑**：第 89-91 行 `$conn = New-Object System.Data.Common.DbProviderFactory` 为无效创建，随后才真正调用 mariadb 命令。
  - **P4 输出约定不统一**：`Check` 函数仅输出"通过/失败"，无"警告"分级；`$Expected` 参数仅失败时打印；无 `[通过/警告/失败]` 前缀统一规范。
  - **P5 敏感信息泄露风险**：第 89 行构造连接字符串明文含 `$DbPassword`（虽未输出，但需复核）。
- .sh（150 行）：
  - 硬编码默认值（第 25-31 行）：`NACOS_ADDR:-192.168.1.100:8848`、`DB_HOST:-192.168.1.101`、`REDIS_HOST:-192.168.1.102`。
  - 检查项 13 项 vs .ps1 12 项：.sh 额外有 3.2 MariaDB 连通、3.3 Redis 连通、4.3 Maven settings，缺"SQL 初始化脚本（4.2 用 ls|wc|grep 方式）"之一——**双平台行为不对齐**。
  - `check()` 用 `eval "$cmd"` 执行命令字符串，存在注入/引号风险（如 `-p'$DB_PASSWORD'` 传参）。

### 2.3 deploy-start-services.ps1 / .sh（基础设施检测与启动）
- 两脚本均有"安装三重检测（命令/服务/进程）→ 运行检测 → 未运行启动 → 探测确认"框架，与 F-006/F-007 目标较接近，是重构的基础。
- **P6 能力缺口**：JDK 未纳入检查（F-006 要求输出 JDK 可用性结论）；Nacos 运行检测仅 HTTP 探测 + java 进程，启动后探测等待 8 秒固定值。
- **P7 双平台差异**：Windows 用 `Get-Service`/`Start-Service`/`Start-Job + cmd /c start`；Linux 用 `systemctl`/`mysqld_safe`/`redis-server --daemonize`；Nacos 启动脚本名 startup.cmd vs startup.sh 已按平台区分，但 `NACOS_HOME` 为空时的错误提示不统一。
- **P8 输出格式不一致**：.sh 用 ANSI 色 + `✅/⚠️/❌` emoji；.ps1 用 PowerShell 颜色（emoji 为 `""`/`""` 空字符，实际不显示图标）；check-env 无 emoji。同版本脚本间输出风格不统一。
- **P9 敏感信息**：.sh 第 66 行 mariadb 命令 `-p'$DB_PASSWORD'` 明文出现在 `eval` 字符串中（未打印，但调试时 `set -x` 会泄露）；.ps1 连接字符串同样含明文。

### 2.4 deploy-start-gateway/auth/biz/system（单服务启动）
- 共同结构：load-env → 校验必要变量 → 校验 jar 存在 → 显示配置 → `java -Xms256m -Xmx512m -jar`。
- **P10 前台阻塞**：.ps1 直接 `java ...`（前台），.sh 用 `exec java`（前台替换）。F-008 一键启动需后台/独立窗口方式，单服务脚本需在重构中补充后台化（Start-Process / nohup 等）或明确"前台运行，供调试"定位。
- **P11 变量校验不一致**：auth 校验 9 变量（含 RSA_PRIVATE_KEY/RSA_PUBLIC_KEY）；gateway 校验 NACOS_ADDR/RSA_PUBLIC_KEY；biz/system 仅校验 NACOS_ADDR/DB_PASSWORD；且 biz/system 用 `DB_USER`、auth 用 `DB_USERNAME`——与 F-009 描述（biz 使用 DB_USER、auth 使用 DB_USERNAME 的差异保持）一致，但各脚本应统一"所需变量清单"明示。
- **P12 显示层不一致**：auth.sh 第 53 行显示 `$DB_AUTH_NAME`，env.json 无此键（未定义显示为空）；biz.sh/system.sh 显示 `DB_URL` 默认值含 `localhost`（未从 env.json 读取 DB_HOST）；.ps1 与 .sh 显示信息不对称。

### 2.5 deploy-rsa-keygen.ps1 / .sh（密钥契约不一致）
- .ps1（131 行，v0.2.6 已对齐 ADR-015）：
  - `openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048` → 私钥 PEM 审计副本；
  - `openssl pkcs8 -topk8 -nocrypt -in ... -outform DER`（显式 PKCS#8，避免 PKCS#1 导致 `algid parse error`）→ DER 二进制；
  - `openssl pkey -in ... -pubout -outform DER` → 公钥 DER（X.509）；
  - `[Convert]::ToBase64String(...)` 单行 Base64 写入 `*_base64.txt`；
  - **契约自校验**（第 86-113 行）：无 PEM 头尾、无换行、严格 Base64 解码、DER 结构偏移校验（私钥 `[0]=0x30 && [7]=0x30`、公钥 `[0]=0x30 && [4]=0x30 && [19]=0x03`）；
  - 输出脱敏：仅打印前 24 字符（第 127-128 行）。
- .sh（92 行，v0.2.6 未更新）：
  - **P13 契约不一致（核心问题）**：第 49-50 行 `base64 -w0 "$PRIVATE_KEY_FILE"` 是对 PEM 文件整体 Base64（含 `-----BEGIN RSA PRIVATE KEY-----` 头尾与换行被 `-w0` 拍平成单行但仍含头尾标记），非 DER 编码，与 Java `Base64.getDecoder()+PKCS8EncodedKeySpec` 不兼容（网关会报 `RSA 公钥解析失败`）；也未生成 `.der` 文件。
  - **P14 输出不脱敏**：第 87-88 行直接 `echo "\"RSA_PRIVATE_KEY\": \"$(cat $PRIVATE_KEY_B64_FILE)\""` 将完整私钥打印到日志，违反 NFR-004/敏感信息红线。
  - **P15 无契约自校验**：仅 `openssl pkey -noout -text` 验证 + 长度统计；无 DER 结构/PKCS#8 校验。
  - **P16 版本号陈旧**：文件头 `版本: v0.1.7`（未随 .ps1 升级）。

### 2.6 deploy-db-init.ps1 / .sh
- **P17 硬编码默认 DB_HOST=192.168.1.101**（.ps1 第 20 行 param 默认值、.sh 第 21 行 `${DB_HOST:-192.168.1.101}`），env 为辅。
- **P18 SQL 清单硬编码**：脚本写死 `auth-init-v0.1.5.sql` / `auth-init-v0.1.6.sql`（.ps1 第 35-36 行、.sh 第 37-44 行），后续新增版本 SQL 需改脚本；应改为读取 `scripts/sql` 目录清单（本任务仅记录现状，不改动）。
- 注：deploy-db-init 不在 F-001~F-012 重构范围核心，但属于 deploy/scripts 目录，若清理弃用脚本时需同步检查引用。

### 2.7 build-backend.ps1 / .sh、build-client.ps1 / .sh
- 已符合"无硬编码、产物唯一落点、SPDX 头"规范；`scripts/` 下存在旧路径重复脚本 `scripts/deploy-rsa-keygen.ps1/.sh`（git 跟踪中），历史路径残留，见 1.3。

---

## 3. 可复用模块与重构输入（供下游 TASK-002~005/007）

| 可复用资产 | 位置 | 复用建议 |
| --- | --- | --- |
| load-env.ps1 / load-env.sh | deploy/scripts/load-env.* | 全部重构脚本统一调用；修复 .ps1 死代码（低优先） |
| 三重检测框架（命令/服务/进程） | deploy-start-services.* 第 52-108 行（.ps1 Test-Installed / .sh has_cmd/has_svc/has_proc） | F-003/F-004 可用性检查可抽取为公共函数 |
| RSA 契约自校验逻辑 | deploy-rsa-keygen.ps1 第 86-113 行 | F-011：.sh 需按此对齐（DER 单行 Base64 + 自校验 + 脱敏） |
| 输出分级/计数汇总框架 | deploy-start-services.* 汇总段（第 211-218 行 .ps1 / 225-239 行 .sh） | F-011 输出规范基线，但需统一分级（通过/警告/失败）与退出码 |
| 端口/健康检查探测 | deploy-start-services.* Nacos HTTP 探测；各服务 `GET /api/v1/{module}/health` | F-008 deploy-start-all 逐服务健康确认可复用该探测思路 |
| env.example.json（27 键） | deploy/env.example.json | 配置驱动唯一模板；重构后脚本引用键不得超出此集合（新键需同步模板） |
| 部署顺序与端口契约 | deploy.md 第 2 节、SAD | gateway(9000) → auth(9100) → biz(9200) → system(9400)；基础设施 MariaDB → Redis → Nacos |

---

## 4. .gitignore 现状与缺口（供 F-012 治理依据）

### 4.1 现状（根目录 .gitignore，332 行，10+ 分区）
已覆盖：操作系统（Mac/Windows/Linux）、IDE（JetBrains/VSCode 等）、AI 工具（OpenCode/Claude 等）、前端 Node.js、Python、Java/Maven/Gradle（target/、*.class、*.jar）、C/C++、Rust、Go、PHP、Dart/Flutter、客户端构建产物（`deploy/cloudoffice-flutter-app/web/*`、`windows/*` 带路径前缀 + `!*.gitkeep` 白名单）、数据库/缓存/日志/临时（*.log、logs/、tmp/、temp/、.cache/）、环境密钥（keys/、env.json、.env.* 白名单 !.env.example、docs2/）、包管理器、压缩包。

### 4.2 已核对的实际效果
- `git status --porcelain` 当前仅显示 `docs/cso-v0.2.7/version_progress.md`（修改）与 `docs/cso-v0.2.7/task_TASK-001/`（未跟踪），无临时文件污染——**说明现有规则对当前已生成文件基本覆盖**。
- 已确认 `scripts/API-TEST/__pycache__/*.pyc` 实际存在但未被 git 跟踪（`__pycache__/` 规则生效）。
- `deploy/env.json`、`deploy/keys/*.pem|*.der|*_base64.txt` 未被跟踪（keys/ 与 env.json 规则生效）——符合预期。

### 4.3 识别缺口（F-012 需新增/加固的规则类型）
| 类别 | 缺口文件/模式 | 建议规则（带路径前缀或精确模式） |
| --- | --- | --- |
| JVM/应用调试产物 | `*.hprof`（堆转储）、`hs_err_pid*.log`（JVM 崩溃日志）、`dump/`、`*.dump`、`heapdump.*` | `*.hprof`、`hs_err_pid*.log`、`dump/`、`*.dump`、`heapdump.*` |
| Maven/构建中间产物 | `.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated`（Maven 下载失败残留） | `*.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated` |
| 测试产物与缓存 | surefire-reports 等独立测试报告目录（`target/` 已排除，但独立产物目录补充）、接口测试中间文件（token 缓存、临时报告）、`*.pyc` 已覆盖但补充 `test-results/`、`reports/` 局部 | 精确模式：`**/surefire-reports/`、`**/test-results/`、`test-output/`；API-TEST 临时 token/report 文件 |
| 工具残留 | API 调试会话（`.har`、`.saz`、`.chls`、`.http` 会话）、编辑器历史（`*.history`、`*.session`）、抓包输出 | `*.har`、`*.saz`、`*.chls`、`*.history`、`*.session`、`*.http`（若作为正式 API 文档则谨慎，建议仅针对缓存子目录） |
| IDE/编译缓存补充 | `.flattened-pom.xml` 已列；另补充 `.idea` 已有；`*.iml` 已有；无需重复 | 按现有分区追加 |
| 调试临时输出 | `debug/`、`trace/` 局部输出、`*.log` 已有但补充 `*.trace`、`*.dump` | `*.trace`（谨慎避免误伤源码扩展名，可加路径前缀） |

### 4.4 治理红线（不得误伤）
- `deploy/env.example.json`（模板，须入库）：不能因 `env.json` 规则误伤——现有规则为精确 `env.json`，安全。
- `deploy/scripts/.gitkeep`、`deploy/cloudoffice-flutter-app/**/.gitkeep`：白名单 `!*.gitkeep` 已保留。
- `pom.xml`、`bootstrap.yml`、`*.java`、`*.dart`、`*.md`：新规则须带路径前缀或精确模式，避免全局通配误伤。
- 已跟踪文件不受新规则影响；如需停止跟踪既有文件须 `git rm --cached`（本任务仅识别缺口，不执行）。

---

## 5. 历史遗留问题清单（TASK-001 交付物）

### P1 硬编码默认地址（对应 PRD 背景 1.1 / US-001 边界 / F-010）
- 位置：`deploy-check-env.ps1` 第 25-31 行（192.168.1.100/101/102）、`deploy-check-env.sh` 第 25-31 行、`deploy-db-init.ps1` 第 20 行、`deploy-db-init.sh` 第 21 行。
- 表现：以硬编码默认地址为主、env.json 为辅；"默认值等于硬编码"的回退判断脆弱。
- 重构要求：全部删除硬编码默认地址，一律从 env.json（经 load-env）读取；缺失关键配置时明确报错退出。

### P2 弃用脚本残留（对应 US-004 / F-011）
- 位置：`deploy-env.ps1`、`deploy-env-template.ps1`、`deploy-env-template.sh`（git 已跟踪）。
- 表现：deploy-env.ps1 无 .sh 对版本；三者与 `load-env + env.example.json` 双份配置逻辑并存，易混淆。
- 重构要求：删除或按 BA 确认明确弃用并移除引用；`deploy/deploy.md` 第 72-73 行目录树同步修正（宣称存在 deploy-env.sh 实为不存在）。

### P3 RSA 密钥输出契约不一致（对应 US-004 / F-011 / ADR-015）
- 位置：`deploy-rsa-keygen.sh`（v0.1.7 未更新）vs `deploy-rsa-keygen.ps1`（v0.2.6 已对齐）。
- 表现：.sh 对 PEM 整体 Base64（含 BEGIN/END），非 DER 单行 Base64；无 .der 产物；不脱敏输出完整私钥；无契约自校验。
- 重构要求：.sh 与 .ps1 对齐（DER 单行 Base64、PKCS#8/X.509、脱敏、自校验），不得破坏 ADR-015。

### P4 可用性检查与运行状态检查能力分散（对应 F-002~F-006 / F-010）
- 表现：check-env 将 Nacos 可用性误放"连通性检查"且 HTTP 探测重复；检查范围混入 Maven/Git/SQL 等开发环境项；"运行状态"能力缺失；start-services 未纳入 JDK。
- 重构要求：deploy-check-env 对齐 F-002~F-006（JDK/MariaDB/Redis/Nacos 可用性 + 运行状态）；移除或降级无关项。

### P5 输出格式与退出码约定不统一（对应 F-011）
- 表现：check-env 无"警告"分级；start-services 用 emoji+ANSI/PowerShell 颜色，风格不一；start-* 用 `❌` 前缀；退出码约定有分歧（check-env 失败 1 / start-services 有警告仍 0）。
- 重构要求：统一"通过/警告/失败"三级输出与退出码约定（全部通过 0 / 失败非零，警告默认 0 或约定 2）。

### P6 缺少一键启动总入口（对应 F-008 / US-003）
- 表现：deploy/scripts 无 `deploy-start-all.ps1/.sh`；当前需手工逐个窗口启动 4 个服务（gateway→auth→biz→system）。
- 重构要求：新增 deploy-start-all 总入口，按序启动并逐服务健康确认，失败即停；校验 4 个 jar 与关键环境变量。

### P7 附加发现（供参考，不属 6 类主问题）
- `deploy-start-*.ps1` 前台阻塞启动（P10）；单服务变量校验不一致（P11）；auth.sh 显示 `$DB_AUTH_NAME` 不存在键（P12）；check-env.ps1 死代码（P2 中 `DbProviderFactory`、load-env.ps1 第 35 行孤立行）；`scripts/` 根目录旧路径脚本残留（deploy-rsa-keygen.ps1/.sh、deployment-guide.md）；deploy.md 目录树与实际不符；脚本内 `-p'$DB_PASSWORD'` 明文传参在调试模式有泄露风险（NFR-004 需复核）。

---

## 6. 相关文档要点摘录（供下游任务引用）

- **SAD G-A7 / 脚本体系约束（v0.2.7 起）**：全部脚本统一经 load-env 从 deploy/env.json 加载；能力划分：可用性检查 → 基础设施一键启动 → 后端按序一键启动 → 单服务启动；.ps1/.sh 双平台一致；输出分级与退出码统一；RSA 契约（ADR-015）不破坏。
- **ADR-016（v0.2.7）**：部署脚本体系重构与配置驱动；删除弃用脚本残留；.sh/.ps1 密钥输出契约对齐；同时治理 .gitignore。
- **PRD F-001~F-012**：详见 docs/cso-v0.2.7/cso-prd-v0.2.7.md；F-008 明确新增 deploy-start-all.ps1/.sh；F-010 删除硬编码默认地址；F-011 输出分级与退出码统一、密钥契约对齐；F-012 .gitignore 治理。
- **URS FR-001~FR-012 / US-001~US-005**：验收标准以脚本执行与输出断言为主。
- **LLD**：模块清单（load-env/check-env/start-services/start-all/start-{svc}/rsa-keygen/.gitignore）、业务规则 R-01~R-16（含 R-01 配置驱动、R-02 退出码、R-03 输出分级、R-05 密钥契约、R-06 口令掩码、R-07 部署顺序、R-09 失败即停、R-10 幂等）。
- **deploy/deploy.md（v0.2.6）**：第 5.3 节已明确 .sh 契约不一致待办（"或将 .sh 与 .ps1 对齐（列入后续版本待办）"）——v0.2.7 正是该待办落地版本。
- **deploy/build.md（v0.2.6）**：编译方案，build-backend/build-client 已规范，无需重构。

---

## 7. 后续任务输入（供 PM/TL 编排 TASK-002~005/007）

1. TASK-002（若为 check-env 重构）：按 F-002~F-006/F-010 重构 deploy-check-env，删除硬编码、加入运行状态检查、输出统一分级。
2. TASK-003（若为 start-services 重构）：按 F-006/F-007 补充 JDK 可用性输出、统一启动方式优先级与探测确认、口令掩码。
3. TASK-004（若为 start-all 重构）：新增 deploy-start-all.ps1/.sh（F-008），复用本清单"端口/健康探测"与"部署顺序契约"。
4. TASK-005（若为单服务脚本重构）：按 F-009 对齐 4 个单服务脚本变量校验与后台启动方式。
5. TASK-007（若为 .gitignore 治理）：按第 4.3 节缺口清单执行 F-012，并遵守第 4.4 节红线。

---

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
