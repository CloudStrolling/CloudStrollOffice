# 需求文档

**项目名称：** 云漫智企 (CloudStrollOffice)
**版本号：** v0.1.4
**日期：** 2026-06-19

---

## 修订记录

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| v0.1.4 | 2026-06-19 | 初始版本，定义系统服务模块搭建需求 | BA |

---

## 1. 项目背景

### 1.1 业务背景

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务互联网应用程序。v0.1.0 阶段完成了微服务基础骨架搭建（Maven 多模块、公共组件、API 网关、认证服务骨架、企业服务骨架、系统服务骨架），v0.1.1~v0.1.3 阶段进行了配置优化与细节调整。

v0.1.4 阶段的目标是**完成系统服务（cloudoffice-system-service）的模块搭建**。系统服务作为基础公共服务承载服务，将在后续版本中提供系统参数配置管理、操作日志、监控告警、定时任务等公共基础能力。本阶段聚焦于完成该模块的启动入口、健康检查端点、应用配置及标准包结构，与 v0.1.0 阶段已建成的认证服务骨架（FR-004）、企业服务骨架（FR-005）保持一致的实现水准。

### 1.2 业务痛点

1. **系统服务缺失：** v0.1.0 阶段仅搭建了系统服务的基础骨架包结构，缺少完整的启动类、健康检查端点和应用配置，无法独立启动
2. **缺少统一基础公共服务载体：** 系统参数配置、操作日志、监控告警等基础公共功能无处承载，阻碍后续业务功能开发
3. **服务治理盲区：** 缺少系统服务的健康检查端点，无法通过网关或监控系统感知系统服务的存活状态
4. **与现有服务标准不一致：** v0.1.0 阶段的认证服务（auth-service）和企业服务（biz-service）已具备完整的启动入口和健康检查端点，系统服务需要补齐到相同水准

### 1.3 项目目标

1. 完成系统服务启动入口（SystemApplication），集成 Nacos 服务发现和配置中心
2. 提供系统服务健康检查端点（/api/v1/system/health）
3. 完成应用配置（端口、数据源、MyBatis-Plus、日志等）
4. 建立标准的包目录结构
5. 提供基础单元测试验证

### 1.4 适用范围

本文档适用于 CloudStrollOffice v0.1.4 版本的开发，覆盖系统服务（cloudoffice-system-service）模块搭建的全部需求范围。

---

## 2. 总体需求描述

### 2.1 角色定义

| 角色 | 描述 |
|------|------|
| 后端开发工程师 | 负责系统服务模块的开发和维护 |
| 系统架构师 | 负责整体技术架构设计和规范符合性审查 |
| 测试工程师 | 负责系统服务模块的测试验证 |

### 2.2 系统上下文

```
[开发者/IDE] ──▶ [cloudoffice-system-service 模块]
                      ├── SystemApplication.java  (启动入口)
                      ├── controller/              (控制器层)
                      │   └── HealthController.java (健康检查)
                      ├── config/ / service/ / mapper/ / entity/ / dto/ / vo/ / enums/ / exception/ / filter/ / interceptor/ / util/
                      │   └── (预留扩展点)
                      ├── bootstrap.yml            (Nacos 配置)
                      └── application.yml          (应用配置)
                             │
                             ▼
                      [Nacos 注册中心/配置中心]
                             │
                             ▼
                      [MariaDB 数据库]
```

### 2.3 模块定位

系统服务（cloudoffice-system-service）在整个微服务架构中承担基础公共服务职能：

- **端口：** 9400
- **包名：** `org.cloudstrolling.cloudoffice.system`
- **依赖：** cloudoffice-common（公共模块）
- **后续承载功能：** 系统参数配置管理、操作日志、监控告警、定时任务等

---

## 3. 功能需求

### FR-001: 系统服务启动入口

- **描述：** 创建 cloudoffice-system-service 的 Spring Boot 启动类 `SystemApplication`，集成 Nacos 服务发现和配置中心，作为系统服务的启动入口。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 启动类位于 `org.cloudstrolling.cloudoffice.system` 包下，类名为 `SystemApplication`
  2. 标注 `@SpringBootApplication` 注解，启用 Spring Boot 自动配置
  3. 标注 `@EnableDiscoveryClient` 注解，启用服务注册与发现能力
  4. 包含标准的 `main(String[] args)` 主方法，调用 `SpringApplication.run()`
  5. 类注释包含 `@author` 和 `@since` 信息
  6. 服务启动后成功注册到 Nacos 注册中心，在 Nacos 控制台可见 `cloudoffice-system-service` 服务实例
  7. 启动日志显示 "Started SystemApplication" 以确认上下文加载成功

### FR-002: 系统服务健康检查端点

