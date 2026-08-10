# 任务上下文（#TASK-010 全量脚本契约与双平台行为总体验证）

> 由 impm-task-coding-context 技能收集合并（TL），基于：PRD v0.2.7（US-004 / 第 7 章验收标准 / F-011）、SAD（ADR-014/015/016、脚本体系约束）、LLD v0.2.7（业务规则 R-01~R-16）、任务清单（TASK-001~009 产出）。

## 1. 任务信息

- **任务编号**：TASK-010
- **任务名称**：全量脚本契约与双平台行为总体验证
- **任务类型**：common（验证类）
- **关联用户故事**：US-004（双平台脚本契约一致与输出规范）
- **关联功能**：F-010、F-011
- **优先级**：P1
- **上游任务**：TASK-003（deploy-check-env 重构）、TASK-004（deploy-start-services 重构）、TASK-005（deploy-start-all 新增）、TASK-006（单服务启动脚本重构）、TASK-007（RSA 密钥输出契约对齐）、TASK-008（弃用脚本清理）——全部已完成
- **任务描述**：对 deploy/scripts 全部 .ps1/.sh 脚本执行语法校验（PowerShell 语法解析 / bash -n）与契约自校验；核对输出分级（通过/警告/失败）与退出码约定（失败非零）双平台一致；核对全部脚本均经 load-env 从 deploy/env.json 加载配置、无硬编码默认地址与凭据；核对密钥输出契约（ADR-015）未破坏；核对弃用脚本无残留；输出验证报告并对照 PRD 第 7 章 8 条验收标准逐条核对。
- **验收标准（任务级）**：全部 .ps1/.sh 脚本通过语法与契约自校验；输出分级（通过/警告/失败）与退出码约定（失败非零）双平台一致；无硬编码环境地址与凭据；密钥契约 ADR-015 未破坏；弃用脚本无残留。
- **验证方法**：全部脚本语法校验（.ps1 PowerShell 解析 / .sh bash -n）；契约自校验（密钥格式、输出分级、退出码、无硬编码地址）；对照 PRD 第 7 章验收标准逐条核对并输出验证报告。

## 2. 用户需求（US-004）

**故事描述**：作为（运维/部署工程师），我想要（.ps1 与 .sh 双版本脚本行为一致、输出统一分级、密钥契约一致、无弃用脚本残留），以便（Windows 与 Linux 部署行为可预期、结果可核对、仓库整洁可审计）。

**US-004 验收标准**：
1. 检查 deploy-rsa-keygen.sh 与 .ps1 输出 → 两者输出契约一致（DER 编码单行 Base64，公钥 X.509 / 私钥 PKCS#8，无 PEM 头尾、无换行），与 Java 端解码契约一致；
2. 检查 deploy/scripts 目录 → 无弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1 已移除或明确弃用），无硬编码默认地址；
3. 分别在 Windows PowerShell 与 Linux Bash 校验语法与执行契约自校验 → 均通过且输出分级（通过/警告/失败）与退出码约定一致；
4. 检查脚本文件头 → 保留 SPDX-License-Identifier（Apache-2.0）与版权声明。

**US-004 边界情况**：.sh 与 .ps1 输出格式不一致→以 DER 单行 Base64 契约为准对齐（ADR-015）；移除弃用脚本后其他脚本引用→检查引用关系同步更新；退出码约定不统一→统一为全部通过 0 / 失败非零；密码/密钥出现在日志→校验脚本输出不含 DB_PASSWORD、RSA_PRIVATE_KEY 明文。

## 3. PRD 第 7 章整体验收标准（8 条，TASK-010 需逐条核对）

1. 全部脚本（.ps1/.sh）均通过 load-env 从 deploy/env.json 加载配置，脚本内无硬编码环境地址（192.168.1.100 等）与凭据；env.json 缺失或关键配置缺失时输出明确错误并以非零码退出。
2. deploy-check-env.ps1/.sh 基于 env.json 完成 JDK（命令 + JAVA_HOME + 版本 21）、MariaDB（命令/服务/进程 + SELECT 1）、Redis（命令/服务/进程 + ping）、Nacos（NACOS_HOME/startup 脚本 + HTTP 探测）可用性检查，并输出运行状态；存在失败项时给出处理提示并退出非零。
3. deploy-start-services.ps1/.sh 检测到未运行的 MariaDB/Redis/Nacos 时自动启动（系统服务优先，其次可执行文件/NACOS_HOME 启动脚本），启动后再次探测确认，无假成功；JDK 仅检查可用性不执行启动。
4. deploy-start-all.ps1/.sh 按 gateway → auth → biz → system 顺序一键启动 4 个后端服务，启动前校验 jar 包与关键环境变量，每服务启动后健康确认，任一步骤失败时停止并给出明确错误提示。
5. 单服务启动脚本（deploy-start-gateway/auth/biz/system）各自独立可用，行为与一键启动对应服务一致。
6. deploy-rsa-keygen.sh 与 .ps1 输出契约一致（DER 编码单行 Base64，公钥 X.509 / 私钥 PKCS#8），与 Java 端解码契约一致；弃用脚本（deploy-env.ps1 / deploy-env-template.ps1）已移除或明确弃用。
7. 脚本输出统一分级（通过/警告/失败）与退出码约定（失败非零）；.ps1 与 .sh 双平台行为一致，通过语法与契约自校验。
8. .gitignore 已补充生成、测试、调试过程中的临时/中间文件排除规则（JVM 调试产物、测试缓存、构建中间产物、工具残留等），git status 不再出现此类文件，且不误伤 env.example.json、.gitkeep、源码与文档等应入库文件。

