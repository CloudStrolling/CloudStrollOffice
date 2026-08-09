# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.6
**日期**：2026-08-09
**测试负责人**：TE

> 说明：本任务（TASK-005）为 v0.2.6 的 F-005 验证闭环——保障既有接口契约无回归并输出 v0.2.6 回归报告（对应 PRD F-005 / US-004）：
> 1. 执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`，复核 TC-046~051（v0.2.5 接口回归脚本，断言级 27 项）保持 **PASS=26、FAIL=0**（TC-046-3 健康检查为可选场景，服务未启动/requests 缺失时按脚本约定 SKIP，不视为失败）；
> 2. 核对 git 变更清单（`git diff --name-status 2b343ac..HEAD`）确认本版本无接口层（Controller/DTO/响应体）与客户端 `cloudoffice-flutter-app/lib/` 运行时代码改动；LoginUserDTO 仅新增内部字段 tokenSignature、GlobalExceptionHandler 为错误码→HTTP 状态映射，均属非接口层代码改动（TASK-004 UT-124 已回标确认），不构成接口契约变更；
> 3. 静态确认 API-001~API-033 契约完整保留、无新增/变更/删除接口（以 API v0.2.6 文档声明为准，与主文档 docs/cso-api.md 接口清单逐项一致 33=33）；
> 4. 将 TC-046~051 复核结果与 TASK-004 的 TC-001~045 结果（PASS=45、FAIL=0）汇总，输出 `docs/cso-v0.2.6/regression-api-test.md` 完整回归报告（脚本清单、执行明细、统计、T-02 两项缺陷闭环说明、签名确认），声明"API 测试全部跑通"。
> 关联需求：PRD F-005 / US-004；接口契约 API-001~API-033（无新增/变更/删除）。
> 用例编号延续版本测试用例文档 cso-testcase-v0.2.6.md 编号空间（TASK-001 用至 TC-053/UT-104/FT-038/UIT-012，TASK-002 用至 TC-056/UT-112/FT-045/UIT-013，TASK-003 用至 TC-064/UT-120/FT-057/UIT-014，TASK-004 用至 TC-071/UT-125/FT-063/UIT-015），本任务新用例从 **TC-072、UT-126、FT-064、UIT-016** 起编号。
> 测试类型覆盖：单元测试（6）、接口测试（5）、功能测试（5）、UI 测试（1），共 17 个。
> 说明：本任务为"回归执行 + 契约确认 + 报告输出"类任务（common/测试验证类），不产生任何业务代码改动；测试资产复核对象为既有脚本 `scripts/API-TEST/cso-api-test-v0.2.5.py`（TC-046~051）与既有报告 `docs/cso-v0.2.5/regression-api-test.md`（需求来源）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 既有接口契约无回归保障（F-005）：TASK-005 复核 TC-046~051 + git 变更清单核对 + 契约静态确认 + 回归报告输出 | TASK-005 | 17 | P0×9、P1×5、P2×3 |
| 其中：单元测试（回归脚本完整性静态核对 + 接口层/客户端零改动负向校验 + API-001~033 契约静态核对 + 非接口层注意项确认） | TASK-005 | 6 | P0×3、P1×3 |
| 其中：接口测试（v0.2.5 回归脚本 TC-046~051 核对 + 复核执行 + 退出码确认 + git 动态核对 + 幂等边界） | TASK-005 | 5 | P0×3、P1×1、P2×1 |
| 其中：功能测试（回归前置核对 + 回归报告完整输出 + 统计口径核对 + 可选场景 SKIP 边界 + 可复现性边界） | TASK-005 | 5 | P0×3、P2×2 |
| 其中：UI 测试（无 UI 变更确认） | TASK-005 | 1 | P1×1 |

## 二、测试用例详情

### 模块：既有接口契约无回归保障（F-005） - 单元测试（静态核对与负向校验）
#### UT-126：v0.2.5 回归脚本完整包含 TC-046~051（P0）
- **用例ID**：UT-126
- **用例名称**：核对 v0.2.5 回归脚本 cso-api-test-v0.2.5.py 完整包含 TC-046~TC-051 共 6 个用例（断言级 27 项），且断言构成符合预期（TC-046-3 为可选健康检查场景，其余 26 项为目标 PASS 断言）
- **所属模块**：scripts/API-TEST / 回归脚本资产
- **优先级**：P0
- **前置条件**：`scripts/API-TEST/cso-api-test-v0.2.5.py` 存在（534 行，6 个用例、27 项断言）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：F-005 / US-004 / AC-1
- **测试数据**：`scripts/API-TEST/cso-api-test-v0.2.5.py`；`docs/cso-v0.2.5/cso-api-v0.2.5.md`（脚本固定检查对象）
- **测试步骤**：
  1. 解析脚本，核对用例输出标签 TC-046~TC-051 是否全部存在且无缺漏
  2. 核对断言构成：TC-046（3 项：046-1 文档声明/046-2 无接口层文件/046-3 可选健康检查）、TC-047（4 项）、TC-048（5 项）、TC-049（5 项）、TC-050（5 项）、TC-051（5 项），合计 27 项
  3. 核对 TC-046-3 为可选场景（异常/未装 requests 时 SKIP，不视为失败），与脚本 `report(..., skipped=True)` 约定一致
- **预期结果**：
  1. TC-046~051 共 6 个用例全部存在，断言级合计 27 项（26 项目标 PASS + 1 项可选 SKIP）
  2. 脚本退出码约定：0=全部通过，1=存在失败；运行方式 `python cso-api-test-v0.2.5.py <项目根>`，`GATEWAY_URL` 可覆盖健康检查地址
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-api-contract-regression-v0.2.6.ps1`（UT-126-1~3 断言段，已由 impm-task-coding-writetest 创建/回标并自检通过（PASS=15/FAIL=0/退出码 0，2026-08-09））
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:46~22:47：单元脚本 `cso-unit-test-api-contract-regression-v0.2.6.ps1` 执行 PASS=15/FAIL=0/退出码 0——UT-126-1 TC-046~TC-051 编号齐全无缺漏、UT-126-2 断言构成核对（27 项=26 项目标 PASS+TC-046-3 可选）通过、UT-126-3 可选场景（skipped=True）+ 退出码 0 约定 + argv 运行方式确认通过）

