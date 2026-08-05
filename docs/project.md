# 项目基本信息
**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端微服务）、Dart 3（Flutter 客户端）
**项目类型**：微服务企业办公套件（Maven 多模块 + Flutter 移动端）
**本地化语言**：简体中文
**总体介绍**：云漫智企（CloudStrollOffice）是基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务企业办公套件。项目采用 Maven 多模块架构，由公共模块（common）、API 网关（gateway）、认证服务（auth-service）、企业服务（biz-service）、系统服务（system-service）及 Flutter 客户端（flutter-app）组成，为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。当前已实现 RBAC 多租户权限模型（用户-角色-权限三层关联）、JWT RS256 双 Token 认证、网关全局认证拦截、多模式登录注册（策略工厂模式）、密码管理、手机号变更、验证码管理等核心能力。

# 数据库信息
**是否使用数据库**：是
**数据库产品**：MariaDB（关系型数据）、Redis 7.2.x（缓存：登录态会话 / Token 黑名单 / 账号与租户状态缓存）
**数据库版本**：MariaDB 10.6 (LTS)

# 编码规范
## 文件组织规范
- 后端按 Maven 多模块组织：cloudoffice-common（公共代码）、cloudoffice-gateway（网关）、cloudoffice-auth-service（认证服务）、cloudoffice-biz-service（企业服务）、cloudoffice-system-service（系统服务）、cloudoffice-flutter-app（客户端）。
- 各服务内按分层组织包：controller（接口层）→ service/impl（业务层）→ mapper（数据访问层）→ entity（实体）→ dto/vo（传输与视图对象）→ config（配置）→ util（工具）；策略模式代码统一放 service/strategy 包。
- 公共代码放公共目录（cloudoffice-common），服务间通过 Maven 依赖引用，避免循环依赖。
- Flutter 客户端按 feature 组织：lib/features/{模块}/ 下再分 screens、providers、models、repositories，共享代码放 shared/，基础设施放 core/ 与 config/。
- 接口路径规范：`/api/v1/{module}/{resource}`。

## 命名规范
- Java 类名、接口名使用首字母大写驼峰（TypeName），方法、变量、参数、成员使用首字母小写驼峰（MethodName/LocalVariableName/ParameterName/MemberName/StaticVariableName），常量使用全大写加下划线（ConstantName），包名全小写点分隔（PackageName）。
- 包根统一为 `org.cloudstrolling.cloudoffice.{module}`。
- 实体类统一以 `Entity` 后缀（如 UserEntity、TenantEntity），请求 DTO 以 `Request` 后缀（如 LoginRequest、RegisterRequest），响应 DTO 放 dto/result 包（如 AuthResult、RegisterResult）。
- Mapper 接口以 `Mapper` 后缀，Service 接口与实现以 `Service` / `ServiceImpl` 后缀。
- Flutter 文件按类型后缀命名（_screen、_provider、_model、_repository、_widget）。

## 代码风格
- 遵循《阿里巴巴 Java 开发手册》，配置了根目录 `checkstyle.xml` 与 `.editorconfig` 强制执行。
- 缩进使用 4 个空格（Markdown 2 个空格），禁止使用 Tab；文件编码统一 UTF-8，行尾 LF，文件末尾保留换行，行宽不超过 120 字符。
- 大括号采用 K&R 风格（LeftCurly/RightCurly/NeedBraces），禁止 System.out.println（必须使用日志框架）。
- 使用 Lombok 减少样板代码（`@Data`、`@Slf4j`、`@Builder` 等），统一使用构造器注入替代 `@Autowired` 字段注入。
- 导入顺序：java/javax → org → com → 静态导入，禁止星号导入与未使用导入，每行仅一个语句/一个变量定义。

## 注释规范
- 关键类、方法、复杂逻辑必须有简体中文注释（Javadoc 或行注释）；注释说明"为什么"而非"是什么"。
- 策略类（登录/注册策略）须说明其负责的登录/注册模式与业务前提。

