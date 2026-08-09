# 任务上下文（#TASK-002 统一 RSA 密钥格式契约为 DER 编码单行 Base64（deploy-rsa-keygen.ps1 + deploy/env.json））

## 1. 任务信息

```json
{
  "id": "TASK-002",
  "title": "统一 RSA 密钥格式契约为 DER 编码单行 Base64（deploy-rsa-keygen.ps1 + deploy/env.json）",
  "description": "修复 v0.0.1 基线遗留缺陷（v0.2.5 回归报告审核项 T-02，SAD ADR-015，PRD F-002）：采用方案 A（脚本侧修复）——修改 deploy/scripts/deploy-rsa-keygen.ps1，生成 RSA 2048 密钥对后输出 DER 编码单行 Base64（公钥 X.509 SubjectPublicKeyInfo / 私钥 PKCS#8 PrivateKeyInfo 经 Base64 编码，无 -----BEGIN/END----- 头尾标记、无换行符），并更新 deploy/env.json 中 RSA_PUBLIC_KEY/RSA_PRIVATE_KEY 的注入值（覆盖旧 PEM 整体 Base64）。修复后 env.json 注入值与 Java 端 RsaKeyConfig 解码契约（Base64.getDecoder() + X509EncodedKeySpec/PKCS8EncodedKeySpec）严格一致，消除网关启动报错 RSA 公钥解析失败（Unable to decode key / extra data at the end）。私钥不得入库、不得写入日志；数据库/Redis/Nacos 连接参数保持不变。",
  "taskType": "common",
  "userStoryId": "US-002",
  "apiId": "",
  "upstreamTaskIds": [],
  "downstreamTaskIds": [
    "TASK-003"
  ],
  "priority": "P0",
  "status": "未完成",
  "testMethod": "契约校验：脚本输出/env.json 值不含 -----BEGIN/-----END 子串、不含换行符、可被 Base64.getDecoder() 严格解码；启动验证：网关启动无 RSA 公钥解析失败",
  "acceptanceCriteria": "1. deploy-rsa-keygen.ps1 输出为 DER 编码单行 Base64（无 PEM 头尾、无换行）；2. deploy/env.json 的 RSA_PUBLIC_KEY/RSA_PRIVATE_KEY 已更新为 DER 单行 Base64 并与其严格一致；3. 注入后可被 Java 端严格 Base64 解码构造密钥（X509/PKCS8EncodedKeySpec）；4. 网关启动无 RSA 公钥解析失败，RS256 签名验签链路正常；5. 私钥不写入日志、不进入代码仓库"
}
```

## 2. 用户需求

### US-002：统一 RSA 密钥格式契约，消除公钥解析失败
#### 故事描述
作为（运维/部署人员），我想要（deploy-rsa-keygen.ps1 生成的 RSA 密钥格式与 Java 端解码逻辑一致），以便（env.json 注入的密钥可被 gateway/auth 正确解析，服务不再因 `RSA 公钥解析失败` 而崩溃）。
#### 前置条件
- 已定位 deploy/env.json 中 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 PEM 整体 Base64（多行、含 BEGIN/END）与 Java 端严格 Base64 解码契约不一致的根因。
#### 验收标准
- [ ] Given 采用方案 A（脚本侧修复），When 重新执行 deploy-rsa-keygen.ps1 生成密钥，Then 输出为 DER 编码单行 Base64（无 PEM 头尾、无换行），env.json 注入后网关启动无 `RSA 公钥解析失败`
- [ ] Given 采用方案 B（代码侧兼容），When 修改 RsaKeyConfig 使用 MIME 解码并剥离 PEM 头尾，Then 原 env.json 的 PEM Base64 密钥可被正确解析，网关启动正常
- [ ] Given 网关与 auth 服务启动成功，When 使用签名密钥完成登录签发与网关验签，Then RS256 签名验签链路正常工作（Token 可签发、可验证）
- [ ] Given 密钥修复完成，When 检查日志与代码仓库，Then 私钥不写入日志、不进入代码仓库
#### 边界情况与错误处理
| 场景 | 预期处理 |
| --- | --- |
| 密钥为多行 Base64 且含 \r\n | 方案 A 下解码失败，需重新生成单行格式；方案 B 下自动剥离 |
| 公钥与私钥不配对 | 网关验签失败，请求返回 401，需成对生成密钥 |
| 密钥文件损坏/截断 | 解析抛异常，服务启动失败，需重新生成并注入 |
| 两端契约不一致的配置残留 | 部署文档同步说明格式要求，env.json 以统一契约为准 |
#### 关联功能编号
F-002、F-003

