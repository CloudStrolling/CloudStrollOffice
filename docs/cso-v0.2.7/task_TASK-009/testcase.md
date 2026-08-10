# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.7
**日期**：2026-08-10
**测试负责人**：TE

> 本任务（TASK-009）为治理 .gitignore 排除生成/测试/调试临时与中间文件（F-012 / US-005 / ADR-016 / SAD G-A7 / 上游 TASK-001 issue-list 第 4 节缺口 + TASK-008 cs.md 第 6 节现状）：
> 整体检查项目根目录文件与子目录，识别生成、测试、调试过程中的临时文件与中间文件，在 .gitignore 中按现有分区风格新增排除规则：JVM/应用调试产物（*.hprof、hs_err_pid*.log、heapdump.*、*.dmp、dump/、*.dump、derby.log、replay_pid*）、构建过程中间产物（*.flattened-pom.xml、*.lastUpdated、maven-status/、dependency-reduced-pom.xml）、测试产物与缓存（surefire-reports/、test-output/、test-results/、接口测试中间文件精确模式）、工具残留（*.saz、*.chls、*.har、*.history、*.session、*.trace）；规则带路径前缀或精确模式，**不得误伤** env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档等应入库文件；治理后执行 git status 验证临时/中间文件不再出现在待提交清单（F-012）。测试方法（任务 testMethod）：git status 验证（无生成/测试/调试过程文件）；应入库文件复核（env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档未缺失、未被误伤）。
> 本任务不涉及数据库变更（DBD v0.2.7 无变更）、不涉及接口变更（API v0.2.7 确认 API-001~API-033 完整保留）。
> 本任务用例编号 **TC-094、UT-224、FT-149、UIT-025** 起（延续 TASK-008 末位：TC-093、UT-223、FT-148、UIT-024）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 治理 .gitignore 排除生成/测试/调试临时与中间文件（F-012 / US-005 / ADR-016）：TASK-009 | TASK-009 | 13 | P0×8、P1×4、P2×1 |
| 其中：单元测试（.gitignore 新增 JVM 调试产物规则、构建/测试中间产物规则、测试产物与缓存规则、工具残留规则、治理红线——规则带路径前缀或精确模式不误伤应入库文件、分区注释与文件头规范） | TASK-009 | 6 | P0×5、P1×1 |
| 其中：接口测试（本任务无接口变更——API 契约静态核对 + 健康检查探活可选） | TASK-009 | 2 | P1×1、P2×1 |
| 其中：功能测试（git status 待提交清单无临时/中间文件、git check-ignore 生效验证、应入库文件未被误伤复核、git check-ignore -v 规则命中行号抽查） | TASK-009 | 4 | P0×3、P1×1 |
| 其中：UI 测试（无 UI 变更确认） | TASK-009 | 1 | P1×1 |

## 二、测试用例详情

### 模块：治理 .gitignore - 单元测试（静态核对）（TASK-009）
#### UT-224：.gitignore 新增 JVM/应用调试产物排除规则（P0）
- **用例ID**：UT-224
- **用例名称**：根目录 .gitignore 新增「JVM / 调试产物」分区（或并入 Java 分区），覆盖 JVM 与应用调试过程产物：堆转储 `*.hprof`、JVM 崩溃日志 `hs_err_pid*.log`（GitHub 官方 Java.gitignore 模板推荐模式，含 replay_pid*）、堆转储变体 `heapdump.*`、Windows 内存转储 `*.dmp`、调试转储目录 `dump/`、调试转储文件 `*.dump`、Derby 嵌入式数据库调试日志 `derby.log`（与已有 `*.log` 双保险）；规则与本任务需求（JVM 调试产物覆盖）一致
- **所属模块**：.gitignore / JVM 调试产物
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：根目录 `.gitignore`
- **测试步骤**：
  1. 读取 .gitignore，grep 逐项核对 `*.hprof`、`hs_err_pid*.log`、`replay_pid*`、`heapdump.*`、`*.dmp`、`dump/`、`*.dump`、`derby.log` 是否全部存在
  2. 核对上述规则位于「JVM / 调试产物」分区（或 Java/Maven 分区之后）且带清晰中文注释
  3. 对照 cs.md 6.1-A 建议清单与 ws.md 官方资料，断言无缺项