- **描述：** 提供 `GET /api/v1/system/health` 健康检查接口，返回服务状态信息，用于容器编排平台的就绪探针和存活探针检测。
- **优先级：** 高 (Must)
- **验收标准：**
  1. `HealthController` 位于 `org.cloudstrolling.cloudoffice.system.controller` 包下
  2. 类标注 `@RestController` 和 `@RequestMapping("/api/v1/system")` 注解
  3. 方法标注 `@GetMapping("/health")`，响应 `GET /api/v1/system/health` 请求
  4. 返回 200 状态码，响应体使用 `ApiResult<Map<String, Object>>` 统一格式
  5. 返回的 data 字段包含以下信息：
     - `service`：服务名称（`cloudoffice-system-service` 或通过 `spring.application.name` 获取）
     - `status`：状态（`"UP"`）
     - `version`：版本号
     - `timestamp`：当前时间戳
  6. 控制器使用 `@Slf4j` 注解
  7. 可通过 `http://localhost:9400/api/v1/system/health` 访问

### FR-003: 系统服务应用配置

- **描述：** 配置系统服务的 Nacos 注册中心/配置中心地址、服务端口、数据库连接、MyBatis-Plus、SpringDoc 和日志级别等。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **bootstrap.yml** 配置：
     - `spring.application.name` 设置为 `cloudoffice-system-service`
     - `spring.cloud.nacos.discovery.server-addr` 配置 Nacos 注册中心地址，支持通过环境变量 `${NACOS_ADDR:127.0.0.1:8848}` 覆盖
     - `spring.cloud.nacos.config.server-addr` 配置 Nacos 配置中心地址，支持环境变量覆盖
     - `spring.cloud.nacos.config.file-extension` 设置为 `yaml`
  2. **application.yml** 配置：
     - `server.port` 设置为 `9400`
     - `spring.datasource.url` 配置 MariaDB 连接地址，支持通过 `DB_URL` 环境变量覆盖
     - `spring.datasource.username` 配置数据库用户名，支持通过 `DB_USER` 环境变量覆盖
     - `spring.datasource.password` 配置数据库密码，支持通过 `DB_PASSWORD` 环境变量覆盖
     - `spring.datasource.driver-class-name` 配置为 `org.mariadb.jdbc.Driver`
     - 排除 `DataSourceAutoConfiguration`（无数据库可启动）
  3. **MyBatis-Plus 配置**：
     - `map-underscore-to-camel-case` 启用驼峰命名映射
     - `log-impl` 配置控制台 SQL 日志输出
     - `logic-delete-field` 设置为 `deleted`
     - `logic-delete-value` 设置为 `1`
     - `logic-not-delete-value` 设置为 `0`
  4. **SpringDoc 配置**：启用 API 文档和 Swagger UI
  5. **日志配置**：`org.cloudstrolling` 包级别至少为 DEBUG
  6. 数据库密码等敏感信息通过环境变量注入，代码仓库中不出现明文敏感信息

### FR-004: 系统服务 Maven 模块配置

- **描述：** 配置 `cloudoffice-system-service` 子模块的 pom.xml，正确继承父 POM 并声明依赖。
- **优先级：** 高 (Must)
- **验收标准：**
  1. pom.xml 正确声明 `<parent>` 指向父 POM（`org.cloudstrolling:cloudoffice`，版本 `0.0.1-SNAPSHOT`）
  2. artifactId 为 `cloudoffice-system-service`
  3. 依赖声明包含：
     - `spring-boot-starter-web`（Spring Boot Web）
     - `mybatis-plus-spring-boot3-starter`（MyBatis-Plus）
     - `mariadb-java-client`（MariaDB 驱动）
     - `spring-cloud-starter-alibaba-nacos-discovery`（Nacos 服务发现）
     - `spring-cloud-starter-alibaba-nacos-config`（Nacos 配置中心）
     - `cloudoffice-common`（公共模块）
     - `lombok`（scope 为 provided）
     - `spring-boot-starter-test`（scope 为 test）
  4. 构建插件包含 `spring-boot-maven-plugin`
  5. 子模块中不出现硬编码的版本号（统一由父 POM 管理）
  6. 使用 `mvn clean compile` 可正常编译且无报错

### FR-005: 系统服务骨架目录结构

- **描述：** 建立标准包目录结构，遵循 project.md 中定义的标准包结构规范，每个目录预留扩展点。
- **优先级：** 中 (Should)
- **验收标准：**
  1. 主源码目录下包含以下标准包结构：
     - `config/` — 配置类目录
     - `controller/` — 控制器层（含 HealthController）
     - `service/` — 业务逻辑层接口
     - `service/impl/` — 业务逻辑实现类
     - `mapper/` — 数据访问层
     - `entity/` — 实体类
     - `dto/` — 数据传输对象
     - `vo/` — 视图对象
     - `enums/` — 枚举类
     - `exception/` — 异常处理类
     - `filter/` — 过滤器
     - `interceptor/` — 拦截器
     - `util/` — 工具类
  2. 以上目录与 auth-service、biz-service 的包目录结构一致
  3. 包名遵循 `org.cloudstrolling.cloudoffice.system.{subpackage}` 规范

