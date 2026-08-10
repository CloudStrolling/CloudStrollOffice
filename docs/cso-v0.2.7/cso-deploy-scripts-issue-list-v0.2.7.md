# deploy/scripts 与 .gitignore 现状问题清单（TASK-001 交付物）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**任务编号**：TASK-001（梳理 deploy/scripts 现有脚本与 .gitignore 现状并输出问题清单）
**编写人**：SSE
**日期**：2026-08-10
**关联需求**：US-004 / PRD 1.1 背景 / F-008 / F-010 / F-011 / F-012 / ADR-015 / ADR-016

> 本清单基于对 `deploy/scripts` 全部 26 个文件（25 个脚本 + .gitkeep）、项目根目录 `.gitignore`（332 行）、`deploy/deploy.md`、`deploy/env.example.json` 及 git 跟踪情况的逐项勘察与代码核对（grep 硬编码地址、文件存在性、RSA 契约静态比对、检查能力分布、输出与退出码约定、deploy-start-all 缺失等），识别出 6 类主问题（P1~P6）与若干附加发现（P7，共 14 项），作为后续重构任务 **TASK-002/003/004/005/007** 的直接依据。

---

## 1. 检查范围与方法

| 检查对象 | 范围 | 方法 |
| --- | --- | --- |
| deploy/scripts 全部脚本 | 26 个文件（含 .gitkeep） | 逐文件读取 + grep 硬编码地址 + 双平台静态比对 |
| 项目根目录 .gitignore | 332 行，10+ 分区 | 逐分区核对 + 缺口识别 |
| deploy/deploy.md | 目录树与部署步骤 | 与 deploy/scripts 实际文件比对 |
| deploy/env.example.json | 27 键配置模板 | 与脚本引用键核对 |
| git 跟踪情况 | deploy/scripts、scripts/、env.json、keys/ | `git ls-files` + `git status --porcelain` |

**核对结论**：context.md 初步识别的 6 类历史遗留问题经实际代码核对**全部属实**；cs.md 中的问题定位经逐文件核验与代码一致（个别细节以本清单为准，见 P4、P7 备注）。

---

## 2. 六类主问题（P1~P6）

### P1 硬编码默认地址（对应 F-010 / PRD 1.1 背景 / R-01 配置驱动）

| 项 | 内容 |
| --- | --- |
| **问题定位** | `deploy-check-env.ps1` 第 25-31 行（param 默认值 `NacosAddr="192.168.1.100:8848"`、`DbHost="192.168.1.101"`、`RedisHost="192.168.1.102"`）；`deploy-check-env.sh` 第 25-31 行（`NACOS_ADDR:-192.168.1.100:8848`、`DB_HOST:-192.168.1.101`、`REDIS_HOST:-192.168.1.102`）；`deploy-db-init.ps1` 第 20 行（param 默认值 `DbHost="192.168.1.101"`）；`deploy-db-init.sh` 第 21 行（`DB_HOST:-192.168.1.101`） |
| **问题表现** | ① 脚本以硬编码默认地址为主、从 env.json 加载为辅；② `.ps1` 第 41-46 行 / `.sh` 第 25-31 行以「默认值等于硬编码值」判断是否回退 env——env.json 未配置或值恰为默认值时判断脆弱，且 env 未设置时静默回退到错误地址，不报错、不退出；③ 违背 SAD G-A7「脚本内不得硬编码环境地址与凭据」与 R-01 配置驱动原则 |
| **影响** | 换环境部署时若漏配 env.json 会静默连到错误的 192.168.1.x 内网地址，检查误报成功或启动失败，排查困难 |
| **建议处置** | 全部删除硬编码默认地址；关键配置（NACOS_ADDR / DB_HOST / REDIS_HOST 等）缺失时显式报错并按「参数错误退出码 2」退出；脚本一律经 load-env 从 deploy/env.json 读取 |
| **下游任务** | TASK-002（check-env 重构）、TASK-005（单服务脚本重构）、TASK-003（start-services 重构） |

### P2 弃用脚本残留（对应 F-011 / ADR-016 / US-004）

