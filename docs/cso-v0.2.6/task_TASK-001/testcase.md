# 测试用例文档（TestCase）— #TASK-001 引入 spring-cloud-starter-bootstrap 配置引导依赖
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.6
**日期**：2026-08-09
**测试负责人**：TE

> 说明：本用例针对任务 TASK-001（根 pom + gateway/auth-service/biz-service/system-service 四个服务模块 pom 引入 `spring-cloud-starter-bootstrap`，修复 `No spring.config.import property has been defined` 启动报错，恢复 bootstrap.yml 在 Spring Boot 3.x 下的加载）。
> 本任务为 backend 类型纯构建/依赖配置变更任务，不涉及数据库（DBD v0.2.6 声明无结构变更）与 HTTP 接口（API v0.2.6 声明无新增/变更接口）。
> 用例编号延续主文档 cso-testcase.md 编号空间（v0.2.5 末位：TC-051、UT-096、FT-030、UIT-011），本任务新用例从 UT-097、TC-052、FT-031、UIT-012 起编号，避免合并版本文档时冲突。
> 关联需求：PRD F-001（引入 bootstrap 配置引导依赖）、用户故事 US-001（恢复服务配置引导，解决服务无法启动）；验收标准 AC-1~AC-5（任务 acceptanceCriteria 5 条）。
> 执行环境：2026-08-09 18:17~18:22，单元测试脚本与接口测试脚本执行完成；构建验证（FT-031/032）执行完成；服务启动验证（FT-033~037）因 Nacos(8848) 不可达按环境阻塞 SKIP；FT-038 边界验证完成（import-check 报错消失 + Nacos 连接异常出现，bootstrap 引导链路生效；服务最终失败于 RSA 密钥解析，属 T-02 回归报告另一子项，不在本任务范围）。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 构建/依赖配置（F-001）：TASK-001 引入 spring-cloud-starter-bootstrap | TASK-001 | 19 | P0×13、P1×5、P2×1 |
| 其中：单元测试（pom 依赖静态校验） | TASK-001 | 8 | P0×5、P1×3 |
| 其中：接口测试（无接口变更回归 + 健康检查探活） | TASK-001 | 2 | P0×1、P1×1 |
| 其中：功能测试（构建执行 + 服务启动验证） | TASK-001 | 8 | P0×7、P1×0、P2×1 |
| 其中：UI 测试（无 UI 变更确认） | TASK-001 | 1 | P1×1 |
| **合计** |  | **19** | P0×13、P1×5、P2×1 |

## 二、测试用例详情

### 模块：构建/依赖配置（F-001） - 单元测试（pom 依赖静态校验）
#### UT-097：根 pom dependencyManagement 声明 spring-cloud-starter-bootstrap（P0）
- **用例ID**：UT-097
- **用例名称**：根 pom.xml 的 dependencyManagement 中包含 spring-cloud-starter-bootstrap 依赖声明
- **所属模块**：根 pom / 依赖管理
- **优先级**：P0
- **前置条件**：TASK-001 编码已完成（根 pom 已修改）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001 / AC-1
- **测试数据**：`<项目根>\pom.xml`
- **测试步骤**：
  1. 解析根 pom.xml 文本，在 `<dependencyManagement>` 段中查找 `spring-cloud-starter-bootstrap` 坐标（`org.springframework.cloud` + `spring-cloud-starter-bootstrap`）
  2. 确认声明位置在 Spring Cloud / Spring Cloud Alibaba BOM import 附近（与 Spring Cloud 系列依赖归组）
- **预期结果**：
  1. 根 pom dependencyManagement 中存在 `spring-cloud-starter-bootstrap` 依赖声明（group/artifact 精确匹配）
  2. 版本未显式指定 5.x（由 spring-cloud-dependencies BOM 2023.0.1 托管为 4.1.2）或显式版本与 BOM 一致
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-097-1~4 断言段）
- **测试过程与结论**：**通过**。脚本 UT-097-1~4 共 4 项断言全部 PASS（2026-08-09 18:17:36 执行，Summary: PASS=15 FAIL=0，退出码 0）：①根 pom `<dependencyManagement>` 段包含 `spring-cloud-starter-bootstrap`；②坐标 groupId 精确匹配 `org.springframework.cloud`；③显式版本为 `4.1.2`（Spring Cloud 2023.0.1 BOM 托管值，非 5.x）；④声明位置在 spring-cloud-alibaba-dependencies BOM import 之后（与 Spring Cloud 系列依赖归组）。

