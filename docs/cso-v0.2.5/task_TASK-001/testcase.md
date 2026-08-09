# 测试用例文档（TestCase）— #TASK-001 新建 deploy 目录与 deploy/scripts 子目录
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**测试负责人**：TE

> 说明：本用例针对任务 TASK-001（新建根目录 deploy 与 deploy/scripts 子目录，作为最终构建产物、环境配置与部署脚本的唯一落点）。
> 本任务为 common 类型纯文件系统操作任务，不涉及数据库（DBD 无变更）与 HTTP 接口（v0.2.5 版本 API 文档声明无新增/变更接口）。
> 用例编号延续主文档 cso-testcase.md 编号空间：UT-061~065 单元测试、TC-046 接口测试、FT-009~011 功能测试、UIT-006 UI 测试。
> 关联需求：PRD F-001、F-006；用户故事 US-001；验收标准 AC-1。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 部署目录结构（F-001/F-006） | TASK-001 | 10 | P0×5、P1×5 |
| 其中：单元测试（目录结构校验） | TASK-001 | 5 | P0×3、P1×2 |
| 其中：接口测试（无接口变更回归确认） | TASK-001 | 1 | P1×1 |
| 其中：功能测试（建目录与可承载性） | TASK-001 | 3 | P0×2、P1×1 |
| 其中：UI 测试（目录可见性/无 UI 变更） | TASK-001 | 1 | P1×1 |
| **合计** |  | **10** | P0×5、P1×5 |

## 二、测试用例详情

### 模块：部署目录结构（F-001/F-006） - 单元测试（目录结构校验）
#### UT-061：deploy 目录存在且为目录类型（P0）
- **用例ID**：UT-061
- **用例名称**：项目根目录存在 deploy 目录且为 Container 类型
- **所属模块**：deploy / 目录结构
- **优先级**：P0
- **前置条件**：TASK-001 编码已完成（已执行建目录操作）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001 / AC-1
- **测试数据**：路径 `<项目根>\deploy`
- **测试步骤**：
  1. 执行目录存在性校验：`Test-Path -LiteralPath "<项目根>\deploy" -PathType Container`
  2. 记录返回布尔值
- **预期结果**：
  1. 返回 True（deploy 目录已创建且为目录类型）
  2. deploy 位于项目根目录，与 src、cloudoffice-flutter-app、scripts、docs 平级
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-061 目录存在性校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行：Test-Path -PathType Container 返回 True；deploy 为根目录直接子项，与 cloudoffice-flutter-app、docs、scripts 等平级）

#### UT-062：deploy/scripts 子目录存在且为目录类型（P0）
- **用例ID**：UT-062
- **用例名称**：deploy 下存在 scripts 子目录且为 Container 类型
- **所属模块**：deploy/scripts / 目录结构
- **优先级**：P0
- **前置条件**：UT-061 通过（deploy 目录已存在）
- **测试类型**：单元测试
- **关联需求ID**：F-006 / US-001 / AC-1
- **测试数据**：路径 `<项目根>\deploy\scripts`
- **测试步骤**：
  1. 执行子目录存在性校验：`Test-Path -LiteralPath "<项目根>\deploy\scripts" -PathType Container`
  2. 记录返回布尔值
- **预期结果**：
  1. 返回 True（deploy/scripts 子目录已创建且为目录类型）
  2. 目录名严格为小写 `scripts`
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-062 子目录存在性校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行：Test-Path -PathType Container 返回 True；目录名为全小写 scripts）

#### UT-063：deploy 目录命名与层级正确（P0）
- **用例ID**：UT-063
- **用例名称**：deploy 目录命名固定为小写且为根目录直接子项
- **所属模块**：deploy / 目录结构
- **优先级**：P0
- **前置条件**：UT-061 通过
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：项目根目录列表
- **测试步骤**：
  1. 列出项目根目录直接子项，确认存在名称为 `deploy`（全小写）的条目
  2. 确认 `deploy` 条目为目录（非文件、非链接）
- **预期结果**：
  1. 根目录存在且仅存在一个名为 `deploy` 的小写目录
  2. 不存在 `Deploy`、`DEPLOY` 等大小写变体目录
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-063 命名与层级校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行：根目录仅 1 个全小写 deploy 目录且为 Container，无 Deploy/DEPLOY 等大小写变体）

#### UT-064：deploy 已存在时复用不覆盖（P1，边界）
- **用例ID**：UT-064
- **用例名称**：deploy 已存在时重复执行建目录不覆盖已有内容
- **所属模块**：deploy / 幂等性
- **优先级**：P1
- **前置条件**：deploy 目录已存在，且内部已放入占位/有效内容（如 `.gitkeep` 占位文件）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / AC-1（deploy 已存在时复用不覆盖）
- **测试数据**：占位文件 `<项目根>\deploy\.gitkeep`（内容任意）
- **测试步骤**：
  1. 在 deploy 内创建占位文件 `.gitkeep`
  2. 再次执行建目录操作（`New-Item -Path "<项目根>\deploy\scripts" -ItemType Directory -Force`）
  3. 检查操作是否报错、占位文件是否仍存在
