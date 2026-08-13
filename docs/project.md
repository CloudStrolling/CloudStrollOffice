# 项目基本信息
**项目中文名称**：云漫智企
**项目英文名称**：CloudStrollOffice
**项目英文缩写**：cso
**编程语言**：Java 21（后端，Spring Boot 3.2.5 / Spring Cloud 2023.0.1）；Dart 3（客户端，Flutter，SDK ^3.12.2）
**项目类型**：微服务企业办公套件（Maven 多模块后端微服务集群 + Flutter 多端客户端）
**本地化语言**：简体中文
**总体介绍**：云漫智企（CloudStrollOffice）是基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务企业办公套件。后端采用 Maven 多模块架构，由公共模块（common）、API 网关（gateway）、认证服务（auth-service）、企业服务（biz-service）、系统服务（system-service）组成，配套 Flutter 客户端（cloudoffice-flutter-app，支持 Web 与 Windows 双平台）。系统为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力：已实现 RBAC 多租户权限模型（用户-角色-权限三层关联 + 租户数据隔离）、6 种客户端类型混合登录、JWT RS256 双 Token（Access 2h + Refresh 7d + 轮换）、Redis 会话管理（登录态/黑名单/状态缓存）、网关 AuthFilter 全局认证（9 步校验 + 用户信息 Header 透传）、多模式登录/注册（策略工厂模式）、密码管理、手机号变更、验证码管理等能力。基础设施依赖 MariaDB 10.6（业务数据）、Redis 7.2（会话缓存）、Nacos 2.3（注册/配置中心），支持 Docker Compose 一键编排部署。

# 数据库信息
**是否使用数据库**：是
**数据库产品**：MariaDB（业务关系型数据库，认证库 `cloudstroll_office_auth` 9 张表；biz/system 库预留）
**数据库版本**：10.6 (LTS)
**缓存数据库**：Redis 7.2.x（登录态会话、Token 黑名单、账号/租户状态缓存、验证码存储）

# 编码规范
## 文件组织规范
- 后端按 Maven 多模块组织：公共代码统一放 `cloudoffice-common`，各业务模块（auth/biz/system）只依赖 common，禁止模块间互相依赖与循环依赖；包根为 `org.cloudstrolling.cloudoffice.{模块}`。
- 模块内按职责分层组织：`config/`（配置）、`controller/`（接口层）、`service/`（业务层，接口与 impl 分离）、`mapper/`（数据访问）、`entity/`（实体）、`dto/`（请求/响应）、`vo/`（视图对象）、`util/`（工具）。
- 客户端独立 Flutter 工程 `cloudoffice-flutter-app`，按 Flutter 标准目录组织（lib/、test/、web/、windows/）。
- 数据库脚本放 `scripts/sql/`，Docker 编排放 `scripts/docker/`，部署脚本放 `scripts/`。
## 命名规范
- 类名/接口名 UpperCamelCase，方法名/变量名 lowerCamelCase，常量 UPPER_SNAKE_CASE；遵循 Java 与 Dart 社区命名约定。
- 接口命名不带 I 前缀（如 `UserService` / `UserServiceImpl`），实体以 `Entity` 后缀（如 `UserEntity`），Mapper 以 `Mapper` 后缀。
- API 路径统一规范：`/api/v1/{module}/{resource}`。
## 代码风格
- 遵循《阿里巴巴 Java 开发手册》，已配置 `checkstyle.xml` 与 `.editorconfig` 强制执行。
- 缩进 4 个空格、禁止 Tab；文件编码统一 UTF-8；行宽不超过 120 字符；大括号采用 K&R 风格。
- 使用 Lombok（@Data、@Slf4j、@Builder 等）减少样板代码；统一使用构造器注入替代 @Autowired 字段注入。
## 注释规范
- 关键类、方法、复杂业务逻辑必须有简体中文注释；注释说明"为什么"而非"是什么"。
- 文件头保留 SPDX-License-Identifier 与版权声明。
## 日志规范
- 使用 Lombok @Slf4j 统一日志，级别规范（DEBUG/INFO/WARN/ERROR）；关键业务路径（登录、注册、鉴权、异常）必须记录日志。
- 禁止输出敏感信息（密码、Token、RSA 私钥等），Token 签名等敏感值记录时需脱敏。
## 测试规范
- 单元测试使用 JUnit 5 + Mockito（Spring Boot Starter Test），测试类位于各模块 `src/test/java`；客户端使用 flutter_test + mockito。
- 编码前先编写测试用例（测试先行），编码后测试必须全部通过。
## 统一错误处理规范
- 统一响应体 `ApiResult<T>`（状态码、消息、数据、时间戳）；分页响应统一 `PageResult<T>`。
- 异常体系统一：`BaseException` → `BusinessException` / `AuthException`，错误码统一在 `ErrorCode` 枚举（含 29 个错误码）；接口层由 `@RestControllerAdvice` 全局异常处理器统一兜底，禁止吞异常、禁止向客户端泄露堆栈信息。
## 其他规范
- 禁止提交密钥、密码等敏感信息：RSA 密钥对、数据库密码等通过环境变量注入（`env.json` / `env.example.json` 模板管理，密钥文件放 `keys/` 并加入 .gitignore）；不提交日志与临时文件。
- 提交信息遵循 Conventional Commits 规范（feat:/fix:/docs:/refactor:/test:/chore:）。

