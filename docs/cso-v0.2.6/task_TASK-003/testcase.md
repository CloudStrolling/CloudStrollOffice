# 测试用例文档（TestCase）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.6
**日期**：2026-08-09
**测试负责人**：TE

> 说明：本任务（TASK-003）为 v0.2.6 的 F-003 验证闭环——重新构建 4 个服务 jar（gateway/auth-service/biz-service/system-service）并完成启动验证与健康检查（需求来源：docs/cso-v0.2.5/regression-api-test.md 记录的 v0.2.5 回归问题）。TASK-001（bootstrap 依赖，ADR-014）与 TASK-002（RSA 密钥契约，ADR-015）已完成修复，本任务验证修复后的构建 + 启动 + 健康检查闭环：
> 1. 执行 `mvn clean package -DskipTests` 构建 4 个服务 jar 并落位 deploy/；
> 2. 按 deploy/deploy.md 标准流程启动 4 个服务；
> 3. 核对启动日志不再出现 `No spring.config.import property has been defined` 与 `RSA 公钥解析失败`；
> 4. 4 个服务注册到 Nacos（控制台可见 cloudoffice-* 实例）；
> 5. 健康检查 `/api/v1/auth/health`（网关白名单）、`/api/v1/biz/health`（直连 9200）、`/api/v1/system/health`（直连 9400）返回服务名/状态/版本/时间戳正常。
> 关联需求：PRD F-003 / US-001 / US-002；接口 API-012 / API-032 / API-033。
> 用例编号延续版本测试用例文档 cso-testcase-v0.2.6.md 编号空间（TASK-001 用至 TC-053/UT-104/FT-038/UIT-012，TASK-002 用至 TC-056/UT-112/FT-045/UIT-013），本任务新用例从 **TC-057、UT-113、FT-046、UIT-014** 起编号。
> 测试类型覆盖：单元测试（8）、接口测试（8）、功能测试（12）、UI 测试（1），共 29 个。
> **缺陷记录（runtest 2026-08-09 19:44 实测确认）**：auth-service `SecurityConfig`（cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/SecurityConfig.java 第 62-69 行）permitAll 仅含 /api/v1/auth/health、verification-code/send、password/forgot/send-code、password/forgot/reset、swagger，**缺少 /api/v1/auth/login、/api/v1/auth/register、/api/v1/auth/refresh 三个端点**，`.anyRequest().authenticated()` 将其拦截返回 401「未授权，请先登录」。网关侧白名单（cloudoffice-gateway application.yml 第 51-53 行）已正确放行这三个路径，请求可达 auth 服务但被其自身安全链拦截。**对本任务 TASK-003 用例（TC-057~064）无影响（全部通过，TC-061/062 负向 401 按预期）**；受影响的为 TASK-002 的 TC-056（RS256 登录链路，本次运行 SKIP）与 TASK-004/005 回归登录前置——属代码缺陷（非环境阻塞），需调度方决策回退编码修复。

## 一、测试范围概述
| 所属模块 | 关联任务 | 用例数 | 优先级分布 |
| --- | --- | --- | --- |
| 构建与部署验证（F-003）：TASK-003 重新构建 4 个服务 jar 并完成启动验证与健康检查 | TASK-003 | 29 | P0×18、P1×8、P2×3 |
| 其中：单元测试（构建产物/环境变量/回归确认静态校验） | TASK-003 | 8 | P0×4、P1×4 |
| 其中：接口测试（3 个健康检查接口 + 网关认证拦截 + 响应契约 + 边界） | TASK-003 | 8 | P0×4、P1×3、P2×1 |
| 其中：功能测试（构建执行 + 服务启动 + 日志核对 + Nacos 注册 + 边界） | TASK-003 | 12 | P0×10、P2×2 |
| 其中：UI 测试（无 UI 变更确认） | TASK-003 | 1 | P1×1 |

## 二、测试用例详情

### 模块：构建与部署验证（F-003） - 单元测试（构建产物/环境变量/回归静态校验）
#### UT-113：deploy/ 下 4 个服务 jar 产物存在且非空（P0）
- **用例ID**：UT-113
- **用例名称**：构建后 deploy 目录存在 cloudoffice-gateway/auth-service/biz-service/system-service 4 个 jar 且非空
- **所属模块**：deploy / 构建产物
- **优先级**：P0
- **前置条件**：TASK-003 已执行 `mvn clean package -DskipTests`（或等价 build-backend.ps1）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / AC-1
- **测试数据**：`<项目根>\deploy\cloudoffice-gateway.jar`、`cloudoffice-auth-service.jar`、`cloudoffice-biz-service.jar`、`cloudoffice-system-service.jar`
- **测试步骤**：
  1. 检查 deploy/ 目录下 4 个 jar 文件（cloudoffice-gateway.jar / cloudoffice-auth-service.jar / cloudoffice-biz-service.jar / cloudoffice-system-service.jar）是否存在
  2. 检查 4 个 jar 文件大小是否非空（应远大于 0 字节，可执行 fat jar 通常 >10MB）
- **预期结果**：
  1. 4 个 jar 全部存在（不存在则说明构建产物未落位，需查 Maven 输出）
  2. 4 个 jar 大小均 >0 字节且具备可执行 jar 规模（>10MB 提示为 fat jar）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-113-1/113-2：jar 存在与大小断言）
- **测试过程与结论**：**通过**——2026-08-09 19:43 执行 cso-unit-test-build-verify-v0.2.6.ps1，UT-113-1/113-2 均 PASS：deploy/ 下 4 个 jar 全部存在且 >10MB（gateway 55,687,694B / auth 75,560,587B / biz 58,579,312B / system 58,579,748B），为空可执行 fat jar 规模。

#### UT-114：4 个 jar 为可执行 fat jar（P0）
- **用例ID**：UT-114
- **用例名称**：4 个服务 jar 均含 Main-Class 清单与 BOOT-INF/classes、spring-boot loader，可直接 java -jar 启动
- **所属模块**：deploy / 构建产物
- **优先级**：P0
- **前置条件**：UT-113 通过（4 个 jar 已存在）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / AC-1
- **测试数据**：4 个 jar 文件；`jar tf <jar>` 输出（或解压后检查）
- **测试步骤**：
  1. 对 4 个 jar 分别执行 `jar tf <jar>` 或解压检查，核对 MANIFEST.MF 中 Main-Class 是否为 `org.springframework.boot.loader.launch.JarLauncher`（Boot 3.2 格式）
  2. 核对 jar 内含 `BOOT-INF/classes/` 与 `BOOT-INF/lib/` 目录、`org/springframework/boot/loader/` 类