- **预期结果**：
  1. JVM/应用调试产物规则全部存在：`*.hprof`、`hs_err_pid*.log`、`replay_pid*`、`heapdump.*`、`*.dmp`、`dump/`、`*.dump`、`derby.log`
  2. 规则归入对应分区、注释清晰，与建议清单一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` UT-224-1（8 条 JVM 规则逐项存在）、UT-224-2（JVM 分区注释存在）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——脚本断言 UT-224-1（8 条 JVM/调试产物规则逐项存在：`*.hprof`、`hs_err_pid*.log`、`replay_pid*`、`heapdump.*`、`*.dmp`、`dump/`、`*.dump`、`derby.log`）、UT-224-2（「JVM / 调试产物」分区注释存在，新增分区行号 236~247 范围）全部通过，与 cs.md 6.1-A 建议清单及 ws.md GitHub 官方 Java.gitignore 模板一致，无缺项

#### UT-225：.gitignore 新增构建/测试中间产物排除规则（P0）
- **用例ID**：UT-225
- **用例名称**：.gitignore 新增「构建 / 测试中间产物」分区（或并入 Java 分区），覆盖 Maven 插件级独立中间产物（target/ 之外的兜底预防）：Flatten 插件 `*.flattened-pom.xml`、Maven 依赖解析失败标记 `*.lastUpdated`、Shade 插件 `dependency-reduced-pom.xml`（**官方默认生成在模块根目录 `${basedir}`，不在 target/ 内，必须忽略**）、Compiler 插件增量编译状态 `maven-status/`；与本任务需求（构建中间产物）一致
- **所属模块**：.gitignore / 构建中间产物
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：根目录 `.gitignore`
- **测试步骤**：
  1. 读取 .gitignore，grep 逐项核对 `*.flattened-pom.xml`、`*.lastUpdated`、`dependency-reduced-pom.xml`、`maven-status/` 是否全部存在
  2. 核对规则位于「构建 / 测试中间产物」分区且带清晰中文注释
  3. 对照 cs.md 6.1-B 建议清单与 ws.md 官方资料（Shade 默认 ${basedir} 关键发现），断言无缺项
- **预期结果**：
  1. 构建中间产物规则全部存在：`*.flattened-pom.xml`、`*.lastUpdated`、`dependency-reduced-pom.xml`、`maven-status/`
  2. 规则归入对应分区、注释清晰
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` UT-225-1（4 条构建中间产物规则逐项存在）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——脚本断言 UT-225-1（4 条构建/测试中间产物规则逐项存在：`*.flattened-pom.xml`、`*.lastUpdated`、`dependency-reduced-pom.xml`、`maven-status/`，行号 250~256 范围）通过，与 cs.md 6.1-B 建议清单一致（Shade 插件 dependency-reduced-pom.xml 官方默认生成在 `${basedir}` 模块根目录，必须忽略），无缺项

#### UT-226：.gitignore 测试产物与缓存排除规则（P0）
- **用例ID**：UT-226
- **用例名称**：.gitignore 测试产物与缓存规则核对：新增测试报告目录兜底规则 `surefire-reports/`、`test-output/`、`test-results/`（均带末尾斜杠只匹配目录，target/ 之外独立输出时兜底）；接口测试中间文件采用精确模式 `scripts/API-TEST/*.tmp`、`scripts/API-TEST/*.token.json`（禁止整目录忽略，保护应入库测试脚本 .py/.ps1）；Python 测试缓存 `__pycache__/`、`.pytest_cache/` 已有规则保留不破坏；与本任务需求（测试缓存与接口测试中间文件）一致
- **所属模块**：.gitignore / 测试产物与缓存
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：根目录 `.gitignore`
- **测试步骤**：
  1. 读取 .gitignore，grep 逐项核对 `surefire-reports/`、`test-output/`、`test-results/` 是否全部存在且以 `/` 结尾
  2. grep 核对 `scripts/API-TEST/*.tmp`、`scripts/API-TEST/*.token.json` 精确规则存在，且无 `scripts/API-TEST/`、`scripts/API-TEST/*.py`、`scripts/API-TEST/*.ps1` 等整目录/通配排除规则
  3. 核对 `__pycache__/`、`.pytest_cache/` 既有规则未被删除或修改
