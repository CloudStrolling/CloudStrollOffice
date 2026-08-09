# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**测试负责人**：TE

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 构建验证与 deploy 目录纯净性/完整性校验（AC-1~AC-7 全量验收）：TASK-006 整体验收 | TASK-006 | 12 | P0×9、P1×3 |
| 其中：单元测试（目录结构/产物落位/纯净性/迁移完整性静态校验） | TASK-006 | 6 | P0×5、P1×1 |
| 其中：接口测试（无接口变更回归确认） | TASK-006 | 1 | P1×1 |
| 其中：功能测试（构建执行/纯净性扫描/脚本冒烟） | TASK-006 | 4 | P0×4 |
| 其中：UI 测试（deploy 资产可见性/无 UI 变更） | TASK-006 | 1 | P1×1 |

> 说明：本任务为 v0.2.5 整体验收任务（P0），全覆盖 PRD 验收标准 AC-1~AC-7：deploy 目录结构完整（含 env 两文件与 scripts 子目录）；4 个后端 jar 与客户端安装产物落位 deploy；无中间产物混入；根目录不残留 env 文件与已迁移脚本；deploy/scripts 下 21 个 sh/ps1 完整且非脚本内容未迁移；脚本冒烟可执行（load-env → deploy-check-env）。
> 用例编号延续版本测试用例文档编号空间（TASK-005 至 UT-090/TC-050/FT-026/UIT-010），本任务用例从 UT-091、TC-051、FT-027、UIT-011 起编号。

## 二、测试用例详情

### 模块：deploy 目录纯净性/完整性校验 - 单元测试（目录结构/产物落位/纯净性/迁移完整性静态校验）
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

### 模块：deploy 目录纯净性/完整性校验 - 接口测试（无接口变更回归确认）
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

### 模块：deploy 目录纯净性/完整性校验 - 功能测试
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

### 模块：deploy 目录纯净性/完整性校验 - UI 测试
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
| 通过 | 12（UT-091~UT-096×6、TC-051×1、FT-027~FT-030×4、UIT-011×1，2026-08-09 全部执行通过） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0（FT-030 冒烟中中间件未启动 4 项按既有约定记环境类 SKIP 不判失败，用例结论为通过；Bash 冒烟因 WSL 未安装发行版以 PowerShell 版替代，测试用例允许） |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
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
- 测试工程师（TE）：TE / 2026-08-09
- 项目经理（PM）：（待签名）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