#### UT-127：git 变更清单无接口层（Controller/DTO/响应体）改动（P0，负向/范围控制）
- **用例ID**：UT-127
- **用例名称**：v0.2.6 全部变更（`git diff --name-status 2b343ac..HEAD`）中无任何接口层文件改动——无 `*Controller.java`、无 Controller 路径、无网关路由结构、无 ApiResult/PageResult 响应体结构变更（满足 F-005 修复约束：不触碰接口层）
- **所属模块**：全项目 / 变更范围
- **优先级**：P0
- **前置条件**：v0.2.6 修复范围已完成并提交（git 变更清单可审计，2b343ac = v0.2.5 合并收尾提交）
- **测试类型**：单元测试（静态核对/负向）
- **关联需求ID**：F-005 / US-004 / AC-2
- **测试数据**：`git diff --name-status 2b343ac..HEAD`（或 `git status --porcelain` + `git diff --name-only` 工作区核对）
- **测试步骤**：
  1. 执行 `git diff --name-status 2b343ac..HEAD` 获取本版本变更文件清单
  2. 检查清单中是否出现 `controller/` 路径、`*Controller.java`、网关路由结构（application.yml 路由段）变更
  3. 核对响应体相关文件（ApiResult.java / PageResult.java / ErrorCode 枚举）是否变更（允许存在但须确认结构未变）
- **预期结果**：
  1. 变更清单中无任何 Controller 文件变更（7 个 Controller：auth 5 个 + biz/system 各 1 个均不在清单）
  2. 无网关路由结构变更；ApiResult 结构（code/message/data/timestamp）与 29 个错误码枚举未变
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-api-contract-regression-v0.2.6.ps1`（UT-127-1~3 断言段，已由 impm-task-coding-writetest 创建/回标并自检通过（PASS=15/FAIL=0/退出码 0，2026-08-09））
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:46~22:47：UT-127-1 git 变更清单（2b343ac..HEAD）无 `*Controller.java`/`controller/` 路径变更、UT-127-2 网关 application.yml 无路由结构变更（routes/predicates/filters 未触碰）、UT-127-3 ApiResult.java/PageResult.java/ErrorCode.java 不在变更清单——响应体结构完整）

#### UT-128：git 变更清单无客户端 lib/ 运行时代码改动（P0，负向/范围控制）
- **用例ID**：UT-128
- **用例名称**：v0.2.6 全部变更清单中无 `cloudoffice-flutter-app/lib/` 前缀文件（客户端运行时代码零改动，Web/Windows 客户端无需任何修改即可正常使用）
- **所属模块**：全项目 / 变更范围（客户端）
- **优先级**：P0
- **前置条件**：v0.2.6 修复范围已完成并提交
- **测试类型**：单元测试（静态核对/负向）
- **关联需求ID**：F-005 / US-004 / AC-2 / AC-3
- **测试数据**：`git diff --name-status 2b343ac..HEAD`
- **测试步骤**：
  1. 执行 git 命令获取变更清单
  2. 检查清单中 `cloudoffice-flutter-app/` 路径下文件（重点 `lib/` 下 *.dart 运行时代码、pubspec.yaml）
- **预期结果**：
  1. 变更清单中无任何 `cloudoffice-flutter-app/lib/` 文件（客户端运行时代码零改动）
  2. 客户端无需重新构建/发布即可继续使用既有接口契约
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-api-contract-regression-v0.2.6.ps1`（UT-128-1 断言段，已由 impm-task-coding-writetest 创建/回标并自检通过（PASS=15/FAIL=0/退出码 0，2026-08-09））
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:46~22:47：UT-128-1 变更清单（2b343ac..HEAD）中 `cloudoffice-flutter-app/` 前缀文件数=0——客户端 lib/ 运行时代码零改动，Web/Windows 客户端无需任何修改）

#### UT-129：API 契约静态核对——主文档与 v0.2.6 文档接口清单逐项一致（P1）
- **用例ID**：UT-129
- **用例名称**：`docs/cso-api.md`（v0.0.1 基线）与 `docs/cso-v0.2.6/cso-api-v0.2.6.md` 第 1 章接口清单逐项核对——API-001~API-033 共 33 个接口的编号/名称/方法/路径/认证列完全一致（33=33）
- **所属模块**：API 契约文档（docs/cso-api.md ↔ docs/cso-v0.2.6/cso-api-v0.2.6.md）
- **优先级**：P1
- **前置条件**：两份 API 文档均存在且完整
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：F-005 / US-004 / AC-3
- **测试数据**：`docs/cso-api.md`（接口清单 33 行）；`docs/cso-v0.2.6/cso-api-v0.2.6.md`（接口清单 33 行）
- **测试步骤**：
  1. 提取主文档接口清单（API-001~033：编号/名称/方法/路径/认证）
  2. 提取 v0.2.6 文档接口清单并逐项比对
  3. 核对关键端点抽样：API-001 登录（POST /api/v1/auth/login 白名单）、API-004 登出（POST /api/v1/auth/logout）、API-012 健康检查（GET /api/v1/auth/health 白名单）、API-032/033 biz/system 健康检查