## 日志规范
- 统一使用 SLF4J（`@Slf4j`）记录日志，禁止 System.out.println。
- 统一日志级别（DEBUG/INFO/WARN/ERROR）：关键业务路径（登录、注册、登出、踢人、改密、验证码发送等）必须记录 INFO 及以上日志，安全事件（登录失败、Token 失效）必须留痕。
- 禁止输出密码、Token、验证码等敏感信息；全局异常兜底不泄露堆栈与内部信息。

## 测试规范
- 测试先行（TDD）：编码前先写测试用例，编码后测试必须全部通过。
- 单元测试使用 JUnit 5 + Mockito（Spring Boot Starter Test），位于各模块 `src/test/java`。
- 认证服务当前已有 206+ 个单元测试覆盖登录、注册、Token、会话、密码、验证码等核心链路，新增功能必须配套测试。

## 统一错误处理规范
- 统一错误码体系：`ErrorCode` 接口定义错误码（29 个，含 19 个认证授权错误码 AUTH-0001~0019 与 14 个 v0.1.6 新增 AUTH-0020~0033），`ErrorCodeEnum` 提供具体实现。
- 异常体系分层：`BaseException` → `BusinessException` / `AuthException`，接口层由 `GlobalExceptionHandler`（@RestControllerAdvice）统一捕获并封装为标准响应，禁止吞异常。
- 所有 REST 接口统一返回 `ApiResult<T>`（含 code、message、data、timestamp），分页接口返回 `PageResult<T>`。
- 网关与认证服务对 401/403 输出自定义 JSON 响应体。

## 其他规范
- 禁止提交密钥、密码、环境变量等敏感信息（RSA 私钥、数据库密码等仅通过环境变量注入，密钥文件放 keys/ 且不入库）。
- 不提交日志与临时文件；遵循 `.gitignore` 忽略规则。
- 提交信息遵循 Conventional Commits 规范（feat:/fix:/docs:/refactor:/test:/chore:）。
- 涉及 AI 辅助开发时遵循根目录 `opencode.json`（opencode-impm 插件）与 `.opencode/` 目录下的 impm 流程规范。

# 项目地图
（由 impm-project-update 技能通过扫描源码目录自动维护，列出各源码目录与关键文件、函数、类的说明。以下为初始化时扫描结果。）

## 根目录
| 路径 | 说明 |
|------|------|
| `pom.xml` | 父 POM：统一依赖管理（Spring Boot 3.2.5 / Spring Cloud 2023.0.1 / Spring Cloud Alibaba 2023.0.1.0 / MyBatis-Plus 3.5.6 / JJWT 0.12.6 / Hutool 5.8.26 / SpringDoc 2.5.0 / Lombok 1.18.32 / MariaDB 驱动 3.3.3），声明 5 个 Maven 子模块 |
| `.editorconfig` | 跨编辑器编码风格：UTF-8、LF、4 空格缩进、120 行宽 |
| `checkstyle.xml` | Checkstyle 规则：命名、复杂度、导入顺序、大括号、禁止 System.out 等 |
| `opencode.json` | OpenCode 配置（opencode-impm 插件） |
| `env.json` / `env.example.json` | 环境变量示例与本地配置（不入库密钥） |
| `scripts/sql/` | 数据库初始化脚本（init.sql / auth-init-v0.1.5.sql / auth-init-v0.1.6.sql） |
| `scripts/docker/` | Docker Compose 编排（8 容器）与各服务 Dockerfile |