#### UT-098：gateway 模块 pom 实际引入 spring-cloud-starter-bootstrap（P0）
- **用例ID**：UT-098
- **用例名称**：cloudoffice-gateway/pom.xml 的 dependencies 中实际引入 spring-cloud-starter-bootstrap
- **所属模块**：cloudoffice-gateway / 依赖声明
- **优先级**：P0
- **前置条件**：TASK-001 编码已完成（gateway pom 已修改）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001 / AC-1（4 个服务模块 pom 均包含该依赖）
- **测试数据**：`<项目根>\cloudoffice-gateway\pom.xml`
- **测试步骤**：
  1. 解析 cloudoffice-gateway/pom.xml 文本，在 `<dependencies>` 段中查找 `spring-cloud-starter-bootstrap` 坐标
  2. 确认引入位置在既有 Nacos starter 等 Spring Cloud 依赖块附近（归组合理）
- **预期结果**：
  1. gateway 模块 pom `<dependencies>` 中存在 `spring-cloud-starter-bootstrap`（仅根 pom 声明不够，模块必须实际引入）
  2. 依赖块未写版本号（由父 pom dependencyManagement 管理）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-098 断言）
- **测试过程与结论**：**通过**。脚本 UT-098 断言 PASS：`cloudoffice-gateway/pom.xml` 的 `<dependencies>` 段实际包含 `spring-cloud-starter-bootstrap`；且组合断言 UT-098-2（依赖块无显式 `<version>`，父 pom 管理）与 UT-098-1（位于 nacos starter 依赖块之后，归组合理）均 PASS。

#### UT-099：auth-service 模块 pom 实际引入 spring-cloud-starter-bootstrap（P0）
- **用例ID**：UT-099
- **用例名称**：cloudoffice-auth-service/pom.xml 的 dependencies 中实际引入 spring-cloud-starter-bootstrap
- **所属模块**：cloudoffice-auth-service / 依赖声明
- **优先级**：P0
- **前置条件**：TASK-001 编码已完成（auth-service pom 已修改）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001 / AC-1
- **测试数据**：`<项目根>\cloudoffice-auth-service\pom.xml`
- **测试步骤**：
  1. 解析 cloudoffice-auth-service/pom.xml 文本，在 `<dependencies>` 段中查找 `spring-cloud-starter-bootstrap` 坐标
  2. 确认与既有 nacos-config / nacos-discovery starter 依赖块归组合理
- **预期结果**：
  1. auth-service 模块 pom `<dependencies>` 中存在 `spring-cloud-starter-bootstrap`（该模块含 nacos-config，是 import-check 报错主要来源，必须引入）
  2. 依赖块未写版本号（由父 pom dependencyManagement 管理）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-099 断言）
- **测试过程与结论**：**通过**。脚本 UT-099 断言 PASS：`cloudoffice-auth-service/pom.xml` 的 `<dependencies>` 段实际包含 `spring-cloud-starter-bootstrap`；组合断言 UT-099-2（无显式版本）与 UT-099-1（位于 nacos starter 块之后）均 PASS。

#### UT-100：biz-service 模块 pom 实际引入 spring-cloud-starter-bootstrap（P0）
- **用例ID**：UT-100
- **用例名称**：cloudoffice-biz-service/pom.xml 的 dependencies 中实际引入 spring-cloud-starter-bootstrap
- **所属模块**：cloudoffice-biz-service / 依赖声明
- **优先级**：P0
- **前置条件**：TASK-001 编码已完成（biz-service pom 已修改）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001 / AC-1
- **测试数据**：`<项目根>\cloudoffice-biz-service\pom.xml`
- **测试步骤**：
  1. 解析 cloudoffice-biz-service/pom.xml 文本，在 `<dependencies>` 段中查找 `spring-cloud-starter-bootstrap` 坐标
  2. 确认与既有 nacos-config / nacos-discovery starter 依赖块归组合理
- **预期结果**：
  1. biz-service 模块 pom `<dependencies>` 中存在 `spring-cloud-starter-bootstrap`
  2. 依赖块未写版本号（由父 pom dependencyManagement 管理）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-100 断言）
- **测试过程与结论**：**通过**。脚本 UT-100 断言 PASS：`cloudoffice-biz-service/pom.xml` 的 `<dependencies>` 段实际包含 `spring-cloud-starter-bootstrap`；组合断言 UT-100-2（无显式版本）与 UT-100-1（位于 nacos starter 块之后）均 PASS。

#### UT-101：system-service 模块 pom 实际引入 spring-cloud-starter-bootstrap（P0）
- **用例ID**：UT-101
- **用例名称**：cloudoffice-system-service/pom.xml 的 dependencies 中实际引入 spring-cloud-starter-bootstrap
- **所属模块**：cloudoffice-system-service / 依赖声明
- **优先级**：P0
- **前置条件**：TASK-001 编码已完成（system-service pom 已修改）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001 / AC-1
- **测试数据**：`<项目根>\cloudoffice-system-service\pom.xml`
- **测试步骤**：
  1. 解析 cloudoffice-system-service/pom.xml 文本，在 `<dependencies>` 段中查找 `spring-cloud-starter-bootstrap` 坐标
  2. 确认与既有 nacos-config / nacos-discovery starter 依赖块归组合理
