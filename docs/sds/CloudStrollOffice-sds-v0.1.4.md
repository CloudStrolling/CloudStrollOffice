# SDS 技术规格说明书

**项目名称：** 云漫智企
**项目英文名：** CloudStrollOffice
**版本号：** v0.1.4
**日期：** 2026-06-19

---

## 1. 技术方案概述

### 1.1 系统定位

cloudoffice-system-service（系统服务）是云漫智企微服务架构中**基础公共服务承载服务**，负责提供系统参数配置管理、操作日志、监控告警、定时任务等公共基础能力。v0.1.4 阶段完成该模块的骨架搭建，使其具备与认证服务（auth-service）、企业服务（biz-service）一致的独立启动、Nacos 注册、健康检查和单元测试能力。

### 1.2 架构风格

- **选用风格：** 微服务架构（Microservices Architecture）
- **技术栈：** Spring Boot 3.2.x + Spring Cloud 2023.x + Spring Cloud Alibaba
- **注册/配置中心：** Nacos 2.3.x
- **数据库：** MariaDB 10.6 LTS（本期预留，排除 DataSourceAutoConfiguration，无 DB 可启动）
- **ORM 框架：** MyBatis-Plus 3.5.x
- **API 文档：** SpringDoc (OpenAPI 3)

### 1.3 核心工作流

```
开发者 IDE 启动 SystemApplication
        │
        ▼
Spring Boot 上下文初始化
        │
        ├── 加载 bootstrap.yml（Nacos 注册中心/配置中心地址）
        ├── 加载 application.yml（端口 9400、数据源、MyBatis-Plus 等）
        │
        ▼
Nacos 服务注册（服务名：cloudoffice-system-service）
        │
        ▼
健康检查端点可用（GET /api/v1/system/health → 200 OK）
```

### 1.4 关键设计原则

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| 渐进式搭建 | 服务按"启动入口 → 基础端点 → 骨架目录 → 测试覆盖"逐步完善 | v0.1.4 仅搭建骨架，不实现具体业务逻辑 |
| 统一规范 | 所有模块遵循相同的包结构、编码规范和测试标准 | 包结构与 auth-service/biz-service 保持一致 |
| 可观测优先 | 每个服务从搭建之初就提供健康检查和标准日志 | `@Slf4j` 日志 + GET /api/v1/system/health 端点 |
| 无数据库可启动 | 排除 DataSourceAutoConfiguration，不强制依赖 MariaDB | DB 连接失败时仅输出 WARN 日志，不阻塞启动 |

### 1.5 对应 PRD UserStory 一览

| 编号 | 技术方案覆盖 |
|------|-------------|
| US-001: 系统服务启动与注册 | 2.1 系统服务模块 — SystemApplication 启动类、Nacos 注册 |
| US-002: 健康检查接口 | 4.2 外部 REST API — GET /api/v1/system/health |
| US-003: 系统服务应用配置 | 3. 数据设计 — bootstrap.yml / application.yml 配置 |
| US-004: 系统服务骨架结构 | 2.1 系统服务模块 — 标准包目录结构 |
| US-005: 系统服务单元测试 | 2.3 测试模块 — SystemApplicationTest / HealthControllerTest |

---

## 2. 模块概要设计

### 2.1 模块清单

| 模块名称 | 模块类型 | 端口 | 功能描述 |
|---------|---------|------|---------|
| cloudoffice-system-service | 公共服务 | 9400 | 系统参数配置、操作日志、监控告警、定时任务等基础公共服务载体 |

### 2.2 模块依赖关系

```
cloudoffice-common (无业务依赖，提供 ApiResult / GlobalExceptionHandler / BaseEntity 等)
       ▲
       │ Maven 依赖
       │
cloudoffice-system-service (端口 9400)
       │
       ├── Nacos 注册中心（服务注册与发现）
       ├── Nacos 配置中心（统一配置管理，本期以本地配置为主）
       └── MariaDB 数据库（cloudstroll_office_system，本期预留）
```

#### 依赖清单

| 依赖 | 说明 | Scope |
|------|------|-------|
| spring-boot-starter-web | Spring Boot Web 启动器 | compile |
| mybatis-plus-spring-boot3-starter | MyBatis-Plus 持久层框架 | compile |
| mariadb-java-client | MariaDB JDBC 驱动 | compile |
| spring-cloud-starter-alibaba-nacos-discovery | Nacos 服务注册与发现 | compile |
| spring-cloud-starter-alibaba-nacos-config | Nacos 配置中心 | compile |
| cloudoffice-common | 公共模块（统一响应体、异常处理、基础实体等） | compile |
| lombok | 代码简化 | provided |
| spring-boot-starter-test | 测试框架 | test |

