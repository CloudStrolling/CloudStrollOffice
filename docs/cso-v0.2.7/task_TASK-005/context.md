# 任务上下文（TASK-005 新增 deploy-start-all.ps1 / .sh 后端服务按序一键启动）

## 0. 用户输入原文与本任务定位

### 用户输入
检查并重构 deploy\scripts 目录下所有的脚本。主要实现如下功能：
1. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 的可用性。
2. 根据 deploy 下的环境配置文件，检查 jdk、mariadb、redis、nacos 是否已启动，并将未启动的服务一键启动。
3. 按部署的顺序要求，一键启动所有的 java 后台服务。
另外，整体检查一下项目当前的文件，将生成、测试、调试过程中的临时文件和中间文件在 .gitignore 中排除。

### 任务定义
新增 deploy-start-all.ps1 / .sh 后端服务按序一键启动：加载 env.json 后校验 4 个 jar 包存在（deploy/cloudoffice-gateway.jar、cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar）与关键环境变量就绪（NACOS_ADDR、RSA_PUBLIC_KEY（gateway/auth）、RSA_PRIVATE_KEY（auth）、DB_PASSWORD（auth/biz/system）等）；按 gateway(9000) → auth(9100) → biz(9200) → system(9400) 顺序以 java -Xms256m -Xmx512m -jar <jar> 启动各服务（Windows Start-Process 独立窗口/后台、Linux nohup 后台并记录 PID 或日志文件）；每个服务启动后健康确认（HTTP 探测 http://localhost:{port}/api/v1/{module}/health 或端口探测，可配置等待重试次数与单次超时），确认成功后再启动下一个；任一步骤失败即停并输出明确错误提示（如端口被占用提示检查 9000/9100/9200/9400）；输出 4 个服务启动结果与健康状态汇总（F-008）。

### 本任务职责边界（TL 提示）
- 本任务**新增 deploy/scripts/deploy-start-all.ps1 与 deploy-start-all.sh 两个脚本**（后端服务按序一键启动总入口，F-008），**不涉及** deploy-check-env（TASK-003 已完成）、deploy-start-services（TASK-004 已完成）、单服务脚本重构（TASK-010）、rsa-keygen（其他任务）、.gitignore 治理（TASK-007）。
- 上游依赖：TASK-001（问题清单，P6 定位）、TASK-002（load-env 模块已完成，F-001）；可复用 TASK-003/004 已完成的检测/启动函数模式。
- 下游任务：TASK-006、TASK-008、TASK-010。

---

## 1. 任务信息

```json
{
  "id": "TASK-005",
  "title": "新增 deploy-start-all.ps1 / .sh 后端服务按序一键启动",
  "description": "新增 deploy-start-all.ps1 与 deploy-start-all.sh：加载 env.json 后校验 4 个 jar 包存在（deploy/cloudoffice-gateway.jar、cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar）与关键环境变量就绪（NACOS_ADDR、RSA_PUBLIC_KEY（gateway/auth）、RSA_PRIVATE_KEY（auth）、DB_PASSWORD（auth/biz/system）等）；按 gateway(9000) → auth(9100) → biz(9200) → system(9400) 顺序以 java -Xms256m -Xmx512m -jar <jar> 启动各服务（Windows Start-Process 独立窗口/后台、Linux nohup 后台并记录 PID 或日志文件）；每个服务启动后健康确认（HTTP 探测 http://localhost:{port}/api/v1/{module}/health 或端口探测，可配置等待重试次数与单次超时），确认成功后再启动下一个；任一步骤失败失败即停并输出明确错误提示（如端口被占用提示检查 9000/9100/9200/9400）；输出 4 个服务启动结果与健康状态汇总（F-008）。",
  "taskType": "common",
  "userStoryId": "US-003",
  "apiId": "",
  "upstreamTaskIds": ["TASK-001", "TASK-002"],
  "downstreamTaskIds": ["TASK-006", "TASK-008", "TASK-010"],
  "priority": "P0",
  "status": "未完成",
  "testMethod": ".ps1/.sh 语法校验；jar 缺失/关键变量缺失前置校验失败场景验证；顺序启动与逐服务健康确认验证；失败即停场景验证",
  "acceptanceCriteria": "deploy-start-all.ps1/.sh 按 gateway→auth→biz→system 顺序一键启动 4 个后端服务并逐服务健康确认后再启动下一个；jar 或关键变量缺失时输出缺失项与处理提示，以非零码退出且不启动任何服务；任一步骤失败时停止后续启动并输出明确错误提示；全部成功输出 4 服务启动结果与健康状态汇总，退出码 0"
}
```