- **预期结果**：
  1. 两份文档接口清单逐项一致（33=33），无新增/变更/删除
  2. v0.2.6 文档第 0 章声明"本版本无新增接口、无接口变更、无接口删除"且与实现一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-api-contract-regression-v0.2.6.ps1`（UT-129-1~3 断言段，已由 impm-task-coding-writetest 创建/回标并自检通过（PASS=15/FAIL=0/退出码 0，2026-08-09））
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:46~22:47：UT-129-1 docs/cso-api.md 接口清单行数=33 且 cso-api-v0.2.6.md=33（33=33）、UT-129-2 33 行逐项一致（差异行 0/33，无新增/变更/删除）、UT-129-3 关键端点抽样（API-001/004/012/032/033 路径与白名单标记）两份文档均通过）

#### UT-130：API v0.2.6 文档声明无新增/变更/删除接口（P1，负向/声明核对）
- **用例ID**：UT-130
- **用例名称**：cso-api-v0.2.6.md 显式声明"无新增接口、无接口变更、无接口删除"，且契约一致性说明（修复范围限定于构建/依赖配置与密钥格式契约）存在——契约静态确认无回归
- **所属模块**：API 契约文档（docs/cso-v0.2.6/cso-api-v0.2.6.md）
- **优先级**：P1
- **前置条件**：`docs/cso-v0.2.6/cso-api-v0.2.6.md` 存在（148 行）
- **测试类型**：单元测试（静态核对/负向）
- **关联需求ID**：F-005 / US-004 / AC-3
- **测试数据**：`docs/cso-v0.2.6/cso-api-v0.2.6.md`（第 0 章版本变更说明 + 第 146 行契约一致性说明）
- **测试步骤**：
  1. 读取文档第 0 章，核对是否同时含"无新增接口"+"无接口变更"+"无接口删除"三句声明
  2. 核对第 1 章接口清单含 API-001 与 API-033（首尾完整）
  3. 核对文末契约一致性说明（修复范围限定 bootstrap/密钥契约，未触碰 Controller/DTO/响应体）
- **预期结果**：
  1. 三句声明全部存在（缺任意一句即契约声明不完整）
  2. 接口清单 API-001~API-033 完整；契约一致性说明存在——静态确认契约完整保留
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-api-contract-regression-v0.2.6.ps1`（UT-130-1~3 断言段，已由 impm-task-coding-writetest 创建/回标并自检通过（PASS=15/FAIL=0/退出码 0，2026-08-09））
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:46~22:47：UT-130-1 第 0 章「无新增接口」+「无接口变更」+「无接口删除」三句声明齐全、UT-130-2 接口清单含 API-001 与 API-033（首尾完整）、UT-130-3 契约一致性说明存在（修复范围限定构建/依赖配置与密钥格式契约，未触碰 Controller/DTO/响应体））

#### UT-131：非接口层注意项确认——LoginUserDTO 内部字段与 GlobalExceptionHandler 状态映射不构成契约变更（P1）
- **用例ID**：UT-131
- **用例名称**：TASK-004 修复中的两处非接口层代码改动（LoginUserDTO.java 新增内部字段 tokenSignature、GlobalExceptionHandler.java 错误码→HTTP 状态映射）经核对不构成对外接口契约变更——未改动 Controller 签名、请求/响应 DTO 结构与 ApiResult 响应体结构（TASK-004 UT-124 结论复核）
- **所属模块**：cloudoffice-common / 非接口层代码改动说明
- **优先级**：P1
- **前置条件**：TASK-004 已提交（变更清单可审计）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：F-005 / US-004 / AC-2（契约零改动，注意项须在回归报告中说明）
- **测试数据**：`git diff 2b343ac..HEAD -- cloudoffice-common`；`LoginUserDTO.java`；`GlobalExceptionHandler.java`
- **测试步骤**：
  1. 核对 LoginUserDTO.java 变更：确认仅新增内部字段 tokenSignature（Access Token 签名指纹，供服务端同端互斥/登出吊销使用），非对外请求/响应字段
  2. 核对 GlobalExceptionHandler.java 变更：确认按 ErrorCode.code 映射 HTTP 状态（409/429/403 契约）+ MissingRequestHeaderException→400，ApiResult 结构与 29 个错误码枚举未变
  3. 复核 TASK-004 UT-124 结论：无 Controller 接口签名、DTO 响应结构与客户端代码改动