| 项 | 内容 |
| --- | --- |
| **问题定位** | `deploy/scripts/deploy-env.ps1`（113 行，文件头自称「已弃用」「兼容保留」）、`deploy/scripts/deploy-env-template.ps1`（78 行，自称「已弃用」）、`deploy/scripts/deploy-env-template.sh`（83 行，自称「已弃用」）；三者均被 git 跟踪（`git ls-files` 确认） |
| **问题表现** | ① deploy-env.ps1 无 .sh 对版本（单版本残留，破坏双平台一一对应）；② 三者与 `load-env.ps1/.sh + deploy/env.example.json` 双份配置逻辑并存，易混淆；③ `deploy/deploy.md` 第 72-73 行目录树宣称存在 `deploy-env.ps1 / .sh` 与 `deploy-env-template.ps1 / .sh`，**实际目录中无 deploy-env.sh**（文档与事实不符）；④ deploy-env.ps1 第 67 行 `$env:NACOS_ADDR = '<NACOS_HOST>:8848'` 等仍以占位符直接写死环境变量，违反配置驱动原则 |
| **影响** | 运维人员可能误用旧脚本造成配置丢失/覆盖；目录树与实际不符误导部署；仓库残留冗余代码 |
| **建议处置** | 按 ADR-016 删除或明确弃用并移除引用（`git rm`）；同步修正 deploy/deploy.md 目录树第 72-73 行；确认无其他脚本引用 deploy-env* 后再移除（grep 引用关系） |
| **下游任务** | TASK-005（单服务脚本与残留清理）、TASK-007（.gitignore 治理时复核） |

### P3 RSA 密钥输出契约不一致（对应 F-011 / ADR-015 / US-004）

| 项 | 内容 |
| --- | --- |
| **问题定位** | `deploy-rsa-keygen.sh`（v0.1.7，92 行）第 48-54 行（`base64 -w0 "$PRIVATE_KEY_FILE"` / `openssl base64 -A` 直接编码 PEM 文件整体）、第 66-69 行（仅长度统计）、第 72-77 行（仅 openssl 文本验证，无 DER 结构校验）、第 87-91 行（直接 `cat` 完整私钥打印到日志）；对比 `deploy-rsa-keygen.ps1`（v0.2.6 已对齐 ADR-015，131 行）第 65 行（`openssl pkcs8 -topk8 -nocrypt -outform DER` 显式 PKCS#8）、第 67 行（`openssl pkey -pubout -outform DER` 公钥 X.509）、第 75-76 行（`[Convert]::ToBase64String` 单行 Base64）、第 86-113 行（契约自校验：无 PEM 头尾/无换行/严格 Base64/DER 结构偏移）、第 127-128 行（脱敏仅打印前 24 字符） |
| **问题表现** | .sh 对 PEM 文件（含 `-----BEGIN/END-----` 头尾）整体 Base64 编码，非 DER 编码单行 Base64；未生成 `.der` 文件；无契约自校验；**输出不脱敏**（完整私钥入日志，违反 NFR-004 敏感信息红线）；版本号陈旧（v0.1.7，未随 .ps1 升级） |
| **影响** | .sh 生成的 Base64 注入 env.json 后，Java 端 `Base64.getDecoder()` + `PKCS8EncodedKeySpec` / `X509EncodedKeySpec` 解码失败（网关报 RSA 公钥解析失败）；私钥明文打印构成敏感信息泄露风险 |
| **建议处置** | .sh 按 .ps1 对齐：`openssl genpkey` → `openssl pkcs8 -topk8 -nocrypt -outform DER`（私钥 PKCS#8）+ `openssl pkey -pubout -outform DER`（公钥 X.509）→ 单行 Base64（`base64 -w0` 作用于 .der 文件）；补充契约自校验（无 PEM/无换行/严格解码/DER 结构偏移：私钥 `[0]=0x30 && [7]=0x30`、公钥 `[0]=0x30 && [4]=0x30 && [19]=0x03`）；输出脱敏（仅前 24 字符）；版本号升级；不得破坏 ADR-015 |
| **下游任务** | TASK-006（如划归 rsa-keygen 对齐任务）或 TASK-005（按实际任务划分） |

### P4 可用性检查与运行状态检查能力分散（对应 F-002~F-006 / F-010）

