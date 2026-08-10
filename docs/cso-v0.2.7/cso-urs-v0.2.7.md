# 用户需求说明书（URS）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：0.2.7
**日期**：2026-08-10
**编写人**：BA

## 1. 业务目标

本版本围绕 **部署脚本体系重构** 与 **仓库清洁度治理** 两个目标，提升项目部署运维的自动化水平与版本库健康度：

- **G1 环境可用性检查统一化**：运维人员可基于 `deploy/env.json`（环境配置文件）一键检查 JDK、MariaDB、Redis、Nacos 四类运行环境的**可用性（是否已安装）**，避免人工逐个验证、脚本与配置分离导致的检查遗漏。
- **G2 基础设施一键启动**：运维人员可基于 `deploy/env.json` 一键检查 JDK、MariaDB、Redis、Nacos 四类环境**是否已启动**，并对未启动的基础设施（MariaDB/Redis/Nacos）自动执行启动，减少部署准备阶段的重复操作与手工命令。
- **G3 后端服务按序一键启动**：运维人员可**按部署顺序一键启动全部 Java 后台服务**（网关 gateway → 认证 auth → 企业 biz → 系统 system），避免按错顺序、遗漏服务、逐个开窗口启动的低效与出错风险，实现"一条命令完成整个后端环境拉起"。
- **G4 脚本体系重构与双平台对齐**：对 `deploy/scripts` 目录下全部脚本（.ps1 / .sh 双版本）进行系统性检查与重构，消除历史遗留的契约不一致（如 deploy-rsa-keygen.sh 与 .ps1 的 RSA 密钥格式契约不一致、deploy-env 弃用脚本残留、硬编码默认参数等），使 Windows 与 Linux 行为一致、输出清晰、可独立验证。
- **G5 仓库临时/中间文件治理**：整体检查项目当前文件，将生成、测试、调试过程中产生的临时文件与中间文件（如 JVM/应用调试产物、测试缓存、构建过程文件等）在 `.gitignore` 中排除，避免误提交、保持 git 仓库整洁与可审计性。

**量化指标**：重构后 `deploy/scripts` 脚本全部通过双平台（Windows PowerShell / Linux Bash）语法与契约自校验；一键启动脚本可在未启动基础设施的环境下自动拉起 MariaDB/Redis/Nacos 并完成 4 个后端服务按序启动；`.gitignore` 覆盖新增识别的临时/中间文件类型后，`git status` 不再出现生成、测试、调试过程文件。

## 2. 用户角色

| 角色名称 | 角色说明 | 使用场景 |
| --- | --- | --- |
| 运维/部署工程师 | 负责环境准备、基础设施启停、后端服务部署与健康保障的工程人员 | 基于 env.json 检查 JDK/MariaDB/Redis/Nacos 可用性与运行状态、一键启动未运行的基础设施、按序一键启动全部 Java 后端服务 |
| 后端开发工程师 | 负责 Maven 多模块（gateway/auth/biz/system）编译、调试与本地环境联调 | 本地开发环境准备与重建、环境异常时快速检查与拉起服务、验证脚本契约一致性 |
| 测试工程师（TE） | 负责接口回归测试与部署验收 | 在干净环境按脚本完成部署前置检查与服务启动，验证一键脚本在测试环境可用 |
| 项目版本管理员 / 维护者 | 负责版本库整洁与仓库治理 | 审核 `.gitignore` 覆盖情况，确保生成、测试、调试临时/中间文件不入库 |

## 3. 业务场景

