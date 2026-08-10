# 代码审核报告
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**审核人**：TL

## 1. 审核范围

本次版本（v0.2.7）聚焦 **部署脚本体系重构**（deploy/scripts 全部脚本）与 **仓库清洁度治理**（.gitignore），不涉及后端业务代码、接口契约与数据库结构变更。审核范围如下：

| 类别 | 文件/目录 | 对应任务 |
| --- | --- | --- |
| 统一配置加载模块 | deploy/scripts/load-env.ps1 / load-env.sh | TASK-002 |
| 环境可用性检查 + 运行状态检测 | deploy/scripts/deploy-check-env.ps1 / .sh | TASK-003 |
| 基础设施一键启动 | deploy/scripts/deploy-start-services.ps1 / .sh | TASK-004 |
| 后端服务按序一键启动 | deploy/scripts/deploy-start-all.ps1 / .sh | TASK-005 |
| 单服务启动 | deploy/scripts/deploy-start-gateway/auth/biz/system.ps1 / .sh（8 个） | TASK-006 |
| RSA 密钥生成契约对齐 | deploy/scripts/deploy-rsa-keygen.ps1 / .sh | TASK-007 |
| 弃用脚本清理 | deploy/scripts（deploy-env.ps1 / deploy-env-template.ps1/.sh 已删除） | TASK-008 |
| 仓库治理 | 项目根目录 .gitignore | TASK-009 |
| 契约总体验证 | docs/cso-v0.2.7/cso-script-contract-verification-v0.2.7.md | TASK-010 |
| 历史资产（语法/契约校验范围） | deploy/scripts/deploy-db-init / build-backend / build-client | 历史（v0.1.7） |
| 独立副本（工作区未提交修改） | scripts/deploy-rsa-keygen.ps1 / .sh | 本版本改动关联 |

审核依据：URS/PRD v0.2.7（F-001~F-012、US-001~US-005）、LLD v0.2.7（模块划分、R-01~R-16 业务规则）、SAD v0.2.7（G-A6/G-A7、ADR-015/ADR-016）、任务清单（TASK-001~010 全部已完成）、测试用例文档与 TASK-010 契约验证报告、git 提交记录（669b5a9..HEAD，TASK-001~010 共 17 个提交）与工作区状态。

## 2. 审核结论

**总体结论：通过（附整改建议）。**

本次版本核心交付物质量良好：
- **契约合规**：deploy/scripts 核心 1~9 号脚本对（18 个脚本）全部通过语法校验（.ps1 Parser.ParseFile 0 错误 / .sh bash -n 退出码 0），RSA 密钥输出契约（ADR-015：DER 单行 Base64、PKCS#8/X.509、无 PEM 头尾无换行）双平台一致，输出分级与退出码约定（失败非零 0/1）统一，无硬编码环境地址（核心脚本 0 命中）；
- **安全红线总体守住**：口令掩码（`****`）、Redis 口令经 REDISCLI_AUTH 环境变量通道、RSA 私钥输出脱敏（前 24 字符前缀）、load-env 不打印敏感值，均符合 LLD R-06 与 SAD 安全约束；
- **架构合规**：模块依赖方向（load-env → check-env/start-services/start-all/start-single）与 LLD 一致，无跨层绕过、无弃用脚本残留；
- **测试覆盖全面**：TASK-001~009 累计 210 个测试用例，10 个单元测试脚本 + 1 个接口测试脚本，TASK-010 契约验证对照 PRD 第 7 章 8 条验收标准全部符合。

