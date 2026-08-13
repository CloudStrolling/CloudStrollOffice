# 功能/UI 测试记录（v0.2.8）

**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.2.8
**日期**：2026-08-13
**测试负责人**：TE

> 本文件为版本功能/UI 测试记录汇总文档（v0.2.8），由各任务编码阶段的 writetest 步骤追加生成。并行任务写入时遵循"先读最新、在尾部追加"规则。

## 功能/UI 测试记录段落

### TASK-005：网关路由与白名单扩展（/api/v1/common/** 路由）— 功能测试记录

**任务说明**：本任务为网关侧纯配置扩展（cloudoffice-gateway/src/main/resources/application.yml）：
1. 新增 `common-service` 路由 `/api/v1/common/** → lb://cloudoffice-common`；
2. AuthFilter 白名单新增 `/api/v1/common/health`（无 Token 放行）；
3. `/api/v1/common/config` 与 `/api/v1/common/config/{serviceName}` 保持非白名单（需认证）。

**功能测试（手工/脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK005-001 | common 健康检查白名单放行 | 无 Token GET 网关 `/api/v1/common/health` | HTTP 200（白名单放行） | 功能测试 | 由接口测试脚本执行（common 服务未启动时环境阻塞 SKIP） |
| TC-TASK005-002 | common 配置查询需认证 | 无 Token GET 网关 `/api/v1/common/config` | HTTP 401 | 功能测试 | 由接口测试脚本执行 |
| TC-TASK005-003 | common 按微服务查询配置需认证 | 无 Token GET 网关 `/api/v1/common/config/auth-service` | HTTP 401 | 功能测试 | 由接口测试脚本执行 |
| TC-TASK005-004 | 既有 auth 白名单不受影响（回归） | 无 Token GET 网关 `/api/v1/auth/health`（应 200）；GET `/api/v1/biz/echo`（应 401） | 200 / 401 | 功能测试 | 由接口测试脚本执行 |

**说明**：
- 本任务为后端网关配置扩展，无前端页面/UI 界面，故无 UI 测试；功能行为由 AuthFilter 集成测试（单元测试，见 AuthFilterTest.java）与接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py）共同验证。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-002：cloudoffice-common 服务化改造（启动类/bootstrap.yml/application.yml/依赖）— 功能测试记录

**任务说明**：本任务为 common 模块服务化改造：
1. 新增 `CommonApplication` 启动类（`org.cloudstrolling.cloudoffice.common`，`@SpringBootApplication + @EnableDiscoveryClient` + main）；
2. 新增 `bootstrap.yml`（应用名 `cloudoffice-common`，Nacos discovery/config server-addr 从 `NACOS_ADDR` 读取，经 spring-cloud-starter-bootstrap 引导）；
3. 新增 `application.yml`（`server.port=${COMMON_PORT:9300}`、SpringDoc 分组 `common`、DataSource/MyBatis 自动配置排除）；
4. `pom.xml` 引入 bootstrap/Nacos 依赖，`spring-boot-maven-plugin`（classifier=exec）产出可执行 fat jar 并复制为 `deploy/cloudoffice-common.jar`，主 artifact 保持瘦 jar（下游依赖不受影响）。

**功能测试（手工/脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK002-005 | 构建产物可执行 jar 落位 deploy | mvn package 后检查 `deploy/cloudoffice-common.jar` 存在且含 Spring Boot Loader；`target/...-0.0.1-SNAPSHOT.jar` 仍为瘦 jar | fat jar 落位 deploy；主 artifact 为瘦 jar | 接口测试（构建产物校验） | 由接口测试脚本执行（test_task002_build_artifact） |
| TC-TASK002-006 | common 服务独立启动冒烟 | `java -jar deploy/cloudoffice-common.jar`（注入 NACOS_ADDR）后探测 9300 与 `/v3/api-docs` | 服务启动成功、9300 监听、注册 Nacos | 接口测试（启动冒烟） | 由接口测试脚本执行（test_task002_startup_smoke；Nacos 未就绪时环境阻塞 SKIP） |
| TC-TASK002-007 | 下游服务依赖不受影响（编译回归） | 项目根执行 `mvn clean package -DskipTests` 全量构建 | 构建成功退出码 0，5 个 jar 齐全 | 功能测试（编译回归） | 由接口测试脚本执行（test_task002_downstream_compile） |