| 项 | 内容 |
| --- | --- |
| **问题定位** | `deploy-check-env.ps1` 第 81-84 行（1.1 Nacos 可用性检查误放「中间件可用性检查」段内做 HTTP 探测）与第 129-132 行（3.1 Nacos 端口连通性检查重复 HTTP 探测 `/nacos/`）；`deploy-check-env.sh` 第 60-62 行与第 103-105 行同样重复；check-env 整体无「运行状态检查」能力（无进程/服务状态检测）；`deploy-start-services.ps1/.sh` 具备运行检测与启动框架（第 118-223 行 / 第 146-223 行）但未纳入 JDK 可用性结论 |
| **问题表现** | ① Nacos 可用性检查与连通性检查重复 HTTP 探测（同一 URL 探测两次）；② 检查范围混入 Maven/Git/JAVA_HOME/SQL 文件等「开发环境项」，与 F-002~F-006（JDK/MariaDB/Redis/Nacos 可用性 + 运行状态）不对齐；③ 「运行状态检查」能力在 check-env 中完全缺失；④ start-services 不输出 JDK 可用性结论（F-006 要求）；⑤ 双平台检查项数量与结构不一致（经逐行核对 .ps1 实际 10 项 Check 调用、.sh 实际 13 项：.sh 多出 3.2 MariaDB 连通、3.3 Redis 连通、4.3 Maven settings，SQL 检查实现方式亦不同） |
| **影响** | 部署前检查结果不可信（Nacos 状态判断重复但语义混乱）、运行状态需靠人工另查、JDK 未纳入导致基础环境漏检、双平台输出不一致 |
| **建议处置** | 重构 check-env 对齐 F-002~F-006：可用性检查（命令/安装/版本）与运行状态检查（进程/服务/端口探测）分离；Nacos 探测统一使用 2.x 的 v1 readiness 接口（`/nacos/v1/console/health/readiness`，v2 接口在 2.3 部分 404）；start-services 补充 JDK 可用性结论；双平台检查项一一对应；无关开发环境项移除或降级为可选 |
| **下游任务** | TASK-002（check-env 重构）、TASK-003（start-services 重构） |

### P5 输出格式与退出码约定不统一（对应 F-011 / R-02 / R-03）

| 项 | 内容 |
| --- | --- |
| **问题定位** | `deploy-check-env.ps1` 第 51-68 行（Check 函数仅输出「通过/失败」两档，无「警告」分级）、第 154-159 行（失败 `exit 1`、成功 `exit 0`）；`deploy-check-env.sh` 第 34-47 行（`eval "$cmd"` 执行命令字符串，第 39 行有注入/引号风险，如 `-p'$DB_PASSWORD'` 传参）、第 142-149 行（失败 `exit 1`、成功 `exit 0`）；`deploy-start-services.ps1` 第 46-50 行（`Write-Result` 中 icon 为 `""`/`""`/`""` 空字符，emoji 实际不显示）、第 211-219 行（**有警告仍 `exit 0`**，第 219 行 `if ($fail -gt 0) { exit 1 } else { exit 0 }`）；`deploy-start-services.sh` 第 57-64 行（print_result 用 `✅/⚠️/❌` emoji + ANSI 色）、第 225-239 行（**有警告仍 `exit 0`**）；`deploy-start-auth/biz/system/gateway` 各单服务脚本错误提示用 `❌` 前缀但无统一分级 |
| **问题表现** | ① check-env 无「警告」分级（仅通过/失败）；② start-services 用 emoji + ANSI/PowerShell 颜色，check-env 无 emoji，同版本脚本风格不统一；③ 退出码约定有分歧：check-env 失败 `exit 1`、start-services 有警告仍 `exit 0`，均无「参数错误 2 / 依赖缺失 3」细分；④ `.sh` 的 `eval "$cmd"` 执行字符串拼接命令存在注入与引号转义风险（`-p'$DB_PASSWORD'` 在 `set -x` 调试时会泄露明文口令） |
| **影响** | 脚本执行结果难以机器化断言（CI/自动化回归无法区分警告与失败）、退出码语义不一致导致联动脚本误判、eval 拼接有安全与调试泄露风险 |
| **建议处置** | 统一「通过/警告/失败」三级输出（.ps1 用 Write-Host + 颜色、.sh 用 printf + 可选 ANSI，双平台分级一致）；统一退出码：全部通过 0 / 失败非零（参数错误 2 / 依赖缺失 3 可选细化）、警告默认 0；.sh 将 eval 改写为直接命令 + 数组参数（如 `cmd=(mariadb -h "$host" ...); "${cmd[@]}"`）；口令类参数掩码显示（`****`）、日志不打印明文 |
| **下游任务** | TASK-002、TASK-003、TASK-005（按脚本归属分别对齐） |

### P6 缺少一键启动总入口（对应 F-008 / US-003 / R-07 部署顺序 / R-09 失败即停）