- **预期结果**：
  1. 重复执行建目录操作不报错（幂等）
  2. `.gitkeep` 占位文件内容与存在性保持不变（未删除、未覆盖）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-064 幂等性校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行：重复 New-Item -Force 无报错；探针文件 .ut064-probe.tmp 存在且内容保持 idempotency-probe 未被覆盖。注：首轮失败为测试脚本缺陷——PS 5.1 的 Set-Content 默认追加换行导致精确比较失败，已修复脚本（读取时 Trim）后通过）

#### UT-065：deploy 不存放源代码与中间产物（P1，负向）
- **用例ID**：UT-065
- **用例名称**：deploy 目录内不得出现源代码与构建中间产物
- **所属模块**：deploy / 目录性质约束
- **优先级**：P1
- **前置条件**：UT-061 通过；deploy 已创建（env 与脚本迁移由后续任务填充）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001（Given 构建完成后 Then 不出现任何中间产物）
- **测试数据**：deploy 目录内容列表
- **测试步骤**：
  1. 递归列出 deploy 目录内容
  2. 检查是否存在中间产物目录（`target`、`build`）或源代码文件（`.java`、`.dart`、`.kt` 等）
- **预期结果**：
  1. deploy 下不存在 `target`、`build` 等构建中间产物目录
  2. deploy 下不存在源代码文件（只允许最终产物、env 配置与 .sh/.ps1 部署脚本，由后续任务填充）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-065 负向校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行：deploy 递归扫描未发现 target/build/node_modules 中间产物目录，无 .java/.dart/.kt/.py/.js 等源代码文件）

### 模块：部署目录结构（F-001/F-006） - 接口测试（无接口变更回归确认）
#### TC-046：v0.2.5 无接口变更，既有接口契约不受影响（P1）
- **用例ID**：TC-046
- **用例名称**：部署目录调整不影响既有 33 个接口契约
- **所属模块**：全模块（接口回归确认）
- **优先级**：P1
- **前置条件**：版本 API 文档 `cso-api-v0.2.5.md` 已声明本版本无新增/变更接口
- **测试类型**：接口测试
- **关联需求ID**：F-001 / F-006
- **测试数据**：版本 API 文档（docs/cso-v0.2.5/cso-api-v0.2.5.md）、git 变更清单
- **测试步骤**：
  1. 检查版本 API 文档"接口变更说明"：确认声明"无新增接口、无接口变更、无接口删除"
  2. 检查 git 变更清单：确认本次修改未触碰任何 Controller / 网关路由 / 接口层代码文件
  3. （可选）确认健康检查类接口地址（如 `/api/v1/auth/health`）在部署脚本中的引用不因目录迁移而失效——由 TASK-005 脚本迁移后验证
- **预期结果**：
  1. 版本 API 文档明确声明本版本无接口变更
  2. git 变更中无接口层代码文件改动（本任务仅目录与配置文件操作）
  3. 既有 33 个接口（API-001~API-033）契约不受本任务影响
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.5.py（test_tc046_no_api_change 函数）
- **测试过程与结论**：**通过**（2026-08-09 执行：TC-046-1 PASS 版本 API 文档声明无新增/变更/删除接口；TC-046-2 PASS git 变更清单未触碰任何 Controller/网关路由/接口层代码文件；TC-046-3 SKIP 健康检查为可选检查，网关未启动不可达按设计跳过不视为失败；PASS=2 FAIL=0 SKIP=1）

### 模块：部署目录结构（F-001/F-006） - 功能测试
#### FT-009：执行建目录操作后根目录出现 deploy 与 deploy/scripts（P0）
- **用例ID**：FT-009
- **用例名称**：端到端验证新建 deploy 目录与 scripts 子目录
- **所属模块**：deploy / 目录创建
- **优先级**：P0
- **前置条件**：项目根目录可写；git 仓库可用
- **测试类型**：功能测试
- **关联需求ID**：F-001 / F-006 / US-001 / AC-1
- **测试数据**：项目根目录 `<项目根>`
- **测试步骤**：
  1. 执行建目录操作：`New-Item -Path "<项目根>\deploy\scripts" -ItemType Directory -Force`
  2. 校验 `Test-Path "<项目根>\deploy" -PathType Container` 为 True
  3. 校验 `Test-Path "<项目根>\deploy\scripts" -PathType Container` 为 True
  4. 校验 deploy 与 src、cloudoffice-flutter-app、scripts、docs 处于同一层级（根目录直接子项）
- **预期结果**：
  1. 操作成功执行无报错
  2. deploy 与 deploy/scripts 均存在且为目录
  3. 目录层级正确（根目录直接子项）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-009 功能测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行：4/4 步骤成功——New-Item 建目录无报错；deploy 与 deploy/scripts 均存在且为 Container；deploy 为根目录直接子项与顶层目录平级）

