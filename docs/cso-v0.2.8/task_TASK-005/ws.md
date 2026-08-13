# 网络资料查询（TASK-005 网关路由与白名单扩展）

## 1. 涉及的三方组件

本任务为 cloudoffice-gateway（Spring Cloud Gateway）纯配置扩展，不引入新的三方依赖，涉及组件：

| 组件 | 版本 | 用途 |
| --- | --- | --- |
| Spring Cloud Gateway（spring-cloud-starter-gateway） | Spring Cloud 2023.0.1 托管版本（Gateway 4.1.x） | 路由定义（RouteDefinition）+ 服务发现负载均衡路由 |
| Spring Cloud LoadBalancer | Spring Cloud 2023.0.1 托管版本 | `lb://` scheme 的负载均衡解析 |
| Spring Cloud Alibaba Nacos Discovery | 2023.0.1.0 | 服务发现（cloudoffice-common 注册名） |
| Nacos 2.3 | 2.3 | 注册中心 |

> 说明：以上组件均为项目既有依赖（`cloudoffice-gateway/pom.xml` 已含 spring-cloud-starter-gateway、spring-cloud-starter-loadbalancer、Nacos discovery；application.yml 已启用 `spring.cloud.gateway.discovery.locator.enabled=true`）。本任务不新增依赖。

## 2. 官方文档要点（Spring Cloud Gateway 官方参考文档）

### 2.1 路由定义（RouteDefinition）配置方式
在 `application.yml` 中通过 `spring.cloud.gateway.routes` 定义路由，路由由 id、uri、predicates、filters 组成：
```yaml
spring:
  cloud:
    gateway:
      routes:
        - id: myRoute
          uri: lb://service-name   # lb scheme → ReactiveLoadBalancerClientFilter 按服务名负载均衡
          predicates:
            - Path=/api/**
```
- `uri: lb://{serviceName}`：使用 `lb` scheme 时，网关通过 `ReactiveLoadBalancerClientFilter`（Spring Cloud LoadBalancer）将服务名解析为真实实例 host:port 并负载均衡；服务名须与注册中心（本工程为 Nacos）中的服务实例名严格一致。
- `Path` predicate：按路径前缀匹配，支持 Ant 风格 `/**`。

### 2.2 服务发现路由定位器（DiscoveryClient Route Locator）
```yaml
spring:
  cloud:
    gateway:
      discovery:
        locator:
          enabled: true
```
- 启用后可为已注册到注册中心的每个服务自动生成 `lb://{serviceId}` 路由；本工程已启用（application.yml 第 40-42 行），可作为兜底，但显式 RouteDefinition 优先级更高、路径控制更精确（本项目采用显式路由方式）。

### 2.3 与 Nacos 集成的关键点
- Nacos 注册的服务实例名即 `spring.application.name`（bootstrap.yml）；cloudoffice-common 服务化（TASK-002）后注册名为 `cloudoffice-common`，网关路由 `lb://cloudoffice-common` 与之一致即可完成服务发现。
- 要求负载均衡实现存在于 classpath（spring-cloud-starter-loadbalancer，本项目已引入）。

## 3. 版本兼容性核对

- 项目 Spring Cloud 版本：2023.0.1（Spring Boot 3.2.5），对应 Spring Cloud Gateway 4.1.x；
- 上述路由配置语法（lb scheme + Path predicate + discovery.locator）在 Gateway 4.1.x 中完全支持，且为项目既有路由（auth/biz/system）已在使用的模式，**无版本兼容问题**。
- 本次新增路由与现有 `auth-service` 路由模式完全一致，属同构配置扩展。

## 4. 相关业务资料与实现要点

### 4.1 网关白名单机制（本工程自定义，非三方组件）
- 白名单配置在 `application.yml` 的 `auth.white-list` 列表（`AuthProperties` 绑定，`@ConfigurationProperties(prefix = "auth")`）；
- `AuthFilter.isWhiteListPath()` 使用 Spring 的 `AntPathMatcher` 对请求路径与白名单逐项匹配，命中即放行；
- 健康检查端点模式：现有 `/api/v1/auth/health` 已在白名单；`/api/v1/common/health` 应与其并列添加（支持 Ant 通配，可精确到端点）。

### 4.2 路由与白名单联动要点
- `/api/v1/common/**` 路由将 common 的 health 与 config 请求都转发到 cloudoffice-common；
- 白名单仅针对 `/api/v1/common/health`（无 Token 放行）；`/api/v1/common/config` 与 `/api/v1/common/config/{serviceName}` 不加入白名单 → 无 Token 时 AuthFilter 返回 401，符合 PRD/SAD/API 文档契约。

### 4.3 幂等与回归保障
- 新增路由/白名单为追加式修改，不删除或改写既有 auth/biz/system 路由与白名单项，保证既有接口回归不受影响（TASK-005 验收标准第 4 条）；
- 测试在 `AuthFilterTest` 中新增 common 路径用例（无 Token 访问 `/api/v1/common/health` 应 200；无 Token 访问 `/api/v1/common/config` 应 401），覆盖网关认证行为。

## 5. 参考链接
- Spring Cloud Gateway 官方参考文档（Routing / LoadBalancer Filter / DiscoveryClient Route Locator）：https://spring.io/projects/spring-cloud-gateway
- Spring Cloud Alibaba Nacos Discovery：https://spring-cloud-alibaba-group.github.io/github-doc/
- 本项目既有实现（同类配置参考）：cloudoffice-gateway/src/main/resources/application.yml（auth/biz/system 路由与白名单）