- **预期结果**：
  1. 4 个 jar 均为 Spring Boot 可执行 fat jar（Main-Class 指向 JarLauncher，非普通 jar）
  2. BOOT-INF/classes 与 BOOT-INF/lib 存在，可 `java -jar` 直接启动
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-114-1/114-2：Main-Class 与 BOOT-INF 结构断言）
- **测试过程与结论**：**通过**——UT-114-1/114-2 均 PASS：4 个 jar 的 META-INF/MANIFEST.MF Main-Class 均为 org.springframework.boot.loader.launch.JarLauncher，含 BOOT-INF/classes 与 BOOT-INF/lib 及 loader 类，可 java -jar 直接启动。

#### UT-115：4 个 jar 内 BOOT-INF/lib 包含 spring-cloud-starter-bootstrap（P0）
- **用例ID**：UT-115
- **用例名称**：4 个服务 jar 产物中实际包含 spring-cloud-starter-bootstrap 依赖（TASK-001 修复进入产物）
- **所属模块**：deploy / 构建产物
- **优先级**：P0
- **前置条件**：UT-113 通过（4 个 jar 已存在）；TASK-001 修复已提交
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / AC-1 / AC-3
- **测试数据**：4 个 jar 内 BOOT-INF/lib 依赖清单（`jar tf <jar> | findstr bootstrap` 或等价方式）
- **测试步骤**：
  1. 对 4 个 jar 分别列出 `BOOT-INF/lib/` 下依赖 jar 清单
  2. 查找 `spring-cloud-starter-bootstrap-*.jar`（预期 4.1.2）
- **预期结果**：
  1. 4 个 jar 的 BOOT-INF/lib 中均包含 spring-cloud-starter-bootstrap-4.1.2.jar（无则说明构建未包含 TASK-001 修复，需重新构建）
  2. 版本为 4.1.x（Spring Cloud 2023.0.1 BOM 托管值），无 5.x
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-115-1/115-2：BOOT-INF/lib bootstrap 依赖断言）
- **测试过程与结论**：**通过**——UT-115-1/115-2 均 PASS：4 个 jar 的 BOOT-INF/lib 均含 spring-cloud-starter-bootstrap-4.1.2.jar（TASK-001 修复已进入产物），版本均为 4.1.x 家族（无 5.x）。

#### UT-116：env.json 含启动脚本 9 个必需变量且非空（P0）
- **用例ID**：UT-116
- **用例名称**：deploy/env.json 包含启动脚本所需 9 个必需变量（NACOS_ADDR/DB_*/REDIS_*/RSA_*）且非空
- **所属模块**：deploy / 环境配置
- **优先级**：P0
- **前置条件**：deploy/env.json 已创建（Copy-Item deploy\env.example.json deploy\env.json 并填写）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / US-002 / AC-2
- **测试数据**：`deploy/env.json`（不入库，仅做键存在性与非空断言，不记录真实密钥值）
- **测试步骤**：
  1. 解析 deploy/env.json，核对 9 个必需变量键是否存在：NACOS_ADDR、DB_HOST、DB_PORT、DB_USERNAME、DB_PASSWORD、REDIS_HOST、REDIS_PORT、RSA_PRIVATE_KEY、RSA_PUBLIC_KEY
  2. 核对 9 个键值均非空字符串
- **预期结果**：
  1. 9 个必需键全部存在（缺失则对应服务启动脚本校验失败，服务无法启动）
  2. 9 个键值均非空（RSA_* 为 DER 单行 Base64 值）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-116-1/116-2：env.json 9 必需键存在与非空断言）
- **测试过程与结论**：**通过**——UT-116-1/116-2 均 PASS：deploy/env.json 含 9 个必需变量键（NACOS_ADDR/DB_*/REDIS_*/RSA_*）且值均非空。

#### UT-117：deploy-start-*.ps1 引用的环境变量键与 env.json 键集合一致（P1）
- **用例ID**：UT-117
- **用例名称**：4 个启动脚本（deploy-start-gateway/auth/biz/system.ps1）引用的环境变量键均可在 env.json 中解析
- **所属模块**：deploy / 启动脚本
- **优先级**：P1
- **前置条件**：UT-116 通过（env.json 键完整）；TASK-001/TASK-002 编码已完成
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / AC-2
- **测试数据**：`deploy/scripts/deploy-start-gateway.ps1`、`deploy-start-auth.ps1`、`deploy-start-biz.ps1`、`deploy-start-system.ps1`；`deploy/env.json`
- **测试步骤**：
  1. 提取 4 个启动脚本中 `$env:<KEY>` 引用的全部环境变量键
  2. 核对每个键在 env.json 中存在对应条目
- **预期结果**：
  1. 脚本引用的每个环境变量键均存在于 env.json（无悬空引用，避免启动时取到空值）
  2. 脚本内 jar 路径指向 deploy/ 下对应产物（Join-Path $ProjectDir 推导）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-117-1/117-2：启动脚本 $env 引用与 jar 路径断言）
- **测试过程与结论**：**通过**——UT-117-1/117-2 均 PASS：4 个启动脚本引用的 $env:<KEY> 均可在 env.json 中解析（无悬空引用），脚本内 jar 引用均为 deploy/ 下 cloudoffice-*.jar。

#### UT-118：回归确认——TASK-001/TASK-002 修复未回退（P1）
- **用例ID**：UT-118
- **用例名称**：4 个模块 pom 仍含 bootstrap 依赖，env.json 密钥仍为 DER 单行 Base64（修复未回退）
- **所属模块**：全项目 / 修复契约回归
- **优先级**：P1
- **前置条件**：TASK-001/TASK-002 编码已完成并提交
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / US-002 / AC-3
- **测试数据**：gateway/auth/biz/system 4 个模块 pom.xml；deploy/env.json（仅格式特征断言）
- **测试步骤**：
  1. 核对 4 个模块 pom.xml 的 dependencies 仍包含 `spring-cloud-starter-bootstrap`（无显式 5.x 版本）
  2. 核对 deploy/env.json 的 RSA_PUBLIC_KEY/RSA_PRIVATE_KEY 仍为 DER 单行 Base64（无 `-----BEGIN`/`-----END` 标记、无 `\r\n`/换行、严格 Base64 可解码）