## 3. 项目信息

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
（由 impm-project-update 技能在 v0.2.5 通过扫描源码目录维护：impm_project_analyzer 扫描 177 个文件，另含 Flutter Dart 源码 58 个文件（扫描器不识别 .dart，由 SA 手动提取声明补全），合计 235 个文件。）

## cloudoffice-common/ — 公共模块（JAR，无启动类）
- `config/MyBatisPlusConfig.java` — MyBatis-Plus 自动填充处理器（insertFill/updateFill 元数据填充）
- `config/SpringDocConfig.java` — SpringDoc OpenAPI 3 配置，按模块分组（auth/biz/cloud/system）
- `constant/RedisKeyConstants.java` — Redis Key 常量与构建（会话/黑名单/状态/验证码）
- `dto/LoginUserDTO.java`、`dto/TokenPairDTO.java` — 登录用户信息、双 Token 传输对象
- `enums/ClientTypeEnum.java` — 6 种客户端类型枚举（Windows/Ubuntu/H5/Android/iOS/WeChatMini，含 DeviceCategory 同端互斥逻辑）
- `enums/LoginModeEnum.java`、`enums/RegisterModeEnum.java`、`enums/OAuthProviderEnum.java` — 登录/注册/OAuth 提供商枚举
- `exception/` — 异常体系：`ErrorCode`（29 个错误码）、`BaseException`、`BusinessException`、`AuthException`、`GlobalExceptionHandler`（@RestControllerAdvice 统一兜底 13 类异常）
- `model/ApiResult.java`（统一响应体）、`model/PageResult.java`（分页响应）、`model/BaseEntity.java`（实体基类）、`model/ErrorCode.java`
- `util/JsonUtils.java` — JSON 工具类
- `src/test/` — 13 个测试类（MyBatisPlusConfigTest、RedisKeyConstantsTest、LoginUserDTOTest、TokenPairDTOTest、ClientTypeEnumTest、BaseExceptionTest、BusinessExceptionTest、ErrorCodeTest、GlobalExceptionHandlerTest、ApiResultTest、BaseEntityTest、PageResultTest、JsonUtilsTest）

## cloudoffice-gateway/ — API 网关（端口 9000）
- `GatewayApplication.java` — 网关启动类
- `config/AuthProperties.java`（认证白名单等属性）、`config/RedisConfig.java`（ReactiveRedis）、`config/RsaKeyConfig.java`（RS256 公钥 PEM 加载与校验）
- `filter/AuthFilter.java` — 全局认证过滤器：getOrder/filter 9 步校验（白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单 → 登录态 → 账号状态 → 租户状态 → Header 透传），辅助方法 checkBlacklist/checkSession/checkAccountStatus/checkTenantStatus/isWhiteListPath/parseToken/getTokenSignature/forwardWithHeaders/writeErrorResponse
- `src/test/` — 6 个测试类（GatewayApplicationTest、AuthPropertiesTest、RedisConfigTest、RsaKeyConfigTest、AuthFilterTest、TestRsaKeyProvider）

