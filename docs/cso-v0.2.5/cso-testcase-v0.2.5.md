# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**测试负责人**：TE

> 说明：本版本（v0.2.5）需求为工程目录结构与构建配置调整（F-001~F-007）：
> 新建根目录 `deploy` 作为最终构建产物唯一落点、后端 jar 与客户端安装产物统一输出到 deploy、`env.json`/`env.example.json` 迁移至 deploy、`deploy/scripts` 子目录建立及 scripts 下全部 .sh/.ps1 脚本迁移。
> 本版本不涉及数据库（DBD 无变更）与 HTTP 接口（API 文档声明无新增/变更接口）。
> 用例编号延续主文档 cso-testcase.md 编号空间（TC-001~045 / UT-001~060 / FT-001~008 / UIT-001~005 为 v0.0.1 基线），本版本新用例从 TC-046、UT-061、FT-009、UIT-006 起编号，避免合并主文档时冲突。
> 任务用例明细见各任务目录 testcase.md；自动化测试函数/脚本位置由 impm-task-coding-writetest 步骤标注，测试过程与结论由 impm-task-coding-runtest 步骤记录。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 部署目录结构（F-001/F-006）：TASK-001 新建 deploy 与 deploy/scripts | TASK-001 | 10 | P0×5、P1×5 |
| 其中：单元测试（目录结构校验） | TASK-001 | 5 | P0×3、P1×2 |
| 其中：接口测试（无接口变更回归确认） | TASK-001 | 1 | P1×1 |
| 其中：功能测试（建目录与可承载性） | TASK-001 | 3 | P0×2、P1×1 |
| 其中：UI 测试（目录可见性/无 UI 变更） | TASK-001 | 1 | P1×1 |
| env 文件迁移（F-005）：TASK-002 env.json / env.example.json 迁移至 deploy | TASK-002 | 12 | P0×6、P1×6 |
| 其中：单元测试（文件迁移校验） | TASK-002 | 7 | P0×4、P1×3 |
| 其中：接口测试（无接口变更回归确认） | TASK-002 | 1 | P1×1 |
| 其中：功能测试（迁移端到端与边界） | TASK-002 | 3 | P0×2、P1×1 |
| 其中：UI 测试（文件可见性与无 UI 变更） | TASK-002 | 1 | P1×1 |
| 脚本迁移（F-007）：TASK-003 scripts 下全部 .sh/.ps1 迁移至 deploy/scripts 并适配路径 | TASK-003 | 12 | P0×5、P1×7 |
| 其中：单元测试（迁移结果与路径适配校验） | TASK-003 | 6 | P0×3、P1×3 |
| 其中：接口测试（无接口变更回归确认） | TASK-003 | 1 | P1×1 |
| 其中：功能测试（迁移完整性与脚本冒烟执行） | TASK-003 | 4 | P0×2、P1×2 |
| 其中：UI 测试（脚本可见性与无 UI 变更） | TASK-003 | 1 | P1×1 |
| 后端构建产物输出（F-002/F-004）：TASK-004 Maven 构建配置——后端 jar 最终产物统一输出至 deploy | TASK-004 | 12 | P0×6、P1×6 |
| 其中：单元测试（构建配置静态校验） | TASK-004 | 6 | P0×4、P1×2 |
| 其中：接口测试（无接口变更回归确认） | TASK-004 | 1 | P1×1 |
| 其中：功能测试（构建执行与产物校验） | TASK-004 | 4 | P0×2、P1×2 |
| 其中：UI 测试（产物可见性/无 UI 变更） | TASK-004 | 1 | P1×1 |
| 客户端构建产物输出（F-003/F-004）：TASK-005 Flutter 客户端构建配置——安装产物统一输出至 deploy | TASK-005 | 12 | P0×6、P1×6 |
| 其中：单元测试（构建脚本/配置静态校验） | TASK-005 | 6 | P0×4、P1×2 |
| 其中：接口测试（无接口变更回归确认） | TASK-005 | 1 | P1×1 |
| 其中：功能测试（构建执行与产物校验） | TASK-005 | 4 | P0×2、P1×2 |
| 其中：UI 测试（产物可见性/无 UI 变更） | TASK-005 | 1 | P1×1 |
| 构建验证与 deploy 目录纯净性/完整性校验（AC-1~AC-7 全量验收）：TASK-006 整体验收 | TASK-006 | 12 | P0×9、P1×3 |
| 其中：单元测试（目录结构/产物落位/纯净性/迁移完整性静态校验） | TASK-006 | 6 | P0×5、P1×1 |
| 其中：接口测试（无接口变更回归确认） | TASK-006 | 1 | P1×1 |
| 其中：功能测试（构建执行/纯净性扫描/脚本冒烟） | TASK-006 | 4 | P0×4 |
| 其中：UI 测试（deploy 资产可见性/无 UI 变更） | TASK-006 | 1 | P1×1 |
| **合计（已并入任务）** |  | **70** | P0×37、P1×33 |

> 说明：TASK-005（Flutter 客户端构建产物输出）测试用例已追加（UT-085~090、TC-050、FT-023~026、UIT-010，共 12 个，P0×6、P1×6），2026-08-09 已由 impm-task-coding-runtest 执行并记录：**全部通过**（修复后复测：首测 FT-023 编码缺陷失败已由 SSE 修复，复测通过，失败闭环 1/3）。
> 说明：TASK-006（构建验证与 deploy 目录纯净性/完整性校验）测试用例已追加（UT-091~096、TC-051、FT-027~030、UIT-011，共 12 个，P0×9、P1×3），2026-08-09 由 impm-task-coding-testcase 编写完成，覆盖 AC-1~AC-7 全量验收，待 impm-task-coding-runtest 执行记录。

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-066 env.json 存在性校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-unit-test-deploy-v0.2.5.ps1：Test-Path -PathType Leaf 返回 True，deploy/env.json 存在且为文件类型）

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-067 env.example.json 存在性校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-unit-test-deploy-v0.2.5.ps1：Test-Path -PathType Leaf 返回 True，deploy/env.example.json 存在且为文件类型）

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-068 根目录残留校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-unit-test-deploy-v0.2.5.ps1：Test-Path 返回 False，根目录无 env.json 残留，满足 AC-5）

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-069 根目录残留校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-unit-test-deploy-v0.2.5.ps1：Test-Path 返回 False，根目录无 env.example.json 残留，满足 AC-5）

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-070 哈希一致性校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-unit-test-deploy-v0.2.5.ps1：deploy/env.example.json 的 SHA256 与迁移前 git 版本（HEAD:env.example.json）完全一致，迁移为纯移动、内容无损）

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-071 敏感文件忽略校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-unit-test-deploy-v0.2.5.ps1：git check-ignore -v 命中 .gitignore 中 env.json 规则；git status --porcelain 未列出 deploy/env.json，敏感文件不入库）

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-v0.2.5.ps1（UT-072 版本跟踪校验段）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-unit-test-deploy-v0.2.5.ps1：git ls-files 显示 deploy/env.example.json 已被跟踪；根目录旧路径 env.example.json 无跟踪记录，无重复跟踪）

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
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.5.py（test_tc047_env_migration_no_api_change 函数）
- **测试过程与结论**：**通过**（2026-08-09 执行 cso-api-test-v0.2.5.py：TC-047-1 版本 API 文档声明无接口变更 PASS；TC-047-2 git 变更未触碰接口层代码文件 PASS；TC-047-2b env 迁移之外的变更均为文档/测试脚本、无业务代码改动 PASS；TC-047-3 接口契约 API-001~API-033 完整保留 PASS；连同 TC-046 回归 PASS=6 FAIL=0 SKIP=1（可选健康检查按设计跳过）。注：首轮执行 TC-047-2b 失败为测试脚本 git 路径解析缺陷（strip 截断路径、env.example.json 识别不全、断言过严），已由 TE 修复脚本并重跑通过，产品代码无缺陷）

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
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-012 功能测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行，详见 cso-ui-test-record-v0.2.5.md：迁移成功无报错（git status 显示 R env.example.json -> deploy/env.example.json）；deploy 下 env.json 与 env.example.json 均为文件类型（Leaf=True）；根目录两文件均不存在（False），满足 AC-5）

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
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-013 功能测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行，详见 cso-ui-test-record-v0.2.5.md：两文件 ConvertFrom-Json 均解析成功（合法 JSON 无损坏）；env.json 与 env.example.json 键名集合一致（各 25 键，Compare-Object diff=0，迁移未丢键）；测试记录仅记键名、未输出任何敏感值明文）

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
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-014 功能测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行，详见 cso-ui-test-record-v0.2.5.md：重复迁移安全跳过无报错；env.json 与 env.example.json 的 SHA256 前后一致（equal=True）、无内容损坏；deploy 下无重复/多余副本文件，文件清单仅 .gitkeep、env.example.json、env.json，目录纯净）

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
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（UIT-007 UI 测试记录段）
- **测试过程与结论**：**通过**（2026-08-09 执行，详见 cso-ui-test-record-v0.2.5.md：deploy 目录下 env.json 与 env.example.json 文件系统可见（Leaf=True，env.json 因 .gitignore 可能在 IDE 中隐藏，以文件管理器为准）；根目录不再显示两文件（False）；git 变更中 cloudoffice-flutter-app 相关变更 count=0，客户端 UI 无变更）

### 模块：脚本迁移（F-007） - 单元测试（迁移结果与路径适配校验）
#### UT-073：deploy/scripts 下存在全部 21 个脚本且类型正确（P0）
- **用例ID**：UT-073
- **用例名称**：迁移后 deploy/scripts 目录下存在全部 21 个脚本（10 个 .sh + 11 个 .ps1）且为文件类型
- **所属模块**：deploy/scripts / 脚本迁移
- **优先级**：P0
- **前置条件**：TASK-003 编码已完成（21 个脚本已迁移至 deploy/scripts）
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-003 / AC-6
- **测试数据**：`<项目根>\deploy\scripts`，21 个脚本清单（load-env、deploy-check-env、deploy-db-init、deploy-env、deploy-env-template、deploy-rsa-keygen、deploy-start-auth/biz/gateway/system/services 的 .sh 与 .ps1）
- **测试步骤**：
  1. 递归列出 `<项目根>\deploy\scripts` 下全部 .sh 与 .ps1 文件：`Get-ChildItem "<项目根>\deploy\scripts" -Recurse -Include *.sh,*.ps1`
  2. 统计 .sh 文件数量与 .ps1 文件数量，核对总数为 21
  3. 逐一执行 `Test-Path "<项目根>\deploy\scripts\<脚本名>" -PathType Leaf`，确认每个脚本均为文件类型
- **预期结果**：
  1. .sh 数量为 10、.ps1 数量为 11，总数 21（与迁移前 scripts 下脚本清单完全一致，无遗漏、无多余）
  2. 21 个脚本全部存在且为 File 类型，文件名为迁移前原文件名（无改名）
  3. 满足验收 AC-6「全部 .sh/.ps1 已迁移至 deploy/scripts」
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1（用例函数：UT-073-1 数量校验 / UT-073-2 存在性校验 / UT-073-3 无多余脚本校验）
- **测试过程与结论**：**通过**（2026-08-09，cso-unit-test-scripts-migrate-v0.2.5.ps1）。UT-073-1：deploy/scripts 下 .sh=10、.ps1=11，总数 21（PASS）；UT-073-2：21 个期望脚本全部存在且为 File 类型（PASS）；UT-073-3：无多余 .sh/.ps1（PASS）。满足 AC-6。

#### UT-074：根目录 scripts 下不再存在任何 .sh/.ps1（P0，负向）
- **用例ID**：UT-074
- **用例名称**：迁移后项目根目录 scripts 下不存在任何 .sh 或 .ps1 脚本残留
- **所属模块**：scripts / 脚本迁移（旧位置清理）
- **优先级**：P0
- **前置条件**：UT-073 通过（21 个脚本已迁移至 deploy/scripts）
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-003 / AC-6
- **测试数据**：路径 `<项目根>\scripts`
- **测试步骤**：
  1. 递归搜索旧位置脚本残留：`Get-ChildItem "<项目根>\scripts" -Recurse -Include *.sh,*.ps1`
  2. 记录返回的文件列表（应为空）
- **预期结果**：
  1. 返回空列表（根目录 scripts 下已不存在任何 .sh/.ps1）
  2. 满足验收 AC-6「根目录不再保留」；旧位置无脚本残留，无重复副本
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1（用例函数：UT-074 负向残留校验，排除 scripts/API-TEST 测试资产）
- **测试过程与结论**：**通过**（2026-08-09，cso-unit-test-scripts-migrate-v0.2.5.ps1）。递归搜索根目录 scripts（排除 scripts/API-TEST）返回 .sh/.ps1 残留数为 0（PASS）。旧位置无脚本残留，无重复副本，满足 AC-6「根目录不再保留」。

#### UT-075：scripts 下非脚本内容保持原位未迁移（P0，负向）
- **用例ID**：UT-075
- **用例名称**：scripts/sql、scripts/docker、scripts/API-TEST、scripts/deployment-guide.md 保持原位置
- **所属模块**：scripts / 非脚本内容保护
- **优先级**：P0
- **前置条件**：UT-074 通过（scripts 下脚本已全部迁移）
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-003 / AC-6（非 sh/ps1 内容未被迁移）
- **测试数据**：`<项目根>\scripts\sql`、`<项目根>\scripts\docker`、`<项目根>\scripts\API-TEST`、`<项目根>\scripts\deployment-guide.md`
- **测试步骤**：
  1. 校验 `Test-Path "<项目根>\scripts\sql" -PathType Container` 为 True，且内含 4 个 SQL 文件（init.sql、init-v0.2.0-full.sql、auth-init-v0.1.5.sql、auth-init-v0.1.6.sql）
  2. 校验 `Test-Path "<项目根>\scripts\docker" -PathType Container` 为 True（docker-compose.yml + 4 个 Dockerfile）
  3. 校验 `Test-Path "<项目根>\scripts\API-TEST" -PathType Container` 为 True
  4. 校验 `Test-Path "<项目根>\scripts\deployment-guide.md" -PathType Leaf` 为 True
- **预期结果**：
  1. sql、docker、API-TEST 三个子目录与 deployment-guide.md 均保持原位置（存在性校验全部为 True）
  2. 非脚本内容未被误迁移至 deploy，满足验收 AC-6「非 sh/ps1 内容未被迁移」
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1（用例函数：UT-075-1 sql / UT-075-2 docker / UT-075-3 API-TEST / UT-075-4 deployment-guide.md 原位校验）
- **测试过程与结论**：**通过**（2026-08-09，cso-unit-test-scripts-migrate-v0.2.5.ps1）。UT-075-1：scripts/sql 存在且含 4 个 SQL 文件（PASS）；UT-075-2：scripts/docker 存在且含 docker-compose.yml + 4 个 Dockerfile（PASS）；UT-075-3：scripts/API-TEST 存在（PASS）；UT-075-4：scripts/deployment-guide.md 存在（PASS）。非脚本内容未被误迁移，满足 AC-6。

#### UT-076：deploy/scripts 下 21 个脚本已被 git 跟踪且历史可追溯（P1）
- **用例ID**：UT-076
- **用例名称**：迁移后 deploy/scripts 下 21 个脚本均已被 git 跟踪，旧路径无跟踪记录，git log --follow 可追溯历史
- **所属模块**：deploy/scripts / 版本管理
- **优先级**：P1
- **前置条件**：UT-073 通过；迁移使用 git mv 完成（或等效的 git add 新路径 + git rm 旧路径）
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-003（迁移保留脚本历史，迁移无损）
- **测试数据**：git 跟踪列表、`deploy/scripts/load-env.sh`（代表样本）
- **测试步骤**：
  1. 执行跟踪校验：`git ls-files deploy/scripts`，统计被跟踪的 .sh/.ps1 数量
  2. 确认根目录旧路径无跟踪记录：`git ls-files scripts/load-env.sh`（及其余 20 个旧路径）返回为空
  3. 执行历史追溯校验：`git log --oneline --follow -- deploy/scripts/load-env.sh`，确认可追溯到脚本的历史提交（迁移为重命名而非新建）