- **预期结果**：
  1. 3 条测试报告目录规则存在且均以 `/` 结尾（只匹配目录）
  2. 接口测试中间文件为精确模式，测试脚本 .py/.ps1 无被忽略风险
  3. Python 测试缓存既有规则完整保留
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` UT-226-1（3 条报告目录规则存在且带尾斜杠）、UT-226-2（API-TEST 精确规则存在且无整目录/脚本通配）、UT-226-3（__pycache__/.pytest_cache 规则保留）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——脚本断言 UT-226-1（`surefire-reports/`、`test-output/`、`test-results/` 3 条测试报告目录规则存在且均以 `/` 结尾只匹配目录）、UT-226-2（`scripts/API-TEST/*.tmp` 与 `scripts/API-TEST/*.token.json` 精确规则存在，且无 `scripts/API-TEST/` 整目录与 *.py/*.ps1 脚本通配排除规则，测试脚本无被忽略风险）、UT-226-3（`__pycache__/`、`.pytest_cache/` 既有规则完整保留未破坏）全部通过

#### UT-227：.gitignore 新增工具残留排除规则（P0）
- **用例ID**：UT-227
- **用例名称**：.gitignore 新增「工具残留」分区（建议插在环境密钥分区之前），覆盖 API 调试/抓包与会话类工具残留：Fiddler 会话归档 `*.saz`、Charles 会话 `*.chls`、HTTP Archive 抓包导出 `*.har`（W3C 事实标准格式）、编辑器/终端会话 `*.history`、`*.session`、调试跟踪 `*.trace`（cs.md 风险提示：若未来引入同名源码扩展名需改路径前缀）；与本任务需求（工具残留）一致
- **所属模块**：.gitignore / 工具残留
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：根目录 `.gitignore`
- **测试步骤**：
  1. 读取 .gitignore，grep 逐项核对 `*.saz`、`*.chls`、`*.har`、`*.history`、`*.session`、`*.trace` 是否全部存在
  2. 核对规则位于「工具残留」分区且带清晰中文注释
  3. 对照 cs.md 6.1-D 建议清单，断言无缺项
- **预期结果**：
  1. 工具残留规则全部存在：`*.saz`、`*.chls`、`*.har`、`*.history`、`*.session`、`*.trace`
  2. 规则归入对应分区、注释清晰
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` UT-227-1（6 条工具残留规则逐项存在）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——脚本断言 UT-227-1（6 条工具残留规则逐项存在：`*.saz`、`*.chls`、`*.har`、`*.history`、`*.session`、`*.trace`，行号 343~349 范围「工具残留」分区）通过，与 cs.md 6.1-D 建议清单一致，无缺项

#### UT-228：治理红线——新增规则不误伤应入库文件（P0）
- **用例ID**：UT-228
- **用例名称**：.gitignore 治理红线静态核对——新增规则全部为精确扩展名/目录模式，无全局通配覆盖应入库文件：`deploy/env.example.json`（现有精确 `env.json` 规则 324 行不得改为 `env.json*` 通配，且不得新增覆盖 env.example.json 的规则）；`.gitkeep` 白名单（`!*.gitkeep` 284/286 行）保留不破坏，新增规则无覆盖 `.gitkeep` 的模式；无 `*.xml`（保护 pom.xml）、无 `*.yml`（保护 bootstrap.yml/application.yml）、无 `*.py`/`*.ps1`/`*.sh` 通配（保护 scripts/API-TEST 测试脚本与 deploy/scripts 脚本）、无 `*.java`/`*.dart`/`*.md` 通配；deploy/cloudoffice-flutter-app/web/* + !*.gitkeep 结构不破坏
- **所属模块**：.gitignore / 治理红线
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：根目录 `.gitignore`
- **测试步骤**：
  1. grep 断言 `.gitignore` 中无 `env.json*` 通配规则；`env.json` 保持精确匹配（324 行现状）
  2. grep 断言 `.gitignore` 中无 `*.xml`、`*.yml`、`*.py`、`*.ps1`、`*.sh`、`*.java`、`*.dart`、`*.md` 全局通配规则
  3. grep 断言 `!*.gitkeep` 白名单（至少 284/286 行两处）与 `deploy/cloudoffice-flutter-app/web/*`、`windows/*` 结构完整保留
  4. 逐条审查新增规则（UT-224~227 涉及的 21 条），断言每条均不会匹配到应入库文件（env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码、文档、测试脚本）
- **预期结果**：
  1. 无 env.json* 通配、无覆盖应入库文件的全局通配规则
  2. .gitkeep 白名单与客户端构建产物排除结构完整保留
  3. 新增 21 条规则逐一安全，不误伤应入库文件
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` UT-228-1（无 env.json* 通配且 env.json 精确保留）、UT-228-2（无 *.xml/*.yml/*.py/*.ps1/*.sh/*.java/*.dart/*.md 全局通配）、UT-228-3（!*.gitkeep 白名单与客户端构建排除结构保留）、UT-228-4/4b（新增规则逐条不命中应入库文件清单，check-ignore --no-index 实测 17 个代表性文件全安全）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——脚本断言 UT-228-1（无 `env.json*` 通配规则、`env.json` 保持精确匹配）、UT-228-2（无 `*.xml`/`*.yml`/`*.yaml`/`*.py`/`*.ps1`/`*.sh`/`*.java`/`*.dart`/`*.md` 任何全局通配规则，pom.xml/bootstrap.yml/测试脚本/源码/文档均无被覆盖风险）、UT-228-3（`deploy/cloudoffice-flutter-app/web/*` + `windows/*` + `!*.gitkeep` 白名单结构完整保留）、UT-228-4/4b（新增 21+2 条规则逐条 `git check-ignore --no-index` 实测 17 个代表性应入库文件——deploy/env.example.json、.gitkeep、pom.xml、bootstrap.yml、.java/.dart/.md/.py/.ps1——全部返回未忽略，退出码 1）全部通过，治理红线达标，新增规则未误伤任何应入库文件

#### UT-229：.gitignore 分区注释与文件头规范（P1）
- **用例ID**：UT-229
- **用例名称**：.gitignore 修改规范核对——新增规则按现有分区注释风格（`# ===================== 分区名 =====================`）归类插入（JVM/调试产物、构建/测试中间产物、工具残留等分区），注释为简体中文；文件尾部 SPDX-License-Identifier（Apache-2.0）与 Copyright 声明（335-336 行现状）保留不被破坏；无重复规则（同一模式未在多个分区重复出现）
- **所属模块**：.gitignore / 规范
- **优先级**：P1
- **前置条件**：TASK-009 编码完成（.gitignore 已更新）
- **测试类型**：单元测试（静态核对）
- **关联需求ID**：US-005 / F-012 / project.md 编码规范
- **测试数据**：根目录 `.gitignore`
- **测试步骤**：
  1. 读取 .gitignore 全文，断言新增分区注释与现有分区风格一致（`# ===...===` 分隔）
  2. 断言新增注释与规则说明为简体中文
  3. 断言文件尾 SPDX-License-Identifier 与 Copyright 行存在
  4. 对新增规则去重核对，断言无重复规则条目
- **预期结果**：
  1. 分区注释风格一致、简体中文
  2. 文件尾 SPDX 与版权声明保留
  3. 无重复规则
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` UT-229-1（新增分区注释风格）、UT-229-2（SPDX/Copyright 尾注保留）、UT-229-3（23 条新增规则无重复）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——脚本断言 UT-229-1（新增分区注释与既有 `# =====...=====` 分隔风格一致，新增分区位于行号 236~351 范围，注释为简体中文）、UT-229-2（文件尾 SPDX-License-Identifier（Apache-2.0）与 Copyright 声明保留未破坏）、UT-229-3（23 条新增规则逐一去重，每个模式恰好出现一次，无重复条目）全部通过

### 模块：接口测试（本任务无接口变更）（TASK-009）
#### TC-094：无接口变更确认（P1）
- **用例ID**：TC-094
- **用例名称**：本任务（TASK-009）仅涉及 .gitignore 规则治理，不触碰任何 Controller/DTO/响应体；git 变更清单静态核对确认无后端接口代码变更（cloudoffice-*/src/main/java 下无 Controller 变更），API-001~API-033 接口契约完整保留（对应 API 文档 v0.2.7「无新增/变更/删除」声明）
- **所属模块**：接口层 / 契约回归
- **优先级**：P1
- **前置条件**：TASK-009 编码完成
- **测试类型**：接口测试（静态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：git 变更清单 + docs/cso-api-v0.2.7.md
- **测试步骤**：
  1. 获取 TASK-009 相关 git 变更文件清单，断言不含 cloudoffice-*/src/main/java 下任何接口代码文件
  2. 断言变更清单仅含 .gitignore 及本任务相关文档/测试产物
  3. 对照 docs/cso-api-v0.2.7.md，断言 API-001~API-033 无新增/变更/删除