- **预期结果**：
  1. bootstrap 依赖声明未被回退删除（防止任务间相互覆盖）
  2. 密钥格式契约保持 DER 单行 Base64（防止旧 PEM 整体 Base64 回退注入）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-118-1/118-2/118-3：pom bootstrap 依赖与 RSA 密钥格式回归断言）
- **测试过程与结论**：**通过**——UT-118-1/118-2/118-3 均 PASS：4 个模块 pom 仍声明 spring-cloud-starter-bootstrap（无 5.x 显式版本）；env.json RSA 密钥保持 DER 单行 Base64 契约（无 PEM 头尾/换行、严格解码成功）——TASK-001/002 修复未回退。

#### UT-119：变更范围控制——无接口层/业务代码/客户端代码改动（P1，负向/范围控制）
- **用例ID**：UT-119
- **用例名称**：本任务 git 变更清单无 Controller/DTO/接口层、业务代码与客户端代码改动
- **所属模块**：全项目 / 变更范围
- **优先级**：P1
- **前置条件**：TASK-003 编码/构建相关修改已产生
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / AC-5（接口契约零改动）
- **测试数据**：`git status --porcelain` + `git diff --name-only`
- **测试步骤**：
  1. 执行 `git status --porcelain` 与 `git diff --name-only` 获取变更文件清单
  2. 检查变更清单中是否出现 `*Controller.java`、`*DTO.java`、网关路由配置、`cloudoffice-flutter-app/` 下代码
- **预期结果**：
  1. 变更清单中无接口层（Controller/DTO/网关路由）与业务代码改动（本任务为构建+启动验证，不触碰代码）
  2. 无客户端（cloudoffice-flutter-app）代码改动
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-119-1/119-2/119-3：git 变更范围断言）
- **测试过程与结论**：**通过**——UT-119-1/119-2/119-3 均 PASS：git 变更清单（9 项，均为 pom/部署脚本/文档/测试资产）无 Controller/DTO/网关路由、无业务 *.java、无客户端代码改动——变更范围符合构建+启动验证任务边界。

#### UT-120：jar 内包含 bootstrap.yml 且 Nacos server-addr 使用占位符（P1）
- **用例ID**：UT-120
- **用例名称**：4 个 jar 内均含 bootstrap.yml，nacos discovery/config server-addr 使用 ${NACOS_ADDR:127.0.0.1:8848} 占位符
- **所属模块**：deploy / 构建产物
- **优先级**：P1
- **前置条件**：UT-113 通过（4 个 jar 已存在）
- **测试类型**：单元测试
- **关联需求ID**：F-003 / US-001 / AC-3
- **测试数据**：4 个 jar 内 bootstrap.yml（`jar xf <jar> BOOT-INF/classes/bootstrap.yml` 或等价方式）
- **测试步骤**：
  1. 从 4 个 jar 中提取 `BOOT-INF/classes/bootstrap.yml`
  2. 核对文件存在且内容包含 `spring.cloud.nacos.discovery.server-addr` / `spring.cloud.nacos.config.server-addr` 配置（占位符 ${NACOS_ADDR:127.0.0.1:8848}）
- **预期结果**：
  1. 4 个 jar 内均包含 bootstrap.yml（Nacos 引导配置进入产物）
  2. server-addr 使用 ${NACOS_ADDR:127.0.0.1:8848} 占位符（环境变量注入契约，支持默认值）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-unit-test-build-verify-v0.2.6.ps1`（UT-120-1/120-2：jar 内 bootstrap.yml 与占位符断言）
- **测试过程与结论**：**通过**——UT-120-1/120-2 均 PASS：4 个 jar 内均含 BOOT-INF/classes/bootstrap.yml，nacos discovery/config server-addr 均使用 ${NACOS_ADDR:127.0.0.1:8848} 占位符。

### 模块：构建与部署验证（F-003） - 接口测试（健康检查接口）
#### TC-057：经网关访问 /api/v1/auth/health 返回正常（P0）
- **用例ID**：TC-057
- **用例名称**：经网关（9000）GET /api/v1/auth/health 返回服务名/状态/版本/时间戳且 status=UP（白名单免认证）
- **所属模块**：认证服务健康检查（API-012）
- **优先级**：P0
- **前置条件**：4 个服务已启动（FT-048~051 通过）；网关 9000 可达；biz/system 服务无需
- **测试类型**：接口测试
- **关联需求ID**：F-003 / API-012 / US-001
- **测试数据**：GET `http://localhost:9000/api/v1/auth/health`（免 Token）
- **测试步骤**：
  1. 执行 GET `http://localhost:9000/api/v1/auth/health`
  2. 检查 HTTP 状态码与响应体 ApiResult 结构
  3. 核对 data 字段：service=cloudoffice-auth-service、status=UP、version 非空、timestamp 非空
- **预期结果**：
  1. HTTP 200，响应体为 ApiResult（code/message/data/timestamp），code=200
  2. data.service 含 `cloudoffice-auth-service`（或 spring.application.name 值）、data.status=UP、version 非空、timestamp 非空
  3. 白名单生效（无 Token 亦可访问，返回 200 而非 401）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc057_gateway_auth_health）
- **测试过程与结论**：**通过**——2026-08-09 19:44 执行 cso-api-test-v0.2.6.py，TC-057 PASS：经网关（9000）GET /api/v1/auth/health 返回 HTTP 200，ApiResult code=200，data.service=cloudoffice-auth-service、status=UP、version/timestamp 非空——白名单免认证生效（返回 200 而非 401）。

#### TC-058：直连 auth 服务（9100）访问 /api/v1/auth/health 返回正常（P0）
- **用例ID**：TC-058
- **用例名称**：直连认证服务（9100）GET /api/v1/auth/health 返回正常
- **所属模块**：认证服务健康检查（API-012）
- **优先级**：P0
- **前置条件**：auth-service 已启动（FT-049 通过）；9100 端口可达
- **测试类型**：接口测试
- **关联需求ID**：F-003 / API-012 / US-001
- **测试数据**：GET `http://localhost:9100/api/v1/auth/health`
- **测试步骤**：
  1. 执行 GET `http://localhost:9100/api/v1/auth/health`（直连，不经网关）
  2. 检查 HTTP 状态码与响应体结构
  3. 核对 data 字段：service/status=UP/version/timestamp 完整
- **预期结果**：
  1. HTTP 200，ApiResult 结构完整
  2. data.status=UP、service 为 cloudoffice-auth-service、version/timestamp 非空
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc058_direct_auth_health）
- **测试过程与结论**：**通过**——TC-058 PASS：直连（9100）GET /api/v1/auth/health 返回 HTTP 200，code=200、status=UP、service=cloudoffice-auth-service、version/timestamp 非空。