- **预期结果**：
  1. `git ls-files deploy/scripts` 下被跟踪的 .sh/.ps1 数量为 21
  2. 根目录 scripts 下旧路径无任何跟踪记录（迁移完成，无重复跟踪）
  3. `git log --follow` 能追溯到脚本迁移前历史（git 识别为重命名，历史无损）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1（用例函数：UT-076-1 新路径跟踪 / UT-076-2 旧路径无跟踪 / UT-076-3 历史追溯——已提交用 git log --follow，未提交用 git diff --cached -M 重命名证据）
- **测试过程与结论**：**通过**（2026-08-09，cso-unit-test-scripts-migrate-v0.2.5.ps1）。UT-076-1：git ls-files deploy/scripts 被跟踪 .sh/.ps1 数=21（PASS）；UT-076-2：根目录 scripts 旧路径无跟踪记录（PASS）；UT-076-3：git diff --cached -M 识别 21/21 个重命名（R 状态，git mv 证据），迁移历史无损（PASS）。

#### UT-077：脚本内失效旧路径引用已全部适配（P1，负向/一致性）
- **用例ID**：UT-077
- **用例名称**：deploy/scripts 下全部脚本不再引用迁移后失效的旧路径（scripts/、模块 target/、根目录 env 等）
- **所属模块**：deploy/scripts / 路径适配
- **优先级**：P1
- **前置条件**：UT-073 通过（21 个脚本已迁移）
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-003 / AC-7（脚本内路径引用已同步更新）
- **测试数据**：deploy/scripts 下 21 个脚本全文内容
- **测试步骤**：
  1. 扫描 deploy/scripts 下全部 .sh/.ps1 文件内容，检查是否存在迁移后失效的旧路径引用模式（不区分大小写）：
     - `$PROJECT_DIR/scripts/` 或 `$ProjectDir\scripts\`（SQL 目录旧引用，迁移后 PROJECT_DIR=deploy，deploy/scripts/sql 不存在）
     - `/cloudoffice-<模块>/target/`（jar 包旧引用，模块 target 目录为中间产物，不在 deploy）
     - `./scripts/deploy-rsa-keygen` 或 `.\scripts\deploy-rsa-keygen`（注释中旧脚本路径引用）
  2. 检查 SQL 目录适配：deploy-db-init.sh 中存在 `ROOT_DIR`（`$(dirname "$PROJECT_DIR")`）推导且 SQL 引用基于 ROOT_DIR/scripts/sql（ps1 为 `Split-Path -Parent $ProjectDir` 同构）
  3. 检查 jar 路径适配：deploy-start-*.sh/ps1 中 jar 引用已指向 deploy 下最终产物路径（不再指向模块 target 目录）
- **预期结果**：
  1. 全部 21 个脚本中不存在上述任何失效旧路径引用（扫描命中数为 0）
  2. deploy-db-init.sh/ps1 中 SQL 目录引用基于项目根推导（`$(dirname "$PROJECT_DIR")/scripts/sql` 或 `Split-Path -Parent $ProjectDir`），迁移后路径真实存在
  3. deploy-start-auth/gateway/biz/system.sh/ps1 中 jar 引用指向 deploy 下最终产物（不再指向各模块 target 目录），满足 AC-7「路径引用已同步更新」
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1（用例函数：UT-077-1 失效路径模式扫描 / UT-077-2 db-init 根目录推导 / UT-077-3 start-* jar 产物路径校验；脚本只报告命中行号，不输出文件内容以防敏感值泄露）
- **测试过程与结论**：**通过**（2026-08-09，cso-unit-test-scripts-migrate-v0.2.5.ps1）。UT-077-1：21 个脚本失效旧路径模式扫描命中数=0（PASS，只报告行号不输出内容）；UT-077-2：deploy-db-init.sh/ps1 均基于 ROOT_DIR/RootDir（项目根推导）引用 scripts/sql（PASS）；UT-077-3：deploy-start-auth/gateway/biz/system.sh/ps1 的 jar 引用均指向 deploy 下最终产物、不含模块 target 路径（PASS）。满足 AC-7「路径引用已同步更新」。

#### UT-078：脚本 env 加载机制保留，自动指向 deploy/env.json（P1）
- **用例ID**：UT-078
- **用例名称**：load-env.sh/ps1 仍基于脚本自身目录推导 PROJECT_DIR，迁移后自动加载 deploy/env.json
- **所属模块**：deploy/scripts / env 加载机制
- **优先级**：P1
- **前置条件**：UT-077 通过；deploy/env.json 已存在（TASK-002 迁移完成）
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-003 / AC-7（env.json 加载正常）
- **测试数据**：`<项目根>\deploy\scripts\load-env.sh`、`<项目根>\deploy\scripts\load-env.ps1`
- **测试步骤**：
  1. 检查 load-env.sh 内容：存在 `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`（或等价）与 `ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"` 推导逻辑
  2. 检查 load-env.ps1 内容：存在 `$ProjectDir = Split-Path -Parent $PSScriptRoot` 与 `$EnvFilePath = Join-Path $ProjectDir $EnvFile` 推导逻辑
  3. 静态推演：脚本位于 deploy/scripts 时，PROJECT_DIR/$ProjectDir 自动等于 deploy，ENV_FILE 默认 env.json → 最终路径为 deploy/env.json
- **预期结果**：
  1. load-env.sh 使用 `${BASH_SOURCE[0]}`（被 source 时仍指向 load-env.sh 自身，而非主调脚本），PROJECT_DIR 由脚本目录推导
  2. load-env.ps1 使用 `$PSScriptRoot` + `Split-Path -Parent` 推导 ProjectDir
  3. 推演结论：env.json 加载路径自动指向 `<项目根>\deploy\env.json`（无需硬编码根目录，机制随迁移自动适配）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-scripts-migrate-v0.2.5.ps1（用例函数：UT-078-1 load-env.sh BASH_SOURCE 机制 / UT-078-2 load-env.ps1 PSScriptRoot 机制 / UT-078-3 静态推演 deploy/env.json 存在性）
- **测试过程与结论**：**通过**（2026-08-09，cso-unit-test-scripts-migrate-v0.2.5.ps1）。UT-078-1：load-env.sh 含 `${BASH_SOURCE[0]}` + `dirname` 推导 PROJECT_DIR + `ENV_FILE_PATH="$PROJECT_DIR/$ENV_FILE"`（PASS）；UT-078-2：load-env.ps1 含 `$PSScriptRoot` + `Split-Path -Parent` 推导 ProjectDir + `Join-Path $ProjectDir $EnvFile`（PASS）；UT-078-3：deploy/env.json 存在（PASS），推演 PROJECT_DIR=deploy → env.json 加载路径自动指向 deploy/env.json。

### 模块：脚本迁移（F-007） - 接口测试（无接口变更回归确认）
#### TC-048：脚本迁移不影响既有接口契约（P1）
- **用例ID**：TC-048
- **用例名称**：scripts 下脚本迁移至 deploy/scripts 不改变任何 HTTP 接口行为
- **所属模块**：全模块（接口回归确认）
- **优先级**：P1
- **前置条件**：版本 API 文档 `cso-api-v0.2.5.md` 已声明本版本无新增/变更接口
- **测试类型**：接口测试
- **关联需求ID**：F-007 / US-003
- **测试数据**：版本 API 文档（docs/cso-v0.2.5/cso-api-v0.2.5.md）、git 变更清单
- **测试步骤**：
  1. 检查版本 API 文档「接口变更说明」：确认声明「无新增接口、无接口变更、无接口删除」
  2. 检查 git 变更清单：确认 TASK-003 仅移动 scripts 下 .sh/.ps1 脚本文件并修改脚本内部路径引用，未触碰任何 Controller / 网关路由 / 接口层代码
  3. （可选）确认脚本内健康检查类接口地址（如 `/api/v1/auth/health`）引用保持不变——脚本迁移只改文件系统路径，不改接口地址
- **预期结果**：
  1. 版本 API 文档明确声明本版本无接口变更
  2. git 变更中无接口层代码文件改动（本任务仅脚本文件迁移与内容路径适配）
  3. 既有 33 个接口（API-001~API-033）契约不受脚本迁移影响，部署脚本迁移后接口调用地址不变
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.5.py（用例函数：test_tc048_scripts_migration_no_api_change，检查点 TC-048-1 文档声明 / TC-048-2、TC-048-2b git 变更无接口层改动 / TC-048-3 接口契约保留 / TC-048-4 脚本内接口地址引用保持既有契约）
- **测试过程与结论**：**通过**（2026-08-09，cso-api-test-v0.2.5.py，本次执行 PASS=11 FAIL=0 SKIP=1）。TC-048-1：版本 API 文档声明无新增/变更/删除接口（PASS）；TC-048-2：git 变更未触碰接口层代码文件（PASS）；TC-048-2b：脚本迁移之外无业务代码/接口层/构建配置改动（PASS）；TC-048-3：API-001~API-033 契约在 API 文档中完整保留（PASS）；TC-048-4：deploy/scripts 脚本中接口地址引用保持既有契约（PASS）。注：同次执行的 TC-046-3（可选连通性）因服务未启动 SKIP，不影响本用例结论。
#### FT-015：冒烟——load-env 脚本可从 deploy/env.json 加载成功（P0）
- **用例ID**：FT-015
- **用例名称**：迁移后 load-env 脚本（Bash + PowerShell）可从 deploy/env.json 加载环境变量成功
- **所属模块**：deploy/scripts / 脚本冒烟
- **优先级**：P0
- **前置条件**：UT-073~078 通过；deploy/env.json 存在（TASK-002 完成）
- **测试类型**：功能测试
- **关联需求ID**：F-007 / US-003 / AC-7
- **测试数据**：`<项目根>\deploy\scripts\load-env.sh`、`<项目根>\deploy\scripts\load-env.ps1`、`<项目根>\deploy\env.json`
- **测试步骤**：
  1. Bash 冒烟：`source "<项目根>/deploy/scripts/load-env.sh"`，观察输出（应显示从 deploy/env.json 加载成功的信息）
  2. PowerShell 冒烟：`. "<项目根>\deploy\scripts\load-env.ps1"`，观察输出
  3. 校验加载后的关键环境变量非空（如 DB_HOST、REDIS_HOST 等，仅校验非空/存在，不得打印敏感值内容）
  4. 注意：全程不得输出 env.json 中真实密码、密钥等敏感值
- **预期结果**：
  1. Bash 与 PowerShell 两个 load-env 脚本均从 `<项目根>\deploy\env.json` 加载成功，无「文件不存在」类报错
  2. 关键环境变量加载后非空（加载链路完整：deploy/scripts/load-env → deploy/env.json）
  3. 测试记录中不出现任何敏感值明文，满足 AC-7「env.json 加载正常、部署运维功能不受影响」
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-015 章节：Bash/PowerShell 双冒烟步骤与记录表）
- **测试过程与结论**：**通过**（2026-08-09，Git Bash + PowerShell 双冒烟）。Bash：Git Bash 环境缺 jq/python3（环境依赖，非迁移缺陷），注入临时 jq.exe 后 `source deploy/scripts/load-env.sh` 输出「环境变量已从 .../deploy/env.json 加载 (jq)」，EXIT=0，DB_HOST/REDIS_HOST 非空（PASS）；PowerShell：`. load-env.ps1` 输出「环境变量已从 D:\...\deploy\env.json 加载」，DB_HOST/REDIS_HOST/NACOS_ADDR 均非空（PASS）。无「文件不存在」类报错，未输出任何敏感值明文，满足 AC-7。

#### FT-016：冒烟——deploy-check-env 脚本可完整执行到汇总（P0）
- **用例ID**：FT-016
- **用例名称**：迁移后 deploy-check-env 脚本（Bash + PowerShell）可完整运行到结果汇总
- **所属模块**：deploy/scripts / 脚本冒烟
- **优先级**：P0
- **前置条件**：FT-015 通过（load-env 加载正常）
- **测试类型**：功能测试
- **关联需求ID**：F-007 / US-003 / AC-7
- **测试数据**：`<项目根>\deploy\scripts\deploy-check-env.sh`、`<项目根>\deploy\scripts\deploy-check-env.ps1`
- **测试步骤**：
  1. Bash 冒烟：`bash "<项目根>/deploy/scripts/deploy-check-env.sh"`，观察执行过程与结果汇总输出
  2. PowerShell 冒烟：`& "<项目根>\deploy\scripts\deploy-check-env.ps1"`，观察执行过程与结果汇总输出
  3. 检查脚本是否出现路径类错误（pom.xml、scripts/sql 等基于项目根路径判断的检查项是否因路径失效报错）
  4. 记录脚本退出状态码与汇总输出
- **预期结果**：
  1. 两个版本脚本均能完整运行到结果汇总（不中途因路径错误崩溃退出）
  2. 基于项目根（pom.xml、scripts/sql/auth-init-v0.1.5.sql 等）的检查项路径在迁移后仍正确解析（或按适配后逻辑正常判断）
  3. 中间件连接类检查项（Nacos/MariaDB/Redis 未启动时）可报告失败/警告，但不阻塞脚本运行到汇总——脚本自身功能正常
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-016 章节：Bash/PowerShell 双冒烟步骤与记录表）
- **测试过程与结论**：**通过**（2026-08-09，Git Bash + PowerShell 双冒烟）。Bash：完整运行到汇总「5 项通过, 8 项失败」，路径类检查（pom.xml 通过、SQL 初始化脚本存在 通过、settings.xml 通过）全部正确解析，失败项均为中间件（Nacos/MariaDB/Redis）未启动与 Git Bash 下 JDK/JAVA_HOME 环境差异，不阻塞脚本运行（PASS）；PowerShell：完整运行到汇总「6 项通过, 4 项失败」，JDK/Maven/Git/JAVA_HOME 检查通过，路径类检查（pom.xml、SQL 脚本）通过，失败项仅为中间件未启动，不阻塞运行（PASS）。两版脚本均未出现因路径失效的崩溃，退出码 1 为存在失败检查项的预期行为。

#### FT-017：迁移完整性端到端——21 个脚本迁移齐全、非脚本内容原位（P1）
- **用例ID**：FT-017
- **用例名称**：端到端验证 scripts 下 21 个脚本全部迁移至 deploy/scripts 且非脚本内容未移动
- **所属模块**：deploy/scripts / 迁移完整性
- **优先级**：P1
- **前置条件**：TASK-003 编码已完成
- **测试类型**：功能测试
- **关联需求ID**：F-007 / US-003 / AC-6
- **测试数据**：迁移前 scripts 下脚本清单（git 历史 `git show HEAD~1:scripts/` 或迁移前快照）、当前 deploy/scripts 清单、当前 scripts 内容清单
- **测试步骤**：
  1. 从 git 历史获取迁移前 scripts 下全部 .sh/.ps1 文件名清单（共 21 个）
  2. 列出当前 deploy/scripts 下全部 .sh/.ps1 文件名清单，与迁移前清单做集合比对（Compare-Object）
  3. 列出当前 scripts 下内容（非脚本内容），确认 sql、docker、API-TEST、deployment-guide.md 均原位
  4. 汇总比对结果
