# 项目基本信息

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**编程语言：** Java 21 (OpenJDK 21 LTS)
**项目类型：** 微服务应用程序（Spring Boot + Spring Cloud）
**当前进度：** impm-task（登录认证与权限管理 v0.1.5）
**本地化语言：** 简体中文
**项目总体介绍：** 云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务互联网应用程序。采用 Maven 多模块架构，由认证服务（auth-service）、企业服务（biz-service）、系统服务（system-service）、API 网关（gateway）及公共模块（common）组成，为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。数据库采用 MariaDB 10.6 (LTS)，缓存使用 Redis 7.2.x，消息队列使用 RocketMQ 5.1.x，注册中心和配置中心使用 Nacos 2.3.x。

---

# 数据库信息

**是否需要使用数据库：** 需要
**数据库类型：** MariaDB 10.6 (LTS)
**ORM 框架：** MyBatis-Plus 3.5.x
**连接池：** HikariCP 5.x

## 数据库设计原则

- **数据库独立：** 每个微服务拥有独立数据库（或 Schema），服务间禁止跨服务直接访问数据库，必须通过 API 调用或消息队列进行数据交换
- **主键策略：** 统一使用雪花算法生成主键 ID（MyBatis-Plus ID_WORKER）
- **公共字段：** 每张表统一添加 `create_time`（创建时间）、`update_time`（更新时间）、`deleted`（逻辑删除，0-正常，1-删除）字段

## 命名规则

| 类别 | 规则 | 示例 |
|------|------|------|
| 数据库 | 每个微服务独立数据库 | `cloudstroll_office_auth`、`cloudstroll_office_biz` |
| 表名 | `t_{module}_{table_name}` | `t_auth_user`、`t_biz_employee` |
| 字段名 | 下划线命名法 | `user_name`、`create_time`、`login_ip` |
| 主键 | 雪花算法，字段名 `id` | `id` BIGINT(20) |
| 普通索引 | `idx_{table}_{column}` | `idx_user_user_name` |
| 唯一索引 | `uk_{table}_{column}` | `uk_user_login_name` |

---

# 编码规范

## 文件组织规范

每个微服务模块遵循以下标准包结构：

```
org.cloudstrolling.cloudoffice.{module}
├── config/          # 配置类（Spring 配置、Swagger 配置等）
├── controller/      # 控制器层（RESTful API 入口）
├── service/         # 业务逻辑层接口
│   └── impl/        # 业务逻辑实现类
├── mapper/          # 数据访问层（MyBatis-Plus Mapper）
├── entity/          # 实体类（数据库表映射）
├── dto/             # 数据传输对象（请求/响应 DTO）
├── vo/              # 视图对象（页面展示 VO）
├── enums/           # 枚举类
├── exception/       # 异常处理类（模块级异常）
├── filter/          # 过滤器
├── interceptor/     # 拦截器
└── util/            # 工具类（模块级工具）
```

- 公共模块（`cloudoffice-common`）放置通用工具类、通用异常、统一响应体、基础实体等，不依赖任何业务模块
- API 网关模块（`cloudoffice-gateway`）不依赖具体业务服务，仅通过服务发现进行路由转发

## 命名规范

| 类别 | 规则 | 示例 |
|------|------|------|
| 包名 | 全小写，`org.cloudstrolling.cloudoffice.{module}` | `org.cloudstrolling.cloudoffice.auth` |
| 模块名 | 中划线连接，`cloudoffice-{module}` | `cloudoffice-auth-service` |
| 类名 | PascalCase（大驼峰） | `UserController`、`AuthService` |
| 方法名 | camelCase（小驼峰） | `getUserById`、`createUser` |
| 变量名 | camelCase（小驼峰） | `userName`、`loginTime` |
| 常量 | UPPER_SNAKE_CASE（全大写 + 下划线） | `MAX_RETRY_COUNT`、`TOKEN_EXPIRE_SECONDS` |
| 配置文件 | 小写中划线 | `bootstrap.yml`、`application.yml` |
| API 路径 | `/api/v1/{module}/{resource}` | `/api/v1/auth/login`、`/api/v1/biz/employee` |

## 代码风格

