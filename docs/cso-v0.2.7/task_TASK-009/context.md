# 任务上下文（TASK-009 治理 .gitignore 排除生成/测试/调试临时与中间文件）

## 0. 用户输入原文与现状勘察

### 用户输入
检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成，测试，调试过程中的临时文件和中间文件在 .gitignore 中排除。

### 任务定义
治理 .gitignore 排除生成/测试/调试临时与中间文件（整体检查项目根目录文件与子目录，识别生成、测试、调试过程中的临时文件与中间文件，在 .gitignore 中按现有分区风格新增排除规则：JVM/应用调试产物（*.hprof、hs_err_pid*.log、堆转储、dump 目录）、测试产物与缓存（__pycache__/.pytest_cache 补充、surefire-reports、接口测试中间文件如 token 缓存/临时报告）、构建过程中间产物（.flattened-pom.xml、*.lastUpdated、maven-status/、dependency-reduced-pom.xml 等）、工具残留（*.saz、*.chls、*.har、API 调试会话文件等）；规则带路径前缀或精确模式，不得误伤 env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档等应入库文件；治理后执行 git status 验证临时/中间文件不再出现在待提交清单（F-012））。

### .gitignore 现状勘察（TASK-001 issue-list.md 第 4 节 + TASK-008 cs.md 第 6 节实测汇总）

**已有规则（项目根目录 .gitignore，332 行，10+ 分区，实际生效）**：
- 操作系统（Mac/Windows/Linux）、通用 IDE/编辑器、AI 开发工具、前端/Node.js、Python、Java/Maven/Gradle、C/C++、Rust、Go、PHP、Dart/Flutter
- 客户端构建产物（`deploy/cloudoffice-flutter-app/web/*`、`windows/*` 带路径前缀 + `!*.gitkeep` 白名单）
- 数据库/缓存/日志/临时（`*.log`、`logs/`、`tmp/`、`temp/`、`.cache/`）
- 环境密钥（`keys/`、精确 `env.json`、`.env.*` 白名单 `!.env.example`、`docs2/`）
- 包管理器、压缩包
- 实测已有细化规则：`target/`、`/target/`、`build/`、`.dart_tool/`、`*.jar`、`*.exe`、`*.class`、`*.apk`、`*.aab`、`*.pid`、`*.log`、`*.bak`、`*.opencode.tmp`、`__pycache__/`、`*$py.class`、`.pytest_cache/`、`.coverage`、`env.bak/`、`venv.bak/`、`.idea/`、`.vscode/`、`.vs/`、`.classpath`、`.Rhistory`、`.opencode-history/`、`.claude-history/`、`conversation-history.jsonl`、`codex_history/`、`codex-*.log`、`copilot-*.log`、`.vscode/copilot/`、`gemini-*.log`、`.aider.chat.history.md`、`.aider.input.history`、`npm-debug.log*`、`yarn-debug.log*`、`yarn-error.log*`、`.pnpm-debug.log*` 等

**识别缺口（TASK-009 需补充，实测无规则）**：
| 类别 | 缺口文件/模式 | 建议规则 |
| --- | --- | --- |
| JVM/应用调试产物 | 堆转储 `*.hprof`、JVM 崩溃日志 `hs_err_pid*.log`、`dump/`、`*.dump`、`heapdump.*`、`*.dmp` | `*.hprof`、`hs_err_pid*.log`、`dump/`、`*.dump`、`heapdump.*`、`*.dmp` |
| Maven/构建中间产物 | `.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated` | `*.flattened-pom.xml`、`maven-status/`、`dependency-reduced-pom.xml`、`*.lastUpdated` |
| 测试产物与缓存 | 独立测试报告目录（`target/` 已排除但补充独立产物）、接口测试中间文件（token 缓存、临时报告） | `**/surefire-reports/`、`**/test-results/`、`test-output/`；API-TEST 临时 token/report 文件（精确模式） |
| 工具残留 | API 调试会话 `*.har`、`*.saz`、`*.chls`；编辑器历史 `*.history`、`*.session` | `*.har`（评估）、`*.saz`、`*.chls`、`*.history`、`*.session` |
| 调试临时输出 | `*.trace`、`*.dump`（已有 `*.log` 覆盖但补充） | `*.trace`（谨慎，可加路径前缀避免误伤源码扩展名） |

**治理红线（不得误伤）**：
- `deploy/env.example.json`（模板，须入库）：现有规则为精确 `env.json`，安全，不得改为 `env.json*` 通配。
- `deploy/scripts/.gitkeep`、`deploy/cloudoffice-flutter-app/**/.gitkeep`：白名单 `!*.gitkeep` 已保留，新增规则不得覆盖。
- `pom.xml`、`bootstrap.yml`、`*.java`、`*.dart`、`*.md`：新规则须带路径前缀或精确模式，避免全局通配误伤。
- 已跟踪文件不受新规则影响；如需停止跟踪既有文件须 `git rm --cached`（本任务为新增规则治理，不执行 git rm）。