### 2.3 模块内部结构

#### 标准包目录结构

```
org.cloudstrolling.cloudoffice.system
├── SystemApplication.java          # 启动入口（@SpringBootApplication + @EnableDiscoveryClient）
├── config/                         # 配置类（MyBatis-Plus 配置、SpringDoc 配置等）
├── controller/                     # 控制器层
│   └── HealthController.java       # 健康检查控制器（GET /api/v1/system/health）
├── service/                        # 业务逻辑层接口（预留）
│   └── impl/                       # 业务逻辑实现类（预留）
├── mapper/                         # 数据访问层（预留）
├── entity/                         # 实体类（预留）
├── dto/                            # 数据传输对象（预留）
├── vo/                             # 视图对象（预留）
├── enums/                          # 枚举类（预留）
├── exception/                      # 异常处理类（预留）
├── filter/                         # 过滤器（预留）
├── interceptor/                    # 拦截器（预留）
└── util/                           # 工具类（预留）
```

#### 资源文件

```
src/main/resources/
├── bootstrap.yml    # Nacos 注册中心/配置中心配置
└── application.yml  # 应用配置（端口、数据源、MyBatis-Plus、SpringDoc、日志）
```

#### 测试模块

```
src/test/java/org/cloudstrolling/cloudoffice/system/
├── SystemApplicationTest.java           # 应用启动测试
└── controller/
    └── HealthControllerTest.java        # 健康检查控制器测试

src/test/resources/
└── bootstrap.yml                        # 测试环境 Nacos 禁用配置
```

### 2.4 关键类说明

| 类名 | 包路径 | 功能描述 |
|------|--------|----------|
| SystemApplication | `org.cloudstrolling.cloudoffice.system` | 系统服务启动入口，标注 `@SpringBootApplication` 启用自动配置，标注 `@EnableDiscoveryClient` 启用 Nacos 服务注册发现，包含标准 main 方法 |
| HealthController | `org.cloudstrolling.cloudoffice.system.controller` | 健康检查 REST 控制器，标注 `@RestController` + `@RequestMapping("/api/v1/system")`，提供 GET /health 端点，返回 service/status/version/timestamp 信息 |
| SystemApplicationTest | `org.cloudstrolling.cloudoffice.system` | 应用启动测试，使用 `@SpringBootTest` 加载完整上下文，验证 Spring 上下文加载成功和 `@EnableDiscoveryClient` 注解存在 |
| HealthControllerTest | `org.cloudstrolling.cloudoffice.system.controller` | 健康检查控制器单元测试，通过反射注入 Mock Environment，验证 200 状态码、ApiResult 响应体各字段正确性 |

---

## 3. 数据设计

### 3.1 数据库说明

- **数据库名：** `cloudstroll_office_system`（本期预留）
- **数据库类型：** MariaDB 10.6 LTS
- **连接池：** HikariCP 5.x
- **状态：** v0.1.4 无业务表，数据库连接配置存在但不影响启动

### 3.2 数据字典

v0.1.4 阶段仅建立服务骨架，无业务实体表和数据库表。后续版本将根据业务功能逐步新增 `t_system_config`（系统配置表）、`t_system_operate_log`（操作日志表）等数据表。

### 3.3 数据库连接配置

```yaml
# application.yml
spring:
  datasource:
    url: ${DB_URL:jdbc:mariadb://127.0.0.1:3306/cloudstroll_office_system}
    username: ${DB_USER:root}
    password: ${DB_PASSWORD:root}
    driver-class-name: org.mariadb.jdbc.Driver
  autoconfigure:
    exclude: org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration
```

- 数据库连接参数支持通过环境变量覆盖：`DB_URL`、`DB_USER`、`DB_PASSWORD`
- 排除 `DataSourceAutoConfiguration`，无数据库连接时仅输出 WARN 日志，不阻塞启动

### 3.4 MyBatis-Plus 配置

```yaml
mybatis-plus:
  configuration:
    map-underscore-to-camel-case: true   # 驼峰命名映射
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl  # 控制台 SQL 日志
  global-config:
    db-config:
      logic-delete-field: deleted        # 逻辑删除字段
      logic-delete-value: 1              # 已删除值
      logic-not-delete-value: 0          # 正常值
```