### 3.1 场景一：部署前置环境可用性检查
- **触发条件**：运维/部署工程师准备部署环境，需要确认 JDK、MariaDB、Redis、Nacos 是否已安装且可访问。
- **参与角色**：运维/部署工程师。
- **操作流程**：
  1. 运维人员确认 `deploy/env.json` 已配置（NACOS_ADDR、NACOS_HOME、DB_HOST/DB_PORT、REDIS_HOST/REDIS_PORT 等）；
  2. 执行环境检查脚本（Windows：`deploy/scripts/deploy-check-env.ps1`；Linux：`deploy/scripts/deploy-check-env.sh`）；
  3. 脚本从 `deploy/env.json` 加载配置，逐项检查 JDK（命令可用性 + 版本 21）、MariaDB（命令/服务/进程 + 数据库连通）、Redis（命令/服务/进程 + ping）、Nacos（NACOS_HOME 目录/启动脚本 + HTTP 探测）；
  4. 输出结构化检查报告（通过/失败/警告），存在失败项时给出处理提示并以非零码退出。

### 3.2 场景二：基础设施运行状态检查与一键启动
- **触发条件**：JDK/MariaDB/Redis/Nacos 已安装但部分服务未运行，需要拉起基础设施后再启动业务服务。
- **参与角色**：运维/部署工程师。
- **操作流程**：
  1. 运维人员执行基础设施检测与启动脚本（`deploy/scripts/deploy-start-services.ps1` / `.sh`）；
  2. 脚本加载 env.json 并校验必要配置完整；
  3. 脚本依次检测 MariaDB、Redis、Nacos 的运行状态（进程/系统服务/TCP 或 HTTP 探测），同时检测 JDK 可用性；
  4. 对未运行的服务按检测到的启动方式（系统服务 / 可执行文件 / NACOS_HOME startup 脚本）自动启动，并再次探测确认启动结果；
  5. 输出各服务状态汇总，全部可达后提示可进行后端服务启动。

### 3.3 场景三：后端服务按序一键启动
- **触发条件**：基础设施已就绪，需要按部署顺序启动全部 Java 后台服务。
- **参与角色**：运维/部署工程师。
- **操作流程**：
  1. 运维人员执行一键启动脚本（如 `deploy/scripts/deploy-start-all.ps1` / `.sh`）；
  2. 脚本校验 jar 包存在（deploy/cloudoffice-gateway.jar、cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar）与必要环境变量（NACOS_ADDR、RSA 密钥等）就绪；
  3. 按部署顺序（gateway → auth → biz → system）逐个启动服务，并对每个服务执行健康检查（HTTP/端口探测）确认启动成功后进入下一个；
  4. 输出全部服务的启动结果与健康状态；任一步骤失败时给出明确错误提示并停止后续启动（可配置继续策略）。
  5. 运维人员也可继续使用单个服务启动脚本（deploy-start-gateway/auth/biz/system）进行独立启动。

### 3.4 场景四：仓库临时/中间文件治理
- **触发条件**：项目经过生成、测试、调试后，工作区出现临时文件与中间文件，需要保证它们不被提交。
- **参与角色**：项目版本管理员 / 维护者、运维/部署工程师。
- **操作流程**：
  1. 整体检查项目当前文件，识别生成、测试、调试过程中的临时文件与中间文件（如 JVM 崩溃/堆转储、调试日志、测试缓存、构建过程文件、工具残留等）；
  2. 在 `.gitignore` 中补充排除规则，确保上述文件不进入版本库；
  3. 执行 `git status` 验证：仅出现预期的源码/文档变更，临时与中间文件不再出现在待提交清单中。

## 4. 功能需求（高层）

