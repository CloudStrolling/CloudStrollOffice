# 项目基本信息

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**编程语言：** Java 21 (OpenJDK 21 LTS)、Dart 3.x (Flutter)
**项目类型：** 微服务应用程序（Spring Boot + Spring Cloud）
**当前进度：** 🚧 开发中（v0.2.0 Flutter前端子项目——任务清单已生成）
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
├── dto/                            # 数据传输对象
│   ├── TokenPairDTO.java           # 双Token响应DTO（accessToken/refreshToken/过期时间/tokenType）
│   └── LoginUserDTO.java           # 登录用户信息DTO（userId/tenantId/userName/clientType/roles/permissions）
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
├── constant/                        # 常量定义
│   └── RedisKeyConstants.java       # Redis Key 常量（v0.1.6 扩展：验证码相关Key — PREFIX_VERIFICATION_CODE/PREFIX_FREQUENCY_LIMIT 及频次限制常量）
├── enums/                            # 枚举类
│   ├── RegisterModeEnum.java        # 注册模式枚举（v0.1.6）：USERNAME_PASSWORD/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO
│   ├── LoginModeEnum.java           # 登录模式枚举（v0.1.6）：USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH
│   └── OAuthProviderEnum.java       # OAuth 提供商枚举（v0.1.6）：WECHAT/ALIPAY/DINGTALK/OTHER
└── util/                           # 工具类
    ├── .gitkeep                    # 占位文件
    └── JsonUtils.java              # JSON 工具类（基于 Jackson ObjectMapper 单例，支持 JavaTimeModule）
