# 任务上下文（TASK-008 清理弃用脚本残留并同步引用关系）

## 0. 用户输入原文与现状勘察

### 用户输入
检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成，测试，调试过程中的临时文件和中间文件在 .gitignore 中排除。

### 任务定义
清理弃用脚本残留并同步引用关系（删除或明确弃用 deploy/scripts 下弃用残留脚本 deploy-env.ps1、deploy-env-template.ps1 等；检查全部脚本与文档对弃用脚本的引用关系并同步更新，避免加载路径失效；确保移除后 deploy/scripts 目录仅保留能力矩阵所需脚本：load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen，.ps1 与 .sh 同名脚本行为一致）。

### deploy/scripts 目录现状（TASK-008 实际检查结果，28 个文件）
- **统一配置加载**：load-env.ps1、load-env.sh
- **环境检查**：deploy-check-env.ps1、deploy-check-env.sh
- **基础设施启动**：deploy-start-services.ps1、deploy-start-services.sh
- **一键总入口**：deploy-start-all.ps1、deploy-start-all.sh
- **单服务启动**：deploy-start-gateway.ps1/.sh、deploy-start-auth.ps1/.sh、deploy-start-biz.ps1/.sh、deploy-start-system.ps1/.sh
- **RSA 密钥生成**：deploy-rsa-keygen.ps1、deploy-rsa-keygen.sh
- **数据库初始化**：deploy-db-init.ps1、deploy-db-init.sh
- **构建**：build-backend.ps1/.sh、build-client.ps1/.sh
- **弃用脚本残留（本任务清理对象）**：deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh（三者均被 git 跟踪；deploy-env.ps1 无 .sh 对版本，单版本残留）
- 占位：.gitkeep

> 注：前序任务 TASK-001~007 已完成——能力矩阵脚本（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen）均已按 v0.2.7 规范重构完成；build-backend/build-client/deploy-db-init 为 v0.2.5 迁移的合法脚本（非弃用残留，不在本任务删除范围，保留与否以 deploy/deploy.md 目录树声明与 PM 确认为准）。本任务仅清理 deploy-env* 弃用残留并同步引用关系。

### deploy/deploy.md 目录树声明（第 67-73 行，需同步修正）
```
deploy/
└── scripts/                          # 部署运维脚本（全部 .sh/.ps1）
    ├── deploy-env.ps1 / .sh          # 环境注入（已弃用，兼容保留）   ← 第 72 行：宣称存在 deploy-env.sh，实际不存在（P7-09）
    ├── deploy-env-template.ps1 / .sh # 环境模板生成                  ← 第 73 行：宣称 .sh 存在（实际存在）
```
> 文档与事实不符：目录树宣称存在 deploy-env.sh，实际 deploy/scripts 目录中无 deploy-env.sh。