- 遵循《阿里巴巴 Java 开发手册》（安装 Alibaba Java Coding Guidelines 插件进行自动检查）
- 使用 Lombok 减少样板代码（`@Data`、`@Slf4j`、`@Builder`、`@NoArgsConstructor`、`@AllArgsConstructor`）
- 统一使用构造器注入替代 `@Autowired` 字段注入（Spring 推荐方式）
- 缩进使用 4 个空格，禁止使用 Tab
- 文件编码统一 UTF-8
- 行宽不超过 120 字符
- 大括号风格采用 K&R 风格（左大括号不换行）
- 接口定义使用 SpringDoc 注解（`@Schema`、`@Operation`）

## 注释规范

- **类注释：** 包含作者（`@author`）、日期（`@since`）、类功能描述
- **方法注释：** 包含参数说明（`@param`）、返回值说明（`@return`）、异常说明（`@throws`）
- **业务注释：** 重要业务逻辑处必须添加行内注释，说明业务意图而非代码做了什么
- **API 注释：** 接口定义使用 SpringDoc 注解（`@Schema`、`@Operation`、`@Parameter`）生成 OpenAPI 3 文档
- 禁止出现无意义注释（如 `// 设置名称` 这种重复代码的注释）
- 修改代码时同步更新相关注释

## 日志规范

- 统一使用 Lombok `@Slf4j` 注解生成日志对象
- 日志级别使用规范：

| 级别 | 使用场景 |
|------|----------|
| `trace` | 调试跟踪，仅在开发环境开启 |
| `debug` | 开发调试，详细运行信息 |
| `info` | 重要业务节点（如操作成功、状态变更等） |
| `warn` | 潜在问题或非预期但可处理的场景 |
| `error` | 异常错误，需人工介入的场景 |

- 禁止在循环中打印日志
- 敏感信息（密码、手机号、身份证号等）需脱敏处理后再打印
- 日志输出包含关键业务标识（如用户 ID、订单号），便于问题追踪
- 异常日志必须打印完整堆栈信息

## 测试规范

- **覆盖率要求：** 单元测试覆盖率不低于 80%
- **测试框架：** Spring Boot Test + JUnit 5 + Mockito
- **测试类注解：** `@SpringBootTest` + `@AutoConfigureMockMvc`
- **测试模式：** 遵循 Given-When-Then 模式组织测试用例
- **命名规范：** `{methodName}_{scenario}_{expectedResult}`（如 `getUserById_userExists_returnUser`）
- 每个 Service 层方法必须有对应的单元测试
- Controller 层使用 MockMvc 进行接口测试
- 测试数据使用 H2 内存数据库或测试容器（Testcontainers）

## 统一错误处理规范

- **通用响应体：** `ApiResult<T>` / `R<T>`，包含 `code`（状态码）、`message`（提示信息）、`data`（数据）、`timestamp`（时间戳）
- **业务异常：** 继承 `BaseException` 或 `BusinessException`，包含错误码和错误信息
- **全局异常处理：** 使用 `@RestControllerAdvice` + `@ExceptionHandler` 统一拦截处理异常
- **错误码分段：** 按模块分段管理

| 错误码段 | 模块 | 示例 |
|----------|------|------|
| AUTH-0001 ~ AUTH-9999 | 认证服务 | `AUTH-0001` 用户名或密码错误 |
| BIZ-0001 ~ BIZ-9999 | 企业服务 | `BIZ-0001` 企业信息不存在 |
| SYS-0001 ~ SYS-9999 | 系统服务 | `SYS-0001` 配置不存在 |
| COMMON-0001 ~ COMMON-9999 | 公共模块 | `COMMON-0001` 参数校验失败 |

## 其他规范