- **预期结果**：
  1. 两处改动均属服务内部实现/行为对齐契约，不构成对外接口契约变更
  2. 回归报告须包含该注意项说明，避免验收误判
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-api-contract-regression-v0.2.6.ps1`（UT-131-1~2 断言段，已由 impm-task-coding-writetest 创建/回标并自检通过（PASS=15/FAIL=0/退出码 0，2026-08-09））
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:46~22:47：UT-131-1 LoginUserDTO.java 变更仅新增内部字段 tokenSignature（无其他字段/契约变更）、UT-131-2 GlobalExceptionHandler.java 变更仅错误码→HTTP 状态映射（HttpStatus.resolve）+ MissingRequestHeaderException→400，ApiResult 结构与 29 个错误码枚举未变——两处均属非接口层改动，不构成对外接口契约变更）

### 模块：既有接口契约无回归保障（F-005） - 接口测试（v0.2.5 回归复核）
#### TC-072：核对用例——cso-api-test-v0.2.5.py 完整包含 TC-046~051（P0）
- **用例ID**：TC-072
- **用例名称**：核对 v0.2.5 回归脚本 cso-api-test-v0.2.5.py 完整包含 TC-046~TC-051 共 6 个用例（断言级 27 项），覆盖 v0.2.5 回归报告记录的六项无接口变更回归确认（无接口变更回归/env 迁移/scripts 迁移/Maven 构建配置/Flutter 构建配置/整体验收）
- **所属模块**：scripts/API-TEST / 回归脚本资产
- **优先级**：P0
- **前置条件**：`scripts/API-TEST/cso-api-test-v0.2.5.py` 存在（534 行，6 个用例、27 项断言）
- **测试类型**：接口测试（静态核对）
- **关联需求ID**：F-005 / US-004 / AC-1
- **测试数据**：`scripts/API-TEST/cso-api-test-v0.2.5.py`；`docs/cso-v0.2.5/regression-api-test.md`（v0.2.5 报告，TC-046~051 定义）
- **测试步骤**：
  1. 解析脚本，统计用例输出标签/断言块数量，核对 TC-046~TC-051 编号是否全部存在且无缺漏
  2. 逐一核对 6 个用例的断言构成：TC-046 无接口变更回归确认（3 项）、TC-047 env 迁移不影响接口契约（4 项）、TC-048 scripts 迁移不影响接口契约（5 项）、TC-049 Maven 构建配置不影响接口契约（5 项）、TC-050 Flutter 客户端构建配置不影响接口契约（5 项）、TC-051 整体验收不影响接口契约（5 项）
  3. 核对 TC-046-3 健康检查为可选场景（异常/未装 requests 时按脚本约定 SKIP，不视为失败）
- **预期结果**：
  1. TC-046~051 共 6 个用例全部存在，断言级 27 项（26 项目标 PASS + 1 项可选 SKIP）
  2. 用例覆盖 git 变更清单/API 文档静态断言与健康检查动态断言，与任务验收标准口径一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（TC-072：`test_tc072_verify_v025_script_complete` 核对函数，静态核对 v0.2.5 脚本 TC-046~051 编号与断言构成；执行复核走 `scripts/API-TEST/cso-api-test-v0.2.5.py`。已由 impm-task-coding-writetest 创建/回标并自检通过（TC-072~076 实测 PASS=7/FAIL=0/退出码 0，2026-08-09））
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:47~22:49：cso-api-test-v0.2.6.py 执行 TC-072-1（6 个用例编号 TC-046~TC-051 齐全）、TC-072-2（27 项断言编号全部存在，26 项目标 PASS+TC-046-3 可选）、TC-072-3（skipped=True 约定 + 退出码 0=全部通过 + argv 传项目根）全部 PASS）

#### TC-073：执行 v0.2.5 回归脚本——TC-046~051 复核保持 PASS=26、FAIL=0（P0）
- **用例ID**：TC-073
- **用例名称**：执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`，TC-046~051 复核结果保持 **PASS=26、FAIL=0**（TC-046-3 健康检查为可选场景，服务未启动时按脚本约定 SKIP 不视为失败）——v0.2.5 无接口变更声明在 v0.2.6 仍成立
- **所属模块**：v0.2.5 接口回归（TC-046~051 / API-001~033 契约复核）
- **优先级**：P0
- **前置条件**：`scripts/API-TEST/cso-api-test-v0.2.5.py` 与 `docs/cso-v0.2.5/cso-api-v0.2.5.md` 存在；Python 3.x 可用（建议 3.8+）；git 工作区已提交 v0.2.6 变更（除文档类外无接口层/客户端未提交改动）
- **测试类型**：接口测试
- **关联需求ID**：F-005 / US-004 / AC-1（核心验收：PASS=26、FAIL=0）
- **测试数据**：命令 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`（项目根缺省为脚本上级两级；环境变量 `GATEWAY_URL` 可覆盖健康检查地址，默认 http://localhost:9000）
- **测试步骤**：
  1. 确认前置条件就绪（脚本与 v0.2.5 API 文档存在；git 变更清单已审计）
  2. 在项目根目录执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`
  3. 核对脚本输出：6 个用例逐项执行，汇总统计 PASS=26、FAIL=0、SKIP<=1（TC-046-3 可选）
  4. 核对关键断言：TC-046-1/047-1/048-1/049-1/050-1/051-1（API 文档无接口变更声明）、TC-046-2/047-2/048-2/049-2/050-2/051-2（git 无接口层改动）、TC-050-2c/051-2b（客户端 lib/ 零改动）、TC-051-3（契约保留）