**说明**：
- 本任务为后端服务化改造，无前端页面/UI 界面，故无 UI 测试；功能行为由单元测试（CommonApplicationConfigTest.java）与接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py）共同验证。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-001：通用配置库与配置表初始化（cloudstroll_office_common + t_common_config + 种子数据）— 功能测试记录

**任务说明**：本任务为数据库初始化（后端 SQL 交付，无前端 UI）：
1. 新建数据库 `cloudstroll_office_common`；
2. 新建通用配置表 `t_common_config`（12 字段 + 主键 + uk_service_group_key 唯一索引 + idx_service_name/idx_config_group 普通索引）；
3. INSERT IGNORE 插入 17 条种子数据，覆盖 gateway/auth-service/biz-service/system-service/common 五个微服务；
4. 不修改 cloudstroll_office_auth 既有 9 张表。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK001-001 | 通用配置库创建 | 执行 v0.2.8 SQL 后查 SHOW DATABASES | cloudstroll_office_common 存在 | 功能测试（SQL 验证） | 自动化脚本执行 |
| TC-TASK001-002 | 表结构正确 | DESCRIBE t_common_config | 12 字段与 DBD 5.2.1 一致 | 功能测试（SQL 验证） | 自动化脚本执行 |
| TC-TASK001-003 | 索引正确 | SHOW INDEX FROM t_common_config | 4 索引（含主键）与 DBD 6.2 一致 | 功能测试（SQL 验证） | 自动化脚本执行 |
| TC-TASK001-004 | 种子数据 | SELECT COUNT / DISTINCT service_name | 17 条、覆盖 5 个微服务 | 功能测试（SQL 验证） | 自动化脚本执行 |
| TC-TASK001-005 | 脚本幂等 | 重复执行 v0.2.8 SQL | 不报错、仍 17 条 | 功能测试（SQL 验证） | 自动化脚本执行 |
| TC-TASK001-006 | 既有库回归 | SHOW TABLES FROM cloudstroll_office_auth | 9 张既有表完整、无新增删除 | 功能测试（回归） | 自动化脚本执行 |

**说明**：
- 本任务为后端数据库初始化，无前端页面/UI 界面，故无 UI 测试；功能行为由数据库验证脚本（scripts/API-TEST/cso-unit-test-db-common-config-v0.2.8.ps1）自动执行验证。
- 详细执行结果见版本回归测试记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-006：build-backend 编译脚本纳入 common 产物 — 功能测试记录

**任务说明**：本任务为编译脚本更新（deploy/scripts/build-backend.ps1 与 build-backend.sh）：
1. 产物校验清单由 4 个 jar 扩展为 5 个 jar，新增 `cloudoffice-common.jar`（置于清单首位）；
2. 头部注释与完成输出更新为"5 个服务 jar"；
3. 校验失败时输出缺失项并以非零码退出（.ps1 exit 1 / .sh exit 1）；
4. 构建命令不变（根 pom 全模块构建，common jar 由 maven-antrun-plugin 自动落位 deploy，TASK-002 已配置）。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK006-001 | build-backend.ps1 产物清单含 common | 静态校验脚本内容 | $Jars 清单含 5 个 jar（含 cloudoffice-common.jar） | 功能测试（脚本校验） | 由接口测试脚本执行（test_task006_build_script_checks） |
| TC-TASK006-002 | build-backend.sh 产物清单含 common | 静态校验脚本内容 | for 循环清单含 5 个 jar（含 common） | 功能测试（脚本校验） | 由接口测试脚本执行（test_task006_build_script_checks） |
| TC-TASK006-003 | 执行 build-backend 后 common jar 落位 deploy | 执行 build-backend.ps1（或校验产物）后检查 deploy/cloudoffice-common.jar 存在且为可执行 fat jar | jar 存在且为 fat jar | 功能测试（编译脚本执行） | 由接口测试脚本执行（test_task006_build_artifacts） |
| TC-TASK006-004 | 现有服务产物输出不受影响 | 检查 deploy 下 gateway/auth/biz/system 4 个 jar 均存在 | 4 个既有服务 jar 齐全 | 功能测试（编译回归） | 由接口测试脚本执行（test_task006_build_artifacts） |
| TC-TASK006-005 | 产物缺失时脚本失败退出非零 | 静态校验 $missing / MISSING 缺失分支与 exit 1 约定 | 输出缺失项、退出码非零 | 功能测试（失败路径校验） | 由接口测试脚本执行（test_task006_build_script_checks） |