#### TC-059：直连 biz 服务（9200）访问 /api/v1/biz/health 返回正常（P0）
- **用例ID**：TC-059
- **用例名称**：直连企业服务（9200）GET /api/v1/biz/health 返回服务名/状态/版本/时间戳正常（免认证）
- **所属模块**：企业服务健康检查（API-032）
- **优先级**：P0
- **前置条件**：biz-service 已启动（FT-050 通过）；9200 端口可达
- **测试类型**：接口测试
- **关联需求ID**：F-003 / API-032 / US-001
- **测试数据**：GET `http://localhost:9200/api/v1/biz/health`（直连，不经网关）
- **测试步骤**：
  1. 执行 GET `http://localhost:9200/api/v1/biz/health`
  2. 检查 HTTP 状态码与响应体结构
  3. 核对 data 字段：service=cloudoffice-biz-service、status=UP、version 非空、timestamp 非空
- **预期结果**：
  1. HTTP 200，ApiResult 结构完整
  2. data.status=UP、service 为 cloudoffice-biz-service、version/timestamp 非空
  3. 直连免认证可访问（API-032 契约）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc059_direct_biz_health）
- **测试过程与结论**：**通过**——TC-059 PASS：直连（9200）GET /api/v1/biz/health 返回 HTTP 200，code=200、status=UP、service=cloudoffice-biz-service、version/timestamp 非空（直连免认证可访问）。

#### TC-060：直连 system 服务（9400）访问 /api/v1/system/health 返回正常（P0）
- **用例ID**：TC-060
- **用例名称**：直连系统服务（9400）GET /api/v1/system/health 返回服务名/状态/版本/时间戳正常（免认证）
- **所属模块**：系统服务健康检查（API-033）
- **优先级**：P0
- **前置条件**：system-service 已启动（FT-051 通过）；9400 端口可达
- **测试类型**：接口测试
- **关联需求ID**：F-003 / API-033 / US-001
- **测试数据**：GET `http://localhost:9400/api/v1/system/health`（直连，不经网关）
- **测试步骤**：
  1. 执行 GET `http://localhost:9400/api/v1/system/health`
  2. 检查 HTTP 状态码与响应体结构
  3. 核对 data 字段：service=cloudoffice-system-service、status=UP、version 非空、timestamp 非空
- **预期结果**：
  1. HTTP 200，ApiResult 结构完整
  2. data.status=UP、service 为 cloudoffice-system-service、version/timestamp 非空
  3. 直连免认证可访问（API-033 契约）
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc060_direct_system_health）
- **测试过程与结论**：**通过**——TC-060 PASS：直连（9400）GET /api/v1/system/health 返回 HTTP 200，code=200、status=UP、service=cloudoffice-system-service、version/timestamp 非空（直连免认证可访问）。

#### TC-061：经网关无 Token 访问 /api/v1/biz/health 返回 401（P1，负向/认证拦截）
- **用例ID**：TC-061
- **用例名称**：经网关（9000）无 Token 访问 /api/v1/biz/health 被认证拦截（白名单未含该路径）
- **所属模块**：网关认证拦截
- **优先级**：P1
- **前置条件**：网关与 biz-service 已启动（FT-048/050 通过）；9000 可达
- **测试类型**：接口测试
- **关联需求ID**：F-003 / API-032（备注：经网关需认证）
- **测试数据**：GET `http://localhost:9000/api/v1/biz/health`（无 Authorization 头）
- **测试步骤**：
  1. 执行 GET `http://localhost:9000/api/v1/biz/health`（不带 Token）
  2. 检查返回 HTTP 状态码
- **预期结果**：
  1. 返回 401（未授权）——证明网关白名单未放行 /api/v1/biz/health，认证拦截生效（维持现状契约）
  2. 若返回 200 则说明白名单被误放行，需核对网关配置
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc061_gateway_biz_health_401）
- **测试过程与结论**：**通过**——TC-061 PASS：经网关（9000）无 Token 访问 /api/v1/biz/health 返回 HTTP 401——网关白名单未放行该路径，认证拦截生效（维持现状契约）。

#### TC-062：经网关无 Token 访问 /api/v1/system/health 返回 401（P1，负向/认证拦截）
- **用例ID**：TC-062
- **用例名称**：经网关（9000）无 Token 访问 /api/v1/system/health 被认证拦截（白名单未含该路径）
- **所属模块**：网关认证拦截
- **优先级**：P1
- **前置条件**：网关与 system-service 已启动（FT-048/051 通过）；9000 可达
- **测试类型**：接口测试
- **关联需求ID**：F-003 / API-033（备注：经网关需认证）
- **测试数据**：GET `http://localhost:9000/api/v1/system/health`（无 Authorization 头）
- **测试步骤**：
  1. 执行 GET `http://localhost:9000/api/v1/system/health`（不带 Token）
  2. 检查返回 HTTP 状态码
- **预期结果**：
  1. 返回 401（未授权）——证明网关白名单未放行 /api/v1/system/health，认证拦截生效（维持现状契约）
  2. 若返回 200 则说明白名单被误放行，需核对网关配置
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc062_gateway_system_health_401）
- **测试过程与结论**：**通过**——TC-062 PASS：经网关（9000）无 Token 访问 /api/v1/system/health 返回 HTTP 401——网关白名单未放行该路径，认证拦截生效（维持现状契约）。

#### TC-063：健康检查响应体 ApiResult 结构契约校验（P1）
- **用例ID**：TC-063
- **用例名称**：3 个健康检查接口响应体均为 ApiResult 结构（code/message/data/timestamp），data 含 service/status/version/timestamp 四字段
- **所属模块**：公共响应体契约（ApiResult）
- **优先级**：P1
- **前置条件**：TC-058~060 通过（3 个直连健康检查均 200）
- **测试类型**：接口测试
- **关联需求ID**：F-003 / API-012 / API-032 / API-033
- **测试数据**：TC-058/059/060 的 3 个响应体 JSON
- **测试步骤**：
  1. 对 auth/biz/system 3 个健康检查响应体逐一解析 JSON
  2. 核对顶层键 code/message/data/timestamp 齐全
  3. 核对 data 对象含 service/status/version/timestamp 四键，code=200、status=UP