- **API 路径规范：** `/api/v1/{module}/{resource}`，使用 RESTful 风格
- **主键生成：** 统一使用雪花算法（MyBatis-Plus ID_WORKER）生成分布式 ID
- **跨服务通信：** 同步调用使用 OpenFeign + 负载均衡，异步使用 RocketMQ 消息队列
- **分布式事务：** 使用 Seata AT 模式保证最终一致性
- **密码加密：** 使用 BCrypt 加密算法存储
- **JWT 令牌：** 无状态令牌，支持刷新机制
- **API 文档：** SpringDoc (OpenAPI 3) 自动生成 API 文档
- **依赖管理：** 所有第三方依赖版本在父 POM 中通过 `<dependencyManagement>` 统一管理，子模块不出现硬编码版本号
- **Git 提交规范：** 遵循 Conventional Commits 规范（`feat:`、`fix:`、`docs:`、`refactor:`等）
- **敏感数据：** 配置中的密码、密钥等敏感信息不得硬编码，通过环境变量或配置中心管理
- **SQL 注入防护：** 使用 MyBatis-Plus 预编译机制，禁止拼接 SQL

---

# 项目地图

## 项目根目录

| 文件/目录 | 描述 |
|-----------|------|
| `.gitignore` | Git 忽略规则配置，涵盖 OS/IDE/Java/Maven/Flutter/Docker 等 |
| `opencode.json` | OpenCode AI 开发工具配置文件，启用 impm 插件 |
| `docs/` | 项目文档目录 |

## docs/ 文档目录

```
docs/
├── origin-requires/               # 原始需求文档（原始输入）
│   └── origin-requires0.1.0.md    # 原始架构需求文档 v0.1.0（技术栈选型、架构设计、服务划分等）
├── requires/                      # 需求文档（梳理后）
│   └── CloudStrollOffice-requirement-v0.1.0.md  # 项目需求文档 v0.1.0（User Story 格式，含 FR/NFR/约束条件）
├── prds/                          # PRD 文档
├── sds/                           # 技术规格说明书
│   └── CloudStrollOffice-sds-v0.1.5.md  # 登录认证与权限管理技术规格说明书 v0.1.5
├── tasks/                         # 任务清单
├── prompts/                       # AI 交互历史记录
│   ├── prompt-20260618-090703.md
│   ├── prompt-20260618-094140.md
│   ├── prompt-20260618-094508.md
│   └── prompt-20260618-123000.md
├── tests/                         # 测试用例文档
│   ├── test-cases-common-v0.1.0.md
│   └── test-cases-services-v0.1.0.md
├── deployment-guide.md            # 编译部署文档
└── project.md                     # 本项目文件（项目信息、编码规范、项目地图）
```

## 已创建模块（v0.1.0 / v0.1.4）

以下模块为已创建的 Maven 子模块：

| 模块目录 | 包名 | 端口 | 功能描述 | 创建阶段 |
|----------|------|------|----------|---------|
| `cloudoffice-common/` | `org.cloudstrolling.cloudoffice.common` | - | 公共模块 — 通用工具类、BaseEntity、统一响应体、异常定义、SpringDoc 配置 | v0.1.0 |
| `cloudoffice-gateway/` | `org.cloudstrolling.cloudoffice.gateway` | 9000 | API 网关 — 路由转发、CORS 配置、Nacos 服务发现集成 | v0.1.0 |
| `cloudoffice-auth-service/` | `org.cloudstrolling.cloudoffice.auth` | 9100 | 认证服务 — Spring Security + OAuth2 骨架、JWT 工具类 | v0.1.0 |
| `cloudoffice-biz-service/` | `org.cloudstrolling.cloudoffice.biz` | 9200 | 企业服务 — 企业信息、人事管理业务骨架 | v0.1.0 |
| `cloudoffice-system-service/` | `org.cloudstrolling.cloudoffice.system` | 9400 | 系统服务 — 系统配置、日志、监控、定时任务骨架，含健康检查端点和单元测试 | v0.1.4 |
| `scripts/docker/` | - | - | Dockerfile 模板 | v0.1.0 |
| `scripts/sql/` | - | - | 数据库初始化脚本模板 | v0.1.0 |
| `.idea/` | - | - | IntelliJ IDEA 统一配置文件（代码风格、运行配置等） | v0.1.0 |

## cloudoffice-common/ 公共模块

### 源码结构