**说明**：
- 本任务为编译脚本更新，无前端页面/UI 界面，故无 UI 测试；双平台行为一致通过 .ps1/.sh 静态比对 + 当前 Windows 环境 .ps1 实执行（产物存在性）验证。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-003：common 健康检查端点与 API 服务（HealthController + SpringDoc）— 功能测试记录

**任务说明**：本任务为 cloudoffice-common 服务的 API 能力实现：
1. 新增 `HealthController`（`org.cloudstrolling.cloudoffice.common.controller`），提供 `GET /api/v1/common/health` 健康检查端点（API-034，白名单放行）；
2. 响应体为统一 `ApiResult<Map>`（code=200、message、data 含 service/status/version/timestamp 四字段、响应体 timestamp），格式与 auth/biz/system 健康检查端点一致；
3. 参考 system-service 为 Controller 增加 `@Tag`/`@Operation` 注解完善 SpringDoc 文档；common 分组已由 TASK-002 在 application.yml（springdoc.group-configs paths-to-match `/api/v1/common/**`）配置，无需改动共享 SpringDocConfig @Bean；
4. 全部接口统一 ApiResult + GlobalExceptionHandler 兜底，不泄露堆栈（公共模块已有）。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK003-002 | 健康检查端点契约 | GET `http://127.0.0.1:9300/api/v1/common/health` | HTTP 200、code=200、data.service=cloudoffice-common/status=UP/version 非空/timestamp 非空 | 接口测试 | 由接口测试脚本执行（test_tc_task003_common_health_endpoint） |
| TC-TASK003-003 | 响应格式一致性 | 校验 data 键集合 | data 恰含 service/status/version/timestamp 四字段（与 auth/biz/system 一致） | 功能测试（格式校验） | 由接口测试脚本执行（test_tc_task003_common_health_endpoint） |
| TC-TASK003-004 | SpringDoc 分组 common | GET `/v3/api-docs/common` 与 `/swagger-ui.html` | 分组返回 200 且 paths 含 /api/v1/common/health；Swagger UI 可访问 | 功能测试（在线文档） | 由接口测试脚本执行（test_tc_task003_common_health_endpoint） |
| TC-TASK003-005 | 全局异常兜底不泄露堆栈 | GET `/api/v1/common/non-exist`（不存在路径） | 返回统一 ApiResult 结构且不含堆栈（无 Exception / at org.cloudstrolling） | 功能测试（异常兜底） | 由接口测试脚本执行（test_tc_task003_common_health_endpoint） |
| TC-TASK003-006 | 下游依赖不受影响（编译回归） | 项目根执行 `mvn clean package -DskipTests` | 构建成功退出码 0，5 个 jar 齐全 | 功能测试（编译回归） | 由接口测试脚本执行（test_task002_downstream_compile 复用） |