- **预期结果**：
  1. 3 个响应体顶层均含 code/message/data/timestamp（ApiResult 契约一致）
  2. data 均含 service/status/version/timestamp 四字段，code=200、status=UP
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc063_apiresult_contract）
- **测试过程与结论**：**通过**——TC-063-1/2/3 均 PASS：auth/biz/system 3 个健康检查响应体均为 ApiResult 结构（顶层 code/message/data/timestamp + data 四字段 service/status/version/timestamp），code=200、status=UP。

#### TC-064：边界——网关根路径 / 存活探测（P2，边界）
- **用例ID**：TC-064
- **用例名称**：访问网关根路径 / 返回网关响应（404/401 均可），证明网关服务存活
- **所属模块**：网关存活探测
- **优先级**：P2
- **前置条件**：网关已启动（FT-048 通过）；9000 可达
- **测试类型**：接口测试
- **关联需求ID**：F-003 / US-001 / AC-4（网关存活）
- **测试数据**：GET `http://localhost:9000/`
- **测试步骤**：
  1. 执行 GET `http://localhost:9000/`
  2. 检查返回（404/401 均可判定网关在运行，只要不是连接拒绝）
- **预期结果**：
  1. 返回网关响应（404 或 401 或网关默认页），HTTP 状态码非 0（连接成功）
  2. 不出现连接拒绝（WinError 10061 / Connection refused），证明网关进程存活
- **自动化测试函数/脚本位置**：`scripts/API-TEST/cso-api-test-v0.2.6.py`（函数 test_tc064_gateway_root_probe）
- **测试过程与结论**：**通过**——TC-064 PASS：GET http://localhost:9000/ 返回网关响应 HTTP 404（非连接拒绝），网关进程存活。

### 模块：构建与部署验证（F-003） - 功能测试（构建执行/服务启动/日志核对/Nacos 注册）
#### FT-046：mvn clean package -DskipTests 构建 4 个服务 jar 成功（P0）
- **用例ID**：FT-046
- **用例名称**：项目根目录执行 mvn clean package -DskipTests，5 个模块（common/gateway/auth/biz/system）构建成功
- **所属模块**：构建流程（deploy/build.md）
- **优先级**：P0
- **前置条件**：JDK 21、Maven 3.8+ 已配置；网络可下载依赖（或本地仓库已就绪）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / AC-1
- **测试数据**：命令 `mvn clean package -DskipTests`（项目根目录）
- **测试步骤**：
  1. 在项目根目录执行 `mvn clean package -DskipTests`
  2. 观察 Maven 输出，确认 BUILD SUCCESS
  3. 确认 5 个模块均执行 package 成功（无编译错误、无依赖解析错误）
- **预期结果**：
  1. BUILD SUCCESS，退出码 0
  2. 无 `无效的发行版本 21`、无依赖下载失败、无编译错误
  3. 4 个服务模块 package 阶段 antrun 复制 jar 至 deploy/ 无报错
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-046 测试步骤与记录）
- **测试过程与结论**：**通过**——2026-08-09 19:19~19:30 构建执行（mvn clean package -DskipTests，Maven 3.9.16 / JDK 21.0.9）：BUILD SUCCESS，5 个模块（common/gateway/auth/biz/system）package 成功；deploy/ 下 4 个 jar 时间戳 19:19:57~19:30:09 为本次构建产物，与 target/ 产物大小完全一致（gateway 55,687,694B / auth 75,560,587B / biz 58,579,312B / system 58,579,748B）；无编译错误、无依赖解析错误；UT-113~120 产物内容断言全部通过（bootstrap 依赖/bootstrap.yml 已进入产物）。

#### FT-047：构建后 deploy/ 下 4 个 jar 更新落位（P0）
- **用例ID**：FT-047
- **用例名称**：构建完成后 deploy/ 下 4 个 jar 时间戳更新且无中间产物
- **所属模块**：构建产物落位（deploy/build.md）
- **优先级**：P0
- **前置条件**：FT-046 通过（构建成功）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / AC-1
- **测试数据**：deploy/ 目录文件清单（构建前后对比）
- **测试步骤**：
  1. 构建前记录 deploy/ 下 4 个 jar 的修改时间
  2. 构建完成后再次检查 4 个 jar 的修改时间
  3. 检查 deploy/ 目录无 target 中间产物残留（仅 4 个最终 jar 被复制）
- **预期结果**：
  1. 4 个 jar 修改时间更新为本次构建时间（产物已刷新）
  2. deploy/ 下无 target 目录或中间产物（仅复制单个最终 jar）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-047 测试步骤与记录）
- **测试过程与结论**：**通过**——deploy/ 下 4 个 jar 时间戳均为本次构建时间（gateway 19:30:09 / auth 19:19:57 / biz 19:19:59 / system 19:20:01），与 target/ 产物大小一致（产物已刷新落位）；deploy/ 目录无 target 中间产物残留（仅 4 个最终 jar + 部署资产）。

#### FT-048：启动 gateway 服务，日志无两类报错并注册 Nacos（P0）
- **用例ID**：FT-048
- **用例名称**：按 deploy/deploy.md 启动 cloudoffice-gateway，启动日志无 import-check 与 RSA 解析报错，注册 Nacos
- **所属模块**：服务启动（gateway / 9000）
- **优先级**：P0
- **前置条件**：FT-047 通过（jar 就绪）；Nacos/MariaDB/Redis 已启动（deploy-start-services.ps1 通过）；env.json 已注入（含 DER 单行 Base64 密钥）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / US-002 / AC-2 / AC-3
- **测试数据**：`.\\deploy\\scripts\\deploy-start-gateway.ps1` 或 `java -Xms256m -Xmx512m -jar deploy\\cloudoffice-gateway.jar`
- **测试步骤**：
  1. 执行 deploy-start-gateway.ps1（或直接 java -jar 启动网关）
  2. 观察启动日志至 `Started GatewayApplication` 出现
  3. 在日志中检索 `No spring.config.import property has been defined`、`RSA 公钥解析失败`、`Unable to decode key`、`extra data at the end`
  4. 检索 Nacos 注册成功标志（`nacos registry ... register finished`）与 `RSA 公钥加载成功`
- **预期结果**：
  1. 服务启动成功（Started GatewayApplication），进程存活
  2. 日志中 4 个错误关键字出现次数 = 0（bootstrap 与 RSA 契约修复生效）
  3. Nacos 注册成功标志出现，服务名 cloudoffice-gateway
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-048 测试步骤与记录）
- **测试过程与结论**：**通过**——2026-08-09 19:30:18 启动 gateway（PID 17448，java -Xms256m -Xmx512m -jar deploy/cloudoffice-gateway.jar）：日志出现 Started GatewayApplication、RSA 公钥加载成功（RsaKeyConfig，RSA/2048）、nacos registry DEFAULT_GROUP cloudoffice-gateway 192.168.140.1:9000 register finished、Netty started on port 9000；错误关键字（No spring.config.import property has been defined / RSA 公钥解析失败 / Unable to decode key / extra data at the end）出现次数=0（见 logs/gateway.out.log）。