```

**测试代码：**
```
cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/
├── config/
│   └── MyBatisPlusConfigTest.java          # MyBatis-Plus 自动填充配置测试
├── dto/
│   ├── TokenPairDTOTest.java               # 双Token响应DTO测试（getter/setter/Builder/序列化）
│   └── LoginUserDTOTest.java               # 登录用户信息DTO测试（getter/setter/Builder/默认空列表/序列化）
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
| `TokenPairDTO` | `org.cloudstrolling.cloudoffice.common.dto` | 双 Token 响应 DTO：Lombok 注解，实现 Serializable，含 accessToken/refreshToken/过期时间/tokenType |
| `LoginUserDTO` | `org.cloudstrolling.cloudoffice.common.dto` | 登录用户信息 DTO：Lombok 注解，实现 Serializable，含 userId/tenantId/userName/clientType/roles/permissions |
| `ErrorCode` | `org.cloudstrolling.cloudoffice.common.exception` | 通用错误码枚举：包含10个HTTP基础错误码 + 33个认证授权错误码（AUTH-0001~AUTH-0033），新增14个错误码（AUTH-0020~AUTH-0033）：REGISTER_MODE_UNSUPPORTED/LOGIN_MODE_UNSUPPORTED/VERIFICATION_CODE_INVALID/VERIFICATION_CODE_EXPIRED/FREQUENCY_LIMITED/SEND_VERIFICATION_CODE_FAILED/OAUTH_BIND_FAILED/ACCOUNT_NOT_SETTLED/PHONE_ALREADY_BOUND/PHONE_NOT_BOUND/PASSWORD_STRENGTH_INSUFFICIENT/PASSWORD_SAME_AS_OLD/PASSWORD_RESET_TOKEN_INVALID/ACCOUNT_ALREADY_SETTLED |
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
│   ├── SecurityConfig.java         # Spring Security 安全配置（BCrypt 编码器、无状态会话、CSRF 关闭、自定义 401/403 JSON 响应；v0.1.6 白名单扩展：新增 /api/v1/auth/verification-code/**、/api/v1/auth/password/forgot/**、/api/v1/auth/phone/change、/api/v1/auth/account/settlement）
│   ├── OAuth2Config.java           # OAuth2 授权服务器骨架配置（预留扩展点，v0.2.0 实现完整授权码流程）
│   ├── RsaKeyConfig.java           # RSA 密钥对配置（加载私钥/公钥用于 JWT RS256 签名/验签）
│   ├── VerificationCodeProperties.java  # 验证码配置属性类（v0.1.6）：过期时间/长度/频率限制间隔
│   └── PasswordProperties.java     # 密码配置属性类（v0.1.6）：最小长度/复杂度要求/历史密码次数
├── controller/                     # 控制器层
│   ├── AuthController.java         # 认证控制器（v0.1.6 重写+扩展：12 个端点 — login/register/refresh/logout/kickout/sendVerificationCode/changePassword/forgotPasswordSendCode/forgotPasswordReset/changePhone/accountSettlement + health）
│   └── HealthController.java       # 健康检查控制器（GET /api/v1/auth/health 返回服务状态）
├── dto/                            # 数据传输对象
│   ├── AssignRolesRequest.java     # 用户角色分配请求 DTO（全量替换角色 ID 列表）
│   ├── KickoutRequest.java         # 强制踢人请求 DTO（目标用户 ID + 客户端类型）
│   ├── LoginRequest.java           # 登录请求 DTO（v0.1.6 扩展：新增 loginMode/loginCode 字段支持多模式登录）
│   ├── RefreshTokenRequest.java    # Token 刷新请求 DTO（refreshToken 字符串，@NotBlank 校验）
│   ├── RegisterRequest.java        # 用户注册请求 DTO（v0.1.6 扩展：新增 registerMode 等字段）
│   ├── UserStatusRequest.java      # 用户状态更新请求 DTO
│   ├── UserUpdateRequest.java      # 用户信息更新请求 DTO
│   ├── SendVerificationCodeRequest.java # 发送验证码请求 DTO（v0.1.6）：target/purpose
│   ├── PasswordChangeRequest.java  # 修改密码请求 DTO（v0.1.6）：oldPassword/newPassword
│   ├── PasswordForgotRequest.java  # 密码找回请求 DTO（v0.1.6）：phone/email/verificationCode/newPassword
│   ├── PhoneChangeRequest.java     # 手机号变更请求 DTO（v0.1.6）：newPhone/verificationCode
│   ├── AccountSettlementRequest.java    # 账号补全请求 DTO（v0.1.6）：username/password
│   └── result/                     # 响应结果 DTO
│       ├── AuthResult.java         # 认证结果 DTO（v0.1.6）：登录方式/是否有密码/账号状态
│       └── RegisterResult.java     # 注册结果 DTO（v0.1.6）：用户ID/userEntity/TODO补全状态
├── entity/                         # 实体类
│   ├── LoginLogEntity.java         # 登录日志实体（t_auth_login_log：登录名/用户ID/租户ID/IP/客户端类型/登录结果/失败原因）
│   ├── OAuthAccountEntity.java     # OAuth 账号绑定实体（v0.1.6）：t_auth_oauth_account — provider/providerUserId/userId/unionId
│   ├── PermissionEntity.java       # 权限实体（t_auth_permission）
│   ├── RoleEntity.java             # 角色实体（t_auth_role）
│   ├── RolePermissionEntity.java   # 角色权限关联实体（t_auth_role_permission）
│   ├── TenantEntity.java           # 租户实体（t_auth_tenant：租户编码/名称/状态/过期时间）
│   ├── UserEntity.java             # 用户实体（t_auth_user：v0.1.6 扩展5字段 — phone/email/registerMode/accountSettled/oauthProvider）
│   ├── UserRoleEntity.java         # 用户角色关联实体（t_auth_user_role）
│   └── VerificationCodeEntity.java # 验证码实体（v0.1.6）：t_auth_verification_code — target/purpose/code/expireTime/used
├── enums/                          # 枚举类（预留，仅 .gitkeep）
├── exception/                      # 异常处理类（预留，仅 .gitkeep）
├── filter/                         # 过滤器（预留，仅 .gitkeep）
├── interceptor/                    # 拦截器（预留，仅 .gitkeep）
├── mapper/                         # 数据访问层
│   ├── LoginLogMapper.java         # 登录日志 Mapper（t_auth_login_log CRUD）
│   ├── OAuthAccountMapper.java     # OAuth 账号绑定 Mapper（v0.1.6）：t_auth_oauth_account CRUD + 按provider+providerUserId查询
│   ├── PermissionMapper.java       # 权限 Mapper（t_auth_permission CRUD）
│   ├── RoleMapper.java             # 角色 Mapper（t_auth_role CRUD + 联表查询）
│   ├── RolePermissionMapper.java   # 角色权限关联 Mapper（t_auth_role_permission CRUD）
│   ├── TenantMapper.java           # 租户 Mapper（t_auth_tenant CRUD）
│   ├── UserMapper.java             # 用户 Mapper（t_auth_user CRUD + 联表查询角色编码/权限标识）
│   ├── UserRoleMapper.java         # 用户角色关联 Mapper（t_auth_user_role CRUD）
│   └── VerificationCodeMapper.java # 验证码 Mapper（v0.1.6）：t_auth_verification_code CRUD + 按target+purpose查询最新未使用验证码
├── service/                        # 业务逻辑层接口
│   ├── AuthenticationService.java  # 统一认证编排服务（v0.1.6）：编排登录策略选择→策略认证→租户/用户状态校验→双Token签发→Redis会话→日志审计的13步流程
│   ├── LoginLogService.java        # 登录日志审计服务接口（记录登录成功/失败/更新登出时间）
│   ├── LoginService.java           # 登录认证服务接口（登录、登出、强制踢人）
│   ├── LoginSessionService.java    # Redis 登录态管理服务接口（会话 CRUD/Token 黑名单/状态缓存）
│   ├── PasswordService.java        # 密码管理服务（v0.1.6）：密码修改(需原密码)/密码找回(验证码重置)/手机号变更(原手机验证码或邮箱验证)
│   ├── PermissionService.java      # 权限管理服务接口
│   ├── RoleService.java            # 角色管理服务接口
│   ├── TokenService.java           # Token 刷新服务接口（含轮换机制）
│   ├── UserService.java            # 用户管理服务接口（注册/状态管理/CRUD）
│   ├── VerificationCodeManager.java    # 验证码管理接口（v0.1.6）：生成/校验/标记已用/频率控制
│   ├── VerificationCodeService.java    # 验证码发送服务接口（v0.1.6）：send(target, purpose)
│   ├── impl/                       # 业务逻辑实现类
│   │   ├── LoginLogServiceImpl.java    # 登录日志审计实现（try-catch 异常隔离，不抛异常）
│   │   ├── LoginServiceImpl.java       # 登录认证实现（13 步登录流程：校验租户/用户/密码 → 签发双 Token → 同端互斥 → Redis 会话 → 日志记录）
│   │   ├── LoginSessionServiceImpl.java # Redis 会话管理实现（基于 RedisTemplate 的登录态/黑名单/状态缓存）
│   │   ├── PermissionServiceImpl.java   # 权限管理实现
│   │   ├── RoleServiceImpl.java         # 角色管理实现（CRUD/权限分配/已用检查）
│   │   ├── SimulatedVerificationCodeService.java  # 验证码发送实现（v0.1.6）：模拟发送，控制台打印验证码
│   │   ├── TokenServiceImpl.java        # Token 刷新实现（Refresh Token 轮换/租户+账号状态校验）
│   │   ├── UserServiceImpl.java         # 用户管理实现（注册/状态变更/角色分配/CRUD）
│   │   └── VerificationCodeManagerImpl.java  # 验证码管理实现（v0.1.6）：6位随机码/Redis存储/频率限制/校验
│   └── strategy/                    # 策略模式实现（v0.1.6）
│       ├── LoginStrategy.java           # 登录策略接口：authenticate(LoginRequest)
│       ├── LoginStrategyFactory.java    # 登录策略工厂：按 LoginMode 获取对应策略 Bean
│       ├── UsernamePasswordStrategy.java    # 用户名密码登录策略
│       ├── PhoneCodeLoginStrategy.java      # 手机验证码登录策略
│       ├── PhonePasswordLoginStrategy.java  # 手机号+密码登录策略
│       ├── OAuthLoginStrategy.java         # OAuth 登录策略
│       ├── RegisterStrategy.java           # 注册策略接口：register(RegisterRequest)
│       ├── RegisterStrategyFactory.java    # 注册策略工厂：按 RegisterMode 获取对应策略 Bean
│       ├── UsernamePwdRegisterStrategy.java    # 用户名密码注册策略
│       ├── PhoneCodeRegisterStrategy.java      # 手机验证码注册策略
│       ├── OAuthRegisterStrategy.java         # OAuth 注册策略
│       ├── PhoneSetUsernameStrategy.java       # 手机注册后补全用户名策略
│       └── OAuthSetInfoStrategy.java           # OAuth 注册后补全信息策略
├── util/                           # 工具类
│   └── JwtUtils.java               # JWT 令牌工具类（RS256 双 Token：签发/解析/签名指纹/getter）
└── vo/                             # 视图对象（预留，仅 .gitkeep）
```

**测试代码：**
```
cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/
├── AuthApplicationTest.java                # 应用启动测试：验证 Spring 上下文加载、@EnableDiscoveryClient 注解
├── config/
│   └── SecurityConfigTest.java             # 安全配置测试：BCrypt 编码器、匿名访问路径、401/403 响应
├── controller/
│   ├── AuthControllerTest.java              # AuthController 单元测试（10 个测试：login/register/refresh/logout/kickout 端点全覆盖）
│   └── HealthControllerTest.java           # 健康检查控制器测试：MockMvc 单元测试，验证 200 状态码和响应体
├── service/
│   └── impl/
│       ├── LoginServiceImplTest.java       # LoginServiceImpl 单元测试（39 个测试：登录/登出/踢人全场景覆盖）
│       ├── LoginLogServiceImplTest.java    # LoginLogServiceImpl 单元测试（更新登出时间/异常处理）
│       ├── LoginSessionServiceImplTest.java # LoginSessionServiceImpl 单元测试（会话/黑名单/状态缓存）
│       ├── RoleServiceImplTest.java        # RoleServiceImpl 单元测试（CRUD/权限分配）
│       ├── TokenServiceImplTest.java       # TokenServiceImpl 单元测试（刷新/黑名单/状态校验）
│       └── UserServiceImplTest.java        # UserServiceImpl 单元测试（注册/状态/角色分配）
└── util/
    └── JwtUtilsTest.java                   # JWT 工具类测试（RS256 双 Token）：17 个测试覆盖签发/解析/签名指纹/错误处理

