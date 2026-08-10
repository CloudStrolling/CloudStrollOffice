# cs.md（TASK-008 清理弃用脚本残留并同步引用关系）

## 1. 任务信息与查询范围

- **任务编号**：TASK-008
- **任务定义**：删除或明确弃用 deploy/scripts 下弃用残留脚本（deploy-env.ps1、deploy-env-template.ps1 等）；检查全部脚本与文档对弃用脚本的引用关系并同步更新，避免加载路径失效；确保移除后 deploy/scripts 目录仅保留能力矩阵所需脚本（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen），.ps1 与 .sh 同名脚本行为一致（F-011、ADR-016）。
- **查询范围**：deploy/scripts 目录全部文件；git 跟踪状态；全项目（脚本 + 文档 + 测试脚本）对 deploy-env 的引用；能力矩阵脚本清单与依赖关系；.gitignore 现状（TASK-009 依据，仅记录）。
- **查询方法**：glob / git ls-files / grep deploy-env（全项目）/ 文件内容核对。

## 2. deploy/scripts 目录现状清单（实测 28 个条目，含 .gitkeep）

| # | 脚本 | 双平台 | 归类 | 处置 |
| --- | --- | --- | --- | --- |
| 1 | load-env.ps1 / load-env.sh | 有 | 能力矩阵（统一配置加载） | 保留 |
| 2 | deploy-check-env.ps1 / .sh | 有 | 能力矩阵（环境可用性检查） | 保留 |
| 3 | deploy-start-services.ps1 / .sh | 有 | 能力矩阵（基础设施检测与一键启动） | 保留 |
| 4 | deploy-start-all.ps1 / .sh | 有 | 能力矩阵（后端服务按序一键启动总入口） | 保留 |
| 5 | deploy-start-gateway.ps1 / .sh | 有 | 能力矩阵（单服务启动） | 保留 |
| 6 | deploy-start-auth.ps1 / .sh | 有 | 能力矩阵（单服务启动） | 保留 |
| 7 | deploy-start-biz.ps1 / .sh | 有 | 能力矩阵（单服务启动） | 保留 |
| 8 | deploy-start-system.ps1 / .sh | 有 | 能力矩阵（单服务启动） | 保留 |
| 9 | deploy-rsa-keygen.ps1 / .sh | 有 | 能力矩阵（RSA 密钥生成） | 保留 |
| 10 | deploy-db-init.ps1 / .sh | 有 | 合法脚本（v0.2.5 迁移） | 保留（不在本任务删除范围） |
| 11 | build-backend.ps1 / .sh | 有 | 合法脚本（v0.2.5 迁移） | 保留（不在本任务删除范围） |
| 12 | build-client.ps1 / .sh | 有 | 合法脚本（v0.2.5 迁移） | 保留（不在本任务删除范围） |
| 13 | **deploy-env.ps1** | **无 .sh 对（单版本残留）** | **弃用脚本残留** | **git rm 删除** |
| 14 | **deploy-env-template.ps1** | 有 | **弃用脚本残留** | **git rm 删除** |
| 15 | **deploy-env-template.sh** | 有 | **弃用脚本残留** | **git rm 删除** |
| 16 | .gitkeep | — | 占位 | 保留 |

> 说明：13 组能力矩阵/合法脚本双平台齐全（26 个文件）+ 3 个弃用残留 + .gitkeep = 28 个条目；deploy-env.ps1 为唯一单版本残留（无 .sh 对，与 UT-134-2 一致）。

## 3. 弃用脚本 git 跟踪确认（git ls-files 实测）

三个弃用脚本均被 git 跟踪，删除需使用 `git rm`（或删除后提交），保证 git 记录完整：

- `deploy/scripts/deploy-env.ps1` — 113 行，文件头自称「已弃用」「兼容保留」；第 67 行等以占位符写死环境变量（违反配置驱动原则，P2 问题记录）
- `deploy/scripts/deploy-env-template.ps1` — 78 行，自称「已弃用」
- `deploy/scripts/deploy-env-template.sh` — 83 行，版本 v0.1.7，头部标注「【已弃用】请改用 deploy 目录下的 env.json 配置文件」

## 4. 全项目对弃用脚本（deploy-env）的引用关系清单（grep 实测）

### 4.1 脚本引用（deploy/scripts 内部）

grep deploy-env 结果：**deploy/scripts 下除 3 个弃用脚本自身外，无任何脚本引用 deploy-env***。能力矩阵脚本与合法脚本统一引用 `load-env.ps1`/`load-env.sh`（`. "$PSScriptRoot\load-env.ps1"` / `source "$SCRIPT_DIR/load-env.sh"`），因此删除弃用脚本**不会造成加载路径失效**（与 UT-193-3 正向约束断言一致）。

### 4.2 文档引用点（需同步更新）