```
cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/
├── config/                         # 配置类（Spring 配置等）
│   ├── MyBatisPlusConfig.java      # MyBatis-Plus 配置：自动填充处理器（createTime/updateTime/deleted）
│   └── SpringDocConfig.java        # SpringDoc OpenAPI 配置，API 文档分组与基本信息
├── exception/                      # 异常定义
│   ├── ErrorCode.java              # 通用错误码枚举：10个HTTP基础错误码 + 19个认证授权错误码（AUTH-0001~AUTH-0019）（实现 model.ErrorCode 接口）
│   ├── BaseException.java          # 异常基类（继承 RuntimeException，含 code/message）
│   ├── BusinessException.java      # 业务异常（带模块标识 module）
│   ├── AuthException.java          # 认证异常（401）
│   └── GlobalExceptionHandler.java # 全局异常处理器（@RestControllerAdvice，覆盖 10+ 异常类型）
├── model/                          # 公共模型
│   ├── ApiResult.java              # 统一响应体（含成功/错误静态工厂方法，链式调用）
│   ├── BaseEntity.java             # 实体基类（雪花算法ID、创建时间、更新时间、逻辑删除）
│   ├── ErrorCode.java              # 错误码接口（定义 getCode/getMessage 契约）
│   └── PageResult.java             # 分页结果封装（含 empty/of 静态工厂方法）
└── util/                           # 工具类
    ├── .gitkeep                    # 占位文件
    └── JsonUtils.java              # JSON 工具类（基于 Jackson ObjectMapper 单例，支持 JavaTimeModule）
```

**测试代码：**
```
cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/
├── config/
│   └── MyBatisPlusConfigTest.java          # MyBatis-Plus 自动填充配置测试
├── exception/
│   ├── BaseExceptionTest.java              # 异常基类测试
│   ├── BusinessExceptionTest.java          # 业务异常测试
│   ├── ErrorCodeTest.java                  # 通用错误码枚举测试（10个HTTP基础错误码 + 19个认证授权错误码，共29个枚举常量的非空校验和预期值验证）
│   └── GlobalExceptionHandlerTest.java     # 全局异常处理器测试
├── model/
│   ├── ApiResultTest.java                  # 统一响应体测试
│   ├── BaseEntityTest.java                 # 实体基类测试
│   └── PageResultTest.java                 # 分页结果封装测试
└── util/
    └── JsonUtilsTest.java                  # JSON 工具类测试
```

### 关键类说明

| 类名 | 包路径 | 功能描述 |
|------|--------|----------|
| `MyBatisPlusConfig` | `org.cloudstrolling.cloudoffice.common.config` | MyBatis-Plus 自动填充处理器：插入时填充 createTime/updateTime/deleted，更新时填充 updateTime |
| `SpringDocConfig` | `org.cloudstrolling.cloudoffice.common.config` | SpringDoc OpenAPI 3 文档配置：包含认证/业务/云资源/系统管理 4 个 API 分组 |
| `ErrorCode` | `org.cloudstrolling.cloudoffice.common.exception` | 通用错误码枚举：包含10个HTTP基础错误码（SUCCESS/BAD_REQUEST/UNAUTHORIZED/FORBIDDEN/NOT_FOUND等）和19个认证授权错误码（TOKEN_EXPIRED/ACCOUNT_DISABLED/LOGIN_FAILED等AUTH-0001~AUTH-0019），共29个枚举常量 |
| `BaseException` | `org.cloudstrolling.cloudoffice.common.exception` | 运行时异常基类（抽象类）：含 code 和 message 属性 |
| `BusinessException` | `org.cloudstrolling.cloudoffice.common.exception` | 业务异常：继承 BaseException，增加 module 模块标识，构造时自动记录错误日志 |
| `AuthException` | `org.cloudstrolling.cloudoffice.common.exception` | 认证异常：继承 BaseException，映射 HTTP 401 状态码 |
| `GlobalExceptionHandler` | `org.cloudstrolling.cloudoffice.common.exception` | 全局异常处理器：@RestControllerAdvice，覆盖参数校验/业务异常/认证异常/权限不足/404/500 等 12+ 种异常场景 |
| `ApiResult` | `org.cloudstrolling.cloudoffice.common.model` | 统一 API 响应体：链式调用 @Accessors(chain=true)，含 success/error 静态工厂方法，自动填充时间戳 |
| `BaseEntity` | `org.cloudstrolling.cloudoffice.common.model` | MyBatis-Plus 实体基类（抽象类）：雪花算法 ID、createTime/updateTime 自动填充、deleted 逻辑删除 |
| `ErrorCode` | `org.cloudstrolling.cloudoffice.common.model` | 错误码契约接口：定义 getCode()/getMessage() 方法 |
| `PageResult` | `org.cloudstrolling.cloudoffice.common.model` | 分页查询结果封装：records/total/page/pageSize，含 empty() 和 of() 静态工厂方法 |
| `JsonUtils` | `org.cloudstrolling.cloudoffice.common.util` | Jackson JSON 序列化工具类：@UtilityClass，注册 JavaTimeModule 支持日期时间类型 |