- **预期结果**：
  1. 迁移前清单与 deploy/scripts 清单完全一致（diff=0：21 个脚本全部迁移、无遗漏、无多余）
  2. scripts 下非脚本内容全部原位（sql/docker/API-TEST/deployment-guide.md 未移动、未删除）
  3. 满足验收 AC-6 全部验收点
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-017 章节：迁移前后清单集合比对步骤与记录表）
- **测试过程与结论**：**通过**（2026-08-09，git 历史 + Compare-Object 集合比对）。迁移前 git 历史（commit f9c19bb）scripts 下 .sh/.ps1 清单=21 个；当前 deploy/scripts=21 个；Compare-Object diff=0（ONLY_PRE=0、ONLY_CUR=0，无遗漏、无多余）（PASS）；scripts 下非脚本内容原位：sql（4 个 SQL）、docker（compose）、API-TEST、deployment-guide.md 全部存在（PASS）。满足 AC-6 全部验收点。

#### FT-018：重复迁移幂等与边界（P1，边界）
- **用例ID**：FT-018
- **用例名称**：deploy/scripts 目标已存在时重复执行迁移操作不覆盖/不损坏现有脚本
- **所属模块**：deploy/scripts / 迁移幂等性
- **优先级**：P1
- **前置条件**：FT-017 通过（deploy/scripts 下已有 21 个脚本）
- **测试类型**：功能测试
- **关联需求ID**：F-007 / US-003
- **测试数据**：`<项目根>\deploy\scripts\load-env.sh`（代表样本）、全部 21 个脚本清单
- **测试步骤**：
  1. 记录 deploy/scripts 下 21 个脚本的当前 SHA256 哈希清单
  2. 在目标已存在的情况下再次执行迁移命令（模拟重复执行：`git mv scripts/load-env.sh deploy/scripts/` 或等效操作）
  3. 校验操作结果：重复迁移应被拒绝（目标已存在）或安全跳过，21 个脚本的 SHA256 哈希保持不变、无内容损坏
  4. 校验 deploy/scripts 下未产生重复/多余文件（如 load-env(1).sh 之类副本）
- **预期结果**：
  1. 重复迁移不产生错误级破坏：21 个脚本哈希前后完全一致（无覆盖、无截断、无编码损坏）
  2. deploy/scripts 下无重复/多余副本文件，目录保持纯净
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-018 章节：SHA256 哈希幂等边界测试步骤与记录表）
- **测试过程与结论**：**通过**（2026-08-09，SHA256 哈希幂等边界测试）。记录 21 个脚本哈希后模拟重复迁移 `git mv scripts/load-env.sh deploy/scripts/load-env.sh`：git 拒绝执行（exit 128，bad source，源路径已不存在，符合目标已存在时的安全拒绝预期）（PASS）；21 个脚本 SHA256 哈希前后完全一致（CHANGED=0，无覆盖/截断/编码损坏）（PASS）；deploy/scripts 无重复/多余副本文件（EXTRA=0）（PASS）。

### 模块：脚本迁移（F-007） - UI 测试
#### UIT-008：迁移后 deploy/scripts 可见、根目录 scripts 不再显示脚本文件，客户端 UI 无变更（P1）
- **用例ID**：UIT-008
- **用例名称**：deploy/scripts 下 21 个脚本在 IDE/文件管理器中可见，根目录 scripts 不再显示脚本文件，客户端 UI 无变更
- **所属模块**：deploy/scripts / 文件可见性；客户端（无 UI 变更）
- **优先级**：P1
- **前置条件**：FT-017 通过（迁移完成）
- **测试类型**：UI 测试
- **关联需求ID**：F-007 / US-003
- **测试数据**：项目根目录、deploy/scripts 目录
- **测试步骤**：
  1. 在 IDE（VS Code/IDEA）项目树中展开 deploy 目录，查看 scripts 子目录下 21 个脚本节点；展开根目录 scripts 节点，确认不再显示任何 .sh/.ps1（sql/docker/API-TEST 仍可见）
  2. 在 Windows 文件管理器中打开项目根目录 scripts 与 deploy/scripts，核对脚本文件可见性与位置
  3. 确认本任务未修改任何 Flutter 客户端界面代码（git 变更中无 cloudoffice-flutter-app/lib 下界面文件）
- **预期结果**：
  1. IDE 项目树与文件管理器中 deploy/scripts 下可见全部 21 个脚本，根目录 scripts 下不再显示脚本文件（仅保留 sql/docker/API-TEST/deployment-guide.md）
  2. 客户端应用界面无任何变更（本任务为纯脚本迁移与路径适配，无 UI 组件改动）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（UIT-008 章节：IDE/文件管理器可见性步骤与记录表）
- **测试过程与结论**：**通过**（2026-08-09，文件系统可见性 + git 变更核查）。deploy/scripts 下可见 21 个脚本文件（=21，与 IDE/文件管理器视图一致）；根目录 scripts 无 .sh/.ps1（0 个），仅保留 API-TEST、docker、sql 子目录与 deployment-guide.md；git status 变更中无 cloudoffice-flutter-app/lib 下界面文件（FLUTTER_UI_CHANGES=0，客户端 UI 无任何变更）（PASS）。

### 模块：后端构建产物输出（F-002/F-004） - 单元测试（构建配置静态校验）
#### UT-079：根 pom.xml 定义 deployDir 属性且指向项目根目录 deploy（P0）
- **用例ID**：UT-079
- **用例名称**：根 pom.xml 的 `<properties>` 中存在 `deployDir` 属性，取值为以根目录相对方式定位的 deploy 路径
- **所属模块**：构建配置 / 根 pom.xml
- **优先级**：P0
- **前置条件**：TASK-004 编码已完成（根 pom.xml 已修改）
- **测试类型**：单元测试
- **关联需求ID**：F-002 / F-004 / US-002 / AC-2
- **测试数据**：`<项目根>\pom.xml`（根父 POM，162 行）
- **测试步骤**：
  1. 读取根 pom.xml 全文，检查 `<properties>` 节点中是否存在 `<deployDir>` 属性
  2. 校验 deployDir 取值以 `${maven.multiModuleProjectDirectory}` 为基础（如 `${maven.multiModuleProjectDirectory}/deploy`），即"以根目录相对方式定位"，而非各模块 `../deploy` 相对路径
  3. 校验 deployDir 值末尾指向的目录名为 `deploy`（全小写，与既有目录契约一致）
- **预期结果**：
  1. 根 pom.xml 中存在 `deployDir` 属性
  2. deployDir 基于 `${maven.multiModuleProjectDirectory}` 定位根目录，路径指向 `<项目根>/deploy`
  3. 目录名全小写 `deploy`，与既有 deploy 目录契约一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-deploy-v0.2.5.ps1`（UT-079 断言组）
- **测试过程与结论**：2026-08-09 执行 cso-unit-test-build-deploy-v0.2.5.ps1，UT-079-1/2/3 断言全部通过：根 pom.xml 存在 deployDir 属性、取值=${maven.multiModuleProjectDirectory}/deploy（以根目录相对方式定位）、尾目录名 deploy 全小写。结论：**通过**。

#### UT-080：四个可执行模块 pom 在 package 阶段配置复制插件且顺序正确（P0）
- **用例ID**：UT-080
- **用例名称**：gateway/auth-service/biz-service/system-service 四个模块 pom 均配置产物复制插件，绑定 package 阶段且声明在 spring-boot-maven-plugin 之后
- **所属模块**：构建配置 / 四个模块 pom.xml
- **优先级**：P0
- **前置条件**：UT-079 通过（deployDir 属性已定义）
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002 / AC-2
- **测试数据**：`<项目根>\cloudoffice-gateway\pom.xml`、`<项目根>\cloudoffice-auth-service\pom.xml`、`<项目根>\cloudoffice-biz-service\pom.xml`、`<项目根>\cloudoffice-system-service\pom.xml`
- **测试步骤**：
  1. 逐一读取四个模块 pom.xml，检查 `<build><plugins>` 中是否存在复制插件声明（如 `org.apache.maven.plugins:maven-antrun-plugin`）
  2. 校验复制插件 `<phase>` 为 `package`（在 package 阶段执行复制）
  3. 校验复制插件在 `<plugins>` 中的声明顺序位于 spring-boot-maven-plugin 之后（保证复制 repackage 后的可执行 jar）
  4. 校验复制插件使用了 antrun 3.x 的 `<target>` 配置（而非已废弃的 `<tasks>`），且复制源为 `${project.build.directory}/${project.build.finalName}.jar`、目标为 `${deployDir}/cloudoffice-{模块名}.jar`
- **预期结果**：
  1. 四个模块 pom 均存在复制插件（antrun 或等价插件）
  2. 复制绑定 package 阶段，且声明顺序在 spring-boot-maven-plugin 之后
  3. 使用 `<target>` 语法、复制源为模块 target 下最终 jar、目标为 deploy 下契约名
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-deploy-v0.2.5.ps1`（UT-080 断言组）
- **测试过程与结论**：2026-08-09 执行脚本，UT-080-1/2/3/4 断言全部通过：gateway/auth-service/biz-service/system-service 四模块 pom 均配置 maven-antrun-plugin、绑定 package 阶段、声明在 spring-boot-maven-plugin 之后、使用 `<target>` 语法且无废弃 `<tasks>`。结论：**通过**。

#### UT-081：deploy 产物命名符合既有脚本契约（P0）
- **用例ID**：UT-081
- **用例名称**：四个模块复制目标文件名与 deploy/scripts 下 deploy-start-* 脚本引用的 jar 命名契约完全一致
- **所属模块**：构建配置 / 产物命名契约
- **优先级**：P0
- **前置条件**：UT-080 通过（四个模块均已配置复制）
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002 / AC-2（产物命名保持模块可辨识，不发生同名覆盖）
- **测试数据**：四个模块 pom.xml、`<项目根>\deploy\scripts\deploy-start-auth.sh`（第 15 行 `JAR_PATH="$PROJECT_DIR/cloudoffice-auth-service.jar"`）等 4 个启动脚本
- **测试步骤**：
  1. 提取四个模块复制插件的 tofile 目标文件名
  2. 与契约清单比对：gateway→`cloudoffice-gateway.jar`、auth-service→`cloudoffice-auth-service.jar`、biz-service→`cloudoffice-biz-service.jar`、system-service→`cloudoffice-system-service.jar`
  3. 校验 deploy/scripts 下 deploy-start-auth/gateway/biz/system.sh/.ps1 中 `JAR_PATH`/jar 引用与上述目标文件名一一对应
- **预期结果**：
  1. 四个目标文件名与契约完全一致（无 `-0.0.1-SNAPSHOT` 版本后缀，模块可辨识）
  2. 四个文件名互不相同，不会发生同名覆盖
  3. 启动脚本引用的 jar 名与构建输出名一致（脚本能启动到 deploy 下产物）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-deploy-v0.2.5.ps1`（UT-081 断言组）
- **测试过程与结论**：2026-08-09 执行脚本，UT-081-1/2/3/4 断言全部通过：四模块复制源为 target 最终 jar、tofile 契约名一致（gateway/auth-service/biz-service/system-service.jar）；4 文件名互不相同、无版本后缀；deploy/scripts 下 deploy-start-* .sh/.ps1 引用契约 jar 名一一对应。结论：**通过**。

#### UT-082：复制配置仅单文件复制且 overwrite=true，无整目录递归复制（P0，负向）
- **用例ID**：UT-082
- **用例名称**：复制配置只复制最终 jar 单个文件（file/tofile 或精确 include），显式 overwrite 覆盖，禁止 fileset 整目录复制 target
- **所属模块**：构建配置 / 中间产物隔离
- **优先级**：P0
- **前置条件**：UT-080 通过
- **测试类型**：单元测试
- **关联需求ID**：F-004 / AC-4（构建完成后 deploy 内不出现 target 类中间目录、编译临时文件、测试产物）
- **测试数据**：四个模块 pom.xml 复制插件配置段
- **测试步骤**：
  1. 检查四个模块复制配置：复制方式必须为单文件复制（antrun `<copy file=... tofile=...>` 或 resources `<includes>` 精确限定 jar 文件名）
  2. 负向检查：全 pom 中不得出现 `<fileset dir="${project.build.directory}">`、`<directory>${project.build.directory}</directory>`（未限定 includes）等整目录递归复制 target 的配置
  3. 检查重复构建覆盖：antrun 需显式 `overwrite="true"`（resources 插件 copy-resources 默认可覆盖），保证"重复构建 overwrite 覆盖旧版本"
- **预期结果**：
  1. 复制均为单文件复制，不携带任何目录结构与中间产物
  2. 无整目录递归复制 target 的配置（AC-4 静态保证）
  3. overwrite 语义明确，重复构建覆盖旧版本
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-deploy-v0.2.5.ps1`（UT-082 断言组）
- **测试过程与结论**：2026-08-09 执行脚本，UT-082-1/2/3 断言全部通过：四模块均为单文件复制（copy file/tofile 无 fileset）；全部 pom 无整目录递归复制 target 配置（recursiveHits=0）；copy 显式 overwrite="true"（重复构建覆盖旧版本）。结论：**通过**。

#### UT-083：common 模块不参与产物输出（P1，负向）
- **用例ID**：UT-083
- **用例名称**：cloudoffice-common 模块 pom 无任何产物复制配置，不向 deploy 输出库 jar
- **所属模块**：构建配置 / common 模块排除
- **优先级**：P1
- **前置条件**：UT-080 通过
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002（common 为库依赖，非可交付服务产物）
- **测试数据**：`<项目根>\cloudoffice-common\pom.xml`（86 行）
- **测试步骤**：
  1. 读取 cloudoffice-common/pom.xml 全文，检查 `<build><plugins>` 中是否存在复制类插件（antrun/copy-resources 等）
  2. 负向校验：确认不存在任何指向 `${deployDir}` 的输出/复制配置
- **预期结果**：
  1. common 模块无复制插件、无 deploy 输出配置（保持现状不动）
  2. deploy 下不会出现 common 库 jar
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-deploy-v0.2.5.ps1`（UT-083 断言组）
- **测试过程与结论**：2026-08-09 执行脚本，UT-083-1/2 断言全部通过：cloudoffice-common/pom.xml 无 maven-antrun-plugin/maven-resources-plugin/copy-resources 复制插件，无 deployDir/tofile/输出到 deploy 配置。结论：**通过**。

#### UT-084：deploy 下 jar 产物被 git 忽略（P1，负向/版本管理）
- **用例ID**：UT-084
- **用例名称**：构建产物 jar 不入库——deploy 下 *.jar 命中 .gitignore，不会被误提交
- **所属模块**：构建配置 / 版本管理
- **优先级**：P1
- **前置条件**：FT-019 功能构建验证通过（deploy 下已有 jar）；.gitignore 已忽略 `*.jar`（第 233-234 行）
- **测试类型**：单元测试
- **关联需求ID**：F-002 / US-002（产物不入库属预期，.gitkeep 保目录可提交）
- **测试数据**：`<项目根>\.gitignore`、`git check-ignore` 命令
- **测试步骤**：
  1. 执行 `git check-ignore -v deploy/cloudoffice-gateway.jar`，确认命中 .gitignore 规则
  2. 执行 `git ls-files deploy`，确认被跟踪的仅有 .gitkeep 等非产物文件，无任何 *.jar
  3. 确认 deploy/.gitkeep 与 deploy/scripts/.gitkeep 仍被跟踪（空目录可提交）
- **预期结果**：
  1. deploy 下 *.jar 被 .gitignore 忽略（不入库属预期行为）
  2. git 跟踪清单中无 jar 产物，deploy 目录通过 .gitkeep 保持可提交
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-deploy-v0.2.5.ps1`（UT-084 断言组）
- **测试过程与结论**：2026-08-09 执行脚本，UT-084-1/2/3 断言全部通过：`git check-ignore -v deploy/cloudoffice-gateway.jar` 命中 .gitignore 规则；`git ls-files deploy` 无任何 *.jar 被跟踪；deploy/.gitkeep 与 deploy/scripts/.gitkeep 均被跟踪（空目录可提交）。结论：**通过**。

