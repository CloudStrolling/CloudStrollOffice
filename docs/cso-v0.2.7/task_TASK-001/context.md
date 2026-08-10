# 任务上下文（TASK-001 梳理 deploy/scripts 现有脚本与 .gitignore 现状并输出问题清单）

## 0. 用户输入原文与现状勘察

### 用户输入
检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成、测试、调试过程中的临时文件和中间文件在 .gitignore 中排除。

### 任务定义
梳理 deploy/scripts 现有脚本与 .gitignore 现状并输出问题清单（检查 deploy/scripts 目录全部 .ps1/.sh 脚本与项目根目录 .gitignore，识别历史遗留问题：硬编码默认地址（192.168.1.100 等）、弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1）、deploy-rsa-keygen.sh 与 .ps1 密钥输出契约不一致、可用性检查与运行状态检查能力分散、输出格式与退出码约定不统一、缺少一键启动总入口等，输出问题清单作为后续重构依据）。

### deploy/scripts 现状勘察（TASK-001 实际检查结果）
deploy/scripts 目录现有 27 个文件（含 .gitkeep）：
- 统一配置加载：load-env.ps1、load-env.sh
- 环境检查：deploy-check-env.ps1、deploy-check-env.sh
- 基础设施启动：deploy-start-services.ps1、deploy-start-services.sh
- 单服务启动：deploy-start-gateway.ps1/.sh、deploy-start-auth.ps1/.sh、deploy-start-biz.ps1/.sh、deploy-start-system.ps1/.sh
- RSA 密钥生成：deploy-rsa-keygen.ps1、deploy-rsa-keygen.sh
- 数据库初始化：deploy-db-init.ps1、deploy-db-init.sh
- 构建：build-backend.ps1/.sh、build-client.ps1/.sh
- **弃用脚本残留**：deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh
- 占位：.gitkeep

初步识别的问题（作为 TASK-001 输出问题清单的输入依据）：
1. 硬编码默认地址（192.168.1.100 等）：deploy-check-env.ps1 等仍以硬编码默认地址为主、参数化加载 env.json 为辅（PRD 1.1 背景确认）。
2. 弃用脚本残留：deploy-env.ps1 / deploy-env-template.ps1 / deploy-env-template.sh 为弃用残留脚本，易与 load-env 双份配置逻辑混淆。
3. RSA 密钥输出契约不一致：deploy-rsa-keygen.sh 与 .ps1 输出契约不一致（ADR-015：DER 编码单行 Base64，公钥 X.509 / 私钥 PKCS#8，无 PEM 头尾、无换行；.sh 需对齐 .ps1）。
4. 可用性检查与运行状态检查能力分散：各脚本对 JDK/MariaDB/Redis/Nacos 的"可用性检查"与"运行状态检查"分散，deploy-check-env 将 Nacos 可用性检查误放于"连通性检查"。
5. 输出格式与退出码约定不统一：各脚本输出分级（通过/警告/失败）与退出码约定不统一。
6. 缺少一键启动总入口：缺少"按部署顺序（gateway → auth → biz → system）一键启动全部 Java 后台服务"的 deploy-start-all 总入口脚本（.ps1/.sh）。

### .gitignore 现状勘察（TASK-001 实际检查结果）
项目根目录 .gitignore（332 行）已有分区：操作系统、通用 IDE/编辑器、AI 开发工具、前端/Node.js、Python、Java/Maven/Gradle、C/C++、Rust、Go、PHP、Dart/Flutter、客户端构建产物（deploy/cloudoffice-flutter-app）、数据库/缓存/日志/临时、环境密钥、包管理器、压缩包。
已有覆盖：target/、*.class、*.jar、*.log、logs/、tmp/、temp/、.cache/、__pycache__/、.pytest_cache/、keys/、env.json 等。
初步识别缺口（供 F-012 治理依据）：
- JVM/应用调试产物：*.hprof（堆转储）、dump 目录、崩溃日志、调试临时文件。
- 测试产物与缓存：接口测试中间文件（token 缓存、临时报告）、surefire-reports 等独立产物、测试生成的临时输出。
- 构建过程中间产物：.flattened-pom.xml、IDE 编译缓存等。
- 工具残留目录与文件：调试器/抓包工具输出、API 调试会话文件、*.history、*.session 等。
- 治理注意：不得误伤 env.example.json、.gitkeep、pom.xml、bootstrap.yml 等应入库文件；新规则须带路径前缀或精确模式。