- **预期结果**：
  1. 无后端接口代码变更，API-001~API-033 契约完整保留
  2. 变更范围与本任务定义一致（.gitignore 治理）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py` TC-094-1（API 文档无接口变更声明）、TC-094-2（git 变更清单无接口层文件）、TC-094-3（API-001~033 契约完整保留）、TC-094-4（变更范围仅限 .gitignore 治理与任务产出）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——`cso-api-test-v0.2.7.py` 断言 TC-094-1（cso-api-v0.2.7.md 声明本版本无新增/变更/删除接口）、TC-094-2（git 变更清单无任何 cloudoffice-*/src/main/java 下 Controller/DTO/响应体/网关路由文件）、TC-094-3（API-001~API-033 契约在 API 文档中完整保留）、TC-094-4（变更范围仅含 .gitignore 治理与任务文档/测试产物）全部通过，无接口变更确认成立

#### TC-095：健康检查端点契约探活（可选，环境依赖）（P2）
- **用例ID**：TC-095
- **用例名称**：基础设施与服务健康检查端点探活（可选，环境依赖）——直连 auth 服务 9100 /api/v1/auth/health 与网关 9000 根路径，断言 HTTP 200 且响应体 ApiResult 结构（code=200、status=UP）与 API 文档契约一致，确认 .gitignore 治理未影响服务运行与健康契约；服务未启动时按环境 SKIP 记录，不作为失败（静态契约由 TC-094 兜底）
- **所属模块**：接口层 / 健康检查探活
- **优先级**：P2
- **前置条件**：TASK-009 编码完成；auth 服务 9100 / 网关 9000 已启动（环境依赖）
- **测试类型**：接口测试（动态探活，环境依赖）
- **关联需求ID**：US-005 / F-012
- **测试数据**：`http://127.0.0.1:9100/api/v1/auth/health`、`http://127.0.0.1:9000/`
- **测试步骤**：
  1. 直连 auth 服务健康端点，断言 HTTP 200、code=200、status=UP
  2. 直连网关根路径，断言 HTTP 200 与 ApiResult 结构
  3. 任一服务未启动时记录环境 SKIP，不做失败判定