### FR-006: 系统服务单元测试

- **描述：** 提供系统服务的基础单元测试，包括应用启动上下文测试和健康检查控制器单元测试。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **SystemApplicationTest**（应用启动测试）：
     - 使用 `@SpringBootTest(classes = SystemApplication.class)` 加载系统服务上下文
     - 测试方法 `contextLoads_shouldLoadSuccessfully_whenApplicationStarts`：验证 Spring 上下文能正常加载
     - 测试方法 `enableDiscoveryClient_shouldBePresent_whenAnnotationCheck`：验证 `@EnableDiscoveryClient` 注解存在于启动类上
     - 配置属性禁用 Nacos 服务发现和配置中心（测试环境不依赖外部中间件）
     - 排除 `DataSourceAutoConfiguration`（测试环境不依赖数据库）
  2. **HealthControllerTest**（健康检查控制器测试）：
     - 使用纯单元测试方式（无需加载完整 Spring 上下文）
     - 通过反射注入 Mock 的 `Environment` 对象
     - 验证：`GET /api/v1/system/health` 返回的 `ApiResult` 状态码为 `200`，`message` 为 `"操作成功"`
     - 验证 data 字段包含 `service`、`status`、`version`、`timestamp` 字段，值正确
     - 验证顶层 `timestamp` 字段存在且为正数
  3. **测试资源文件**：
     - 测试环境 `bootstrap.yml` 配置禁用 Nacos 服务发现和配置中心
  4. 测试类遵循 Given-When-Then 模式
  5. 使用 JUnit 5 + Mockito 测试框架

---

## 4. 非功能需求

### NFR-001: 可用性

- **描述：** 系统服务应能在开发环境下快速启动，不影响数据库也须可正常启动。
- **指标：**
  - 模块启动时间 ≤ 30 秒
  - 无数据库连接时启动成功（仅输出 WARN 日志），不阻塞启动过程
  - Nacos 连接失败时给出明确错误提示信息

### NFR-002: 可维护性

- **描述：** 系统服务代码应遵循项目统一的编码规范和包结构规范，与认证服务和企业服务保持一致的实现水准。
- **指标：**
  - 包结构、命名规范与 auth-service、biz-service 完全一致
  - 构造器注入优先（允许 @Autowired 字段注入的过渡方式）
  - 类注释包含 `@author` 和 `@since`，方法注释包含 `@param`、`@return`
  - 统一使用 `@Slf4j` 记录日志

### NFR-003: 可靠性

- **描述：** 系统服务应具备基础的错误处理和日志记录能力。
- **指标：**
  - 全局异常处理器兜底所有未捕获异常（依赖 common 模块的 GlobalExceptionHandler）
  - 启动日志记录关键配置项加载状态
  - 不泄露敏感信息（数据库密码等）到日志中

### NFR-004: 测试覆盖率

- **描述：** 核心功能代码应具备单元测试覆盖。
- **指标：**
  - 启动类测试覆盖上下文加载和注解检查
  - 健康检查控制器测试覆盖正常响应路径
  - 测试应可在不依赖外部中间件（Nacos、MariaDB）的环境下运行

---

## 5. 技术栈选型

### 5.1 核心框架

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| JDK | OpenJDK | 21 (LTS) | 长期支持版本 |
| Spring Boot | Spring Boot | 3.2.5 | 应用框架基础 |
| Spring Cloud | Spring Cloud | 2023.0.1 | 微服务框架 |
| Spring Cloud Alibaba | Spring Cloud Alibaba | 2023.0.1.0 | 阿里巴巴微服务套件 |
| 构建工具 | Maven | 3.9.x | 项目构建与依赖管理 |

### 5.2 中间件

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| 注册中心 | Nacos | 2.3.x | 服务注册与发现（必选） |
| 配置中心 | Nacos | 2.3.x | 统一配置管理（必选） |
| 数据库 | MariaDB | 10.6 (LTS) | 关系型数据库（本期预留，无 DB 可启动） |

### 5.3 开发框架与组件

| 组件 | 选型 | 版本 | 说明 |
|------|------|------|------|
| ORM 框架 | MyBatis-Plus | 3.5.6 | 增强型 MyBatis 框架 |
| API 文档 | SpringDoc (OpenAPI 3) | 2.5.0 | RESTful API 文档 |
| 连接池 | HikariCP | 5.x | 高性能 JDBC 连接池 |
| 代码简化 | Lombok | 1.18.32 | 减少样板代码 |
| JSON 处理 | Jackson | 2.16.x | JSON 序列化/反序列化 |
| 工具库 | Hutool | 5.8.26 | Java 工具类库（通过 common 模块引入） |