**需关注的问题（审核只输出意见，不修改代码）**：
1. **高优先级**：`scripts/` 根目录残留 deploy-rsa-keygen.sh 独立副本（工作区未提交修改），其输出仍为 **PEM 文件整体 Base64（旧逻辑）** 且 **完整打印 RSA_PRIVATE_KEY 明文**，与 ADR-015 契约及"NFR-004 完整私钥绝不打印"红线相悖，文件头注释却声称"与 deploy/scripts 版本对齐"（实际未对齐）——见 S-02 / Q-01 / A-03；
2. **中优先级**：deploy-check-env 的 MariaDB SELECT 1 检测以 `-p"$DB_PASSWORD"` 命令行参数传口令，进程列表可见（见 S-01）；deploy-start-services 兜底启动可执行文件（mysqld/redis-server）时未携带 env.json 端口/密码配置，存在"启动实例与配置不符"隐患（见 S-03）；
3. **建议改进项**：.ps1 输出分级对齐（P3）、公共函数抽取、Linux 真实环境端到端验证、.ps1 公私钥成对自校验等（见 Q-02/Q-03/T-01/T-03）。

## 3. 问题清单

### 3.1 安全漏洞（注入、越权、硬编码密钥、敏感信息泄露）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 | 处理状态 |
| --- | --- | --- | --- | --- | --- |
| S-01 | 中 | deploy/scripts/deploy-check-env.ps1 第 146 行、deploy-check-env.sh 第 154 行 | MariaDB SELECT 1 连通性检测以 `-p"$env:DB_PASSWORD"` / `-p"$DB_PASSWORD"` 命令行参数传递口令：日志虽掩码为 `****`，但口令会出现在进程命令行中，Windows（Get-CimInstance Win32_Process）/Linux（ps -ef）均可读取，属进程级口令泄露。TASK-010 验证报告 4.6 仅对历史脚本 deploy-db-init 记录 P8，核心脚本 check-env 同样存在此模式且未记录 | 改用 MySQL/MariaDB 官方支持的 `MYSQL_PWD` 环境变量传递口令（如 `$env:MYSQL_PWD = $env:DB_PASSWORD`，命令中省略 -p），或改经 `--defaults-extra-file` 临时配置文件（用后删除）；至少应在注释与验证报告中记录该边界 | **已修复**（2026-08-10，SSE）：双平台改用 MYSQL_PWD 环境变量传递口令、命令省略 -p，调用后恢复/清除环境变量；决策记录见第 5 章 |
| S-02 | 高 | scripts/deploy-rsa-keygen.sh 第 62~73、99~107 行（工作区未提交修改） | 根目录 scripts/ 副本与 deploy/scripts 版本**未同步**：① 第 64/68 行 `base64 -w0 "$PRIVATE_KEY_FILE"` 对 **PEM 文件**整体编码（含 `-----BEGIN/END-----` 头尾），输出为 PEM 整体 Base64，违反 ADR-015"DER 编码单行 Base64"契约——若运维误用该副本生成密钥注入 env.json，Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码必然失败（网关启动报 RSA 公钥解析失败，v0.2.6 修复过的缺陷复发）；② 第 102~106 行 `echo "  \"RSA_PRIVATE_KEY\": \"$(cat $PRIVATE_KEY_B64_FILE)\""` **完整打印私钥明文**到控制台，违反 NFR-004 敏感信息红线与 SAD"私钥不得入库、不得写入日志"约束；③ 文件头注释（第 6~8 行）声称"功能与 deploy/scripts/deploy-rsa-keygen.sh（v0.2.7 重构版）对齐"，实际逻辑未对齐，声明与事实不符，易误导使用者 | 删除 scripts/deploy-rsa-keygen.sh/.ps1 副本（部署脚本唯一落点为 deploy/scripts，符合 ADR-013/ADR-016），或将其改为仅打印提示的 thin wrapper（提示用户使用 deploy/scripts 版本）；在删除前不得提交当前副本内容；同时核对 scripts/deployment-guide.md 与 deploy/deploy.md 的脚本路径引用并同步更新 | **已修复**（2026-08-10，SSE）：先 `git restore` 还原 coding-comment 未提交注释修改，再 `git rm` 删除两个根目录副本；同步更新 scripts/deployment-guide.md 与 docs/deployment-guide.md 的脚本路径引用；deploy/scripts 正确版本保持不变；详见第 5 章 |
| S-03 | 低 | deploy/scripts/deploy-start-services.ps1 第 209~231、267~289 行；deploy-start-services.sh 第 211~232、276~292 行 | "可执行文件"兜底启动路径直接 `Start-Process mysqld/mariadbd/redis-server`（.sh 为 `nohup redis-server` / `mysqld_safe`）且**未携带 env.json 中的端口/密码等配置**：若 env.json 配置了 REDIS_PASSWORD 而本机 Redis 无配置文件（默认无密码 6379），启动出的实例与 env.json 不符，后续带 REDISCLI_AUTH 的 ping 探测将失败（AUTH 被无密码实例拒绝）导致"启动成功但探测失败"的误报；mysqld 同理（数据目录/端口/凭据未指定） | 兜底启动时按 env.json 附加启动参数（Redis 至少 `--port $REDIS_PORT`，若配置了密码提示需 `--requirepass`；MariaDB 提示使用系统服务或已初始化的数据目录），或在该路径输出明确提示"已用默认配置启动，请核对与 env.json 的一致性"；探测失败时给出该提示而非仅报超时 | **已修复**（2026-08-10，SSE）：双平台兜底启动均附加 `--port`（MariaDB）与 `--port/--requirepass`（Redis）配置参数，探测失败提示补充"核对实例端口/口令与 env.json 一致性"；详见第 5 章 |
| S-04 | 低（遗留） | deploy/scripts/deploy-db-init.ps1 第 20~23 行、deploy-db-init.sh 第 21~24 行 | 历史资产（v0.1.7）硬编码默认地址与凭据 `192.168.1.101 / 3306 / root / <DB_PASSWORD>`，静态字面量违反"脚本内无硬编码环境地址与凭据"红线；运行时经 load-env 8 项关键配置校验兜底（缺失即退出非零，不落硬编码值），行为合规 | 后续版本将 db-init 纳入能力矩阵时修复：param/默认值改为仅从 env 读取，或将该脚本标注弃用（验证报告 P1 已记录，本报告复述为遗留项） | **已修复**（2026-08-10，SSE）：deploy-db-init.ps1/.sh param 默认值改为空/无默认，连接参数一律仅从 env.json 读取；同时补 SPDX 头；其口令命令行传参（P8）一并改为 MYSQL_PWD；详见第 5 章 |
| S-05 | 低（观察） | deploy/scripts/load-env.sh 第 38 行（jq 分支） | `jq -r 'to_entries \| .[] \| "export \(.key)=\(.value \| @sh)"'`：**值**经 @sh 正确转义，但**键名**未转义（直接拼接）。若 env.json 键名含空格/分号等特殊字符，eval 时存在拼接注入风险；键名来自运维本地受控文件、非外部输入，实际风险极低，且缺失校验仅输出键名，触发面有限 | 防御性改进：键名同时经 `@sh` 转义，或对键名做白名单/正则校验（`^[A-Za-z_][A-Za-z0-9_]*$`）；load-env.ps1 的 `Set-Item -Path "env:$($_.Name)"` 同理可加键名合法性校验 | **已修复**（2026-08-10，SSE）：load-env.sh jq 分支键名经 `@sh` 转义 + 白名单正则校验（非法键名报错退出非零），python3 分支同步增加 shlex.quote 键名转义与正则校验；load-env.ps1 增加键名合法性校验；详见第 5 章 |