- **预期结果**：
  1. 健康端点契约与 API 文档一致（HTTP 200、ApiResult 结构齐全）
  2. 服务不可达时按环境 SKIP 记录
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.7.py` TC-095-1（直连 auth 9100 /api/v1/auth/health 探活）、TC-095-2（gateway 9000 根路径探活，任意 HTTP 响应即存活）；服务未启动按环境 SKIP；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS，未走环境 SKIP）**——本机 auth 9100 与 gateway 9000 服务运行中：TC-095-1（直连 auth `/api/v1/auth/health` 返回 HTTP 200、code=200、status=UP，与 API-012 契约一致）、TC-095-2（gateway 9000 根路径探活返回 HTTP 响应）全部通过；.gitignore 治理未影响服务运行与健康检查契约

### 模块：功能测试（git 治理效果验证）（TASK-009）
#### FT-149：git status 待提交清单无生成/测试/调试过程文件（P0）
- **用例ID**：FT-149
- **用例名称**：治理后执行 `git status --porcelain` 验证——待提交清单中不出现任何生成、测试、调试过程文件（*.hprof、hs_err_pid*.log、heapdump.*、*.dmp、*.dump、*.flattened-pom.xml、*.lastUpdated、dependency-reduced-pom.xml、maven-status/、surefire-reports/、test-output/、test-results/、scripts/API-TEST/*.tmp、*.token.json、*.saz、*.chls、*.har、*.history、*.session、*.trace、derby.log 等新治理类型）；仅出现预期变更（.gitignore 与任务相关文档/测试产物），满足 F-012 验收标准「git status 不再出现生成、测试、调试过程文件」
- **所属模块**：git 仓库 / 治理效果
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：功能测试（git status 验证）
- **关联需求ID**：US-005 / F-012
- **测试数据**：`git status --porcelain` 输出
- **测试步骤**：
  1. 执行 `git status --porcelain`，收集全部待提交文件
  2. 用本任务治理的类型清单（JVM 调试产物/构建中间产物/测试产物/工具残留四类 21 种模式）逐一匹配，断言 0 命中
  3. 核对剩余变更文件均为预期变更（.gitignore、版本测试用例文档、任务文档、测试脚本、version_progress.md 等）
- **预期结果**：
  1. 待提交清单无任何生成/测试/调试过程文件
  2. 变更文件均为预期内容（.gitignore 治理 + 任务产出）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` FT-149-1（git status --porcelain 匹配治理类型清单 0 命中）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——FT-149-1（`git status --porcelain` 待提交清单用 21 种治理类型模式逐一匹配，0 命中）通过；待提交清单仅含 .gitignore（M）、docs/cso-v0.2.7/ 版本文档（cso-task、cso-testcase、version_progress、task_TASK-009/）与 scripts/API-TEST/ 测试脚本（cso-unit-test-gitignore-v0.2.7.ps1 新增、cso-api-test-v0.2.7.py 修改），无任何生成/测试/调试过程文件，满足 F-012 验收标准

#### FT-150：git check-ignore 生效验证——治理类型文件被忽略（P0）
- **用例ID**：FT-150
- **用例名称**：临时创建各类治理类型文件/目录（.hprof、hs_err_pid12345.log、heapdump.bin、x.dmp、dump/、x.dump、.flattened-pom.xml、x.lastUpdated、dependency-reduced-pom.xml、maven-status/、surefire-reports/、test-output/、test-results/、x.saz、x.chls、x.har、x.history、x.session、x.trace、derby.log 等，置于模块根目录与 deploy/ 下验证任意层级匹配），执行 `git status --porcelain` 断言均不出现、`git check-ignore` 断言均返回被忽略（退出码 0），验证后清理全部临时文件并确认无残留；证明新增规则真实生效（F-012 验收核心）
- **所属模块**：git 仓库 / 规则生效验证
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：功能测试（动态验证）
- **关联需求ID**：US-005 / F-012
- **测试数据**：临时创建的代表性治理类型文件/目录（21 种模式全覆盖，测试后清理）
- **测试步骤**：
  1. 在项目根目录、cloudoffice-common 模块目录、deploy/ 下分别创建治理类型空文件/目录（如 heap.hprof、hs_err_pid12345.log、cloudoffice-common/.flattened-pom.xml、x.saz 等）
  2. 对每个文件执行 `git check-ignore <路径>`，断言退出码 0（被忽略）
  3. 执行 `git status --porcelain`，断言创建的临时文件均未出现在待提交清单
  4. 删除全部临时文件/目录，执行 `git status --porcelain` 断言无残留、工作区恢复治理后状态