## cloudoffice-auth-service/ — 认证服务（端口 9100，核心业务模块）
- `AuthApplication.java` — 启动类
- `config/` — `SecurityConfig`（Spring Security + BCrypt）、`RsaKeyConfig`（RS256 密钥对）、`RedisConfig`、`MyBatisPlusConfig`、`PasswordProperties`（密码策略）、`VerificationCodeProperties`（验证码配置）、`OAuth2Config`（OAuth2 授权服务器骨架）
- `controller/AuthController.java` — 认证端点：login/register/refresh/logout/kickout/changePassword/forgotPasswordSendCode/forgotPasswordReset/changePhone/accountSettlement/sendVerificationCode
- `controller/UserController.java` — 用户管理：getUserById/updateUser/deleteUser/assignRoles/updateStatus
- `controller/RoleController.java`、`controller/PermissionController.java`（tree/list/create）、`controller/HealthController.java`（health）
- `entity/` — 9 个实体：UserEntity、TenantEntity、RoleEntity、PermissionEntity、UserRoleEntity、RolePermissionEntity、LoginLogEntity、OAuthAccountEntity、VerificationCodeEntity
- `dto/` — 12 个请求 DTO：LoginRequest、RegisterRequest、RefreshTokenRequest、KickoutRequest、PasswordChangeRequest、PasswordForgotRequest、PhoneChangeRequest、AccountSettlementRequest、SendVerificationCodeRequest、UserStatusRequest、UserUpdateRequest、AssignRolesRequest；`dto/result/AuthResult.java`、`dto/result/RegisterResult.java`
- `mapper/` — 9 个 Mapper 接口（UserMapper/TenantMapper/RoleMapper/PermissionMapper/UserRoleMapper/RolePermissionMapper/LoginLogMapper/OAuthAccountMapper/VerificationCodeMapper）
- `service/`（接口 + impl）：
  - `AuthenticationService` — 认证编排服务：authenticate/register 统一编排登录注册，checkTenantStatus/checkUserStatus/processMutualExclusion
  - `LoginService` + `LoginServiceImpl` — 登录认证：login/logout/kickout 全流程
  - `LoginSessionService` + `LoginSessionServiceImpl` — Redis 会话管理：createSession/getSession/removeSession/removeAllSessions/addToBlacklist/isBlacklisted/账号租户状态缓存
  - `TokenService` + `TokenServiceImpl` — 双 Token 签发与轮换：refresh/parseAndValidateRefreshToken
  - `PasswordService` — 密码管理：changePassword/forgotPasswordSendCode/forgotPasswordReset/changePhone
  - `VerificationCodeManager` + `VerificationCodeManagerImpl` — 验证码管理器：generateCode/verifyCode/isSendTooFrequent/cleanExpiredCodes
  - `VerificationCodeService` + `SimulatedVerificationCodeService` — 验证码发送（模拟模式 sendSmsCode/sendEmailCode）
  - `UserService` + `UserServiceImpl` — 用户管理：register/banUser/unbanUser/lockUser/unlockUser/list/assignRoles/accountSettlement
  - `RoleService` + `RoleServiceImpl`、`PermissionService` + `PermissionServiceImpl`、`LoginLogService` + `LoginLogServiceImpl` — 角色/权限/登录日志审计
- `service/strategy/` — 策略模式（工厂 + 策略实现）：
  - 登录 4 策略：UsernamePasswordStrategy、PhoneCodeLoginStrategy、PhonePasswordLoginStrategy、OAuthLoginStrategy（LoginStrategyFactory 装配）
  - 注册 5 策略：UsernamePwdRegisterStrategy、PhoneCodeRegisterStrategy、OAuthRegisterStrategy、PhoneSetUsernameStrategy、OAuthSetInfoStrategy（RegisterStrategyFactory 装配，含两步注册）
- `util/JwtUtils.java` — JWT RS256 双 Token 工具：generateAccessToken/generateRefreshToken/parseAccessToken/parseRefreshToken/getTokenSignature
- `vo/PermissionVO.java` — 权限视图对象
- `src/test/` — 28 个测试类（AuthApplicationTest、RsaKeyConfigTest、SecurityConfigTest、AuthControllerTest、UserControllerTest、RoleControllerTest、PermissionControllerTest、HealthControllerTest、AuthenticationServiceTest、PasswordServiceTest、各 service/impl 测试、各 strategy 测试、JwtUtilsTest 等）

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

## 根目录关键文件与目录
- `pom.xml` — Maven 父 POM（groupId: org.cloudstrolling，统一依赖管理）
- `checkstyle.xml` / `.editorconfig` — 代码风格与规范配置
- `env.json` / `env.example.json` — 环境变量模板（数据库、Redis、RSA 密钥等）
- `keys/` — RSA 密钥对存放目录（敏感，不入库）
- `scripts/` — 部署脚本（deploy-*.ps1/sh）、SQL 脚本（sql/）、Docker 编排（docker/）、API 测试脚本（API-TEST/）
- `docs/` — 项目文档（project.md、sad.md、版本目录等）

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->

## 4. 系统架构相关

# 系统架构设计文档（SAD）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：0.2.6
**日期**：2026-08-09
**编写人**：SA

## 1. 设计目标与约束

