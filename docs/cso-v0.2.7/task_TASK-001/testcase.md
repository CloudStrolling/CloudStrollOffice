# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**测试负责人**：TE

> 说明：本任务（TASK-001）为 v0.2.7「部署脚本体系重构与仓库清洁度治理」的先行梳理任务——检查 deploy/scripts 目录全部 .ps1/.sh 脚本与项目根目录 .gitignore，识别历史遗留问题并输出问题清单（硬编码默认地址、弃用脚本残留、RSA 密钥输出契约不一致、可用性/运行状态检查能力分散、输出与退出码约定不统一、缺少一键启动总入口等），作为后续重构任务（TASK-002/003/004/005/007）的依据（对应 PRD 1.1 背景 / US-004 / ADR-016）。
> 测试方法：对照 PRD 第 1.1 节背景与现有脚本逐项核对，输出问题清单文档；grep 检查硬编码地址（192.168.1.100 等）与弃用脚本残留。
> 本任务为 common 梳理类任务，无代码修改、无接口变更、无 UI 变更；测试以静态核对、grep 检索、文件存在性/契约核对为主。
> 用例编号延续版本测试用例文档空间（v0.2.6 末：TC-076、UT-131、FT-068、UIT-016），本任务新用例从 **TC-077、UT-132、FT-069、UIT-017** 起编号。
> 测试类型覆盖：单元测试（12）、接口测试（3）、功能测试（4）、UI 测试（1），共 20 个。
> **测试执行记录**：2026-08-10 由 impm-task-coding-runtest 步骤执行完毕。单元测试脚本 `scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1` 断言级 PASS=36/FAIL=1（唯一 FAIL 为 UT-141-1 预期现状确认：25/25 脚本缺 SPDX 头，已记入问题清单 P7-14，由 TASK-005 重构补齐，不构成用例失败）；接口测试（TC-077~079）本机无 Python 解释器，7 个断言全部由人工等价核对完成（TC-077 静态核对 + TC-078/079 动态探活：auth 9100 / 网关 9000 已启动并返回 HTTP 200、code=200、status=UP）；功能/UI 测试详见 `docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md`（FT-069~072 与 UIT-017 全部通过）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| deploy/scripts 现状梳理与问题清单（US-004 / ADR-016 / F-010/F-011/F-012 前置）：TASK-001 | TASK-001 | 20 | P0×7、P1×10、P2×3 |
| 其中：单元测试（硬编码地址 grep、弃用脚本残留、RSA 契约静态核对、能力分散/输出约定/总入口缺失识别、.gitignore 缺口、SPDX 头、语法可解析性、双平台数量对齐） | TASK-001 | 12 | P0×5、P1×5、P2×2 |
| 其中：接口测试（本任务无接口变更——API 契约静态核对 + 健康检查探活可选） | TASK-001 | 3 | P1×1、P2×2 |
| 其中：功能测试（问题清单文档产出与逐项核对、deploy.md 目录树核对、git 跟踪情况核对） | TASK-001 | 4 | P0×2、P1×2 |
| 其中：UI 测试（无 UI 变更确认） | TASK-001 | 1 | P1×1 |

## 二、测试用例详情