**说明**：
- 本任务为后端接口服务，无前端页面/UI 界面，故无 UI 测试；功能行为由单元测试（HealthControllerTest.java）与接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py）共同验证。
- common 服务独立启动依赖 Nacos；Nacos 未就绪时接口用例按环境阻塞 SKIP（沿用 TASK-002 冒烟策略）。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-008：部署停止脚本更新（deploy-stop-all 含 common 居末 + deploy-stop-common）— 功能测试记录

**任务说明**：本任务为部署停止脚本更新（deploy/scripts/deploy-stop-all.ps1/.sh 与新增 deploy-stop-common.ps1/.sh）：
1. `deploy-stop-all` 服务停止顺序固定为 system → biz → auth → gateway → common（common 在所有后端服务中最后停止，v0.2.8 F-009，确保其他服务停止过程中仍可访问配置接口）；服务清单由 4 项扩展为 5 项，汇总输出自动覆盖 common；
2. 停止方式保持 v0.2.7 约定：优先读取 `deploy/logs/{name}.pid` 记录的 PID，校验进程命令行含 jar 名后停止（.ps1 Stop-Process / .sh kill SIGTERM），轮询等待退出（默认超时 30s/间隔 2s），超时强制停止（-Force / kill -9）；PID 文件缺失或进程不存在视为已停止（幂等通过），回退按 java 进程命令行含 jar 名定位；
3. 新增 `deploy-stop-common` 单服务停止脚本（common/cloudoffice-common.jar/9300），经 load-env 加载 env.json，仅停止 common 单服务，不停止 Nacos/Redis/MySQL/MariaDB；
4. 双平台行为一致（.ps1/.sh 契约对齐），输出分级（通过/警告/失败）与退出码约定（失败非零）。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK008-001 | deploy-stop-all.ps1 服务清单含 common 且居末 | 静态校验脚本内容 | $Services 含 5 项（system/biz/auth/gateway/common），common(Jar=cloudoffice-common.jar,Port=9300) 位于最后 | 功能测试（脚本校验） | 由接口测试脚本执行（test_task008_stop_script_checks） |
| TC-TASK008-002 | deploy-stop-all.sh 服务清单含 common 且居末 | 静态校验脚本内容 | SERVICES 含 5 项且 common 位于最后 | 功能测试（脚本校验） | 由接口测试脚本执行（test_task008_stop_script_checks） |
| TC-TASK008-003 | deploy-stop-all 未运行服务幂等跳过 | 当前无后端 java 服务时执行 deploy-stop-all.ps1 | 5 个服务均显示"未在运行（PID 文件/进程均未命中），幂等跳过"（通过），退出码 0 | 功能测试（脚本执行） | 由接口测试脚本执行（test_task008_stop_script_execute） |
| TC-TASK008-004 | deploy-stop-common.ps1 契约正确 | 静态校验脚本内容 | 存在且含 common/cloudoffice-common.jar/9300/load-env/幂等跳过/退出码约定 | 功能测试（脚本校验） | 由接口测试脚本执行（test_task008_stop_script_checks） |
| TC-TASK008-005 | deploy-stop-common.sh 契约正确 | 静态校验脚本内容 | 存在且契约与 .ps1 对齐（SERVICE_NAME/JAR_NAME/SERVICE_PORT/load-env/幂等跳过/退出码约定） | 功能测试（脚本校验） | 由接口测试脚本执行（test_task008_stop_script_checks） |
| TC-TASK008-006 | deploy-stop-common 停止运行中进程 | 启动命令行含 cloudoffice-common.jar 的模拟 java 进程并写 common.pid，执行 deploy-stop-common.ps1 | 进程按 PID 文件定位被停止、输出通过、退出码 0 | 功能测试（脚本执行） | 由接口测试脚本执行（test_task008_stop_script_execute） |