### 1.2 设计约束（本任务相关摘录）
- **安全约束**：密码一律 BCrypt 加密存储，日志禁止输出密码与 Token；JWT 私钥仅存在于 auth-service（签名），公钥存在于 gateway 与 auth-service（验签）；密钥通过环境变量注入，禁止硬编码。RSA 密钥格式统一为 **DER 编码单行 Base64**（无 PEM 头尾标记、无换行）：deploy-rsa-keygen.ps1 生成/env.json 注入的 `RSA_PUBLIC_KEY`、`RSA_PRIVATE_KEY` 必须与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约严格一致，严禁将多行 PEM 整体 Base64（含 BEGIN/END 标记与 \r\n）直接注入 env.json（v0.2.6 修复 v0.0.1 基线遗留缺陷）。
- **部署资产约束**：最终构建产物（后端各服务 jar 包、客户端安装文件/exe）统一输出至根目录 `deploy` 目录；环境配置 `env.json`/`env.example.json` 与部署运维脚本（`deploy/scripts` 下的 .sh/.ps1）集中存放于 deploy 下；构建中间产物（target 目录、编译临时文件、测试产物）禁止进入 deploy。

## 7. 安全架构（本任务相关摘录）
- **认证机制**：JWT RS256 双 Token：Access Token 2 小时 + Refresh Token 7 天；刷新后旧 Refresh Token 立即入黑名单（防重放）；私钥仅存 auth-service，公钥存 gateway 与 auth-service。
- **数据安全**：JWT 密钥、数据库密码、Redis 密码一律通过环境变量注入，代码与配置文件不含真实密钥。RSA 密钥格式契约统一：`RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 采用 DER 编码单行 Base64（无 PEM 头尾、无换行），由 deploy-rsa-keygen.ps1 生成并注入 env.json，与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）解码契约严格一致；私钥不得入库、不得写入日志（v0.2.6 修复项）。

## 10. 架构决策记录（ADR）— ADR-015
| ADR-015 | RSA 密钥格式契约 | 统一 RSA 密钥格式为 DER 编码单行 Base64：deploy-rsa-keygen.ps1 输出/env.json 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）解码逻辑严格一致；禁止多行 PEM 整体 Base64 直接注入 | 原 env.json 注入 PEM 整体 Base64（多行、含 BEGIN/END）与 Java 严格解码契约不匹配，网关启动报 `RSA 公钥解析失败`（v0.0.1 基线遗留缺陷 T-02，v0.2.6 修复）；统一脚本输出契约可消除配置歧义，Java 端无需兼容代码、运行时代码零改动 | 2026-08-09 |

## 5. 任务关键设计要点（LLD v0.2.6 摘录）

### 5.1 RSA 密钥生成与注入（LLD 6.2，F-002）
```
功能：deploy-rsa-keygen.ps1 输出与 Java 端解码契约一致的 DER 单行 Base64 密钥
契约定义（SAD 安全约束，ADR-015）：
- RSA_PUBLIC_KEY  = Base64(DER 编码公钥 X.509 SubjectPublicKeyInfo)，单行
- RSA_PRIVATE_KEY = Base64(PKCS8 编码私钥 PrivateKeyInfo)，单行
- 无 "-----BEGIN/END PUBLIC KEY-----" 等 PEM 头尾标记
- 无 \r\n / \n 换行符

生成流程：
1. 生成 RSA 2048 密钥对
2. 公钥：DER 编码（X.509）→ Base64 编码（单行）→ RSA_PUBLIC_KEY
3. 私钥：PKCS8 编码（PKCS#8）→ Base64 编码（单行）→ RSA_PRIVATE_KEY
4. 写入 deploy/env.json（覆盖旧 PEM 整体 Base64 值）
5. 输出提示：密钥契约说明（单行、无头尾），供运维确认

校验（注入前）：
- 值不含 "-----BEGIN" / "-----END" 子串
- 值不含换行符（单行）
- 可被 Base64.getDecoder() 严格解码（无 extra data）
```

### 5.2 RsaKeyConfig 密钥解析（LLD 6.3，F-002，既有代码逻辑）
```
功能：gateway/auth 启动时从环境变量加载 RSA 密钥（本版本不改代码，契约由脚本侧对齐）