- **预期结果**：
  1. 全部治理类型临时文件被 git check-ignore 确认忽略、git status 不出现
  2. 临时文件清理干净，无测试残留（治理本身不制造新垃圾）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` FT-150-1（check-ignore 22 个临时路径全部命中）、FT-150-2（git status 无临时文件泄露）、FT-150-3（清理后无残留、前后基线一致）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——动态实测：FT-150-1（在项目根目录、cloudoffice-common 模块目录、deploy/ 下创建 22 个治理类型临时文件/目录，`git check-ignore` 逐一断言全部命中、退出码 0）、FT-150-2（创建后 `git status --porcelain` 断言无任何临时文件出现在待提交清单）、FT-150-3（删除全部临时文件/目录后 `git status --porcelain` 断言无残留、工作区恢复治理后基线）全部通过——新增规则真实生效（F-012 验收核心），且治理本身未制造新垃圾

#### FT-151：应入库文件未被误伤——git ls-files 复核（P0）
- **用例ID**：FT-151
- **用例名称**：应入库文件复核（F-012 验收 + testMethod）——`git ls-files` 确认全部应入库文件仍被跟踪、未被新规则误伤：deploy/env.example.json（环境模板）、全部 .gitkeep（deploy/.gitkeep、deploy/scripts/.gitkeep、deploy/cloudoffice-flutter-app/**/.gitkeep、各 Maven 模块 src 下 .gitkeep、Flutter lib/test 下 .gitkeep 等约 40 个）、全部 pom.xml（根 + 5 模块）、全部 bootstrap.yml（15 个，含 src/test/resources）、全部源码（*.java、*.dart）、全部文档（*.md）、scripts/API-TEST 全部 .py/.ps1 测试脚本与 deploy/scripts 全部脚本；同时 `git status --porcelain --ignored` 复核被忽略路径清单中无任何应入库文件（对照 cs.md 第 4 节应入库清单）
- **所属模块**：git 仓库 / 应入库文件复核
- **优先级**：P0
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：功能测试（静态复核）
- **关联需求ID**：US-005 / F-012
- **测试数据**：`git ls-files` 输出、`git status --porcelain --ignored` 输出、cs.md 第 4 节应入库文件清单
- **测试步骤**：
  1. 执行 `git ls-files`，断言 deploy/env.example.json 存在
  2. 执行 `git ls-files deploy | Select-String "\.gitkeep"`，断言 .gitkeep 数量与 cs.md 记录一致（约 40 个）且 deploy 下全部存在
  3. 执行 `git ls-files | Select-String "pom\.xml"` 断言 6 个（根 + 5 模块）；`Select-String "bootstrap\.yml"` 断言 15 个
  4. 执行 `git ls-files | Select-String "\.java$|\.dart$|\.md$"`，断言源码与文档仍全部被跟踪（数量与治理前一致）
  5. 执行 `git ls-files scripts/API-TEST deploy/scripts`，断言测试脚本与部署脚本全部被跟踪
  6. 执行 `git status --porcelain --ignored`，断言被忽略清单中不含上述任何应入库文件
- **预期结果**：
  1. 全部应入库文件仍被跟踪（env.example.json、约 40 个 .gitkeep、6 个 pom.xml、15 个 bootstrap.yml、源码、文档、测试脚本、部署脚本）
  2. 被忽略路径清单中无应入库文件（未被误伤）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` FT-151-1（env.example.json 被跟踪）、FT-151-2（.gitkeep 数量核对，实际 48 个/deploy 下 5 个）、FT-151-3（pom.xml=6、bootstrap.yml=8，实际仓库事实，用例规划 15 为设计值）、FT-151-4（源码与文档全量跟踪）、FT-151-5（--ignored 清单无应入库文件）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——`git ls-files` 全量复核：FT-151-1（deploy/env.example.json 仍被跟踪）、FT-151-2（.gitkeep 全部被跟踪 count=48、deploy 下 5 个全部在位）、FT-151-3（pom.xml=6（根+5 模块）、bootstrap.yml=8（4 模块 × main/test）——以实际仓库事实为准，用例规划值 15 为设计预估，断言按实际记录）、FT-151-4（源码与文档全量跟踪：java=160、dart=58、md=135、scripts/API-TEST=23、deploy/scripts=24）、FT-151-5（`git status --porcelain --ignored` 被忽略清单中无任何应入库文件——.gitkeep/pom.xml/bootstrap.yml/env.example.json/.java/.dart/测试脚本 0 命中）全部通过，应入库文件未被误伤