## 4. 验证范围：deploy/scripts 脚本清单（TASK-001~009 产出，当前实况）

deploy/scripts 目录当前共 24 个脚本（12 对 .ps1/.sh）+ .gitkeep，无弃用残留（TASK-008 已完成清理）：

| # | 脚本对 | 能力归属 | 上游任务 |
| --- | --- | --- | --- |
| 1 | load-env.ps1 / load-env.sh | 统一配置加载模块（F-001） | TASK-002 |
| 2 | deploy-check-env.ps1 / deploy-check-env.sh | 环境可用性检查 + 运行状态检测（F-002~F-006、F-010） | TASK-003 |
| 3 | deploy-start-services.ps1 / deploy-start-services.sh | 基础设施运行状态检查与一键启动（F-006、F-007） | TASK-004 |
| 4 | deploy-start-all.ps1 / deploy-start-all.sh | 后端服务按序一键启动（F-008） | TASK-005 |
| 5 | deploy-start-gateway.ps1 / .sh | 单服务启动（F-009） | TASK-006 |
| 6 | deploy-start-auth.ps1 / .sh | 单服务启动（F-009） | TASK-006 |
| 7 | deploy-start-biz.ps1 / .sh | 单服务启动（F-009） | TASK-006 |
| 8 | deploy-start-system.ps1 / .sh | 单服务启动（F-009） | TASK-006 |
| 9 | deploy-rsa-keygen.ps1 / deploy-rsa-keygen.sh | RSA 密钥生成（F-011、ADR-015） | TASK-007 |
| 10 | deploy-db-init.ps1 / deploy-db-init.sh | 数据库初始化（历史资产，参与语法/契约校验） | 历史 |
| 11 | build-backend.ps1 / build-backend.sh | 后端构建（历史资产，参与语法/契约校验） | 历史 |
| 12 | build-client.ps1 / build-client.sh | 客户端构建（历史资产，参与语法/契约校验） | 历史 |

注：TASK-010 校验范围为 deploy/scripts 全部 .ps1/.sh 脚本（含历史保留的 deploy-db-init、build-backend、build-client）；v0.2.7 能力矩阵核心为 1~9 号脚本对。

## 5. 契约约定（验证核对基准）

### 5.1 RSA 密钥契约（ADR-015，v0.2.6 确立，v0.2.7 不得破坏）
- deploy-rsa-keygen.ps1/.sh 均输出 **DER 编码单行 Base64**：公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo；
- 无 PEM 头尾（BEGIN/END 标记）、无换行；
- 与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约严格一致；
- 契约自校验点：输出不含 "-----BEGIN"、不含换行、可被严格 Base64 解码、公钥私钥成对。

### 5.2 输出分级与退出码约定（F-011 / R-02 / R-03 / LLD 6.7）
- 输出分级：`[通过]`（绿）/`[警告]`（黄）/`[失败]`（红，含处理建议）三级前缀；汇总行：通过 N 项 / 警告 M 项 / 失败 K 项；
- 退出码约定：全部通过退出 0；存在失败项退出非零（1）；关键步骤失败（env.json 缺失、前置校验不通过、启动失败即停）退出 1；存在警告但无失败按约定退出 0 并提示警告；
- 颜色输出在非交互终端自动降级为纯文本。

### 5.3 配置驱动约束（R-01 / ADR-016）
- 全部脚本统一经 load-env 从 deploy/env.json 加载配置（NACOS_ADDR/NACOS_HOME/DB_*/REDIS_*/RSA_* 等）；
- 脚本内不得硬编码环境地址（如 192.168.1.100/101/102）与凭据；
- 口令掩码：DB_PASSWORD/REDIS_PASSWORD 不得明文打印，命令中口令以掩码（`****`）显示。

### 5.4 双平台对齐与文件头（R-04 / R-16）
- .ps1 与 .sh 同名脚本行为一致，可通过语法校验与契约自校验；
- 脚本文件头保留 SPDX-License-Identifier（Apache-2.0）与版权声明，简体中文注释。