## cloudoffice-common（公共模块，JAR 无启动类）
| 路径 | 说明 |
|------|------|
| `common/model/ApiResult.java` | 统一响应体 `ApiResult<T>`（code/message/data/timestamp） |
| `common/model/PageResult.java` | 分页响应 `PageResult<T>` |
| `common/model/BaseEntity.java` | 实体基类（id、创建/更新时间等公共字段） |
| `common/model/ErrorCode.java` | 错误码接口（错误码/消息规范） |
| `common/exception/ErrorCode.java` | 错误码枚举实现（29 个错误码） |
| `common/exception/BaseException.java` | 异常基类 |
| `common/exception/BusinessException.java` | 业务异常 |
| `common/exception/AuthException.java` | 认证授权异常 |
| `common/exception/GlobalExceptionHandler.java` | 全局异常处理器（@RestControllerAdvice） |
| `common/config/MyBatisPlusConfig.java` | MyBatis-Plus 配置（分页插件、自动填充） |
| `common/config/SpringDocConfig.java` | SpringDoc (OpenAPI 3) 配置，按模块分组 |
| `common/dto/TokenPairDTO.java` | 双 Token DTO（Access + Refresh） |
| `common/dto/LoginUserDTO.java` | 登录用户信息 DTO |
| `common/constant/RedisKeyConstants.java` | Redis Key 常量（含验证码前缀） |
| `common/enums/ClientTypeEnum.java` | 客户端类型枚举（6 种） |
| `common/enums/LoginModeEnum.java` | 登录模式枚举（4 种） |
| `common/enums/RegisterModeEnum.java` | 注册模式枚举（5 种） |
| `common/enums/OAuthProviderEnum.java` | OAuth 提供商枚举（4 种） |
| `common/util/JsonUtils.java` | JSON 工具类（Jackson 封装） |

## cloudoffice-gateway（API 网关，端口 9000）
| 路径 | 说明 |
|------|------|
| `gateway/GatewayApplication.java` | 网关启动类 |
| `gateway/filter/AuthFilter.java` | 全局认证过滤器：9 步校验（白名单放行 → Bearer 格式 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传） |
| `gateway/config/RsaKeyConfig.java` | RSA 公钥配置（验签） |
| `gateway/config/RedisConfig.java` | Redis 配置（黑名单/登录态/状态校验） |
| `gateway/config/AuthProperties.java` | 认证相关属性（白名单路径、Header 名称等） |