| 项 | 内容 |
| --- | --- |
| **问题定位** | `deploy/scripts` 目录中不存在 `deploy-start-all.ps1` 与 `deploy-start-all.sh`（glob 目录清单确认）；现有仅 4 个单服务启动脚本：`deploy-start-gateway.ps1/.sh`、`deploy-start-auth.ps1/.sh`、`deploy-start-biz.ps1/.sh`、`deploy-start-system.ps1/.sh` |
| **问题表现** | 无「按部署顺序（gateway → auth → biz → system）一键启动全部 Java 后台服务」的总入口；当前需手工逐个窗口启动 4 个服务；单服务脚本为前台阻塞启动（.ps1 第 49/57/41/41 行直接 `java`、.sh 第 59/73/58/56 行 `exec java`），无后台化、无健康确认、无失败即停 |
| **影响** | 部署效率低、易漏服务、无法自动化编排；前台阻塞方式不适合无人值守/CI 场景 |
| **建议处置** | 新增 `deploy-start-all.ps1/.sh` 总入口：校验 4 个 jar 与关键环境变量 → 按 gateway → auth → biz → system 顺序后台启动（.ps1 `Start-Process -RedirectStandardOutput`、.sh `nohup ... &`）→ 逐服务轮询健康端点（`GET /api/v1/{module}/health`，建议复用项目自定义健康端点）确认就绪 → 任一失败即停（退出非零）；部署顺序契约 gateway(9000) → auth(9100) → biz(9200) → system(9400) |
| **下游任务** | TASK-004（新增 deploy-start-all） |

---

## 3. 附加发现（P7，供参考，不属 6 类主问题）