cloudoffice-auth-service/src/test/resources/
└── bootstrap.yml                           # 测试环境 Nacos 禁用配置
```

### 关键类说明

| 类名 | 包路径 | 功能描述 |
|------|--------|----------|
| `AuthApplication` | `org.cloudstrolling.cloudoffice.auth` | 认证服务启动入口，@SpringBootApplication + @EnableDiscoveryClient 集成 Nacos 服务发现 |
| `SecurityConfig` | `org.cloudstrolling.cloudoffice.auth.config` | Spring Security 安全配置：BCryptPasswordEncoder 密码编码器、无状态会话管理、CSRF 关闭、健康检查/Swagger 端点匿名访问、自定义 401/403 JSON 响应 |
| `OAuth2Config` | `org.cloudstrolling.cloudoffice.auth.config` | OAuth2 授权服务器骨架配置类，预留下期扩展点 |
| `RsaKeyConfig` | `org.cloudstrolling.cloudoffice.auth.config` | RSA 密钥对配置类，加载 RSA 私钥/公钥用于 JWT RS256 签名和验签 |
| `HealthController` | `org.cloudstrolling.cloudoffice.auth.controller` | 健康检查控制器：GET /api/v1/auth/health，返回服务名称/状态/版本/时间戳 |
| `AuthController` | `org.cloudstrolling.cloudoffice.auth.controller` | 认证控制器：v0.1.6 重写+扩展 — 12 个端点（login/register/refresh/logout/kickout/sendVerificationCode/changePassword/forgotPasswordSendCode/forgotPasswordReset/changePhone/accountSettlement + health），@RequiredArgsConstructor 注入 |
| `LoginRequest` | `org.cloudstrolling.cloudoffice.auth.dto` | 登录请求 DTO：v0.1.6 扩展新增 loginMode/loginCode 字段支持多模式登录 |
| `RefreshTokenRequest` | `org.cloudstrolling.cloudoffice.auth.dto` | Token 刷新请求 DTO：refreshToken 字符串，@NotBlank 校验 |
| `LoginLogEntity` | `org.cloudstrolling.cloudoffice.auth.entity` | 登录日志实体：t_auth_login_log，记录登录名、用户/租户 ID、IP、客户端类型、登录结果、失败原因等 |
| `TenantEntity` | `org.cloudstrolling.cloudoffice.auth.entity` | 租户实体：t_auth_tenant，含租户编码/名称/状态/过期时间 |
| `UserEntity` | `org.cloudstrolling.cloudoffice.auth.entity` | 用户实体：t_auth_user，v0.1.6 扩展5字段 — phone(手机号)/email(邮箱)/registerMode(注册模式)/accountSettled(账号是否已补全)/oauthProvider(OAuth提供商) |
| `TenantMapper` | `org.cloudstrolling.cloudoffice.auth.mapper` | 租户 Mapper：BaseMapper<TenantEntity>，提供租户表 CRUD 操作 |
| `UserMapper` | `org.cloudstrolling.cloudoffice.auth.mapper` | 用户 Mapper：BaseMapper<UserEntity> + 联表查询方法（selectRoleCodesByUserId/selectPermissionCodesByUserId） |
| `LoginService` | `org.cloudstrolling.cloudoffice.auth.service` | 登录认证服务接口：login(LoginRequest)/logout()/kickout()（v0.1.6 保留向后兼容，新逻辑委托给 AuthenticationService） |
| `LoginServiceImpl` | `org.cloudstrolling.cloudoffice.auth.service.impl` | 登录认证实现：13 步完整登录流程（参数校验→clientType校验→租户查询→用户查询→BCrypt校验→角色权限→双 Token 签发→同端互斥→Redis 会话→状态缓存→日志记录→用户表更新） |
| `LoginLogService` | `org.cloudstrolling.cloudoffice.auth.service` | 登录日志审计服务接口：recordLoginSuccess/recordLoginFailure/updateLogoutTime |
| `LoginLogServiceImpl` | `org.cloudstrolling.cloudoffice.auth.service.impl` | 登录日志审计实现：try-catch 异常隔离，数据库写入失败仅记录错误日志不影响主流程 |
| `LoginSessionService` | `org.cloudstrolling.cloudoffice.auth.service` | Redis 登录态管理服务接口：会话 CRUD/Token 黑名单/账号状态缓存/租户状态缓存 |
| `LoginSessionServiceImpl` | `org.cloudstrolling.cloudoffice.auth.service.impl` | Redis 会话管理实现：基于 RedisTemplate 的登录态存储/黑名单/状态缓存 |
| `TokenService` | `org.cloudstrolling.cloudoffice.auth.service` | Token 刷新服务接口：含 Refresh Token 轮换机制 |
| `TokenServiceImpl` | `org.cloudstrolling.cloudoffice.auth.service.impl` | Token 刷新实现：黑名单校验/轮换/租户+账号状态重新校验 |
| `UserService` | `org.cloudstrolling.cloudoffice.auth.service` | 用户管理服务接口：注册/状态变更/角色分配/CRUD（v0.1.6 新增 updatePassword/updatePhone/updateEmail/updateAccountSettled 方法） |
| `UserServiceImpl` | `org.cloudstrolling.cloudoffice.auth.service.impl` | 用户管理实现：注册校验/状态管理/角色分配/CRUD |
| `JwtUtils` | `org.cloudstrolling.cloudoffice.auth.util` | JWT 令牌工具类（RS256 双 Token）：构造器注入 RsaKeyConfig，提供 generateAccessToken/generateRefreshToken/parseAccessToken/parseRefreshToken/getTokenSignature/getAccessTokenExpiration/getRefreshTokenExpiration |
| `VerificationCodeProperties` | `org.cloudstrolling.cloudoffice.auth.config` | 验证码配置属性类（v0.1.6）：codeExpireSeconds/codeLength/frequencyLimitInterval 配置绑定 |
| `PasswordProperties` | `org.cloudstrolling.cloudoffice.auth.config` | 密码配置属性类（v0.1.6）：minLength/complexityRequired/historyPasswordCount 配置绑定 |
| `RegisterModeEnum` | `org.cloudstrolling.cloudoffice.common.enums` | 注册模式枚举（v0.1.6）：USERNAME_PASSWORD/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO |
| `LoginModeEnum` | `org.cloudstrolling.cloudoffice.common.enums` | 登录模式枚举（v0.1.6）：USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH |
| `OAuthProviderEnum` | `org.cloudstrolling.cloudoffice.common.enums` | OAuth 提供商枚举（v0.1.6）：WECHAT/ALIPAY/DINGTALK/OTHER |
| `AuthenticationService` | `org.cloudstrolling.cloudoffice.auth.service` | 统一认证编排服务（v0.1.6）：authenticate(LoginRequest)/register(RegisterRequest) — 13步编排流程 |
| `PasswordService` | `org.cloudstrolling.cloudoffice.auth.service` | 密码管理服务（v0.1.6）：changePassword/forgotPasswordSendCode/forgotPasswordReset/changePhone |
| `VerificationCodeManager` | `org.cloudstrolling.cloudoffice.auth.service` | 验证码管理接口（v0.1.6）：生成6位随机码/Redis存储/频率限制/校验/标记已用 |
| `VerificationCodeService` | `org.cloudstrolling.cloudoffice.auth.service` | 验证码发送服务接口（v0.1.6）：send(target, purpose) — 由 SimulatedVerificationCodeService 模拟实现 |
| `LoginStrategy` | `org.cloudstrolling.cloudoffice.auth.service.strategy` | 登录策略接口（v0.1.6）：authenticate(LoginRequest) → AuthResult，4种实现 |
| `RegisterStrategy` | `org.cloudstrolling.cloudoffice.auth.service.strategy` | 注册策略接口（v0.1.6）：register(RegisterRequest) → RegisterResult，5种实现 |
| `OAuthLoginStrategy` | `org.cloudstrolling.cloudoffice.auth.service.strategy` | OAuth 登录策略（v0.1.6）：按OAuth提供商查询绑定关系→获取/创建用户→返回AuthResult |
| `UsernamePasswordStrategy` | `org.cloudstrolling.cloudoffice.auth.service.strategy` | 用户名密码登录策略（v0.1.6）：按loginName查询用户→BCrypt校验密码→返回AuthResult |
| `PhoneCodeLoginStrategy` | `org.cloudstrolling.cloudoffice.auth.service.strategy` | 手机验证码登录策略（v0.1.6）：校验手机号存在→校验验证码→返回AuthResult |
| `PhonePasswordLoginStrategy` | `org.cloudstrolling.cloudoffice.auth.service.strategy` | 手机号+密码登录策略（v0.1.6）：按手机号查用户→BCrypt校验密码→返回AuthResult |
| `OAuthAccountEntity` | `org.cloudstrolling.cloudoffice.auth.entity` | OAuth 账号绑定实体（v0.1.6）：t_auth_oauth_account — provider/providerUserId/userId/unionId |
| `VerificationCodeEntity` | `org.cloudstrolling.cloudoffice.auth.entity` | 验证码实体（v0.1.6）：t_auth_verification_code — target/purpose/code/expireTime/used |

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

> **说明：** 项目地图持续更新中，反映当前 v0.2.0 阶段的代码实现状态。Java 微服务后端已迭代至 v0.1.7，Flutter 前端子项目 v0.2.0 已全部实现。

---

## cloudoffice-flutter-app/ Flutter 前端子项目（v0.2.0）

### 项目信息

| 属性 | 值 |
|------|-----|
| 项目名称 | `cloudoffice-flutter-app` |
| 编程语言 | Dart 3.x |
| Flutter SDK | D:\jenemy\develop\flutter |
| 目标平台 | Web + Windows |
| 功能范围 | 注册、登录、找回密码（v0.2.0） |

### 实际目录结构

```
cloudoffice-flutter-app/
├── lib/
│   ├── main.dart                    # 应用入口（runApp → CloudStrollOfficeApp）
│   ├── app.dart                     # MaterialApp 配置（MultiProvider + GoRouter）
│   ├── config/                      # 配置（API 地址、主题等）
│   │   ├── api_config.dart          # API 配置类（baseUrl/timeout/clientType）
│   │   └── theme_config.dart        # 主题配置（Material 3 主题）
│   ├── core/                        # 核心层
│   │   ├── http/                    # HTTP 客户端封装
│   │   │   ├── api_client.dart      # Dio 单例封装
│   │   │   ├── api_interceptor.dart # 拦截器（Token 注入 + 401 自动刷新）
│   │   │   └── api_result.dart      # 通用 ApiResult<T> 响应模型
│   │   ├── router/                  # 路由配置
│   │   │   └── app_router.dart      # GoRouter 路由表 + 登录守卫
│   │   ├── storage/                 # 本地存储
│   │   │   └── secure_storage.dart  # 安全存储封装（flutter_secure_storage）
│   │   └── utils/                   # 工具类
│   │       └── validators.dart      # 表单校验（9 个函数 + 密码强度）
│   ├── features/                    # 功能模块
│   │   ├── auth/                    # 认证功能
│   │   │   ├── models/             # 7 个数据模型
│   │   │   │   ├── login_request.dart
│   │   │   │   ├── register_request.dart
│   │   │   │   ├── token_pair.dart
│   │   │   │   ├── user_info.dart
│   │   │   │   ├── send_verification_code_request.dart
│   │   │   │   ├── password_forgot_request.dart
│   │   │   │   └── register_result.dart
│   │   │   ├── providers/          # 状态管理
│   │   │   │   ├── auth_provider.dart          # 登录/注册/登出状态 + Token持久化
│   │   │   │   └── forgot_password_provider.dart # 两步找回密码流程
│   │   │   ├── repositories/       # 数据仓库
│   │   │   │   └── auth_repository.dart       # 6 个认证 API 调用
│   │   │   └── screens/            # 页面
│   │   │       ├── login_screen.dart           # 登录页面
│   │   │       ├── register_screen.dart        # 注册页面
│   │   │       └── forgot_password_screen.dart # 找回密码页面
│   │   └── home/                    # 首页
│   │       ├── providers/
│   │       │   └── home_provider.dart         # 用户信息 + 退出登录
│   │       └── screens/
│   │           └── home_screen.dart
│   └── shared/                      # 共享组件
│       ├── widgets/                 # 5 个公共组件
│       │   ├── custom_text_field.dart
│       │   ├── password_field.dart
│       │   ├── loading_button.dart
│       │   ├── password_strength_indicator.dart
│       │   └── verification_code_field.dart
│       └── constants/               # 常量
│           └── app_constants.dart
├── test/                            # 测试（182 个用例）
│   ├── test_helpers.dart            # 测试辅助类（StubAuthRepository）
│   ├── widget_test.dart             # 应用冒烟测试
│   ├── core/
│   │   ├── http/
│   │   │   ├── api_client_test.dart
│   │   │   └── api_result_test.dart
│   │   ├── storage/
│   │   │   └── secure_storage_test.dart
│   │   └── utils/
│   │       └── validators_test.dart
│   └── features/
│       ├── auth/
│       │   ├── models/             # 7 个模型测试
│       │   ├── repositories/
│       │   │   └── auth_repository_test.dart
│       │   └── providers/
│       │       ├── auth_provider_test.dart
│       │       └── forgot_password_provider_test.dart
│       └── home/
│           └── providers/
│               └── home_provider_test.dart
├── web/                             # Web 平台配置（title: 云漫智企）
├── windows/                         # Windows 平台配置（窗口标题: 云漫智企）
├── pubspec.yaml                     # 依赖配置（dio/provider/go_router/flutter_secure_storage/shared_preferences）
├── analysis_options.yaml            # 代码分析配置
└── README.md                        # 项目说明
```

### 关键说明

| 类/文件 | 路径 | 功能描述 |
|---------|------|----------|
| `main.dart` | `lib/main.dart` | Flutter 应用入口，runApp(CloudStrollOfficeApp()) |
| `app.dart` | `lib/app.dart` | MaterialApp.router 配置：MultiProvider（AuthProvider/ForgotPasswordProvider/HomeProvider）+ GoRouter + Material 3 主题 |
| `api_config.dart` | `lib/config/api_config.dart` | API 基础配置：baseUrl/gateway:9000、connectTimeout 15s、receiveTimeout 30s、clientType 平台自适应 |
| `theme_config.dart` | `lib/config/theme_config.dart` | Material Design 3 主题：ColorScheme.fromSeed(primary: 0xFF1976D2)、InputDecoration/Button/Card/Text 全局样式 |
| `api_client.dart` | `lib/core/http/api_client.dart` | Dio 单例封装：baseUrl/超时/默认请求头、get/post/put/delete 方法、注册 ApiInterceptor |
| `api_interceptor.dart` | `lib/core/http/api_interceptor.dart` | Token 注入（白名单路径跳过）、401 自动刷新（并发锁+等待队列）、刷新失败清除 Token |
| `api_result.dart` | `lib/core/http/api_result.dart` | 泛型 ApiResult<T>：fromJson/fromJsonList/toJson、isSuccess()、success()/error() 工厂 |
| `app_router.dart` | `lib/core/router/app_router.dart` | GoRouter 4 路由（/login /register /forgot-password /）+ 登录守卫：未登录→/login，已登录→/ |
| `secure_storage.dart` | `lib/core/storage/secure_storage.dart` | flutter_secure_storage 单例封装：saveTokenPair/getAccessToken/getRefreshToken/hasTokens/clearTokens |
| `validators.dart` | `lib/core/utils/validators.dart` | 9 个校验函数：validateLoginName(4-64)/Password(8-64)/ConfirmPassword/Phone(11位)/Code(6位)/UserName(2-50)/Email + calculatePasswordStrength |
| `auth_repository.dart` | `lib/features/auth/repositories/auth_repository.dart` | 6 个 API 调用：login/register/refreshToken/logout/sendVerificationCode/forgotPasswordReset，统一 DioException→ApiResult.error 转换 |
| `auth_provider.dart` | `lib/features/auth/providers/auth_provider.dart` | 认证状态管理：login/loginWithSmsCode/register/registerWithPhone/logout/checkLoginStatus，Token 自动持久化 |
| `forgot_password_provider.dart` | `lib/features/auth/providers/forgot_password_provider.dart` | 两步找回密码：sendVerificationCode + verifyIdentity + resetPassword，验证码倒计时 60s，成功倒计时 3s，Timer 自动释放 |
| `home_provider.dart` | `lib/features/home/providers/home_provider.dart` | 首页状态：loadUserInfo/logout，API 失败仍清除本地 Token（离线退出） |
| `login_screen.dart` | `lib/features/auth/screens/login_screen.dart` | 登录页：登录名+密码输入、"记住我"（SharedPreferences 持久化）、注册/忘记密码链接、LoadingButton 防重复提交 |
| `register_screen.dart` | `lib/features/auth/screens/register_screen.dart` | 注册页：用户名+真实姓名+密码+确认密码+密码强度指示器、实时 onUserInteraction 校验 |
| `forgot_password_screen.dart` | `lib/features/auth/screens/forgot_password_screen.dart` | 两步找回密码：Step1 身份验证（VerificationCodeField）、Step2 重置密码（PasswordField+PasswordStrengthIndicator）、步骤指示器 |
| `home_screen.dart` | `lib/features/home/screens/home_screen.dart` | 首页：用户信息卡片（脱敏手机号/邮箱）、退出登录确认对话框、加载中状态 |
| `custom_text_field.dart` | `lib/shared/widgets/custom_text_field.dart` | 统一封装的 TextFormField：prefixIcon/suffixIcon/validator/onChanged 等 Material 3 风格 |
| `password_field.dart` | `lib/shared/widgets/password_field.dart` | 密码输入框：显示/隐藏密码切换（visibility/visibility_off 图标） |
| `loading_button.dart` | `lib/shared/widgets/loading_button.dart` | 加载按钮：isLoading 显示 CircularProgressIndicator 并禁用、full width 48px height |
| `password_strength_indicator.dart` | `lib/shared/widgets/password_strength_indicator.dart` | 密码强度实时指示：弱(红)/中(橙)/强(绿) 三级 + LinearProgressIndicator |
| `verification_code_field.dart` | `lib/shared/widgets/verification_code_field.dart` | 验证码输入组件：手机号输入 + 获取验证码按钮 + 6位验证码输入、倒计时状态外部控制 |
| `app_constants.dart` | `lib/shared/constants/app_constants.dart` | 应用常量：kPasswordMinLength=8、kPasswordMaxLength=64、kCountdownSeconds=60、kSuccessCountdownSeconds=3、kCodeLength=6 |

---

# 变更记录

| 日期 | 版本 | 变更说明 |
|------|------|----------|
| 2026-06-24 | v0.2.0 | 架构设计更新 - 基于 v0.2.0 PRD 更新 architecture.md，新增 Flutter 前端架构（2.7 模块设计、技术选型、ADR-026、部署架构、目录结构） |
| 2026-06-24 | v0.2.0 | 项目地图更新 - 新增 Flutter 前端子项目 (cloudoffice-flutter-app) 目录规划，支持 Web + Windows 双平台 |
| 2026-06-24 | v0.2.0 | Flutter 前端 v0.2.0 全部编码完成 - 26 个 TASK 全部实现（core层/7个数据模型/AuthRepository/3个Provider/4个页面/5个共享组件/AppRouter/app入口），182 个单元测试全部通过，flutter analyze 零错误零警告 |
| 2026-06-23 | v0.1.5 | 项目地图更新 - 认证服务源码结构全面更新（DTO/Entity/Mapper/Service/Impl），新增 LoginRequest/LoginServiceImpl(login)/LoginLogServiceImpl(recordLoginSuccess/Failure)/JwtUtils(getter) |
| 2026-06-24 | v0.1.6 | 全部完成 - README/部署指南/项目地图文档更新，分支cso-v0.1.6合并至master，回归测试234个全部通过 |
| 2026-06-23 | v0.1.6 | 编码完成 - 用户认证增强开发（多模式注册/登录/密码管理/手机号变更/验证码管理），36个TASK全部实现，206个测试全部通过，52个文件变更 |
| 2026-06-22 | v0.1.5 | 项目文档更新 - 登录认证与权限管理开发 |
| 2026-06-22 | v0.1.5 | 项目地图更新 - ErrorCode枚举新增AUTH-0001~AUTH-0019认证错误码（共29个），ErrorCodeTest同步新增19个认证错误码测试方法 |
| 2026-06-22 | v0.1.5 | JwtUtils 重构完成 - HS256 → RS256 双 Token，新增 generateAccessToken/generateRefreshToken/parseAccessToken/parseRefreshToken/getTokenSignature 方法，JwtUtilsTest 新增 17 个测试用例 |
| 2026-06-19 | v0.1.4 | 系统服务模块搭建 - 完成 cloudoffice-system-service 基础框架 |
| 2026-06-19 | v0.1.0 | 项目文档更新 - 移除cloud-service微服务模块 |