**说明**：
- 本任务为部署停止脚本更新，无前端页面/UI 界面，故无 UI 测试；功能行为由接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py，test_task008_stop_script_checks / test_task008_stop_script_execute）自动执行验证。
- .sh 平台当前 Windows 环境不可直接执行，以静态校验 + 与 .ps1 逻辑比对方式对齐双平台契约（沿用 TASK-006 策略）。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-004：通用配置管理查询接口（ConfigController/ConfigService/ConfigCacheManager/ConfigMapper）— 功能测试记录

**任务说明**：本任务为 cloudoffice-common 通用配置管理查询接口实现（API-035/API-036）：
1. 新增 `ConfigController`（`org.cloudstrolling.cloudoffice.common.controller`）：`GET /api/v1/common/config`（按 serviceName/group/key 过滤 + 分页，API-035）与 `GET /api/v1/common/config/{serviceName}`（按微服务名称查询不分页，API-036）；
2. 新增 `ConfigService`：缓存优先（Redis，命中 ≤50ms）→ 未命中回源数据库 t_common_config 并回填缓存（TTL 300s）→ 敏感配置脱敏（sensitive=1 替换为掩码，默认 ****，可由 common 配置 sensitive-mask 覆盖）；
3. 新增 `ConfigCacheManager`：以 serviceName 为粒度管理缓存键 `common:config:{serviceName}` 的读写与失效；
4. 新增 `ConfigMapper`（BaseMapper<ConfigEntity>）与 `ConfigEntity`（@TableName("t_common_config")）；`ConfigProperties`（@ConfigurationProperties common.config：cache-ttl-seconds/sensitive-mask）；
5. serviceName 合法性校验（gateway/auth-service/biz-service/system-service/common，非法返回 400）；
6. common 的 application.yml 接入 MariaDB（cloudstroll_office_common）数据源、Redis 与 MyBatis-Plus 分页插件；仅实现查询，POST/PUT/DELETE 写入预留扩展点不实现。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK004-002 | API-035 配置列表查询契约 | GET `http://127.0.0.1:9300/api/v1/common/config?serviceName=auth-service&page=1&pageSize=10` | HTTP 200、code=200、data 为 PageResult（records/total/page/pageSize） | 接口测试 | 由接口测试脚本执行（test_task004_config_query_endpoints） |
| TC-TASK004-003 | API-036 按微服务查询契约 | GET `http://127.0.0.1:9300/api/v1/common/config/auth-service` | HTTP 200、code=200、data 为配置项数组 | 接口测试 | 由接口测试脚本执行（test_task004_config_query_endpoints） |
| TC-TASK004-004 | serviceName 非法返回 400 | GET `http://127.0.0.1:9300/api/v1/common/config/non-existent` | HTTP 400、code=400（BusinessException 兜底） | 功能测试（参数校验） | 由接口测试脚本执行（test_task004_config_query_endpoints） |
| TC-TASK004-005 | 敏感配置脱敏 | 查询含 sensitive=true 配置项的服务配置 | 敏感项 value 为掩码（****），不暴露明文 | 功能测试（脱敏） | 由接口测试脚本执行（test_task004_config_query_endpoints） |
| TC-TASK004-009 | 空结果返回 200 空列表 | GET `/api/v1/common/config?serviceName=gateway&key=not-exist-key` | HTTP 200、code=200、records 为空（非 500） | 功能测试（边界） | 由接口测试脚本执行（test_task004_config_query_endpoints） |

**说明**：
- 本任务为后端接口服务，无前端页面/UI 界面，故无 UI 测试；功能行为由单元测试（ConfigServiceTest.java / ConfigCacheManagerTest.java / ConfigControllerTest.java / ConfigMapperTest.java / ConfigPropertiesTest.java）与接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py，test_task004_config_query_endpoints）共同验证。
- common 服务独立启动依赖 Nacos 与 MariaDB/Redis；环境未就绪时接口用例按环境阻塞 SKIP（沿用 TASK-003 策略）。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-007：部署启动脚本更新（deploy-start-all 含 common 居首 + deploy-start-common）— 功能测试记录