## cloudoffice-auth-service/ 认证服务模块

### 源码结构

```
cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/
├── AuthApplication.java            # 认证服务启动入口（@SpringBootApplication + @EnableDiscoveryClient）
├── config/                         # 配置类
│   ├── SecurityConfig.java         # Spring Security 安全配置（BCrypt 编码器、无状态会话、CSRF 关闭、自定义 401/403 JSON 响应）
│   └── OAuth2Config.java           # OAuth2 授权服务器骨架配置（预留扩展点，v0.2.0 实现完整授权码流程）
├── controller/                     # 控制器层
│   └── HealthController.java       # 健康检查控制器（GET /api/v1/auth/health 返回服务状态）
├── dto/                            # 数据传输对象（预留，仅 .gitkeep）
├── entity/                         # 实体类（预留，仅 .gitkeep）
├── enums/                          # 枚举类（预留，仅 .gitkeep）
├── exception/                      # 异常处理类（预留，仅 .gitkeep）
├── filter/                         # 过滤器（预留，仅 .gitkeep）
├── interceptor/                    # 拦截器（预留，仅 .gitkeep）
├── mapper/                         # 数据访问层（预留，仅 .gitkeep）
├── service/                        # 业务逻辑层接口（预留，仅 .gitkeep）
│   └── impl/                       # 业务逻辑实现类（预留，仅 .gitkeep）
├── util/                           # 工具类
│   └── JwtUtils.java               # JWT 令牌工具类（签发、验证、解析，支持 HS256 算法）
└── vo/                             # 视图对象（预留，仅 .gitkeep）
```

**测试代码：**
```
cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/
├── AuthApplicationTest.java                # 应用启动测试：验证 Spring 上下文加载、@EnableDiscoveryClient 注解
├── config/
│   └── SecurityConfigTest.java             # 安全配置测试：BCrypt 编码器、匿名访问路径、401/403 响应
├── controller/
│   └── HealthControllerTest.java           # 健康检查控制器测试：MockMvc 单元测试，验证 200 状态码和响应体
└── util/
    └── JwtUtilsTest.java                   # JWT 工具类测试：令牌生成、解析、验证、过期校验

cloudoffice-auth-service/src/test/resources/
└── bootstrap.yml                           # 测试环境 Nacos 禁用配置
```

### 关键类说明

| 类名 | 包路径 | 功能描述 |
|------|--------|----------|
| `AuthApplication` | `org.cloudstrolling.cloudoffice.auth` | 认证服务启动入口，@SpringBootApplication + @EnableDiscoveryClient 集成 Nacos 服务发现 |
| `SecurityConfig` | `org.cloudstrolling.cloudoffice.auth.config` | Spring Security 安全配置：BCryptPasswordEncoder 密码编码器、无状态会话管理、CSRF 关闭、健康检查/Swagger 端点匿名访问、自定义 401/403 JSON 响应 |
| `OAuth2Config` | `org.cloudstrolling.cloudoffice.auth.config` | OAuth2 授权服务器骨架配置类，预留下期扩展点 |
| `HealthController` | `org.cloudstrolling.cloudoffice.auth.controller` | 健康检查控制器：GET /api/v1/auth/health，返回服务名称/状态/版本/时间戳 |
| `JwtUtils` | `org.cloudstrolling.cloudoffice.auth.util` | JWT 令牌工具类：构造器注入配置属性（secret/expiration/algorithm），@PostConstruct 校验密钥长度并初始化 HMAC 密钥，提供 generateToken/parseToken/validateToken/getUserIdFromToken/getUserNameFromToken 方法 |

---