### 全项目对弃用脚本（deploy-env）的引用关系清单（grep 实测）
| 引用位置 | 引用内容 | 处置方向 |
| --- | --- | --- |
| deploy/scripts/deploy-env.ps1（本体） | 第 29 行自引用 `.\deploy\scripts\deploy-env.ps1`；第 10/17/40/53/112 行引用 deploy-rsa-keygen.ps1、load-env.ps1、env.json | 删除本体（git rm） |
| deploy/scripts/deploy-env-template.ps1（本体） | 第 8/22 行引用 load-env.ps1、deploy-rsa-keygen.ps1 | 删除本体（git rm） |
| deploy/scripts/deploy-env-template.sh（本体） | 第 7/18/23 行引用 load-env.sh、deploy-rsa-keygen.sh | 删除本体（git rm） |
| deploy/deploy.md 第 72-73 行 | 目录树声明 deploy-env.ps1/.sh 与 deploy-env-template.ps1/.sh | 从目录树移除两行（或标注已删除），与事实一致 |
| README.md 第 229 行 | `./deploy-env.sh  # 或 PowerShell: .\deploy-env.ps1`（部署/环境变量加载指引） | 同步更新为 load-env 用法（需读取上下文确认章节内容） |
| docs/cso-lld.md 第 771-772 行 | 部署脚本迁移清单：`deploy-env-template.sh`、`deploy-env.ps1（.ps1）`、`deploy-env-template.ps1`、`deploy-env.ps1` | 从清单移除弃用脚本（主文档，本任务完成后同步或由 doc-merge 统一处理，需与 PM 确认范围） |
| scripts/deployment-guide.md 第 1535 行 | 表格行：`deploy-env-template.* | 环境变量模板（已弃用）` | 同步更新/删除（旧路径文档，需确认是否仍在维护） |
| scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1 | UT-134-1/134-2（正向断言残留存在，P0 现状确认）、UT-143-2（断言唯一单版本为 deploy-env.ps1） | TASK-001 验收测试：残留移除后需反转断言（或由 TASK-008 测试更新） |
| scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1 第 228-229 行 | v0.2.5 验收测试：预期文件清单含 deploy-env.ps1/deploy-env-template.* | 历史版本测试脚本（v0.2.5 归档），仅记录现状，一般不改 |
| scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1 第 63-64 行 | v0.2.5 迁移测试：文件清单含 deploy-env.ps1/deploy-env-template.* | 历史版本测试脚本，仅记录现状，一般不改 |
| scripts/API-TEST/cso-unit-test-start-single-v0.2.7.ps1 | UT-193-3（负向断言：8 个脚本内无 deploy-env.ps1/deploy-env-local 引用，P0 合规） | 正向约束测试：保留，作为引用关系无残留的回归依据 |
| docs/prompts/prompt-*.md | 会话过程记录（提及 deploy-env 的历史对话） | 历史存档，不改 |
| docs/sad.md ADR-016 | 决策记录描述含"删除弃用脚本残留（deploy-env 等）" | ADR 历史决策描述，不改 |

---

## 1. 任务信息

```json
{
  "id": "TASK-008",
  "title": "清理弃用脚本残留并同步引用关系",
  "description": "删除或明确弃用 deploy/scripts 下弃用残留脚本（deploy-env.ps1、deploy-env-template.ps1 等）；检查全部脚本与文档对弃用脚本的引用关系并同步更新，避免加载路径失效；确保移除后 deploy/scripts 目录仅保留能力矩阵所需脚本（load-env、deploy-check-env、deploy-start-services、deploy-start-all、deploy-start-gateway/auth/biz/system、deploy-rsa-keygen），.ps1 与 .sh 同名脚本行为一致（F-011、ADR-016）。",
  "taskType": "common",
  "userStoryId": "US-004",
  "apiId": "",
  "upstreamTaskIds": ["TASK-001", "TASK-002", "TASK-003", "TASK-004", "TASK-005", "TASK-006", "TASK-007"],
  "downstreamTaskIds": ["TASK-010"],
  "priority": "P1",
  "status": "未完成",
  "testMethod": "目录核对（弃用脚本已移除）；全量脚本与文档引用关系检查（grep deploy-env 确认无残留引用）",
  "acceptanceCriteria": "deploy/scripts 目录无弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1 已移除或明确弃用）；其余脚本与文档对弃用脚本的引用已同步更新，加载路径不失效；目录仅保留能力矩阵所需脚本"
}
```

## 2. 用户需求