- **预期结果**：
  1. system-service 模块 pom `<dependencies>` 中存在 `spring-cloud-starter-bootstrap`
  2. 依赖块未写版本号（由父 pom dependencyManagement 管理）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-101 断言）
- **测试过程与结论**：**通过**。脚本 UT-101 断言 PASS：`cloudoffice-system-service/pom.xml` 的 `<dependencies>` 段实际包含 `spring-cloud-starter-bootstrap`；组合断言 UT-101-2（无显式版本）与 UT-101-1（位于 nacos starter 块之后）均 PASS。

#### UT-102：版本契约——bootstrap 依赖版本由 BOM 托管且禁止 5.x（P1，负向/一致性）
- **用例ID**：UT-102
- **用例名称**：全项目 5 处 pom 中 spring-cloud-starter-bootstrap 未显式声明 5.x 版本（BOM 托管 4.1.2）
- **所属模块**：全项目 / 依赖版本契约
- **优先级**：P1
- **前置条件**：UT-097~101 通过（5 个 pom 均已引入 bootstrap 依赖）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001（版本兼容性：Spring Cloud 2023.0.1 BOM 托管 4.1.2）
- **测试数据**：根 pom 与 4 个服务模块 pom 全文
- **测试步骤**：
  1. 扫描全部 6 个 pom.xml（含 cloudoffice-common），查找 `spring-cloud-starter-bootstrap` 依赖声明
  2. 检查各声明是否显式书写 `<version>`；若有，记录版本值
  3. 断言不允许出现 `5.x` 版本（5.0.2 属 Spring Cloud 2025.x，与本项目 2023.0.1 不兼容）
- **预期结果**：
  1. 所有引入处均未显式声明 5.x 版本（版本由 spring-cloud-dependencies BOM 2023.0.1 托管，解析为 4.1.2）
  2. 若显式声明版本，必须与 BOM 一致（4.1.x）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-102-1~2 断言）
- **测试过程与结论**：**通过**。脚本 UT-102-1~2 断言 PASS：全项目 6 个 pom（根 + 4 模块 + common）中无任何 5.x 显式版本命中；显式版本仅根 pom 的 4.1.2（属 4.1.x 家族，与 BOM 2023.0.1 一致）。

#### UT-103：配置文件未被改动（P1，负向/一致性）
- **用例ID**：UT-103
- **用例名称**：4 个服务模块的 bootstrap.yml 与 application.yml 内容未被本任务改动
- **所属模块**：资源文件 / 配置一致性
- **优先级**：P1
- **前置条件**：TASK-001 编码已完成（git 变更已产生）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001（最小改动原则，配置文件已含 nacos server-addr 无需修改）
- **测试数据**：git 变更清单；`cloudoffice-{gateway|auth-service|biz-service|system-service}/src/main/resources/{bootstrap,application}.yml`
- **测试步骤**：
  1. 执行 `git status --porcelain` 与 `git diff --stat`，获取本任务变更文件清单
  2. 检查 4 个模块的 bootstrap.yml / application.yml 是否出现在变更清单中
- **预期结果**：
  1. 变更清单仅含 pom.xml 文件（根 pom + 4 个服务模块 pom），不包含任何 yml 配置文件
  2. 4 个 bootstrap.yml（含 Nacos discovery/config server-addr）与 application.yml 保持原样
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-103-1 断言）
- **测试过程与结论**：**通过**。脚本 UT-103-1 断言 PASS：`git status --short` 变更清单中无任何 `*.yml` 文件（yml 变更数=0），4 个模块的 bootstrap.yml / application.yml 保持原样，满足最小改动原则。

#### UT-104：无接口层/业务代码/客户端代码改动（P1，负向/范围控制）
- **用例ID**：UT-104
- **用例名称**：git 变更范围仅限构建配置，无 Controller/Service/Mapper/客户端代码改动
- **所属模块**：全项目 / 变更范围控制
- **优先级**：P1
- **前置条件**：TASK-001 编码已完成（git 变更已产生）
- **测试类型**：单元测试
- **关联需求ID**：F-001 / US-001 / AC-5（无接口层/业务代码/客户端代码改动）
- **测试数据**：git 变更清单（`git status --porcelain` + `git diff --stat`）
- **测试步骤**：
  1. 执行 `git status --porcelain` 与 `git diff --name-only`（含未提交变更）
  2. 检查变更清单中是否出现 Java 源码（`*.java`）、Dart 源码（`*.dart`）、Mapper XML、网关路由配置、前端界面文件
