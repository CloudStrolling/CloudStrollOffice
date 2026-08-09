# 测试用例文档（TestCase）— TASK-002
**任务编号**：TASK-002
**任务标题**：迁移 env.json 与 env.example.json 至 deploy 目录
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| env 文件迁移（F-005）：env.json / env.example.json 迁移至 deploy | TASK-002 | 12 | P0×6、P1×6 |
| 其中：单元测试（文件迁移校验） | TASK-002 | 7 | P0×4、P1×3 |
| 其中：接口测试（无接口变更回归确认） | TASK-002 | 1 | P1×1 |
| 其中：功能测试（迁移端到端与边界） | TASK-002 | 3 | P0×2、P1×1 |
| 其中：UI 测试（目录/文件可见性与无 UI 变更） | TASK-002 | 1 | P1×1 |
| **合计** |  | **12** | P0×6、P1×6 |

> 编号说明：延续 v0.0.1 基线（TC-001~045 / UT-001~060 / FT-001~008 / UIT-001~005）与 v0.2.5 TASK-001（UT-061~065 / TC-046 / FT-009~011 / UIT-006），本任务用例从 UT-066、TC-047、FT-012、UIT-007 起编号。

## 二、测试用例详情

### 模块：env 文件迁移（F-005） - 单元测试（文件迁移校验）
#### UT-066：deploy/env.json 存在且为文件类型（P0）
- **用例ID**：UT-066
- **用例名称**：迁移后 deploy 目录下存在 env.json 且为 File 类型
- **所属模块**：deploy / env 文件迁移
- **优先级**：P0
- **前置条件**：TASK-002 编码已完成（env.json 已迁移至 deploy）
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003 / AC-5
- **测试数据**：路径 `<项目根>\deploy\env.json`
- **测试步骤**：
  1. 执行文件存在性校验：`Test-Path -LiteralPath "<项目根>\deploy\env.json" -PathType Leaf`
  2. 记录返回布尔值
- **预期结果**：
  1. 返回 True（deploy/env.json 已存在且为文件类型）
  2. 文件位于 deploy 目录下（迁移目标位置正确）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-066 env.json 存在性校验段，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-unit-test-deploy-v0.2.5.ps1，Test-Path 返回 True，deploy/env.json 为文件类型）

#### UT-067：deploy/env.example.json 存在且为文件类型（P0）
- **用例ID**：UT-067
- **用例名称**：迁移后 deploy 目录下存在 env.example.json 且为 File 类型
- **所属模块**：deploy / env 文件迁移
- **优先级**：P0
- **前置条件**：UT-066 通过（deploy 目录可承载 env 文件）
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003 / AC-5
- **测试数据**：路径 `<项目根>\deploy\env.example.json`
- **测试步骤**：
  1. 执行文件存在性校验：`Test-Path -LiteralPath "<项目根>\deploy\env.example.json" -PathType Leaf`
  2. 记录返回布尔值
- **预期结果**：
  1. 返回 True（deploy/env.example.json 已存在且为文件类型）
  2. 文件位于 deploy 目录下（迁移目标位置正确）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-067 env.example.json 存在性校验段，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-unit-test-deploy-v0.2.5.ps1，Test-Path 返回 True，deploy/env.example.json 为文件类型）

#### UT-068：项目根目录不存在 env.json（P0，负向）
- **用例ID**：UT-068
- **用例名称**：迁移后项目根目录不再保留 env.json
- **所属模块**：项目根目录 / env 文件迁移
- **优先级**：P0
- **前置条件**：UT-066 通过（env.json 已迁移至 deploy）
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003 / AC-5
- **测试数据**：路径 `<项目根>\env.json`
- **测试步骤**：
  1. 执行旧位置存在性校验：`Test-Path -LiteralPath "<项目根>\env.json"`
  2. 记录返回布尔值
- **预期结果**：
  1. 返回 False（项目根目录已不存在 env.json，无残留）
  2. 满足验收 AC-5「项目根目录不再保留 env.json」
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-068 根目录残留校验段，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-unit-test-deploy-v0.2.5.ps1，Test-Path 返回 False，根目录无 env.json 残留，满足 AC-5）

#### UT-069：项目根目录不存在 env.example.json（P0，负向）
- **用例ID**：UT-069
- **用例名称**：迁移后项目根目录不再保留 env.example.json
- **所属模块**：项目根目录 / env 文件迁移
- **优先级**：P0
- **前置条件**：UT-067 通过（env.example.json 已迁移至 deploy）
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003 / AC-5
- **测试数据**：路径 `<项目根>\env.example.json`
- **测试步骤**：
  1. 执行旧位置存在性校验：`Test-Path -LiteralPath "<项目根>\env.example.json"`
  2. 记录返回布尔值