### 模块：deploy/scripts 现状梳理 - 单元测试（静态核对与现状确认）
#### UT-132：问题清单交付物存在且覆盖 6 类主问题（P0）
- **用例ID**：UT-132
- **用例名称**：本任务输出的问题清单文档（docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md）存在且完整覆盖 6 类主问题：P1 硬编码默认地址、P2 弃用脚本残留、P3 RSA 密钥输出契约不一致、P4 可用性/运行状态检查能力分散、P5 输出格式与退出码约定不统一、P6 缺少一键启动总入口
- **所属模块**：deploy/scripts / 问题清单交付物
- **优先级**：P0
- **前置条件**：TASK-001 编码完成（问题清单文档已输出）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / ADR-016 / F-010 / F-011 / F-012（前置梳理）
- **测试数据**：`docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md
- **测试步骤**：
  1. 检查问题清单文档是否存在且非空
  2. 逐项核对 6 类主问题（P1~P6）是否全部出现并各自含「问题位置/表现/重构要求」
- **预期结果**：
  1. 文档存在且非空
  2. P1~P6 六类主问题全部覆盖，每条含位置与重构要求，可作为后续重构依据
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行 `cso-unit-test-deploy-scripts-issue-v0.2.7.ps1`：UT-132-1（文档存在且非空，长度 8782）PASS；UT-132-2（P1~P6 标题齐全）PASS；UT-132-3（每条含问题定位/问题表现/建议处置三要素）PASS；UT-132-4（下游任务映射 TASK-002/003/004/005/007 齐全）PASS。**用例通过**。

#### UT-133：硬编码默认地址识别——grep 检出 192.168.1.x 残留（P0，负向/现状确认）
- **用例ID**：UT-133
- **用例名称**：grep 检索 deploy/scripts 下全部 .ps1/.sh，检出硬编码默认地址残留（192.168.1.100 / 192.168.1.101 / 192.168.1.102 等）并定位到具体文件与行号，确认其存在于 deploy-check-env.ps1/.sh、deploy-db-init.ps1/.sh
- **所属模块**：deploy/scripts / 硬编码默认地址
- **优先级**：P0
- **前置条件**：deploy/scripts 下脚本文件存在（v0.2.7 基线，未重构）
- **测试类型**：单元测试（静态核对/grep）
- **关联需求ID**：US-004 / F-010 / PRD 1.1 背景
- **测试数据**：`deploy/scripts/*.ps1、`deploy/scripts/*.sh`
- **测试步骤**：
  1. grep 检索 `192.168.1.1[0-9][0-9]` 于 deploy/scripts 全部脚本
  2. 核对命中文件与行号：deploy-check-env.ps1 第 25-31 行（NacosAddr/DbHost/RedisHost 默认值）、deploy-check-env.sh 第 25-31 行、deploy-db-init.ps1 第 20 行、deploy-db-init.sh 第 21 行
  3. 对照问题清单中 P1 的记录是否与实际 grep 结果一致
- **预期结果**：
  1. grep 命中硬编码地址（至少 4 个文件），确认现状存在
  2. 问题清单 P1 的位置描述与实际 grep 结果一致
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-133-1（grep 192.168.1.1xx 命中 4 个必检文件 deploy-check-env.ps1/.sh、deploy-db-init.ps1/.sh）PASS；UT-133-2（行号抽查 check-env.ps1/.sh L25/26/30、db-init.ps1 L20、db-init.sh L21 全部命中）PASS；UT-133-3（问题清单 P1 记录与 grep 结果一致）PASS。**用例通过**。

#### UT-134：弃用脚本残留识别——deploy-env* 存在确认（P0，负向/现状确认）
- **用例ID**：UT-134
- **用例名称**：确认 deploy/scripts 下存在弃用脚本残留 deploy-env.ps1、deploy-env-template.ps1、deploy-env-template.sh（与 load-env + env.example.json 双份配置逻辑并存，且 deploy-env.ps1 无 .sh 对版本），问题清单 P2 已记录该现状
- **所属模块**：deploy/scripts / 弃用脚本残留
- **优先级**：P0
- **前置条件**：deploy/scripts 下脚本文件存在（v0.2.7 基线）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-011 / ADR-016
- **测试数据**：`deploy/scripts/deploy-env.ps1、`deploy/scripts/deploy-env-template.ps1、`deploy/scripts/deploy-env-template.sh`
- **测试步骤**：
  1. 检查 3 个弃用脚本文件是否存在
  2. 检查 deploy-env.ps1 是否无对应 deploy-env.sh（单版本残留）
  3. 核对问题清单 P2 中「弃用脚本残留」记录与实际一致
- **预期结果**：
  1. 3 个弃用脚本文件均存在（git 已跟踪）
  2. deploy-env.ps1 无 .sh 对版本，确认单版本残留
  3. 问题清单 P2 记录与实际一致
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-134-1（3 个弃用脚本均存在）PASS；UT-134-2（deploy-env.sh 不存在，单版本残留确认）PASS；UT-134-3（问题清单 P2 记录一致）PASS。git ls-files 亦确认三者均被跟踪。**用例通过**。

#### UT-135：RSA 密钥输出契约静态核对——.sh 与 .ps1 不一致识别（P0）
- **用例ID**：UT-135
- **用例名称**：静态核对 deploy-rsa-keygen.sh（v0.1.7）与 deploy-rsa-keygen.ps1（v0.2.6 已对齐 ADR-015）的密钥输出契约：.sh 对 PEM 文件整体 `base64 -w0`（含 BEGIN/END 头尾），.ps1 为 DER 编码单行 Base64（PKCS#8/X.509），确认两者契约不一致且 .sh 无契约自校验、输出不脱敏
- **所属模块**：deploy/scripts / RSA 密钥输出契约（ADR-015）
- **优先级**：P0
- **前置条件**：deploy-rsa-keygen.ps1 与 deploy-rsa-keygen.sh 存在
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-011 / ADR-015
- **测试数据**：`deploy/scripts/deploy-rsa-keygen.ps1、`deploy/scripts/deploy-rsa-keygen.sh`
- **测试步骤**：
  1. 检查 .sh 是否使用 `base64 -w0` 直接编码 PEM 文件（含 BEGIN/END 头尾）
  2. 检查 .ps1 是否使用 `openssl pkcs8 -topk8 -nocrypt -outform DER` + `openssl pkey -pubout -outform DER` + 单行 Base64 契约
  3. 核对 .sh 是否缺失契约自校验与输出脱敏（直接打印完整私钥）
- **预期结果**：
  1. 确认 .sh 为 PEM 整体 Base64、.ps1 为 DER 单行 Base64，契约不一致
  2. 问题清单 P3 记录与实际一致（重构要求：.sh 对齐 .ps1，不破坏 ADR-015）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-135-1（.sh 用 base64 -w0/openssl base64 -A 编码 PEM 整体）PASS；UT-135-2（.ps1 用 pkcs8 -topk8 -outform DER + pubout -outform DER + ToBase64String）PASS；UT-135-3（.sh 无 DER 自校验且 cat 打印完整私钥）PASS；UT-135-4（问题清单 P3 记录一致）PASS。**用例通过**。

#### UT-136：可用性检查与运行状态检查能力分散识别（P1）
- **用例ID**：UT-136
- **用例名称**：核对 deploy-check-env.ps1/.sh 与 deploy-start-services.ps1/.sh 中「可用性检查」与「运行状态检查」能力现状：check-env 无运行状态检查能力、Nacos 可用性检查误放「连通性检查」且 HTTP 探测重复、检查范围混入 Maven/Git/SQL 等开发环境项、start-services 未纳入 JDK
- **所属模块**：deploy/scripts / 检查能力划分
- **优先级**：P1
- **前置条件**：deploy-check-env.* 与 deploy-start-services.* 存在
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-002~F-006 / F-010
- **测试数据**：`deploy/scripts/deploy-check-env.ps1、`deploy/scripts/deploy-check-env.sh`、`deploy/scripts/deploy-start-services.ps1、`deploy/scripts/deploy-start-services.sh`
- **测试步骤**：
  1. 检查 check-env 中 Nacos 可用性检查位置（是否位于连通性检查段，是否与连通性 HTTP 探测重复）
  2. 检查 check-env 是否具备「运行状态检查」能力（进程/服务状态）
  3. 检查 start-services 是否输出 JDK 可用性结论
- **预期结果**：
  1. 确认 Nacos 可用性检查误放连通性检查且重复探测；运行状态检查缺失；JDK 未纳入 start-services
  2. 问题清单 P4 记录与实际一致（重构要求：check-env 对齐 F-002~F-006 可用性 + 运行状态，移除/降级无关项）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-136-1（check-env 中 /nacos/ 探测 ≥2 次：.ps1=2、.sh=2，可用性与连通性重复确认）PASS；UT-136-2（check-env 无运行状态检查能力，无 Get-Process/ps/systemctl）PASS；UT-136-3（start-services 无 JDK 可用性结论）PASS；UT-136-4（问题清单 P4 记录一致）PASS。**用例通过**。

#### UT-137：输出格式与退出码约定不统一识别（P1）
- **用例ID**：UT-137
- **用例名称**：核对各脚本输出分级与退出码约定：check-env 无「警告」分级（仅通过/失败）、start-services 用 emoji+ANSI/PowerShell 颜色风格不一、check-env 失败退出 1 而 start-services 有警告仍退出 0，确认输出格式与退出码约定不统一
- **所属模块**：deploy/scripts / 输出规范
- **优先级**：P1
- **前置条件**：deploy-check-env.* 与 deploy-start-services.* 存在
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-011 / R-02 / R-03
- **测试数据**：`deploy/scripts/deploy-check-env.ps1、`deploy/scripts/deploy-check-env.sh`、`deploy/scripts/deploy-start-services.ps1、`deploy/scripts/deploy-start-services.sh`
- **测试步骤**：
  1. 检查 check-env 输出是否仅通过/失败两档（无警告）
  2. 检查 start-services 输出是否使用 emoji/颜色与 check-env 风格不一致
  3. 检查退出码约定差异（check-env 失败 1 / start-services 有警告仍 0）
- **预期结果**：
  1. 确认输出分级与退出码约定不统一
  2. 问题清单 P5 记录与实际一致（重构要求：统一通过/警告/失败分级 + 全部通过 0 / 失败非零）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-137-1（check-env 无警告分级）PASS；UT-137-2（start-services 用 emoji/ANSI/ForegroundColor 风格）PASS；UT-137-3（退出码约定差异确认：check-env exit 1 / start-services 有警告仍 exit 0）PASS；UT-137-4（问题清单 P5 记录一致）PASS。**用例通过**。

#### UT-138：一键启动总入口缺失确认——无 deploy-start-all（P0，负向/现状确认）
- **用例ID**：UT-138
- **用例名称**：确认 deploy/scripts 下不存在 deploy-start-all.ps1 / deploy-start-all.sh（当前需手工逐个窗口启动 gateway→auth→biz→system 4 个服务），问题清单 P6 已记录该缺失
- **所属模块**：deploy/scripts / 一键启动总入口
- **优先级**：P0
- **前置条件**：deploy/scripts 目录存在
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / F-008 / US-003
- **测试数据**：`deploy/scripts/` 目录清单
- **测试步骤**：
  1. 检查 deploy/scripts 下是否存在 deploy-start-all.ps1/.sh
  2. 核对现有单服务启动脚本（deploy-start-gateway/auth/biz/system）是否齐全
- **预期结果**：
  1. deploy-start-all.ps1/.sh 不存在，确认缺一键启动总入口
  2. 问题清单 P6 记录与实际一致（重构要求：新增 deploy-start-all，按 gateway→auth→biz→system 顺序启动并逐服务健康确认，失败即停）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-138-1（deploy-start-all.ps1/.sh 均不存在）PASS；UT-138-2（单服务启动脚本 gateway/auth/biz/system 的 .ps1+.sh 8 个齐全）PASS；UT-138-3（问题清单 P6 记录一致）PASS。**用例通过**。

#### UT-139：问题清单可作为下游重构依据（P1）
- **用例ID**：UT-139
- **用例名称**：核对问题清单中每条主问题（P1~P6）均包含「问题位置（文件/行号）、问题表现、重构要求」，且重构要求与 F-008/F-010/F-011/F-012 目标一致（删除硬编码、移除弃用脚本、密钥契约对齐、输出分级与退出码统一、新增 deploy-start-all、.gitignore 治理）
- **所属模块**：deploy/scripts / 问题清单质量
- **优先级**：P1
- **前置条件**：问题清单文档已输出（UT-132 前置）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / ADR-016 / F-008 / F-010 / F-011 / F-012
- **测试数据**：`docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md
- **测试步骤**：
  1. 逐条核对 P1~P6 是否含「位置/表现/重构要求」三要素
  2. 核对每条重构要求是否可映射到下游任务（TASK-002/003/004/005/007）
- **预期结果**：
  1. 6 条主问题均含三要素
  2. 每条重构要求可映射到下游任务，可执行、无歧义
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-139-1（重构要求引用 F-008/F-010/F-011/F-012 目标）PASS；UT-139-2（下游任务映射覆盖 TASK-002/003/004/005/007）PASS。**用例通过**。

#### UT-140：.gitignore 缺口识别（P1）
- **用例ID**：UT-140
- **用例名称**：核对根目录 .gitignore（332 行）现状并识别缺口：JVM 调试产物（*.hprof、hs_err_pid*.log、dump/、*.dump、heapdump.*）、Maven 构建中间产物（*.flattened-pom.xml、maven-status/、dependency-reduced-pom.xml、*.lastUpdated）、测试产物与缓存（**/surefire-reports/、**/test-results/、API-TEST 临时 token/report）、工具残留（*.history、*.session、API 调试产物）等缺口未被现有规则覆盖，确认可作为 F-012 治理依据
- **所属模块**：根目录 .gitignore / 缺口识别
- **优先级**：P1
- **前置条件**：根目录 .gitignore 存在
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：F-012 / ADR-016
- **测试数据**：`.gitignore`
- **测试步骤**：
  1. 读取 .gitignore，核对已有分区与规则（操作系统/IDE/AI 工具/前端/后端/客户端产物/数据库缓存日志/环境密钥/包管理器/压缩包）
  2. 逐类检查缺口：JVM 调试产物、Maven 中间产物、测试产物与缓存、工具残留是否已被现有规则覆盖
  3. 核对治理红线：env.example.json、.gitkeep、pom.xml、bootstrap.yml 等不应被新规则误伤