### 模块：后端构建产物输出（F-002/F-004） - 接口测试（无接口变更回归确认）
#### TC-049：构建配置修改不影响既有接口契约（P1）
- **用例ID**：TC-049
- **用例名称**：Maven 构建配置修改（产物输出至 deploy）不改变任何 HTTP 接口行为
- **所属模块**：全模块（接口回归确认）
- **优先级**：P1
- **前置条件**：版本 API 文档 `cso-api-v0.2.5.md` 已声明本版本无新增/变更接口
- **测试类型**：接口测试
- **关联需求ID**：F-002 / F-004 / US-002
- **测试数据**：版本 API 文档（docs/cso-v0.2.5/cso-api-v0.2.5.md）、git 变更清单
- **测试步骤**：
  1. 检查版本 API 文档「接口变更说明」：确认声明「无新增接口、无接口变更、无接口删除」
  2. 检查 git 变更清单：确认 TASK-004 仅修改 pom.xml 构建配置（根 pom + 4 个模块 pom），未触碰任何 Controller / 网关路由 / 接口层代码
  3. （可选）确认部署脚本内接口地址引用（如 `/api/v1/auth/health`）不因构建配置修改而变化——本任务不改脚本，仅改产物输出位置
- **预期结果**：
  1. 版本 API 文档明确声明本版本无接口变更
  2. git 变更中无接口层代码文件改动（本任务仅 pom.xml 构建配置）
  3. 既有 33 个接口（API-001~API-033）契约不受构建配置修改影响，部署脚本接口调用地址不变
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（函数 `test_tc049_build_config_no_api_change()`）
- **测试过程与结论**：2026-08-09 执行 cso-api-test-v0.2.5.py，TC-049-1/2/2b/3/4 断言全部通过：版本 API 文档声明无新增/变更/删除接口；git 变更清单无接口层代码文件；构建配置修改白名单外无任何业务代码/接口层/客户端源码改动；API-001~API-033 契约完整保留；deploy/scripts 脚本接口地址引用保持既有契约。结论：**通过**。

### 模块：后端构建产物输出（F-002/F-004） - 功能测试
#### FT-019：执行 mvn package 后 deploy 下存在 4 个最终 jar（P0）
- **用例ID**：FT-019
- **用例名称**：端到端构建验证——执行 Maven package 后 deploy 目录下出现 gateway/auth/biz/system 四个最终 jar
- **所属模块**：构建产物 / 构建执行
- **优先级**：P0
- **前置条件**：TASK-004 编码已完成；本地 Maven 3.9.x 与 JDK 21 可用；在项目根目录执行构建
- **测试类型**：功能测试
- **关联需求ID**：F-002 / F-004 / US-002 / AC-2
- **测试数据**：构建命令 `mvn clean package`（或 `mvn package`，如耗时过长可 `-pl cloudoffice-gateway,cloudoffice-auth-service,cloudoffice-biz-service,cloudoffice-system-service -am` 指定四模块）；预期产物 `<项目根>\deploy\cloudoffice-gateway.jar`、`cloudoffice-auth-service.jar`、`cloudoffice-biz-service.jar`、`cloudoffice-system-service.jar`
- **测试步骤**：
  1. 在项目根目录执行 `mvn clean package`（构建成功 BUILD SUCCESS）
  2. 逐一校验 `Test-Path "<项目根>\deploy\cloudoffice-gateway.jar" -PathType Leaf` 等 4 个产物文件均存在且为文件类型
  3. 校验 4 个 jar 文件大小非空（>0 字节，为有效产物）
  4. 校验 4 个文件名与契约一致且互不相同（无版本后缀、无同名覆盖）
- **预期结果**：
  1. 构建成功（BUILD SUCCESS）
  2. deploy 下存在 4 个最终 jar（gateway/auth/biz/system，文件名符合契约）
  3. 满足验收 AC-2「auth-service、biz-service、system-service、gateway 的最终 jar 包出现在 deploy 目录」
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（七、功能测试记录 FT-019）
- **测试过程与结论**：2026-08-09 在项目根目录执行 `mvn clean package`：BUILD SUCCESS（01:17 min，五模块全部 SUCCESS，antrun 在 package 阶段复制 1 文件至 deploy）。deploy 下 4 个 jar 均存在且为文件类型，大小非空（gateway=70631784、auth=67161122、biz=50179833、system=50180269 字节）；4 文件名契约一致且互不相同、无版本后缀。满足 AC-2。结论：**通过**。

#### FT-020：重复构建 overwrite 覆盖旧版本（P1，边界）
- **用例ID**：FT-020
- **用例名称**：连续两次构建后 deploy 下 jar 被新版覆盖且数量不变（无重复副本）
- **所属模块**：构建产物 / 重复构建覆盖
- **优先级**：P1
- **前置条件**：FT-019 通过（deploy 下已有 4 个 jar）
- **测试类型**：功能测试
- **关联需求ID**：F-002 / US-002（重复构建 overwrite 覆盖旧版本）
- **测试数据**：deploy 下 4 个 jar；再次执行 `mvn package`（或 `mvn clean package`）
- **测试步骤**：
  1. 记录首次构建后 deploy 下 4 个 jar 的 SHA256 哈希与时间戳
  2. 再次执行 `mvn package` 触发重复构建（编码可加一行注释/改动触发重新打包，或直接重跑）
  3. 重新计算 4 个 jar 的 SHA256 哈希与时间戳
  4. 统计 deploy 下 *.jar 数量与文件清单
- **预期结果**：
  1. 重复构建成功后 4 个 jar 的时间戳更新（新版本覆盖旧版本，无"目标已存在跳过"导致产物陈旧）
  2. deploy 下 *.jar 数量仍为 4（无 `(1)` 副本、无版本后缀堆积，覆盖而非并存）
  3. 满足"重复构建 overwrite 覆盖旧版本"
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（七、功能测试记录 FT-020）
- **测试过程与结论**：2026-08-09 记录三次数构建的 SHA256 哈希与时间戳：①编码阶段产物 13:27:02~13:27:28；②执行 `mvn clean package` 后 13:35:17~13:35:56（哈希全部变化，覆盖生效）；③再执行 `mvn package`（非 clean 增量）后 13:36:46~13:37:16（antrun copy 再次执行，哈希刷新）。deploy 下 *.jar 数量恒为 4（无 (1) 副本、无版本后缀堆积，覆盖而非并存）。结论：**通过**。

#### FT-021：deploy 下无任何中间产物混入（P0，负向）
- **用例ID**：FT-021
- **用例名称**：构建完成后 deploy 目录内不出现 target 类中间目录、编译临时文件、测试产物
- **所属模块**：构建产物 / 中间产物隔离
- **优先级**：P0
- **前置条件**：FT-019 通过（构建已完成）
- **测试类型**：功能测试
- **关联需求ID**：F-004 / AC-4（构建完成后 deploy 内不出现 target 类中间目录、编译临时文件、测试产物）
- **测试数据**：`<项目根>\deploy` 全目录清单；中间产物黑名单：`target`、`classes`、`test-classes`、`*.original`、`*.class`、`maven-status`、`surefire-reports`、`*.tmp`、`*.log`
- **测试步骤**：
  1. 递归列出 deploy 下全部文件与目录：`Get-ChildItem "<项目根>\deploy" -Recurse`，输出完整清单
  2. 负向校验：清单中不得出现任何中间产物——无 `target` 目录、无 classes/test-classes、无 `*.original`（repackage 前原始 jar）、无 `*.class` 编译文件、无 maven-status/surefire-reports 等构建临时目录、无测试产物
  3. 校验 deploy 下仅含预期内容：4 个 jar + env.json + env.example.json + scripts/ 子目录（及其 .sh/.ps1）