| 引用位置 | 行号 | 引用内容 | 处置方向 |
| --- | --- | --- | --- |
| deploy/deploy.md（目录树） | 第 72 行 | `├── deploy-env.ps1 / .sh  # 环境注入（已弃用，兼容保留）`（宣称存在 deploy-env.sh，实际不存在，P7-09） | 删除该行 |
| deploy/deploy.md（目录树） | 第 73 行 | `├── deploy-env-template.ps1 / .sh # 环境模板生成` | 删除该行 |
| README.md | 第 229 行 | `./deploy-env.sh  # 或 PowerShell: .\deploy-env.ps1`（「从模板生成环境配置」代码块） | 更新为 env.example.json → env.json 复制用法（deploy/scripts 下无环境模板生成脚本后，正确做法是 `Copy-Item deploy\env.example.json deploy\env.json`；具体表述由 code 阶段按上下文修正） |
| docs/cso-lld.md（主文档） | 第 771-772 行 | 部署脚本迁移清单含 `deploy-env-template.sh`、`deploy-env.ps1（.ps1）`、`deploy-env-template.ps1` | 从清单移除弃用脚本（主文档同步由 doc-merge 统一处理，或经 PM 确认后本任务同步） |
| scripts/deployment-guide.md | 第 1535 行 | 附录 A 表格行：`deploy-env-template.* \| 环境变量模板（已弃用） \| deploy-env-template.sh \| deploy-env-template.ps1` | 删除该表格行（附录 A 同时缺 deploy-start-all 条目，一并核对） |
| docs/deployment-guide.md | 第 1535 行 | 与 scripts/deployment-guide.md 完全相同的副本（54554 字节、同一修改时间、git 历史 v0.2.5 提交 ba8398b 跟踪） | 同样删除该表格行（**context.md 引用清单之外的补充发现**） |
| docs/cso-testcase.md（主文档） | 第 2252、3082 行 | 测试数据清单含 deploy-env、deploy-env-template（21 个脚本清单） | 主测试用例文档，范围经 PM 确认后处理（版本内测试用例文档 cso-testcase-v0.2.7.md 由 testcase/writetest 阶段更新） |
| docs/cso-prd.md（主文档） | 第 678 行 | v0.2.5 迁移范围描述提及 deploy-env | 历史需求描述，不改 |

### 4.3 测试脚本引用点

| 引用位置 | 用例/行号 | 引用内容 | 处置方向 |
| --- | --- | --- | --- |
| scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1 | UT-134-1（第 207-212 行）、UT-134-2（第 214-218 行）、UT-143-2（第 541-548 行）、第 221 行 P2 断言 | 正向断言 3 个弃用脚本存在；deploy-env.ps1 无 .sh 对；唯一单版本为 deploy-env.ps1；deploy.md 需引用 deploy-env | TASK-001 验收测试，弃用脚本移除后**需反转/移除断言**（由本任务测试阶段处理，属预期变更） |
| scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1 | UT-193-3（第 338-343 行） | 负向断言 8 个单服务脚本内无 deploy-env-local / deploy-env.ps1 / deploy-env.sh 引用 | 保留，作为引用关系无残留的回归依据 |
| scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1 | 第 228-229 行 | v0.2.5 验收测试文件清单含 deploy-env.ps1、deploy-env-template.* | 历史版本归档测试，不改 |
| scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1 | 第 63-64 行 | v0.2.5 迁移测试文件清单含 deploy-env.ps1、deploy-env-template.* | 历史版本归档测试，不改 |

### 4.4 历史存档/决策记录（不改）

- docs/prompts/prompt-*.md — 会话过程记录（历史存档）
- docs/sad.md ADR-016（第 306 行）— 决策记录，描述「删除弃用脚本残留（deploy-env 等）」，是行动描述而非引用
- docs/cso-v0.2.7/cso-lld-v0.2.7.md 第 418、548 行 — R-13 需求规则与验收标准（任务本身定义，不改）
- docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md 第 44-45 行 — P2 问题记录（任务依据，不改）

## 5. 能力矩阵脚本清单与依赖关系（可复用组件）

### 5.1 能力矩阵脚本（v0.2.7 规范，全部保留）