- **预期结果**：
  1. 变更清单中无任何 `*.java`、`*.dart`、`*.xml`（Mapper/其他源码）文件
  2. 变更仅限 5 个 pom.xml（根 pom + gateway/auth/biz/system 四个模块），满足 AC-5「无接口层/业务代码/客户端代码改动」
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-bootstrap-dependency-v0.2.6.ps1`（UT-104-1~2 断言）
- **测试过程与结论**：**通过**。脚本 UT-104-1~2 断言 PASS：变更清单中无 `*.java` / `*.dart` / Mapper xml / 客户端代码（cloudoffice-flutter-app 下 0 项）；5 个 pom（根 pom + 4 个服务模块 pom）均在变更清单中，满足 AC-5 变更范围控制。

### 模块：构建/依赖配置（F-001） - 接口测试（无接口变更回归 + 健康检查探活）
#### TC-052：本任务无接口变更，既有接口契约不受影响（P1）
- **用例ID**：TC-052
- **用例名称**：bootstrap 依赖引入不改变任何 HTTP 接口契约（API-001~033 完整保留）
- **所属模块**：全模块（接口回归确认）
- **优先级**：P1
- **前置条件**：版本 API 文档 `cso-api-v0.2.6.md` 已声明本版本无新增/变更接口
- **测试类型**：接口测试
- **关联需求ID**：F-001 / US-001（不得改变既有接口契约与业务代码逻辑）
- **测试数据**：版本 API 文档（docs/cso-v0.2.6/cso-api-v0.2.6.md）、git 变更清单
- **测试步骤**：
  1. 检查版本 API 文档「接口变更说明」：确认声明「无新增接口、无接口变更、无接口删除」
  2. 检查 git 变更清单：确认 TASK-001 仅修改 5 个 pom.xml（根 pom + 4 个服务模块 pom），未触碰任何 Controller / DTO / 响应体 / 网关路由 / 接口层代码
  3. 核对 API 文档接口清单 API-001~API-033 完整保留（33 个接口无增删改）
- **预期结果**：
  1. 版本 API 文档明确声明本版本无接口变更
  2. git 变更中无接口层代码文件改动（本任务仅 pom 依赖声明变更）
  3. 既有 33 个接口（API-001~API-033）契约不受影响，网关路由不变
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 `test_tc052_no_api_change`，TC-052-1~4 断言）
- **测试过程与结论**：**通过**。脚本 TC-052-1~4 共 4 项断言全部 PASS（2026-08-09 18:18:22 执行，PASS=4 FAIL=0 SKIP=4，退出码 0）：①版本 API 文档 cso-api-v0.2.6.md 存在且声明「无新增接口、无接口变更、无接口删除」；②git 变更清单未触碰接口层代码文件（无 Controller/网关路由/接口层改动）；③API 文档中 API-001~API-033 完整保留；④git 变更仅限 5 个 pom.xml 与文档/测试资产，无接口层/业务/客户端代码改动（AC-5）。

#### TC-053：4 服务健康检查接口探活（P0）
- **用例ID**：TC-053
- **用例名称**：服务启动后 /api/v1/auth/health、/api/v1/biz/health、/api/v1/system/health 返回正常状态
- **所属模块**：gateway/auth-service/biz-service/system-service / 健康检查
- **优先级**：P0
- **前置条件**：FT-033~FT-036 通过（4 个服务已成功启动并注册 Nacos）；服务端口 9000/9100/9200/9400 可达
- **测试类型**：接口测试
- **关联需求ID**：F-001 / US-001（Given 4 个服务启动完成 Then 健康检查接口返回正常）
- **测试数据**：`http://127.0.0.1:9100/api/v1/auth/health`、`http://127.0.0.1:9200/api/v1/biz/health`、`http://127.0.0.1:9400/api/v1/system/health`（直连）；`http://127.0.0.1:9000/api/v1/auth/health`（经网关，白名单）
- **测试步骤**：
  1. 直连调用 auth-service 健康检查：`GET http://127.0.0.1:9100/api/v1/auth/health`，记录 HTTP 状态码与响应体
  2. 直连调用 biz-service 健康检查：`GET http://127.0.0.1:9200/api/v1/biz/health`，记录 HTTP 状态码与响应体
  3. 直连调用 system-service 健康检查：`GET http://127.0.0.1:9400/api/v1/system/health`，记录 HTTP 状态码与响应体
  4. 经网关调用 auth 健康检查：`GET http://127.0.0.1:9000/api/v1/auth/health`，记录 HTTP 状态码与响应体
- **预期结果**：
  1. 4 个健康检查请求均返回 HTTP 200
  2. 响应体为 ApiResult 结构（code=200、message=正常、data 含服务名/状态/版本/时间戳），服务状态为正常
  3. 说明：biz/system 经网关访问需携带 Token（非白名单），本用例以直连验证服务可用性为主，网关路径仅验证白名单内 auth/health
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 `test_tc053_health_probe`，TC-053-1~4 断言）
- **测试过程与结论**：**阻塞（环境）**。脚本 TC-053-1~4 共 4 项探活全部按环境阻塞 SKIP（不计失败）：端口 9100/9200/9400/9000 均无服务监听（WinError 10061 连接被拒），原因是 Nacos(8848) 不可达导致 4 个服务未启动（FT-033~036 前置未满足）。前置条件明确要求"服务已启动"，按环境阻塞记录，不作为任务失败；待基础设施就绪后需回归执行。

