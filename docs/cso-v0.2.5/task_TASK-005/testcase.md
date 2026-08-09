# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**测试负责人**：TE

> 说明：本任务（TASK-005）为修改 Flutter 客户端构建配置：安装产物统一输出至 deploy（对应 PRD F-003/F-004、US-002，验收标准 AC-3/AC-4）。
> 用例编号延续版本测试用例文档编号空间：单元测试从 UT-085 起、接口测试从 TC-050 起、功能测试从 FT-023 起、UI 测试从 UIT-010 起（TASK-001~004 已用至 UT-084 / TC-049 / FT-022 / UIT-009）。
> 自动化测试函数/脚本位置已由 impm-task-coding-writetest 步骤标注确认；测试过程与结论由 impm-task-coding-runtest 步骤记录。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 客户端构建产物输出（F-003/F-004）：TASK-005 Flutter 客户端构建配置——安装产物统一输出至 deploy | TASK-005 | 12 | P0×6、P1×6 |
| 其中：单元测试（构建脚本静态校验） | TASK-005 | 6 | P0×4、P1×2 |
| 其中：接口测试（无接口变更回归确认） | TASK-005 | 1 | P1×1 |
| 其中：功能测试（构建执行与产物校验） | TASK-005 | 4 | P0×2、P1×2 |
| 其中：UI 测试（产物可见性/无 UI 变更） | TASK-005 | 1 | P1×1 |