### US-004：双平台脚本契约一致与输出规范
#### 故事描述
作为（运维/部署工程师），我想要（.ps1 与 .sh 双版本脚本行为一致、输出统一分级、密钥契约一致、无弃用脚本残留），以便（Windows 与 Linux 部署行为可预期、结果可核对、仓库整洁可审计）。
#### 前置条件
- 已完成 `deploy/scripts` 全量脚本重构（对应 F-001~F-011）。
#### 验收标准
- [ ] Given 重构完成，When 检查 `deploy-rsa-keygen.sh` 与 `.ps1` 输出，Then 两者输出契约一致（DER 编码单行 Base64，公钥 X.509 / 私钥 PKCS#8，无 PEM 头尾、无换行），与 Java 端解码契约一致
- [ ] Given 重构完成，When 检查 `deploy/scripts` 目录，Then 无弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1 已移除或明确弃用），无硬编码默认地址
- [ ] Given 双版本脚本存在，When 分别在 Windows PowerShell 与 Linux Bash 校验语法与执行契约自校验，Then 均通过且输出分级（通过/警告/失败）与退出码约定一致
- [ ] Given 脚本文件更新完成，When 检查文件头，Then 保留 SPDX-License-Identifier（Apache-2.0）与版权声明
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| .sh 与 .ps1 输出格式不一致 | 以 v0.2.6 确立的 DER 单行 Base64 契约为准对齐（ADR-015） |
| 移除弃用脚本后其他脚本引用 | 检查引用关系并同步更新，避免加载路径失效 |
| 退出码约定不统一 | 统一为：全部通过 0 / 失败非零（脚本约定） |
| 密码/密钥出现在日志 | 校验脚本输出不含 DB_PASSWORD、RSA_PRIVATE_KEY 明文 |
#### 关联功能编号
F-010、F-011

## 3. 项目信息

**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**数据库**：MariaDB 10.6（认证库 `cloudstroll_office_auth` 9 张表；biz/system 库预留）；Redis 7.2.x（会话/黑名单/状态缓存）
**总体介绍**：基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 的微服务企业办公套件。后端 Maven 多模块（common/gateway/auth-service/biz-service/system-service），配套 Flutter 客户端（Web + Windows）。已实现 RBAC 多租户权限模型、6 种客户端类型混合登录、JWT RS256 双 Token、Redis 会话管理、网关 AuthFilter 全局认证（9 步校验）、多模式登录/注册等。基础设施依赖 MariaDB 10.6、Redis 7.2、Nacos 2.3。

### 与本任务相关的项目规范（project.md 摘要）
- 部署资产：最终构建产物统一输出到根目录 `deploy`；`env.json`/`env.example.json` 与 `deploy/scripts` 下全部 .sh/.ps1 集中存放；构建中间产物禁止进入 deploy。
- 文件头保留 SPDX-License-Identifier 与版权声明；注释使用简体中文。
- 禁止提交密钥、密码等敏感信息；不提交日志与临时文件。
- 提交信息遵循 Conventional Commits 规范（refactor:/chore:/docs: 适用于脚本清理）。

## 4. 系统架构相关

### 脚本体系约束（SAD 1.2，v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据。
- 脚本能力划分：可用性检查（deploy-check-env）→ 基础设施一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all）→ 单服务启动（deploy-start-gateway/auth/biz/system）。
- .ps1 与 .sh 双平台行为一致；输出统一分级（通过/警告/失败）、退出码约定（失败非零）。
- RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏。

### 部署脚本体系重构决策（ADR-016，v0.2.7）
- 以 `deploy/env.json` 为唯一配置源（load-env 统一加载）；能力划分为四类：可用性检查、基础设施一键启动、后端按序一键启动、单服务启动。
- .ps1 与 .sh 双平台行为对齐；输出分级与退出码约定统一；**删除弃用脚本残留（deploy-env 等）**；.sh 与 .ps1 密钥输出契约对齐（不破坏 ADR-015）。
- 同时治理 `.gitignore`，排除生成/测试/调试临时与中间文件。

### 部署顺序与端口（SAD 部署架构）
- 后端服务按依赖顺序启动：gateway（9000）→ auth-service（9100）→ biz-service（9200）→ system-service（9400）。
- 基础设施：Nacos 2.3（8848）、MariaDB 10.6（3306）、Redis 7.2（6379）。
- 基础设施启动顺序：MariaDB → Redis → Nacos（数据库与缓存先于注册中心）。
- 各服务提供 `/api/v1/{module}/health` 健康检查端点；部署 jar 落位 deploy 目录（cloudoffice-gateway.jar 等）。