### 模块：构建/依赖配置（F-001） - 功能测试（构建执行 + 服务启动验证）
#### FT-031：mvn package 构建通过且无依赖解析错误（P0）
- **用例ID**：FT-031
- **用例名称**：执行 mvn package 构建成功，依赖解析无冲突、无 spring-cloud-starter-bootstrap 相关错误
- **所属模块**：全项目 / 构建验证
- **优先级**：P0
- **前置条件**：UT-097~102 通过（5 个 pom 已正确修改）；Maven 可用（建议 Maven 3.8+/JDK 21）
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001 / AC-2（mvn package 构建通过、无依赖解析错误）
- **测试数据**：项目根 pom；执行命令 `mvn package -DskipTests`（或全量 `mvn package`）
- **测试步骤**：
  1. 在项目根目录执行 `mvn package`（含 -DskipTests 或全量，视执行环境），记录退出码
  2. 检查构建日志：是否存在依赖解析错误、依赖冲突、`spring-cloud-starter-bootstrap` 解析失败等异常
  3. 检查构建结果：BUILD SUCCESS 或 BUILD FAILURE
- **预期结果**：
  1. 构建退出码为 0（BUILD SUCCESS）
  2. 构建日志无依赖解析错误/冲突（bootstrap 依赖 4.1.2 由 BOM 托管，与其他 Spring Cloud 组件兼容）
  3. 满足验收 AC-2「mvn package 构建通过、无依赖解析错误」
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-031 测试步骤与记录）
- **测试过程与结论**：**通过**。2026-08-09 18:18 在项目根目录执行 `mvn package -DskipTests`（Maven 3.9.16 / JDK 21.0.9），退出码 0，构建日志出现 `[INFO] BUILD SUCCESS`；日志无 ERROR、无依赖解析错误/冲突、无 `spring-cloud-starter-bootstrap` 解析失败（bootstrap 依赖 4.1.2 由 BOM 托管，兼容）。满足验收 AC-2。

#### FT-032：构建后 deploy 目录产出 4 个可执行 jar（P0）
- **用例ID**：FT-032
- **用例名称**：mvn package 后 deploy 目录存在 cloudoffice-gateway/auth-service/biz-service/system-service 4 个可执行 jar
- **所属模块**：deploy / 构建产物
- **优先级**：P0
- **前置条件**：FT-031 通过（构建成功）
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001（修复后重新构建 4 个 jar 并启动服务）
- **测试数据**：`<项目根>\deploy\cloudoffice-gateway.jar`、`<项目根>\deploy\cloudoffice-auth-service.jar`、`<项目根>\deploy\cloudoffice-biz-service.jar`、`<项目根>\deploy\cloudoffice-system-service.jar`
- **测试步骤**：
  1. 检查 deploy 目录下 4 个 jar 文件存在且为文件类型：`Test-Path -PathType Leaf`
  2. 检查各 jar 时间戳为本次构建时间（非旧产物）
- **预期结果**：
  1. 4 个 jar 均存在且为文件类型，命名符合既有脚本契约（deploy-start-*.sh/ps1 引用的文件名）
  2. 构建产物为最新（可执行 jar，含 BOOT-INF 结构）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-032 测试步骤与记录）
- **测试过程与结论**：**通过**。deploy 目录下 4 个 jar 均存在且为文件类型：cloudoffice-gateway.jar（70,635,649 字节）、cloudoffice-auth-service.jar（75,560,587 字节）、cloudoffice-biz-service.jar（58,579,312 字节）、cloudoffice-system-service.jar（58,579,748 字节）；时间戳均为 2026-08-09 18:18（本次构建时间），为最新可执行 jar（含 BOOT-INF 结构），命名符合 deploy-start-*.ps1/sh 脚本契约。

#### FT-033：启动 gateway 服务，日志无 bootstrap 相关报错（P0）
- **用例ID**：FT-033
- **用例名称**：启动 cloudoffice-gateway（端口 9000），启动日志不再出现 No spring.config.import property has been defined
- **所属模块**：cloudoffice-gateway / 启动验证
- **优先级**：P0
- **前置条件**：FT-032 通过（jar 已就绪）；Nacos 2.3（8848）、MariaDB（3306）、Redis（6379）已启动且网络可达；deploy/env.json 已注入环境变量
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001 / AC-3（启动日志不再出现该报错）
- **测试数据**：`<项目根>\deploy\cloudoffice-gateway.jar`；启动命令见 deploy/scripts/deploy-start-gateway.sh/ps1
- **测试步骤**：
  1. 按部署脚本启动 gateway 服务（或 `java -jar deploy/cloudoffice-gateway.jar`），记录启动过程日志
  2. 检查日志中是否出现 `No spring.config.import property has been defined`
  3. 检查服务是否成功启动（Started GatewayApplication / Tomcat started on port 9000）