## cloudoffice-gateway/ API 网关模块

### 源码结构

```
cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/
├── GatewayApplication.java         # 网关启动入口（@SpringBootApplication + @EnableDiscoveryClient）
└── config/                         # 配置类目录（预留，待实现鉴权过滤器等）
```

**资源文件：**
```
cloudoffice-gateway/src/main/resources/
├── bootstrap.yml                   # Nacos 注册/配置中心配置（server-addr 环境变量注入）
└── application.yml                 # 应用配置（端口 9000、路由规则、CORS 配置）
```

**测试代码：**
```
cloudoffice-gateway/src/test/java/org/cloudstrolling/cloudoffice/gateway/
└── GatewayApplicationTest.java             # 应用启动测试：验证 Spring 上下文加载、@EnableDiscoveryClient 注解

cloudoffice-gateway/src/test/resources/
└── bootstrap.yml                           # 测试环境 Nacos 禁用配置
```

### 关键类说明

| 类名 | 包路径 | 功能描述 |
|------|--------|----------|
| `GatewayApplication` | `org.cloudstrolling.cloudoffice.gateway` | API 网关启动入口，@SpringBootApplication + @EnableDiscoveryClient 集成 Nacos 服务发现，统一流量入口（端口 9000） |
| `GatewayApplicationTest` | `org.cloudstrolling.cloudoffice.gateway` | 应用启动测试：验证 Spring 上下文正常加载、@EnableDiscoveryClient 注解存在 |

---

## cloudoffice-biz-service/ 企业服务模块

### 源码结构

```
cloudoffice-biz-service/src/main/java/org/cloudstrolling/cloudoffice/biz/
├── BizApplication.java             # 企业服务启动入口（@SpringBootApplication + @EnableDiscoveryClient）
├── config/                         # 配置类（预留，仅 .gitkeep）
├── controller/                     # 控制器层
│   └── HealthController.java       # 健康检查控制器（GET /api/v1/biz/health 返回服务状态）
├── dto/                            # 数据传输对象（预留，仅 .gitkeep）
├── entity/                         # 实体类（预留，仅 .gitkeep）
├── enums/                          # 枚举类（预留，仅 .gitkeep）
├── exception/                      # 异常处理类（预留，仅 .gitkeep）
├── filter/                         # 过滤器（预留，仅 .gitkeep）
├── interceptor/                    # 拦截器（预留，仅 .gitkeep）
├── mapper/                         # 数据访问层（预留，仅 .gitkeep）
├── service/                        # 业务逻辑层接口（预留，仅 .gitkeep）
│   └── impl/                       # 业务逻辑实现类（预留，仅 .gitkeep）
├── util/                           # 工具类（预留，仅 .gitkeep）
└── vo/                             # 视图对象（预留，仅 .gitkeep）
```

**资源文件：**
```
cloudoffice-biz-service/src/main/resources/
├── bootstrap.yml                   # Nacos 注册/配置中心配置（server-addr 环境变量注入）
└── application.yml                 # 应用配置（端口 9200、MariaDB 数据源、MyBatis-Plus、SpringDoc、日志级别）
```

**测试代码：**
```
cloudoffice-biz-service/src/test/java/org/cloudstrolling/cloudoffice/biz/
├── BizApplicationTest.java                 # 应用启动测试：验证 Spring 上下文加载、@EnableDiscoveryClient 注解
└── controller/
    └── HealthControllerTest.java           # 健康检查控制器测试：MockMvc 单元测试，验证 200 状态码和响应体

cloudoffice-biz-service/src/test/resources/
└── bootstrap.yml                           # 测试环境 Nacos 禁用配置
```

### 关键类说明

| 类名 | 包路径 | 功能描述 |
|------|--------|----------|
| `BizApplication` | `org.cloudstrolling.cloudoffice.biz` | 企业服务启动入口，@SpringBootApplication + @EnableDiscoveryClient 集成 Nacos 服务发现 |
| `HealthController` | `org.cloudstrolling.cloudoffice.biz.controller` | 健康检查控制器：GET /api/v1/biz/health，返回服务名称/状态/版本/时间戳 |
| `BizApplicationTest` | `org.cloudstrolling.cloudoffice.biz` | 应用启动测试：验证 Spring 上下文正常加载、@EnableDiscoveryClient 注解存在 |
| `HealthControllerTest` | `org.cloudstrolling.cloudoffice.biz.controller` | 健康检查控制器单元测试：MockMvc 测试，验证 HTTP 200 状态码和响应体 |