| 编号 | 问题定位 | 问题表现 | 影响 | 建议处置 |
| --- | --- | --- | --- | --- |
| P7-01 | `deploy-start-*.ps1` 第 49/57/41/41 行、`.sh` 第 59/73/58/56 行 | 单服务脚本均为**前台阻塞启动**，无后台化/独立窗口/健康确认 | 一键启动编排依赖后台化（F-008） | TASK-005 统一后台启动方式或明确「前台运行，供调试」定位 |
| P7-02 | `deploy-start-auth.ps1` 第 18-19 行 / `deploy-start-auth.sh` 第 21-22 行（校验 9 变量）；`deploy-start-gateway.ps1` 第 18-28 行 / `.sh` 第 20-29 行（校验 NACOS_ADDR/RSA_PUBLIC_KEY）；`deploy-start-biz.ps1` 第 18-22 行（**仅校验 NACOS_ADDR**）vs `deploy-start-biz.sh` 第 21-29 行（校验 NACOS_ADDR/DB_PASSWORD）；`deploy-start-system.ps1` 第 18-22 行（仅 NACOS_ADDR）vs `.sh` 第 20-28 行（NACOS_ADDR/DB_PASSWORD） | **变量校验范围双平台不一致**：biz/system 的 .ps1 比 .sh 少校验 DB_PASSWORD；各服务所需变量清单未统一明示 | 同环境 Windows 启动缺少 DB_PASSWORD 校验，连接失败后才暴露 | TASK-005 统一每服务的「所需变量清单」（biz/system 用 DB_USER、auth 用 DB_USERNAME 的差异保持），.ps1 与 .sh 对齐 |
| P7-03 | `deploy-start-auth.sh` 第 53 行 | 显示 `$DB_AUTH_NAME`，env.json 无此键（未定义显示为空），.ps1 第 49 行显示 `$env:DB_HOST:$env:DB_PORT` 无双平台对应 | 显示层误导运维 | TASK-005 对齐显示信息 |
| P7-04 | `deploy-start-biz.sh` 第 43 行、`deploy-start-system.sh` 第 42 行 | 显示 `数据库 URL: ${DB_URL:-jdbc:mariadb://${DB_HOST:-localhost}:3306/...}`——DB_URL 未从 env.json 读取且默认值含 `localhost` 硬编码；.ps1 无对应 DB_URL 显示 | 显示信息不真实、含硬编码默认值 | TASK-005 从 env.json 读取 DB_HOST 拼装显示或移除误导性默认值 |
| P7-05 | `deploy-check-env.ps1` 第 35 行 | 孤立死代码行 `$MyInvocation.MyCommand.ScriptBlock.Module.SessionState.Path.CurrentFileSystemDrive`（无赋值、无输出）。**备注**：cs.md 记录为 load-env.ps1 第 35 行，经实际核对 load-env.ps1 干净，此孤立行实际位于 deploy-check-env.ps1 第 35 行，本清单以实际代码为准 | 无功能影响，属代码噪声 | TASK-002 重构时删除 |
| P7-06 | `deploy-check-env.ps1` 第 89-90 行 | `$connStr` 含明文密码；第 90 行 `$conn = New-Object System.Data.Common.DbProviderFactory` 为无效创建（随后未使用，真正连接走第 92 行 mariadb 命令） | 死代码 + 连接字符串明文（未输出但需复核） | TASK-002 删除无效创建、改用 mysqladmin ping / SELECT 1 且口令参数掩码 |
| P7-07 | `deploy-db-init.ps1` 第 35-36 行、`deploy-db-init.sh` 第 37-44 行 | SQL 文件版本号 `auth-init-v0.1.5.sql` / `auth-init-v0.1.6.sql` 在脚本内硬编码，未读取 `scripts/sql` 目录清单 | 新增版本 SQL 需改脚本 | 建议改为读取目录清单（本任务仅记录现状） |
| P7-08 | `scripts/deploy-rsa-keygen.ps1`、`scripts/deploy-rsa-keygen.sh`、`scripts/deployment-guide.md` | 根目录 `scripts/` 下存在旧路径脚本残留（git 已跟踪），与 deploy/scripts 新版重复 | 历史路径残留易误导 | 后续任务按需清理或标注弃用（不在本任务范围，仅提示） |
| P7-09 | `deploy/deploy.md` 第 72-73 行 | 目录树宣称存在 `deploy-env.sh`，实际不存在（文档与事实不符） | 误导部署人员 | 随 P2 处置同步修正文档 |
| P7-10 | `deploy-start-services.sh` 第 66 行、`deploy-check-env.sh` 第 66 行、`deploy-db-init.sh` 第 49/56 行等 | mariadb 命令 `-p'$DB_PASSWORD'` 明文出现在命令字符串中（未打印，但 `set -x` / eval 调试时会泄露） | NFR-004 敏感信息泄露风险 | 口令参数掩码、避免 eval 拼接、建议环境变量方式传参 |
| P7-11 | `deploy-check-env.ps1` 第 81-84 行、`deploy-start-services.ps1` 第 152 行等 | Nacos HTTP 探测使用 `/nacos/` 页面 HTML 匹配，未使用 Nacos 2.x 稳定的 v1 readiness 接口（WS 资料确认 v2 接口在 2.3 部分版本 404） | 探测结果不稳定 | TASK-002/003 统一使用 `/nacos/v1/console/health/readiness` |
| P7-12 | `deploy-start-services.ps1` 第 167-168 行、`.sh` 第 184-186 行 | Nacos 启动后固定等待 8 秒再探测，非循环轮询 + 超时上限 | 慢环境启动未就绪误判失败 | 改为循环探测 + 超时上限 |
| P7-13 | 双平台版本号 | .sh 脚本版本号陈旧（check-env/db-init/rsa-keygen/start-* 多为 v0.1.7，start-services.sh 为 v0.2.0），.ps1 无版本号或已更新（rsa-keygen.ps1 为 v0.2.6） | 版本追溯困难 | 重构时统一版本号标注 |
| P7-14 | `deploy/scripts` 下全部 25 个脚本文件头（build-backend/build-client/deploy-check-env/deploy-db-init/deploy-env/deploy-env-template/deploy-rsa-keygen/deploy-start-*/deploy-start-services/load-env 的 .ps1 与 .sh） | **全部脚本缺失 SPDX-License-Identifier（Apache-2.0）与版权声明**（UT-141-1 静态核对确认：25/25 缺失，0/25 含 SPDX 头） | 违反 project.md 编码规范（脚本文件头须保留 SPDX 与版权声明），版权与许可声明缺失，合规性风险 | TASK-005 重构时统一补齐全部脚本文件头 SPDX-License-Identifier（Apache-2.0）与版权声明（参照本项目文档头部格式）；补齐后 UT-141-1 应转通过 |

---

## 4. .gitignore 现状与缺口（供 F-012 治理依据，TASK-007 执行）

### 4.1 现状（根目录 .gitignore，332 行）

