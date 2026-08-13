# 现有代码查询（TASK-005 网关路由与白名单扩展）

## 1. 网关模块结构（cloudoffice-gateway）

```
cloudoffice-gateway/
├── pom.xml
└── src/
    ├── main/
    │   ├── java/org/cloudstrolling/cloudoffice/gateway/
    │   │   ├── GatewayApplication.java          # 启动类
    │   │   ├── filter/AuthFilter.java           # 全局认证过滤器（9 步校验）
    │   │   └── config/
    │   │       ├── AuthProperties.java          # @ConfigurationProperties("auth") 白名单列表
    │   │       ├── RsaKeyConfig.java            # RSA 公钥配置
    │   │       └── RedisConfig.java             # ReactiveRedisTemplate 配置
    │   └── resources/
    │       ├── bootstrap.yml                    # Nacos 注册/配置引导（应用名 cloudoffice-gateway）
    │       └── application.yml                  # 路由、白名单、Redis、CORS 配置
    └── test/
        ├── java/org/cloudstrolling/cloudoffice/gateway/
        │   ├── GatewayApplicationTest.java
        │   ├── TestRsaKeyProvider.java
        │   ├── filter/AuthFilterTest.java       # AuthFilter 集成测试
        │   └── config/ (AuthPropertiesTest / RsaKeyConfigTest / RedisConfigTest)
        └── resources/
            ├── application.yml                  # 测试白名单/密钥配置
            └── bootstrap.yml                    # 测试 Nacos 引导配置
```

## 2. 网关路由配置（src/main/resources/application.yml，本任务主要修改文件）

现有路由 `spring.cloud.gateway.routes`：
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: auth-service
          uri: lb://cloudoffice-auth-service
          predicates:
            - Path=/api/v1/auth/**
        - id: biz-service
          uri: lb://cloudoffice-biz-service
          predicates:
            - Path=/api/v1/biz/**
        - id: system-service
          uri: lb://cloudoffice-system-service
          predicates:
            - Path=/api/v1/system/**
      globalcors: ... # allowedOriginPatterns "*" 等
      discovery:
        locator:
          enabled: true
```
- 路由采用 `lb://{服务名}` + `Path=/api/v1/{module}/**` 模式，与 Nacos 服务发现集成。
- **需新增**：`id: common-service`、`uri: lb://cloudoffice-common`、`Path=/api/v1/common/**`。

现有白名单 `auth.white-list`：
```yaml
auth:
  white-list:
    - /api/v1/auth/login
    - /api/v1/auth/register
    - /api/v1/auth/refresh
    - /api/v1/auth/logout
    - /api/v1/auth/health
    - /api/v1/auth/verification-code/send
    - /api/v1/auth/password/forgot/send-code
    - /api/v1/auth/password/forgot/reset
    - /swagger-ui/**
    - /v3/api-docs/**
    - /favicon.ico
    - /webjars/**
```
- 白名单以路径列表配置在 `application.yml` 的 `auth.white-list` 下，由 `AuthProperties` 绑定。
- **需新增**：`/api/v1/common/health`（置于 auth 健康检查之后、swagger 之前，与 auth/biz/system 健康检查端点一致）。

## 3. 白名单绑定与匹配机制

- `config/AuthProperties.java`：`@ConfigurationProperties(prefix = "auth")` + `@Data` + `@Component`，字段 `List<String> whiteList = new ArrayList<>()`。白名单无需修改 Java 代码。
- `filter/AuthFilter.java`：`isWhiteListPath(String path)` 使用 `AntPathMatcher` 对白名单逐项匹配，命中即放行（`return chain.filter(exchange)`）；未命中继续 9 步认证（Bearer 校验→RS256 验签→tokenType→黑名单→会话→账号→租户→Header 透传）。**白名单扩展为纯配置变更，无需改动 AuthFilter Java 代码**。

## 4. 网关测试现状（AuthFilterTest.java）

- 集成测试 `@SpringBootTest(classes = GatewayApplication.class, webEnvironment = DEFINED_PORT)`，端口 9999；
- 通过 properties 注入白名单：`auth.white-list[0]=/api/v1/auth/login` ... `[7]=/webjars/**`；
- `TestConfig` 通过 `RouteLocatorBuilder` 定义两条测试路由（test-health `/api/v1/auth/health`、test-echo `/api/v1/biz/echo`），使用自定义 GatewayFilter 直接构造响应，避免真实 HTTP 代理；
- 用例：白名单无 Token 放行（`/api/v1/auth/health`）、无 Token 401、有效 Token 透传 Header、黑名单 401、登录态不存在 401、过期 Token 401、tokenType=refresh 401、非 Bearer 401、空 Bearer 401、过滤器优先级校验。
- **需新增测试**：common 白名单无 Token 放行（`/api/v1/common/health`）、common 非白名单路径无 Token 401（`/api/v1/common/config`）。

## 5. 测试资源配置（src/test/resources/application.yml）

```yaml
auth:
  white-list:
    - /api/v1/auth/login
    - /api/v1/auth/register
    - /api/v1/auth/refresh
    - /api/v1/auth/health
    - /swagger-ui/**
    - /v3/api-docs/**
    - /favicon.ico
    - /webjars/**
  rsa:
    public-key: MIIBIjANBgkqh...
```
- 测试白名单独立维护；本任务需同步补充 `/api/v1/common/health`（如测试依赖该配置）或以 properties 注入方式在测试类中声明。

## 6. API 设计文档现状（docs/cso-v0.2.8/cso-api-v0.2.8.md）

- **API-034**：`GET /api/v1/common/health`（白名单放行，返回服务名/状态 UP/版本/时间戳）；
- **API-035**：`GET /api/v1/common/config`（需认证，serviceName/group/key 过滤 + 分页）；
- **API-036**：`GET /api/v1/common/config/{serviceName}`（需认证，按微服务查询不分页）；
- API 文档第 2/3 章已明确：网关新增 `/api/v1/common/** → lb://cloudoffice-common` 路由；白名单新增 `/api/v1/common/health`；config 端点保持非白名单需认证。**API 设计已先行完成，本任务无需新增/变更接口设计**，但应在 api 子步骤核对一致性。

## 7. 本任务代码改动范围（仅网关模块）

| 文件 | 改动 |
| --- | --- |
| cloudoffice-gateway/src/main/resources/application.yml | 新增 common-service 路由 + 白名单 `/api/v1/common/health` |
| cloudoffice-gateway/src/test/java/.../filter/AuthFilterTest.java | 新增 common 白名单/非白名单测试用例与测试路由 |
| cloudoffice-gateway/src/test/resources/application.yml | （按需）同步测试白名单 |

> 注意：`cloudoffice-common` 服务端（启动类/健康检查/配置接口）由 TASK-002/003/004 并行实现，本任务只负责网关侧路由与白名单配置，两者通过 Nacos 服务名 `cloudoffice-common` 契约衔接。