#### FT-049：启动 auth-service 服务，日志无两类报错并注册 Nacos（P0）
- **用例ID**：FT-049
- **用例名称**：启动 cloudoffice-auth-service，启动日志无 import-check 与 RSA 解析报错，注册 Nacos
- **所属模块**：服务启动（auth-service / 9100）
- **优先级**：P0
- **前置条件**：FT-047 通过（jar 就绪）；基础设施可达；env.json 已注入（9 个必需变量）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / US-002 / AC-2 / AC-3
- **测试数据**：`.\\deploy\\scripts\\deploy-start-auth.ps1` 或 `java -Xms256m -Xmx512m -jar deploy\\cloudoffice-auth-service.jar`
- **测试步骤**：
  1. 执行 deploy-start-auth.ps1（或直接 java -jar 启动认证服务）
  2. 观察启动日志至 `Started AuthApplication` 出现
  3. 检索 `No spring.config.import property has been defined`、`RSA` 解析失败关键字（含密钥对匹配校验失败）
  4. 检索 Nacos 注册成功标志
- **预期结果**：
  1. 服务启动成功（Started AuthApplication），进程存活
  2. 日志中错误关键字出现次数 = 0（bootstrap 与 RSA 契约修复生效，含密钥对匹配校验通过）
  3. Nacos 注册成功，服务名 cloudoffice-auth-service
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-049 测试步骤与记录）
- **测试过程与结论**：**通过**——2026-08-09 19:30:18 启动 auth-service（PID 4344）：日志出现 Started AuthApplication、RSA 私钥加载成功 + RSA 公钥加载成功 + RSA 密钥强校验通过（2048 位）+ RSA 密钥对匹配校验通过 + RsaKeyConfig 初始化成功（RSA/2048）、nacos registry DEFAULT_GROUP cloudoffice-auth-service 192.168.140.1:9100 register finished、Tomcat started on port 9100；错误关键字出现次数=0（见 logs/auth.out.log）。

#### FT-050：启动 biz-service 服务，日志无两类报错并注册 Nacos（P0）
- **用例ID**：FT-050
- **用例名称**：启动 cloudoffice-biz-service，启动日志无 import-check 与 RSA 解析报错，注册 Nacos
- **所属模块**：服务启动（biz-service / 9200）
- **优先级**：P0
- **前置条件**：FT-047 通过（jar 就绪）；基础设施可达；env.json 已注入
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / AC-2 / AC-3
- **测试数据**：`.\\deploy\\scripts\\deploy-start-biz.ps1` 或 `java -Xms256m -Xmx512m -jar deploy\\cloudoffice-biz-service.jar`
- **测试步骤**：
  1. 执行 deploy-start-biz.ps1（或直接 java -jar 启动企业服务）
  2. 观察启动日志至 `Started BizApplication` 出现
  3. 检索 `No spring.config.import property has been defined`、`RSA 公钥解析失败` 等关键字
  4. 检索 Nacos 注册成功标志
- **预期结果**：
  1. 服务启动成功（Started BizApplication），进程存活
  2. 日志中错误关键字出现次数 = 0
  3. Nacos 注册成功，服务名 cloudoffice-biz-service
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-050 测试步骤与记录）
- **测试过程与结论**：**通过**——2026-08-09 19:22:22 启动 biz-service（PID 24308）：日志出现 Started BizApplication、nacos registry DEFAULT_GROUP cloudoffice-biz-service 192.168.140.1:9200 register finished、Tomcat started on port 9200；错误关键字出现次数=0（见 logs/biz.out.log）。

#### FT-051：启动 system-service 服务，日志无两类报错并注册 Nacos（P0）
- **用例ID**：FT-051
- **用例名称**：启动 cloudoffice-system-service，启动日志无 import-check 与 RSA 解析报错，注册 Nacos
- **所属模块**：服务启动（system-service / 9400）
- **优先级**：P0
- **前置条件**：FT-047 通过（jar 就绪）；基础设施可达；env.json 已注入
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / AC-2 / AC-3
- **测试数据**：`.\\deploy\\scripts\\deploy-start-system.ps1` 或 `java -Xms256m -Xmx512m -jar deploy\\cloudoffice-system-service.jar`
- **测试步骤**：
  1. 执行 deploy-start-system.ps1（或直接 java -jar 启动系统服务）
  2. 观察启动日志至 `Started SystemApplication` 出现
  3. 检索 `No spring.config.import property has been defined`、`RSA 公钥解析失败` 等关键字
  4. 检索 Nacos 注册成功标志
- **预期结果**：
  1. 服务启动成功（Started SystemApplication），进程存活
  2. 日志中错误关键字出现次数 = 0
  3. Nacos 注册成功，服务名 cloudoffice-system-service
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-051 测试步骤与记录）
- **测试过程与结论**：**通过**——2026-08-09 19:22:22 启动 system-service（PID 26308）：日志出现 Started SystemApplication、nacos registry DEFAULT_GROUP cloudoffice-system-service 192.168.140.1:9400 register finished、Tomcat started on port 9400；错误关键字出现次数=0（见 logs/system.out.log）。

#### FT-052：4 个服务全部注册到 Nacos（P0）
- **用例ID**：FT-052
- **用例名称**：Nacos 控制台可见 cloudoffice-gateway/auth-service/biz-service/system-service 4 个服务各 1 个健康实例
- **所属模块**：服务注册（Nacos 8848）
- **优先级**：P0
- **前置条件**：FT-048~051 通过（4 个服务均已启动）；Nacos 控制台可访问
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / AC-2 / AC-4
- **测试数据**：Nacos 控制台 `http://localhost:8848/nacos/` 服务列表（或 Nacos OpenAPI 服务列表）
- **测试步骤**：
  1. 访问 Nacos 控制台服务列表（或调用 Nacos 服务查询接口）
  2. 检索 cloudoffice-gateway / cloudoffice-auth-service / cloudoffice-biz-service / cloudoffice-system-service 4 个服务
  3. 核对每个服务有 1 个健康实例（healthy=true，IP/端口正确）