| 需求编号 | 需求名称 | 需求描述 | 优先级 |
| --- | --- | --- | --- |
| FR-001 | env.json 配置加载统一 | 全部重构脚本统一通过 `load-env.ps1` / `load-env.sh` 从 `deploy/env.json` 加载环境配置，避免脚本间重复/不一致的加载逻辑；缺失 env.json 或关键配置项时给出明确错误提示 | 高 |
| FR-002 | JDK 可用性检查 | 根据 env.json 检查 JDK 是否已安装：检测 java 命令可用性、`JAVA_HOME` 是否设置且目录有效、java 版本为 21；版本不符或缺失时输出失败并提示 | 高 |
| FR-003 | MariaDB 可用性检查 | 根据 env.json（DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/DB_SERVICE_NAME/DB_PROCESS_NAME）检查 MariaDB/MySQL 是否已安装：命令/服务/进程三重检测，并通过数据库连接（SELECT 1）验证连通性 | 高 |
| FR-004 | Redis 可用性检查 | 根据 env.json（REDIS_HOST/REDIS_PORT/REDIS_SERVICE_NAME/REDIS_PROCESS_NAME）检查 Redis 是否已安装：命令/服务/进程三重检测，并通过 `redis-cli ping` 验证连通性 | 高 |
| FR-005 | Nacos 可用性检查 | 根据 env.json（NACOS_ADDR/NACOS_HOME）检查 Nacos 是否已安装：NACOS_HOME 目录与启动脚本（startup.cmd/startup.sh）存在性 + HTTP 探测（`http://NACOS_ADDR/nacos/`） | 高 |
| FR-006 | 运行状态检测 | 检查 JDK、MariaDB、Redis、Nacos 是否已启动：进程/系统服务/TCP 端口/HTTP 探测等方式，输出各服务运行状态 | 高 |
| FR-007 | 未启动基础设施一键启动 | 对检测为未运行的 MariaDB/Redis/Nacos 自动执行启动（优先系统服务，其次可执行文件/NACOS_HOME 启动脚本），启动后再次探测确认；JDK 不涉及"启动"，仅检查可用性并提示 | 高 |
| FR-008 | 后端服务按序一键启动 | 提供一键启动全部 Java 后台服务的脚本，按部署顺序（gateway → auth → biz → system）逐个启动 4 个后端服务，启动前校验 jar 包与关键环境变量（NACOS_ADDR、RSA_PUBLIC_KEY/RSA_PRIVATE_KEY 等）就绪，并对每个服务做启动确认 | 高 |
| FR-009 | 单服务启动脚本保持可用 | 保留并重构单个服务启动脚本（deploy-start-gateway/auth/biz/system），加载 env.json、校验必备变量与 jar 存在后启动对应服务，供按需单独启动使用 | 中 |
| FR-010 | 前置检查脚本整合 | 重构 deploy-check-env 脚本，将其能力与"可用性检查 + 运行状态检查"对齐，从 env.json 读取参数（去除硬编码默认地址），输出通过/失败/警告汇总 | 高 |
| FR-011 | 脚本契约与输出规范 | 全部 .ps1/.sh 双版本脚本对齐：RSA 密钥生成脚本 .sh 与 .ps1 输出契约一致（DER 单行 Base64）；脚本输出统一分级（通过/警告/失败）与退出码约定（失败非零）；消除弃用脚本残留（deploy-env 等） | 高 |
| FR-012 | .gitignore 临时/中间文件治理 | 整体检查项目当前文件，识别生成、测试、调试过程中的临时文件与中间文件，在 `.gitignore` 中补充排除规则（如 JVM 堆转储/崩溃日志、调试过程文件、测试缓存、构建过程中间产物、工具残留目录等），确保 `git status` 不再出现此类文件 | 高 |

## 5. 非功能需求（高层）