---

## cloudoffice-system-service/ 系统服务模块（v0.1.4）

### 源码结构

```
cloudoffice-system-service/src/main/java/org/cloudstrolling/cloudoffice/system/
├── SystemApplication.java          # 系统服务启动入口（@SpringBootApplication + @EnableDiscoveryClient）
├── config/                         # 配置类（预留，仅 .gitkeep）
├── controller/                     # 控制器层
│   └── HealthController.java       # 健康检查控制器（GET /api/v1/system/health 返回服务状态）
├── dto/                            # 数据传输对象（预留，仅 .gitkeep）
├── entity/                         # 实体类（预留，仅 .gitkeep）
├── enums/                          # 枚举类（预留，仅 .gitkeep）
├── exception/                      # 异常处理类（预留，仅 .gitkeep）
├── filter/                         # 过滤器（预留，仅 .gitkeep）
├── interceptor/                    # 拦截器（预留，仅 .gitkeep）
├── mapper/                         # 数据访问层（预留，仅 .gitkeep）
├── service/                        # 业务逻辑层接口（预留，仅 .gitkeep）
│   └── impl/                       # 业务逻辑实现类（预留，仅 .gitkeep）
├── util/                           # 工具类（预留，仅 .gitkeep）
└── vo/                             # 视图对象（预留，仅 .gitkeep）
```

**资源文件：**
```
cloudoffice-system-service/src/main/resources/
├── bootstrap.yml                   # Nacos 注册/配置中心配置（server-addr 环境变量注入）
└── application.yml                 # 应用配置（端口 9400、MariaDB 数据源、MyBatis-Plus、SpringDoc、日志级别）
```

**测试代码：**
```
cloudoffice-system-service/src/test/java/org/cloudstrolling/cloudoffice/system/
├── SystemApplicationTest.java              # 应用启动测试：验证 Spring 上下文加载、@EnableDiscoveryClient 注解
└── controller/
    └── HealthControllerTest.java           # 健康检查控制器测试：MockMvc 单元测试，验证 200 状态码和响应体

cloudoffice-system-service/src/test/resources/
└── bootstrap.yml                           # 测试环境 Nacos 禁用配置
```

### 关键类说明

| 类名 | 包路径 | 功能描述 |
|------|--------|----------|
| `SystemApplication` | `org.cloudstrolling.cloudoffice.system` | 系统服务启动入口，@SpringBootApplication + @EnableDiscoveryClient 集成 Nacos 服务发现 |
| `HealthController` | `org.cloudstrolling.cloudoffice.system.controller` | 健康检查控制器：GET /api/v1/system/health，返回服务名称/状态/版本/时间戳，@Slf4j 日志记录 |
| `SystemApplicationTest` | `org.cloudstrolling.cloudoffice.system` | 应用启动测试：验证 Spring 上下文正常加载、@EnableDiscoveryClient 注解存在 |
| `HealthControllerTest` | `org.cloudstrolling.cloudoffice.system.controller` | 健康检查控制器单元测试：反射注入 Mock Environment，验证 HTTP 200 状态码、ApiResult 响应体各字段正确性 |

---

> **说明：** 项目地图持续更新中，反映当前 v0.1.5 阶段的代码实现状态。

---

# 变更记录

| 日期 | 版本 | 变更说明 |
|------|------|----------|
| 2026-06-22 | v0.1.5 | 项目文档更新 - 登录认证与权限管理开发 |
| 2026-06-22 | v0.1.5 | 项目地图更新 - ErrorCode枚举新增AUTH-0001~AUTH-0019认证错误码（共29个），ErrorCodeTest同步新增19个认证错误码测试方法 |
| 2026-06-19 | v0.1.4 | 系统服务模块搭建 - 完成 cloudoffice-system-service 基础框架 |
| 2026-06-19 | v0.1.0 | 项目文档更新 - 移除cloud-service微服务模块 |