- **预期结果**：
  1. 启动日志不再出现 `No spring.config.import property has been defined`（bootstrap 依赖生效，import-check 跳过）
  2. 服务启动成功，监听端口 9000，注册到 Nacos
  3. 满足验收 AC-3「服务启动日志不再出现 No spring.config.import property has been defined」
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-033 测试步骤与记录）
- **测试过程与结论**：**阻塞（环境）**。环境探测（2026-08-09 18:17）显示 Nacos(8848) 不可达（端口未监听），gateway 依赖 Nacos discovery 注册，前置条件"基础设施可达"不满足，未执行启动。按环境阻塞 SKIP 记录，不作为任务失败；待 Nacos 启动后需回归执行启动验证。

#### FT-034：启动 auth-service 服务，日志无 bootstrap 相关报错（P0）
- **用例ID**：FT-034
- **用例名称**：启动 cloudoffice-auth-service（端口 9100），启动日志不再出现 No spring.config.import property has been defined
- **所属模块**：cloudoffice-auth-service / 启动验证
- **优先级**：P0
- **前置条件**：FT-032 通过（jar 已就绪）；基础设施可达；env 已注入
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001 / AC-3（auth 是含 nacos-config 的 import-check 主要报错服务）
- **测试数据**：`<项目根>\deploy\cloudoffice-auth-service.jar`；启动命令见 deploy/scripts/deploy-start-auth.sh/ps1
- **测试步骤**：
  1. 按部署脚本启动 auth-service，记录启动过程日志
  2. 检查日志中是否出现 `No spring.config.import property has been defined`
  3. 检查服务是否成功启动（Started AuthApplication / Tomcat started on port 9100）
- **预期结果**：
  1. 启动日志不再出现 `No spring.config.import property has been defined`
  2. 服务启动成功，监听端口 9100，注册到 Nacos（认证底座服务可用，为 API 回归提供环境）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-034 测试步骤与记录）
- **测试过程与结论**：**阻塞（环境）**。Nacos(8848) 不可达，服务无法完成注册，前置条件不满足。附加证据：在 FT-038 边界验证中实际尝试启动了 auth-service（18:19:38~43），日志确认 **import-check 报错出现次数=0**（bootstrap 依赖已生效），但服务最终因 RSA 密钥解析失败（`RSA key loading failed: Unable to decode key`，属 T-02 回归报告 RSA 密钥子项，非本任务范围）未完成启动。按环境阻塞记录，不作为任务失败；待基础设施就绪且 RSA 密钥子项处理后需回归执行。

#### FT-035：启动 biz-service 服务，日志无 bootstrap 相关报错（P0）
- **用例ID**：FT-035
- **用例名称**：启动 cloudoffice-biz-service（端口 9200），启动日志不再出现 No spring.config.import property has been defined
- **所属模块**：cloudoffice-biz-service / 启动验证
- **优先级**：P0
- **前置条件**：FT-032 通过（jar 已就绪）；基础设施可达；env 已注入
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001 / AC-3
- **测试数据**：`<项目根>\deploy\cloudoffice-biz-service.jar`；启动命令见 deploy/scripts/deploy-start-biz.sh/ps1
- **测试步骤**：
  1. 按部署脚本启动 biz-service，记录启动过程日志
  2. 检查日志中是否出现 `No spring.config.import property has been defined`
  3. 检查服务是否成功启动（Started BizApplication / Tomcat started on port 9200）
- **预期结果**：
  1. 启动日志不再出现 `No spring.config.import property has been defined`
  2. 服务启动成功，监听端口 9200，注册到 Nacos
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-035 测试步骤与记录）
- **测试过程与结论**：**阻塞（环境）**。Nacos(8848) 不可达，biz-service 依赖 Nacos discovery/config，服务无法启动注册，前置条件不满足。按环境阻塞 SKIP 记录，不作为任务失败；待 Nacos 启动后需回归执行。

#### FT-036：启动 system-service 服务，日志无 bootstrap 相关报错（P0）
- **用例ID**：FT-036
- **用例名称**：启动 cloudoffice-system-service（端口 9400），启动日志不再出现 No spring.config.import property has been defined
- **所属模块**：cloudoffice-system-service / 启动验证
- **优先级**：P0
- **前置条件**：FT-032 通过（jar 已就绪）；基础设施可达；env 已注入
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001 / AC-3
- **测试数据**：`<项目根>\deploy\cloudoffice-system-service.jar`；启动命令见 deploy/scripts/deploy-start-system.sh/ps1
- **测试步骤**：
  1. 按部署脚本启动 system-service，记录启动过程日志
  2. 检查日志中是否出现 `No spring.config.import property has been defined`
  3. 检查服务是否成功启动（Started SystemApplication / Tomcat started on port 9400）