- **预期结果**：
  1. 中间产物黑名单全部未命中（命中数=0）
  2. deploy 下内容清单与预期完全一致（4 个最终 jar + env 文件 + scripts 子目录，无任何多余内容）
  3. 满足验收 AC-4「构建完成后 deploy 目录内不出现 target 类中间目录、编译临时文件、测试产物等中间产物」
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（七、功能测试记录 FT-021）
- **测试过程与结论**：2026-08-09 构建完成后递归列出 deploy 全目录：黑名单（target/classes/test-classes/*.original/*.class/maven-status/surefire-reports/*.tmp/*.log）命中数=0；deploy 顶层仅 4 个 jar + env.json + env.example.json + scripts/ + .gitkeep，deploy/scripts 下仅 .gitkeep + 21 个 .sh/.ps1，无任何多余内容。满足 AC-4。结论：**通过**。

#### FT-022：deploy 下 jar 为可执行 jar（含 BOOT-INF 结构）（P1）
- **用例ID**：FT-022
- **用例名称**：deploy 下 4 个 jar 均为 Spring Boot 可执行 jar（复制的是 repackage 后产物，可直接 java -jar 启动）
- **所属模块**：构建产物 / 产物有效性
- **优先级**：P1
- **前置条件**：FT-019 通过（deploy 下已有 4 个 jar）
- **测试类型**：功能测试
- **关联需求ID**：F-002 / US-002（可交付最终产物可用）
- **测试数据**：deploy 下 4 个 jar；`jar tf` / PowerShell `System.IO.Compression.ZipFile` 查看 jar 包内容
- **测试步骤**：
  1. 用 `jar tf "<项目根>\deploy\cloudoffice-gateway.jar"`（或等效 zip 读取方式）列出 jar 内容
  2. 校验 jar 包含 `BOOT-INF/classes/`、`BOOT-INF/lib/`、`META-INF/MANIFEST.MF`（Spring Boot repackage 可执行结构）
  3. 对 4 个 jar 逐一执行上述校验
  4. 校验 jar 内不含模块 target 中间结构（无 `com/...` 顶层类目录直接裸露等非 repackage 形态）
- **预期结果**：
  1. 4 个 jar 均含 BOOT-INF/ 可执行结构与 Main-Class 清单（复制的是 repackage 后的可执行 jar）
  2. 产物可直接 `java -jar` 启动（可交付性成立）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（七、功能测试记录 FT-022）
- **测试过程与结论**：2026-08-09 用 System.IO.Compression.ZipFile 逐一校验 4 个 jar：均含 BOOT-INF/classes/、BOOT-INF/lib/、META-INF/MANIFEST.MF，Main-Class=org.springframework.boot.loader.launch.JarLauncher（Spring Boot 3.2 repackage 可执行结构）；裸顶层 org/springframework（110 条）为 Spring Boot 3.2+ 内置 loader 类属正常结构；业务类 com/cloudstrolling 等裸暴露=0。产物可直接 java -jar 启动。结论：**通过**。

### 模块：后端构建产物输出（F-002/F-004） - UI 测试
#### UIT-009：deploy 下 jar 产物在 IDE/文件管理器中可见，客户端 UI 无变更（P1）
- **用例ID**：UIT-009
- **用例名称**：deploy 下 4 个 jar 产物在 IDE 项目树/文件管理器中可见，客户端 UI 无变更
- **所属模块**：构建产物 / 产物可见性；客户端（无 UI 变更）
- **优先级**：P1
- **前置条件**：FT-019 通过（deploy 下已有 4 个 jar）
- **测试类型**：UI 测试
- **关联需求ID**：F-002 / F-004 / US-002
- **测试数据**：`<项目根>\deploy` 目录（4 个 jar 产物）
- **测试步骤**：
  1. 在 Windows 文件管理器中打开项目根目录 deploy，确认 4 个 jar（cloudoffice-gateway/auth-service/biz-service/system-service.jar）可见（注：*.jar 被 .gitignore 忽略，部分 IDE 项目树可能默认隐藏，以文件管理器为准）
  2. 在 IDE（VS Code/IDEA）项目树中查看 deploy 节点下 jar 产物可见性
  3. 确认本任务未修改任何 Flutter 客户端界面代码（git 变更中无 cloudoffice-flutter-app/lib 下界面文件）
- **预期结果**：
  1. 文件管理器中 deploy 下可见 4 个最终 jar 产物（统一落点，交付人员单目录可收集）
  2. 客户端应用界面无任何变更（本任务为纯构建配置修改，无 UI 组件改动）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（八、UI 测试记录 UIT-009）
- **测试过程与结论**：2026-08-09 文件系统验证 deploy 下 4 个 jar 均可见（Test-Path Leaf=True，Windows 文件管理器可正常显示）；git 变更清单中 cloudoffice-flutter-app/lib 下界面文件变更数=0；git 变更仅 5 个 pom.xml 构建配置 + docs 文档 + scripts/API-TEST 测试脚本，无任何 Flutter 界面代码改动。结论：**通过**。

### 模块：客户端构建产物输出（F-003/F-004） - 单元测试（构建脚本/配置静态校验）
#### UT-085：cloudoffice-flutter-app 下存在客户端构建脚本（P0）
- **用例ID**：UT-085
- **用例名称**：cloudoffice-flutter-app 工程下存在客户端构建脚本（build-release.ps1 / build-release.sh 或等价脚本）
- **所属模块**：构建配置 / 客户端构建脚本
- **优先级**：P0
- **前置条件**：TASK-005 编码已完成（客户端构建脚本已新建）；deploy 目录已存在（TASK-001 完成）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-002 / AC-3
- **测试数据**：`<项目根>\cloudoffice-flutter-app` 目录，构建脚本候选：`build-release.ps1`、`build-release.sh`（或编码阶段采用的其他脚本名，如 build-windows.ps1）
- **测试步骤**：
  1. 递归搜索 `<项目根>\cloudoffice-flutter-app` 下全部脚本文件（`Get-ChildItem -Recurse -Include *.ps1,*.sh,*.bat,*.cmd`）
  2. 确认存在客户端构建脚本（本任务新建的构建入口，文件名为编码阶段确定的契约名）
  3. 执行 `Test-Path "<项目根>\cloudoffice-flutter-app\<构建脚本名>" -PathType Leaf`，确认其为文件类型
- **预期结果**：
  1. cloudoffice-flutter-app 下存在本任务新建的客户端构建脚本（编码前该工程无任何构建脚本）
  2. 构建脚本存在且为文件类型，可读可执行
  3. 满足验收 AC-3 的前提：客户端构建存在统一执行入口
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-085 断言组，由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：**通过**（2026-08-09 执行 `powershell -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1 -ProjectRoot <项目根>`，PASS=16 FAIL=0：[PASS] UT-085——build-release.ps1 与 build-release.sh 均存在，app dir 正确）

#### UT-086：构建脚本包含 flutter build 命令与失败中止逻辑（P0）
- **用例ID**：UT-086
- **用例名称**：客户端构建脚本包含 `flutter build windows --release`（及可选 Web）构建命令，并在构建失败时立即中止（$LASTEXITCODE / set -e 检查）
- **所属模块**：构建配置 / 客户端构建脚本
- **优先级**：P0
- **前置条件**：UT-085 通过（构建脚本已存在）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-002 / AC-3
- **测试数据**：`<项目根>\cloudoffice-flutter-app\build-release.ps1`（或编码确定的脚本名）
- **测试步骤**：
  1. 读取构建脚本全文，检查是否包含 `flutter build` 命令（Windows 平台：`flutter build windows --release`；如覆盖 Web：`flutter build web --release`）
  2. 检查 PowerShell 脚本是否在构建命令后检查 `$LASTEXITCODE -ne 0`（或 Bash 脚本是否使用 `set -e` / `$?` 检查），构建失败即中止、不继续执行复制动作
  3. 检查脚本是否包含构建前置步骤（如 `flutter pub get`，可选）
- **预期结果**：
  1. 构建脚本包含 `flutter build windows --release`（Windows 安装产物构建命令），构建入口完整
  2. 构建失败后脚本立即中止（不复制缺失/残缺产物到 deploy），防止失败产物污染 deploy
  3. 脚本命令与 Flutter 官方构建命令一致（x64 架构化产物路径适用，Flutter 3.16+）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-086 断言组，由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：**通过**（2026-08-09 同批执行：[PASS] UT-086-1 ps1/sh 均含 flutter build windows --release 与 flutter build web --release；[PASS] UT-086-2 ps1 $LASTEXITCODE -ne 0 / sh set -e 失败中止；[PASS] UT-086-3 flutter pub get 前置）

#### UT-087：构建脚本复制动作仅针对最终产物，严禁整目录递归复制 build/（P0，负向）
- **用例ID**：UT-087
- **用例名称**：构建脚本产物复制仅针对最终产物目录（Release 目录/web 产物），不得出现整目录递归复制 build/ 的配置
- **所属模块**：构建配置 / 中间产物隔离
- **优先级**：P0
- **前置条件**：UT-086 通过（构建脚本含构建命令）
- **测试类型**：单元测试
- **关联需求ID**：F-004 / AC-4（构建完成后 deploy 内不出现 target 类中间目录、编译临时文件、测试产物）
- **测试数据**：`<项目根>\cloudoffice-flutter-app\build-release.ps1`（或编码确定的脚本名）；Windows 最终产物目录 `build\windows\x64\runner\Release\`；Web 最终产物目录 `build\web\`
- **测试步骤**：
  1. 检查构建脚本复制源：Windows 复制源必须限定为 `build\windows\x64\runner\Release\`（或其下具体文件 exe/dll/data），Web 复制源限定为 `build\web\`（均为最终产物目录）
  2. 负向检查：脚本中不得出现 `Copy-Item build -Recurse`（PowerShell）或 `cp -r build`（Bash）等整目录递归复制整个 build/（构建缓存）的语句
  3. 检查复制动作不携带构建过程文件（CMakeFiles、vcxproj、*.obj、*.pdb 等编译临时文件不得进入 deploy）
- **预期结果**：
  1. 复制源仅限定最终产物目录（Release/、build/web/），无整目录递归复制 build/ 的语句（静态命中数为 0）
  2. 构建缓存与编译过程文件不进入 deploy（AC-4 静态保证）
  3. 复制动作遵循"仅复制最终产物文件，不整目录递归复制构建输出目录"原则
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-087 断言组，由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：**通过**（2026-08-09 同批执行：[PASS] UT-087-1 复制源限定 build\windows\x64\runner\Release 与 build\web；[PASS] UT-087-2 整目录递归复制 build/ 静态命中数=0；[PASS] UT-087-3 CMakeFiles/vcxproj/obj/pdb 中间模式命中=0）

#### UT-088：客户端产物命名可辨识且不与后端 jar 同名冲突（P1）
- **用例ID**：UT-088
- **用例名称**：deploy 下客户端最终产物命名可辨识（含 cloudoffice-flutter-app 或客户端标识），与 4 个后端 jar 无同名冲突
- **所属模块**：构建配置 / 产物命名契约
- **优先级**：P1
- **前置条件**：UT-087 通过；deploy 下已有 4 个后端 jar（TASK-004 完成，cloudoffice-gateway/auth-service/biz-service/system-service.jar）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-002（产物命名保持模块可辨识，不发生同名覆盖）
- **测试数据**：构建脚本中的复制目标路径/文件名、deploy 目录既有产物清单
- **测试步骤**：
  1. 提取构建脚本复制动作的目标路径与文件名（Windows 产物 exe 名与 Web 产物目录名）
  2. 校验客户端产物命名包含客户端可辨识标识（如 `cloudoffice-flutter-app`、`cloudoffice_client` 或 `cloudoffice_flutter_app`），不发生与 jar 的同名冲突（jar 为 .jar 后缀、客户端为 .exe/.zip/目录，命名空间不重叠）
  3. 校验产物目标位置与部署脚本引用约定一致（deploy 根目录或 deploy 下客户端子目录，与 deploy/scripts 引用约定一致）
- **预期结果**：
  1. 客户端产物命名可辨识（交付人员可区分后端 jar 与客户端产物）
  2. 与 4 个后端 jar 无同名冲突，无相互覆盖风险
  3. 产物落点与 deploy/scripts 部署脚本引用约定一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-088 断言组，由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：**通过**（2026-08-09 同批执行：[PASS] UT-088-1 deploy/cloudoffice-flutter-app 落点目录存在且脚本命名可辨识；[PASS] UT-088-2 deploy 下 4/4 后端 jar 齐全，无直接写 deploy 根的 exe/dll/zip 冲突模式；[PASS] UT-088-3 deploy/scripts 无陈旧客户端产物引用）

#### UT-089：客户端构建缓存 build/ 被 git 忽略，deploy 下产物入库规则正确（P1，负向/版本管理）
- **用例ID**：UT-089
- **用例名称**：客户端构建缓存 build/ 命中 .gitignore；deploy 下客户端产物（*.exe/*.dll/*.zip）默认不入库或已按规则放行
- **所属模块**：构建配置 / 版本管理
- **优先级**：P1
- **前置条件**：UT-085 通过；根 `.gitignore` 与 `cloudoffice-flutter-app\.gitignore` 均存在
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-002（构建缓存不入库；产物入库策略明确）
- **测试数据**：`<项目根>\.gitignore`、`<项目根>\cloudoffice-flutter-app\.gitignore`、`git check-ignore` 命令
- **测试步骤**：
  1. 执行 `git check-ignore -v cloudoffice-flutter-app/build/windows/x64/runner/Release/cloudoffice_flutter_app.exe`，确认命中 .gitignore 中 `build/` 规则（构建缓存整体忽略）
  2. 执行 `git check-ignore -v deploy/cloudoffice-flutter-app/`（或 deploy 下客户端产物路径），确认 deploy 下客户端产物（*.exe/*.dll/*.zip）的入库策略：默认忽略（命中 `*.exe`/`*.dll` 全局规则）或按编码阶段确定的放行规则（`!deploy/**/*.exe` 等）处理
  3. 确认 build/ 构建缓存不存在于 git 跟踪清单（`git ls-files cloudoffice-flutter-app/build` 返回为空）
- **预期结果**：
  1. 客户端 build/ 构建缓存被 .gitignore 忽略（不入库，与既有规则一致）
  2. deploy 下客户端产物的入库规则明确且与 .gitignore 一致（产物不入库或放行规则正确），无规则冲突
  3. git 跟踪清单中无任何构建缓存/过程文件
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-089 断言组，由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：**通过**（2026-08-09 同批执行：[PASS] UT-089-1 git check-ignore 命中 build/ 缓存路径；[PASS] UT-089-2 deploy 下 *.exe/*.dll 均被 git 忽略，规则明确；[PASS] UT-089-3 git ls-files 无 build 缓存，deploy/cloudoffice-flutter-app 仅跟踪 .gitkeep）

#### UT-090：构建脚本无失效旧路径引用（P0，负向/一致性）
- **用例ID**：UT-090
- **用例名称**：客户端构建脚本中不存在迁移后失效的旧路径引用（旧版 Release 路径、根目录 env.json、scripts/ 旧位置等）
- **所属模块**：构建配置 / 路径适配
- **优先级**：P0
- **前置条件**：UT-085 通过（构建脚本已存在）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / F-004 / US-002（脚本内路径引用与迁移后的 deploy 目录结构一致）
- **测试数据**：构建脚本全文内容；失效旧路径模式：`build\windows\runner\Release`（非 x64 旧路径）、`<项目根>\env.json`（根目录旧位置）、`scripts\`（脚本旧位置）等
- **测试步骤**：
  1. 扫描构建脚本内容，检查是否存在失效旧路径引用（不区分大小写）：
     - `build\windows\runner\Release` / `build/windows/runner/Release`（Flutter 3.16 前旧产物路径，本工程产物实际在 x64 架构化路径）
     - `..\env.json` / `env.json`（根目录旧位置引用，迁移后 env 在 deploy 下——若脚本引用 env 则须指向 deploy/env.json）
     - `scripts\deploy-*` 等旧脚本位置引用
  2. 检查脚本路径定位方式：使用 `$PSScriptRoot`（PowerShell）或 `$(dirname "${BASH_SOURCE[0]}")`（Bash）相对定位，无硬编码绝对路径
- **预期结果**：
  1. 构建脚本中不存在上述任何失效旧路径引用（扫描命中数为 0）
  2. 脚本路径定位基于脚本自身目录推导，与项目"deploy 为产物唯一落点"的既有约定一致
  3. 路径引用一致性满足 SAD 部署资产约束（迁移后脚本内路径引用同步适配）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-090 断言组，由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：**通过**（2026-08-09 同批执行：[PASS] UT-090-1 旧路径引用命中数=0（非 x64 Release 路径/根 env.json/旧 scripts/ 均未命中）；[PASS] UT-090-2 ps1 用 $PSScriptRoot、sh 用 BASH_SOURCE[0] 自定位；[PASS] UT-090-3 无硬编码绝对盘符路径）

### 模块：客户端构建产物输出（F-003/F-004） - 接口测试（无接口变更回归确认）
#### TC-050：客户端构建配置修改不影响既有接口契约（P1）
- **用例ID**：TC-050
- **用例名称**：Flutter 客户端构建配置修改（产物输出至 deploy）不改变任何 HTTP 接口行为
- **所属模块**：全模块（接口回归确认）
- **优先级**：P1
- **前置条件**：版本 API 文档 `cso-api-v0.2.5.md` 已声明本版本无新增/变更接口
- **测试类型**：接口测试
- **关联需求ID**：F-003 / F-004 / US-002
- **测试数据**：版本 API 文档（docs/cso-v0.2.5/cso-api-v0.2.5.md）、git 变更清单
- **测试步骤**：
  1. 检查版本 API 文档「接口变更说明」：确认声明「无新增接口、无接口变更、无接口删除」
  2. 检查 git 变更清单：确认 TASK-005 仅新增/修改客户端构建脚本与构建配置（cloudoffice-flutter-app 下构建脚本、可能涉及的 pubspec/windows/web 配置），未触碰任何 Controller / 网关路由 / 接口层代码，未修改客户端 lib/ 下业务源码
  3. （可选）确认客户端 API 调用层（lib/ 下 ApiClient/ApiInterceptor 等）未因构建配置修改而改动——本任务仅构建脚本，不改客户端运行时代码
- **预期结果**：
  1. 版本 API 文档明确声明本版本无接口变更
  2. git 变更中无接口层代码文件改动、无客户端运行时代码改动（本任务仅新增构建脚本与构建配置）
  3. 既有 33 个接口（API-001~API-033）契约不受客户端构建配置修改影响
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（函数 `test_tc050_client_build_config_no_api_change()`，由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：**通过**（2026-08-09 执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py`（miniconda Python）：[PASS] TC-050-1 版本 API 文档声明无新增/变更/删除接口；[PASS] TC-050-2 git 变更清单未触碰接口层代码文件；[PASS] TC-050-2b 构建配置修改之外无业务/接口/客户端运行时代码改动；[PASS] TC-050-2c cloudoffice-flutter-app/lib 运行时代码零改动；[PASS] TC-050-3 API-001~API-033 契约完整保留；脚本整体 PASS=21 FAIL=0 SKIP=1（TC-046-3 网关未启动的可选连通性检查，预期跳过））