## 2. 用户需求

### US-003：按部署顺序一键启动全部后端服务
#### 故事描述
作为（运维/部署工程师），我想要（按部署顺序 gateway → auth → biz → system 一键启动全部 Java 后台服务），以便（一条命令完成整个后端环境拉起，避免按错顺序、遗漏服务、逐个开窗口的低效与出错风险）。
#### 前置条件
- 4 个服务 jar 包已构建并落位 deploy 目录（cloudoffice-gateway.jar 等）；
- `deploy/env.json` 已配置 NACOS_ADDR、RSA_PRIVATE_KEY/RSA_PUBLIC_KEY、DB_PASSWORD 等关键项；
- 基础设施（MariaDB/Redis/Nacos）已就绪（可由 US-002 脚本先行拉起）。
#### 验收标准
- [ ] Given 4 个 jar 与关键环境变量就绪，When 执行 `deploy-start-all.ps1`/`.sh`，Then 按 gateway → auth → biz → system 顺序逐个启动，每服务启动后健康确认成功后再启动下一个
- [ ] Given 某 jar 缺失或关键变量缺失，When 执行一键启动脚本，Then 输出缺失项与处理提示，以非零码退出，不启动任何服务
- [ ] Given 某服务启动失败，When 执行一键启动脚本，Then 输出明确错误提示并停止后续启动（默认失败即停策略）
- [ ] Given 全部服务启动成功，When 执行一键启动脚本，Then 输出 4 个服务的启动结果与健康状态汇总，退出码 0
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| gateway 启动失败 | 停止后续服务启动，提示检查 NACOS_ADDR/RSA_PUBLIC_KEY |
| 健康检查超时 | 按等待重试次数重试，仍失败则输出失败并停止 |
| 端口被占用 | 提示检查端口占用（9000/9100/9200/9400）并指导处理 |
| 需要只启动单个服务 | 使用单服务脚本 deploy-start-gateway/auth/biz/system |
#### 关联功能编号
F-001、F-008、F-009

## 3. 本任务相关功能详细描述（PRD v0.2.7 摘录）

### F-008 后端服务按序一键启动
#### 功能描述
提供一键启动全部 Java 后台服务的脚本 `deploy-start-all.ps1` / `.sh`，按部署顺序（gateway → auth → biz → system）逐个启动 4 个后端服务，启动前校验 jar 包与关键环境变量就绪，并对每个服务做启动确认。
#### 业务规则（本任务编码直接依据）
- 启动顺序固定为：gateway（9000）→ auth-service（9100）→ biz-service（9200）→ system-service（9400）；
- 启动前校验：4 个 jar 包存在（deploy/cloudoffice-gateway.jar、cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar）；关键环境变量就绪（NACOS_ADDR、RSA_PUBLIC_KEY（gateway/auth）、DB_PASSWORD（auth/biz/system）等）；
- 启动命令统一为 `java -Xms256m -Xmx512m -jar <jar>`，各服务独立后台运行（Windows 独立窗口或 Start-Process，Linux nohup/后台执行并记录 PID 或日志文件）；
- 每个服务启动后执行健康确认：HTTP 探测（如经网关 `http://localhost:9000/api/v1/{auth|biz|system}/health` 或各服务端口探测），确认成功后再启动下一个；不满足时可配置等待重试次数/超时；
- 任一步骤失败时输出明确错误提示并停止后续启动（默认失败即停）；
- 输出全部服务的启动结果与健康状态汇总。
#### 页面原型说明
无页面原型（命令行脚本）。