---

## 6. 约束条件

### 6.1 技术约束

1. **JDK 版本：** 必须使用 Java 21 (OpenJDK 21 LTS)，不得使用更低版本
2. **构建工具：** 必须使用 Maven 3.9.x
3. **注册中心：** 必须集成 Nacos 2.3.x
4. **数据库：** MariaDB 10.6 (LTS)，数据库名 `cloudstroll_office_system`
5. **端口：** 系统服务固定为 9400，不可与其他服务端口冲突
6. **模块命名：** `cloudoffice-system-service`
7. **包命名：** `org.cloudstrolling.cloudoffice.system`

### 6.2 规范约束

1. **代码规范：** 严格遵守《阿里巴巴 Java 开发手册》，包结构与 auth-service、biz-service 保持一致
2. **接口规范：** API 路径遵循 `/api/v1/system/{resource}` RESTful 风格
3. **响应格式：** 统一使用 `ApiResult<T>` 响应体
4. **敏感信息：** 数据库密码等敏感配置通过环境变量注入，禁止硬编码

### 6.3 架构约束

1. **无直接代码依赖：** 系统服务与其他业务服务之间无直接代码依赖，仅通过 API 或消息队列通信（本期不涉及）
2. **common 模块依赖：** 系统服务通过 Maven 依赖集成 common 模块的通用组件
3. **数据库排除：** 启动时通过 `DataSourceAutoConfiguration` 排除，无数据库可正常启动

---

## 7. 假设与依赖

### 7.1 外部依赖

1. **Nacos 服务：** 开发环境中需要部署并运行 Nacos 2.3.x 服务（单机模式可满足开发需求）
2. **MariaDB 服务：** 本期为预留状态，无数据库不影响启动，WARN 日志可接受
3. **cloudoffice-common 公共模块：** 依赖 common 模块提供的 `ApiResult`、`BaseEntity` 等公共组件

### 7.2 环境假设

1. 开发人员本地已安装 JDK 21（OpenJDK 21 LTS）
2. 开发人员本地已安装 Maven 3.9.x，并正确配置 `settings.xml`
3. Nacos 服务地址默认为 `127.0.0.1:8848`，可通过环境变量 `NACOS_ADDR` 覆盖
4. 数据库连接参数可通过 `DB_URL`、`DB_USER`、`DB_PASSWORD` 环境变量覆盖

### 7.3 项目假设

1. 本期 v0.1.4 仅完成系统服务基础框架搭建，不实现具体业务功能
2. 系统服务的具体业务功能（系统配置管理、操作日志、监控告警、定时任务等）将在后续版本实现
3. 定时任务框架选型后续决策，本期不做绑定

---

## 8. 优先级汇总 (MoSCoW)

| 优先级 | 需求编号 | 需求名称 |
|--------|----------|----------|
| **Must (必须有)** | FR-001 | 系统服务启动入口 |
| **Must (必须有)** | FR-002 | 系统服务健康检查端点 |
| **Must (必须有)** | FR-003 | 系统服务应用配置 |
| **Must (必须有)** | FR-004 | 系统服务 Maven 模块配置 |
| **Should (应该有)** | FR-005 | 系统服务骨架目录结构 |
| **Should (应该有)** | FR-006 | 系统服务单元测试 |

---

## 9. 模块间依赖关系

```
cloudoffice-common (无业务依赖)
       ▲
       │ 依赖
       │
cloudoffice-system-service (端口 9400)
       │
       ▼
Nacos 注册中心/配置中心 (服务注册&配置管理)
       │
       ▼
MariaDB 数据库 (本期预留，无DB可启动)
```

- **common 模块：** 系统服务的基础依赖，提供统一响应体、异常处理等公共组件
- **Nacos 注册中心：** 系统服务启动时自动注册，供 Gateway 路由发现
- **Nacos 配置中心：** 系统服务通过 bootstrap.yml 配置从 Nacos 拉取配置
- **MariaDB 数据库：** 本期预留，通过 `DataSourceAutoConfiguration` 排除依赖，无 DB 可启动

---

## 10. 验收总体标准

1. 所有 Must 优先级需求（FR-001 ~ FR-004）必须全部完成并通过验收
2. 所有 Should 优先级需求（FR-005、FR-006）应在资源允许的情况下尽量完成
3. 项目通过 `mvn clean compile -pl cloudoffice-system-service -am` 编译无错误
4. 系统服务可在本地开发环境中正常启动，端口 9400
5. `GET http://localhost:9400/api/v1/system/health` 返回 200 及正确响应
6. 系统服务在 Nacos 注册中心中可见
7. 所有单元测试通过（`mvn test -pl cloudoffice-system-service`）