- **预期结果**：
  1. 脚本执行完成，**PASS=26、FAIL=0、SKIP=1（TC-046-3 可选场景）或 SKIP=0**，退出码 0
  2. TC-046~051 全部通过——v0.2.6 修复未引入接口契约回归（无新增/变更/删除接口声明成立）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（执行复核，本用例由 runtest 直接执行并记录）
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:47：执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`（miniconda3 Python 3.13.11），TC-046~051 六项复核全部 PASS，汇总 **PASS=27、FAIL=0、SKIP=0、退出码 0**——服务可达时 TC-046-3 健康检查实际 PASS，**优于最低验收线 PASS=26**；v0.2.5 无接口变更声明在 v0.2.6 仍成立）

#### TC-074：回归脚本退出码 0——脚本正常跑完不崩溃（P0）
- **用例ID**：TC-074
- **用例名称**：v0.2.5 回归脚本执行完成退出码 0（脚本约定：0=全部通过 FAIL=0；1=存在失败），无未捕获异常崩溃
- **所属模块**：v0.2.5 接口回归 / 脚本健壮性
- **优先级**：P0
- **前置条件**：TC-073 已执行
- **测试类型**：接口测试
- **关联需求ID**：F-005 / US-004 / AC-1
- **测试数据**：TC-073 执行输出与 `$LASTEXITCODE`（或 echo $?）
- **测试步骤**：
  1. 核对 TC-073 执行后的进程退出码
  2. 检查脚本输出中无未捕获异常堆栈（26 个静态/git 断言不涉及网络 IO，天然无超时风险；TC-046-3 健康检查有 try/except + SKIP 约定）
- **预期结果**：
  1. 退出码 0（PASS=26、FAIL=0；TC-046-3 可选场景 SKIP 不影响退出码）
  2. 无异常堆栈——脚本完整跑完全部 6 个用例并输出汇总统计
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（执行复核，本用例由 runtest 直接执行并记录）
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:47：TC-073 执行退出码=0，无未捕获异常堆栈（26 项静态/git 断言不涉及网络 IO，TC-046-3 健康检查有 try/except + SKIP 约定）——脚本完整跑完全部 6 个用例并输出汇总统计）

#### TC-075：git 变更清单动态核对——接口层零改动 + 客户端 lib/ 零改动（P1）
- **用例ID**：TC-075
- **用例名称**：v0.2.5 回归脚本的 git 断言动态确认——TC-046-2/047-2/048-2/049-2/050-2/051-2 断言命中数为 0（接口层文件零改动）、TC-050-2c/051-2b 断言无 `cloudoffice-flutter-app/lib/` 前缀文件——本版本无接口层与客户端运行时代码改动
- **所属模块**：全项目 / git 变更清单动态核对
- **优先级**：P1
- **前置条件**：TC-073 已执行（脚本 git 断言已动态运行）
- **测试类型**：接口测试
- **关联需求ID**：F-005 / US-004 / AC-2
- **测试数据**：TC-073 执行日志中 TC-046~051 的 git 断言行输出
- **测试步骤**：
  1. 从 TC-073 执行日志定位 TC-046~051 的 git 断言输出
  2. 核对接口层判定（is_interface_file 命中数=0）与客户端判定（lib/ 前缀文件数=0）断言均 PASS
  3. 与 UT-127/UT-128 静态核对结果交叉印证
- **预期结果**：
  1. 全部 git 断言 PASS（无接口层文件、无客户端 lib/ 文件、迁移白名单外无业务代码改动）
  2. 动态（脚本断言）与静态（UT-127/128）双重确认无接口层/客户端运行时代码改动
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（TC-075 由 TC-073 执行输出核对，本用例由 runtest 记录）
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:47~22:49：TC-075 断言 PASS——v0.2.5 回归脚本输出中 TC-046-2/047-2/048-2/049-2/050-2/051-2（接口层文件零改动 6 条）与 TC-050-2c/051-2b（客户端 lib/ 零改动 2 条）全部 [PASS]；与 UT-127/UT-128 静态核对双重确认无接口层/客户端运行时代码改动）

#### TC-076：边界——回归脚本幂等复跑结果一致（P2，边界/幂等）
- **用例ID**：TC-076
- **用例名称**：v0.2.5 回归脚本连续两次执行结果一致（26 项静态/git 断言与文档状态无关，重复执行无冲突，仍 PASS=26、FAIL=0）——回归结果可复现
- **所属模块**：v0.2.5 接口回归 / 幂等性
- **优先级**：P2
- **前置条件**：TC-073 已通过一次（首次执行结果正常）
- **测试类型**：接口测试
- **关联需求ID**：F-005 / US-004（边界情况：回归结果可复现约定）
- **测试数据**：再次执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py <项目根>`
- **测试步骤**：
  1. 在 TC-073 通过后再次执行回归脚本
  2. 对比两次执行的汇总统计与失败用例
- **预期结果**：
  1. 第二次执行仍 PASS=26、FAIL=0（静态/git 断言不产生副作用，结果可复现）
  2. 若因工作区出现未提交接口层/客户端改动导致 FAIL，记录原因并回退相应改动后复跑（对应边界处理约定）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（执行复核，本用例由 runtest 记录）
- **测试过程与结论**：**通过**（runtest 实测 2026-08-09 22:47~22:49：TC-076 幂等复跑（cso-api-test-v0.2.6.py 强制重跑）结果与首次一致——**PASS=27、FAIL=0、SKIP=0、退出码 0**，静态/git 断言无副作用，回归结果可复现）

### 模块：既有接口契约无回归保障（F-005） - 功能测试（回归前置与报告输出）
#### FT-064：回归执行前置核对——v0.2.5 API 文档与 git 基线提交可用（P0）
- **用例ID**：FT-064
- **用例名称**：执行 v0.2.5 回归脚本前核对前置：`docs/cso-v0.2.5/cso-api-v0.2.5.md` 存在（脚本固定检查对象，勿删除）、git 基线提交 2b343ac 存在（v0.2.5 合并收尾提交，变更审计基线）、Python 3.x 可用
- **所属模块**：回归前置（环境与资产核对）
- **优先级**：P0
- **前置条件**：v0.2.6 变更已完成并提交（TASK-001~004 已提交）
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-004 / AC-1 / AC-2
- **测试数据**：`docs/cso-v0.2.5/cso-api-v0.2.5.md`；`git rev-parse 2b343ac`；`python --version`
- **测试步骤**：
  1. 核对 v0.2.5 API 文档存在且非空（脚本 VERSION_DIR/API_DOC 检查对象）
  2. 核对 git 基线提交 2b343ac 存在（`git cat-file -t 2b343ac` 返回 commit）
  3. 核对 Python 运行时可用（`python --version`；requests 缺失时 TC-046-3 SKIP 不视为失败）