- **预期结果**：
  1. 返回 False（项目根目录已不存在 env.example.json，无残留）
  2. 满足验收 AC-5「项目根目录不再保留 env.example.json」
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-069 根目录残留校验段，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-unit-test-deploy-v0.2.5.ps1，Test-Path 返回 False，根目录无 env.example.json 残留，满足 AC-5）

#### UT-070：迁移无损——env.example.json 内容与迁移前一致（P1）
- **用例ID**：UT-070
- **用例名称**：deploy/env.example.json 与迁移前（git 历史版本）内容一致
- **所属模块**：deploy / env 文件迁移无损性
- **优先级**：P1
- **前置条件**：UT-067 通过；env.example.json 已入库（git 跟踪）
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003（迁移后文件可正常使用）
- **测试数据**：`<项目根>\deploy\env.example.json`、git 历史版本 `HEAD:env.example.json`（迁移前根目录版本）
- **测试步骤**：
  1. 计算当前文件哈希：`Get-FileHash "<项目根>\deploy\env.example.json" -Algorithm SHA256`
  2. 从 git 获取迁移前版本内容：`git show HEAD:env.example.json` 并计算 SHA256
  3. 对比两个哈希值是否一致
- **预期结果**：
  1. 两个 SHA256 哈希完全一致（迁移为纯移动，内容无损、无编码/换行改动）
  2. 迁移后 env.example.json 模板可继续作为 env.json 的生成模板
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-070 哈希一致性校验段，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-unit-test-deploy-v0.2.5.ps1，deploy/env.example.json 哈希与迁移前 git 版本哈希一致，迁移为纯移动无内容改动）

#### UT-071：敏感安全——deploy/env.json 未被 git 跟踪（P1，负向/安全）
- **用例ID**：UT-071
- **用例名称**：迁移后 deploy/env.json 仍命中 .gitignore 忽略规则，不被提交
- **所属模块**：deploy / 敏感信息安全
- **优先级**：P1
- **前置条件**：UT-066 通过；env.json 含真实密钥/密码等敏感值
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003（敏感信息不入库）
- **测试数据**：路径 `<项目根>\deploy\env.json`、git 忽略规则
- **测试步骤**：
  1. 执行忽略规则校验：`git check-ignore -v deploy/env.json`
  2. 执行 `git status --porcelain` 检查 deploy/env.json 是否出现在未跟踪/变更列表中
- **预期结果**：
  1. `git check-ignore -v` 命中 `.gitignore` 中 `env.json` 规则（无路径前缀规则仍匹配 deploy/env.json）
  2. `git status` 不显示 deploy/env.json（敏感文件不入库，未要求跟踪）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-071 敏感文件忽略校验段，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-unit-test-deploy-v0.2.5.ps1，git check-ignore -v 命中忽略规则，git status 未列出 deploy/env.json，敏感信息不入库）

#### UT-072：版本管理——deploy/env.example.json 已被 git 跟踪（P1）
- **用例ID**：UT-072
- **用例名称**：迁移后 deploy/env.example.json 已被 git 跟踪（可入库模板）
- **所属模块**：deploy / 版本管理
- **优先级**：P1
- **前置条件**：UT-070 通过；env.example.json 迁移使用 git mv 或已 git add 新路径
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003（模板文件可入库）
- **测试数据**：git 跟踪列表
- **测试步骤**：
  1. 执行跟踪校验：`git ls-files deploy/env.example.json`
  2. 确认根目录 `git ls-files env.example.json` 无记录（旧路径不再跟踪）
- **预期结果**：
  1. `git ls-files deploy/env.example.json` 返回该文件路径（已被跟踪）
  2. 根目录旧路径无跟踪记录（迁移完成，无重复跟踪）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-072 版本跟踪校验段，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-unit-test-deploy-v0.2.5.ps1，git ls-files 显示 deploy/env.example.json 已被跟踪，根目录旧路径无跟踪记录）