### 3.2 性能陷阱（N+1 查询、内存泄漏、不必要的循环、大数据量全表扫描）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| P-01 | 低（观察） | deploy/scripts/deploy-check-env.sh 第 55~61 行、deploy-start-services.sh 第 55~61 行（has_svc 函数） | `systemctl list-units --type=service --all \| grep -qw` 每次调用全量枚举 systemd 服务列表并 grep；调用次数有限（每服务安装检测/运行检测各 1 次，不在循环探测内重复调用），实际开销可忽略；若未来在 wait_for_service 探测循环中复用该函数将放大开销 | 维持现状即可；如后续重构可改为 `systemctl is-active`/`systemctl status` 定向查询替代全量枚举 |
| P-02 | 低（观察） | deploy/scripts/deploy-start-all.ps1 第 83~91 行（Wait-HealthUp） | 健康确认最坏耗时约 `重试 30 次 × (HTTP 3s 超时 + 2s 间隔)` ≈ 2.5 分钟/服务，4 个服务最坏约 10 分钟；属启动等待合理范围（LLD 第 12 章约定），但 HTTP 探测与 TCP 探测串行执行，当服务未监听时每次循环需等满 HTTP 3s 超时才转 TCP（TCP 探测本身 1s 内返回） | 可在循环内先做 TCP 探测（1s 内失败），失败再做 HTTP 探测，缩短端口未开时的单次轮询耗时；非必须，可优化项 |
| P-03 | 低（观察） | deploy/scripts/deploy-start-services.ps1 第 134~143 行（Wait-ServiceUp） | 循环探测 30s/2s 固定，单次探测含 TCP 1s 超时，无资源泄漏（TcpClient 均 finally Dispose / 命令子进程自然结束）；.sh 侧 `nohup` 后台进程由系统接管，脚本退出不误杀，符合 LLD 第 12 章"脚本退出不误杀"要求 | 无问题，观察项 |