---

## 1. 任务信息

```json
{
  "id": "TASK-009",
  "title": "治理 .gitignore 排除生成/测试/调试临时与中间文件",
  "description": "整体检查项目根目录文件与子目录，识别生成、测试、调试过程中的临时文件与中间文件，在 .gitignore 中按现有分区风格新增排除规则：JVM/应用调试产物（*.hprof、hs_err_pid*.log、堆转储、dump 目录）、测试产物与缓存（__pycache__/.pytest_cache 补充、surefire-reports、接口测试中间文件如 token 缓存/临时报告）、构建过程中间产物（.flattened-pom.xml、*.lastUpdated、maven-status/、dependency-reduced-pom.xml 等）、工具残留（*.saz、*.chls、*.har、API 调试会话文件等）；规则带路径前缀或精确模式，不得误伤 env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档等应入库文件；治理后执行 git status 验证临时/中间文件不再出现在待提交清单（F-012）。",
  "taskType": "common",
  "userStoryId": "US-005",
  "apiId": "",
  "upstreamTaskIds": [],
  "downstreamTaskIds": [],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "git status 验证（无生成/测试/调试过程文件）；应入库文件复核（env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档未缺失、未被误伤）",
  "acceptanceCriteria": ".gitignore 新增规则覆盖 JVM 调试产物、测试缓存、构建中间产物、工具残留等类型；git status 不再出现生成、测试、调试过程文件；不误伤应入库文件（env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档）"
}
```

## 2. 用户需求

### US-005：仓库临时/中间文件治理
#### 故事描述
作为（项目版本管理员/维护者），我想要（将生成、测试、调试过程中的临时文件与中间文件在 .gitignore 中排除），以便（git 仓库保持整洁、可审计，不误提交过程产物）。
#### 前置条件
- 项目已初始化（docs/project.md 与 docs/sad.md 存在）；
- 已整体检查项目当前文件并识别生成、测试、调试过程文件。
#### 验收标准
- [ ] Given 项目当前存在生成、测试、调试临时/中间文件，When 更新 `.gitignore`，Then 新增规则覆盖 JVM 调试产物（*.hprof、dump 目录）、测试缓存（.pytest_cache、__pycache__）、构建中间产物、工具残留等类型
- [ ] Given 治理完成，When 执行 `git status`，Then 不再出现生成、测试、调试过程文件（仅出现预期源码/文档变更）
- [ ] Given 治理完成，When 核对忽略规则，Then 不误伤应入库文件（env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档等）
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 新增规则误伤应入库文件 | 检查 `git status` 未出现应入库文件缺失；用精确路径/前缀规则避免误伤 |
| 同名目录在源码与产物中都有 | 带 `deploy/` 等路径前缀精确匹配，仅排除产物目录 |
| 已跟踪文件被新规则忽略 | 新规则只影响未跟踪文件；如需停止跟踪既有文件需 `git rm --cached` 并确认 |
| 临时文件类型持续新增 | 保持分区注释清晰，便于后续维护者补充 |
#### 关联功能编号
F-012

### 功能描述摘要（PRD 4.12 F-012 .gitignore 临时/中间文件治理）
- 检查范围：项目根目录全部文件与子目录，重点识别——
  - JVM/应用调试产物：堆转储（*.hprof）、崩溃日志、dump 目录、调试临时文件；
  - 测试产物与缓存：*.pyc/__pycache__、.pytest_cache、测试生成的临时输出、接口测试中间文件（如 token 缓存、临时报告）、Maven surefire 报告（target 已排除但补充 surefire-reports 等独立产物）；
  - 构建过程中间产物：除已有 target/、build/、dist/ 外，补充构建工具残留（如 .flattened-pom.xml、*.class 已覆盖但补充 ide 编译缓存）；
  - 工具残留目录与文件：调试器/抓包工具输出、API 调试会话文件、编辑器/IDE 会话文件（补充 *.history、*.session 等）。
- 补充规则须带路径前缀或精确模式，**不得误伤**应入库的源码、文档、模板与配置模板（env.example.json、.gitkeep、pom.xml、bootstrap.yml 等）。
- 治理后执行 `git status` 验证：仅出现预期的源码/文档变更，临时与中间文件不再出现在待提交清单中。
- 补充规则按现有 .gitignore 分区风格归类（如"JVM/调试产物"、"测试缓存"、"工具残留"等分区）。

## 3. 项目信息

**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**数据库**：MariaDB 10.6（认证库 `cloudstroll_office_auth` 9 张表；biz/system 库预留）；Redis 7.2.x（会话/黑名单/状态缓存）
**总体介绍**：基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 的微服务企业办公套件。后端 Maven 多模块（common/gateway/auth-service/biz-service/system-service），配套 Flutter 客户端（Web + Windows）。已实现 RBAC 多租户权限模型、6 种客户端类型混合登录、JWT RS256 双 Token、Redis 会话管理、网关 AuthFilter 全局认证（9 步校验）、多模式登录/注册等。基础设施依赖 MariaDB 10.6、Redis 7.2、Nacos 2.3。

