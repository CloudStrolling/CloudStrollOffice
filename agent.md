# 云漫智企（CloudStrollOffice）Agent 使用说明

本项目基于 impm（iterative project management）软件工程流程，由 1 个主控 Agent（PM）与 12 个 subagent 协作完成瀑布式开发。所有 Agent 定义位于 `.opencode/agents/` 目录，技能定义位于 `.opencode/skills/` 目录。

**当前版本 v0.2.6（部署与配置缺陷修复）**：依据 `docs/cso-v0.2.5/regression-api-test.md` 记录的问题完成修复——5 个 pom 引入 `spring-cloud-starter-bootstrap`（ADR-014）、RSA 密钥统一 DER 单行 Base64 契约（ADR-015）、SecurityConfig 白名单增补（login/register/refresh）与全局异常处理器注册等契约行为对齐；4 个服务全部正常启动，**API 回归测试全量跑通**（TC-001~051 PASS=72、FAIL=0、SKIP=0），接口契约 API-001~033 无回归，客户端零改动。

## 一、Agent 角色一览

| 角色 | 英文名 | 类型 | 职责 | 主要技能 |
|------|--------|------|------|---------|
| **PM** | Project Manager | primary（主控） | 编排 impm 全流程，调度其余 Agent 完成项目初始化、需求分析、编码开发、回归测试与版本文档整理四阶段；自己不做具体事务 | /impm、/impm-init、/impm-docs、/impm-coding、/impm-finish |
| **BA** | Business Analyst | subagent | 编写 URS 用户需求说明书与 PRD 产品需求文档，是需求源头 | impm-init-urs / impm-init-prd / impm-urs-create / impm-prd-create |
| **SA** | System Architect | subagent | 系统架构设计（SAD）、维护 docs/project.md 项目地图、技术决策（ADR） | impm-init-project / impm-init-sad / impm-init-api / impm-sad-update / impm-project-update |
| **TL** | Tech Lead | subagent | 详细设计（LLD）、API 接口设计、任务清单生成、代码审核 | impm-init-lld / impm-lld-create / impm-api-create / impm-task-create / impm-task-coding-context / impm-task-coding-api / impm-coding-review |
| **DBA** | Database Architect | subagent | 数据库设计（DBD）、SQL 脚本编写与数据库变更管理 | impm-init-dbd / impm-dbd-create / impm-task-coding-dbd |
| **TE** | Test Engineer | subagent | 测试用例、单元测试函数、接口测试脚本编写与执行、回归测试 | impm-init-testcase / impm-task-coding-testcase / impm-task-coding-writetest / impm-task-coding-runtest / impm-regression-test |
| **SCM** | Software Configuration Management | subagent | git 版本管理、分支策略、提交规范与版本合并发布 | impm-init-git / impm-init-commit / impm-version-create / impm-analysis-commit / impm-task-coding-gitcommit / impm-git-merge |
| **DW** | Document Writer | subagent | 通用技术文档维护：代码备注、文档合并、README/agent.md、编译部署文档 | impm-coding-comment / impm-doc-merge / impm-doc-update / impm-deploy-update |
| **CS** | Code Searcher | subagent | 本地代码查询，为编码任务提供现有代码与可复用组件信息 | impm-task-coding-cs |
| **WS** | Web Searcher | subagent | 网络资料查询（官方文档、SDK 用法、版本兼容性） | impm-task-coding-ws |
| **SSE** | Senior Software Engineer | subagent | 通用任务编码（非前后端业务，如工程配置、工具类等） | impm-task-coding-code（common 分支） |
| **FEE** | Front-End Engineer | subagent | 前端页面与交互实现（本项目的 Flutter 客户端） | impm-task-coding-code（frontend 分支） |
| **BEE** | Back-End Engineer | subagent | 后端业务接口实现（本项目的 Spring Boot 微服务） | impm-task-coding-code（backend 分支） |

## 二、Agent 使用方式

### 1. 全流程开发

在 OpenCode 中输入以下命令，PM 将按瀑布式流程调度各 subagent：