### 3.3 代码质量（重复代码、过长函数、命名混乱、缺乏注释）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 | 处理状态 |
| --- | --- | --- | --- | --- | --- |
| Q-01 | 中 | scripts/deploy-rsa-keygen.ps1 / .sh（根目录副本，工作区未提交） | 与 deploy/scripts 版本形成**双副本双维护源**且内容漂移：.sh 副本仍为旧逻辑（PEM 整体 Base64 + 完整密钥打印），.ps1 副本已与新版本一致（DER 单行 + 脱敏）；TASK-007 仅重构了 deploy/scripts 版本，根目录副本只补了 SPDX 头与说明注释、未同步逻辑。违反 ADR-013"部署资产集中化"与 ADR-016"deploy/scripts 为脚本唯一落点"的设计意图，且脚本头注释与实际内容不符 | 删除 scripts/deploy-rsa-keygen.* 副本，或改为 thin wrapper（`& "$(dirname $PSScriptRoot)/deploy/scripts/deploy-rsa-keygen.ps1" @args` / 转发执行 deploy/scripts 版本）；同步核对 scripts/deployment-guide.md 引用并更新 | **已修复**（2026-08-10，SSE）：与 S-02 一并处理，根目录副本已 git rm 删除，deploy/scripts 为唯一落点；引用同步见第 5 章 |
| Q-02 | 低 | deploy/scripts/deploy-rsa-keygen.ps1（deploy/scripts 版本） | 输出风格与 .sh 版本不一致：.ps1 无 `[通过]/[失败]` 分级前缀与汇总行（直接用 Write-Host/Write-Error），.sh 有 print_result 分级 + 汇总行；双平台退出码约定一致（失败 exit 1）、密钥契约一致，仅展示层不一致（验证报告 P3 已记录） | 后续版本将 .ps1 输出对齐 .sh 的分级与汇总行（低风险纯输出层改动） |
| Q-03 | 低 | deploy/scripts/deploy-check-env.ps1 与 deploy-start-services.ps1 等 8 个 .ps1 | `Write-Result`、`Test-TcpPort`、`Split-Csv` 等函数在多脚本间复制粘贴重复定义（.sh 侧 has_cmd/has_svc/tcp_port_open 同理），逻辑变更需多处同步，存在漂移风险；双平台脚本无法像代码一样共享库，可接受但增加维护成本 | 可选优化：抽取公共函数模块（如 common-functions.ps1 / .sh），load-env 已实现配置层复用，函数层复用可作为后续版本改进项；至少保持现状"同名函数语义一致"的纪律 |
| Q-04 | 低 | deploy/scripts/deploy-start-services.ps1 第 316 行 | Nacos 启动经 `Start-Process cmd.exe /c "startup.cmd -m standalone"`：路径含空格已用引号包裹，但若 NACOS_HOME 路径含 `&`、`^` 等 cmd 特殊字符仍可能解析异常（load-env 未限制 NACOS_HOME 字符集） | 可选：改用 `Start-Process -FilePath $nacosStartup` 直启 .cmd（PowerShell 可直接执行），或对 NACOS_HOME 做路径合法性提示 |
| Q-05 | 低（观察） | .gitignore 第 243、349~351 行 | `dump/`、`*.history`、`*.session`、`*.trace` 等全局规则语义较宽（LLD 6.8 要求"带路径前缀或精确模式"）；已验证当前仓库无同名源码扩展名、无误伤（TASK-010 UT-240 动态复核通过），但后续新增源码目录时存在误伤风险 | 维持现状；后续新增文件类型时注意复核这些宽规则，必要时加路径前缀收紧 |