#### FT-152：git check-ignore -v 规则命中行号抽查（P1）
- **用例ID**：FT-152
- **用例名称**：`git check-ignore -v` 抽查新增规则实际命中——对代表性路径（derby.log、dump/x.dump、cloudoffice-common/maven-status/compile/createdFiles.lst、cloudoffice-common/target/surefire-reports/TEST-x.xml、debug.saz、session.har 等）执行 `git check-ignore -v`，断言返回的命中规则行号为 TASK-009 新增规则行（而非依赖既有 target/、*.log 等规则），证明新增规则独立生效；命中行号在新增规则所在分区范围内
- **所属模块**：git 仓库 / 规则命中核对
- **优先级**：P1
- **前置条件**：TASK-009 编码完成（.gitignore 已新增规则）
- **测试类型**：功能测试（动态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：代表性路径清单 + `git check-ignore -v` 输出
- **测试步骤**：
  1. 对代表性路径逐一执行 `git check-ignore -v <路径>`（先创建对应临时空文件使路径真实存在，或使用已存在文件 derby.log）
  2. 记录每个路径命中的 .gitignore 行号
  3. 断言命中行号为新增规则所在分区范围（如 *.hprof 命中 JVM 分区行、x.saz 命中工具残留分区行），非既有规则兜底命中
  4. 清理临时文件
- **预期结果**：
  1. 每个治理类型路径命中对应新增规则（行号在新增分区范围内）
  2. 无依赖既有规则的兜底命中（证明新规则独立生效）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` FT-152-1（check-ignore -v 抽查 6 类路径全部命中新增规则行：*.hprof L238 / *.flattened-pom.xml L252 / dependency-reduced-pom.xml L255 / dump+*.dump L244/245 / *.saz L345 / *.har L347；derby.log 由既有 *.log L320 兜底属双保险设计，不计入新增抽查）；writetest 冒烟断言 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——FT-152-1（`git check-ignore -v` 抽查 6 类代表性路径，全部命中 TASK-009 新增规则行而非既有规则兜底：heap.hprof → L238 `*.hprof`、cloudoffice-common/x.flattened-pom.xml → L252 `*.flattened-pom.xml`、cloudoffice-common/dependency-reduced-pom.xml → L255 `dependency-reduced-pom.xml`、deploy/dump/x.dump → L244/245 `dump/`+`*.dump`、x.saz → L345 `*.saz`、session.har → L347 `*.har`；derby.log 由既有 `*.log`（L320）兜底命中属「双保险」设计不计入新增抽查）通过——新增规则独立生效，非既有规则兜底

### 模块：UI 测试（无 UI 变更确认）（TASK-009）
#### UIT-025：无 UI 变更确认（P1）
- **用例ID**：UIT-025
- **用例名称**：TASK-009 仅涉及 .gitignore 规则治理，不涉及任何 Flutter 客户端 UI/交互变更；git 变更清单静态核对无 cloudoffice-flutter-app 下任何源码（lib/、test/）与配置（pubspec.yaml 等）变更，客户端 UI/交互/运行行为零变更，无需 UI 测试
- **所属模块**：客户端 / UI 变更确认
- **优先级**：P1
- **前置条件**：TASK-009 编码完成
- **测试类型**：UI测试（静态核对）
- **关联需求ID**：US-005 / F-012
- **测试数据**：git 变更清单
- **测试步骤**：
  1. 获取 TASK-009 相关 git 变更文件清单
  2. 断言不含 cloudoffice-flutter-app/lib、cloudoffice-flutter-app/test、cloudoffice-flutter-app/pubspec.yaml 等任何客户端代码/配置文件
  3. 断言变更仅含 .gitignore 与任务相关文档/测试产物
- **预期结果**：
  1. 客户端零代码/配置变更，UI/交互/运行行为不受影响，无需 UI 测试
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md`「五、功能测试记录（FT-149 ~ FT-152，TASK-009）」UIT-025 节（git 变更清单静态核对）；writetest 冒烟静态核对 PASS
- **测试过程与结论**：**正式执行 2026-08-10（impm-task-coding-runtest）：通过（PASS）**——git 变更清单静态核对（详见 docs/cso-v0.2.7/cso-ui-test-record-v0.2.7.md「五、功能测试记录」UIT-025 节）：变更清单仅含 .gitignore（M）、docs/cso-v0.2.7/ 版本文档与 scripts/API-TEST/ 测试脚本，无任何 cloudoffice-flutter-app/lib、test/、pubspec.yaml 等客户端代码/配置文件，客户端 UI/交互/运行行为零变更，无需 UI 测试

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 13 |
| 失败 | 0 |
| 阻塞 | 0 |
| 跳过 | 0 |

