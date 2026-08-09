# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.5
**日期**：2026-08-09
**测试负责人**：TE

> 说明：本任务（TASK-004）为修改 Maven 构建配置：后端 jar 最终产物统一输出至 deploy（对应 PRD F-002/F-004、US-002，验收标准 AC-2/AC-4）。
> 用例编号延续版本测试用例文档编号空间：单元测试从 UT-079 起、接口测试从 TC-049 起、功能测试从 FT-019 起、UI 测试从 UIT-009 起（TASK-001~003 已用至 UT-078 / TC-048 / FT-018 / UIT-008）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 后端构建产物输出至 deploy（F-002/F-004）：TASK-004 Maven 构建配置 | TASK-004 | 12 | P0×6、P1×6 |
| 其中：单元测试（构建配置静态校验） | TASK-004 | 6 | P0×4、P1×2 |
| 其中：接口测试（无接口变更回归确认） | TASK-004 | 1 | P1×1 |
| 其中：功能测试（构建执行与产物校验） | TASK-004 | 4 | P0×2、P1×2 |
| 其中：UI 测试（产物可见性/无 UI 变更） | TASK-004 | 1 | P1×1 |

## 二、测试用例详情

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
- **前置条件**：UT-019 功能构建验证通过（deploy 下已有 jar）；.gitignore 已忽略 `*.jar`（第 233-234 行）
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

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 12（UT-079~084、TC-049、FT-019~022、UIT-009，2026-08-09 全部执行通过） |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
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

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-09
- 项目经理（PM）：（待签名）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