### 3.4 架构合规性（分层是否清晰、是否违反依赖方向、是否绕过已定义的接口）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| A-01 | 无问题 | deploy/scripts 全部脚本 | 模块分层与 LLD 一致：load-env（配置加载）→ check-env（可用性检查）/ start-services（基础设施启动）/ start-all（后端按序启动）/ start-single（单服务启动）；依赖方向正确（下游依赖 load-env，不反向）；rsa-keygen 独立（不依赖 load-env，符合 LLD 2.2 边界"独立密钥生成工具"）；build-backend/build-client 不依赖 load-env 属合规（构建脚本无需环境配置）；未发现绕过 load-env 直接读 env.json 的路径 | 无需处理 |
| A-02 | 低 | deploy/scripts/deploy-start-all.ps1/.sh 与 deploy-start-{svc}.ps1/.sh | LLD 类图标注 `StartAll --> StartSingle`（复用单服务启动逻辑），实际实现为各脚本**独立复制**启动/健康确认逻辑（.ps1 各自定义 Test-HttpOk/Wait-HealthUp，.sh 各自定义 http_ok/wait_health_up），非真正复用；行为一致但存在多份实现 | 保持"逻辑一致"现状（TASK-010 FT-157 已验证一致性）即可；后续可抽取公共函数模块实现真实复用（同 Q-03） |
| A-03 | 中 | scripts/deploy-rsa-keygen.ps1 / .sh（根目录） | 根目录残留部署脚本副本，违反 ADR-013"根目录 deploy 为部署资产唯一落点"与 ADR-016"deploy/scripts 脚本体系"的架构约束；副本逻辑与主版本漂移（.sh 仍为旧 PEM 契约），破坏"双平台契约一致"架构目标 | 删除或改为转发 wrapper（同 S-02 / Q-01），保证部署脚本唯一落点为 deploy/scripts | **已修复**（2026-08-10，SSE）：与 S-02/Q-01 一并删除根目录副本，部署脚本唯一落点恢复为 deploy/scripts，符合 ADR-013/ADR-016；详见第 5 章 |

### 3.5 测试覆盖（关键路径是否有测试、边界条件是否覆盖）