## 二、测试用例详情

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
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-085 断言组，已由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：2026-08-09 执行 `powershell -ExecutionPolicy Bypass -File scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1 -ProjectRoot <项目根>`，[PASS] UT-085（build-release.ps1 与 build-release.sh 均存在，app dir 正确）→ **通过**

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
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-086 断言组，已由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：2026-08-09 同批执行：[PASS] UT-086-1（ps1/sh 均含 flutter build windows --release 与 flutter build web --release）、[PASS] UT-086-2（ps1 $LASTEXITCODE -ne 0 / sh set -e 失败中止）、[PASS] UT-086-3（flutter pub get 前置）→ **通过**

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
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-087 断言组，已由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：2026-08-09 同批执行：[PASS] UT-087-1（复制源限定 build\windows\x64\runner\Release 与 build\web）、[PASS] UT-087-2（整目录递归复制 build/ 静态命中数=0）、[PASS] UT-087-3（CMakeFiles/vcxproj/obj/pdb 中间模式命中=0）→ **通过**

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
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-088 断言组，已由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：2026-08-09 同批执行：[PASS] UT-088-1（deploy/cloudoffice-flutter-app 落点目录存在且脚本命名可辨识）、[PASS] UT-088-2（deploy 下 4/4 后端 jar 齐全，无直接写 deploy 根的 exe/dll/zip 冲突模式）、[PASS] UT-088-3（deploy/scripts 无陈旧客户端产物引用）→ **通过**

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
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-089 断言组，已由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：2026-08-09 同批执行：[PASS] UT-089-1（git check-ignore 命中 build/ 缓存路径）、[PASS] UT-089-2（deploy 下 *.exe/*.dll 均被 git 忽略，规则明确）、[PASS] UT-089-3（git ls-files 无 build 缓存，deploy/cloudoffice-flutter-app 仅跟踪 .gitkeep）→ **通过**

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
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-client-build-v0.2.5.ps1`（UT-090 断言组，已由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：2026-08-09 同批执行：[PASS] UT-090-1（旧路径引用命中数=0：非 x64 Release 路径/根 env.json/旧 scripts/ 均未命中）、[PASS] UT-090-2（ps1 用 $PSScriptRoot、sh 用 BASH_SOURCE[0] 自定位）、[PASS] UT-090-3（无硬编码绝对盘符路径）→ **通过**

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
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.5.py`（函数 `test_tc050_client_build_config_no_api_change()`，已由 impm-task-coding-writetest 标注确认）
- **测试过程与结论**：2026-08-09 执行 `python scripts/API-TEST/cso-api-test-v0.2.5.py`（miniconda Python）：[PASS] TC-050-1（版本 API 文档声明无新增/变更/删除接口）、[PASS] TC-050-2（git 变更清单未触碰接口层代码文件）、[PASS] TC-050-2b（构建配置修改之外无业务/接口/客户端运行时代码改动）、[PASS] TC-050-2c（cloudoffice-flutter-app/lib 运行时代码零改动）、[PASS] TC-050-3（API-001~API-033 契约在 API 文档中完整保留）；脚本整体 PASS=21 FAIL=0 SKIP=1（TC-046-3 网关未启动的可选连通性检查，预期跳过）→ **通过**

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
- **测试过程与结论**：**通过（修复后复测，失败 1/3 已闭环）**。首测 **失败（P0）**：2026-08-09 执行 `powershell -ExecutionPolicy Bypass -File build-release.ps1 -Platform all`（EXIT=1），根因：build-release.ps1 为 UTF-8 无 BOM + LF 行尾编码，Windows PowerShell 5.1 按 ANSI 代码页解码中文注释导致解析异常、$PSScriptRoot 失效（$ScriptDir/$ProjectDir/$DeployDir 全部为空）。SSE 已修复：脚本保存为 **UTF-8 带 BOM + CRLF**（复测前字节级确认：UTF8-BOM=True、CRLF=True）并修正 `$ScriptDir = $PSScriptRoot` 路径推导。**复测 2026-08-09**：在 `<项目根>\cloudoffice-flutter-app` 执行 `powershell -ExecutionPolicy Bypass -File build-release.ps1 -Platform all`（Flutter 3.44.3 / Dart 3.12.2），**BUILD_EXIT=0**，全流程成功：flutter pub get → flutter build windows --release（√ Built build\windows\x64\runner\Release\cloudoffice_flutter_app.exe）→ 复制 Windows 产物 → flutter build web --release（√ Built build\web）→ 复制 Web 产物。deploy\cloudoffice-flutter-app\windows\ 下产物齐备：cloudoffice_flutter_app.exe（91648 字节，>0 非空）、flutter_windows.dll（21284864 字节）、dartjni.dll（66560）、flutter_secure_storage_x_windows_plugin.dll（159744）、data\flutter_assets\（Windows 可交付物构成完整）；**build 目录与 deploy 产物 SHA256 完全一致**（93BB...0D1E，复制动作真实生效）。产物命名符合契约（位于 deploy\cloudoffice-flutter-app\windows\ 子树，与 4 个后端 jar 无同名冲突）。**AC-3 满足** → **通过**

#### FT-024：构建完成后 deploy 下无客户端构建中间产物混入（P0，负向）
- **用例ID**：FT-024
- **用例名称**：客户端构建完成后 deploy 目录内不出现构建缓存（build/）、编译过程文件、测试产物等中间产物
- **所属模块**：构建产物 / 中间产物隔离
- **优先级**：P0
- **前置条件**：FT-023 通过（客户端构建已完成）
- **测试类型**：功能测试
- **关联需求ID**：F-004 / AC-4（构建完成后 deploy 内不出现 target 类中间目录、编译临时文件、测试产物）
- **测试数据**：`<项目根>\deploy` 全目录清单；中间产物黑名单：`build`、`CMakeFiles`、`*.vcxproj`、`*.obj`、`*.pdb`、`*.o`、`*.a`、`*.tmp`、`*.log`、`flutter_assets`（仅指 build 缓存内，data/flutter_assets 随 Release 正常携带）
- **测试步骤**：
  1. 构建完成后递归列出 deploy 下全部文件与目录：`Get-ChildItem "<项目根>\deploy" -Recurse`，输出完整清单
  2. 负向校验：清单中不得出现任何客户端构建中间产物——无 `build` 缓存目录（整体未混入）、无 CMakeFiles/vcxproj/obj/pdb 等编译过程文件、无测试产物（test/ 输出、coverage 等）
  3. 校验 deploy 下仅含预期内容：4 个后端 jar + env.json + env.example.json + scripts/ 子目录 + 客户端最终产物（exe/DLL/data 或 Web 包），无任何多余内容
- **预期结果**：
  1. 中间产物黑名单全部未命中（命中数=0，deploy 内无 build 缓存与编译过程文件）
  2. deploy 下内容清单与预期完全一致（仅最终产物 + 部署资产，无任何多余内容）
  3. 满足验收 AC-4「构建完成后 deploy 目录内不出现 target 类中间目录、编译临时文件、测试产物等中间产物」
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.5/cso-ui-test-record-v0.2.5.md`（九、功能测试记录 FT-024）
- **测试过程与结论**：**通过（修复后复测）**。2026-08-09 FT-023 构建成功后执行 deploy 全目录递归负向校验（`Get-ChildItem deploy -Recurse -Force`）：中间产物黑名单（build、CMakeFiles、*.vcxproj、*.obj、*.pdb、*.o、*.a、*.tmp、*.log、*.ilk 等）**命中数=0**；deploy 顶层清单纯净：4 个后端 jar + env.json + env.example.json + scripts/（全部迁移脚本）+ cloudoffice-flutter-app/（仅 windows/ 与 web/ 两个最终产物子树，无任何多余内容）。**AC-4 满足** → **通过**

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
- **测试过程与结论**：**通过（修复后复测）**。2026-08-09 与 FT-023 同批执行 Web 构建（flutter build web --release，√ Built build\web，BUILD_EXIT=0）：deploy\cloudoffice-flutter-app\web\ 下 Web 部署包完整——index.html（1589 字节非空）、main.dart.js（2634453 字节）、assets/（AssetManifest.bin、FontManifest.json、fonts/ 等）、canvaskit/、icons/、manifest.json、version.json 齐备；**deploy 与 build\web 产物 SHA256 一致**（index.html AE43... 两端相同），仅最终 Web 包内容进入 deploy、build/web 构建缓存未整体混入（目录清单与预期一致）。**AC-3 Web 交付物满足** → **通过**

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
- **测试过程与结论**：**通过（修复后复测）**。2026-08-09 基线（首建后）：exe SHA256=93BB...0D1E、windows 文件数=14、web 文件数=39；重跑 `build-release.ps1 -Platform all`（BUILD_EXIT=0）后：**产物数量不变**（windows=14、web=39，无 `(1)` 副本、无版本后缀堆积）。**覆盖语义动态验证**：向 deploy\web\index.html 追加篡改标记（SHA256 由 AE43... 变为 06F8...）后重跑构建，index.html 被 **Copy-Item -Recurse -Force** 覆盖恢复为 build 目录原始版本（AE43... 与 build 一致、与篡改后不同），证明不存在「目标已存在跳过」导致产物陈旧，覆盖而非并存。注：exe 时间戳未变（2026-06-27）系 Flutter/Ninja 增量构建产物本身未变（build 目录产物时间戳同为旧值且内容哈希一致），非脚本缺陷。**「重复构建 overwrite 覆盖旧版本」语义满足** → **通过**

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
- **测试过程与结论**：**通过（修复后复测）**。步骤 1/2（产物可见性）：FT-023 复测后 deploy\cloudoffice-flutter-app\windows\ 下文件管理器可见 cloudoffice_flutter_app.exe（91648 字节）、flutter_windows.dll、dartjni.dll、flutter_secure_storage_x_windows_plugin.dll、data\（Windows 交付物构成完整），web\ 下可见完整 Web 部署包（index.html/main.dart.js/assets/ 等），与后端 jar 同一统一落点 deploy，交付人员单目录可收集；步骤 3（无 UI 变更）：2026-08-09 git status 确认 cloudoffice-flutter-app 下仅新增 build-release.ps1 与 build-release.sh（未跟踪），`cloudoffice-flutter-app/lib` 下文件变更数=0（FLUTTER_UI_CHANGES=0），客户端应用界面无任何变更 → **通过**

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 12（UT-085、UT-086、UT-087、UT-088、UT-089、UT-090 单元测试 16/16 断言通过；TC-050 接口测试 5/5 断言通过；FT-023、FT-024、FT-025、FT-026 功能测试通过；UIT-010 UI 测试通过） |
| 失败 | 0（首测 FT-023 编码缺陷失败已由 SSE 修复，复测通过，失败闭环 1/3） |
| 阻塞 | 0 |
| 跳过 | 0（接口脚本 TC-046-3 为网关未启动的可选连通性检查 SKIP，非本任务用例） |
| 结论 | **通过**：TASK-005 全部 12 个用例复测通过。修复验证：build-release.ps1 编码已转 UTF-8 带 BOM + CRLF、$ScriptDir=$PSScriptRoot 路径推导修正；build-release.ps1 -Platform all 实测 BUILD_EXIT=0，Windows 产物与 Web 包均已复制至 deploy\cloudoffice-flutter-app；FT-024 中间产物黑名单命中=0、FT-026 -Force 覆盖语义动态验证通过（篡改文件被覆盖回原始版本）。AC-3/AC-4 全部满足。 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
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

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-09
- 项目经理（PM）：（待签名）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