---

## 1. 任务信息

```json
{
  "id": "TASK-001",
  "title": "梳理 deploy/scripts 现有脚本与 .gitignore 现状并输出问题清单",
  "description": "检查 deploy/scripts 目录全部 .ps1/.sh 脚本与项目根目录 .gitignore，识别历史遗留问题：硬编码默认地址（192.168.1.100 等）、弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1）、deploy-rsa-keygen.sh 与 .ps1 密钥输出契约不一致、可用性检查与运行状态检查能力分散、输出格式与退出码约定不统一、缺少一键启动总入口等，输出问题清单作为后续重构依据（对应 PRD 1.1 背景与 ADR-016）。",
  "taskType": "common",
  "userStoryId": "US-004",
  "apiId": "",
  "upstreamTaskIds": [],
  "downstreamTaskIds": [
    "TASK-002",
    "TASK-003",
    "TASK-004",
    "TASK-005",
    "TASK-007"
  ],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "对照 PRD 第 1.1 节背景与现有脚本逐项核对，输出问题清单文档；grep 检查硬编码地址与弃用脚本残留",
  "acceptanceCriteria": "输出问题清单，覆盖：硬编码默认地址、弃用脚本残留、RSA 密钥输出契约不一致、可用性/运行状态检查能力分散、输出与退出码不统一、缺一键启动总入口；清单可作为后续任务重构依据"
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
- 禁止提交密钥、密码等敏感信息（RSA 密钥对、数据库密码等通过 env.json 注入，密钥文件放 keys/ 并加入 .gitignore）；不提交日志与临时文件。

## 4. 系统架构相关

### 脚本体系约束（SAD 1.2，v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据。
- 脚本能力划分：可用性检查（deploy-check-env）→ 基础设施一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all）→ 单服务启动（deploy-start-gateway/auth/biz/system）。
- .ps1 与 .sh 双平台行为一致；输出统一分级（通过/警告/失败）、退出码约定（失败非零）。
- RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏。

### RSA 密钥格式契约（ADR-015，v0.2.6 确立）
- 统一 RSA 密钥格式为 DER 编码单行 Base64：公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo，无 PEM 头尾、无换行。
- 与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/ `PKCS8EncodedKeySpec`（私钥）解码契约严格一致。
- 禁止将多行 PEM 整体 Base64（含 BEGIN/END 标记与 \r\n）直接注入 env.json。

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
- 安全：`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`（DER 编码单行 Base64）。
- 应用参数：`VERIFICATION_CODE_*`、`PASSWORD_MIN_LENGTH`/`PASSWORD_MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ`。

## 5. 本任务执行要点（TL 提示）
1. 本任务为"梳理现状并输出问题清单"，是 v0.2.7 部署脚本重构的先行任务（无上游依赖，下游 TASK-002/003/004/005/007）。
2. 输出的问题清单须覆盖 6 类问题：硬编码默认地址、弃用脚本残留、RSA 密钥输出契约不一致、可用性/运行状态检查能力分散、输出与退出码不统一、缺一键启动总入口；并可作为后续重构任务的依据。
3. 检查手段：grep 检查硬编码地址（192.168.1.100 等）与弃用脚本残留；对照 PRD 1.1 节背景与现有脚本逐项核对。
4. .gitignore 治理属后续任务（F-012），本任务仅梳理现状与缺口。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