逻辑（既有，保持不动）：
1. 读环境变量 RSA_PUBLIC_KEY / RSA_PRIVATE_KEY（或 @Value 注入）
2. decodePublicKey：Base64.getDecoder().decode(RSA_PUBLIC_KEY) → X509EncodedKeySpec → KeyFactory RSA 生成公钥
3. decodePrivateKey：Base64.getDecoder().decode(RSA_PRIVATE_KEY) → PKCS8EncodedKeySpec → KeyFactory RSA 生成私钥
4. 解析失败 → 抛启动异常，服务终止（防止无密钥运行）

本版本契约：env.json 注入值 = 脚本输出值 = 严格 DER 单行 Base64，两端一致，运行时代码零改动。
```

### 5.3 密钥数据流（LLD 8.1）
```
deploy-rsa-keygen.ps1（生成）
  → RSA 2048 密钥对（DER 编码：公钥 X.509 / 私钥 PKCS8）
  → Base64 单行编码（无 PEM 头尾、无换行）
  → deploy/env.json：RSA_PUBLIC_KEY / RSA_PRIVATE_KEY（覆盖旧 PEM 整体 Base64）
  → 环境变量注入 gateway + auth-service
  → RsaKeyConfig：Base64.getDecoder() 解码 → X509/PKCS8EncodedKeySpec → RSA KeyFactory
  → gateway（公钥验签）/ auth-service（私钥签名 + 公钥验签）
  → JWT RS256 双 Token 签发与网关验签链路正常
```

## 6. 回归报告依据（docs/cso-v0.2.5/regression-api-test.md，用户输入指定文档）

- **根因（第 42-44 行）**：env.json 中 RSA 密钥格式与 Java 解码契约不匹配：
  - deploy/env.json 的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 **PEM 文件整体 Base64（多行，含 BEGIN/END 标记与 \r\n）**（deploy-rsa-keygen.ps1 生成格式）；
  - Java 端 RsaKeyConfig（gateway/auth）使用严格 `Base64.getDecoder()` + `X509EncodedKeySpec`（期望 **DER 编码的 Base64，单行**），网关启动即报 `RSA 公钥解析失败（Unable to decode key / extra data at the end）`。
- **整改建议（第 51 行）**：修正 RSA 密钥生成/注入格式：deploy-rsa-keygen.ps1 输出 DER 单行 Base64（或 Java 端改用 MIME 解码器并剥除 PEM 头尾），保证 env.json 密钥与代码契约一致。
- **审核项 T-02（cso-review-v0.2.5.md）**：deploy/scripts/deploy-rsa-keygen.ps1、deploy/env.json 中 RSA 密钥为 PEM 整体 Base64（多行含 BEGIN/END），与 Java 端 `Base64.getDecoder()` + X509EncodedKeySpec（DER 单行 Base64）契约不匹配，网关启动即解析失败；整改：deploy-rsa-keygen.ps1 输出 DER 单行 Base64（或 Java 端改用 MIME 解码器剥除 PEM 头尾），修复后重新构建启动服务，补跑 cso-api-test-v0.0.1.py 完成 TC-001~045 动态闭环。

## 7. 任务边界与约束

| 类别 | 规则 |
| --- | --- |
| 修复范围 | 仅允许改动：deploy/scripts/deploy-rsa-keygen.ps1（密钥生成脚本）、deploy/env.json（密钥注入载体）；禁止改动接口层（Controller/DTO/响应体）、客户端 lib/ 运行时代码、数据库表结构、业务代码逻辑、RsaKeyConfig（Java 端保持不动） |
| 密钥格式 | `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 统一为 DER 编码单行 Base64（无 PEM 头尾、无换行）；与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约严格一致 |
| 密钥配对 | 公钥与私钥必须成对生成（RSA 2048），公钥验签/私钥签名配对一致 |
| 密钥安全 | 私钥不得入库、不得写入日志；密钥通过环境变量/配置文件注入，禁止硬编码 |
| 数据约束 | 数据库/Redis/Nacos 连接参数保持不变；本版本不新增数据表、不修改表结构 |
| 上游依赖 | 无（TASK-002 无上游任务）；下游任务 TASK-003（服务启动与健康检查验证）依赖本任务完成 |
| 测试方法 | 契约校验：脚本输出/env.json 值不含 -----BEGIN/-----END 子串、不含换行符、可被 Base64.getDecoder() 严格解码；启动验证：网关启动无 RSA 公钥解析失败 |
| 注意 | context.md 不记录任何真实密钥值（敏感信息红线） |