---

## 4. 接口设计

### 4.1 内部接口

| 接口名称 | 通信方式 | 调用关系 | 说明 |
|---------|---------|---------|------|
| SystemApplication.main() | JVM 进程内 | 开发者 IDE 调用 | 服务启动入口，加载 Spring 上下文 |
| 服务注册 | Nacos SDK (gRPC/HTTP) | system-service → Nacos Server | 启动时自动注册到 Nacos 注册中心 |
| 配置拉取 | Nacos SDK (gRPC/HTTP) | system-service → Nacos Server | bootstrap.yml 指定配置中心地址 |

### 4.2 外部 REST API

#### GET /api/v1/system/health

**功能描述：** 系统服务健康检查端点，返回服务运行状态信息，用于容器编排平台的就绪探针（Readiness Probe）和存活探针（Liveness Probe）检测。

**请求规范：**

| 项目 | 值 |
|------|-----|
| 请求方法 | GET |
| 请求路径 | `/api/v1/system/health` |
| 请求头 | 无（无需认证） |
| 请求参数 | 无 |

**成功响应（200 OK）：**

```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-system-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": 1770000000000
  },
  "timestamp": 1770000000000
}
```

**响应字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| code | Integer | 状态码，200 表示成功 |
| message | String | 提示信息 "操作成功" |
| data.service | String | 服务名称，通过 `spring.application.name` 获取 |
| data.status | String | 服务状态，固定为 "UP" |
| data.version | String | 服务版本号，从 `build-info` 或 `pom.xml` 获取 |
| data.timestamp | Long | 当前时间戳（毫秒） |
| timestamp | Long | 响应时间戳（毫秒） |

**错误场景：**

| 场景 | HTTP 状态码 | 响应体 |
|------|------------|--------|
| 服务内部异常 | 500 | ApiResult 格式的错误响应 |
| 路径不存在（如 `/api/v1/system/health/`） | 404 | Spring 默认 404 页面或 ApiResult |
| 请求方法错误（如 POST） | 405 | Spring 默认 405 响应 |

### 4.3 通信协议

| 项目 | 规范 |
|------|------|
| 协议 | HTTP/1.1 |
| 数据格式 | JSON（UTF-8 编码） |
| 统一响应体 | `ApiResult<T>` — code/message/data/timestamp |
| 媒体类型 | `application/json` |
| 路径版本策略 | 路径前缀 `/api/v1/` |

### 4.4 错误码定义

v0.1.4 阶段使用 common 模块的通用错误码体系：

| 错误码 | HTTP 状态码 | 说明 |
|--------|------------|------|
| SUCCESS (200) | 200 | 操作成功 |
| BAD_REQUEST (400) | 400 | 请求参数错误 |
| UNAUTHORIZED (401) | 401 | 未认证 |
| FORBIDDEN (403) | 403 | 权限不足 |
| NOT_FOUND (404) | 404 | 资源不存在 |
| INTERNAL_ERROR (500) | 500 | 服务器内部错误 |
| SYS-0001 ~ SYS-9999 | 500/400 | 系统服务业务错误码段（后续版本扩展） |

---

## 5. 安全设计

### 5.1 威胁模型

v0.1.4 阶段为骨架搭建阶段，仅暴露健康检查端点，无业务数据和用户认证需求。安全风险极低。

### 5.2 认证机制

- 健康检查端点（`/api/v1/system/health`）无需认证，对外开放
- 其他端点预留认证拦截器扩展点（`filter/`、`interceptor/` 目录预留）
- API 文档（`/swagger-ui.html`、`/v3/api-docs`）在开发环境无需认证

### 5.3 敏感数据处理

| 数据类型 | 处理方式 | 存储位置 |
|---------|---------|---------|
| 数据库密码 | 环境变量 `DB_PASSWORD` 注入 | 环境变量 |
| 数据库用户名 | 环境变量 `DB_USER` 注入，默认值 root | 环境变量 / application.yml |
| Nacos 地址 | 环境变量 `NACOS_ADDR` 注入，默认值 127.0.0.1:8848 | 环境变量 / bootstrap.yml |

- **约束：** 代码仓库中不出现明文敏感信息，所有敏感配置通过环境变量覆盖默认值

---

## 6. 非功能需求设计