### 模块：env 文件迁移（F-005） - 接口测试（无接口变更回归确认）
#### TC-047：env 文件迁移不影响既有接口契约（P1）
- **用例ID**：TC-047
- **用例名称**：env 配置文件迁移不改变任何 HTTP 接口行为
- **所属模块**：全模块（接口回归确认）
- **优先级**：P1
- **前置条件**：版本 API 文档 `cso-api-v0.2.5.md` 已声明本版本无新增/变更接口
- **测试类型**：接口测试
- **关联需求ID**：F-005 / US-003
- **测试数据**：版本 API 文档（docs/cso-v0.2.5/cso-api-v0.2.5.md）、git 变更清单
- **测试步骤**：
  1. 检查版本 API 文档「接口变更说明」：确认声明「无新增接口、无接口变更、无接口删除」
  2. 检查 git 变更清单：确认 TASK-002 仅移动 env.json / env.example.json 两个配置文件，未触碰任何 Controller / 网关路由 / 接口层代码
  3. （可选）确认 env 文件在 deploy 目录下加载路径——脚本引用适配属 TASK-003 范围，本任务不验证脚本执行
- **预期结果**：
  1. 版本 API 文档明确声明本版本无接口变更
  2. git 变更中无接口层代码文件改动（本任务仅文件移动操作）
  3. 既有 33 个接口（API-001~API-033）契约不受 env 文件迁移影响
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.5.py（test_tc047_env_migration_no_api_change 函数，已落实）
- **测试过程与结论**：通过（2026-08-09，执行 cso-api-test-v0.2.5.py：TC-047-1 文档声明无接口变更 PASS；TC-047-2 git 变更未触碰接口层代码 PASS；TC-047-2b env 迁移之外的变更均为文档/测试脚本、无业务代码改动 PASS；TC-047-3 接口契约 API-001~API-033 完整保留 PASS。注：执行中发现测试脚本 git 路径解析存在 strip 截断缺陷，已由 TE 修复脚本断言并重跑通过，产品代码无缺陷）

### 模块：env 文件迁移（F-005） - 功能测试
#### FT-012：执行迁移后根目录两文件消失、deploy 下出现（P0）
- **用例ID**：FT-012
- **用例名称**：端到端验证 env.json 与 env.example.json 从根目录迁移至 deploy
- **所属模块**：deploy / env 文件迁移
- **优先级**：P0
- **前置条件**：TASK-001 已完成（deploy 目录存在）；项目根目录存在 env.json、env.example.json（迁移前状态）
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-003 / AC-5
- **测试数据**：项目根目录 `<项目根>`、目标目录 `<项目根>\deploy`
- **测试步骤**：
  1. 执行迁移操作：`Move-Item -LiteralPath "<项目根>\env.json" -Destination "<项目根>\deploy\env.json"`；`git mv env.example.json deploy/env.example.json`（或 Move-Item 回退方案）
  2. 校验 `Test-Path "<项目根>\deploy\env.json" -PathType Leaf` 为 True
  3. 校验 `Test-Path "<项目根>\deploy\env.example.json" -PathType Leaf` 为 True
  4. 校验 `Test-Path "<项目根>\env.json"` 为 False、`Test-Path "<项目根>\env.example.json"` 为 False
- **预期结果**：
  1. 迁移操作成功执行无报错
  2. deploy 下存在 env.json 与 env.example.json（文件类型）
  3. 项目根目录不再存在两个文件（满足 AC-5）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-012 功能测试记录段，已落实）
- **测试过程与结论**：通过（2026-08-09，详见 cso-ui-test-record-v0.2.5.md：迁移成功无报错；deploy 下两文件为文件类型；根目录两文件已不存在，满足 AC-5）

#### FT-013：迁移后 env 文件内容完整可解析（P0）
- **用例ID**：FT-013
- **用例名称**：迁移后 deploy 下 env.json 与 env.example.json 为合法 JSON 且键完整
- **所属模块**：deploy / env 文件内容完整性
- **优先级**：P0
- **前置条件**：FT-012 通过（两文件已迁移至 deploy）
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-003（迁移后 env 加载正常）
- **测试数据**：`<项目根>\deploy\env.json`、`<项目根>\deploy\env.example.json`（各含 25 个键）
- **测试步骤**：
  1. 用 `ConvertFrom-Json` 解析 `<项目根>\deploy\env.json`，记录解析是否成功
  2. 用 `ConvertFrom-Json` 解析 `<项目根>\deploy\env.example.json`，记录解析是否成功
  3. 对比两文件键名集合：`(Get-Content deploy\env.json | ConvertFrom-Json).PSObject.Properties.Name` 与模板键清单（25 个键）比对
  4. 注意：不得在测试记录中输出 env.json 的敏感值（密码/密钥）
- **预期结果**：
  1. 两文件均能成功解析为合法 JSON（无语法损坏）
  2. env.json 键名集合与 env.example.json 键名集合一致（25 个键完整，迁移未丢键）
  3. 测试记录中不出现任何敏感值明文
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-013 功能测试记录段，已落实）
- **测试过程与结论**：通过（2026-08-09，详见 cso-ui-test-record-v0.2.5.md：两文件 ConvertFrom-Json 解析成功；env.json 与 env.example.json 键名集合一致（各 25 键，Compare-Object diff=0）；测试记录仅记键名未输出敏感值）