# 项目地图
（由 impm-project-update 技能在 v0.2.8 通过扫描源码目录维护：impm_project_analyzer 扫描 368 个文件（Java/Python/SQL/YAML/Config/C/C++ 等）；deploy/scripts 下 .ps1/.sh 脚本 34 个（扫描器不识别 PowerShell/Bash，由 SA 手动提取补全），合计约 402 个文件。v0.2.8 核心变化：cloudoffice-common 从纯 JAR 库升级为可独立启动的微服务，新增通用配置管理接口（t_common_config 表 + Redis 缓存）；deploy/scripts 新增 common 服务启停脚本与 deploy-stop-all 脚本、serve-web 脚本；gateway 新增 common 服务路由。）

## cloudoffice-common/ — 公共模块微服务（端口 9300，v0.2.8 升级为可独立启动的微服务）
- `CommonApplication.java` — 公共模块服务启动类（v0.2.8 新增，@SpringBootApplication + main 方法）
- `application.yml` / `bootstrap.yml` — 服务配置（v0.2.8 新增，接入 t_common_config 数据源与 Redis 本地缓存、Nacos 注册配置）
- `cache/ConfigCacheManager.java` — 通用配置缓存管理器：getCachedConfigs/cacheConfigs/evict（v0.2.8 新增，Redis 缓存读写与容错）
- `config/ConfigProperties.java` — 通用配置管理属性（v0.2.8 新增，缓存 TTL、敏感配置脱敏等可配置项）
- `config/MyBatisPlusConfig.java` — MyBatis-Plus 配置（自动填充处理器 insertFill/updateFill + 分页插件）
- `config/RedisConfig.java` — Redis 配置类（v0.2.8 新增，common 服务独立 RedisTemplate）
- `config/SpringDocConfig.java` — SpringDoc OpenAPI 3 配置，按模块分组（auth/biz/cloud/system）
- `constant/RedisKeyConstants.java` — Redis Key 常量与构建（会话/黑名单/状态/验证码/配置缓存，v0.2.8 新增 buildConfigCacheKey）
- `controller/ConfigController.java` — 通用配置管理控制器：queryConfigList/queryConfigsByService（v0.2.8 新增，只读查询接口，无写入端点）
- `controller/HealthController.java` — 健康检查控制器（v0.2.8 新增，health 端点）
- `dto/LoginUserDTO.java`、`dto/TokenPairDTO.java` — 登录用户信息、双 Token 传输对象（v0.2.6 调整 LoginUserDTO 以支持网关透传）
- `entity/ConfigEntity.java` — 通用配置实体（t_common_config 表映射，v0.2.8 新增）
- `enums/ClientTypeEnum.java` — 6 种客户端类型枚举（Windows/Ubuntu/H5/Android/iOS/WeChatMini，含 DeviceCategory 同端互斥逻辑）
- `enums/LoginModeEnum.java`、`enums/RegisterModeEnum.java`、`enums/OAuthProviderEnum.java` — 登录/注册/OAuth 提供商枚举
- `exception/` — 异常体系：`ErrorCode`（29 个错误码）、`BaseException`、`BusinessException`、`AuthException`、`GlobalExceptionHandler`（@RestControllerAdvice 统一兜底 14 类异常：MethodArgumentNotValid/Bind/ConstraintViolation 参数校验、Business/Auth 业务认证异常、BadCredentials 凭证错误、AccessDenied 越权、MethodNotSupported 405、NoHandlerFound 404、MissingRequestHeader/MissingServletRequestParameter 缺参、TypeMismatch 类型不匹配、HttpMessageNotReadable 请求体解析失败、兜底 Exception 500）
- `mapper/ConfigMapper.java` — 通用配置 Mapper（t_common_config，v0.2.8 新增）
- `model/ApiResult.java`（统一响应体）、`model/PageResult.java`（分页响应）、`model/BaseEntity.java`（实体基类）、`model/ErrorCode.java`
- `service/ConfigService.java` — 通用配置管理服务：queryConfigList/queryConfigsByService/loadConfigsByService/queryEnabledConfigs/validateServiceName/toConfigItemVO（v0.2.8 新增，含缓存优先/回填/敏感配置脱敏逻辑）
- `util/JsonUtils.java` — JSON 工具类
- `vo/ConfigItemVO.java` — 通用配置项视图对象（v0.2.8 新增）
- `src/test/` — 20 个测试类（v0.2.8 新增 7 个：ConfigCacheManagerTest、CommonApplicationConfigTest、ConfigPropertiesTest、ConfigControllerTest、HealthControllerTest、ConfigMapperTest、ConfigServiceTest；原有 13 个：MyBatisPlusConfigTest、RedisKeyConstantsTest、LoginUserDTOTest、TokenPairDTOTest、ClientTypeEnumTest、BaseExceptionTest、BusinessExceptionTest、ErrorCodeTest、GlobalExceptionHandlerTest、ApiResultTest、BaseEntityTest、PageResultTest、JsonUtilsTest）