### 6.1 性能指标

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 服务首次启动时间 | ≤ 30 秒 | Maven 构建日志 + IDE 控制台 |
| 健康检查接口响应时间 | < 100ms | JMeter / curl + time 命令 |
| Maven 编译时间 | ≤ 30 秒 | `mvn clean compile -pl cloudoffice-system-service -am` 计时 |

### 6.2 可用性

| 场景 | 预期行为 |
|------|---------|
| 数据库连接失败（无 MariaDB） | 服务正常启动，仅输出 WARN 级别日志，不阻塞启动 |
| Nacos 连接失败 | 服务启动失败，输出明确错误日志，提示检查 Nacos 地址和运行状态 |
| 端口 9400 被占用 | 端口绑定异常，服务启动失败，日志提示端口冲突 |
| Nacos 配置中心不可用 | 使用本地配置文件（bootstrap.yml / application.yml）作为兜底 |

### 6.3 可靠性

| 机制 | 实现方案 |
|------|---------|
| 全局异常兜底 | `@RestControllerAdvice` + `@ExceptionHandler(Exception.class)`，由 common 模块 `GlobalExceptionHandler` 提供，覆盖 12+ 异常场景 |
| 日志记录 | `@Slf4j` 注解统一日志记录，关键配置项加载状态在启动日志中记录 |
| 敏感信息保护 | 数据库密码等敏感信息不打印到日志中 |

### 6.4 可观测性

| 类型 | 方案 | 本阶段状态 |
|------|------|-----------|
| 日志 | SLF4J（Logback）+ `@Slf4j` 注解 | ✔ 已启用 |
| 健康检查 | GET /api/v1/system/health 端点 | ✔ 已启用 |
| Actuator | Spring Boot Actuator（`/actuator/health`） | ✔ 已启用 |
| API 文档 | SpringDoc OpenAPI 3 + Swagger UI | ✔ 已启用 |
| 指标 | Prometheus + Grafana | ⏳ 后续版本 |
| 链路追踪 | SkyWalking | ⏳ 后续版本 |

### 6.5 可维护性

| 维度 | 规范要求 |
|------|---------|
| 包结构 | 与 auth-service、biz-service 完全一致，遵循标准 13 目录结构 |
| 命名规范 | 包名 `org.cloudstrolling.cloudoffice.system.{subpackage}`，类名 PascalCase，方法名 camelCase |
| 注释规范 | 类注释含 `@author` 和 `@since`，方法注释含 `@param` 和 `@return` |
| 日志规范 | 统一使用 `@Slf4j`，遵循 trace/debug/info/warn/error 级别规范 |
| API 文档 | 使用 SpringDoc 注解（`@Schema`、`@Operation`）生成 OpenAPI 3 文档 |

### 6.6 测试要求

| 测试目标 | 要求 |
|---------|------|
| 启动类测试 | 验证 Spring 上下文加载成功、`@EnableDiscoveryClient` 注解存在 |
| 健康检查控制器测试 | 验证 200 状态码、ApiResult 响应体各字段正确性 |
| 环境独立性 | 测试环境禁用 Nacos（测试 bootstrap.yml），排除 DataSourceAutoConfiguration，无外部中间件依赖 |
| 测试框架 | JUnit 5 + Mockito，遵循 Given-When-Then 模式 |
| 测试命名规范 | `{methodName}_{scenario}_{expectedResult}` |

---

## 7. 部署与运维设计

### 7.1 服务规格

| 属性 | 值 |
|------|-----|
| 服务名称 | cloudoffice-system-service |
| 端口 | 9400 |
| 服务注册名 | cloudoffice-system-service |
| 默认 Nacos 地址 | 127.0.0.1:8848 |
| 默认数据库地址 | 127.0.0.1:3306 |
| 默认数据库名 | cloudstroll_office_system |

### 7.2 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| NACOS_ADDR | 127.0.0.1:8848 | Nacos 注册/配置中心地址 |
| DB_URL | jdbc:mariadb://127.0.0.1:3306/cloudstroll_office_system | 数据库 JDBC URL |
| DB_USER | root | 数据库用户名 |
| DB_PASSWORD | root | 数据库密码 |

### 7.3 Maven 编译与运行

```bash
# 编译（仅编译系统服务及其依赖模块）
mvn clean compile -pl cloudoffice-system-service -am

# 运行测试
mvn test -pl cloudoffice-system-service

# 打包
mvn clean package -pl cloudoffice-system-service -am -DskipTests
```

### 7.4 Docker 部署

