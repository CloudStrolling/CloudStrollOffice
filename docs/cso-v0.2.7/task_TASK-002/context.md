# 任务上下文（TASK-002 实现 load-env.ps1 / load-env.sh 统一配置加载模块）

## 0. 用户输入原文

检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成，测试，调试过程中的临时文件和中间文件在 .gitignore 中排除。

### 任务定义
实现 load-env.ps1 / load-env.sh 统一配置加载模块（新增双平台脚本，从 deploy/env.json 统一加载环境配置 NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_HOST/REDIS_PORT/REDIS_PASSWORD/REDIS_DATABASE/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME/RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 等为会话环境变量；env.json 不存在时输出错误提示并退出非零；关键配置缺失时逐个列出缺失项并退出；不硬编码地址凭据；保留 SPDX-License-Identifier 版权头与简体中文注释）。

### 现有 load-env 分析（TASK-001 cs.md 2.1 + issue-list.md 结论）
- `load-env.ps1`（35 行）：`param([string]$EnvFile = "env.json")`；`$ProjectDir = Split-Path -Parent $PSScriptRoot`（= deploy）；`ConvertFrom-Json` 后 `Set-Item -Path "env:$($_.Name)"` 注入；失败 `exit 1`。
  - **问题点（低）**：第 35 行 `$MyInvocation.MyCommand.ScriptBlock.Module.SessionState.Path.CurrentFileSystemDrive` 为孤立死代码（无赋值、无输出）——**经 issue-list P7-05 实际核对，该孤立行实际位于 deploy-check-env.ps1 第 35 行，load-env.ps1 本身干净，本任务无需处理**。
- `load-env.sh`（39 行）：jq 优先、python3 回退；`eval "$(jq -r 'to_entries | .[] | "export \(.key)=\(.value | @sh)"')"`；失败 `return 1`。
- **可复用**：全部重构脚本应继续统一调用 load-env.ps1/.sh，不重复实现加载逻辑。TASK-002 在现有基础上补齐 env.json 缺失提示、关键配置缺失逐项列出、非零退出等 F-001 契约。

---

## 1. 任务信息

```json
{
  "id": "TASK-002",
  "title": "实现 load-env.ps1 / load-env.sh 统一配置加载模块",
  "description": "新增 load-env.ps1 与 load-env.sh 双平台脚本，从 deploy/env.json 统一加载环境配置（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_HOST/REDIS_PORT/REDIS_PASSWORD/REDIS_DATABASE/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME/RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 等）为会话环境变量；env.json 不存在时输出错误提示（复制 env.example.json 并填写配置）并以非零码退出；关键配置缺失时逐个列出缺失项并退出；脚本内不硬编码环境地址与凭据；保留 SPDX-License-Identifier（Apache-2.0）版权头与简体中文注释（F-001）。",
  "taskType": "common",
  "userStoryId": "US-001",
  "apiId": "",
  "upstreamTaskIds": ["TASK-001"],
  "downstreamTaskIds": ["TASK-003", "TASK-004", "TASK-005", "TASK-006"],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "PowerShell 语法解析 + Bash 语法校验（bash -n）；env.json 存在/缺失/关键配置缺失三场景行为验证与退出码核对",
  "acceptanceCriteria": "load-env.ps1/.sh 能从 deploy/env.json 加载全部键值对为环境变量；env.json 缺失时提示复制 env.example.json 并以非零码退出；关键配置缺失时逐个列出缺失项并退出非零；脚本内无硬编码地址与凭据"
}
```

## 2. 用户需求（PRD US-001 与 F-001）

### US-001：基于 env.json 一键检查环境可用性
#### 故事描述
作为（运维/部署工程师），我想要（基于 deploy/env.json 一键检查 JDK/MariaDB/Redis/Nacos 四类环境的可用性），以便（确认环境是否满足部署前置条件，避免人工逐个验证与配置遗漏）。
#### 前置条件
- 已按 deploy.md 完成 `deploy/env.json` 配置（至少含 NACOS_ADDR、NACOS_HOME、DB_*、REDIS_* 关键项）；
- 部署主机已安装（或未安装待检测）JDK 21、MariaDB/MySQL、Redis、Nacos。
#### 验收标准（本任务相关项）
- [ ] Given deploy/env.json 存在且配置完整，When 执行任一重构脚本，Then 脚本经 load-env 从 env.json 加载配置并可用
- [ ] Given env.json 缺失或关键配置不完整，When 执行脚本，Then 输出明确错误提示（复制 env.example.json 并填写配置）并以非零码退出
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| env.json 缺失 | 提示复制 env.example.json 并填写配置，非零码退出 |
| 关键配置缺失 | 逐个列出缺失项，非零码退出 |
| 环境地址硬编码残留 | 检查脚本源码确认无 192.168.1.100 等硬编码地址 |
#### 关联功能编号
F-001（本任务）；US-001 另关联 F-002~F-006、F-010（下游任务）