### F-001 env.json 配置加载统一（load-env 已完成，TASK-002 交付，直接复用）
- load-env.ps1 / load-env.sh 从 `deploy/env.json` 读取键值对注入会话环境变量；env.json 缺失时输出错误提示（复制 env.example.json）并以非零码退出；关键配置校验下限 8 项：NACOS_ADDR、NACOS_HOME、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT，缺失项逐个列出键名并退出非零；
- 各脚本必须经 load-env 加载后校验本脚本所需的关键配置项，缺失项逐个列出并退出；
- **脚本内不得硬编码环境地址与凭据**，全部读取自 env.json 加载后的环境变量。

### F-011 脚本契约与输出规范（全部脚本统一遵守）
- 输出分级约定：成功项前缀"通过"（绿色）、警告项"警告"（黄色）、失败项"失败"（红色）；汇总显示通过/警告/失败计数；
- 退出码约定：全部通过退出 0；存在失败项退出非零（1）；参数错误可细化退出码 2；存在警告但无失败退出 0 并提示警告；
- 脚本文件保留 SPDX-License-Identifier（Apache-2.0）与版权声明，简体中文注释，版本号统一 v0.2.7；
- .ps1 与 .sh 同名脚本行为一致、可独立验证（语法校验 + 契约自校验）；口令/密钥类敏感值不得明文输出。

## 4. 项目信息

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
- 禁止提交密钥、密码等敏感信息（DB_PASSWORD、RSA 私钥等通过 env.json 注入，日志/输出不得打印明文）；不提交日志与临时文件。
- 提交信息遵循 Conventional Commits 规范。

## 5. 系统架构相关

### 脚本体系约束（SAD 1.2 / ADR-016，v0.2.7 起）
- 全部部署脚本统一通过 `load-env.ps1`/`load-env.sh` 从 `deploy/env.json` 加载配置，脚本内不得硬编码环境地址与凭据。
- 脚本能力划分：可用性检查（deploy-check-env）→ 基础设施一键启动（deploy-start-services）→ **后端服务按序一键启动（deploy-start-all）** → 单服务启动（deploy-start-gateway/auth/biz/system）。
- .ps1 与 .sh 双平台行为一致；输出统一分级（通过/警告/失败）、退出码约定（失败非零）。
- RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏（本任务仅校验变量非空存在，不校验密钥格式）。

### 部署顺序与端口（SAD 部署架构 / deploy.md 部署方案契约）
- **后端服务启动顺序（固定契约）**：gateway（9000）→ auth-service（9100）→ biz-service（9200）→ system-service（9400）；网关统一入口建议最先启动，业务服务随后。
- 基础设施：Nacos 2.3（8848）、MariaDB 10.6（3306）、Redis 7.2（6379）；基础设施启动顺序：MariaDB → Redis → Nacos。
- **各服务提供 `/api/v1/{module}/health` 健康检查端点**（服务名/状态/版本/时间戳）；健康检查接口为网关白名单直接放行（deploy.md 第 8 节：GET http://<主机>:9000/api/v1/auth/health 已验证可经网关访问，状态正常）。
- **部署 jar 落位 deploy 目录（v0.2.6 已重建并启动验证通过）**：`deploy/cloudoffice-gateway.jar`、`deploy/cloudoffice-auth-service.jar`、`deploy/cloudoffice-biz-service.jar`、`deploy/cloudoffice-system-service.jar`（glob 实际确认 4 个 jar 均存在）。
- 启动命令契约：`java -Xms256m -Xmx512m -jar <jar>`（deploy.md 第 5.6 节）。