- **预期结果**：
  1. v0.2.5 API 文档存在；git 基线提交可用；Python 3.x 可执行
  2. 前置就绪后 TC-073 可正常执行
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-064 测试步骤与记录，已由 impm-task-coding-writetest 编写，2026-08-09 22:40）
- **测试过程与结论**：**通过**（runtest 复核 2026-08-09 22:47：`docs/cso-v0.2.5/cso-api-v0.2.5.md` 存在（Test-Path=True）、`git cat-file -t 2b343ac` 返回 commit（基线可用）、miniconda3 Python 3.13.11 + requests 2.32.5 可用——前置三要素齐备，TC-073 可正常执行）

#### FT-065：regression-api-test.md 完整回归报告输出——脚本清单、执行明细、统计、T-02 闭环说明、签名确认（P0）
- **用例ID**：FT-065
- **用例名称**：`docs/cso-v0.2.6/regression-api-test.md` 完整输出——在 TASK-004 报告（TC-001~045）基础上汇总：脚本清单与执行结果（cso-api-test-v0.0.1.py + cso-api-test-v0.2.5.py）、TC-046~051 复核明细（断言级）、全量统计（TC-001~051）、T-02 两项缺陷闭环说明（bootstrap 依赖缺失 / RSA 密钥格式契约不匹配）、签名确认（TE/PM）
- **所属模块**：回归报告产出（docs/cso-v0.2.6/regression-api-test.md）
- **优先级**：P0
- **前置条件**：TC-073 执行完成（TC-046~051 复核结果已产生）；TASK-004 报告已含 TC-001~045 部分
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-004 / AC-4（回归报告完整输出）
- **测试数据**：`docs/cso-v0.2.6/regression-api-test.md`
- **测试步骤**：
  1. 检查回归报告文件存在且非空
  2. 核对报告包含：①脚本清单与执行结果（cso-api-test-v0.2.5.py 执行命令/用例数/通过/失败/跳过/结果；cso-api-test-v0.0.1.py 结果汇总）；②TC-046~051 复核明细（用例/断言/结果）；③统计（TC-001~045 PASS=45 + TC-046~051 PASS=26 → 全量 PASS=71、FAIL=0、SKIP<=1 可选）；④T-02 两项缺陷闭环说明（bootstrap 依赖缺失 ADR-014 / RSA 密钥格式契约 ADR-015）；⑤git 变更清单核对结论（无接口层/客户端运行时代码改动）+ API-001~033 静态确认；⑥签名确认
  3. 核对报告声明"API 测试全部跑通"
- **预期结果**：
  1. 报告文件存在且内容完整（六要素齐全：脚本清单、执行明细、统计、T-02 闭环说明、git/契约核对、签名确认）
  2. 统计口径：TC-001~045 PASS=45、FAIL=0、SKIP=0 + TC-046~051 PASS=26、FAIL=0、SKIP<=1（可选）→ 全量 PASS=71、FAIL=0；声明"API 测试全部跑通"
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-065 测试步骤与记录，已由 impm-task-coding-writetest 编写，2026-08-09 22:40）
- **测试过程与结论**：**通过**（runtest 复核 2026-08-09 22:47~22:49：`docs/cso-v0.2.6/regression-api-test.md` 存在且内容完整（223 行）——六要素齐全：①脚本清单与执行结果（§7.1 两脚本）、②TC-046~051 复核明细（§7.2 断言级 27 行）、③统计（§7.6 全量 PASS=72/FAIL=0）、④T-02 两项缺陷闭环说明（§7.5 ADR-014/ADR-015）、⑤git 变更清单核对（§7.3 无接口层/客户端改动 + 非接口层注意项）+ API-001~033 静态确认（§7.4 33=33）、⑥签名确认（§7.7 TE/PM）；报告声明"**结论：API 测试全部跑通。**"）

#### FT-066：回归报告统计口径核对——全量 PASS=71、FAIL=0（P0）
- **用例ID**：FT-066
- **用例名称**：回归报告统计口径核对——TASK-004 的 TC-001~045（PASS=45、FAIL=0、SKIP=0）+ TASK-005 复核的 TC-046~051（PASS=26、FAIL=0、SKIP<=1 可选）→ 全版本累计 **PASS=71、FAIL=0**（SKIP 为 TC-046-3 可选场景约定，不视为失败），与任务验收标准一致
- **所属模块**：v0.2.6 接口回归 / 结果统计
- **优先级**：P0
- **前置条件**：FT-065 已执行（报告已产出）
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-004 / AC-1 / AC-4
- **测试数据**：`docs/cso-v0.2.6/regression-api-test.md` 统计章节 + TC-073 执行输出
- **测试步骤**：
  1. 核对报告统计章节：TC-001~045 部分 PASS=45、FAIL=0、SKIP=0（TASK-004 记录）
  2. 核对 TC-046~051 部分 PASS=26、FAIL=0、SKIP=1（TC-046-3 可选）或 SKIP=0
  3. 核对全量统计 PASS=71（45+26）、FAIL=0、SKIP<=1（可选场景不视为失败）与退出码 0
