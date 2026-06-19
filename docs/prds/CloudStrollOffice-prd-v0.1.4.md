# PRD 文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.1.4
**日期：** 2026-06-19

---

## 1. 产品概述

### 1.1 项目背景
云漫智企微服务平台已完成认证服务（auth-service）、企业服务（biz-service）的骨架搭建（v0.1.0），但系统服务（system-service）仅建立了基础包结构，缺少完整的启动入口、健康检查端点、应用配置和单元测试，无法独立启动和注册到 Nacos。v0.1.4 阶段需完成系统服务的独立模块搭建，使其具备与认证服务、企业服务一致的基础能力，为后续承载系统参数配置管理、操作日志、监控告警、定时任务等公共服务奠定基础。

### 1.2 产品目标
- **目标 1：** 完成 cloudoffice-system-service 模块的完整搭建，使其可独立启动并注册到 Nacos 注册中心
- **目标 2：** 提供标准化的健康检查端点（GET /api/v1/system/health），支持服务监控与容器编排平台的就绪/存活探针
- **目标 3：** 建立完整的标准包目录结构和单元测试体系，与 auth-service、biz-service 保持一致的实现水准

### 1.3 核心设计理念
- **渐进式搭建：** 每个服务按"启动入口 → 基础端点 → 骨架目录 → 测试覆盖"逐步完善，不追求一步到位
- **统一规范：** 所有模块遵循相同的包结构、编码规范和测试标准，确保项目整体一致性和可维护性
- **可观测优先：** 每个服务从搭建之初就提供健康检查和标准日志，为后续监控告警奠定基础
- **无数据库可启动：** 系统服务排除 DataSourceAutoConfiguration，无数据库连接时仅输出 WARN 日志，不阻塞启动过程

---

## 2. 用户故事（User Stories）

### US-001: 系统服务启动与注册

**优先级：** 高
**关联需求：**
需求文档：docs/requires/CloudStrollOffice-requirement-v0.1.4.md
需求编号：FR-001（系统服务启动入口）、FR-004（系统服务 Maven 模块配置）

#### 故事描述
- **作为** 系统运维人员
- **我想要** 系统服务启动后自动注册到 Nacos 注册中心
- **以便** 网关和其他服务能够通过服务发现找到系统服务

#### 验收标准
- [ ] **AC1：** Given Nacos 注册中心已启动，When 执行 `mvn clean compile -pl cloudoffice-system-service -am` 编译并通过，Then 编译无报错
- [ ] **AC2：** Given Nacos 注册中心已启动，When 启动 SystemApplication，Then 服务成功注册到 Nacos，服务名为 `cloudoffice-system-service`
- [ ] **AC3：** Given 服务已启动，When 调用 GET /actuator/health，Then 返回 HTTP 200 状态码
- [ ] **AC4：** Given 启动类位于 `org.cloudstrolling.cloudoffice.system` 包，When 检查类声明，Then 标注 `@SpringBootApplication` 和 `@EnableDiscoveryClient` 注解，包含标准 main 方法
- [ ] **AC5：** Given 检查 pom.xml，When 验证父 POM 和依赖声明，Then artifactId 为 `cloudoffice-system-service`，版本由父 POM 统一管理，无硬编码版本号

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| Nacos 连接失败 | 服务启动失败，输出明确错误日志，提示检查 Nacos 地址和运行状态 |
| 端口 9400 被占用 | 端口绑定异常，服务启动失败，日志提示端口冲突 |
| Maven 依赖解析失败 | 编译报错，提示检查父 POM 依赖配置和本地 Maven 仓库 |

---

### US-002: 健康检查接口

**优先级：** 高
**关联需求：**
需求文档：docs/requires/CloudStrollOffice-requirement-v0.1.4.md
需求编号：FR-002（系统服务健康检查端点）

#### 故事描述
- **作为** 系统运维人员
- **我想要** 通过 GET /api/v1/system/health 获取服务健康状态
- **以便** 快速确认系统服务是否正常运行，并作为容器编排平台的就绪探针和存活探针

#### 验收标准
- [ ] **AC1：** Given 系统服务已启动，When 发送 GET /api/v1/system/health，Then 返回 HTTP 200，响应体为 ApiResult 格式
- [ ] **AC2：** Given 响应成功，When 检查响应体 data 字段，Then `data.service` 为 `"cloudoffice-system-service"`（或通过 `spring.application.name` 获取），`data.status` 为 `"UP"`
- [ ] **AC3：** Given 响应成功，When 检查响应体，Then `data.version` 存在且非空，`data.timestamp` 存在且为正数
- [ ] **AC4：** Given 响应成功，When 检查顶层字段，Then `code` 为 200，`message` 为 `"操作成功"`，`timestamp` 存在且为正数
- [ ] **AC5：** Given 服务运行中，When 通过浏览器访问 `http://localhost:9400/api/v1/system/health`，Then 返回正确的 JSON 响应

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 请求路径错误（如 /api/v1/system/health/） | 返回 404 |
| 请求方法错误（如 POST /api/v1/system/health） | 返回 405 |
| 服务未就绪时请求 | 返回 503 或连接拒绝 |