已有 10+ 分区且实际生效（`git status --porcelain` 无临时文件污染；`scripts/API-TEST/__pycache__/`、`deploy/env.json`、`deploy/keys/` 均未被跟踪）：
- 操作系统（Mac/Windows/Linux）、通用 IDE/编辑器、AI 开发工具、前端/Node.js、Python、Java/Maven/Gradle、C/C++、Rust、Go、PHP、Dart/Flutter
- 客户端构建产物（`deploy/cloudoffice-flutter-app/web/*`、`windows/*` 带路径前缀 + `!*.gitkeep` 白名单）
- 数据库/缓存/日志/临时（`*.log`、`logs/`、`tmp/`、`temp/`、`.cache/`）
- 环境密钥（`keys/`、精确 `env.json`、`.env.*` 白名单 `!.env.example`、`docs2/`）
- 包管理器、压缩包

### 4.2 识别缺口（新增/加固规则建议，全部带路径前缀或精确模式）

| 类别 | 缺口文件/模式 | 建议规则 |
| --- | --- | --- |
| JVM/应用调试产物 | 堆转储 `*.hprof`、JVM 崩溃日志 `hs_err_pid*.log`、`dump/`、`*.dump`、`heapdump.*` | `*.hprof`、`hs_err_pid*.log`、`dump/`、`*.dump`、`heapdump.*` |
| Maven/构建中间产物 | `.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated` | `*.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated` |
| 测试产物与缓存 | 独立测试报告目录（`target/` 已排除但补充独立产物）、接口测试中间文件（token 缓存、临时报告） | `**/surefire-reports/`、`**/test-results/`、`test-output/`；API-TEST 临时 token/report 文件（精确模式） |
| 工具残留 | API 调试会话 `*.har`、`*.saz`、`*.chls`；编辑器历史 `*.history`、`*.session` | `*.har`（评估）、`*.saz`、`*.chls`、`*.history`、`*.session` |
| 调试临时输出 | `*.trace`、`*.dump`（已有 `*.log` 覆盖但补充） | `*.trace`（谨慎，可加路径前缀避免误伤源码扩展名） |

### 4.3 治理红线（不得误伤）

- `deploy/env.example.json`（模板，须入库）：现有规则为精确 `env.json`，安全，不得改为 `env.json*` 通配。
- `deploy/scripts/.gitkeep`、`deploy/cloudoffice-flutter-app/**/.gitkeep`：白名单 `!*.gitkeep` 已保留，新增规则不得覆盖。
- `pom.xml`、`bootstrap.yml`、`*.java`、`*.dart`、`*.md`：新规则须带路径前缀或精确模式，避免全局通配误伤。
- 已跟踪文件不受新规则影响；如需停止跟踪既有文件须 `git rm --cached`（本任务仅识别缺口，不执行）。

---

## 5. 后续任务映射（重构依据）

| 下游任务 | 依据问题 | 重构要点 |
| --- | --- | --- |
| TASK-002（check-env 重构） | P1、P4、P5、P7-05/06/11 | 删除硬编码默认地址、可用性检查与运行状态检查分离、Nacos 用 v1 readiness、输出三级分级与退出码统一、清理死代码 |
| TASK-003（start-services 重构） | P1、P4、P5、P7-10/11/12 | 补充 JDK 可用性结论、统一启动方式与探测确认（循环轮询 + 超时）、口令掩码、输出分级与退出码 |
| TASK-004（start-all 新增） | P6 | 新增 deploy-start-all.ps1/.sh：按序启动 + 逐服务健康确认 + 失败即停 |
| TASK-005（单服务脚本重构） | P1、P2、P3、P5、P7-01/02/03/04 | 变量校验清单统一（.ps1/.sh 对齐）、后台启动、显示层修正、删除/清理弃用脚本残留、rsa-keygen.sh 契约对齐 |
| TASK-007（.gitignore 治理） | 第 4 节 | 按 4.2 缺口清单补充规则，遵守 4.3 红线 |

---

## 6. 结论

本清单完整覆盖 6 类主问题（P1 硬编码默认地址、P2 弃用脚本残留、P3 RSA 密钥输出契约不一致、P4 可用性/运行状态检查能力分散、P5 输出与退出码不统一、P6 缺一键启动总入口）与 14 项附加发现（P7），每条均含问题定位（文件 + 行号）、影响与建议处置，可直接作为 TASK-002/003/004/005/007 的重构依据。所有定位均经实际代码核对（grep 硬编码地址、文件存在性、RSA 契约静态比对、双平台数量/结构比对、git 跟踪确认），与 v0.2.7 基线一致。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