**Dockerfile 模板路径：** `scripts/docker/system-service/Dockerfile`

```dockerfile
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY target/cloudoffice-system-service-*.jar app.jar
EXPOSE 9400
ENV NACOS_ADDR=127.0.0.1:8848
ENV DB_URL=jdbc:mariadb://127.0.0.1:3306/cloudstroll_office_system
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Docker Compose 集成：** 由项目根目录 `scripts/docker/docker-compose.yml` 统一编排

### 7.5 环境划分

| 环境 | 部署方式 | Nacos 地址 | 数据库地址 |
|------|---------|-----------|-----------|
| 开发环境（dev） | IDE 直接启动 / Docker | 127.0.0.1:8848 | 127.0.0.1:3306 |
| 测试环境（test） | Docker Compose | 按环境配置 | 按环境配置 |
| 生产环境（prod） | Docker / K8s（后续） | 按环境配置 | 按环境配置 |

---

## 8. 风险与缓解措施

| 风险编号 | 风险描述 | 可能性 | 影响 | 缓解措施 |
|---------|---------|-------|------|---------|
| RISK-001 | Nacos 服务未启动导致系统服务启动失败 | 中 | 高 | 启动时验证 Nacos 连接，输出明确错误日志指导开发者检查 Nacos 地址；bootstrap.yml 默认值 127.0.0.1:8848 |
| RISK-002 | MariaDB 数据库未安装导致启动异常 | 中 | 中 | 排除 `DataSourceAutoConfiguration`，无 DB 时仅输出 WARN 日志，服务 HTTP 端口正常监听 |
| RISK-003 | 端口 9400 被其他进程占用 | 低 | 高 | 端口绑定异常时服务启动失败，日志输出明确端口冲突提示 |
| RISK-004 | 父 POM 依赖版本不一致导致编译失败 | 低 | 高 | 子模块不出现硬编码版本号，统一由父 POM `<dependencyManagement>` 管理 |

---

## 9. 附录

### 9.1 术语表

| 术语 | 释义 |
|------|------|
| Nacos | 阿里巴巴开源的服务注册发现和配置管理平台 |
| Spring Cloud Alibaba | 阿里巴巴微服务解决方案，集成 Nacos、Sentinel、Seata 等组件 |
| ApiResult | 统一 API 响应体，包含 code/message/data/timestamp 字段 |
| GlobalExceptionHandler | 全局异常处理器，使用 `@RestControllerAdvice` 统一拦截处理异常 |
| Actuator | Spring Boot 提供生产级可观测性功能（健康检查、指标、日志等） |
| SpringDoc | OpenAPI 3 规范的 Java 实现，自动生成 RESTful API 文档 |
| MyBatis-Plus | MyBatis 的增强工具，提供代码生成器、分页插件、Lambda 查询等功能 |
| HikariCP | Spring Boot 默认的 JDBC 连接池，性能业界最优 |

### 9.2 参考文档

| 文档名称 | 路径 |
|---------|------|
| 需求文档 v0.1.4 | `docs/requires/CloudStrollOffice-requirement-v0.1.4.md` |
| PRD 文档 v0.1.4 | `docs/prds/CloudStrollOffice-prd-v0.1.4.md` |
| 架构文档 | `docs/architecture.md` |
| 项目信息与编码规范 | `docs/project.md` |

### 9.3 附录：配置模板

#### bootstrap.yml

```yaml
spring:
  application:
    name: cloudoffice-system-service
  cloud:
    nacos:
      discovery:
        server-addr: ${NACOS_ADDR:127.0.0.1:8848}
      config:
        server-addr: ${NACOS_ADDR:127.0.0.1:8848}
        file-extension: yaml
```

#### application.yml

```yaml
server:
  port: 9400

spring:
  datasource:
    url: ${DB_URL:jdbc:mariadb://127.0.0.1:3306/cloudstroll_office_system}
    username: ${DB_USER:root}
    password: ${DB_PASSWORD:root}
    driver-class-name: org.mariadb.jdbc.Driver
  autoconfigure:
    exclude: org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration

mybatis-plus:
  configuration:
    map-underscore-to-camel-case: true
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
  global-config:
    db-config:
      logic-delete-field: deleted
      logic-delete-value: 1
      logic-not-delete-value: 0

springdoc:
  api-docs:
    enabled: true
  swagger-ui:
    enabled: true

logging:
  level:
    org.cloudstrolling: DEBUG
```