- **预期结果**：
  1. 全量统计 **PASS=71、FAIL=0**，无失败用例；SKIP 仅限 TC-046-3 可选场景
  2. 统计口径与 context.md 执行要点一致，无口径漂移
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-066 测试步骤与记录，已由 impm-task-coding-writetest 编写，2026-08-09 22:40）
- **测试过程与结论**：**通过**（runtest 复核 2026-08-09 22:47~22:49：报告统计口径核对——TC-001~045 部分 PASS=45/FAIL=0/SKIP=0（§1/§2，TASK-004 记录）、TC-046~051 部分 PASS=27/FAIL=0/SKIP=0（本次实测服务可达，TC-046-3 实际 PASS）、全量统计 PASS=72/FAIL=0/SKIP=0/退出码 0（§7.6）——本次实测 TC-046~051 PASS=27 优于最低线 PASS=26，统计口径与执行结果一致，无漂移）

#### FT-067：边界——TC-046-3 健康检查可选场景 SKIP 不视为失败（P2，边界）
- **用例ID**：FT-067
- **用例名称**：TC-046-3 健康检查（GET /api/v1/auth/health 动态探活）为可选场景——服务未启动或 requests 缺失时按脚本约定 SKIP 不视为失败（US-004 边界约定：脚本 `report(..., skipped=True)` 不计数 FAIL）
- **所属模块**：v0.2.5 接口回归 / 可选场景处理
- **优先级**：P2
- **前置条件**：TC-073 已执行（脚本运行环境已确定）
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-004（边界情况：服务未启动时 SKIP 不视为失败）
- **测试数据**：TC-073 执行输出中 TC-046-3 行；GATEWAY_URL 环境变量（默认 http://localhost:9000）
- **测试步骤**：
  1. 从 TC-073 执行输出定位 TC-046-3 结果
  2. 若 SKIP：核对输出含 skipped 标记且不影响汇总 FAIL 计数（PASS=26、FAIL=0 仍成立）
  3. 若 PASS：核对健康检查返回 200（服务可达时动态探活成功）
- **预期结果**：
  1. TC-046-3 无论 SKIP（服务未启动/requests 缺失）或 PASS（服务可达）均不构成失败
  2. 汇总统计保持 PASS=26、FAIL=0（SKIP<=1 可选场景约定生效）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-067 测试步骤与记录，已由 impm-task-coding-writetest 编写，2026-08-09 22:40）
- **测试过程与结论**：**通过**（runtest 复核 2026-08-09 22:47：本次 TC-073 执行输出中 TC-046-3 为 **PASS 分支**（服务可达、requests 2.32.5 可用，GET /api/v1/auth/health 返回 200）；SKIP 分支约定有效——脚本 `report(..., skipped=True)` 不计数 FAIL，服务未启动/requests 缺失时 PASS=26/FAIL=0 仍成立，不影响汇总统计）

#### FT-068：边界——回归报告可复现性：脚本重复执行结果一致（P2，边界/可复现性）
- **用例ID**：FT-068
- **用例名称**：v0.2.5 回归脚本重复执行结果一致（TC-046~051 静态/git 断言可复现，报告记录的统计与再次执行结果吻合）——回归结果可追溯、可复现
- **所属模块**：v0.2.5 接口回归 / 可复现性
- **优先级**：P2
- **前置条件**：TC-073/TC-076 已执行（首次与幂等复跑结果已记录）
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-004（边界情况：回归结果可复现约定）
- **测试数据**：TC-073（首次）+ TC-076（复跑）执行输出与回归报告统计
- **测试步骤**：
  1. 对比首次与复跑执行的汇总统计（PASS/FAIL/SKIP）
  2. 核对回归报告记录的统计与两次执行结果一致
- **预期结果**：
  1. 首次与复跑均 PASS=26、FAIL=0（结果可复现）
  2. 回归报告统计与执行结果吻合，无漂移
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-068 测试步骤与记录，已由 impm-task-coding-writetest 编写，2026-08-09 22:40）
- **测试过程与结论**：**通过**（runtest 复核 2026-08-09 22:47~22:49：首次（22:47）与幂等复跑（TC-076，22:49）均 PASS=27/FAIL=0/SKIP=0/退出码 0，结果一致可复现；回归报告 §7.1/§7.6 统计（全量 PASS=72/FAIL=0）与两次执行结果吻合，无漂移）

### 模块：既有接口契约无回归保障（F-005） - UI 测试（无 UI 变更确认）
#### UIT-016：客户端 UI 无任何变更（P1）
- **用例ID**：UIT-016
- **用例名称**：本任务为接口契约无回归保障 + 回归报告输出，客户端应用界面与交互无任何变更（git 变更清单无 `cloudoffice-flutter-app/lib/` 下 .dart 界面文件与客户端配置改动，Web/Windows 客户端零修改可用）
- **所属模块**：客户端（cloudoffice-flutter-app）/ 无 UI 变更
- **优先级**：P1
- **前置条件**：v0.2.6 修复范围已完成并提交（git 工作区存在变更记录）
- **测试类型**：UI 测试
- **关联需求ID**：F-005 / US-004 / AC-2 / AC-3（客户端运行时代码零改动）
- **测试数据**：git 变更清单（`git diff --name-status 2b343ac..HEAD` + `git status --porcelain`）
- **测试步骤**：
  1. 执行 git 命令获取变更文件清单
  2. 检查清单中是否出现 `cloudoffice-flutter-app/lib` 下界面代码（*.dart）、pubspec.yaml、客户端构建配置