### 关键配置项（env.json，load-env 加载）
- Nacos：`NACOS_ADDR`（host:port）、`NACOS_HOME`（安装目录）。
- 数据库：`DB_HOST`、`DB_PORT`、`DB_USERNAME`、`DB_PASSWORD`、`DB_USER`（兼容项）、`DB_SERVICE_NAME`、`DB_PROCESS_NAME`。
- Redis：`REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD`、`REDIS_DATABASE`、`REDIS_SERVICE_NAME`、`REDIS_PROCESS_NAME`。
- 安全：`RSA_PRIVATE_KEY`、`RSA_PUBLIC_KEY`（DER 编码单行 Base64，契约 ADR-015；本任务仅校验存在非空，不得打印明文）。
- 应用参数：`VERIFICATION_CODE_*`、`PASSWORD_MIN_LENGTH`/`PASSWORD_MAX_LENGTH`、`MARIADB_ROOT_PASSWORD`、`TZ`。

### 本任务关键变量校验清单（按任务定义与 F-009 单服务脚本差异约定）
- gateway：NACOS_ADDR、RSA_PUBLIC_KEY；
- auth：NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD（auth 使用 DB_USERNAME 的差异保持与现状一致）；
- biz/system：NACOS_ADDR、DB_PASSWORD（biz 使用 DB_USER、auth 使用 DB_USERNAME 的差异保持与现状一致，任务定义以"DB_PASSWORD（auth/biz/system）"为关键校验项）。

## 6. TASK-001 问题清单相关依据（issue-list.md 摘录，P6 / P7-01）

### P6 缺少一键启动总入口（对应 F-008 / US-003，本任务直接依据）
- **问题定位**：`deploy/scripts` 目录中不存在 `deploy-start-all.ps1` 与 `deploy-start-all.sh`（glob 目录清单确认）；现有仅 4 个单服务启动脚本：deploy-start-gateway/auth/biz/system.ps1/.sh。
- **问题表现**：无「按部署顺序（gateway → auth → biz → system）一键启动全部 Java 后台服务」的总入口；当前需手工逐个窗口启动 4 个服务；单服务脚本为前台阻塞启动（.ps1 直接 `java`、.sh `exec java`），无后台化、无健康确认、无失败即停。
- **影响**：部署效率低、易漏服务、无法自动化编排；前台阻塞方式不适合无人值守/CI 场景。
- **建议处置**：新增 `deploy-start-all.ps1/.sh` 总入口：校验 4 个 jar 与关键环境变量 → 按 gateway → auth → biz → system 顺序后台启动（.ps1 `Start-Process -RedirectStandardOutput`、.sh `nohup ... &`）→ 逐服务轮询健康端点（`GET /api/v1/{module}/health`）确认就绪 → 任一失败即停（退出非零）。

### P7-01 单服务脚本前台阻塞（供参考）
- `deploy-start-*.ps1`/`.sh` 均为前台阻塞启动，无后台化/独立窗口/健康确认；F-008 一键启动编排依赖后台化能力（本任务必须后台启动），单服务脚本后台化改造归 TASK-010。

## 7. 上游可复用模块与函数模式（TASK-002/003/004 已完成，直接复用依据）

### 7.1 load-env.ps1 / load-env.sh（TASK-002 已完成，deploy/scripts/load-env.ps1、load-env.sh）
- 统一从 `deploy/env.json` 加载全部键值对为会话环境变量；env.json 缺失时提示复制 env.example.json 并以非零码退出；关键配置（NACOS_ADDR/NACOS_HOME/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT 8 项）缺失时逐个列出缺失键名退出非零。
- **PowerShell 调用方式**：dot-source，`.\deploy\scripts\load-env.ps1`（脚本内部已处理 env.json 缺失与关键配置缺失，下游脚本无需重复校验）。
- **Bash 调用方式**：`source "$SCRIPT_DIR/load-env.sh"`（source 型脚本，失败 return 1；注意调用方 set -e 与 return 的配合）。