### 5.5 部署顺序（R-07）
- 基础设施：MariaDB → Redis → Nacos；
- 后端服务：gateway（9000）→ auth（9100）→ biz（9200）→ system（9400）。

## 6. 关联设计文档要点

### 6.1 SAD 脚本体系约束（v0.2.7 起）
- 全部部署脚本统一通过 load-env.ps1/load-env.sh 从 deploy/env.json 加载配置，脚本内不得硬编码环境地址与凭据；
- 能力划分：可用性检查（deploy-check-env）→ 基础设施一键启动（deploy-start-services）→ 后端服务按序一键启动（deploy-start-all）→ 单服务启动（deploy-start-{svc}）；
- .ps1 与 .sh 双平台行为一致；输出分级（通过/警告/失败）与退出码约定（失败非零）统一；RSA 密钥格式契约（ADR-015）在脚本重构中不得破坏。

### 6.2 ADR-016（v0.2.7 决策）
部署脚本体系重构与配置驱动：以 deploy/env.json 为唯一配置源、四类能力划分、双平台对齐、删除弃用脚本残留、密钥输出契约对齐（不破坏 ADR-015）、同时治理 .gitignore 排除临时/中间文件。仅涉及部署运维层，不改变后端架构、接口契约与数据库设计。

### 6.3 LLD 关键业务规则（R-01~R-16 核心摘录）
- R-05 RSA 密钥契约 = ADR-015（DER 单行 Base64）；R-06 口令掩码；R-08 结果可确认（不报假成功）；R-09 失败即停（start-all）；R-10 幂等启动（已运行跳过）；R-11 JDK 无启动概念；R-12 未安装不可启动；R-13 弃用脚本清理；R-14 前置检查对齐（移除 Maven/Git 版本等无关检查项）；R-15 仓库治理不误伤。

### 6.4 环境信息（project.md / SAD）
- 项目：云漫智企（CloudStrollOffice），缩写 cso，v0.2.7；
- 技术栈：Java 21 + Spring Boot 3.2.5 + Spring Cloud 2023.0.1（gateway 9000 / auth 9100 / biz 9200 / system 9400）+ Nacos 2.3（8848）+ MariaDB 10.6（3306）+ Redis 7.2（6379）；
- 部署资产唯一落点：根目录 deploy（jar 包、env.json/env.example.json、deploy/scripts）；
- 环境配置唯一源：deploy/env.json（模板 env.example.json）。

## 7. 验证执行要点（供 TASK-010 编码/验证阶段使用）

1. **语法校验**：全部 12 对脚本 —— .ps1 用 PowerShell 语法解析（`[System.Management.Automation.Language.Parser]::ParseFile` 或 PSParser）校验；.sh 用 `bash -n` 校验（Windows 无 bash 时可用 git-bash/wsl 或静态核对，需记录校验环境）；
2. **契约自校验**：deploy-rsa-keygen 输出（DER 单行 Base64：无 BEGIN/END、无换行、严格 Base64 可解码、公私钥配对）；输出分级前缀 [通过]/[警告]/[失败] 与汇总行存在；退出码约定（失败非零）静态核对；
3. **硬编码检查**：grep 全脚本确认无 192.168.1.100 等硬编码地址；无 DB_PASSWORD/REDIS_PASSWORD/RSA_PRIVATE_KEY 明文输出路径；
4. **load-env 依赖检查**：全部业务脚本均引用 load-env（.ps1 点源 / .sh source 或执行加载）后才使用配置；
5. **弃用残留检查**：deploy-env.ps1 / deploy-env-template.ps1 / deploy-env.sh 等无残留，无引用；
6. **文件头检查**：SPDX-License-Identifier（Apache-2.0）与版权声明保留；
7. **输出验证报告**：对照 PRD 第 7 章 8 条验收标准逐条核对，输出验证报告（建议写入 docs/cso-v0.2.7/task_TASK-010/ 或版本目录，按 coding 阶段约定位置输出）。

## 8. 数据来源

- PRD：docs/cso-v0.2.7/cso-prd-v0.2.7.md（US-004、F-011、第 7 章验收标准）
- SAD：docs/sad.md（ADR-014/015/016、脚本体系约束、部署架构）
- LLD：docs/cso-v0.2.7/cso-lld-v0.2.7.md（业务规则 R-01~R-16、6.7 输出分级与退出码、13. 单元测试策略）
- 任务清单：docs/cso-v0.2.7/cso-task-v0.2.7.json（TASK-001~010）
- 项目信息：docs/project.md（项目基本信息、编码规范）
- 脚本实况：deploy/scripts/（glob 扫描 2026-08-10）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