**任务说明**：本任务为部署启动脚本更新（deploy/scripts/deploy-start-all.ps1/.sh 与新增 deploy-start-common.ps1/.sh）：
1. `deploy-start-all` 服务启动顺序固定为 common → gateway → auth → biz → system（common 在所有后端服务中最先启动，v0.2.8 F-008/ADR-019）；服务清单由 4 项扩展为 5 项，common 置于第一位（Port 读 COMMON_PORT 缺省 9300，HealthUrl 为 http://localhost:{port}/api/v1/common/health，RequiredVars 含 NACOS_ADDR/COMMON_PORT/DB_PASSWORD）；
2. 前置校验由 4 个 jar 扩展为 5 个 jar（含 cloudoffice-common.jar），任一缺失输出缺失项并以非零码退出、不启动任何服务；
3. 启动循环按 common → gateway → auth → biz → system 顺序逐个启动（java -Xms256m -Xmx512m -jar），每服务健康确认成功后再启动下一个，common 健康确认成功后再启动 gateway；任一步骤失败即停（break），失败提示含 9000/9100/9200/9400/9300 端口排查建议；
4. 汇总输出 5 个服务的启动结果与健康状态（含 common），全部成功退出 0；
5. 新增 `deploy-start-common` 单服务启动脚本（common/cloudoffice-common.jar/COMMON_PORT 缺省 9300/health/load-env），行为与 deploy-start-all 中 common 子块一致；
6. 双平台行为一致（.ps1/.sh 契约对齐），输出分级（通过/警告/失败）与退出码约定（失败非零）。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK007-001 | deploy-start-all.ps1 服务清单含 common 且居首 | 静态校验脚本内容 | $Services 含 5 项（common/gateway/auth/biz/system），common(cloudoffice-common.jar/COMMON_PORT 缺省 9300/health/RequiredVars) 位于首位 | 功能测试（脚本校验） | 由接口测试脚本执行（test_task007_start_script_checks） |
| TC-TASK007-002 | deploy-start-all.sh 服务清单含 common 且居首 | 静态校验脚本内容 | SERVICES 含 5 项且 common 位于首位 | 功能测试（脚本校验） | 由接口测试脚本执行（test_task007_start_script_checks） |
| TC-TASK007-003 | deploy-start-common.ps1 契约正确 | 静态校验脚本内容 | 存在且含 common/cloudoffice-common.jar/COMMON_PORT 缺省 9300/health/load-env/退出码约定 | 功能测试（脚本校验） | 由接口测试脚本执行（test_task007_start_script_checks） |
| TC-TASK007-004 | deploy-start-common.sh 契约正确 | 静态校验脚本内容 | 存在且契约与 .ps1 对齐（SERVICE_NAME/JAR_NAME/SERVICE_PORT/load-env/退出码约定） | 功能测试（脚本校验） | 由接口测试脚本执行（test_task007_start_script_checks） |
| TC-TASK007-005 | 前置校验缺失非零退出不启动 | 模拟 jar/COMMON_PORT 缺失场景（或静态校验 5 服务遍历 + exit 1 约定） | 输出缺失项（仅列键名不打印值）、退出码非零、不启动任何服务 | 功能测试（失败路径校验） | 由接口测试脚本执行（test_task007_start_script_checks） |
| TC-TASK007-006 | common 启动失败失败即停 | 静态校验健康确认失败 break 分支与 9300 端口排查提示 | common 失败即停，gateway 及之后服务不启动，退出码非零 | 功能测试（失败路径校验） | 由接口测试脚本执行（test_task007_start_script_checks） |
| TC-TASK007-007 | 全部启动成功输出 5 服务汇总退出码 0 | 静态校验汇总输出覆盖 common + "5 个后端服务" + exit 0 约定 | 5 个服务全部启动成功且健康确认通过、退出码 0 | 功能测试（脚本校验） | 由接口测试脚本执行（test_task007_start_script_checks；全量实执行留给部署验证） |