### 关键配置项（env.json，load-env 加载）
- Nacos：`NACOS_ADDR`（host:port）、`NACOS_HOME`（安装目录，检测/启动用）。
- 数据库：`DB_HOST`、`DB_PORT`、`DB_USERNAME`、`DB_PASSWORD`、`DB_USER`（兼容项）、`DB_SERVICE_NAME`、`DB_PROCESS_NAME`。
- Redis：`REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD`、`REDIS_DATABASE`、`REDIS_SERVICE_NAME`、`REDIS_PROCESS_NAME`。
- 安全：`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`（DER 编码单行 Base64）。
- 应用参数：`VERIFICATION_CODE_*`、`PASSWORD_MIN_LENGTH`/`PASSWORD_MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ`。

## 5. TASK-001 问题清单关键发现（issue-list.md，本任务直接依据）

### P2 弃用脚本残留（对应 F-011 / ADR-016 / US-004）
- **问题定位**：`deploy/scripts/deploy-env.ps1`（113 行，文件头自称"已弃用""兼容保留"）、`deploy/scripts/deploy-env-template.ps1`（78 行，自称"已弃用"）、`deploy/scripts/deploy-env-template.sh`（83 行，自称"已弃用"）；三者均被 git 跟踪。
- **问题表现**：① deploy-env.ps1 无 .sh 对版本（单版本残留，破坏双平台一一对应）；② 三者与 `load-env.ps1/.sh + deploy/env.example.json` 双份配置逻辑并存，易混淆；③ `deploy/deploy.md` 第 72-73 行目录树宣称存在 `deploy-env.ps1 / .sh` 与 `deploy-env-template.ps1 / .sh`，**实际目录中无 deploy-env.sh**（文档与事实不符）；④ deploy-env.ps1 第 67 行 `$env:NACOS_ADDR = '<NACOS_HOST>:8848'` 等仍以占位符直接写死环境变量，违反配置驱动原则。
- **影响**：运维人员可能误用旧脚本造成配置丢失/覆盖；目录树与实际不符误导部署；仓库残留冗余代码。
- **建议处置**：按 ADR-016 删除或明确弃用并移除引用（`git rm`）；同步修正 deploy/deploy.md 目录树第 72-73 行；确认无其他脚本引用 deploy-env* 后再移除（grep 引用关系）。

### P7 相关发现
- P7-08：根目录 `scripts/` 下存在旧路径脚本残留（scripts/deploy-rsa-keygen.ps1、scripts/deploy-rsa-keygen.sh、scripts/deployment-guide.md），与 deploy/scripts 新版重复——历史路径残留，按需清理（不在本任务范围，仅提示）。
- P7-09：`deploy/deploy.md` 第 72-73 行目录树宣称存在 `deploy-env.sh`，实际不存在——随 P2 处置同步修正文档。

## 6. 本任务执行要点（TL 提示）
1. 本任务为"清理弃用脚本残留并同步引用关系"，上游 TASK-001~007 已完成（能力矩阵脚本均已重构），下游 TASK-010。
2. 清理对象：deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh（git rm 删除，非"标注弃用保留"——ADR-016 明确"删除弃用脚本残留"）。
3. 引用关系同步清单见上文"全项目对弃用脚本的引用关系清单"，逐项处置；不得遗漏 deploy.md 目录树、README.md、docs/cso-lld.md、scripts/deployment-guide.md 等文档引用。
4. 保留的合法脚本（build-backend/build-client/deploy-db-init 等）不在删除范围；删除前先确认 deploy/deploy.md 目录树对其的声明，保持目录树与实际一致。
5. 移除后目录核验：deploy/scripts 仅保留能力矩阵脚本 + build-*/deploy-db-init（合法脚本）+ .gitkeep；`grep deploy-env` 无残留引用（docs/prompts 历史会话与历史版本测试脚本除外）。
6. 文件头规范：修改的脚本/文档保留 SPDX-License-Identifier（Apache-2.0）与版权声明；提交信息用 Conventional Commits。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