| 编号 | 严重程度 | 文件位置 | 问题描述 | 建议 |
| --- | --- | --- | --- | --- |
| T-01 | 中 | scripts/API-TEST/cso-unit-test-*-v0.2.7.ps1（10 个）；TASK-010 验证报告 §1 | .sh 脚本仅在本机 git-bash 执行 `bash -n` 语法校验（验证报告注明"WSL 不可用（Hyper-V 未启用）"），**未在真实 Linux 环境执行验证**：systemctl/sudo/nohup/mysqld_safe/`/dev/tcp` 等 Linux 特有启动与探测路径无真实运行证据；双平台"行为一致"的结论主要基于静态比对（FT-154~157），非两端实跑 | 在真实 Linux 部署环境（或 CI，如 GitHub Actions ubuntu runner）补做端到端验证：`bash -n` + 关键场景实跑（check-env 各环境 / start-services 启动确认 / rsa-keygen 契约自校验），并记录验证证据 |
| T-02 | 低 | scripts/API-TEST/cso-api-test-v0.2.7.py；TASK-010 验证报告 §2 | 单元测试以静态断言/契约校验为主（源码字符串断言、语法解析），真实"启动 MariaDB/Redis/Nacos → 启动 4 个后端服务"的端到端链路依赖真实环境，属部署验收范畴；TASK-010 已核对 PRD 8 条验收标准全部符合，回归记录显示 auth 9100/网关 9000 探活通过，但 4 服务全链路一键启动的真实执行未在版本内记录 | 在部署验收（阶段 4）或 CI 中执行 deploy-start-all 真实链路并记录结果；如已执行请补充到回归测试记录 |
| T-03 | 低 | deploy/scripts/deploy-rsa-keygen.ps1；scripts/API-TEST/cso-unit-test-rsa-key-contract-v0.2.7.ps1 | .ps1 版本无"公私钥成对"自校验（.sh 第 185~188 行有，由私钥派生公钥比对），验证报告 P7 观察项；测试用例覆盖了 .sh 的成对校验，.ps1 侧无对应断言 | 后续版本在 .ps1 增加成对校验（读回 DER 私钥 → openssl pkey -pubout 派生公钥 → 与 public_key.der Base64 比对），并补充测试用例 |
| T-04 | 无问题 | docs/cso-v0.2.7/cso-testcase-v0.2.7.md；cso-script-contract-verification-v0.2.7.md | 测试覆盖充分：TASK-001~009 累计 210 个用例（P0 优先），边界与异常场景覆盖完整（env.json 缺失/非法 JSON、关键配置缺失、口令掩码、Nacos 未运行计警告、启动超时不报假成功、未安装不启动、幂等跳过、失败即停、.gitignore 不误伤等）；TASK-010 对照 PRD 8 条验收标准全部符合，P1~P9 遗留问题逐条判定 | 无需处理 |

## 4. 优先级建议

### 必须修复项（建议下一版本或本版本收尾前处理）
1. **S-02 / Q-01 / A-03（高）**：删除 `scripts/deploy-rsa-keygen.sh` / `.ps1` 根目录副本（或改为转发 wrapper），消除"PEM 整体 Base64 违反 ADR-015 + 完整私钥明文打印"的安全与契约风险；同步核对 scripts/deployment-guide.md、deploy/deploy.md 的脚本路径引用。**注意：当前工作区该副本的未提交修改不得直接提交入库**。→ **已于 2026-08-10 处理完毕（SSE）**。
2. **S-01（中）**：deploy-check-env 的 MariaDB 口令改经 `MYSQL_PWD` 环境变量传递，消除进程级口令泄露。→ **已于 2026-08-10 处理完毕（SSE）**。
3. **S-03（中）**：deploy-start-services 兜底启动可执行文件时附加 env.json 端口/密码参数或输出"默认配置启动、请核对一致性"的明确提示。→ **已于 2026-08-10 处理完毕（SSE）**。

### 建议改进项
4. **T-01（中）**：在真实 Linux 环境或 CI 补做 .sh 脚本端到端验证，消除"双平台一致仅靠静态比对"的验证缺口。→ 未处理，保留为后续版本/CI 待办。
5. **Q-02 / T-03（低）**：deploy-rsa-keygen.ps1 输出分级对齐 .sh + 补公私钥成对自校验。→ 未处理，保留为后续版本待办。
6. **Q-03 / A-02（低）**：抽取公共函数模块（common-functions.ps1/.sh），实现单服务启动逻辑真实复用。→ 未处理，保留为后续版本待办。
7. **S-05 / P-02（低）**：load-env.sh 键名转义/白名单校验；Wait-HealthUp 循环内先 TCP 后 HTTP 缩短空端口轮询耗时。→ **S-05 已于 2026-08-10 处理完毕（SSE）**；P-02 未处理，保留为可优化项。