---

### US-003: 系统服务应用配置

**优先级：** 高
**关联需求：**
需求文档：docs/requires/CloudStrollOffice-requirement-v0.1.4.md
需求编号：FR-003（系统服务应用配置）

#### 故事描述
- **作为** 开发人员
- **我想要** 系统服务具备完整的 Nacos 注册发现、数据源和 MyBatis-Plus 等配置
- **以便** 系统服务能够正常运行并与基础设施集成

#### 验收标准
- [ ] **AC1：** Given bootstrap.yml 配置完成，When 服务启动，Then `spring.application.name` 为 `cloudoffice-system-service`，成功连接 Nacos 注册中心和配置中心
- [ ] **AC2：** Given application.yml 配置完成，When 服务启动，Then 监听端口 9400
- [ ] **AC3：** Given 数据源配置通过环境变量注入，When 服务启动且未设置环境变量，Then 使用默认值 `127.0.0.1:3306` 连接数据库，输出 WARN 日志但服务正常启动
- [ ] **AC4：** Given MyBatis-Plus 配置完成，When 检查配置，Then 启用驼峰命名映射、控制台 SQL 日志输出、逻辑删除（deleted 字段，1-已删除，0-正常）
- [ ] **AC5：** Given SpringDoc 配置完成，When 访问 /swagger-ui.html 或 /v3/api-docs，Then 返回 API 文档页面或 OpenAPI 3 JSON
- [ ] **AC6：** Given 日志级别配置完成，When 查看启动日志，Then `org.cloudstrolling` 包级别为 DEBUG，关键配置项加载状态被记录

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 数据库连接失败（无 MariaDB） | 服务正常启动，仅输出 WARN 级别日志，不阻塞启动 |
| Nacos 配置中心不可用 | 使用本地配置（bootstrap.yml / application.yml）作为兜底 |
| 环境变量未设置 | 使用 bootstrap.yml 中配置的默认值（如 `NACOS_ADDR:127.0.0.1:8848`） |
| 数据库密码错误 | 数据源初始化失败，输出 ERROR 日志，但不影响服务 HTTP 端口监听 |

---

### US-004: 系统服务骨架结构

**优先级：** 中
**关联需求：**
需求文档：docs/requires/CloudStrollOffice-requirement-v0.1.4.md
需求编号：FR-005（系统服务骨架目录结构）

#### 故事描述
- **作为** 开发人员
- **我想要** 系统服务拥有标准化的包目录结构
- **以便** 后续业务功能开发时遵循统一的项目组织规范

#### 验收标准
- [ ] **AC1：** Given 查看项目源码，When 检查主源码目录 `src/main/java/org/cloudstrolling/cloudoffice/system/`，Then 存在以下目录：`config/`、`controller/`、`service/`、`service/impl/`、`mapper/`、`entity/`、`dto/`、`vo/`、`enums/`、`exception/`、`filter/`、`interceptor/`、`util/`
- [ ] **AC2：** Given 目录结构已建立，When 与 auth-service 和 biz-service 对比，Then 目录结构完全一致
- [ ] **AC3：** Given 包名检查，When 验证各目录的 Java 包声明，Then 包名遵循 `org.cloudstrolling.cloudoffice.system.{subpackage}` 规范
- [ ] **AC4：** Given 资源文件检查，When 查看 `src/main/resources/`，Then 存在 `bootstrap.yml` 和 `application.yml`

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 新增子包未遵循命名规范 | 代码审查时指出，要求修正 |
| 目录结构与 auth-service/biz-service 不一致 | 需调整至一致，确保项目统一性 |

---

### US-005: 系统服务单元测试

**优先级：** 中
**关联需求：**
需求文档：docs/requires/CloudStrollOffice-requirement-v0.1.4.md
需求编号：FR-006（系统服务单元测试）

#### 故事描述
- **作为** 开发人员
- **我想要** 系统服务具备基本的单元测试
- **以便** 验证服务启动和核心接口的正确性，确保代码质量