- **预期结果**：
  1. 变更清单中无任何 `cloudoffice-flutter-app/lib` 下 .dart 界面文件与客户端配置文件改动
  2. 客户端应用界面/交互/运行行为无任何变更（接口契约不变，客户端无需任何修改即可继续正常使用登录认证与业务功能）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（UIT-016 测试步骤与记录，已由 impm-task-coding-writetest 编写，2026-08-09 22:40）
- **测试过程与结论**：**通过**（runtest 复核 2026-08-09 22:46~22:49：`git diff --name-status 2b343ac..HEAD` 变更清单中 `cloudoffice-flutter-app/` 路径下文件数=0（UT-128-1 实测 PASS）——无任何 .dart 界面文件/pubspec.yaml/客户端配置改动，客户端界面/交互/运行行为零变更，Web/Windows 客户端零修改可用）

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 17（UT-126~131 ×6、TC-072~076 ×5、FT-064~068 ×5、UIT-016 ×1——2026-08-09 22:46~22:49 由 impm-task-coding-runtest 执行/复核确认：单元脚本 cso-unit-test-api-contract-regression-v0.2.6.ps1 实测 PASS=15/FAIL=0/退出码 0；接口脚本 cso-api-test-v0.2.6.py 实测 TASK-005 用例 TC-072~076 全部 PASS；v0.2.5 回归脚本 cso-api-test-v0.2.5.py 实测 PASS=27/FAIL=0/SKIP=0/退出码 0（首次+幂等复跑一致，优于最低验收线 PASS=26）；功能/UI 复核 cso-ui-test-record-v0.2.6.md 记录齐备与实测证据一致） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0（TC-046-3 可选场景本次服务可达实际 PASS；SKIP 约定依然有效：服务未启动/requests 缺失时按脚本约定 SKIP 不视为失败） |

> 注意项（runtest 如实报告）：`cso-api-test-v0.2.6.py` 整脚本执行时出现 1 项 FAIL——**TC-054-4**（TASK-002 的版本级变更控制断言，非本任务用例）。原因：断言要求 `deploy/scripts/deploy-rsa-keygen.ps1` 出现在工作区变更清单（`len(script_changes) >= 1`），该文件已于 TASK-002 提交（b42558d）入库，提交后"必须出现在工作区"前提永久失效（TASK-004 执行记录 PASS=39/FAIL=2 已登记同类预期断言行为；脚本注释亦声明 TC-052-4/TC-054-4 为版本级变更控制断言）。**不构成接口契约回归、不影响 TASK-005 验收（TC-046~051 复核 PASS=27/FAIL=0 与契约静态确认均达成）**；若后续版本需消除该断言失效，可将其调整为"已入库或不在变更清单均视为通过"。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 本机无 Python 运行时（python/py 均不在 PATH，ws.md 实测确认） | cso-api-test-v0.2.5.py 无法执行，TC-073/074 阻塞 | 在具备 Python 3.x（建议 3.8+）的目标环境执行，或先安装 Python（TC-046-3 健康检查需 requests，缺失时按脚本约定 SKIP 不视为失败） |
| v0.2.5 API 文档（cso-api-v0.2.5.md）被误删/移动 | 脚本静态断言检查对象缺失，TC-046-1 等断言 FAIL | 脚本 VERSION_DIR/API_DOC 固定指向 docs/cso-v0.2.5/，前置核对（FT-064）先行确认文件存在 |
| 工作区存在未提交接口层/客户端改动 | git 断言（TC-046-2/050-2c/051-2b 等）FAIL，误判契约回归 | 执行前确保 v0.2.6 变更已提交；git 变更清单审计（UT-127/128）先行确认；若检出误改回退后复跑（TC-076 边界约定） |
| TASK-004 非接口层注意项（LoginUserDTO 内部字段/GlobalExceptionHandler 状态映射）被误判为接口变更 | 验收误判，契约无回归结论失真 | UT-131 静态确认 + 回归报告注意项说明（不构成 Controller 签名/DTO 响应结构/ApiResult 结构变更，TASK-004 UT-124 结论复核） |
| 回归报告统计口径漂移（SKIP 是否视为失败、PASS 汇总口径） | 验收标准核对失败 | 按 ws.md 第 5 节固定口径输出：TC-001~045 PASS=45 + TC-046~051 PASS=26 → 全量 PASS=71、FAIL=0、SKIP<=1（TC-046-3 可选场景 SKIP 不视为失败） |
| 服务未启动/requests 缺失导致 TC-046-3 不可执行 | 健康检查动态断言无法闭环 | 按脚本约定 SKIP 不视为失败（US-004 边界约定），不阻塞 PASS=26、FAIL=0 验收目标 |

## 五、签名确认
- 测试工程师（TE）：2026-08-09 编写完成（TASK-005 共 17 个用例：TC-072~076、UT-126~131、FT-064~068、UIT-016，P0×9、P1×5、P2×3）；**执行结果已由 impm-task-coding-runtest 于 2026-08-09 22:46~22:49 全部记录：17/17 通过**（UT-126~131 单元脚本实测 PASS=15/FAIL=0/退出码 0；TC-072~076 接口实测全部 PASS；v0.2.5 回归脚本复核 PASS=27/FAIL=0/SKIP=0/退出码 0（首次+幂等复跑一致，优于最低验收线 PASS=26）；FT-064~068、UIT-016 功能/UI 复核通过；回归报告 docs/cso-v0.2.6/regression-api-test.md 完整输出声明"API 测试全部跑通"）——**TASK-005 验收标准 AC-1~AC-4 全部达成**（注意项：cso-api-test-v0.2.6.py 整脚本中 TC-054-4 为 TASK-002 版本级变更控制断言因文件已入库而失效，非本任务用例、非契约回归，已如实记录）
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