**说明**：
- 本任务为部署启动脚本更新，无前端页面/UI 界面，故无 UI 测试；功能行为由接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py，test_task007_start_script_checks）自动执行验证。
- 全量启动实执行依赖基础设施（MariaDB/Redis/Nacos）与 5 个 jar 就绪，环境未就绪时以脚本静态校验 + 前置校验失败路径验证替代（沿用 TASK-006/008 策略）。
- .sh 平台当前 Windows 环境不可直接执行，以静态校验 + 与 .ps1 逻辑比对方式对齐双平台契约。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-009：环境配置更新（env.json / env.example.json 新增 COMMON_PORT）— 功能测试记录

**任务说明**：本任务为环境配置文件更新（deploy/env.json 与 deploy/env.example.json）：
1. 两个文件均新增 `COMMON_PORT` 键（示例值/实际值均为 `"9300"`），供 cloudoffice-common 服务 application.yml（`server.port=${COMMON_PORT:9300}`，TASK-002 已配置）与部署脚本（deploy-start-all/deploy-start-common 读取 COMMON_PORT）使用；
2. env.example.json 作为入库模板提供示例值，env.json 填入实际值；
3. 现有 gateway/auth/biz/system 配置项（NACOS_ADDR/DB_*/REDIS_*/RSA_* 等）不受影响；
4. 保持 env.json 不入库（.gitignore 排除）、env.example.json 入库的现有策略；
5. COMMON_PORT 键名符合 load-env 键名合法性白名单正则（`^[A-Za-z_][A-Za-z0-9_]*$`），无需修改 load-env 脚本。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK009-001 | env.example.json 新增 COMMON_PORT 且示例值正确 | 解析 deploy/env.example.json，校验 JSON 合法性与 COMMON_PORT 存在及值 | JSON 合法、COMMON_PORT 存在且示例值 "9300" 正确 | 功能测试（配置校验） | 由接口测试脚本执行（test_task009_env_config_checks） |
| TC-TASK009-002 | env.json 新增 COMMON_PORT 且实际值正确 | 解析 deploy/env.json，校验 JSON 合法性与 COMMON_PORT 存在及值 | JSON 合法、COMMON_PORT 存在且实际值 "9300" 正确 | 功能测试（配置校验） | 由接口测试脚本执行（test_task009_env_config_checks） |
| TC-TASK009-003 | 现有 gateway/auth/biz/system 配置项不受影响 | 校验两文件原有关键键（NACOS_ADDR/DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD/REDIS_HOST/REDIS_PORT/RSA_PUBLIC_KEY/RSA_PRIVATE_KEY 等）完整保留 | 现有全部配置键完整保留，仅新增 COMMON_PORT | 功能测试（配置校验） | 由接口测试脚本执行（test_task009_env_config_checks） |
| TC-TASK009-004 | env.json 与 env.example.json 键集合一致 | 比较两文件键集合 | 两文件键集合一致，env.example.json 可作为 env.json 模板 | 功能测试（配置校验） | 由接口测试脚本执行（test_task009_env_config_checks） |
| TC-TASK009-005 | COMMON_PORT 符合 load-env 键名白名单 | 用正则 `^[A-Za-z_][A-Za-z0-9_]*$` 校验键名 | COMMON_PORT 符合白名单正则，load-env 加载不报非法键名 | 功能测试（配置校验） | 由接口测试脚本执行（test_task009_env_config_checks） |
| TC-TASK009-006 | env.json 不入库、env.example.json 入库策略保持 | 执行 git check-ignore deploy/env.json 与 deploy/env.example.json | env.json 被忽略（不入库）、env.example.json 未被忽略（可入库） | 功能测试（仓库策略校验） | 由接口测试脚本执行（test_task009_env_config_checks） |

**说明**：
- 本任务为环境配置文件更新，无前端页面/UI 界面，故无 UI 测试；功能行为由接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py，test_task009_env_config_checks）自动执行验证。
- 纯配置变更，无代码/脚本/SQL/API 变更；单元测试/接口测试/UI 测试不适用。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。