### 与本任务相关的项目规范（project.md 摘要）
- 部署资产：最终构建产物统一输出到根目录 `deploy`（后端 jar 包、客户端安装文件/exe）；`env.json`/`env.example.json` 与 `deploy/scripts` 下全部 .sh/.ps1 集中存放；构建中间产物（target 目录、编译临时文件、测试产物）禁止进入 deploy。
- 文件头保留 SPDX-License-Identifier 与版权声明；注释使用简体中文。
- 禁止提交密钥、密码等敏感信息（RSA 密钥对、数据库密码等通过 env.json 注入，密钥文件放 `keys/` 并加入 .gitignore）；不提交日志与临时文件。
- 提交信息遵循 Conventional Commits 规范（feat:/fix:/docs:/refactor:/test:/chore:，本任务适合 chore: 或 docs:）。

## 4. 系统架构相关

### 部署运维自动化目标（SAD G-A7，v0.2.7）
- 以 `deploy/env.json` 为唯一配置源，重构 `deploy/scripts` 全部脚本（.ps1/.sh 双平台），形成"环境可用性检查（deploy-check-env）→ 基础设施运行状态检查与一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all，gateway→auth→biz→system）→ 单服务启动（deploy-start-{svc}）"的脚本能力矩阵。
- **同时治理 `.gitignore`，排除生成、测试、调试过程中的临时/中间文件，保持仓库整洁可审计（v0.2.7）**。

### 部署脚本体系重构决策（ADR-016，v0.2.7）
- 以 `deploy/env.json` 为唯一配置源（load-env 统一加载）；能力划分为四类：可用性检查、基础设施一键启动、后端按序一键启动、单服务启动。
- .ps1 与 .sh 双平台行为对齐；输出分级与退出码约定统一；删除弃用脚本残留（deploy-env 等）；.sh 与 .ps1 密钥输出契约对齐（不破坏 ADR-015）。
- **同时治理 `.gitignore` 排除生成/测试/调试临时与中间文件**。

### 部署资产约束（SAD 1.2）
- 最终构建产物统一输出至根目录 `deploy`；构建中间产物（target 目录、编译临时文件、测试产物等）禁止进入 deploy；`env.json`/`env.example.json` 环境配置与 `deploy/scripts` 下全部 .sh/.ps1 部署运维脚本集中存放于 deploy 下。

### 前端/客户端构建产物
- Flutter 客户端（cloudoffice-flutter-app）构建生成 web/、windows/、build/、.dart_tool/ 等目录（已有规则覆盖，需复核不误伤源码与 .gitkeep）。

## 5. 本任务执行要点（TL 提示）
1. 本任务为"治理 .gitignore 排除生成/测试/调试临时与中间文件"（F-012 / US-005 / G-5），对应 PRD 验收标准第 8 条；无上游依赖（upstreamTaskIds 为空），可独立执行。
2. 执行方式：整体检查项目根目录文件与子目录（含 deploy/、scripts/、docs/、各 Maven 模块、Flutter 工程），结合 TASK-001 issue-list.md 第 4 节缺口清单与 TASK-008 cs.md 第 6 节现状观察，在 .gitignore 按现有分区风格新增规则；治理后执行 `git status` 验证。
3. 新增规则覆盖四大类（详见第 0 节缺口清单）：
   - JVM/应用调试产物：`*.hprof`、`hs_err_pid*.log`、堆转储（`heapdump.*`）、`dump/`、`*.dump`、`*.dmp`；
   - 测试产物与缓存：`**/surefire-reports/`、`**/test-results/`、`test-output/`、接口测试中间文件（token 缓存/临时报告，精确模式）、`.pytest_cache`/`__pycache__` 补充；
   - 构建过程中间产物：`*.flattened-pom.xml`、`*.lastUpdated`、`maven-status/`、`dependency-reduced-pom.xml`；
   - 工具残留：`*.saz`、`*.chls`、`*.har`、`*.history`、`*.session`、API 调试会话文件。
4. 治理红线（不得误伤）：`deploy/env.example.json`（现有精确 `env.json` 规则不得改为通配）、`.gitkeep`（白名单 `!*.gitkeep` 保留）、`pom.xml`、`bootstrap.yml`、`*.java`、`*.dart`、`*.md` 等应入库文件；新规则须带路径前缀或精确模式。
5. 验证要求：治理后执行 `git status` 确认临时/中间文件不再出现在待提交清单；复核应入库文件（env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档）未缺失、未被误伤。
6. 已跟踪文件不受新规则影响，本任务不执行 `git rm --cached`（如需停止跟踪既有文件须另行确认）。
7. .gitignore 修改保留现有分区风格与注释；如需更新文档（如 docs/project.md 根目录文件说明）按文件头规范保留 SPDX-License-Identifier 与版权声明。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