| 命令 | 阶段 | 说明 |
|------|------|------|
| `/impm-init` | 初始化阶段 | 项目初始化：git 基线、project.md、URS/PRD/SAD/DBD/API/LLD、任务清单、测试用例（13 步） |
| `/impm-docs` | 需求分析整理阶段 | 版本需求分析：版本创建、URS、PRD、SAD 更新、DBD、API、LLD、任务清单、git 提交（9 步） |
| `/impm-coding` | 编码开发阶段 | 按任务清单上下游顺序调度 BEE/FEE/SSE 编码，TE 测试，逐任务提交 |
| `/impm-finish` | 回归测试与版本文档整理阶段 | 回归测试、代码备注、代码审核、项目地图更新、文档合并、README/agent.md、部署文档、git 合并 |
| `/impm` | 全流程 | 一次执行全部四个阶段 |

### 2. 阶段内步骤说明

| 阶段 | 步骤 | 执行角色 | 产出 |
|------|------|---------|------|
| 需求分析 | version-create | SCM | 版本分支 `{缩写}-v{版本号}`、版本目录、version_progress.md |
| 需求分析 | urs-create / prd-create | BA | `docs/cso-v{版本号}/cso-urs-v{版本号}.md`、`cso-prd-v{版本号}.md` |
| 需求分析 | sad-update | SA | `docs/sad.md`（架构变更与 ADR） |
| 需求分析 | dbd-create | DBA | `docs/cso-v{版本号}/cso-dbd-v{版本号}.md` + `.sql` |
| 需求分析 | api-create / lld-create / task-create | TL | API 设计、LLD 详细设计、任务清单 JSON |
| 需求分析 | analysis-commit | SCM | git 提交需求分析成果 |
| 编码开发 | task-coding-context / -cs / -ws / -dbd / -api | TL/CS/WS/DBA | 任务上下文、代码查询、资料查询 |
| 编码开发 | task-coding-testcase / -writetest / -runtest | TE | 测试用例、测试代码、测试执行结果 |
| 编码开发 | task-coding-code | BEE/FEE/SSE | 后端/前端/通用实现代码 |
| 编码开发 | task-coding-gitcommit | SCM | 按任务提交 git |
| 回归测试 | regression-test | TE | 全量单元测试 + 接口测试回归报告 |
| 文档整理 | coding-comment / doc-merge / doc-update / deploy-update | DW | 代码注释、主文档合并、README/agent.md、deploy 部署文档 |
| 文档整理 | coding-review | TL | 代码审核报告 |
| 文档整理 | project-update | SA | 项目地图更新 |
| 版本收尾 | git-merge | SCM | squash 合并版本分支到主分支 |

### 3. 版本进度追踪

- 每个步骤完成后，由执行者通过 `impm_progress` 在 `docs/cso-v{版本号}/version_progress.md` 记录状态（已完成/无需数据库/任务编号-已完成 等）。
- PM 每步核对产出文件与进度记录，确保流程不跳过、不乱序。

### 4. 任务调度规范

- 编码任务严格按 `docs/cso-v{版本号}/cso-task-v{版本号}.json` 中定义的上下游依赖顺序执行，由 `impm_task_manager` 校验。
- subagent 只做本职事务；需要现有代码查 CS、需要资料查 WS、需要数据库变更交 DBA、需求与设计疑问反馈调度方。

## 三、本项目文档资产地图

| 文档 | 路径 | 维护者 |
|------|------|--------|
| 项目主文档 | `docs/project.md`（基本信息、编码规范、项目地图） | SA |
| 系统架构设计 | `docs/sad.md` | SA |
| 主文档（URS/PRD/API/DBD/LLD/Testcase） | `docs/cso-urs.md`、`docs/cso-prd.md`、`docs/cso-api.md`、`docs/cso-dbd.md`、`docs/cso-dbd.sql`、`docs/cso-lld.md`、`docs/cso-testcase.md` | 各角色编写，DW 合并 |
| 版本目录 | `docs/cso-v{版本号}/`（URS/PRD/DBD/API/LLD/Task/Testcase/Review/回归报告/进度等），最新 `docs/cso-v0.2.6/` | 各角色 |
| 项目根 README | `readme.md`（项目介绍、快速开始、目录结构、命令说明） | DW |
| Agent 说明 | `agent.md`（本文件） | DW |
| 编译部署文档 | `deploy/build.md`、`deploy/deploy.md` | DW |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