## cloudoffice-auth-service（认证服务，端口 9100）
| 路径 | 说明 |
|------|------|
| `auth/AuthApplication.java` | 认证服务启动类 |
| `auth/controller/AuthController.java` | 认证接口：登录/注册/刷新/登出/踢人/发送验证码/密码修改/密码找回/手机号变更/账号补全（12 个端点） |
| `auth/controller/UserController.java` | 用户管理：分页/详情/更新/状态/角色分配/删除 |
| `auth/controller/RoleController.java` | 角色管理：CRUD + 权限分配 |
| `auth/controller/PermissionController.java` | 权限管理：树形列表/CRUD |
| `auth/controller/HealthController.java` | 健康检查端点 |
| `auth/entity/` | 9 个实体：UserEntity、TenantEntity、RoleEntity、PermissionEntity、UserRoleEntity、RolePermissionEntity、LoginLogEntity、OAuthAccountEntity、VerificationCodeEntity |
| `auth/mapper/` | 9 个 Mapper：UserMapper、TenantMapper、RoleMapper、PermissionMapper、UserRoleMapper、RolePermissionMapper、LoginLogMapper、OAuthAccountMapper、VerificationCodeMapper |
| `auth/dto/` | 请求 DTO：LoginRequest、RegisterRequest、RefreshTokenRequest、KickoutRequest、PasswordChangeRequest、PasswordForgotRequest、PhoneChangeRequest、AccountSettlementRequest、SendVerificationCodeRequest、UserUpdateRequest、UserStatusRequest、AssignRolesRequest 等 |
| `auth/dto/result/` | 响应 DTO：AuthResult（登录结果）、RegisterResult（注册结果） |
| `auth/service/AuthenticationService.java` | 认证编排服务（统一编排登录/注册流程） |
| `auth/service/LoginService.java` | 登录认证服务（13 步完整流程） |
| `auth/service/LoginSessionService.java` | Redis 会话管理（登录态/黑名单/踢人） |
| `auth/service/LoginLogService.java` | 登录日志审计（IP、客户端类型、结果、失败原因） |
| `auth/service/TokenService.java` | 双 Token 签发 + 刷新轮换 |
| `auth/service/PasswordService.java` | 密码管理（修改/找回/重置后清除登录态） |
| `auth/service/VerificationCodeManager.java` | 验证码管理器（生成/校验/频率控制/生命周期） |
| `auth/service/VerificationCodeService.java` | 验证码发送服务（短信/邮箱） |
| `auth/service/impl/SimulatedVerificationCodeService.java` | 模拟验证码服务（开发环境 mock） |
| `auth/service/UserService.java` / `RoleService.java` / `PermissionService.java` | 用户/角色/权限管理服务 |
| `auth/service/strategy/login/` | 登录策略：LoginStrategy 接口 + LoginStrategyFactory 工厂 + 4 个策略（UsernamePassword/PhoneCode/PhonePassword/OAuth） |
| `auth/service/strategy/register/` | 注册策略：RegisterStrategy 接口 + RegisterStrategyFactory 工厂 + 5 个策略（UsernamePwd/PhoneCode/OAuth/PhoneSetUsername/OAuthSetInfo） |
| `auth/config/SecurityConfig.java` | Spring Security：BCrypt、无状态会话、401/403 JSON、白名单 |
| `auth/config/RsaKeyConfig.java` | RSA 密钥配置（私钥签名） |
| `auth/config/RedisConfig.java` | Redis 配置 |
| `auth/config/MyBatisPlusConfig.java` | MyBatis-Plus 配置 |
| `auth/config/VerificationCodeProperties.java` | 验证码配置（过期/间隔/长度/模拟开关） |
| `auth/config/PasswordProperties.java` | 密码策略配置（长度范围） |
| `auth/config/OAuth2Config.java` | OAuth 提供商配置 |
| `auth/util/JwtUtils.java` | JWT RS256 双 Token 工具类 |
| `auth/vo/PermissionVO.java` | 权限视图对象（树形） |

## cloudoffice-biz-service（企业服务，端口 9200，骨架）
| 路径 | 说明 |
|------|------|
| `biz/BizApplication.java` | 企业服务启动类 |
| `biz/controller/HealthController.java` | 健康检查端点（企业信息/人事管理骨架预留） |

## cloudoffice-system-service（系统服务，端口 9400，骨架）
| 路径 | 说明 |
|------|------|
| `system/SystemApplication.java` | 系统服务启动类 |
| `system/controller/HealthController.java` | 健康检查端点（系统配置/日志/监控/定时任务骨架预留） |

## cloudoffice-flutter-app（Flutter 客户端）
| 路径 | 说明 |
|------|------|
| `lib/main.dart` / `lib/app.dart` | 应用入口 |
| `lib/core/http/api_client.dart` | HTTP 客户端封装 |
| `lib/core/http/api_interceptor.dart` | 请求拦截器（Token 注入/刷新） |
| `lib/core/http/api_result.dart` | 响应体模型（对齐后端 ApiResult） |
| `lib/core/router/app_router.dart` | 路由配置 |
| `lib/core/storage/secure_storage.dart` | 安全存储（Token） |
| `lib/core/utils/validators.dart` | 输入校验工具 |
| `lib/config/api_config.dart` | 后端 API 地址配置 |
| `lib/config/theme_config.dart` | 主题配置 |
| `lib/features/auth/` | 认证模块：screens（登录/注册/找回密码）、providers、models（LoginRequest/RegisterRequest/TokenPair/UserInfo 等）、repositories（AuthRepository） |
| `lib/features/home/` | 首页模块（screens + providers） |
| `lib/shared/widgets/` | 通用组件：密码框、验证码框、密码强度指示、加载按钮、自定义文本框 |
| `lib/shared/constants/app_constants.dart` | 应用常量 |

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