- **预期结果**：
  1. 启动日志不再出现 `No spring.config.import property has been defined`
  2. 服务启动成功，监听端口 9400，注册到 Nacos
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-036 测试步骤与记录）
- **测试过程与结论**：**阻塞（环境）**。Nacos(8848) 不可达，system-service 依赖 Nacos discovery/config，服务无法启动注册，前置条件不满足。按环境阻塞 SKIP 记录，不作为任务失败；待 Nacos 启动后需回归执行。

#### FT-037：bootstrap.yml 生效——Nacos discovery/config server-addr 被正确加载（P0）
- **用例ID**：FT-037
- **用例名称**：服务启动过程中 bootstrap.yml 生效，Nacos discovery/config server-addr 被加载、服务注册到 Nacos
- **所属模块**：全服务 / 配置引导验证
- **优先级**：P0
- **前置条件**：FT-033~036 通过（4 个服务均已启动）
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001 / AC-4（bootstrap.yml 生效，Nacos discovery/config server-addr 被正确加载）
- **测试数据**：4 个服务启动日志；Nacos 控制台 `http://127.0.0.1:8848/nacos`（服务列表）
- **测试步骤**：
  1. 检查服务启动日志：确认 bootstrap 阶段加载 bootstrap.yml（日志出现 bootstrap 上下文创建/加载线索，或通过 Nacos 配置拉取行为确认）
  2. 确认日志中 Nacos discovery/config server-addr 指向 `127.0.0.1:8848`（或 env 注入的 NACOS_ADDR）
  3. 打开 Nacos 控制台服务列表，确认 cloudoffice-gateway/auth-service/biz-service/system-service 4 个服务已注册（实例数 ≥1）
- **预期结果**：
  1. bootstrap.yml 在应用上下文创建前被加载（Nacos server-addr 生效，配置引导链路打通）
  2. Nacos 控制台可见 4 个服务均已注册（gateway 不依赖 nacos-config 但也按 ADR-014 统一引入 bootstrap，discovery 注册正常）
  3. 满足验收 AC-4「bootstrap.yml 生效，Nacos discovery/config server-addr 被正确加载」
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-037 测试步骤与记录）
- **测试过程与结论**：**阻塞（环境，核心证据已验证）**。Nacos(8848) 不可达，4 个服务未启动，Nacos 控制台注册确认无法执行（步骤 3 环境阻塞）。附加证据：FT-038 边界验证中 auth-service 启动日志（18:19:38~40）确认 bootstrap.yml 引导链路生效——启动早期 nacos-config 客户端即初始化并尝试连接 `127.0.0.1:8848`（`[req-serv] nacos-server port:8848`、`Try to connect to server on start up, server: {serverIp = '127.0.0.1', server main port = 8848}`、`LOCAL_SNAPSHOT_PATH:C:\Users\jenemy\nacos\config`），证明 Nacos discovery/config server-addr 被正确加载（步骤 1/2 核心证据 ✅）。待基础设施就绪后需回归确认 Nacos 控制台服务注册。

#### FT-038：边界——Nacos 不可达时启动失败并报连接异常（P2，边界）
- **用例ID**：FT-038
- **用例名称**：引入 bootstrap 依赖后若 Nacos 不可达，服务启动失败并报 Nacos 连接异常（环境问题可预期）
- **所属模块**：全服务 / 边界场景
- **优先级**：P2
- **前置条件**：TASK-001 编码已完成；可临时停止 Nacos 或改 NACOS_ADDR 指向不可达地址（可选，视环境）
- **测试类型**：功能测试
- **关联需求ID**：F-001 / US-001（PRD 边界情况：引入依赖后 Nacos 不可达，服务启动失败，报连接 Nacos 异常）
- **测试数据**：`NACOS_ADDR` 指向不可达地址；任一服务 jar
- **测试步骤**：
  1. （可选）将 NACOS_ADDR 临时指向不可达地址（如 127.0.0.1:18848），或直接停止 Nacos 容器
  2. 尝试启动任一服务，观察启动过程与报错
  3. 恢复 Nacos 环境，重新启动服务确认恢复正常
- **预期结果**：
  1. 服务启动失败，日志报 Nacos 连接异常（而非 import-check 报错）——证明 bootstrap 引导链路已生效、失败原因属环境不可达
  2. 恢复 Nacos 后服务可正常启动（环境问题而非依赖问题）
  3. 本用例为边界确认，若执行环境不允许破坏性操作可记录为跳过（不视为缺陷）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-038 测试步骤与记录）