#### FT-014：重复迁移操作的幂等与边界（P1，边界）
- **用例ID**：FT-014
- **用例名称**：目标文件已存在时重复执行迁移不损坏现有内容
- **所属模块**：deploy / env 文件迁移幂等性
- **优先级**：P1
- **前置条件**：FT-012 通过（deploy 下已存在 env.json / env.example.json）
- **测试类型**：功能测试
- **关联需求ID**：F-005 / US-003
- **测试数据**：`<项目根>\deploy\env.json`、`<项目根>\deploy\env.example.json`（迁移后现有文件）
- **测试步骤**：
  1. 记录 deploy 下两文件的当前 SHA256 哈希
  2. 在 deploy 目标已存在的情况下再次执行迁移命令（模拟重复执行）
  3. 校验操作结果：重复执行应被拒绝（目标已存在）或安全跳过，deploy 下文件哈希保持不变、无内容损坏
  4. 校验 deploy 下未产生重复/多余文件（如 env(1).json 之类）
- **预期结果**：
  1. 重复迁移不产生错误级破坏：目标文件内容与哈希保持不变
  2. deploy 下未产生多余副本文件，目录保持纯净
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-014 功能测试记录段，已落实）
- **测试过程与结论**：通过（2026-08-09，详见 cso-ui-test-record-v0.2.5.md：重复迁移安全跳过无报错，env.json 哈希 FFC415AF… 与 env.example.json 哈希 4DE09CC4… 前后一致；deploy 下无重复/多余副本，文件清单仅 .gitkeep、env.example.json、env.json）

### 模块：env 文件迁移（F-005） - UI 测试
#### UIT-007：迁移后在 IDE/文件管理器中可见新位置，客户端 UI 无变更（P1）
- **用例ID**：UIT-007
- **用例名称**：deploy 目录下 env 文件在项目树/文件管理器中可见，根目录不再显示，客户端 UI 无变更
- **所属模块**：deploy / 文件可见性；客户端（无 UI 变更）
- **优先级**：P1
- **前置条件**：FT-012 通过（两文件已迁移至 deploy）
- **测试类型**：UI 测试
- **关联需求ID**：F-005 / US-003
- **测试数据**：项目根目录、deploy 目录
- **测试步骤**：
  1. 在 IDE（VS Code/IDEA）项目树中展开 deploy 目录，查看 env.json 与 env.example.json 节点（注意：env.json 可能因 .gitignore 在部分 IDE 中默认隐藏，以文件管理器为准）
  2. 在 Windows 文件管理器中打开项目根目录，确认根目录不再显示 env.json 与 env.example.json；打开 deploy 目录确认两个文件可见
  3. 确认本任务未修改任何 Flutter 客户端界面代码（git 变更中无 cloudoffice-flutter-app/lib 下界面文件）
- **预期结果**：
  1. 文件管理器中 deploy 目录可见 env.json 与 env.example.json，根目录不再显示两文件
  2. 客户端应用界面无任何变更（本任务为纯文件迁移，无 UI 组件改动）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（UIT-007 UI 测试记录段，已落实）
- **测试过程与结论**：通过（2026-08-09，详见 cso-ui-test-record-v0.2.5.md：deploy 下 env.json/env.example.json 文件系统可见（Test-Path Leaf=True）；根目录不再显示两文件；git 变更中 cloudoffice-flutter-app 相关变更 count=0，客户端 UI 无变更）

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 12 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| env.json 含真实密钥/密码，迁移或测试过程泄露 | 安全事件 | UT-071 校验 .gitignore 忽略；测试记录仅记键名不记敏感值；编码与测试全程遵守红线 |
| 迁移后根目录残留旧文件 | 违反 AC-5，双份配置易导致加载不一致 | UT-068/UT-069 负向校验根目录无残留 |
| 迁移过程内容损坏/编码变化 | env 加载失败导致部署异常 | UT-070 哈希一致性校验 + FT-013 JSON 可解析与键完整性校验 |
| 重复执行迁移造成目标覆盖或多余副本 | 配置被覆盖、目录不纯净 | FT-014 幂等性边界测试 |
| env 文件迁移后脚本引用旧路径失效 | 部署脚本加载 env 失败（属 TASK-003 范围） | TC-047 明确边界：脚本适配由 TASK-003 验证，本任务仅保证文件迁移正确 |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-09
- 项目经理（PM）：（待签名）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