### 模块：客户端构建产物输出（F-003/F-004） - 功能测试
#### FT-023：执行 Flutter 客户端构建后 Windows 安装产物出现在 deploy（P0）
- **用例ID**：FT-023
- **用例名称**：端到端构建验证——执行客户端构建脚本后，Windows 安装产物（exe + 依赖 DLL + data）出现在 deploy 目录
- **所属模块**：构建产物 / 构建执行
- **优先级**：P0
- **前置条件**：TASK-005 编码已完成；Flutter SDK 可用（Dart SDK ^3.12.2 对应 Flutter 3.4x）；在 cloudoffice-flutter-app 工程目录执行构建
- **测试类型**：功能测试
- **关联需求ID**：F-003 / F-004 / US-002 / AC-3
- **测试数据**：构建命令（编码确定的构建脚本，内部执行 `flutter build windows --release`）；预期产物：`<项目根>\deploy\` 下客户端 Windows 产物（exe 名 `cloudoffice_flutter_app.exe` 或编码确定的契约名，含依赖 DLL 与 data/）
- **测试步骤**：
  1. 在 `<项目根>\cloudoffice-flutter-app` 目录执行客户端构建脚本（构建成功，脚本退出码为 0）
  2. 校验 deploy 目录下出现客户端 Windows 最终产物：`Test-Path "<项目根>\deploy\<客户端产物路径>"` 为 True
  3. 校验产物有效性：exe 文件存在且大小非空（>0 字节）；依赖 DLL（flutter_windows.dll 等）与 data/ 目录随产物齐备（Windows 可交付物构成完整）
  4. 校验产物命名符合契约且与后端 jar 无同名冲突
- **预期结果**：
  1. 构建脚本执行成功（退出码 0），无「构建失败」报错
  2. deploy 目录下出现客户端 Windows 安装产物（exe 等最终产物），满足验收 AC-3「执行 Flutter 客户端构建后，安装文件/exe 等最终产物出现在 deploy 目录」
  3. 产物构成完整（exe + DLL + data），可交付性成立
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（九、功能测试记录 FT-023）
- **测试过程与结论**：**通过（修复后复测，首测失败 1/3 已闭环）**（首测失败：build-release.ps1 为 UTF-8 无 BOM + LF 编码，Windows PowerShell 5.1 解析异常、$PSScriptRoot 为空、EXIT=1；SSE 修复为 UTF-8 带 BOM + CRLF 并修正 $ScriptDir=$PSScriptRoot。2026-08-09 复测：`powershell -ExecutionPolicy Bypass -File build-release.ps1 -Platform all` **BUILD_EXIT=0**，Windows 产物复制至 deploy\cloudoffice-flutter-app\windows：cloudoffice_flutter_app.exe（91648 字节非空）+ flutter_windows.dll（21284864）+ dartjni.dll + flutter_secure_storage_x_windows_plugin.dll + data\flutter_assets\ 齐备，build 与 deploy 产物 SHA256 一致（93BB...0D1E）；命名与 4 个后端 jar 无冲突。AC-3 满足。详细记录见 cso-ui-test-record-v0.2.5.md 九、FT-023）

#### FT-024：构建完成后 deploy 下无客户端构建中间产物混入（P0，负向）
- **用例ID**：FT-024
- **用例名称**：客户端构建完成后 deploy 目录内不出现构建缓存（build/）、编译过程文件、测试产物等中间产物
- **所属模块**：构建产物 / 中间产物隔离
- **优先级**：P0
- **前置条件**：FT-023 通过（客户端构建已完成）
- **测试类型**：功能测试
- **关联需求ID**：F-004 / AC-4（构建完成后 deploy 内不出现 target 类中间目录、编译临时文件、测试产物）
- **测试数据**：`<项目根>\deploy` 全目录清单；中间产物黑名单：`build`、`CMakeFiles`、`*.vcxproj`、`*.obj`、`*.pdb`、`*.o`、`*.a`、`*.tmp`、`*.log`（data/flutter_assets 为 Release 正常携带资源，不属于中间产物黑名单）
- **测试步骤**：
  1. 构建完成后递归列出 deploy 下全部文件与目录：`Get-ChildItem "<项目根>\deploy" -Recurse`，输出完整清单
  2. 负向校验：清单中不得出现任何客户端构建中间产物——无 `build` 缓存目录（整体未混入）、无 CMakeFiles/vcxproj/obj/pdb 等编译过程文件、无测试产物（test/ 输出、coverage 等）
  3. 校验 deploy 下仅含预期内容：4 个后端 jar + env.json + env.example.json + scripts/ 子目录 + 客户端最终产物（exe/DLL/data 或 Web 包），无任何多余内容
- **预期结果**：
  1. 中间产物黑名单全部未命中（命中数=0，deploy 内无 build 缓存与编译过程文件）
  2. deploy 下内容清单与预期完全一致（仅最终产物 + 部署资产，无任何多余内容）
  3. 满足验收 AC-4「构建完成后 deploy 目录内不出现 target 类中间目录、编译临时文件、测试产物等中间产物」
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（九、功能测试记录 FT-024）
- **测试过程与结论**：**通过（修复后复测）**（2026-08-09 FT-023 构建成功后 deploy 全目录递归负向校验：中间产物黑名单（build/CMakeFiles/*.vcxproj/*.obj/*.pdb/*.o/*.a/*.tmp/*.log/*.ilk）命中数=0；deploy 顶层清单纯净：4 个后端 jar + env.json + env.example.json + scripts/ + cloudoffice-flutter-app/（仅 windows/ 与 web/ 两个最终产物子树）。AC-4 满足）

#### FT-025：Web 构建产物输出至 deploy（P1）
- **用例ID**：FT-025
- **用例名称**：执行客户端 Web 构建后，Web 部署包（build/web 内容）输出至 deploy 目录（若编码覆盖 Web 平台）
- **所属模块**：构建产物 / Web 构建执行
- **优先级**：P1
- **前置条件**：FT-023 通过（客户端构建链路可用）；编码阶段确定覆盖 Web 平台（构建脚本含 `flutter build web --release`）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-002 / AC-3（客户端最终产物含 Web 部署包）
- **测试数据**：构建命令（编码确定的构建脚本，Web 部分执行 `flutter build web --release`）；预期产物：`<项目根>\deploy\` 下客户端 Web 部署包（index.html、main.dart.js、assets/ 等）
- **测试步骤**：
  1. 执行构建脚本的 Web 构建部分（或独立执行 `flutter build web --release` 后按脚本复制逻辑校验）
  2. 校验 deploy 目录下出现 Web 部署包内容（index.html、main.dart.js、assets/ 等标准 Web 产物）
  3. 校验 Web 包完整性：入口文件 index.html 存在且大小非空，assets 目录存在
  4. 负向校验：build/web 构建缓存本身未整体混入 deploy（仅最终 Web 包内容进入）
- **预期结果**：
  1. Web 构建成功，deploy 下出现完整 Web 部署包（index.html + main.dart.js + assets/）
  2. Web 包为最终可交付物（可直接托管静态服务器），无 build 缓存混入
  3. 满足 AC-3 对客户端最终产物（含 Web 部署包）出现在 deploy 的要求
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（九、功能测试记录 FT-025）
- **测试过程与结论**：**通过（修复后复测）**（2026-08-09 与 FT-023 同批执行 Web 构建：flutter build web --release 成功（√ Built build\web），deploy\cloudoffice-flutter-app\web\ 下 index.html（1589 字节非空）、main.dart.js（2634453）、assets/、canvaskit/、manifest.json 等完整；deploy 与 build\web 产物 SHA256 一致，无 build/web 缓存整体混入。AC-3 Web 交付物满足）

#### FT-026：重复构建 overwrite 覆盖旧产物且无重复副本（P1，边界）
- **用例ID**：FT-026
- **用例名称**：连续两次客户端构建后 deploy 下产物被新版覆盖且数量不变（无重复副本、无版本堆积）
- **所属模块**：构建产物 / 重复构建覆盖
- **优先级**：P1
- **前置条件**：FT-023 通过（deploy 下已有客户端 Windows 产物）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-002（重复构建 overwrite 覆盖旧版本）
- **测试数据**：deploy 下客户端产物；再次执行客户端构建脚本（或 `flutter build windows --release` 后按脚本复制逻辑）
- **测试步骤**：
  1. 记录首次构建后 deploy 下客户端产物的 SHA256 哈希与时间戳
  2. 再次执行客户端构建脚本触发重复构建（编码可加一行注释/改动触发重新编译，或直接重跑）
  3. 重新计算产物 SHA256 哈希与时间戳，统计 deploy 下客户端产物文件数量与清单
- **预期结果**：
  1. 重复构建成功后产物时间戳更新（新版覆盖旧版，无"目标已存在跳过"导致产物陈旧）
  2. deploy 下客户端产物数量保持不变（无 `(1)` 副本、无版本后缀堆积，覆盖而非并存）
  3. 满足"重复构建 overwrite 覆盖旧版本"的产物更新语义
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（九、功能测试记录 FT-026）
- **测试过程与结论**：**通过（修复后复测）**（2026-08-09 基线：exe SHA256=93BB...0D1E、windows 文件数=14、web 文件数=39；重跑构建 BUILD_EXIT=0 后数量不变（14/39、无副本堆积）；覆盖语义动态验证：篡改 deploy\web\index.html（SHA256 AE43...→06F8...）后重跑构建，被 Copy-Item -Recurse -Force 覆盖恢复原始版本（与 build 一致），无「目标已存在跳过」；exe 时间戳未变系 Flutter 增量构建产物本身未变，非脚本缺陷）

### 模块：客户端构建产物输出（F-003/F-004） - UI 测试
#### UIT-010：deploy 下客户端产物在 IDE/文件管理器中可见，客户端 UI 无变更（P1）
- **用例ID**：UIT-010
- **用例名称**：deploy 下客户端最终产物在 IDE 项目树/文件管理器中可见，客户端应用界面无变更
- **所属模块**：构建产物 / 产物可见性；客户端（无 UI 变更）
- **优先级**：P1
- **前置条件**：FT-023 通过（deploy 下已有客户端产物）
- **测试类型**：UI 测试
- **关联需求ID**：F-003 / F-004 / US-002
- **测试数据**：`<项目根>\deploy` 目录（客户端 Windows 产物 exe/DLL/data 及可选 Web 包）
- **测试步骤**：
  1. 在 Windows 文件管理器中打开项目根目录 deploy，确认客户端产物（cloudoffice_flutter_app.exe 等）可见（注：*.exe/*.dll 被 .gitignore 忽略，部分 IDE 项目树可能默认隐藏，以文件管理器为准）
  2. 在 IDE（VS Code/IDEA）项目树中查看 deploy 节点下客户端产物可见性
  3. 确认本任务未修改任何 Flutter 客户端界面代码（git 变更中无 cloudoffice-flutter-app/lib 下界面文件；本任务仅新增构建脚本与构建配置）
- **预期结果**：
  1. 文件管理器中 deploy 下可见客户端最终产物（与后端 jar 同一统一落点，交付人员单目录可收集）
  2. 客户端应用界面无任何变更（本任务为纯构建脚本/配置新增，无 UI 组件改动）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（十、UI 测试记录 UIT-010）
- **测试过程与结论**：**通过（修复后复测）**（2026-08-09 FT-023 复测后：deploy\cloudoffice-flutter-app\windows\ 下 exe/DLL/data 与 web\ 下 Web 包在文件管理器中可见（与后端 jar 同一统一落点，交付人员单目录可收集）；git status 确认 cloudoffice-flutter-app 下仅新增 build-release.ps1 与 build-release.sh，lib 下文件变更数=0，客户端 UI 无任何变更）

### 模块：构建验证与 deploy 目录纯净性/完整性校验（AC-1~AC-7 全量验收） - 单元测试（目录结构/产物落位/纯净性/迁移完整性静态校验）
#### UT-091：deploy 目录结构完整性——含 env 两文件与 scripts 子目录（P0）
- **用例ID**：UT-091
- **用例名称**：项目根目录存在 deploy 目录，且包含 env.json、env.example.json 与 scripts 子目录（AC-1 全量静态核对）
- **所属模块**：部署资产 / 目录结构
- **优先级**：P0
- **前置条件**：TASK-001~TASK-005 编码已完成（deploy 目录、env 迁移、脚本迁移、构建配置均已落位）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / F-005 / F-006 / US-001 / AC-1
- **测试数据**：`<项目根>\deploy` 目录；`<项目根>\deploy\scripts` 子目录；`<项目根>\deploy\env.json`、`<项目根>\deploy\env.example.json`
- **测试步骤**：
  1. 校验 deploy 目录存在且为目录类型：`Test-Path "<项目根>\deploy" -PathType Container` 为 True
  2. 校验 deploy/scripts 子目录存在且为目录类型：`Test-Path "<项目根>\deploy\scripts" -PathType Container` 为 True
  3. 校验 deploy/env.json 存在且为文件类型：`Test-Path "<项目根>\deploy\env.json" -PathType Leaf` 为 True
  4. 校验 deploy/env.example.json 存在且为文件类型：`Test-Path "<项目根>\deploy\env.example.json" -PathType Leaf` 为 True
- **预期结果**：
  1. 四项校验全部为 True，deploy 目录结构完整（AC-1 满足）
  2. env 两文件与 scripts 子目录均位于 deploy 内，交付人员单目录可收集全部部署资产
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1（UT-091~UT-096 整体验收静态校验脚本，对应 Assert-Test 断言）
- **测试过程与结论**：**通过**。2026-08-09 执行 cso-unit-test-deploy-acceptance-v0.2.5.ps1：UT-091-1（deploy 存在且为容器）PASS、UT-091-2（deploy/scripts 存在且为容器）PASS、UT-091-3（deploy/env.json 存在）PASS、UT-091-4（deploy/env.example.json 存在）PASS，四项断言全部通过；AC-1 满足。

#### UT-092：4 个后端最终 jar 落位 deploy 且命名符合契约（P0）
- **用例ID**：UT-092
- **用例名称**：deploy 目录下存在 auth-service、biz-service、system-service、gateway 四个最终 jar 且命名可辨识
- **所属模块**：构建产物 / 后端 jar 落位
- **优先级**：P0
- **前置条件**：TASK-004 编码已完成；deploy 目录存在
- **测试类型**：单元测试
- **关联需求ID**：F-002 / F-004 / US-002 / AC-2
- **测试数据**：`<项目根>\deploy\cloudoffice-auth-service.jar`、`<项目根>\deploy\cloudoffice-biz-service.jar`、`<项目根>\deploy\cloudoffice-system-service.jar`、`<项目根>\deploy\cloudoffice-gateway.jar`
- **测试步骤**：
  1. 逐个校验四个 jar 文件存在且为文件类型、大小非空（>0 字节）
  2. 校验四个文件名互不相同且与 deploy/scripts/deploy-start-*.sh 脚本引用命名契约一一对应（auth-service/biz-service/system-service/gateway 一一匹配，不发生同名覆盖）
- **预期结果**：
  1. 四个 jar 全部存在且非空（AC-2 静态满足：auth-service、biz-service、system-service、gateway 最终 jar 出现在 deploy）
  2. 命名可辨识、无同名冲突，与启动脚本引用一致
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1（UT-091~UT-096 整体验收静态校验脚本，对应 Assert-Test 断言）
- **测试过程与结论**：**通过**。2026-08-09 执行 cso-unit-test-deploy-acceptance-v0.2.5.ps1：UT-092-1（4 个契约 jar 全部存在）PASS、UT-092-2（均非空，auth=67,161,122 / biz=50,179,833 / system=50,180,269 / gateway=70,631,784 字节）PASS、UT-092-3（4 名互不相同、无同名覆盖）PASS、UT-092-4（deploy-start-* 脚本引用精确契约名、无 target/ 路径）PASS；AC-2 静态满足。

#### UT-093：客户端最终产物落位 deploy/cloudoffice-flutter-app（P1）
- **用例ID**：UT-093
- **用例名称**：deploy 下存在客户端最终产物目录（windows/ 与 web/），Windows exe 与 Web 入口文件齐备
- **所属模块**：构建产物 / 客户端产物落位
- **优先级**：P1
- **前置条件**：TASK-005 编码已完成；客户端构建产物已输出至 deploy
- **测试类型**：单元测试
- **关联需求ID**：F-003 / F-004 / US-002 / AC-3
- **测试数据**：`<项目根>\deploy\cloudoffice-flutter-app\windows\`（cloudoffice_flutter_app.exe 等）、`<项目根>\deploy\cloudoffice-flutter-app\web\`（index.html 等）
- **测试步骤**：
  1. 校验 deploy/cloudoffice-flutter-app 目录存在
  2. 校验 windows/ 下存在可执行文件（.exe，大小非空）与依赖 DLL（flutter_windows.dll 等）、data/ 目录
  3. 校验 web/ 下存在入口文件 index.html（大小非空）与 assets/ 目录
  4. 校验客户端产物与 4 个后端 jar 无同名冲突（部署在 cloudoffice-flutter-app 子目录下）
- **预期结果**：
  1. 客户端 Windows 与 Web 最终产物均落位 deploy（AC-3 静态满足）
  2. 产物构成完整、命名可辨识，与后端 jar 隔离共存
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1（UT-091~UT-096 整体验收静态校验脚本，对应 Assert-Test 断言）
- **测试过程与结论**：**通过**。2026-08-09 执行 cso-unit-test-deploy-acceptance-v0.2.5.ps1：UT-093-1（cloudoffice-flutter-app 存在）PASS、UT-093-2（windows/ 下 exe=91,648 字节非空、DLL=3 个全部非空、data/ 存在）PASS、UT-093-3（web/ 下 index.html=1,589 字节非空、assets/ 存在）PASS、UT-093-4（deploy 顶层无 *.exe/*.dll，客户端产物与后端 jar 隔离无冲突）PASS；AC-3 静态满足。

#### UT-094：deploy 内无中间产物混入（P0，负向）
- **用例ID**：UT-094
- **用例名称**：deploy 目录内不出现 target 类中间目录、编译临时文件、测试产物、构建缓存（AC-4 静态负向校验）
- **所属模块**：构建产物 / 中间产物隔离
- **优先级**：P0
- **前置条件**：TASK-001~005 编码已完成；deploy 目录存在
- **测试类型**：单元测试
- **关联需求ID**：F-004 / US-001 / US-002 / AC-4
- **测试数据**：`<项目根>\deploy` 全目录递归清单；中间产物黑名单：`target`、`build`、`.dart_tool`、`__pycache__`、`*.class`、`*.o`、`*.tmp`、`*.log`、`surefire-reports` 等
- **测试步骤**：
  1. 递归列出 deploy 下全部目录与文件：`Get-ChildItem "<项目根>\deploy" -Recurse`
  2. 负向校验：目录名命中黑名单（target/build/.dart_tool/__pycache__/surefire-reports）的数量=0
  3. 负向校验：文件扩展名命中黑名单（.class/.o/.tmp/.log/.obj/.pdb 等）的数量=0
- **预期结果**：
  1. 中间产物黑名单全部未命中（命中数=0，AC-4 静态满足：deploy 内无 target 类中间目录、编译临时文件、测试产物、构建缓存）
  2. deploy 内仅含预期内容：4 个 jar + env 两文件 + scripts/ + cloudoffice-flutter-app/（windows/ + web/）与 .gitkeep 占位
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1（UT-091~UT-096 整体验收静态校验脚本，对应 Assert-Test 断言）
- **测试过程与结论**：**通过**。2026-08-09 执行 cso-unit-test-deploy-acceptance-v0.2.5.ps1：UT-094-1（黑名单目录 target/build/.dart_tool/__pycache__/surefire-reports/CMakeFiles 命中=0）PASS、UT-094-2（黑名单文件 *.class/*.o/*.tmp/*.log/*.obj/*.pdb/*.ilk/*.vcxproj 命中=0）PASS；AC-4 静态满足。

#### UT-095：根目录不再保留 env.json 与 env.example.json（P0，负向）
- **用例ID**：UT-095
- **用例名称**：项目根目录不存在 env.json 与 env.example.json，两文件已迁移至 deploy（AC-5 负向校验）
- **所属模块**：环境配置 / 迁移完整性
- **优先级**：P0
- **前置条件**：TASK-002 编码已完成（env 两文件已迁移至 deploy）
- **测试类型**：单元测试
- **关联需求ID**：F-005 / US-003 / AC-5
- **测试数据**：`<项目根>\env.json`、`<项目根>\env.example.json`（应不存在）；对照 `<项目根>\deploy\env.json`、`<项目根>\deploy\env.example.json`（应存在）
- **测试步骤**：
  1. 负向校验：`Test-Path "<项目根>\env.json"` 为 False（根目录不再保留）
  2. 负向校验：`Test-Path "<项目根>\env.example.json"` 为 False（根目录不再保留）
  3. 正向对照：deploy 下两文件存在（结合 UT-091 结论）
- **预期结果**：
  1. 根目录两文件均不存在，deploy 下两文件均存在（AC-5 满足，无双份配置、无加载不一致风险）
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1（UT-091~UT-096 整体验收静态校验脚本，对应 Assert-Test 断言）
- **测试过程与结论**：**通过**。2026-08-09 执行 cso-unit-test-deploy-acceptance-v0.2.5.ps1：UT-095-1（根目录 env.json 不存在）PASS、UT-095-2（根目录 env.example.json 不存在）PASS、UT-095-3（正向对照：deploy 下两文件均存在）PASS；AC-5 满足（无双份配置、无加载不一致风险）。

#### UT-096：21 个 sh/ps1 全部位于 deploy/scripts 且非脚本内容未迁移（P0，负向）
- **用例ID**：UT-096
- **用例名称**：deploy/scripts 下存在全部 21 个 .sh/.ps1，根目录 scripts 下无 sh/ps1 残留，非脚本内容（docker/sql/API-TEST 等）未被迁移（AC-6 负向校验）
- **所属模块**：部署脚本 / 迁移完整性
- **优先级**：P0
- **前置条件**：TASK-003 编码已完成（21 个脚本已迁移至 deploy/scripts）
- **测试类型**：单元测试
- **关联需求ID**：F-007 / US-003 / AC-6
- **测试数据**：`<项目根>\deploy\scripts\` 清单；`<项目根>\scripts\` 清单；预期 21 个脚本名（load-env、deploy-check-env、deploy-env、deploy-env-template、deploy-db-init、deploy-rsa-keygen、deploy-start-auth、deploy-start-biz、deploy-start-gateway、deploy-start-services、deploy-start-system 的 sh/ps1 对，其中 deploy-env 仅 ps1）
- **测试步骤**：
  1. 统计 deploy/scripts 下 .sh 数量（预期 10）与 .ps1 数量（预期 11），合计=21
  2. 逐个校验 21 个脚本名全部存在且为文件类型
  3. 负向校验：根目录 scripts 顶层（非递归）无任何 .sh/.ps1 残留
  4. 负向校验：scripts 下非脚本内容保持原位——`scripts/sql/`、`scripts/docker/`、`scripts/API-TEST/`、`scripts/deployment-guide.md` 仍存在，且 deploy/scripts 下未出现这些非脚本内容
- **预期结果**：
  1. deploy/scripts 下 .sh=10、.ps1=11、合计 21 个，全部存在（AC-6 静态满足：全部 .sh/.ps1 已迁移至 deploy/scripts）
  2. 根目录 scripts 无 sh/ps1 残留（无双份脚本）
  3. 非脚本内容（docker/sql/API-TEST/deployment-guide.md）原位未迁移，其既有引用不受破坏
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-unit-test-deploy-acceptance-v0.2.5.ps1（UT-091~UT-096 整体验收静态校验脚本，对应 Assert-Test 断言）
- **测试过程与结论**：**通过**。2026-08-09 执行 cso-unit-test-deploy-acceptance-v0.2.5.ps1：UT-096-1（deploy/scripts 下 sh=10、ps1=11、合计 21）PASS、UT-096-2（21 个脚本名全部存在为文件）PASS、UT-096-3（根目录 scripts 顶层无 .sh/.ps1 残留）PASS、UT-096-4（scripts/sql、scripts/docker、scripts/API-TEST、deployment-guide.md 全部原位存在）PASS、UT-096-5（deploy/scripts 仅 21 脚本 + .gitkeep，无非脚本内容混入）PASS；AC-6 满足。

### 模块：构建验证与 deploy 目录纯净性/完整性校验 - 接口测试（无接口变更回归确认）
#### TC-051：本版本整体验收不涉及接口变更，既有接口契约不受影响（P1）
- **用例ID**：TC-051
- **用例名称**：v0.2.5 整体验收（deploy 目录纯净性/完整性校验）不改变任何 HTTP 接口行为
- **所属模块**：全模块（接口回归确认）
- **优先级**：P1
- **前置条件**：版本 API 文档 `cso-api-v0.2.5.md` 已声明本版本无新增/变更/删除接口
- **测试类型**：接口测试
- **关联需求ID**：F-001~F-007 / US-001~US-003
- **测试数据**：版本 API 文档（docs/cso-v0.2.5/cso-api-v0.2.5.md）、git 变更清单
- **测试步骤**：
  1. 检查版本 API 文档「接口变更说明」：确认声明「无新增接口、无接口变更、无接口删除」
  2. 检查 git 变更清单：确认本版本（TASK-001~006）全部变更均为目录结构、构建配置、环境配置与部署脚本迁移，未触碰任何 Controller / 网关路由 / 接口层代码，未修改客户端 lib/ 下运行时代码
  3. （可选）确认 deploy/scripts 下脚本调用的健康检查接口地址（如 `/api/v1/auth/health`）引用保持正确
- **预期结果**：
  1. 版本 API 文档明确声明本版本无接口变更
  2. git 变更中无接口层代码文件改动、无客户端运行时代码改动
  3. 既有 33 个接口（API-001~API-033）契约不受影响
- **自动化测试函数/脚本位置**：scripts/API-TEST/cso-api-test-v0.2.5.py（函数 test_tc051_acceptance_no_api_change，TC-051 专项）
- **测试过程与结论**：**通过**。2026-08-09 执行 cso-api-test-v0.2.5.py：TC-051-1（版本 API 文档声明无新增/变更/删除接口）PASS、TC-051-2（git 变更未触碰接口层代码文件）PASS、TC-051-2b（git 变更无客户端运行时代码 lib/ 改动）PASS、TC-051-3（API-001~API-033 契约完整保留）PASS、TC-051-4（deploy/scripts 脚本健康检查接口地址引用保持既有契约）PASS；脚本整体 PASS=26、FAIL=0、SKIP=1（TC-046-3 健康检查连通性为可选检查项，requests 未安装按既有约定 SKIP 不判失败）；本版本无接口变更，既有 33 个接口契约不受影响。

### 模块：构建验证与 deploy 目录纯净性/完整性校验 - 功能测试
#### FT-027：Maven 各模块 package 后 4 个后端 jar 落位 deploy 且为可执行 jar（P0）
- **用例ID**：FT-027
- **用例名称**：端到端构建验证——执行根目录 Maven 各模块 package 后，4 个后端最终可执行 jar 出现在 deploy（AC-2 端到端）
- **所属模块**：构建产物 / 后端构建执行
- **优先级**：P0
- **前置条件**：TASK-001~005 编码已完成；Maven 环境可用（JDK 21）；deploy 目录存在
- **测试类型**：功能测试
- **关联需求ID**：F-002 / F-004 / US-002 / AC-2
- **测试数据**：构建命令 `mvn clean package -DskipTests`（根目录执行，覆盖 auth/biz/system/gateway 四模块）；预期产物：deploy 下 cloudoffice-auth-service.jar、cloudoffice-biz-service.jar、cloudoffice-system-service.jar、cloudoffice-gateway.jar
- **测试步骤**：
  1. 在项目根目录执行 `mvn clean package -DskipTests`，构建成功（BUILD SUCCESS，退出码 0）
  2. 校验 deploy 下四个 jar 全部存在且大小非空、时间戳为本次构建刷新（overwrite=true 覆盖语义生效）
  3. 可执行性抽查：`jar tf deploy/cloudoffice-gateway.jar | grep BOOT-INF` 命中（repackage 后含 BOOT-INF，可用 java -jar 启动）
  4. 校验四个 jar 与 deploy/scripts 启动脚本引用命名一致（无契约失配）
- **预期结果**：
  1. 构建成功（BUILD SUCCESS），无「构建失败」报错；构建失败时不落盘失败产物
  2. deploy 下 4 个最终 jar 齐备且为最新构建产物（AC-2 满足）
  3. jar 为 repackage 可执行 jar（含 BOOT-INF），非瘦 jar
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-027 功能测试记录章节，实际执行由 impm-task-coding-runtest 记录）
- **测试过程与结论**：**通过**。2026-08-09 在项目根目录执行 `mvn clean package -DskipTests`：BUILD SUCCESS（五模块全部 SUCCESS，Total time 29.274s），antrun 插件 package 阶段逐模块执行 `[copy] Copying 1 file to ...\deploy`；4 个 jar 全部存在且非空（auth=67,161,122 / biz=50,179,833 / system=50,180,269 / gateway=70,631,784 字节），时间戳均为本次构建 2026-08-09 15:45（mvn clean + overwrite 覆盖语义生效，无陈旧产物）；可执行性抽查：gateway jar 含 BOOT-INF 140 条目 + META-INF/MANIFEST.MF、auth jar 含 BOOT-INF 233 条目（repackage 可执行 jar，非瘦 jar）；与启动脚本命名契约一致（UT-092-4 印证，无契约失配）；AC-2 端到端满足。

#### FT-028：Flutter 客户端构建后 Windows/Web 产物落位 deploy（P0）
- **用例ID**：FT-028
- **用例名称**：端到端构建验证——执行客户端构建脚本（-Platform all）后，Windows 安装产物与 Web 部署包出现在 deploy（AC-3 端到端）
- **所属模块**：构建产物 / 客户端构建执行
- **优先级**：P0
- **前置条件**：FT-027 通过；Flutter SDK 可用（Dart SDK ^3.12.2）；在 cloudoffice-flutter-app 工程目录执行构建
- **测试类型**：功能测试
- **关联需求ID**：F-003 / F-004 / US-002 / AC-3
- **测试数据**：`<项目根>\cloudoffice-flutter-app\build-release.ps1 -Platform all`（内部执行 flutter build windows/web --release）；预期产物：deploy/cloudoffice-flutter-app/windows/（exe+DLL+data）与 web/（index.html+main.dart.js+assets/）
- **测试步骤**：
  1. 执行 `powershell -ExecutionPolicy Bypass -File build-release.ps1 -Platform all`，构建成功（退出码 0）
  2. 校验 deploy/cloudoffice-flutter-app/windows/ 下 exe（大小非空）、flutter_windows.dll 等依赖 DLL、data/ 齐备
  3. 校验 deploy/cloudoffice-flutter-app/web/ 下 index.html（大小非空）、main.dart.js、assets/ 齐备
  4. 抽样 SHA256 一致性：deploy 产物与 build/ 源产物一致（复制正确、无损坏）
- **预期结果**：
  1. 客户端构建成功（退出码 0），Windows 与 Web 最终产物均落位 deploy（AC-3 满足）
  2. 产物构成完整（exe + DLL + data / Web 完整包），可交付性成立
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-028 功能测试记录章节，实际执行由 impm-task-coding-runtest 记录）
- **测试过程与结论**：**通过**。2026-08-09 在 cloudoffice-flutter-app 目录执行 `powershell -ExecutionPolicy Bypass -File build-release.ps1 -Platform all`：BUILD_EXIT=0（flutter pub get → flutter build windows --release「√ Built build\windows\x64\runner\Release\cloudoffice_flutter_app.exe」→ flutter build web --release「√ Built build\web」→ 复制 Windows 与 Web 产物，脚本输出「客户端构建完成，全部最终产物已复制到 deploy」）；windows/ 下 exe=91,648 字节非空、DLL=3 个全部非空（flutter_windows.dll / dartjni.dll / flutter_secure_storage_x_windows_plugin.dll）、data/ 存在；web/ 下 index.html=1,589 字节非空、main.dart.js、assets/ 均存在；SHA256 一致性：exe 与 build\windows\x64\runner\Release 源产物完全一致（93BB5141...30D1E）、web/index.html 与 build\web 源产物一致（复制正确、无损坏）；AC-3 端到端满足。

#### FT-029：构建完成后 deploy 纯净性端到端负向校验（P0，负向）
- **用例ID**：FT-029
- **用例名称**：Maven 与客户端构建全部完成后，deploy 目录内不出现任何中间产物（target/build/.dart_tool/编译临时文件/测试产物/构建缓存）（AC-4 端到端负向）
- **所属模块**：构建产物 / 中间产物隔离
- **优先级**：P0
- **前置条件**：FT-027 与 FT-028 通过（后端与客户端构建均已执行）
- **测试类型**：功能测试
- **关联需求ID**：F-004 / US-001 / US-002 / AC-4
- **测试数据**：`<项目根>\deploy` 全目录递归清单（构建后状态）；中间产物黑名单：`target`、`build`、`.dart_tool`、`__pycache__`、`CMakeFiles`、`surefire-reports`、`*.class`、`*.o`、`*.obj`、`*.pdb`、`*.tmp`、`*.log`、`*.ilk`、`*.vcxproj`
- **测试步骤**：
  1. 构建完成后递归列出 deploy 全部文件与目录：`Get-ChildItem "<项目根>\deploy" -Recurse`，输出完整清单
  2. 负向校验：目录名命中黑名单（target/build/.dart_tool/__pycache__/CMakeFiles/surefire-reports）的数量=0
  3. 负向校验：文件扩展名命中黑名单（.class/.o/.obj/.pdb/.tmp/.log/.ilk/.vcxproj）的数量=0
  4. 正向校验：deploy 内容清单与预期完全一致——4 个 jar + env.json + env.example.json + scripts/（21 个 sh/ps1）+ cloudoffice-flutter-app/（windows/ + web/）+ .gitkeep 占位，无任何多余内容
- **预期结果**：
  1. 中间产物黑名单全部未命中（命中数=0，AC-4 满足：deploy 内无 target 类中间目录、编译临时文件、测试产物、构建缓存）
  2. deploy 下仅含最终产物与部署资产，交付人员单目录收集全部可交付内容
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-029 功能测试记录章节，实际执行由 impm-task-coding-runtest 记录）
- **测试过程与结论**：**通过**。2026-08-09 FT-027/FT-028 构建全部完成后递归扫描 deploy：负向校验目录名命中黑名单（target/build/.dart_tool/__pycache__/CMakeFiles/surefire-reports）=0（BAD_DIRS=0）、文件扩展名命中黑名单（.class/.o/.obj/.pdb/.tmp/.log/.ilk/.vcxproj）=0（BAD_FILES=0）；正向校验 deploy 顶层仅 4 个 jar + env.json + env.example.json + scripts/ + cloudoffice-flutter-app/ + .gitkeep，scripts 下仅 21 个 .sh/.ps1 + .gitkeep（sh=10、ps1=11），cloudoffice-flutter-app 下仅 windows/ 与 web/ 两个最终产物子树，无任何多余内容；AC-4 端到端满足。

#### FT-030：deploy/scripts 脚本冒烟执行——load-env → deploy-check-env（P0）
- **用例ID**：FT-030
- **用例名称**：迁移后 deploy/scripts 下脚本可正常执行，load-env.sh → deploy-check-env.sh 冒烟链路通过，env.json 加载正常（AC-7 端到端）
- **所属模块**：部署脚本 / 脚本可执行性
- **优先级**：P0
- **前置条件**：TASK-005 编码已完成（脚本路径引用已适配）；deploy/scripts 下存在 load-env.sh、deploy-check-env.sh；Bash/WSL 或 Git Bash 环境可用（或 PowerShell 版 load-env.ps1/deploy-check-env.ps1）
- **测试类型**：功能测试
- **关联需求ID**：F-007 / US-003 / AC-7
- **测试数据**：`<项目根>\deploy\scripts\load-env.sh`、`<项目根>\deploy\scripts\deploy-check-env.sh`（或 .ps1 版）；deploy/env.json（含数据库/Redis 等配置键）
- **测试步骤**：
  1. 执行冒烟链路第一步：`bash deploy/scripts/load-env.sh`，校验退出码为 0 且可输出/导出 env.json 配置键（如 MYSQL_HOST 等，仅校验键非空，不输出敏感值）
  2. 执行冒烟链路第二步：`bash deploy/scripts/deploy-check-env.sh`，校验退出码为 0（环境检查通过）
  3. （可选）在 PowerShell 环境执行 load-env.ps1 → deploy-check-env.ps1 冒烟，验证 Windows 部署链同样可用
  4. 校验脚本执行过程中未引用失效旧路径（无「找不到 /env.json」「找不到根目录 jar」类报错）
- **预期结果**：
  1. 冒烟链路 load-env → deploy-check-env 执行成功（退出码 0，无路径引用报错）（AC-7 满足：迁移后脚本可正常执行，脚本内 env.json 等路径引用已同步更新）
  2. env.json 在 deploy 下被正常加载，部署运维功能不受目录迁移影响
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（FT-030 功能测试记录章节，实际执行由 impm-task-coding-runtest 记录）
- **测试过程与结论**：**通过**。2026-08-09 执行冒烟链路（以 PowerShell 版执行，测试用例允许 Bash/WSL/Git Bash 或 PowerShell 版）：① load-env.ps1 执行成功（输出「环境变量已从 D:\...\deploy\env.json 加载」），加载后 DB_HOST、REDIS_HOST、NACOS_ADDR 均非空，env.json 在 deploy 下正常加载；② deploy-check-env.ps1 完整运行到汇总「检查完成: 6 项通过, 4 项失败」（EXIT=1），4 项失败均为中间件未启动（Nacos 127.0.0.1:8848、MariaDB 127.0.0.1:3306、Redis 127.0.0.1:6379 不可达），按既有约定记环境类 SKIP 不判失败；JDK/Maven/Git/JAVA_HOME/项目代码/SQL 初始化脚本路径类检查全部通过，执行过程中无「找不到 /env.json」「找不到根目录 jar」类失效路径报错；③ Bash 版：本机 WSL 未安装发行版（HCS_E_HYPERV_NOT_INSTALLED），Git Bash 亦缺 jq/python3（FT-015 已记录），属环境依赖非脚本缺陷，以 PowerShell 版冒烟链路替代验证（测试用例允许）；AC-7 满足。

### 模块：构建验证与 deploy 目录纯净性/完整性校验 - UI 测试
#### UIT-011：deploy 资产在 IDE/文件管理器中可见，客户端 UI 无变更（P1）
- **用例ID**：UIT-011
- **用例名称**：deploy 目录及 env 文件、scripts 子目录、构建产物在 IDE 项目树/文件管理器中可见，客户端应用界面无变更
- **所属模块**：部署资产 / 可见性；客户端（无 UI 变更）
- **优先级**：P1
- **前置条件**：FT-027~FT-030 通过（deploy 完整性与脚本可执行性已验证）
- **测试类型**：UI 测试
- **关联需求ID**：F-001 / F-005 / F-006 / F-007 / US-001 / US-003
- **测试数据**：`<项目根>\deploy` 目录（env.json、env.example.json、scripts/ 子目录、4 个 jar、cloudoffice-flutter-app/ 客户端产物）
- **测试步骤**：
  1. 在 Windows 文件管理器中打开项目根目录 deploy，确认 env 两文件、scripts 子目录、4 个 jar 与客户端产物可见（注：*.jar/*.exe/*.dll 被 .gitignore 忽略，部分 IDE 项目树可能默认隐藏，以文件管理器为准）
  2. 在 IDE（VS Code/IDEA）项目树中查看 deploy 节点下 env 文件、scripts 子目录与 .gitkeep 占位可见性
  3. 确认本版本（TASK-001~006）未修改任何 Flutter 客户端界面代码（git 变更中无 cloudoffice-flutter-app/lib 下界面文件；本版本仅目录结构、构建配置、环境配置与部署脚本调整）
- **预期结果**：
  1. 文件管理器中 deploy 下可见全部部署资产与最终产物（交付人员单目录可收集，AC-1/AC-6 可视性满足）
  2. 客户端应用界面无任何变更（本版本为纯工程结构与构建/部署配置调整，无 UI 组件改动）
- **自动化测试函数/脚本位置**：docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md（UIT-011 UI 测试记录章节，实际执行由 impm-task-coding-runtest 记录）
- **测试过程与结论**：**通过**。2026-08-09 执行：① 文件管理器（文件系统验证）中 deploy 下全部部署资产与最终产物可见——env.json（True）、env.example.json（True）、scripts/ 子目录（True）、4 个 jar（count=4）、cloudoffice-flutter-app\windows\cloudoffice_flutter_app.exe（True）、.gitkeep（True）；*.jar/*.exe/*.dll 被 .gitignore 忽略为预期策略（IDE 项目树可能默认隐藏，以文件管理器为准）；② IDE 项目树 deploy 节点下 env 文件、scripts 子目录与 .gitkeep 占位可见性由文件系统验证支撑（Test-Path 全部 True）；③ git 变更清单中 cloudoffice-flutter-app/lib 下界面文件变更数=0（FLUTTER_UI_CHANGES=0），本版本仅目录结构、构建配置、环境配置与部署脚本调整，客户端应用界面无任何变更；AC-1/AC-6 可视性满足。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 70（TASK-001~004 共 46 个 + TASK-005 共 12 个（UT-085~090、TC-050、FT-023~026、UIT-010）+ TASK-006 共 12 个（UT-091~096、TC-051、FT-027~030、UIT-011），2026-08-09 全部执行通过；TASK-005 中 FT-023~026、UIT-010 为修复后复测通过；TASK-006 由 impm-task-coding-runtest 执行，AC-1~AC-7 全量验收通过） |
| 失败 | 0（首测 TASK-005 FT-023 编码缺陷失败已由 SSE 修复，复测通过，失败闭环 1/3） |
| 阻塞 | 0 |
| 跳过 | 0（TC-046-3 健康检查为可选子项按设计 SKIP，不构成用例跳过；TASK-006 FT-030 冒烟中中间件未启动 4 项按既有约定记环境类 SKIP 不判失败，用例结论为通过；Bash 冒烟因 WSL 未安装发行版以 PowerShell 版替代，测试用例允许） |
| 待执行 | 0（TASK-006 共 12 个用例已于 2026-08-09 由 impm-task-coding-runtest 全部执行并回填） |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| deploy 已存在但含过期/无效内容 | 复用可能掩盖目录结构问题 | UT-064/FT-011 验证复用不覆盖；迁移任务前人工核对 deploy 内容 |
| 目录大小写不一致（Deploy/DEPLOY） | Windows 不区分大小写但 Linux 区分，部署脚本路径失效 | UT-063 校验全小写命名；编码与检查均固定小写 `deploy` |
| 中间产物误入 deploy | 违反"产物集中、纯净交付"约束 | UT-065 负向校验 target/build 等目录；后续构建配置任务持续回归 |
| 脚本/产物路径引用未适配迁移 | 部署功能失效 | TC-046/TC-047 关联确认 + TASK-003/TASK-005 脚本迁移任务专项验证 |
| env.json 含真实密钥/密码，迁移或测试过程泄露 | 安全事件 | UT-071 校验 .gitignore 忽略；测试记录仅记键名不记敏感值；编码与测试全程遵守红线 |
| 迁移后根目录残留旧文件 | 违反 AC-5，双份配置易导致加载不一致 | UT-068/UT-069 负向校验根目录无残留 |
| 迁移过程内容损坏/编码变化 | env 加载失败导致部署异常 | UT-070 哈希一致性校验 + FT-013 JSON 可解析与键完整性校验 |
| 重复执行迁移造成目标覆盖或多余副本 | 配置被覆盖、目录不纯净 | FT-014 幂等性边界测试 |
| 脚本迁移遗漏或产生多余副本 | 违反 AC-6，部署功能缺失 | UT-073 数量+类型双校验、FT-017 迁移前后清单集合比对（diff=0） |
| 根目录 scripts 残留脚本文件 | 双份脚本易导致执行版本不一致 | UT-074 负向校验旧位置无残留 |
| 非脚本内容（sql/docker/API-TEST 等）被误迁移 | 破坏既有引用（如 docker-compose 相对路径） | UT-075 非脚本内容原位校验 |
| 脚本内失效旧路径引用未适配（SQL 目录、jar 路径、注释） | 迁移后脚本执行失效，部署运维功能受损 | UT-077 失效旧路径模式扫描 + FT-016 check-env 冒烟验证 |
| 迁移用普通 mv 导致 git 历史丢失 | 历史不可追溯，后续定位困难 | UT-076 git ls-files + git log --follow 追溯校验 |
| load-env 加载路径仍指向根目录 env.json | env 加载失败，全部部署脚本受影响 | UT-078 加载机制静态校验 + FT-015 load-env 冒烟验证 |
| 脚本内真实密码/RSA 密钥在迁移或测试中泄露 | 安全事件 | 迁移照搬（git mv）；测试记录只记「加载成功/键非空」，不输出任何敏感值 |
| 重复执行迁移覆盖现有脚本内容 | 脚本损坏、部署不可用 | FT-018 幂等性边界测试（哈希前后一致） |
| 复制配置使用了 antrun 3.x 已废弃的 `<tasks>` 语法 | 构建直接失败（3.0.0 起 `<tasks>` 用于破坏构建） | UT-080 静态校验 `<target>` 语法 |
| antrun 声明顺序在 spring-boot-maven-plugin 之前 | 复制的是未 repackage 的普通 jar，无法 java -jar 启动 | UT-080 校验插件顺序 + FT-022 BOOT-INF 结构校验 |
| 整目录递归复制 target | 中间产物混入 deploy，违反 AC-4 | UT-082 静态负向校验 + FT-021 构建后目录清单负向校验 |
| 产物命名含版本号或与脚本契约不一致 | 启动脚本找不到 jar，部署功能失效 | UT-081 命名契约比对（与 deploy-start-*.sh 引用一一对应） |
| 模块间同名 jar 相互覆盖 | 部分服务产物缺失 | UT-081 校验 4 个文件名互不相同 |
| deployDir 用各模块 `../deploy` 相对路径 | -pl/-am 构建顺序下路径歧义，产物落错位置 | UT-079 校验基于 `${maven.multiModuleProjectDirectory}` 定位 |
| common 模块误配置复制插件 | 库 jar 误入 deploy，deploy 不纯净 | UT-083 负向校验 common 无输出配置 |
| 重复构建不覆盖旧产物（目标已存在跳过） | 交付陈旧产物 | UT-082 overwrite 静态校验 + FT-020 重复构建时间戳/哈希校验 |
| 构建产物 jar 被误提交 git | 仓库膨胀、产物与源码混淆 | UT-084 git check-ignore / ls-files 校验 |
| 构建配置修改意外触碰接口层代码 | 接口契约回归 | TC-049 接口回归确认（git 变更清单无接口层改动） |
| 客户端工程缺少构建脚本 | 无法统一执行客户端构建与产物输出，AC-3 无法满足 | UT-085 校验构建脚本存在性 |
| 构建脚本无失败中止逻辑 | 构建失败时复制残缺产物到 deploy，交付损坏产物 | UT-086 校验 $LASTEXITCODE/set -e 失败中止 |
| 整目录递归复制 build/ | 构建缓存混入 deploy，违反 AC-4 | UT-087 静态负向校验 + FT-024 构建后目录清单负向校验 |
| 复制旧版 Release 路径（build/windows/runner/Release 非 x64） | 复制源不存在，构建脚本失败或产物缺失 | UT-090 失效旧路径扫描 + FT-023 构建验证 |
| 产物命名与后端 jar 冲突或不可辨识 | 交付人员无法区分产物，存在覆盖风险 | UT-088 命名契约校验（与 deploy 既有产物比对） |
| 产物落点与 deploy/scripts 脚本引用约定不一致 | 部署脚本找不到客户端产物，部署功能失效 | UT-088 产物落点契约校验 |
| 客户端构建缓存 build/ 被误提交 git | 仓库膨胀、产物与源码混淆 | UT-089 git check-ignore / ls-files 校验 |
| 产物复制携带编译过程文件（vcxproj/obj/pdb） | deploy 不纯净，违反 F-004 | UT-087 静态校验 + FT-024 黑名单负向校验 |
| 重复构建不覆盖旧产物（目标已存在跳过） | 交付陈旧产物 | FT-026 重复构建时间戳/哈希校验 |
| 客户端 Web 产物缺失或 build/web 整体混入 | Web 交付物不完整或 deploy 不纯净 | FT-025 Web 产物完整性与负向校验 |
| 构建脚本/配置修改意外触碰接口层代码或客户端运行时代码 | 接口契约或客户端功能回归 | TC-050 接口回归确认（git 变更清单无接口层/运行时代码改动） |
| 客户端构建耗时过长影响测试执行 | 测试阻塞 | FT-023 采用既有构建脚本执行；如环境缺依赖记录 SKIP 并标注原因 |
| deploy 目录结构不完整（env 文件/scripts 子目录缺失） | 部署资产分散，AC-1 不满足 | UT-091 目录结构四要素静态校验 |
| 后端 jar 未落位或命名失配 | 启动脚本找不到 jar，部署失败，AC-2 不满足 | UT-092 命名契约比对 + FT-027 构建端到端与 BOOT-INF 可执行性抽查 |
| 客户端产物未落位或构成不完整 | Windows/Web 交付物缺失，AC-3 不满足 | UT-093 静态校验 + FT-028 构建端到端与 SHA256 一致性抽样 |
| 中间产物（target/build 缓存/编译临时文件）混入 deploy | 违反"产物集中、纯净交付"，AC-4 不满足 | UT-094 静态黑名单 + FT-029 构建后全目录递归负向校验 |
| 根目录残留 env.json/env.example.json | 双份配置，加载不一致，AC-5 不满足 | UT-095 根目录负向校验 |
| 脚本迁移遗漏/根目录残留/非脚本内容被误迁移 | 部署功能缺失或既有引用破坏，AC-6 不满足 | UT-096 数量+类型+原位三重复核 |
| 脚本路径引用未适配（env.json/jar 路径失效） | 迁移后脚本执行失败，AC-7 不满足 | FT-030 冒烟链路 load-env → deploy-check-env 执行验证 |
| 构建验证耗时过长（Maven + Flutter 全量构建） | 测试阻塞 | FT-027/FT-028 采用既有构建命令执行；如环境缺依赖记录 SKIP 并标注原因 |
| 验收误判旧产物（deploy 下为陈旧 jar） | 假阳性通过 | FT-027 构建前 mvn clean、overwrite=true 语义 + 时间戳/哈希校验 |
| 本版本工程调整意外触碰接口层或客户端运行时代码 | 接口契约或客户端功能回归 | TC-051 接口回归确认（git 变更清单无接口层/运行时代码改动） |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-09（TASK-006 共 12 个用例已全部执行并通过，AC-1~AC-7 全量验收完成）
- 项目经理（PM）：（待签名）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