- **测试过程与结论**：**通过（核心断言；恢复验证环境阻塞）**。当前环境 Nacos 恰好不可达（天然满足步骤 1 场景），实际启动 auth-service（18:19:38~43）验证：①日志 **无任何 `No spring.config.import property has been defined`**（import-check 已跳过，bootstrap 引导链路生效 ✅）；②出现 **Nacos 连接异常**（`Server check fail, please check server 127.0.0.1, port 9848 is available`，nacos-client 2.3.2，UNAVAILABLE: io exception ✅）；③服务启动失败，直接原因另含 RSA 密钥解析失败（`RSA key loading failed: Unable to decode key`，属 T-02 回归报告 RSA 密钥子项，非本任务范围）——失败原因属环境问题而非依赖问题，符合预期 1/3。步骤 3（恢复 Nacos 后重启验证）因 Nacos 未启动且 RSA 密钥子项未处理无法执行，按用例说明"环境不允许破坏性操作可记录为跳过，不视为缺陷"，恢复验证部分环境阻塞。

### 模块：构建/依赖配置（F-001） - UI 测试（无 UI 变更确认）
#### UIT-012：客户端 UI 无任何变更（P1）
- **用例ID**：UIT-012
- **用例名称**：bootstrap 依赖引入为纯构建配置变更，客户端应用界面与交互无任何变更
- **所属模块**：客户端（cloudoffice-flutter-app）/ 无 UI 变更
- **优先级**：P1
- **前置条件**：TASK-001 编码已完成（git 变更已产生）
- **测试类型**：UI 测试
- **关联需求ID**：F-001 / US-001 / AC-5（无客户端代码改动）
- **测试数据**：git 变更清单（`git status --porcelain` + `git diff --name-only`）
- **测试步骤**：
  1. 执行 `git status --porcelain` 与 `git diff --name-only`，获取本任务变更文件清单
  2. 检查变更清单中是否出现 `cloudoffice-flutter-app/lib` 下界面代码（*.dart）、pubspec.yaml、客户端构建配置
  3. （可选）确认客户端构建产物路径与运行时行为不受 pom 变更影响
- **预期结果**：
  1. 变更清单中无任何 `cloudoffice-flutter-app/lib` 下 .dart 界面文件与客户端配置文件改动
  2. 客户端应用界面/交互/运行行为无任何变更（本任务为纯后端构建依赖配置变更）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（UIT-012 测试步骤与记录）
- **测试过程与结论**：**通过**。单元测试脚本 UT-104-1 断言（2026-08-09 18:17:36）确认：`git status --short` 变更清单中 `cloudoffice-flutter-app/` 路径下文件数=0，无任何 .dart 界面文件、pubspec.yaml 或客户端构建配置改动；本任务为纯后端构建依赖配置变更，客户端界面/交互/运行行为无任何变更，满足 AC-5。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 13（UT-097~104、TC-052、FT-031、FT-032、FT-038、UIT-012） |
| 失败 | 0 |
| 阻塞 | 6（TC-053、FT-033、FT-034、FT-035、FT-036、FT-037——Nacos 8848 不可达，环境阻塞） |
| 跳过 | 0 |

> 说明：FT-038 核心边界断言（无 import-check 报错 + Nacos 连接异常）验证通过，其"恢复 Nacos 后重启"步骤因环境阻塞未执行，按用例说明不视为缺陷；阻塞用例均需在基础设施（Nacos/MariaDB/Redis）就绪后回归执行（见风险评估）。

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| Nacos/MariaDB/Redis 基础设施未启动 | 服务启动验证（FT-033~037）阻塞，无法确认修复效果 | 按部署文档先启动基础设施（docker compose），再执行启动验证；本次执行时 Nacos(8848) 不可达（MariaDB/Redis 可达），FT-033~037 与 TC-053 已按环境阻塞记录 |
| 仅根 pom 声明而未在模块引入 | 启动仍报 import-check 错误，修复无效 | 已设计 UT-098~101 逐一校验 4 个模块实际引入，防漏（本次全部通过） |
| 显式声明 5.x 版本 | 与 Spring Cloud 2023.0.1 不兼容导致构建/启动异常 | 已设计 UT-102 版本契约负向校验，禁止 5.x（本次通过） |
| 环境变量（env.json）未正确注入 | RSA 密钥/数据库连接失败，服务无法启动 | 先执行 deploy-check-env 脚本核验环境；TASK-001 仅处理 bootstrap 依赖，RSA 密钥契约为 T-02 另一子项（后续任务） |
| 回归报告 T-02 的 RSA 密钥子项未处理 | 即使 bootstrap 修复，服务仍可能因密钥解析失败无法启动 | 明确 TASK-001 范围仅 bootstrap 依赖；本次启动验证已实证：import-check 报错消失（bootstrap 修复生效），auth-service 启动失败于 RSA 密钥解析（`RSA key loading failed: Unable to decode key`），归入后续任务（F-002 / T-02 RSA 密钥子项）处理，本任务用例按环境阻塞记录 |

## 五、签名确认
- 测试工程师（TE）：2026-08-09 执行完成，通过 13 / 失败 0 / 阻塞 6（环境）
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