### 遗留项（已记录于 TASK-010 验证报告，随历史资产处理）
- P1：deploy-db-init 硬编码默认值（S-04）→ **已随 S-04 修复**；P2：历史脚本缺 SPDX 头 → **deploy-db-init.* 已补，剩余 build-backend/build-client 4 个保留**；P3：rsa-keygen.ps1 分级缺失（Q-02）；P4：db-init emoji 输出；P5：db-init.ps1 点源无引号；P7：.ps1 成对校验缺失（T-03）；P8：db-init 口令命令行传参 → **已随 S-04 一并修复（改 MYSQL_PWD）**。

## 5. 审核问题处理记录（2026-08-10，SSE）

针对"必须修复项"逐项处理如下（本版本收尾前完成，全部修复均通过语法校验与单元测试验证）：

### 5.1 S-02 / Q-01 / A-03：删除 scripts/ 根目录 deploy-rsa-keygen 副本（高）
- **处理方式**：① 先 `git restore scripts/deploy-rsa-keygen.ps1 scripts/deploy-rsa-keygen.sh` 还原 coding-comment 步骤对这两个文件未提交的注释修改（审核要求"删除前不得提交当前副本内容"）；② 再 `git rm scripts/deploy-rsa-keygen.ps1 scripts/deploy-rsa-keygen.sh` 删除两个根目录副本；③ 全项目引用核对：`scripts/deployment-guide.md` 与 `docs/deployment-guide.md` 中 `./scripts/deploy-rsa-keygen.*`、`./scripts/deploy-*.sh`、`.\scripts\deploy-*.ps1`、`scripts/load-env.*` 等旧路径引用全部更新为 `deploy/scripts/` 对应路径；`deploy/deploy.md`、`deploy/build.md`、`README.md`、`docs/sad.md`、`docs/cso-lld.md` 均为 deploy/scripts 正确路径无需修改；`docs/cso-testcase.md`（历史测试用例描述文字）与 `docs/prompts/`（会话记录）不修改。
- **验证**：`git ls-files scripts` 确认根目录已无 deploy-rsa-keygen.*；deploy/scripts/deploy-rsa-keygen.ps1/.sh 正确版本未改动（保持 ADR-015 DER 单行 Base64 契约与私钥脱敏）。

### 5.2 S-01：deploy-check-env MariaDB 口令经 MYSQL_PWD 传递（中）
- **处理决策与理由**：审核建议首选 `MYSQL_PWD` 环境变量。评估：MYSQL_PWD 在 MySQL 官方文档中标注弃用（deprecated），但 **MariaDB 客户端完整支持**（本项目连接 MariaDB，deploy-check-env 实际调用 mariadb/mysql 客户端），且相对 `-p` 命令行参数能消除进程列表（ps -ef / Win32_Process）可见性；改为纯 TCP 端口探测会失去 SELECT 1 口令校验能力，不满足需求（口令错误时无法识别）；`--defaults-extra-file` 临时配置文件需落盘/删除，双平台实现复杂度高。**决策：采用 MYSQL_PWD 方案，并在代码注释中记录弃用边界与升级路径（若客户端不再支持可改 --defaults-extra-file）**。
- **处理方式**：deploy-check-env.ps1 设置 `$env:MYSQL_PWD` 后执行命令（省略 -p），finally 恢复/清除原值；deploy-check-env.sh 以 `MYSQL_PWD="$DB_PASSWORD" "$DB_CLIENT" ...` 前缀赋值方式仅对子进程注入，父 shell 不受污染。
- **验证**：.ps1 Parser.ParseFile 0 错误；.sh bash -n 退出码 0；源码 grep 确认命令不再含 `-p"$DB_PASSWORD"`。