> 本任务（TASK-009）13 个用例（单元 6：UT-224~229、接口 2：TC-094/095、功能 4：FT-149~152、UI 1：UIT-025）已全部执行完毕（2026-08-10，impm-task-coding-runtest 步骤）：**通过 13 / 失败 0 / 阻塞 0 / 跳过 0**。单元+功能测试脚本 `scripts/API-TEST/cso-unit-test-gitignore-v0.2.7.ps1` 断言级 **PASS=25/FAIL=0**（UT-224-1/2、UT-225-1、UT-226-1/2/3、UT-227-1、UT-228-1/2/3/4/4b、UT-229-1/2/3、FT-149-1、FT-150-1/2/3、FT-151-1/2/3/4/5、FT-152-1 全部通过）；接口测试脚本 `scripts/API-TEST/cso-api-test-v0.2.7.py` 全量 **PASS=59/FAIL=0/SKIP=0**（含 TASK-009 的 TC-094-1~4 静态回归与 TC-095-1/2 动态探活——本机 auth 9100/gateway 9000 服务运行中全部通过，未走环境 SKIP）；UI 测试 UIT-025 git 变更清单静态核对通过（cloudoffice-flutter-app 零改动）。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| 新增全局通配规则误伤应入库文件 | env.example.json/.gitkeep/pom.xml/bootstrap.yml/源码/文档被忽略 | UT-228 治理红线静态核对（21 条新增规则逐条不命中应入库文件）+ FT-151 git ls-files 全量复核 + git status --porcelain --ignored 复核被忽略清单 |
| 已跟踪文件不受新规则影响（gitignore 官方语法） | 历史已跟踪临时文件（如 opencode.json）无法被新规则忽略 | 本任务按约定不执行 git rm --cached（已跟踪文件治理需另行确认）；用例仅验证未跟踪文件被忽略（FT-150） |
| ! 无法重新包含已被排除父目录内文件 | deploy/.../web/* + !*.gitkeep 白名单结构被破坏 | UT-228-3 专项断言白名单结构完整保留（cs.md/ws.md 红线） |
| git check-ignore -v 需要路径真实存在 | 抽查路径不存在时 check-ignore 无法命中 | FT-152 先创建临时空文件再验证（测后清理）；derby.log 等真实存在文件直接验证 |
| 测试临时文件清理不彻底 | 治理任务自身制造新临时文件残留 | FT-150-3 专项断言清理后 git status 无残留 |
| 环境无 bash/WSL | .sh 相关动态验证无法执行 | 本任务以 git 命令与 .gitignore 文本核对为主（PowerShell 可全量执行），无 .sh 动态依赖 |
| 真实环境服务运行状态 | TC-095 探活依赖服务启动 | 服务未启动按环境 SKIP 记录，不作为失败；静态契约由 TC-094 兜底 |
| 规则命中行号随 .gitignore 编辑漂移 | FT-152 按行号断言脆弱 | 命中核对以「命中规则模式内容」为准（check-ignore -v 返回规则文本），行号仅作参考并记录实际值 |

## 五、签名确认
- 测试工程师（TE）：TE / 2026-08-10（impm-task-coding-testcase 步骤：TASK-009 测试用例 13 个已编写完成——单元 6：UT-224~229（JVM 调试产物/构建中间产物/测试产物缓存/工具残留规则核对、治理红线不误伤应入库文件、分区注释与 SPDX 规范）；接口 2：TC-094 无接口变更确认 + TC-095 健康检查探活可选；功能 4：FT-149 git status 无过程文件 + FT-150 check-ignore 生效验证 + FT-151 应入库文件未被误伤复核 + FT-152 check-ignore -v 命中行号抽查；UI 1：UIT-025 无 UI 变更确认；测试函数/脚本与执行结果由 impm-task-coding-writetest / impm-task-coding-runtest 步骤完成，TE 签名确认）
- 测试工程师（TE）执行补充：**TASK-009 已由 impm-task-coding-runtest 步骤（2026-08-10）正式执行完毕：通过 13 / 失败 0 / 阻塞 0 / 跳过 0**——单元+功能测试脚本 `cso-unit-test-gitignore-v0.2.7.ps1` 断言级 **PASS=25/FAIL=0**（UT-224~229 静态核对全部通过：JVM/调试产物 8 条、构建/测试中间产物 4 条、测试报告目录 3 条带尾斜杠、API-TEST 精确规则 2 条无整目录/脚本通配、工具残留 6 条；治理红线：无 env.json* 通配、无 *.xml/*.yml/*.py/*.ps1/*.sh/*.java/*.dart/*.md 全局通配、!*.gitkeep 白名单结构保留、17 个代表性应入库文件 check-ignore --no-index 全部安全；SPDX/Copyright 尾注保留、23 条新增规则无重复；FT-149 git status 0 命中治理类型；FT-150 动态创建 22 个临时文件/目录 check-ignore 全命中、清理无残留；FT-151 git ls-files 全量复核 env.example.json/.gitkeep=48/pom.xml=6/bootstrap.yml=8/源码文档测试脚本全跟踪、--ignored 清单无应入库文件；FT-152 check-ignore -v 抽查 6 类路径全部命中新增规则行）；接口测试脚本 `cso-api-test-v0.2.7.py` 全量 **PASS=59/FAIL=0/SKIP=0**（TC-094 静态回归 4 断言 + TC-095 健康端点探活 2 断言，本机 4 服务运行中动态探活全部通过）；UI 测试 UIT-025 git 变更清单静态核对通过（cloudoffice-flutter-app 零改动）。TE 签名确认。
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