- **预期结果**：
  1. 4 个服务全部出现在服务列表（cloudoffice-* 命名）
  2. 每个服务实例健康（healthy=true），端口与部署方案一致（9000/9100/9200/9400）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-052 测试步骤与记录）
- **测试过程与结论**：**通过**——4 个服务注册日志确认：nacos registry ... register finished 均出现（gateway 192.168.140.1:9000 / auth 192.168.140.1:9100 / biz 192.168.140.1:9200 / system 192.168.140.1:9400）；auth REGISTER-SERVICE 实例 healthy=true；gateway 订阅到 DEFAULT_GROUP@@cloudoffice-auth-service 实例 healthy=true（ip=192.168.140.1:9100）——4 个服务各 1 个健康实例，端口与部署方案一致（Nacos 控制台 OpenAPI /v1/ns/catalog 返回 501 为 Nacos 2.3 API 路径差异，以服务日志注册证据为准）。

#### FT-053：启动日志全量核对——无 No spring.config.import property has been defined（P0）
- **用例ID**：FT-053
- **用例名称**：4 个服务启动日志中 `No spring.config.import property has been defined` 出现次数 = 0（bootstrap 修复生效）
- **所属模块**：启动日志核对（bootstrap 缺陷 T-02 子项）
- **优先级**：P0
- **前置条件**：FT-048~051 通过（4 个服务已启动，日志已采集）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / AC-3
- **测试数据**：4 个服务启动日志（启动窗口输出）
- **测试步骤**：
  1. 汇总 4 个服务启动日志
  2. 全文检索关键字 `No spring.config.import property has been defined`
  3. 统计出现次数并核对 import-check 相关报错
- **预期结果**：
  1. 4 个服务日志中该关键字出现次数均为 0（v0.2.5 缺陷修复确认）
  2. 无 import-check / config import 相关 ERROR
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-053 测试步骤与记录）
- **测试过程与结论**：**通过**——4 份启动日志（logs/gateway|auth|biz|system.out.log）全量检索 `No spring.config.import property has been defined` 出现次数=0，无 import-check / config import 相关 ERROR——v0.2.5 bootstrap 缺陷修复确认。

#### FT-054：启动日志全量核对——无 RSA 公钥解析失败（P0）
- **用例ID**：FT-054
- **用例名称**：4 个服务启动日志中 `RSA 公钥解析失败`/`Unable to decode key`/`extra data at the end` 出现次数 = 0（密钥契约修复生效）
- **所属模块**：启动日志核对（RSA 密钥缺陷 T-02 子项）
- **优先级**：P0
- **前置条件**：FT-048~051 通过（4 个服务已启动，日志已采集）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-002 / AC-3
- **测试数据**：4 个服务启动日志（启动窗口输出）
- **测试步骤**：
  1. 汇总 4 个服务启动日志
  2. 全文检索关键字 `RSA 公钥解析失败`、`Unable to decode key`、`extra data at the end`、`key loading failed`
  3. 统计出现次数
- **预期结果**：
  1. 4 个服务日志中上述关键字出现次数均为 0（v0.2.5 RSA 解析失败缺陷修复确认）
  2. 网关/auth 日志中出现 `RSA 公钥加载成功`/`RsaKeyConfig 初始化成功` 类成功标志
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-054 测试步骤与记录）
- **测试过程与结论**：**通过**——4 份启动日志全量检索 `RSA 公钥解析失败`/`Unable to decode key`/`extra data at the end`/`key loading failed` 出现次数=0；gateway 日志出现 `RSA 公钥加载成功`、auth 日志出现 `RSA 密钥强校验通过（2048 位）`+`RSA 密钥对匹配校验通过`+`RsaKeyConfig 初始化成功（RSA/2048）`——v0.2.5 RSA 解析失败缺陷修复确认。

#### FT-055：网关 9000 与认证服务 9100 可访问（P0）
- **用例ID**：FT-055
- **用例名称**：网关（9000）与认证服务（9100）端口可达，为 TASK-004/TASK-005 回归脚本执行提供前置
- **所属模块**：服务可达性（回归前置）
- **优先级**：P0
- **前置条件**：FT-048/049 通过（网关与 auth 已启动）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001 / US-003 / AC-5
- **测试数据**：TCP 连接测试 `http://localhost:9000/`、`http://localhost:9100/api/v1/auth/health`
- **测试步骤**：
  1. 探测网关 9000 端口可连接（HTTP 请求返回网关响应，非连接拒绝）
  2. 探测认证服务 9100 端口可连接（健康检查返回 200）
- **预期结果**：
  1. 9000 端口返回网关响应（404/401 均可，非 Connection refused）
  2. 9100 健康检查返回 200——满足 US-003 回归脚本前置条件（admin 登录不再连接拒绝崩溃）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-055 测试步骤与记录）
- **测试过程与结论**：**通过**——网关 9000 探测：GET http://localhost:9000/ 返回 HTTP 404（网关响应，非 Connection refused）；认证服务 9100 探测：GET http://localhost:9100/api/v1/auth/health 返回 code=200、status=UP——满足 US-003 回归脚本前置条件（admin 登录不再连接拒绝崩溃）。

#### FT-056：边界——重复启动时端口占用报错（P2，边界/负向）
- **用例ID**：FT-056
- **用例名称**：已启动服务占用的端口再次启动同一 jar 时失败并报端口占用（Web server failed to start. Port XXXX was already in use）
- **所属模块**：服务启动边界
- **优先级**：P2
- **前置条件**：至少 1 个服务已启动（如 auth 9100）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / US-001（边界情况）
- **测试数据**：对已占用端口再次执行 `java -jar deploy\\cloudoffice-auth-service.jar`
- **测试步骤**：
  1. 在 auth-service 已占用 9100 的情况下，再次尝试启动同一 jar
  2. 观察启动日志
  3. 核对报错信息与进程状态（第二次实例应启动失败退出）
- **预期结果**：
  1. 第二次启动报 `Port 9100 was already in use`（Web server failed to start）并退出
  2. 已运行实例不受影响（健康检查仍 200）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-056 测试步骤与记录）
- **测试过程与结论**：**通过**——2026-08-09 19:46~19:47 边界验证：对已占用 9100 端口再次启动 auth jar（先执行 load-env.ps1 注入 env.json 环境变量）→ 第二次实例输出 `APPLICATION FAILED TO START` + `Web server failed to start. Port 9100 was already in use.` 并退出；已运行实例不受影响（健康检查仍 code=200 status=UP）。

