# 本地代码查询（#TASK-003 common 健康检查端点与 API 服务（HealthController + SpringDoc））

## 1. 任务边界与前置状态

- 上游 TASK-002（common 服务化改造）已完成：CommonApplication 启动类、bootstrap.yml、application.yml、pom.xml（Nacos/bootstrap 依赖、exec 打包）均已就绪。
- 本任务（TASK-003）聚焦：在 cloudoffice-common 中实现健康检查端点 `GET /api/v1/common/health`（API-034）+ 确认 SpringDoc OpenAPI 分组 common 可在线访问；全部接口统一 ApiResult 响应与全局异常处理器兜底。
- 任务类型 common → 编码由 SSE subagent 执行；只写 cloudoffice-common 模块代码，禁止越界写 TASK-004（配置查询）等任务文件。

## 2. cloudoffice-common 现状（服务化改造后）

| 文件 | 现状 | 说明 |
| --- | --- | --- |
| src/main/java/.../common/CommonApplication.java | @SpringBootApplication + @EnableDiscoveryClient + main | TASK-002 已建，服务名 cloudoffice-common |
| src/main/resources/bootstrap.yml | 应用名 cloudoffice-common，Nacos discovery/config server-addr ${NACOS_ADDR:127.0.0.1:8848}、namespace ${NACOS_NAMESPACE:cso-dev}、group cloudoffice-common、file-extension yaml | TASK-002 已建 |
| src/main/resources/application.yml | server.port ${COMMON_PORT:9300}；spring.application.name cloudoffice-common；排除 DataSource/MyBatis 自动配置；**springdoc.group-configs 已含 group: common，paths-to-match: /api/v1/common/**；springdoc api-docs/swagger-ui enabled** | TASK-002 已建；SpringDoc 分组 common 已在 yml 配置（TASK-002 为避免改动共享 SpringDocConfig @Bean 而采用 group-configs 方案），本任务无需重复配置 |
| src/main/java/.../common/model/ApiResult.java | 统一响应体（code/message/data/timestamp），success/error 静态工厂 | 公共 jar 能力，保留 |
| src/main/java/.../common/exception/GlobalExceptionHandler.java | @RestControllerAdvice 全局异常处理器（业务/认证/参数校验/兜底），不泄露堆栈 | 公共 jar 能力，common 独立启动时组件扫描会加载，已存在 |
| src/main/java/.../common/config/SpringDocConfig.java | @Configuration，4 个 @Bean GroupedOpenApi（auth/biz/cloud/system，pathsToMatch 旧路径 /api/auth/** 等） | **本任务不改动**（TASK-002 明确约定避免改动共享 SpringDocConfig @Bean；common 分组经 application.yml group-configs 提供） |
| src/main/java/.../common/controller/ | **不存在** | 需新建 controller 包与 HealthController |

## 3. 健康检查端点参考样板（auth/biz/system，与其对齐）

### auth-service（/api/v1/auth/health）
- 包：`org.cloudstrolling.cloudoffice.auth.controller.HealthController`，`@RestController @RequestMapping("/api/v1/auth") @Slf4j`
- `@Autowired Environment env`；`GET /health` 返回 `ApiResult<Map<String, Object>>`：
  - service = `env.getProperty("spring.application.name", "cloudoffice-auth-service")`
  - status = "UP"
  - version = "0.0.1-SNAPSHOT"
  - timestamp = `Instant.now().toString()`（ISO 格式）
- 返回 `ApiResult.success(info)`。

### system-service（/api/v1/system/health，带 SpringDoc 注解）
- `@RestController @RequestMapping("/api/v1/system") @Slf4j @Tag(name="系统服务健康检查", description=...)`
- 构造器注入 Environment；`@GetMapping("/health") @Operation(summary="健康检查", description=...)`；timestamp 用 `System.currentTimeMillis()`。

### 结论（common 版实现要点）
- 新建 `org.cloudstrolling.cloudoffice.common.controller.HealthController`，`@RestController @RequestMapping("/api/v1/common")`；
- `GET /health` 返回 `ApiResult<Map<String,Object>>`，字段：service（默认 cloudoffice-common，从 Environment 读 spring.application.name）、status=UP、version、timestamp（ISO 格式）；
- 参考 system-service 增加 `@Tag`/`@Operation` 注解以完善 SpringDoc 文档分组内容；
- 全部接口统一 ApiResult + GlobalExceptionHandler（已有）兜底，不泄露堆栈。

## 4. API 契约（API-034，docs/cso-v0.2.8/cso-api-v0.2.8.md 5.1 节）

- 路径 `GET /api/v1/common/health`，白名单无需认证；
- data 为 Map：service（cloudoffice-common）、status（UP）、version（版本号，示例 0.2.8-SNAPSHOT）、timestamp（ISO 格式字符串）；
- 响应示例 code=200、message=操作成功；错误码 500（服务异常）、503（服务不可用）。

## 5. 版本共享文档（读最新，写回需合并）

- `docs/cso-v0.2.8/cso-testcase-v0.2.8.md`：需追加本任务（TASK-003）测试用例，先读最新再合并写回；
- `docs/cso-v0.2.8/cso-ui-test-record-v0.2.8.md`：功能/UI 测试记录（后端任务无 UI，记录说明即可）；
- `scripts/API-TEST/cso-api-test-v0.2.8.py`：接口测试脚本（现含 TASK-005/TASK-002 用例），本任务需新增 TASK-003 用例（健康检查直连 9300 契约校验 + 可选网关白名单）并注册到 main；先读最新再合并写回；
- 任务边界：TASK-004（ConfigController/Service/配置查询）、TASK-005（网关路由/白名单）、TASK-006~010（脚本/文档/env）均为其他任务，本任务不改其代码文件。

## 6. 版本/测试环境说明

- 测试方法：接口测试（testMethod=接口测试）；
- 单元测试：cloudoffice-common 模块已有 CommonApplicationConfigTest 等（Tests run: 120 基线），本任务新增 HealthController 相关单测（静态/契约校验）；
- 接口测试运行依赖服务启动；common 独立启动依赖 Nacos 可达，Nacos 未就绪按环境阻塞 SKIP（沿用 TASK-002 冒烟策略）；
- 现有 deploy 产物：deploy/cloudoffice-common.jar（TASK-002 构建产物，含启动类）。