### TASK-010：部署文档与 readme 更新（deploy.md / readme.md）— 功能测试记录

**任务说明**：本任务为部署文档与 readme 更新（deploy/deploy.md 与 readme.md，v0.2.8 F-010/F-011/US-006）：
1. deploy.md：服务端口映射表新增 cloudoffice-common（9300）；启动顺序更新为 common → gateway → auth → biz → system（common 最先启动）；停止顺序更新为 system → biz → auth → gateway → common（common 最后停止）；健康检查端点新增 /api/v1/common/health；环境变量说明补充 COMMON_PORT；单服务启动/停止脚本新增 deploy-start-common/deploy-stop-common、一键停止脚本 deploy-stop-all；
2. readme.md：项目介绍补充 cloudoffice-common 服务化说明（独立部署微服务 9300 + 通用配置管理接口）；功能清单新增 common 服务化与通用配置管理功能介绍；模块说明、端口映射表、部署说明、健康检查接口表、项目结构与版本规划同步更新；
3. 约束：仅追加/更新 common 相关部分，不删除或覆盖现有 gateway/auth/biz/system 内容。

**功能测试（脚本，无 UI）**：

| 用例ID | 场景 | 操作 | 预期结果 | 测试类型 | 结论 |
| --- | --- | --- | --- | --- | --- |
| TC-TASK010-001 | deploy.md 端口映射表含 cloudoffice-common（9300） | 读取 deploy/deploy.md 文本，校验含 cloudoffice-common 与 9300 | 端口映射表含 cloudoffice-common（9300） | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-002 | deploy.md 启动顺序 common 首位 | 读取 deploy/deploy.md，校验 common 位于 gateway 之前 | 启动顺序为 common → gateway → auth → biz → system（common 首位） | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-003 | deploy.md 停止顺序 common 末位 | 读取 deploy/deploy.md，校验 common 位于 system 之后 | 停止顺序为 system → biz → auth → gateway → common（common 末位） | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-004 | deploy.md 健康检查端点含 /api/v1/common/health | 读取 deploy/deploy.md，校验含 /api/v1/common/health | 健康检查端点说明含 /api/v1/common/health | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-005 | deploy.md 环境变量说明含 COMMON_PORT | 读取 deploy/deploy.md，校验含 COMMON_PORT | 环境变量说明含 common 相关配置项（COMMON_PORT） | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-006 | readme.md 项目介绍含 common 服务化说明 | 读取 readme.md，校验含 cloudoffice-common 与服务化/独立部署表述 | 项目介绍含 common 服务化说明 | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-007 | readme.md 功能清单含通用配置管理功能介绍 | 读取 readme.md，校验含"通用配置管理" | 功能清单含通用配置管理功能介绍 | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-008 | readme.md 端口映射含 cloudoffice-common（9300） | 读取 readme.md，校验含 cloudoffice-common 与 9300 | 端口映射表含 cloudoffice-common（9300） | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |
| TC-TASK010-009 | 现有 gateway/auth/biz/system 内容未被删除或覆盖 | 读取 deploy/deploy.md 与 readme.md，校验仍含 gateway/auth/biz/system 各自端口（9000/9100/9200/9400）与服务说明 | 现有 gateway/auth/biz/system 内容保留 | 功能测试（文档校验） | 由接口测试脚本执行（test_task010_docs_checks） |

**说明**：
- 本任务为文档更新（deploy.md / readme.md），无前端页面/UI 界面，故无 UI 测试；功能行为由接口测试脚本（scripts/API-TEST/cso-api-test-v0.2.8.py，test_task010_docs_checks）自动执行验证。
- 纯文档变更，无代码/脚本/SQL/API 变更；单元测试/接口测试/UI 测试不适用。
- 详细执行结果见版本接口测试回归记录（impm-task-coding-runtest 步骤执行后更新）。