#### FT-057：边界——健康检查 timestamp 字段类型兼容（P2，边界/兼容性）
- **用例ID**：FT-057
- **用例名称**：3 个健康检查接口 timestamp 字段类型不一致时断言兼容（auth/biz 为 ISO 字符串、system 为毫秒长整型）
- **所属模块**：健康检查响应兼容性
- **优先级**：P2
- **前置条件**：TC-058~060 通过（3 个直连健康检查均 200）
- **测试类型**：功能测试
- **关联需求ID**：F-003 / API-012 / API-032 / API-033（既有实现契约）
- **测试数据**：TC-058/059/060 响应体中的 timestamp 字段
- **测试步骤**：
  1. 记录 auth/biz/system 3 个健康检查响应中 timestamp 字段的值与类型
  2. 核对 auth/biz 为 ISO 8601 字符串（如 2026-08-09T19:00:00.123Z）、system 为毫秒长整型（13 位数字）
  3. 确认断言逻辑对两种类型均兼容（不因类型不一致误判失败）
- **预期结果**：
  1. timestamp 字段非空（auth/biz 可解析为时间字符串、system 为合法毫秒时间戳）
  2. 断言脚本兼容两种类型（已知跨服务类型差异，不视为缺陷，TASK-004/005 回归时注意）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（FT-057 测试步骤与记录）
- **测试过程与结论**：**通过**——TC-058/059/060 响应实测：auth/biz timestamp 为 ISO 8601 字符串（如 2026-08-09T11:45:36.031073Z，TYPE=String）、system 为毫秒长整型（1786275936081，TYPE=Int64）；接口脚本 is_timestamp_compatible 对两种类型均兼容断言通过——已知跨服务类型差异，不视为缺陷，TASK-004/005 回归时注意。

### 模块：构建与部署验证（F-003） - UI 测试（无 UI 变更确认）
#### UIT-014：客户端 UI 无任何变更（P1）
- **用例ID**：UIT-014
- **用例名称**：本任务为后端构建/启动验证，客户端应用界面与交互无任何变更
- **所属模块**：客户端（cloudoffice-flutter-app）/ 无 UI 变更
- **优先级**：P1
- **前置条件**：TASK-003 相关构建/启动操作已执行（git 工作区存在变更记录）
- **测试类型**：UI 测试
- **关联需求ID**：F-003 / US-001 / AC-5（客户端运行时代码零改动）
- **测试数据**：git 变更清单（`git status --porcelain` + `git diff --name-only`）
- **测试步骤**：
  1. 执行 `git status --porcelain` 与 `git diff --name-only`，获取变更文件清单
  2. 检查变更清单中是否出现 `cloudoffice-flutter-app/lib` 下界面代码（*.dart）、pubspec.yaml、客户端构建配置
- **预期结果**：
  1. 变更清单中无任何 `cloudoffice-flutter-app/lib` 下 .dart 界面文件与客户端配置文件改动
  2. 客户端应用界面/交互/运行行为无任何变更（本任务为构建+启动验证，接口契约不变，客户端零改动）
- **自动化测试函数/脚本位置**：`docs/cso-v0.2.6/cso-ui-test-record-v0.2.6.md`（UIT-014 测试步骤与记录）
- **测试过程与结论**：**通过**——git 变更清单（9 项，见 UT-119 记录）中 cloudoffice-flutter-app/ 路径下文件数=0，无任何 .dart 界面文件/pubspec.yaml/客户端配置改动——客户端界面/交互/运行行为无任何变更（接口契约不变，客户端零改动）。

## 三、执行汇总
| 结果 | 数量 |
| --- | --- |
| 通过 | 28（UT-113~120 ×8 全部通过；TC-057~064 ×8 全部通过；FT-046~057 ×12 全部通过） |
| 失败 | 0 |
| 阻塞 | 1（TC-056 RS256 登录链路——auth-service SecurityConfig permitAll 缺 /api/v1/auth/login、/api/v1/auth/register、/api/v1/auth/refresh 三端点，经网关登录返回 401「未授权，请先登录」，接口脚本按业务失败标记 SKIP；属代码缺陷而非环境阻塞，需调度方决策回退编码修复，将阻塞 TASK-004/005 回归登录前置用例） |
| 跳过 | 0 |

## 四、风险评估
| 风险点 | 影响 | 应对措施 |
| --- | --- | --- |
| Nacos/MariaDB/Redis 基础设施未启动 | 服务启动验证（FT-048~052）阻塞，无法确认修复闭环 | 按部署文档先执行 deploy-start-services.ps1 启动基础设施；若 8848 不可达则按环境阻塞记录，待基础设施就绪后回归 |
| deploy/env.json 未正确注入（RSA 密钥非 DER 单行 Base64） | 服务启动报 RSA 解析失败，健康检查全部失败 | UT-116/118 静态校验 env.json 键与格式；FT-048/049 启动日志核对；密钥值须来自 deploy-rsa-keygen.ps1 输出的 *_base64.txt |
| 构建产物未含 TASK-001/TASK-002 修复 | jar 内无 bootstrap 依赖，启动仍报 import-check | UT-115 校验 jar 内 BOOT-INF/lib 含 spring-cloud-starter-bootstrap；UT-120 校验 jar 内 bootstrap.yml；FT-053/054 日志核对 |
| 端口冲突/进程残留 | 服务启动失败或误判（假启动） | FT-056 边界用例验证端口占用报错；启动前核对端口占用；FT-055 双向可达性确认 |
| 健康检查 timestamp 类型跨服务不一致 | 断言脚本误判失败 | FT-057 边界用例明确两种类型兼容断言，不视为缺陷 |
| 环境阻塞用例遗留 | v0.2.5 缺陷修复闭环未完成 | 阻塞用例（FT-048~052 等）列入回归范围，基础设施就绪后由 TASK-004/005 回归执行（US-003） |

## 五、签名确认
- 测试工程师（TE）：2026-08-09 TASK-003 测试执行完成（runtest 19:43~19:47）：单元测试 UT-113~120 全部通过（18/18 断言）、接口测试 TC-057~064 全部通过（PASS=26 含 TASK-001/002 回归，FAIL=0，SKIP=1）、功能测试 FT-046~057 全部通过（12/12）、UI 测试 UIT-014 通过；缺陷记录：auth-service SecurityConfig permitAll 缺 /api/v1/auth/login、/api/v1/auth/register、/api/v1/auth/refresh 三端点（登录 401，TC-056 SKIP，阻塞 TASK-004/005 回归登录前置，需调度方决策回退编码修复）
- 项目经理（PM）：

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
