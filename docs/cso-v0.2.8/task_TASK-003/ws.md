# 网络资料查询（#TASK-003 common 健康检查端点与 API 服务（HealthController + SpringDoc））

## 1. 涉及的三方组件

| 组件 | 用途 | 项目版本 | 资料版本 |
| --- | --- | --- | --- |
| springdoc-openapi-starter-webmvc-ui | SpringDoc OpenAPI 3 + Swagger UI（WebMVC 场景，common 服务使用） | 2.5.0（父 POM dependencyManagement 管理，SAD 技术栈表） | 2.5.x（与 Spring Boot 3.2.x 兼容） |
| spring-boot-starter-web | Web MVC 容器（common 独立服务） | 3.2.5 | 3.2.x |
| io.swagger.v3:swagger-annotations（随 springdoc 传递引入） | @Tag / @Operation 注解（可选，用于完善文档） | 2.2.x（springdoc 2.5 依赖） | 2.2.x |

版本兼容结论：springdoc-openapi 2.5.0 官方支持 Spring Boot 3.2.x 与 WebMVC；本项目 cloudoffice-common 使用 webmvc-starter，兼容性无风险。

## 2. SpringDoc OpenAPI 3 关键用法

### 2.1 分组配置（springdoc.group-configs，YAML 方式）
- 官方支持在 `application.yml` 用 `springdoc.group-configs` 定义多个 API 分组，按路径（paths-to-match）或包（packages-to-scan）过滤端点；
- 本项目 TASK-002 已在 application.yml 配置：
  ```yaml
  springdoc:
    api-docs:
      enabled: true
      path: /v3/api-docs
    swagger-ui:
      enabled: true
      path: /swagger-ui.html
    group-configs:
      - group: common
        paths-to-match: /api/v1/common/**
  ```
- 访问入口：Swagger UI `{host}:{port}/swagger-ui.html`；OpenAPI JSON `{host}:{port}/v3/api-docs`（分组端点 `{host}:{port}/v3/api-docs/common`）。
- 结论：common 分组已在 yml 配置完毕，本任务只需确保 HealthController 端点落入 `/api/v1/common/**` 路径即可被该分组收录；**无需新增/修改 SpringDocConfig 的 @Bean**（TASK-002 约定避免改动共享 SpringDocConfig）。

### 2.2 @Tag / @Operation 注解（完善文档）
- `@Tag(name = "...", description = "...")` 标注在 Controller 类上，组织操作到文档分组；
- `@Operation(summary = "...", description = "...")` 标注在方法上，描述接口含义；
- 使用示例（与 system-service HealthController 一致）：
  ```java
  @RestController
  @RequestMapping("/api/v1/common")
  @Tag(name = "common 服务健康检查", description = "提供 common 服务的存活探活与基础信息获取接口")
  public class HealthController {
      @GetMapping("/health")
      @Operation(summary = "健康检查", description = "返回 common 服务运行状态、版本号和时间戳")
      public ApiResult<Map<String, Object>> health() { ... }
  }
  ```
- 本项目依赖 springdoc-openapi-starter-webmvc-ui 已传递引入 swagger-annotations（io.swagger.v3.oas.annotations），可直接 import `io.swagger.v3.oas.annotations.Operation`、`io.swagger.v3.oas.annotations.tags.Tag`。

### 2.3 Spring Security 放行文档端点
- 官方建议在安全配置中放行 `/v3/api-docs/**`、`/swagger-ui/**`、`/swagger-ui.html` 等文档路径；
- 本项目网关 AuthFilter 白名单已含 `/swagger-ui/**`、`/v3/api-docs/**`（API 文档白名单）；common 服务自身未启用 Spring Security 过滤链（pom 仅引 spring-security-core 用于异常类），文档端点默认可访问，无需额外配置。

## 3. Spring Boot 健康检查端点实践

- 参考现有 auth/biz/system 三服务 HealthController 契约：返回 `ApiResult<Map<String,Object>>`，data 含 service/status/version/timestamp；
- common 版：service 从 `Environment.getProperty("spring.application.name", "cloudoffice-common")` 读取；status 固定 "UP"；version 对齐 API 契约示例（0.2.8-SNAPSHOT）；timestamp 用 `Instant.now().toString()`（ISO 格式，与 auth 一致）。

## 4. 相关任务资料与经验

- **统一 ApiResult**：全接口统一 code/message/data/timestamp，GlobalExceptionHandler（@RestControllerAdvice）兜底，不泄露堆栈——本项目 common 公共模块已有，直接复用；
- **错误码契约**：API-034 错误码 500（服务异常）、503（服务不可用）；健康检查正常路径仅返回 200；
- **白名单**：`/api/v1/common/health` 已在网关 AuthFilter 白名单（TASK-005 完成），本任务无需处理网关侧；
- **接口测试注意**：common 独立启动依赖 Nacos；Nacos 未就绪时接口脚本按环境阻塞 SKIP（沿用 TASK-002 冒烟策略）；脚本直连 common 9300 校验健康契约，网关不可达按 SKIP。

## 5. 排错经验

- 若 Swagger UI 无法访问，检查 `springdoc.swagger-ui.enabled` 与 `springdoc.api-docs.enabled` 是否 true、路径是否被安全配置拦截；
- 若分组为空，检查 paths-to-match 与端点实际路径是否匹配（本任务端点 `/api/v1/common/health` 命中 `/api/v1/common/**`）；
- 若 common 启动报 Nacos 连接错误，属环境未就绪（PRD US-001 边界场景），按环境阻塞处理，不视为代码缺陷。