## cloudoffice-gateway/ — API 网关（端口 9000）
- `GatewayApplication.java` — 网关启动类
- `pom.xml` — 网关依赖（Spring Cloud Gateway、ReactiveRedis、RS256 验签依赖，v0.2.6 调整）
- `config/AuthProperties.java`（认证白名单等属性）、`config/RedisConfig.java`（ReactiveRedis）、`config/RsaKeyConfig.java`（RS256 公钥 PEM 加载与校验）
- `filter/AuthFilter.java` — 全局认证过滤器：getOrder/filter 9 步校验（白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传），辅助方法 checkBlacklist/checkSession/checkAccountStatus/checkTenantStatus/isWhiteListPath/parseToken/getTokenSignature/commaSeparateClaim/getAccountStatusError/getTenantStatusError/forwardWithHeaders/writeErrorResponse
- `application.yml` — RSA 公钥配置与认证白名单（v0.2.6 更新；v0.2.8 新增 common 服务化路由：/api/v1/common/** 转发到 cloudoffice-common，common 健康检查路径加入白名单）
- `src/test/` — 6 个测试类（GatewayApplicationTest、AuthPropertiesTest、RedisConfigTest、RsaKeyConfigTest、AuthFilterTest、TestRsaKeyProvider；v0.2.8 AuthFilterTest 新增 common 健康检查白名单与 common 配置接口鉴权回归用例）

## cloudoffice-auth-service/ — 认证服务（端口 9100，核心业务模块）
- `AuthApplication.java` — 启动类
- `config/` — `SecurityConfig`（Spring Security 安全过滤链 + BCrypt 密码编码器）、`RsaKeyConfig`（RS256 密钥对）、`RedisConfig`、`MyBatisPlusConfig`、`PasswordProperties`（密码策略）、`VerificationCodeProperties`（验证码配置）、`OAuth2Config`（OAuth2 授权服务器骨架）
- `controller/AuthController.java` — 认证端点：login/register/refresh/logout/kickout/changePassword/forgotPasswordSendCode/forgotPasswordReset/changePhone/accountSettlement/sendVerificationCode/getCurrentUserId
- `controller/UserController.java` — 用户管理：getUserById/updateUser/deleteUser/assignRoles/updateStatus
- `controller/RoleController.java`、`controller/PermissionController.java`（tree/list/getById/create/update/delete）、`controller/HealthController.java`（health）
- `entity/` — 9 个实体：UserEntity、TenantEntity、RoleEntity、PermissionEntity、UserRoleEntity、RolePermissionEntity、LoginLogEntity、OAuthAccountEntity、VerificationCodeEntity
- `dto/` — 12 个请求 DTO：LoginRequest、RegisterRequest、RefreshTokenRequest、KickoutRequest、PasswordChangeRequest、PasswordForgotRequest、PhoneChangeRequest、AccountSettlementRequest、SendVerificationCodeRequest、UserStatusRequest、UserUpdateRequest、AssignRolesRequest；`dto/result/AuthResult.java`、`dto/result/RegisterResult.java`
- `mapper/` — 9 个 Mapper 接口（UserMapper/TenantMapper/RoleMapper/PermissionMapper/UserRoleMapper/RolePermissionMapper/LoginLogMapper/OAuthAccountMapper/VerificationCodeMapper）
- `service/`（接口 + impl）：
  - `AuthenticationService` — 认证编排服务：authenticate/register 统一编排登录注册，checkTenantStatus/checkUserStatus/processMutualExclusion/getClientIp
  - `LoginService` + `LoginServiceImpl` — 登录认证：login/logout/kickout 全流程 + getCurrentOperator/isAdmin/recordKickoutLog（操作者识别与踢出审计）
  - `LoginSessionService` + `LoginSessionServiceImpl` — Redis 会话管理：createSession/getSession/removeSession/removeAllSessions/addToBlacklist/isBlacklisted/账号租户状态缓存（maskSignature 脱敏）
  - `TokenService` + `TokenServiceImpl` — 双 Token 签发与轮换：refresh/parseAndValidateRefreshToken + checkUserStatus/checkTenantStatus/calculateRemainingSeconds/maskSignature（刷新时复核账号租户状态）
  - `PasswordService` — 密码管理：changePassword/forgotPasswordSendCode/forgotPasswordReset/changePhone
  - `VerificationCodeManager` + `VerificationCodeManagerImpl` — 验证码管理器：generateCode/verifyCode/isSendTooFrequent/cleanExpiredCodes
  - `VerificationCodeService` + `SimulatedVerificationCodeService` — 验证码发送（模拟模式 sendSmsCode/sendEmailCode）
  - `UserService` + `UserServiceImpl` — 用户管理：register/update/delete/updateStatus/banUser/unbanUser/lockUser/unlockUser/list/assignRoles/accountSettlement/assignDefaultRole
  - `RoleService` + `RoleServiceImpl` — 角色管理：list/listAll/findById/create/update/delete/assignPermissions/checkRoleCodeUnique
  - `PermissionService` + `PermissionServiceImpl` — 权限管理：tree/listAll/findById/create/update/delete/checkPermCodeUnique/convertToVO
  - `LoginLogService` + `LoginLogServiceImpl` — 登录日志审计：recordLoginSuccess/recordLoginFailure/updateLogoutTime
- `service/strategy/` — 策略模式（工厂 + 策略实现）：
  - 登录 4 策略：UsernamePasswordStrategy、PhoneCodeLoginStrategy、PhonePasswordLoginStrategy、OAuthLoginStrategy（LoginStrategyFactory 装配）
  - 注册 5 策略：UsernamePwdRegisterStrategy、PhoneCodeRegisterStrategy、OAuthRegisterStrategy、PhoneSetUsernameStrategy、OAuthSetInfoStrategy（RegisterStrategyFactory 装配，含两步注册）
- `util/JwtUtils.java` — JWT RS256 双 Token 工具：generateAccessToken/generateRefreshToken/parseAccessToken/parseRefreshToken/getTokenSignature/getAccessTokenExpiration/getRefreshTokenExpiration/parseToken
- `vo/PermissionVO.java` — 权限视图对象
- `src/test/` — 29 个测试类（AuthApplicationTest、RsaKeyConfigTest、SecurityConfigTest、AuthControllerTest、UserControllerTest、RoleControllerTest、PermissionControllerTest、HealthControllerTest、AuthenticationServiceTest、PasswordServiceTest、LoginLogServiceImplTest、LoginServiceImplTest、LoginSessionServiceImplTest、RoleServiceImplTest、TokenServiceImplTest、UserServiceImplTest、VerificationCodeManagerImplTest、LoginStrategyFactoryTest、RegisterStrategyFactoryTest、UsernamePasswordStrategyTest、PhoneCodeLoginStrategyTest、PhonePasswordLoginStrategyTest、OAuthLoginStrategyTest、UsernamePwdRegisterStrategyTest、PhoneCodeRegisterStrategyTest、OAuthRegisterStrategyTest、PhoneSetUsernameStrategyTest、OAuthSetInfoStrategyTest、JwtUtilsTest）

## cloudoffice-biz-service/ — 企业服务（端口 9200，骨架）
- `BizApplication.java` — 启动类
- `controller/HealthController.java` — 健康检查（health）
- 企业信息管理、人事管理等业务功能待版本迭代填充
- `src/test/` — 2 个测试类（BizApplicationTest、HealthControllerTest）

## cloudoffice-system-service/ — 系统服务（端口 9400，骨架）
- `SystemApplication.java` — 启动类
- `controller/HealthController.java` — 健康检查（health）
- 系统配置、日志、监控、定时任务等功能待版本迭代填充
- `src/test/` — 2 个测试类（SystemApplicationTest、HealthControllerTest）

## cloudoffice-flutter-app/ — Flutter 客户端（独立工程，Web + Windows 双平台）
- `pubspec.yaml` — 依赖：dio 5.4（网络）、provider 6.1（状态管理）、go_router 14.2（路由）、flutter_secure_storage_x 13.1（Token 安全存储）、shared_preferences 2.2（本地配置）；dev：flutter_lints 6.0、mockito 5.4
- `lib/main.dart` — 应用入口（main）；`lib/app.dart` — 根组件 CloudStrollOfficeApp
- `lib/config/` — `ApiConfig`（API 地址配置）、`ThemeConfig`（主题配置）
- `lib/core/http/` — `ApiClient`（dio 封装 get/post/put/delete）、`ApiInterceptor`（Token 注入、白名单、401 自动刷新与请求排队）、`ApiResult`（响应模型）
- `lib/core/router/` — `AppRouter`（go_router 路由表）；`lib/core/storage/SecureStorage`（Token 安全存储 save/get/clear）；`lib/core/utils/Validators`（校验与密码强度计算）
- `lib/features/auth/models/` — 7 个模型：LoginRequest、RegisterRequest、TokenPair、UserInfo、PasswordForgotRequest、SendVerificationCodeRequest、RegisterResult
- `lib/features/auth/providers/` — `AuthProvider`（login/loginWithSmsCode/register/registerWithPhone/logout/checkLoginStatus）、`ForgotPasswordProvider`（三步找回：sendVerificationCode/verifyIdentity/resetPassword）
- `lib/features/auth/repositories/` — `AuthRepository`（认证接口访问）；`lib/features/auth/screens/` — LoginScreen、RegisterScreen、ForgotPasswordScreen
- `lib/features/home/` — `providers/HomeProvider`（loadUserInfo/logout）、`screens/HomeScreen`（用户信息展示）
- `lib/shared/` — `constants/AppConstants`、`widgets/`（CustomTextField、LoadingButton、PasswordField、PasswordStrengthIndicator、VerificationCodeField）
- `test/` — 27 个测试文件（widget_test、各 config/core/features/shared 单元测试，含 StubAuthRepository、ApiClientSpy 等测试替身）

## deploy/ — 部署工程目录（v0.2.7 重构，v0.2.8 扩展 common 服务支持）
- `env.json` / `env.example.json` — 环境配置文件（Nacos 地址/安装目录、DB/Redis 主机端口口令与服务进程名、RSA 密钥、验证码/密码策略等；v0.2.8 新增 common 服务相关环境变量；env.json 不入库，缺失时 load-env 提示复制模板）
- `scripts/` — 部署脚本体系（.ps1 与 .sh 双平台版本，功能与契约一致），均基于 env.json 经 load-env 统一加载，输出分级（通过/警告/失败）与退出码约定 F-011：
  - `load-env.ps1` / `load-env.sh` — 统一配置加载模块（F-001）：env.json 键值注入环境变量、键名白名单校验、缺失兜底退出
  - `deploy-check-env.ps1` / `.sh` — 环境可用性检查与运行状态检测（F-002~F-006）：JDK（命令/JAVA_HOME/版本 21）、MariaDB/Redis（命令/系统服务/进程三重安装检测 + SELECT 1 / redis-cli ping）、Nacos（NACOS_HOME 检查 + HTTP 探测），只检查不启动
  - `deploy-start-services.ps1` / `.sh` — 基础设施运行状态检查与一键启动（F-006/F-007）：未安装不启动并报失败、已运行幂等跳过、未运行按 MariaDB → Redis → Nacos 顺序自动启动（系统服务 → 可执行文件，Nacos 走 startup 脚本），启动后循环探测确认
  - `deploy-start-all.ps1` / `.sh` — 后端服务按序一键启动（F-008）：前置校验（JDK + 5 个 jar + 关键环境变量）→ 按 common(9300) → gateway(9000) → auth(9100) → biz(9200) → system(9400) 顺序后台启动（v0.2.8 新增 common 为第一位执行，java -Xms256m -Xmx512m，日志/PID 落 deploy/logs/）→ 每服务 HTTP 健康确认（可配置重试次数/间隔/超时）成功后再启动下一个，任一步失败即停
  - `deploy-start-common.ps1` / `.sh` — common 单服务启动脚本（v0.2.8 新增），行为与 deploy-start-all 中 common 服务一致
  - `deploy-start-gateway.ps1` / `.sh`、`deploy-start-auth.ps1` / `.sh`、`deploy-start-biz.ps1` / `.sh`、`deploy-start-system.ps1` / `.sh` — 单服务启动脚本（F-009），行为与 deploy-start-all 中各服务一致（v0.2.7 重构，system 为新增）
  - `deploy-stop-all.ps1` / `.sh` — 全部后端服务一键停止（v0.2.8 新增）：按 system → biz → auth → gateway → common 逆序停止，PID 文件清理
  - `deploy-stop-common.ps1` / `.sh` — common 单服务停止脚本（v0.2.8 新增）
  - `deploy-db-init.ps1` / `.sh` — 数据库初始化（F-010，执行 scripts/sql 下建库脚本）
  - `deploy-rsa-keygen.ps1` / `.sh` — RSA 密钥对生成（生成 PEM/DER/Base64 至 deploy/keys/，输出契约 v0.2.7 对齐）
  - `build-backend.ps1` / `.sh` — 后端 Maven 一键构建（v0.2.8 包含 common 模块）；`build-client.ps1` / `.sh` — Flutter 客户端一键构建
  - `serve-web.ps1` / `.sh` — Flutter Web 静态资源服务脚本（v0.2.8 新增）
  - `usage.md` — 部署脚本使用说明文档（v0.2.8 新增）
- `deploy.md` / `build.md` — 部署方案与编译方案文档（v0.2.8 更新 common 服务编译与部署流程；对应主文档 docs/{cso}-deploy.md 的版本化副本）
- `logs/` — 运行日志与 PID 文件（*-start.log/.err、*.pid；不入库，.gitignore 已排除）
- `keys/` — RSA 密钥产物（PEM/DER/Base64；敏感不入库）
- `cloudoffice-*.jar` — 后端构建产物（common/gateway/auth/biz/system 5 个 jar；v0.2.8 新增 common；不入库）
- `cloudoffice-flutter-app/` — 客户端构建产物（web/ 与 windows/ 发布包；不入库，仅保留 .gitkeep）
- `surefire-reports/`、`test-output/`、`test-results/` — Maven 测试报告输出（不入库）

## scripts/ — 工程辅助目录（v0.2.7 调整：部署脚本已迁移至 deploy/scripts）
- `API-TEST/` — 接口测试脚本（cso-api-test-v0.0.1/v0.2.5/v0.2.6/v0.2.7/v0.2.8.py、test_auth_api.py，版本回归接口测试；v0.2.8 新增 common 健康检查白名单、common 配置接口鉴权、编译脚本检查、启停脚本检查、环境配置检查、文档检查等用例）
- `docker/docker-compose.yml` — 基础设施 Docker Compose 编排（MariaDB/Redis/Nacos）
- `sql/` — 数据库脚本（auth-init-v0.1.5/v0.1.6.sql、init-v0.2.0-full.sql、init.sql）
- `deployment-guide.md` — 部署指南（与 docs/deployment-guide.md 同步维护）

## 根目录关键文件与目录
- `pom.xml` — Maven 父 POM（groupId: org.cloudstrolling，统一依赖管理；v0.2.8 common 模块 packaging 从 jar 调整为可启动服务）
- `checkstyle.xml` / `.editorconfig` — 代码风格与规范配置
- `.gitignore` — v0.2.7 治理：排除生成/测试/调试临时与中间文件（*.jar/*.log/*.err/*.pid、logs/、keys/、env.json、target/、surefire-reports/、test-output/、test-results/、deploy/cloudoffice-flutter-app/web|windows/*、work/、docs2/ 等，产物不入库仅保留 .gitkeep 占位）
- `deploy/` — 部署工程目录（v0.2.7 起部署脚本与构建产物统一收纳，v0.2.8 扩展 common 服务支持，见上方 deploy/ 章节）
- `keys/` — RSA 密钥对存放目录（敏感，不入库）
- `scripts/` — 工程辅助目录：API 测试（API-TEST/）、Docker 编排（docker/）、SQL 脚本（sql/）、部署指南（deployment-guide.md）；部署脚本已迁移至 deploy/scripts（v0.2.7）
- `docs/` — 项目文档（project.md、sad.md、版本目录等）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->