### 7.2 deploy-check-env.ps1 / .sh（TASK-003 已完成，检测函数模式）
- **Write-Result / print_result**（.ps1 / .sh）：输出"通过/警告/失败"三级并累计计数（$script:pass/$script:warn/$script:fail 或 PASS/WARN/FAIL）。
- **Test-TcpPort / tcp_port_open**（.ps1 / .sh）：TCP 端口可达性探测（TcpClient 超时 / /dev/tcp），可用于本任务端口探测式健康确认（备用方案）。
- **Test-NacosHttp / nacos_http_ok**：HTTP 探测（本任务可参照实现 HTTP 健康探测函数）。
- **口令掩码与安全约定**：口令类参数日志仅显示 `****`，命令与日志不出现明文（本任务不涉及口令命令，但 RSA 密钥/DB_PASSWORD 不得打印）。

### 7.3 deploy-start-services.ps1 / .sh（TASK-004 已完成，启动函数模式）
- 启动方式优先级、启动后再次探测确认（循环探测 + 超时上限，如 30s 内每 2s 探测）、不报假成功、幂等跳过（已运行输出"已运行"）、未安装不尝试启动等模式。
- **本任务对应模式**：每服务启动后轮询健康端点（等待重试次数与单次超时可配置，建议默认重试 30 次、间隔 2 秒、单次超时 3 秒），确认成功后再启动下一个；任一失败即停并输出明确错误提示。

## 8. 本任务执行要点（TL 提示）
1. 本任务**新增** `deploy/scripts/deploy-start-all.ps1` 与 `deploy/scripts/deploy-start-all.sh` 双平台脚本（F-008 总入口），必须经 load-env 加载配置、保持双平台行为一致，不修改其他既有脚本。
2. 核心流程（对照 PRD F-008 业务规则）：
   - ① load-env 加载 env.json；
   - ② 前置校验：4 个 jar 包存在 + 关键环境变量就绪（NACOS_ADDR、RSA_PUBLIC_KEY（gateway/auth）、RSA_PRIVATE_KEY（auth）、DB_PASSWORD（auth/biz/system）等）；**任一缺失输出缺失项与处理提示，以非零码退出且不启动任何服务**；
   - ③ 按 gateway → auth → biz → system 顺序逐个启动：`java -Xms256m -Xmx512m -jar <jar>`；Windows 用 `Start-Process` 后台（记录日志文件，可用 -RedirectStandardOutput/-RedirectStandardError），Linux 用 `nohup ... > log 2>&1 &` 并记录 PID（echo $!）；
   - ④ 每服务启动后健康确认：HTTP 探测 `http://localhost:{port}/api/v1/{module}/health`（首选；gateway 探测 9000 根路径或 health 端点、auth/biz/system 直接探测各自端口 health 端点），或端口探测（TcpClient//dev/tcp）作为备用；循环轮询 + 可配置重试次数/单次超时（建议默认重试 30 次、间隔 2 秒、单次超时 3 秒）；确认成功后再启动下一个；
   - ⑤ 任一步骤失败：输出明确错误提示（如"端口被占用，请检查 9000/9100/9200/9400"、"请检查 NACOS_ADDR/RSA_PUBLIC_KEY 配置"）并**停止后续启动**（默认失败即停），退出非零；
   - ⑥ 全部成功：输出 4 个服务启动结果与健康状态汇总，退出码 0。
3. 双平台一致性：.ps1 与 .sh 输出分级（通过/警告/失败）、退出码约定（全部通过 0 / 失败非零 1）、启动顺序、健康确认逻辑必须一致；不依赖 emoji 而用 [通过]/[警告]/[失败] 文本 + 颜色。
4. 安全与规范：RSA 密钥、DB_PASSWORD 等敏感值**不得打印明文**；脚本内无硬编码地址与凭据；文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明；版本号统一 v0.2.7；简体中文注释。
5. 日志文件与 PID：Linux nohup 输出建议落位 deploy/logs/ 或当前目录（注意 .gitignore 已排除 logs/、*.log）；PID 记录便于停止服务。
6. 测试方法（任务 testMethod）：.ps1/.sh 语法校验；jar 缺失/关键变量缺失前置校验失败场景验证（不启动任何服务、非零退出）；顺序启动与逐服务健康确认验证；失败即停场景验证。
7. 本任务不涉及接口（apiId 为空）与数据库变更。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