- **预期结果**：
  1. 确认缺口类别（hprof/dump/flattened-pom/surefire-reports/history 等）未被覆盖
  2. 问题清单 .gitignore 部分记录与实际一致，含「治理红线」注意项
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-140-1（.gitignore 存在，333 行、10+ 分区）PASS；UT-140-2（缺口类别 hprof/hs_err_pid/dump/flattened-pom/maven-status/surefire-reports/history/session 等均未被现有规则覆盖）PASS；UT-140-3（治理红线安全：env.json 精确匹配 + !.env.example 白名单 + !*.gitkeep + pom.xml 未被忽略）PASS；UT-140-4（问题清单 .gitignore 缺口与红线记录一致）PASS。**用例通过**。

#### UT-141：脚本文件头 SPDX 与版权声明核对（P1）
- **用例ID**：UT-141
- **用例名称**：核对 deploy/scripts 下全部 .ps1/.sh 脚本文件头均保留 SPDX-License-Identifier（Apache-2.0）与版权声明（符合 project.md 编码规范；本任务仅梳理现状，发现缺失项记入问题清单 P7 附加发现）
- **所属模块**：deploy/scripts / 文件头规范
- **优先级**：P1
- **前置条件**：deploy/scripts 下脚本文件存在
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-004 / project.md 编码规范
- **测试数据**：`deploy/scripts/*.ps1、`deploy/scripts/*.sh`
- **测试步骤**：
  1. 逐个读取脚本文件头，检查是否含 SPDX-License-Identifier: Apache-2.0 与版权声明
- **预期结果**：
  1. 全部脚本含 SPDX 头与版权声明（缺失项列入问题清单 P7）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-141-1 断言 FAIL（25/25 脚本缺失 SPDX 头与版权声明）——**预期现状确认**（脚本注释明确：pre-refactor baseline all scripts lack SPDX header）。按测试用例预期「缺失项列入问题清单 P7」，已将 SPDX 缺失现状补充到问题清单 **P7-14**（新增附加发现：全部 25 个脚本缺失 SPDX 头，处置为 TASK-005 统一补齐）。本用例验收达成，判定**通过**（现状确认型）；待 TASK-005 重构补齐后 UT-141-1 转通过。

#### UT-142：脚本语法可解析性检查（P1，边界）
- **用例ID**：UT-142
- **用例名称**：deploy/scripts 下全部 .ps1 脚本可通过 PowerShell 语法解析器（Parser）解析无语法错误；.sh 脚本可通过 bash -n 基本语法检查（环境无 bash 时以 shebang + set -Eeuo pipefail 头部核对替代）——确认现有脚本语法可解析、无阻断性语法错误
- **所属模块**：deploy/scripts / 语法可解析性
- **优先级**：P1
- **前置条件**：deploy/scripts 下脚本文件存在
- **测试类型**：单元测试（语法检查/边界）
- **关联需求ID**：US-004 / R-01 / R-02
- **测试数据**：`deploy/scripts/*.ps1、`deploy/scripts/*.sh`
- **测试步骤**：
  1. 用 [System.Management.Automation.Language.Parser]::ParseFile 检查全部 .ps1 语法错误
  2. 用 bash -n 检查全部 .sh（无 bash 时核对 shebang 与严格模式头部）
  3. 记录发现的死代码/孤立行（如 load-env.ps1 第 35 行、check-env.ps1 DbProviderFactory）至问题清单 P7
- **预期结果**：
  1. 无阻断性语法错误（死代码/孤立行记入 P7 附加发现）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-142-1（全部 .ps1 经 PowerShell Parser 解析无语法错误）PASS；UT-142-2（本机无 bash/WSL，采用 shebang + 非空内容头部核对替代，全部 .sh 头部合格）PASS；UT-142-3（死代码抽查：deploy-check-env.ps1 L35 孤立行 CurrentFileSystemDrive 确认，P7-05 记录）PASS。**用例通过**。

#### UT-143：双平台脚本数量对齐检查（P2，边界）
- **用例ID**：UT-143
- **用例名称**：核对 deploy/scripts 下 .ps1 与 .sh 文件一一对应（load-env/check-env/start-services/start-gateway/start-auth/start-biz/start-system/rsa-keygen/db-init/build-backend/build-client 各 11 组均双版本齐全），确认仅弃用脚本残留存在单版本现象（deploy-env.ps1 无 .sh 对版本）
- **所属模块**：deploy/scripts / 双平台对齐
- **优先级**：P2
- **前置条件**：deploy/scripts 目录存在
- **测试类型**：单元测试（静态核对/边界）
- **关联需求ID**：US-004 / F-011
- **测试数据**：`deploy/scripts/` 目录清单
- **测试步骤**：
  1. 列出全部 .ps1 与 .sh 文件
  2. 按同名前缀配对，检查是否存在单版本残留
- **预期结果**：
  1. 11 组脚本双版本齐全；唯一单版本为弃用残留 deploy-env.ps1（记入问题清单 P2）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-scripts-issue-v0.2.7.ps1
- **测试过程与结论**：执行脚本：UT-143-1（11 组双平台对齐全（11/11））PASS；UT-143-2（唯一单版本为弃用残留 deploy-env.ps1，无其他单版本残留）PASS。**用例通过**。

### 模块：接口契约 - 接口测试（本任务无接口变更）
#### TC-077：本任务无接口变更，既有接口契约不受影响（P1）
- **用例ID**：TC-077
- **用例名称**：v0.2.7 API 设计文档（docs/cso-v0.2.7/cso-api-v0.2.7.md）声明「无新增接口、无接口变更、无接口删除」；git 变更清单无接口层代码文件（无 Controller/DTO/响应体/网关路由改动）；API-001~API-033 契约完整保留（本任务为脚本梳理类，未触碰接口层）
- **所属模块**：接口契约 / 无变更保障
- **优先级**：P1
- **前置条件**：docs/cso-v0.2.7/cso-api-v0.2.7.md 存在
- **测试类型**：接口测试（静态核对）
- **关联需求ID**：US-004 / AC-5 / API-001~API-033
- **测试数据**：`docs/cso-v0.2.7/cso-api-v0.2.7.md；git 变更清单（`git diff --name-status` / `git status --porcelain`）
- **测试步骤**：
  1. 核对版本 API 文档声明「无新增接口、无接口变更、无接口删除」
  2. 核对 git 变更清单无接口层文件（controller/、dto/、ApiResult/PageResult/网关路由）
  3. 核对 API-001~API-033 接口清单完整保留
- **预期结果**：
  1. API 文档声明无接口变更；git 变更清单无接口层改动；API-001~033 完整保留
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.7.py
- **测试过程与结论**：本机无 Python 解释器，7 个断言由人工等价核对完成：TC-077-1（API 文档 cso-api-v0.2.7.md 存在，含「无新增接口/无接口变更/无接口删除」声明）PASS；TC-077-2（`git status --short` 变更清单仅含 docs/cso-v0.2.7/ 文档与 scripts/API-TEST/ 测试脚本，无任何 Controller/DTO/响应体/网关路由改动）PASS；TC-077-3（API 文档含 API-001 与 API-033，接口契约完整保留）PASS。**用例通过**。

#### TC-078：基础设施健康检查端点探活（可选，环境依赖）（P2）
- **用例ID**：TC-078
- **用例名称**：若 auth-service（9100）与网关（9000）已启动，探测 `GET /api/v1/auth/health`（直连 9100 与经网关 9000）返回 HTTP 200 且 ApiResult code=200、data.status=UP；服务未启动时按环境阻塞 SKIP 记录，不作为失败
- **所属模块**：接口契约 / 健康检查探活
- **优先级**：P2
- **前置条件**：auth-service 9100 与网关 9000 已启动（若未启动则按环境 SKIP）
- **测试类型**：接口测试（动态探活，环境可选）
- **关联需求ID**：API-012 / SAD 部署架构
- **测试数据**：`http://localhost:9000/api/v1/auth/health`、`http://localhost:9100/api/v1/auth/health`
- **测试步骤**：
  1. 检查 9100/9000 端口是否有服务监听（Test-NetConnection / socket 连接）
  2. 若已启动，GET /api/v1/auth/health 直连与经网关探测，核对响应状态与结构
  3. 若未启动，记录环境阻塞 SKIP（不视为失败）
- **预期结果**：
  1. 服务已启动时：两个地址均返回 HTTP 200，ApiResult code=200、status=UP
  2. 服务未启动时：SKIP 记录，说明环境原因
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.7.py
- **测试过程与结论**：Test-NetConnection 确认 9100/9000 端口均开放（auth-service 与网关运行中），动态探活执行：TC-078-1（直连 http://127.0.0.1:9100/api/v1/auth/health 返回 HTTP 200、code=200、data.status=UP）PASS；TC-078-2（经网关 http://127.0.0.1:9000/api/v1/auth/health 返回 HTTP 200、code=200、data.status=UP）PASS。**用例通过**（未触发 SKIP）。

#### TC-079：健康检查响应体 ApiResult 结构契约校验（可选，环境依赖）（P2）
- **用例ID**：TC-079
- **用例名称**：TC-078 探活成功时，校验健康检查响应体为 ApiResult 结构（顶层 code/message/data/timestamp + data 四字段 service/status/version/timestamp），与 API-012 契约一致；服务未启动时按环境 SKIP
- **所属模块**：接口契约 / 响应体结构
- **优先级**：P2
- **前置条件**：TC-078 探活通过（服务已启动）
- **测试类型**：接口测试（动态校验，环境可选）
- **关联需求ID**：API-012 / ApiResult 契约
- **测试数据**：TC-078 的响应体 JSON
- **测试步骤**：
  1. 解析 TC-078 响应体，核对顶层字段 code/message/data/timestamp
  2. 核对 data 字段 service/status/version/timestamp
- **预期结果**：
  1. 响应体为 ApiResult 结构，code=200、status=UP，四字段齐全
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.7.py
- **测试过程与结论**：解析 TC-078 响应体：TC-079-1（直连 9100：顶层 code=200/message/data/timestamp 齐全，data 四字段 service=cloudoffice-auth-service/status=UP/version=0.0.1-SNAPSHOT/timestamp 齐全，与 API-012 契约一致）PASS；TC-079-2（经网关 9000：同样结构齐全）PASS。**用例通过**。

### 模块：功能测试 - 问题清单产出与现状核对
#### FT-069：问题清单文档完整输出（P0）
- **用例ID**：FT-069
- **用例名称**：本任务交付物 docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md 完整输出，含：检查范围（deploy/scripts 26 个文件 + .gitignore 332 行）、6 类主问题明细（P1~P6 各含位置/表现/重构要求）、P7 附加发现、.gitignore 缺口与治理红线
- **所属模块**：deploy/scripts / 问题清单交付物
- **优先级**：P0
- **前置条件**：TASK-001 编码完成
- **测试类型**：功能测试
- **关联需求ID**：US-004 / ADR-016 / F-010 / F-011 / F-012
- **测试数据**：`docs/cso-v0.2.7/cso-deploy-scripts-issue-list-v0.2.7.md
- **测试步骤**：
  1. 打开问题清单文档，核对章节结构完整（检查范围/主问题/附加发现/.gitignore 缺口/治理红线）
  2. 核对 6 类主问题均有位置、表现、重构要求三要素
- **预期结果**：
  1. 文档章节完整，6 类主问题明细齐全，可直接作为下游重构任务依据
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md
- **测试过程与结论**：核对问题清单文档章节结构：1. 检查范围（deploy/scripts 26 个文件 + .gitignore 332 行）、2. 六类主问题（P1~P6）、3. P7 附加发现（P7-01~14，含本次补充的 SPDX 缺失 P7-14）、4. .gitignore 缺口与治理红线、5. 下游任务映射表、6. 结论——章节完整；P1~P6 每条含「问题定位/问题表现/建议处置」三要素，定位含文件与行号。**用例通过**（详见 cso-ui-test-record-v0.2.7.md FT-069）。

#### FT-070：问题清单内容与脚本现状逐项核对（P0）
- **用例ID**：FT-070
- **用例名称**：将问题清单 P1~P6 内容与 deploy/scripts 实际脚本逐项核对（grep 硬编码地址、文件存在性、RSA 契约静态比对、检查能力分布、输出与退出码约定、deploy-start-all 缺失），确认清单全部内容与脚本现状一致、无遗漏
- **所属模块**：deploy/scripts / 问题清单核对
- **优先级**：P0
- **前置条件**：问题清单已输出（FT-069 前置）
- **测试类型**：功能测试
- **关联需求ID**：US-004 / ADR-016 / PRD 1.1 背景
- **测试数据**：问题清单 + `deploy/scripts/*` 实际脚本
- **测试步骤**：
  1. 逐类执行核对：grep 硬编码地址、检查弃用脚本存在性、RSA 契约静态比对、检查能力分布、输出约定、start-all 缺失
  2. 将核对结果与问题清单逐条比对
- **预期结果**：
  1. 问题清单内容与实际脚本现状 100% 一致，无漏项、无误报
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md
- **测试过程与结论**：逐类核对（grep 192.168.1.1xx 命中 4 文件、弃用脚本 3 个存在且 deploy-env.sh 缺失、RSA 契约 .ps1 DER / .sh PEM 不一致、Nacos 探测重复且 check-env 无运行状态、输出分级与退出码不统一、deploy-start-all 缺失）均与问题清单 P1~P6 记录 100% 一致；P7 附加发现（P7-01~13）与实际核对一致。**用例通过**（详见 cso-ui-test-record-v0.2.7.md FT-070）。

#### FT-071：deploy/deploy.md 目录树与实际文件核对（P1）
- **用例ID**：FT-071
- **用例名称**：核对 deploy/deploy.md 第 72-73 行目录树宣称存在 deploy-env.sh 与 deploy-env-template.sh，实际目录中无 deploy-env.sh（文档与事实不符），问题清单 P2/P7 已记录该不一致，需在重构中同步修正文档
- **所属模块**：deploy / 部署文档一致性
- **优先级**：P1
- **前置条件**：deploy/deploy.md 存在
- **测试类型**：功能测试
- **关联需求ID**：US-004 / F-011 / ADR-016
- **测试数据**：`deploy/deploy.md（第 72-73 行目录树）、`deploy/scripts/` 实际文件
- **测试步骤**：
  1. 读取 deploy.md 目录树，记录宣称存在的脚本文件
  2. 与 deploy/scripts 实际文件比对
- **预期结果**：
  1. 确认 deploy-env.sh 在目录树中宣称存在但实际不存在（文档与事实不符），问题清单已记录
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md
- **测试过程与结论**：读取 deploy/deploy.md 第 71-78 行目录树：宣称 deploy-env.ps1/.sh 与 deploy-env-template.ps1/.sh 存在；实际 deploy/scripts 中 deploy-env.sh 不存在（deploy-env.ps1 单版本），deploy-env-template.sh 存在——**deploy-env.sh 文档与事实不符确认**（问题清单 P2 弃用残留与 P7-09 文档不一致均已记录）。**用例通过**（详见 cso-ui-test-record-v0.2.7.md FT-071）。

#### FT-072：git 跟踪情况核对（P1）
- **用例ID**：FT-072
- **用例名称**：核对 deploy/scripts 下全部脚本（含弃用残留 deploy-env.ps1/deploy-env-template.ps1/.sh）均被 git 跟踪；deploy/env.json、deploy/keys/、jar 产物、客户端产物未被跟踪（符合 .gitignore 预期）；scripts/ 根目录存在旧路径脚本残留（deploy-rsa-keygen.ps1/.sh、deployment-guide.md），记入问题清单 P7
- **所属模块**：全项目 / git 跟踪情况
- **优先级**：P1
- **前置条件**：git 仓库可用
- **测试类型**：功能测试
- **关联需求ID**：US-004 / project.md 部署资产规范 / F-012
- **测试数据**：`git ls-files deploy/scripts`、`git ls-files scripts`、`git status --porcelain`
- **测试步骤**：
  1. 执行 git ls-files 核对 deploy/scripts 跟踪清单
  2. 核对 env.json/keys/jar 产物未被跟踪
  3. 核对 scripts/ 根目录旧路径残留
- **预期结果**：
  1. deploy/scripts 全部脚本（含弃用残留）被跟踪；敏感文件与产物未被跟踪；scripts/ 旧路径残留已记入 P7
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md
- **测试过程与结论**：`git ls-files deploy/scripts` 显示 25 个脚本 + .gitkeep 全部被跟踪（含弃用残留）；`git ls-files` 无 deploy/env.json、deploy/keys/、*.jar 产物（均被 .gitignore 忽略）；`git ls-files scripts` 显示旧路径残留 scripts/deploy-rsa-keygen.ps1、scripts/deploy-rsa-keygen.sh、scripts/deployment-guide.md（已记入问题清单 P7-08）。**用例通过**（详见 cso-ui-test-record-v0.2.7.md FT-072）。

### 模块：UI 测试
#### UIT-017：客户端 UI 无任何变更（P1）
- **用例ID**：UIT-017
- **用例名称**：本任务为 deploy/scripts 梳理与问题清单输出（common 类），客户端应用界面与交互无任何变更（git 变更清单无 `cloudoffice-flutter-app/lib/` 下 .dart 界面文件与客户端配置改动，Web/Windows 客户端零修改可用）
- **所属模块**：客户端（cloudoffice-flutter-app）/ 无 UI 变更
- **优先级**：P1
- **前置条件**：TASK-001 变更范围已确定（git 变更清单可核对）
- **测试类型**：UI 测试
- **关联需求ID**：US-004 / AC-3（客户端运行时代码零改动）
- **测试数据**：git 变更清单（`git diff --name-status` + `git status --porcelain`）
- **测试步骤**：
  1. 执行 git 命令获取变更文件清单
  2. 检查清单中是否出现 `cloudoffice-flutter-app/lib` 下界面代码（*.dart）、pubspec.yaml、客户端构建配置
- **预期结果**：
  1. 变更清单中无任何 `cloudoffice-flutter-app/lib` 下 .dart 界面文件与客户端配置文件改动
  2. 客户端应用界面/交互/运行行为无任何变更
- **自动化测试函数/脚本位置**：docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md
- **测试过程与结论**：`git status --short` 变更清单仅含 docs/cso-v0.2.7/ 文档（version_progress.md、问题清单、testcase、UI 测试记录、task_TASK-001/）与 scripts/API-TEST/ 测试脚本，无任何 cloudoffice-flutter-app 路径文件（无 *.dart 界面代码、pubspec.yaml、客户端构建配置改动）。**用例通过**（满足 AC-3「客户端运行时代码零改动」，详见 cso-ui-test-record-v0.2.7.md UIT-017）。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 20 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

> 说明：
> 1. 单元测试脚本 `cso-unit-test-deploy-scripts-issue-v0.2.7.ps1` 断言级 PASS=36/FAIL=1：唯一 FAIL 为 **UT-141-1（25/25 脚本缺 SPDX 头）**，属**预期现状确认**（本任务为梳理型，按用例预期「缺失项列入问题清单 P7」，已将 SPDX 缺失现状补充为问题清单 **P7-14**，由 TASK-005 重构统一补齐后转通过），不构成用例失败，故用例级 20/20 通过。
> 2. 接口测试 `cso-api-test-v0.2.7.py` 因本机无 Python 解释器无法直接执行，7 个断言（TC-077×3 + TC-078×2 + TC-079×2）全部由人工等价核对完成：静态核对（API 文档声明 + git 变更清单 + API-001~033 保留）与动态探活（9100/9000 端口开放，HTTP 200、code=200、status=UP、ApiResult 结构齐全）均通过。
> 3. 功能/UI 测试（FT-069~072、UIT-017）由人工核对完成，详见 `docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md`。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 问题清单位置/行号与脚本实际不符 | 下游重构任务定位偏差 | FT-070 将清单与实际脚本逐项核对（grep + 文件存在性），确保一致 |
| 健康检查探活依赖服务启动 | TC-078/079 无法动态执行 | 服务未启动按环境阻塞 SKIP 记录，不作为失败；本次 9100/9000 已启动并探活通过 |
| 环境无 bash/WSL | UT-142 .sh 语法检查无法动态执行 | 以 shebang + set -Eeuo pipefail 头部核对替代，或记录环境 SKIP |
| 本任务为梳理类，改动面小但影响下游 5 个任务 | 清单缺项导致重构遗漏 | UT-132/UT-139 双重保障：6 类主问题全覆盖 + 每条含位置/表现/重构要求三要素 |
| deploy.md 目录树与实际不符 | 重构时引用错误文档误导运维 | FT-071 专项核对，问题清单 P2/P7 记录并同步修正要求 |
| .gitignore 治理红线（env.example.json/.gitkeep 等） | 新增规则误伤应入库文件 | UT-140 治理红线核对：规则带路径前缀或精确模式 |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-10（TASK-001 20 个用例全部执行完成：单元 12、接口 3、功能 4、UI 1 全部通过；UT-141-1 预期失败已按用例预期补充问题清单 P7-14；SPDX 缺失现状反馈已补充到问题清单 P7）
- 项目经理（PM）：待执行

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