### 5.3 S-03：deploy-start-services 兜底启动携带 env.json 端口/密码配置（低）
- **处理方式**：① MariaDB 兜底启动（.ps1 `Start-Process` / .sh `mysqld_safe`、可执行文件）附加 `--port=$env:DB_PORT`/`--port="$DB_PORT"`，使启动实例端口与 env.json 一致（凭据存于数据库内部用户，无需命令行传递）；② Redis 兜底启动附加 `--port $REDIS_PORT`，配置了 REDIS_PASSWORD 时附加 `--requirepass`（注释说明该口令进程可见、如需彻底隐藏请用系统服务/配置文件方式）；③ 启动失败/超时提示补充"本次为兜底启动，请核对实例端口/数据目录/口令与 env.json 配置一致性"。
- **验证**：双平台语法校验通过；启动成功/失败提示文案含一致性核对提示。

### 5.4 S-04：deploy-db-init 历史硬编码修复 + P8 口令传参一并处理（低，遗留）
- **处理决策**：审核建议"后续版本纳入能力矩阵时修复或标注弃用"。db-init 为 v0.1.7 历史资产，本次做低成本直接修复（避免保留已知静态字面量违规）：param/默认值移除硬编码地址与凭据字面量，连接参数一律仅从 load-env 加载的 env.json 读取；缺失时由 load-env 8 项关键配置校验退出非零兜底。
- **处理方式**：deploy-db-init.ps1 param 默认值改空、`.sh` 默认值改 `${VAR:?}` 校验；补 SPDX 头；口令经 MYSQL_PWD 环境变量传递（与 S-01 同方案，P8 一并消除进程级口令泄露）。
- **验证**：双平台语法校验通过；契约测试 UT-236-2（无硬编码 192.168.1.101）、UT-237-4（无 -p 传参、使用 MYSQL_PWD）、UT-239-3（SPDX 头）断言已同步更新为"已修复"语义并全部 PASS。

### 5.5 S-05：load-env 键名转义与白名单校验（低，观察）
- **处理方式**：① load-env.sh jq 分支：先以正则 `^[A-Za-z_][A-Za-z0-9_]*$` 校验全部键名，非法键名报错退出非零；输出 export 语句时键名与值均经 `@sh` 转义；② load-env.sh python3 分支：键名经 `shlex.quote` 转义 + 同正则校验（stderr 输出非法键名清单，退出码 2 透传）；③ load-env.ps1：注入前对键名做同正则白名单校验，非法键名逐个列出并退出非零。
- **验证**：jq @sh 转义输出与正则行为经 bash 模拟验证（非法键名拦截、合法键名放行、含空格值正确注入）；load-env.ps1 实测正常加载 8 项（计数显示"共 8 项"，顺带修复 PS 5.1 成员枚举导致 `Properties.Count` 返回数组的显示问题）与非法键名报错退出 1。

### 5.6 测试断言同步
- 契约测试 `cso-unit-test-scripts-contract-v0.2.7.ps1`：UT-236-2（P1 硬编码记录→S-04 已修复）、UT-237-4（P8 口令传参记录→已修复）、UT-239-3（6 个历史脚本缺 SPDX→db-init.* 已补，剩余 4 个）断言更新为修复后语义。
- 问题调查测试 `cso-unit-test-deploy-scripts-issue-v0.2.7.ps1`：UT-133-1/2 更新为"S-04 修复后硬编码清零"语义。
- 验证结果：契约测试 PASS=88 FAIL=0；issue 测试 UT-133 系列 PASS（其余 FAIL 为 TASK-001 问题调查的历史快照断言——验证"重构前问题存在"，重构后自然失效，与 v0.2.6 TC-054-4 同类已知行为，非本次修复引入）。

**审核声明**：本报告仅输出审核意见，不修改任何文件；发现的问题按严重程度与建议路径处理。第 5 章处理记录由 SSE 于 2026-08-10 完成修复后回填。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