- **load-env.ps1 / load-env.sh** — 统一配置加载模块：从 deploy/env.json 加载全部键值（NACOS_ADDR/NACOS_HOME、DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/DB_USER/DB_SERVICE_NAME/DB_PROCESS_NAME、REDIS_HOST/REDIS_PORT/REDIS_PASSWORD/REDIS_DATABASE/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME、RSA_PRIVATE_KEY/RSA_PUBLIC_KEY、VERIFICATION_CODE_*、PASSWORD_MIN/MAX_LENGTH、MARIADB_ROOT_PASSWORD、TZ 等）；env.json 缺失/关键配置缺失时输出错误并以非零码退出；source 型脚本（.sh 无 set -e，避免污染父 shell）。
- **deploy-check-env.ps1 / .sh** — JDK（java 命令 + JAVA_HOME + 版本 21）/ MariaDB（命令/服务/进程三重 + SELECT 1）/ Redis（三重 + redis-cli ping）/ Nacos（NACOS_HOME/bin/startup.cmd|sh + HTTP 探测）可用性检查 + 运行状态检测；输出通过/警告/失败分级；Nacos 已安装未启动计「警告（未运行）」。
- **deploy-start-services.ps1 / .sh** — 检测 MariaDB/Redis/Nacos 运行状态，未运行且已安装按 MariaDB → Redis → Nacos 顺序自动启动（服务启动优先级：系统服务 → 可执行文件 → Nacos startup 脚本），启动后再次探测确认；JDK 仅检查可用性不启动。
- **deploy-start-all.ps1 / .sh** — 校验 4 个 jar 存在与关键变量就绪后，按 gateway(9000) → auth(9100) → biz(9200) → system(9400) 顺序启动，逐服务健康确认（HTTP 探测 /api/v1/{module}/health 或端口），失败即停。
- **deploy-start-gateway/auth/biz/system.ps1 / .sh（8 个）** — 单服务启动：校验本服务关键变量与 jar 后 java -Xms256m -Xmx512m -jar 启动；日志落位 deploy/logs/{module}-start.log(.err)、PID 记录 deploy/logs/{module}.pid。
- **deploy-rsa-keygen.ps1 / .sh** — DER 编码单行 Base64 输出（公钥 X.509 / 私钥 PKCS#8，无 PEM 头尾、无换行，ADR-015 契约），输出到 deploy/keys/。

### 5.2 依赖关系（关键）

- 全部能力矩阵脚本统一 `. "$PSScriptRoot\load-env.ps1"` / `source "$SCRIPT_DIR/load-env.sh"` 加载配置，脚本内不硬编码地址与凭据。
- **无任何脚本引用 deploy-env*** → 删除弃用脚本不影响脚本间依赖。
- .sh 脚本输出分级（通过/警告/失败）与退出码约定（失败非零）与 .ps1 对齐（F-011）。

### 5.3 部署顺序与端口（SAD 部署架构）

- 基础设施：MariaDB 10.6（3306）→ Redis 7.2（6379）→ Nacos 2.3（8848）。
- 后端：gateway（9000）→ auth-service（9100）→ biz-service（9200）→ system-service（9400）。

## 6. .gitignore 现状（TASK-009 依据，本任务不修改）

> 任务边界确认（impm_task_manager）：TASK-009「治理 .gitignore 排除生成/测试/调试临时与中间文件」（P0，未完成）为独立任务，本任务（TASK-008）不做 .gitignore 修改，仅记录现状供下游参考。

**已有规则**（实测）：target/、/target/、build/、.dart_tool/、*.jar、*.exe、*.class、*.apk、*.aab、*.pid、*.log、*.bak、*.opencode.tmp、__pycache__/、*$py.class、.pytest_cache/、.coverage、env.bak/、venv.bak/、.idea/、.vscode/、.vs/、.classpath、.Rhistory、.opencode-history/、.claude-history/、conversation-history.jsonl、codex_history/、codex-*.log、copilot-*.log、.vscode/copilot/、gemini-*.log、.aider.chat.history.md、.aider.input.history、npm-debug.log*、yarn-debug.log*、yarn-error.log*、.pnpm-debug.log* 等。

**缺口**（TASK-009 需补充，实测无规则）：`*.hprof`（JVM 堆转储）、`hs_err_pid*.log`（JVM 崩溃日志）、`*.dmp`、`surefire-reports/`、`flattened-pom.xml`/`.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated`、接口测试中间文件（token 缓存/临时报告）、调试工具残留（*.saz/*.chls/*.har）等。

## 7. 关键结论与编码建议（供 code 阶段使用）

1. **删除对象明确**：仅 deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh 三个弃用脚本（git rm），其余 24 个脚本 + .gitkeep 全部保留。
2. **引用同步清单**：deploy/deploy.md 第 72-73 行（删除两行）、README.md 第 229 行（更新为 env.example.json → env.json 复制用法）、scripts/deployment-guide.md 第 1535 行与 docs/deployment-guide.md 第 1535 行（删除表格行，注意两份为同内容副本需同步改）、docs/cso-lld.md 第 771-772 行（迁移清单移除，范围与 PM 确认）、docs/cso-testcase.md 第 2252/3082 行（范围与 PM 确认）。
3. **测试同步**：cso-unit-test-deploy-scripts-issue-v0.2.7.ps1 的 UT-134-1/134-2、UT-143-2 与 P2 断言需在测试阶段反转/移除；cso-unit-test-start-single-v0.2.7.ps1 的 UT-193-3 保留作回归依据；v0.2.5 归档测试不改。
4. **删除后目录核验**：仅剩能力矩阵脚本 + build-*/deploy-db-init（合法脚本）+ .gitkeep；`grep deploy-env` 无残留引用（docs/prompts 历史会话、docs/sad.md ADR-016 描述、v0.2.5 归档测试除外）。
5. **文件头规范**：修改的文档保留 SPDX-License-Identifier（Apache-2.0）与版权声明；提交信息用 Conventional Commits（refactor:/docs:/chore:）。
6. .gitignore 治理属于 TASK-009，本任务不越界修改。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