| 编号 | 类别 | 需求描述 | 指标 |
| --- | --- | --- | --- |
| NFR-001 | 兼容性 | 脚本双平台可用 | 全部 .ps1 可在 Windows PowerShell 运行、.sh 可在 Linux/macOS Bash 运行，Windows 与 Linux 行为一致 |
| NFR-002 | 可靠性 | 启动结果可确认 | 基础设施一键启动后再次探测确认；后端服务启动后通过端口/HTTP 探测确认健康，避免"命令已执行但服务未起来"的假成功 |
| NFR-003 | 可维护性 | 脚本配置与实现分离 | 脚本所需环境参数全部来自 `deploy/env.json`（经 load-env 加载），脚本内不硬编码环境地址与凭据 |
| NFR-004 | 安全性 | 敏感信息保护 | 脚本日志与输出不得打印数据库口令、RSA 私钥等敏感信息（如连接命令中密码以掩码显示）；env.json 与 keys 目录保持不入库 |
| NFR-005 | 可测试性 | 脚本可验证 | 关键脚本提供契约自校验（如 RSA 密钥格式校验）；测试/验收可通过执行脚本输出与退出码断言结果 |
| NFR-006 | 易用性 | 一键化与提示清晰 | 一键启动脚本"一条命令完成基础设施拉起 + 后端服务按序启动"；失败时输出可操作的错误提示与处理建议 |
| NFR-007 | 仓库整洁性 | 临时/中间文件不污染版本库 | 更新 .gitignore 后，`git status` 不再出现生成、测试、调试过程文件；不误伤应入库的源码、文档、模板与配置模板（env.example.json） |

## 6. 约束条件

- **技术约束**：脚本体系为 Windows PowerShell（.ps1）与 Linux Bash（.sh）双平台，脚本需在两种 shell 语法下分别实现且行为对齐；后端服务为 Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1，启动命令为 `java -Xms256m -Xmx512m -jar <jar>`；部署资产集中化策略下 jar 与 env.json 均位于 `deploy` 目录。
- **基础设施约束**：MariaDB 10.6（3306）、Redis 7.2（6379）、Nacos 2.3（8848）为外部依赖，脚本只能检测与驱动其启动，不负责安装；Nacos 启动依赖 `NACOS_HOME` 配置及其 startup 脚本。
- **契约约束**：RSA 密钥格式契约（DER 编码单行 Base64，公钥 X.509 / 私钥 PKCS#8）为 v0.2.6 确立并验证的契约（ADR-015），脚本重构不得破坏该契约；.sh 与 .ps1 行为必须一致。
- **范围约束**：本版本聚焦 `deploy/scripts` 脚本重构与 `.gitignore` 治理，不修改后端业务代码与接口契约；`deploy` 目录内最终产物（jar、客户端产物）与 `scripts/sql`、`scripts/docker`、`scripts/API-TEST` 等非脚本资产不在重构范围（如发现问题列入待办）。
- **合规约束**：遵循 Apache License 2.0；脚本文件保留 SPDX-License-Identifier 与版权声明；严禁提交密钥、口令等敏感信息。

## 7. 假设与依赖

- **假设**：
  - 假设运维/部署工程师已按 deploy.md 完成 `deploy/env.json` 配置（至少含 NACOS_ADDR、NACOS_HOME、DB_*、REDIS_* 关键项）；
  - 假设部署主机已安装 JDK 21、MariaDB/MySQL、Redis、Nacos（脚本负责检测与启动，不负责安装）；
  - 假设 Linux 环境部署时使用与 Windows 契约对齐的 .sh 脚本（v0.2.6 遗留的 deploy-rsa-keygen.sh 契约不一致问题在本版本修复）；
  - 假设"JDK 启动"在业务上不适用——JDK 为运行时环境，仅检查可用性，不执行启动操作。
- **依赖**：
  - 依赖 `deploy/env.json` / `deploy/env.example.json`（环境配置模板与实际配置）作为全部脚本的唯一配置源；
  - 依赖 `load-env.ps1` / `load-env.sh` 实现统一环境变量加载；
  - 依赖 MariaDB/Redis/Nacos 安装产物与启动方式（系统服务/可执行文件/NACOS_HOME startup 脚本）可被脚本检测到；
  - 依赖 4 个后端服务 jar 包（deploy/cloudoffice-gateway.jar 等）已由构建流程生成并可执行；
  - 依赖 .gitignore 治理基于当前项目实际文件分布进行，需整体检查后确定补充规则，避免误伤应入库文件。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