### F-001 env.json 配置加载统一（PRD 4.1）
#### 功能描述
全部重构脚本统一通过 `load-env.ps1` / `load-env.sh` 从 `deploy/env.json` 加载环境配置（NACOS_ADDR、NACOS_HOME、DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/DB_SERVICE_NAME/DB_PROCESS_NAME、REDIS_HOST/REDIS_PORT/REDIS_PASSWORD/REDIS_DATABASE/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME、RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 等），避免脚本间重复/不一致的加载逻辑；缺失 env.json 或关键配置项时给出明确错误提示。
#### 业务规则（本任务编码直接依据）
- load-env 脚本保持从 `deploy/env.json` 读取（`Join-Path $ProjectDir env.json` / `$PROJECT_DIR/env.json`），将 JSON 键值对设置为当前会话环境变量；
- env.json 不存在时输出错误提示（复制 env.example.json 为 env.json 并填写配置）并以非零码退出；
- 各脚本必须在加载后校验本脚本所需的关键配置项（至少含 NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT），缺失项逐个列出并退出；
- 脚本内不得硬编码环境地址与凭据，全部读取自 env.json（经 load-env 加载后的环境变量）。
#### 页面原型说明
无页面原型（命令行脚本）。

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
- 禁止提交密钥、密码等敏感信息（RSA 密钥对、数据库密码等通过 env.json 注入，密钥文件放 keys/ 并加入 .gitignore）；不提交日志与临时文件。

## 4. 系统架构相关

### 脚本体系约束（SAD 1.2，v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据。
- 脚本能力划分：可用性检查（deploy-check-env）→ 基础设施一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all）→ 单服务启动（deploy-start-gateway/auth/biz/system）。
- .ps1 与 .sh 双平台行为一致；输出统一分级（通过/警告/失败）、退出码约定（失败非零）。
- RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏。

### 部署脚本体系重构决策（ADR-016，v0.2.7）
- 以 `deploy/env.json` 为唯一配置源（load-env 统一加载）；能力划分为四类：可用性检查、基础设施一键启动、后端按序一键启动、单服务启动。
- .ps1 与 .sh 双平台行为对齐；输出分级与退出码约定统一；删除弃用脚本残留（deploy-env 等）；.sh 与 .ps1 密钥输出契约对齐（不破坏 ADR-015）。
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
- 安全：`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`（DER 编码单行 Base64，契约 ADR-015）。
- 应用参数：`VERIFICATION_CODE_*`、`PASSWORD_MIN_LENGTH`/`PASSWORD_MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ`。

## 5. 本任务执行要点（TL 提示）
1. 本任务为 v0.2.7 部署脚本重构的第 1 个实现任务（上游 TASK-001 问题清单已完成；下游 TASK-003/004/005/006 全部依赖本任务的 load-env 统一加载能力），必须保证双平台脚本可用、契约完整。
2. 核心契约（F-001）：env.json 存在则加载全部键值对为会话环境变量；env.json 缺失则提示「复制 env.example.json 并填写配置」并以非零码退出；关键配置缺失时逐个列出缺失项并退出非零；脚本内无硬编码地址与凭据。
3. 双平台行为一致：.ps1 与 .sh 均须实现同一套契约（语法校验 + 三场景行为验证：env.json 存在 / 缺失 / 关键配置缺失），退出码一致（加载成功 0 / env.json 缺失或关键配置缺失 非零）。
4. 关键配置项建议至少含：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT（PRD F-001 业务规则原文），可考虑将 DB_SERVICE_NAME/DB_PROCESS_NAME/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME/RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 纳入可选校验（依各下游脚本实际所需，本任务以 F-001 规则为准）。
5. 保留 SPDX-License-Identifier（Apache-2.0）版权头与简体中文注释；口令类敏感值不得明文输出。
6. 测试方法（任务 testMethod）：PowerShell 语法解析（Parser.ParseFile）+ Bash 语法校验（bash -n）；env.json 存在/缺失/关键配置缺失三场景行为验证与退出码核对。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