#### 验收标准
- [ ] **AC1：** Given 运行 SystemApplicationTest，When 执行 `contextLoads_shouldLoadSuccessfully_whenApplicationStarts` 测试方法，Then 断言 Spring 应用上下文加载成功（不依赖 Nacos 和数据库）
- [ ] **AC2：** Given 运行 SystemApplicationTest，When 执行 `enableDiscoveryClient_shouldBePresent_whenAnnotationCheck` 测试方法，Then 断言启动类上存在 `@EnableDiscoveryClient` 注解
- [ ] **AC3：** Given 运行 HealthControllerTest，When 发送 GET /api/v1/system/health，Then 断言响应状态码 200、message 为 `"操作成功"`
- [ ] **AC4：** Given 运行 HealthControllerTest，When 验证响应体 data 字段，Then `data.service` 为 `"cloudoffice-system-service"`，`data.status` 为 `"UP"`，`data.version` 非空，`data.timestamp` 为正数
- [ ] **AC5：** Given 测试环境配置，When 检查测试资源文件，Then `src/test/resources/bootstrap.yml` 中 Nacos 服务发现和配置中心被禁用
- [ ] **AC6：** Given 执行全部测试，When 运行 `mvn test -pl cloudoffice-system-service`，Then 所有测试通过，无失败用例

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 测试环境无 Nacos 服务 | 测试通过（bootstrap.yml 已禁用 Nacos） |
| 测试环境无 MariaDB 数据库 | 测试通过（排除 DataSourceAutoConfiguration） |
| 测试类命名不规范 | 代码审查时指出，要求遵循 `{methodName}_{scenario}_{expectedResult}` 命名模式 |
| 测试用例未覆盖 Given-When-Then 模式 | 代码审查时指出，要求补充结构化注释 |

---

## 3. 非功能性需求

### 3.1 性能
- 系统服务启动时间 ≤ 30 秒（首次启动含依赖解析）
- 健康检查接口响应时间 < 100ms
- 使用 `mvn clean compile -pl cloudoffice-system-service -am` 编译时间 ≤ 30 秒

### 3.2 可用性
- 服务注册失败时输出明确错误日志，指导开发者检查 Nacos 连接地址和运行状态
- 数据库连接失败时不阻止服务启动（WARN 级别日志），方便开发环境调试
- Nacos 配置中心不可用时，使用本地配置文件作为兜底

### 3.3 可靠性
- 全局异常处理器（继承 common 模块的 GlobalExceptionHandler）兜底所有未捕获异常
- 启动日志记录关键配置项加载状态（端口、数据源、Nacos 地址等）
- 不泄露敏感信息（数据库密码等）到日志中

### 3.4 安全性
- 数据库密码等敏感配置通过环境变量（DB_PASSWORD）注入，禁止硬编码
- Nacos 地址、数据库 URL 等支持环境变量覆盖默认值
- 代码仓库中不出现明文敏感信息

### 3.5 可维护性
- 包结构、命名规范与 auth-service、biz-service 完全一致
- 统一使用 Lombok `@Slf4j` 注解记录日志
- 构造器注入优先（允许 @Autowired 字段注入的过渡方式）
- 类注释包含 `@author` 和 `@since`，方法注释包含 `@param`、`@return`
- 使用 SpringDoc 注解（`@Schema`、`@Operation`）生成 API 文档

### 3.6 测试
- 启动类测试覆盖上下文加载和 `@EnableDiscoveryClient` 注解检查
- 健康检查控制器测试覆盖 200 状态码和所有响应体字段
- 测试可在不依赖外部中间件（Nacos、MariaDB）的环境下独立运行
- 使用 JUnit 5 + Mockito 测试框架，遵循 Given-When-Then 模式

---

## 4. 附录

### 4.1 系统服务模块规格

| 属性 | 值 |
|------|-----|
| 模块名称 | cloudoffice-system-service |
| 包名 | org.cloudstrolling.cloudoffice.system |
| 端口 | 9400 |
| 服务注册名 | cloudoffice-system-service |
| 数据库名 | cloudstroll_office_system |
| 健康检查端点 | GET /api/v1/system/health |
| Maven 父 POM | org.cloudstrolling:cloudoffice:0.0.1-SNAPSHOT |

### 4.2 依赖清单

| 依赖 | 说明 |
|------|------|
| spring-boot-starter-web | Spring Boot Web 启动器 |
| mybatis-plus-spring-boot3-starter | MyBatis-Plus 持久层框架 |
| mariadb-java-client | MariaDB JDBC 驱动 |
| spring-cloud-starter-alibaba-nacos-discovery | Nacos 服务注册与发现 |
| spring-cloud-starter-alibaba-nacos-config | Nacos 配置中心 |
| cloudoffice-common | 公共模块（统一响应体、异常处理、基础实体等） |
| lombok | 代码简化（scope: provided） |
| spring-boot-starter-test | 测试框架（scope: test） |

### 4.3 接口规范

```
GET /api/v1/system/health
响应 200:
{
    "code": 200,
    "message": "操作成功",
    "data": {
        "service": "cloudoffice-system-service",
        "status": "UP",
        "version": "0.0.1-SNAPSHOT",
        "timestamp": 1718000000000
    },
    "timestamp": 1718000000000
}
```

### 4.4 参考文档

| 文档 | 路径 |
|------|------|
| 需求文档 | docs/requires/CloudStrollOffice-requirement-v0.1.4.md |
| 架构文档 | docs/architecture.md |
| 项目信息 | docs/project.md |