#### FT-010：deploy 目录可承载最终产物与部署资产（P0）
- **用例ID**：FT-010
- **用例名称**：验证 deploy 下可写入最终产物、环境配置与脚本（目录可用性）
- **所属模块**：deploy / 目录可承载性
- **优先级**：P0
- **前置条件**：FT-009 通过（deploy 与 deploy/scripts 已创建）
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001
- **测试数据**：探针文件 `<项目根>\deploy\.probe-artifact.tmp`（模拟最终产物落点）、`<项目根>\deploy\.probe-env.json`（模拟环境配置落点）、`<项目根>\deploy\scripts\.probe-script.ps1`（模拟部署脚本落点）
- **测试步骤**：
  1. 在 deploy 下创建探针文件 `.probe-artifact.tmp`（模拟 jar/exe 最终产物落点）并写入内容
  2. 在 deploy 下创建探针文件 `.probe-env.json`（模拟 env.json/env.example.json 落点）并写入内容
  3. 在 deploy/scripts 下创建探针脚本 `.probe-script.ps1`（模拟 .sh/.ps1 脚本迁移落点）并写入内容
  4. 校验三个探针文件存在且内容正确
  5. 清理探针文件（恢复 deploy 纯净状态，供后续任务填充）
- **预期结果**：
  1. 三个探针文件均创建成功、内容正确（deploy 目录可写、可承载最终产物/环境配置/部署脚本）
  2. 探针文件清理后 deploy 内不留测试残留
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-010 功能测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行：3 个探针文件（.probe-artifact.tmp/.probe-env.json/.probe-script.ps1）均创建成功且内容正确，证明 deploy 可承载最终产物/env 配置/部署脚本；清理后无测试残留）

#### FT-011：deploy 已存在时复用现有目录不覆盖（P1，边界）
- **用例ID**：FT-011
- **用例名称**：deploy 已存在场景下功能级复用验证
- **所属模块**：deploy / 复用不覆盖
- **优先级**：P1
- **前置条件**：deploy 目录已存在且含有效内容（如 `.gitkeep` 占位文件或已有 env 配置）
- **测试类型**：功能测试
- **关联需求ID**：F-001 / AC-1
- **测试数据**：`<项目根>\deploy\.gitkeep`（已存在内容）
- **测试步骤**：
  1. 确认 deploy 已存在并记录其现有内容清单
  2. 再次执行建目录操作
  3. 对比操作前后 deploy 内容清单
- **预期结果**：
  1. 操作成功无报错、无重复创建
  2. deploy 原有内容（如 .gitkeep）完整保留，未被覆盖或删除
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-011 功能测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行：再次建目录无报错；操作前后 deploy 内容清单完全一致（Compare-Object diff=0），.gitkeep 与 scripts/.gitkeep 完整保留）

### 模块：部署目录结构（F-001/F-006） - UI 测试
#### UIT-006：deploy 目录在项目树/文件管理器中可见，客户端 UI 无变更（P1）
- **用例ID**：UIT-006
- **用例名称**：deploy 目录结构在 IDE 项目树与文件管理器中可见且无 UI 回归
- **所属模块**：deploy / 目录可见性；客户端（无 UI 变更）
- **优先级**：P1
- **前置条件**：FT-009 通过（deploy 与 deploy/scripts 已创建）
- **测试类型**：UI 测试
- **关联需求ID**：F-001 / F-006
- **测试数据**：项目根目录
- **测试步骤**：
  1. 在 IDE（VS Code/IDEA）项目树中展开项目根目录，查看 deploy 节点
  2. 在 Windows 文件管理器中打开项目根目录，确认 deploy 目录可见且含 scripts 子目录
  3. 确认本任务未修改任何 Flutter 客户端界面代码（git 变更中无 cloudoffice-flutter-app/lib 下界面文件）
- **预期结果**：
  1. IDE 项目树与文件管理器中均可看到 `deploy` 目录及其 `scripts` 子目录
  2. 客户端应用界面无任何变更（本任务为纯目录/配置任务，无 UI 组件改动）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（UIT-006 UI 测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行：deploy 与 deploy/scripts 在文件系统可见（IDE 项目树/文件管理器可显示）；git 变更清单中无任何 cloudoffice-flutter-app/lib 界面文件改动，客户端 UI 无变更）

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 10 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0（TC-046-3 健康检查为可选子项按设计 SKIP，不构成用例跳过） |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| deploy 已存在但含过期/无效内容 | 复用可能掩盖目录结构问题 | UT-064/FT-011 验证复用不覆盖；迁移任务前人工核对 deploy 内容 |
| 目录大小写不一致（Deploy/DEPLOY） | Windows 不区分大小写但 Linux 区分，部署脚本路径失效 | UT-063 校验全小写命名；编码与检查均固定小写 `deploy` |
| 中间产物误入 deploy | 违反"产物集中、纯净交付"约束 | UT-065 负向校验 target/build 等目录；后续构建配置任务持续回归 |
| 脚本/产物路径引用未适配迁移 | 部署功能失效 | TC-046 关联确认 + TASK-005 脚本迁移任务专项验证 |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-09
- 项目经理（PM）：（待签名）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
