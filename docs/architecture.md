# 架构文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffic
**版本号：** v0.2.0
**日期：** 2026-06-24

---

## 1. 系统架构概述

### 1.1 系统定位

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务企业管理平台，旨在为企业提供企业信息管理、人事管理、工作流审批、薪酬管理、统一认证授权等综合服务能力。v0.1.0 阶段完成基础骨架搭建，v0.1.4 阶段完成系统服务模块搭建，v0.1.5 阶段构建了完整的登录认证与权限管理系统，包括 RBAC 多租户权限模型、多端混合登录、JWT + Redis 双重会话管理、双 Token 续签机制和登录日志审计等核心能力。v0.1.6 阶段完成用户认证能力全面增强，引入策略模式实现多模式注册/登录（用户名密码/手机验证码/手机密码/OAuth）、统一认证服务层（AuthenticationService）、密码管理、手机号变更、验证码管理等核心能力，使平台认证体系覆盖主流互联网应用的用户接入场景。v0.1.7 阶段新增管理中台服务（`cloudoffice-admin-service`），提供管理员身份认证与角色权限校验、用户管理 CRUD（创建/查询/编辑/启用禁用/重置密码/角色分配）、管理员操作审计日志等核心能力，通过 OpenFeign 声明式 HTTP 客户端与 auth-service 进行服务间通信，并建立独立数据库 `cloudstroll_office_admin` 存储审计日志等管理后台数据。

### 1.2 架构风格

- **选用风格：** 微服务架构（Microservices Architecture）
- **选型理由：** 传统企业管理软件多为单体架构，存在扩展困难、技术栈陈旧、模块间耦合严重等问题。微服务架构通过服务解耦与独立部署，支持各业务域独立开发、测试、部署和扩展，符合 PRD 中 "微服务优先" 的核心设计理念，满足 NFR-003（服务间解耦）的要求。
- **前端架构风格：** Screen-Provider-Repository 三层架构（Flutter 前端），UI 层（Screen）↔ 状态管理层（Provider）↔ 数据仓库层（Repository）↔ HTTP 客户端层（ApiClient）严格分层，各层职责单一、可独立测试
- **跨平台策略：** Flutter 跨平台 UI 框架，一套 Dart 代码同时支持 Web（Chrome）和 Windows（VS2022）双平台，不引入平台特定代码（除非绝对必要），保持跨平台代码统一

### 1.3 架构层次图

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              客户端层 (Client)                            │
│   Flutter Web (Chrome)  │  Flutter Windows (VS2022)  │  第三方 API       │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          API 网关层 (Gateway)                              │
│                  Spring Cloud Gateway（端口 9000）                          │
│           路由转发 │ CORS │ 负载均衡 │ 服务发现 │ AuthFilter 认证过滤       │
│           ┌──────────────────────────────────────────────────────────┐   │
│           │  AuthFilter：白名单放行 → RS256公钥验签 → Redis黑名单校验  │   │
│           │  → 登录态校验 → 账号/租户状态校验 → 用户信息Header透传     │   │
│           └──────────────────────────────────────────────────────────┘   │
│           路由规则扩展(v0.1.7)：/api/v1/admin/** → admin-service          │
└──────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼──────────────────┬──────────────────┐
        ▼                         ▼                  ▼
┌──────────────────────────────┐   ┌──────────────────────────┐   ┌──────────────────────────┐
│  认证服务                      │   │   企业服务                 │   │  管理中台服务              │
│  auth-service                │   │   biz-service             │   │  admin-service            │
│  (端口 9100)                  │   │   (端口 9200)             │   │  (端口 9500)              │
│  RBAC + 双Token              │   │   企业信息/人事管理          │   │  管理员认证与权限校验       │
│  多端混合登录                  │   │   v0.1.0 骨架阶段          │   │  用户管理CRUD             │
│  登录日志审计                  │   │                           │   │  操作审计日志              │
│  v0.1.5 完整实现              │   │                           │   │  v0.1.7 新增              │
│  策略模式认证架构(v0.1.6)：     │   │                           │   │                          │
│  ┌─ 统一认证服务层(AuthSvc)    │   │                           │   │  ┌─ AdminAuthFilter       │
│  │  LoginStrategy x4          │   │                           │   │  │  AdminContext           │
│  │  RegisterStrategy x5      │   │                           │   │  │  AuthServiceClient      │
│  │  密码管理/手机号变更         │   │                           │   │  │  @AdminAuditLog AOP    │
│  │  验证码管理                 │   │                           │   │  └─────────────────────  │
│  └───────────────────────────┘   │                           │   │                          │
│                                  │◄──── OpenFeign ──────────│                          │
│  auth-service 扩展(v0.1.7)：     │                           │                          │
│  ┌─ AdminUserController         │                           │                          │
│  │  (供admin-service内调API)    │                           │                          │
│  └───────────────────────────┘   │                           │                          │
└──────────────────────────────┘   └──────────────────────────┘   └──────────────────────────┘
        │                       │                                  │
        ▼                       ▼                                  ▼
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                          系统服务 (system-service)                                         │
│                          (端口 9400)                                                       │
│                     系统配置 │ 日志 │ 监控 │ 定时任务                                        │
│                    v0.1.4 完成搭建（含健康检查 + 单元测试）                                    │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                                  │
        ┌─────────────────────────┼─────────────────────────────┬────────────────┐
        ▼                         ▼                             ▼                ▼
┌─────────────────┐   ┌──────────────────────┐   ┌──────────────────────────┐   ┌──────────────────────┐
│   MariaDB 10.6  │   │   Redis 7.2.x         │   │   RocketMQ 5.1.x         │   │   MariaDB 10.6       │
│ cloudstroll_    │   │  缓存层（本期启用）      │   │  消息队列层（本期预留）     │   │ cloudstroll_office_  │
│ office_auth     │   │  Token黑名单/登录态    │   │                          │   │ admin (v0.1.7 新增)  │
│ 7张表(v0.1.5)   │   │  账号/租户状态缓存     │   │                          │   │ 审计日志等管理数据     │
│ 3张新表(v0.1.6) │   │  验证码缓存(v0.1.6)   │   │                          │   │                    │
│ auth-service DB │   │                      │   │                          │   │ admin-service DB    │
└─────────────────┘   └──────────────────────┘   └──────────────────────────┘   └──────────────────────┘
                                  │
┌──────────────────────────────────────────────────────────────────────────┐
│                         基础设施层                                          │
│   Nacos 2.3.x (注册/配置中心) │ Seata 2.0.x │ Prometheus │ Grafana        │
└──────────────────────────────────────────────────────────────────────────┘
```

### 1.4 核心架构特点

| 特点 | 说明 |
|------|------|
| 服务解耦 | 每个业务域独立为微服务（auth/biz/system），通过 API 网关统一入口，服务间无直接代码依赖 |
| 统一治理 | Nacos 统一注册发现与配置管理，父 POM 统一管理所有第三方依赖版本 |
| 认证集中化 | Token 签发仅由 `cloudoffice-auth-service` 负责，请求鉴权在 `cloudoffice-gateway` 完成，业务服务不再重复校验 Token |
| 无状态+有状态混合校验 | 网关层通过 RS256 公钥本地验签（无状态）快速校验 Token，同时通过 Redis 查询登录态和黑名单（有状态），兼顾性能与安全 |
| 多租户隔离 | 所有认证数据（用户、角色、权限）均按租户 ID 隔离，用户名在租户内唯一，租户间数据互不可见 |
| 多端会话管理 | 以「用户 ID + 客户端类型」为维度管理登录会话，同类型端互斥（PC/WEB/MOBILE/MINI_PROGRAM），不同类型端可共存 |
| 渐进演进 | v0.1.0 搭建骨架，v0.1.4 新增系统服务，v0.1.5 完成完整认证体系，v0.1.6 增强认证能力（策略模式多模式注册/登录、密码管理、手机号变更、验证码管理），v0.1.7 新增管理中台服务（管理员认证、用户管理 CRUD、审计日志） |
| 策略模式解耦 | 登录和注册的多种方式通过策略模式实现，新增认证方式只需新增策略实现类并注册到工厂，不修改现有核心逻辑（v0.1.6 新增） |
| 统一认证编排 | `AuthenticationService` 统一编排凭证校验与 Token 签发/会话管理，所有登录方式共享同一套后处理流程（v0.1.6 新增） |
| 权限南向校验 | admin-service 负责管理员身份认证与角色权限校验，auth-service 负责用户数据持久化，服务间通过 OpenFeign 解耦调用，禁止跨服务直接访问数据库（v0.1.7 新增） |
| 管理后台 API 隔离 | 所有管理后台 API 统一使用 `/api/v1/admin/` 前缀，通过网关路由隔离，与普通用户 API 严格分离，新增管理资源仅需新增 Controller 和 Service（v0.1.7 新增） |
| AOP 审计日志 | 管理员关键操作（创建用户、禁用用户、重置密码、角色分配）通过 `@AdminAuditLog` 注解 + AOP 切面自动记录审计日志，不侵入业务逻辑代码（v0.1.7 新增） |
| 分层解耦前端 | Flutter 前端采用 Screen-Provider-Repository 三层架构，UI 层与业务逻辑严格分离，各层职责单一、可独立测试（v0.2.0 新增） |
| 跨平台一致性 | 基于 Flutter 跨平台框架，同一套 Dart 代码在 Web（Chrome）和 Windows（VS2022）双平台上运行表现一致，UI 布局和行为无明显差异（v0.2.0 新增） |
| Token 自动刷新 | Flutter 前端基于 Dio 拦截器实现 Access Token 过期自动刷新（Refresh Token Rotation），后台静默完成 Token 轮换，不中断用户操作（v0.2.0 新增） |
| 前端安全存储 | Token 等敏感数据使用 flutter_secure_storage 安全存储，Web 平台回退加密存储方案，不存储在普通 SharedPreferences 中（v0.2.0 新增） |


---

## 2. 模块设计

### 2.1 公共模块（cloudoffice-common）

- **职责：** 提供所有业务服务共享的通用组件，包括统一响应体 `ApiResult<T>`、通用异常体系（`BaseException`、`BusinessException`、`GlobalExceptionHandler`、`ErrorCode`）、基础实体类 `BaseEntity`、SpringDoc OpenAPI 3 配置、通用工具类、认证错误码枚举、客户端类型枚举、Token 数据传输对象等。
- **依赖：** Spring Boot Starter Web、SpringDoc、MyBatis-Plus、Lombok、Hutool、Jackson
- **接口：** 无对外 REST 接口，作为 Maven 依赖被其他模块引用
- **说明：** 纯依赖模块，不含启动类，被打包为 JAR 供各服务引用

**v0.1.5 新增内容：**
- `ErrorCode` 枚举中新增 19 个认证授权相关错误码（`TOKEN_EXPIRED`、`TOKEN_INVALID`、`TOKEN_BLACKLISTED`、`REFRESH_TOKEN_EXPIRED`、`REFRESH_TOKEN_INVALID`、`ACCOUNT_DISABLED`、`ACCOUNT_LOCKED`、`ACCOUNT_BANNED`、`ACCOUNT_EXPIRED`、`LOGIN_FAILED`、`CAPTCHA_ERROR`、`CLIENT_TYPE_INVALID`、`SESSION_KICKED_OUT`、`TENANT_DISABLED`、`TENANT_EXPIRED`、`PERMISSION_DENIED`、`ROLE_NOT_FOUND`、`USER_NOT_FOUND` 等）
- `org.cloudstrolling.cloudoffice.common.enums` 包下新增 `ClientTypeEnum` 枚举，包含 6 种客户端类型（WINDOWS/UBUNTU/H5/ANDROID/IOS/WECHAT_MINI），按设备分类（PC/WEB/MOBILE/MINI_PROGRAM）实现多端互斥登录逻辑
- `org.cloudstrolling.cloudoffice.common.dto` 包下新增 `TokenPairDTO`（双 Token 数据传输对象，含 accessToken/refreshToken/过期时间/tokenType）和 `LoginUserDTO`（登录用户信息传输对象，含 userId/tenantId/userName/clientType/roles/permissions）
- 新增 Redis Key 常量管理类 `RedisKeyConstants`，统一管理 Redis Key 前缀

**v0.1.6 新增内容：**
- `org.cloudstrolling.cloudoffice.common.enums` 包下新增 `RegisterModeEnum`（5 种注册模式：USERNAME / PHONE_CODE / OAUTH / PHONE_SET_USERNAME / OAUTH_SET_INFO）、`LoginModeEnum`（4 种登录模式：USERNAME_PASSWORD / PHONE_CODE / PHONE_PASSWORD / OAUTH）、`OAuthProviderEnum`（OAuth 提供商枚举：WECHAT / DINGTALK / WECHAT_WORK / ALIPAY）
- `ErrorCode` 枚举中新增 14 个认证增强错误码（`AUTH-0020` ~ `AUTH-0033`），覆盖密码管理、短信验证码、OAuth 认证、手机号变更等场景（详见错误码速查表）
- 新增验证码相关配置项常量类设计（Key 前缀管理扩展）

### 2.2 API 网关（cloudoffice-gateway）

- **职责：** 微服务统一流量入口，基于 Spring Cloud Gateway 实现请求路由转发、CORS 跨域支持、Nacos 服务发现集成、全局认证过滤器 AuthFilter（Token 校验与用户信息透传）、Redis 集成（黑名单/登录态/状态缓存查询）。
- **依赖：** Spring Cloud Gateway、Spring Cloud Alibaba Nacos Discovery、Spring Cloud LoadBalancer、Spring Boot Starter Data Redis、commons-pool2、common 模块
- **端口：** 9000
- **v0.1.5 新增能力：**
  - **AuthFilter 全局认证过滤器**：实现 `GlobalFilter` + `Ordered` 接口，优先级 `Ordered.HIGHEST_PRECEDENCE + 10`
    - 白名单路径放行（通过 `auth.white-list` 配置项动态配置）
    - 非白名单请求强制校验 `Authorization: Bearer <token>` 头
    - 校验流程：RS256 公钥验签 → Redis 黑名单查询 → Redis 登录态查询 → 账号状态校验 → 租户状态校验
    - 校验通过后向请求头透传用户信息：`X-User-Id`、`X-Tenant-Id`、`X-User-Name`、`X-Client-Type`、`X-Roles`、`X-Permissions`
    - 白名单默认路径：`POST /api/v1/auth/login`、`POST /api/v1/auth/register`、`POST /api/v1/auth/refresh`、`GET /api/v1/auth/health`、`POST /api/v1/auth/verification-code/send`、`POST /api/v1/auth/password/forgot/send-code`、`POST /api/v1/auth/password/forgot/reset`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`
    - **v0.1.7 更新：** 白名单路径扩展新增 `GET /api/v1/admin/health`，health 检查路径无需管理员认证
  - **Redis 集成**：配置 `ReactiveRedisTemplate<String, Object>` Bean，使用非阻塞响应式 Redis 客户端
  - **RSA 公钥加载**：从配置/环境变量加载 RS256 公钥用于 Token 验签
- **路由规则：**
  - `/api/v1/auth/**` → `cloudoffice-auth-service`
  - `/api/v1/biz/**` → `cloudoffice-biz-service`
  - `/api/v1/system/**` → `cloudoffice-system-service`
  - `/api/v1/admin/**` → `cloudoffice-admin-service`（v0.1.7 新增）

### 2.3 认证服务（cloudoffice-auth-service）

- **职责：** 统一认证授权中心，提供完整的用户认证与权限管理能力。包括：用户名密码登录（双 Token 签发）、Token 刷新（Refresh Token Rotation）、用户登出（Token 黑名单）、强制踢人、账号封禁/解封、RBAC 多租户权限管理（用户/角色/权限 CRUD 管理）、登录日志审计、**多模式注册/登录（策略模式）、密码管理、手机号变更、验证码管理**。集成 Spring Security + Spring Data Redis，使用 RS256 非对称签名算法。
- **依赖：** Spring Boot Starter Web、Spring Security、Spring Boot Starter Data Redis、commons-pool2、MyBatis-Plus、MariaDB Driver、jjwt、Nacos Discovery/Config、common 模块、**spring-boot-starter-mail**
- **端口：** 9100
- **v0.1.5 新增完整能力（参见下文）**

  **1. RBAC 权限模型（多租户隔离）：**
  - 6 张数据库表：`t_auth_tenant`（租户）、`t_auth_user`（用户）、`t_auth_role`（角色）、`t_auth_permission`（权限）、`t_auth_user_role`（用户-角色关联）、`t_auth_role_permission`（角色-权限关联）
  - 用户-角色-权限三层关联，用户名在租户内唯一（唯一索引 `uk_tenant_login_name`）
  - 租户管理：独立数据库存储企业租户信息，支持租户状态控制（正常/禁用/过期）和用户数限制

  **2. 登录认证与双 Token 机制：**
  - `POST /api/v1/auth/login`：用户名密码登录（BCrypt 校验），RS256 签发 Access Token（2h 有效）和 Refresh Token（7d 有效）
  - `POST /api/v1/auth/refresh`：Refresh Token 轮换（Rotation），同时更换 Access Token 和 Refresh Token，旧 Token 加入黑名单防重放
  - `POST /api/v1/auth/logout`：当前端口登出，Token 加入黑名单，登录态清除
  - `POST /api/v1/auth/kickout`：强制踢人（管理员操作），指定用户和客户端类型，支持踢所有端

  **3. 多端混合登录管理：**
  - 6 种客户端类型：WINDOWS（PC类）、UBUNTU（PC类）、H5（WEB类）、ANDROID（MOBILE类）、IOS（MOBILE类）、WECHAT_MINI（MINI_PROGRAM类）
  - 同类型端互斥（同一用户 + 同端类型新登录踢旧会话），不同类型端可共存
  - 登录态会话存储：Redis Key `auth:session:{userId}:{clientType}`

  **4. Redis 登录态管理（LoginSessionService）：**
  - 登录态会话 CRUD：创建/查询/删除，TTL 7 天
  - Token 黑名单管理：添加/校验，TTL = Token 剩余有效期
  - 账号状态缓存：`auth:account:status:{userId}`
  - 租户状态缓存：`auth:tenant:status:{tenantId}`
  - 支持批量清理（封禁所有端、踢所有端）

  **5. JWT 工具类重构（JwtUtils）：**
  - 从 HS256 升级为 RS256 非对称加密
  - `generateAccessToken(LoginUserDTO)`：签发 Access Token（含 sub/tenantId/clientType/tokenType="access"/roles/permissions/iat/exp）
  - `generateRefreshToken(LoginUserDTO)`：签发 Refresh Token（含 sub/tenantId/clientType/tokenType="refresh"/tokenVersion/iat/exp）
  - `parseAccessToken(token)`/`parseRefreshToken(token)`：解析并校验 tokenType
  - `getTokenSignature(token)`：获取 Token 签名指纹用于黑名单 Key
  - 支持三种密钥加载方式：环境变量 → 配置文件 Base64 → PEM 文件路径

  **6. 登录日志审计（LoginLogService）：**
  - 表 `t_auth_login_log` 记录每次登录认证详细信息
  - 记录字段：租户 ID、用户 ID、登录名、登录 IP、客户端类型、设备信息、登录时间、登出时间、登录状态（成功/失败/登出）、失败原因
  - 登录成功、登录失败、主动登出均记录日志（同步写入，后续可优化为异步）

  **7. 用户-角色-权限管理 API：**
  - `UserController`：用户分页查询、详情查询、信息修改、状态变更（封禁/解封）、角色分配、逻辑删除
  - `RoleController`：角色列表、创建、修改、权限分配、逻辑删除
  - `PermissionController`：树形权限列表查询、创建、修改、删除
  - 所有管理接口校验当前用户的操作权限（租户管理员或平台管理员）

**v0.1.6 新增完整能力：**

  **8. 策略模式认证架构（strategy 包）：**
  - 新增 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包，实现登录和注册的策略模式解耦
  - **登录策略（LoginStrategy）**：接口 `LoginStrategy` 定义 `authenticate(LoginRequest)` 方法，返回 `AuthResult`
    - `UsernamePasswordStrategy`：用户名+密码登录（基于现有 LoginService 逻辑重构）
    - `PhoneCodeLoginStrategy`：手机+短信验证码登录
    - `PhonePasswordLoginStrategy`：手机+密码登录（BCrypt 校验）
    - `OAuthLoginStrategy`：第三方 OAuth 登录（通过 openId 关联平台用户）
  - **注册策略（RegisterStrategy）**：接口 `RegisterStrategy` 定义 `register(RegisterRequest)` 方法
    - `UsernamePwdStrategy`：用户名+密码+手机号注册
    - `PhoneCodeStrategy`：手机+短信验证码注册
    - `OAuthRegisterStrategy`：第三方 OAuth 注册
    - `PhoneSetUsernameStrategy`：手机注册后设置用户名（两步注册第一步）
    - `OAuthSetInfoStrategy`：OAuth 注册后完善信息（两步注册第一步）
  - **策略工厂**：`LoginStrategyFactory` / `RegisterStrategyFactory` 根据 mode 获取对应策略实现
  - 策略实例预先初始化（Spring 容器管理），运行时零额外开销调度
  - 新增登录/注册模式仅需新增策略实现类并注册到工厂，无需修改核心流程（开闭原则）

  **9. 统一认证服务层（AuthenticationService）：**
  - 新增 `AuthenticationService` 统一编排认证流程
  - **登录编排**：调用 `LoginStrategyFactory.getStrategy(loginMode).authenticate(request)` 获取 AuthResult → 校验租户状态 → 校验用户状态（含 `account_settled` 校验）→ 构建 LoginUserDTO → 签发 JWT 双 Token → 同端互斥处理 → 写入 Redis 登录态 → 缓存账号/租户状态 → 记录登录日志 → 更新最后登录时间和 IP → 返回 TokenPairDTO
  - 所有登录模式共享同一套后处理流程，确保 Token 签发和会话管理一致
  - 新旧请求兼容：`loginMode` 不传时默认 `USERNAME_PASSWORD` 模式

  **10. 密码管理服务（PasswordService）：**
  - `changePassword(userId, oldPassword, newPassword)`：修改密码
    - 校验原密码（BCrypt.matches）
    - 校验新密码与旧密码不同
    - 新密码 BCrypt 加密存储（强度系数≥10）
    - 密码修改后可选择清理该用户所有登录态会话
  - `forgotPasswordSendCode(target, mode)`：密码找回发送验证码
  - `forgotPasswordReset(target, mode, code, newPassword)`：密码找回重置密码
    - 校验验证码有效性和过期时间
    - 验证码使用后立即标记为已使用（防重放）
    - 重置成功后清理该用户所有 Redis 登录态会话（强制重新登录）

  **11. 验证码管理服务（VerificationCodeService / VerificationCodeManager）：**
  - `VerificationCodeService` 接口：定义 `sendSmsCode(phone, code, purpose)` 和 `sendEmailCode(email, code, purpose)` 发送方法
  - `SimulatedVerificationCodeService`：模拟实现（日志输出验证码，用于开发和测试）
  - `VerificationCodeManager`：验证码生成/校验/过期管理
    - `generateCode(target, mode, purpose)`：生成 6 位数字验证码，写入数据库
    - `verifyCode(target, code, purpose)`：校验验证码，校验后标记为已使用
    - `isSendTooFrequent(target, purpose)`：检查发送频率（同一 target 同一用途 60 秒内不可重复发送）
    - `cleanExpiredCodes()`：清理过期验证码（5 分钟有效期）
  - 验证码存储优先使用 Redis（利用 TTL 自动过期），Redis 不可用时回退到数据库存储

  **12. 新增/变更 API 端点：**
  - `POST /api/v1/auth/register`（扩展）：请求体新增 `registerMode` 字段，支持 5 种注册模式，`registerMode` 不传时默认 `USERNAME`（向后兼容）
  - `POST /api/v1/auth/login`（扩展）：请求体新增 `loginMode` 字段，支持 4 种登录模式，`loginMode` 不传时默认 `USERNAME_PASSWORD`（向后兼容）
  - `PUT /api/v1/auth/password/change`（新增，需登录）：修改密码
  - `POST /api/v1/auth/password/forgot/send-code`（新增，白名单）：密码找回-发送验证码
  - `POST /api/v1/auth/password/forgot/reset`（新增，白名单）：密码找回-重置密码
  - `PUT /api/v1/auth/phone/change`（新增，需登录）：修改绑定手机号
  - `PUT /api/v1/auth/account/settlement`（新增，需登录）：两步注册完善账号信息
  - `POST /api/v1/auth/verification-code/send`（新增，白名单）：通用发送验证码

  **13. 新增/变更 DTO：**
  - `LoginRequest`（变更）：新增 `loginMode`（登录模式）、`phone`、`smsCode`、`oauthProvider`、`oauthCode` 字段，部分字段按模式改为可选
  - `RegisterRequest`（变更）：新增 `registerMode`（注册模式）、`smsCode`、`oauthProvider`、`oauthCode` 字段，移除 `tenantId`
  - `PasswordChangeRequest`（新增）：`oldPassword`、`newPassword`、`confirmPassword`
  - `PasswordForgotRequest`（新增）：`mode`、`target`、`code`、`newPassword`
  - `SendVerificationCodeRequest`（新增）：`target`、`purpose`、`mode`
  - `PhoneChangeRequest`（新增）：`newPhone`、`oldPhoneCode`、`newPhoneCode`、`emailCode`
  - `AccountSettlementRequest`（新增）：`userId`、`loginName`、`password`、`phone`、`smsCode`
  - `AuthResult`（新增，策略认证结果）：`userId`、`tenantId`、`loginName`、`userName`、`phone`、`roles`、`permissions`

  **14. 新增/变更实体与 Mapper：**
  - `UserEntity`（变更）：新增 `registerMode`、`accountSettled`、`phoneVerified`、`emailVerified`、`lastPasswordChangeTime` 字段
  - `OAuthAccountEntity`（新增）：`t_auth_oauth_account` 表实体（用户-OAuth 账号关联）
  - `VerificationCodeEntity`（新增）：`t_auth_verification_code` 表实体（验证码记录）
  - `OAuthAccountMapper`（新增）：OAuth 账号关联 Mapper
  - `VerificationCodeMapper`（新增）：验证码记录 Mapper

  **15. 用户表扩展：**
  - `t_auth_user` 表新增字段：`register_mode`（注册模式）、`account_settled`（账号是否完善）、`phone_verified`（手机已验证）、`email_verified`（邮箱已验证）、`last_password_change_time`（最后修改密码时间）
  - `account_settled=0` 的用户在登录时返回 `ACCOUNT_NOT_SETTLED` 错误，引导完善资料
  - 已有用户记录的 `register_mode` 默认 `USERNAME`，`account_settled` 默认 `1`（完全向后兼容）

### 2.4 企业服务（cloudoffice-biz-service）

- **职责：** 企业核心业务承载服务，本阶段为骨架模块，建立标准包目录结构。后续将承载企业信息管理、部门管理、员工管理、考勤管理、工作流审批、薪酬管理等业务功能。
- **依赖：** Spring Boot Starter Web、Nacos Discovery/Config、MyBatis-Plus、MariaDB Driver、common 模块
- **端口：** 9200
- **说明：** v0.1.0 仅搭建骨架，不实现具体业务逻辑

### 2.5 系统服务（cloudoffice-system-service）

- **职责：** 基础公共服务承载服务，提供系统参数配置管理、操作日志、监控告警、定时任务等功能。v0.1.4 完成基础框架搭建。
- **依赖：** Spring Boot Starter Web、Nacos Discovery/Config、MyBatis-Plus、MariaDB Driver、common 模块
- **端口：** 9400
- **已实现内容（v0.1.4）**（不变）
- **说明：** v0.1.4 完成基础框架搭建，定时任务框架选型后续决策，本期不做绑定

### 2.6 管理中台服务（cloudoffice-admin-service）

- **职责：** 统一的管理后台后端服务，提供管理员身份认证与角色权限校验、用户管理 CRUD（分页查询/详情/创建/编辑/启用禁用/重置密码/角色分配）、管理员操作审计日志等功能。所有管理 API 统一使用 `/api/v1/admin/` 路径前缀，通过网关路由严格隔离。
- **依赖：** Spring Boot Starter Web、Nacos Discovery/Config、MyBatis-Plus、MariaDB Driver、Spring Cloud OpenFeign、Spring Cloud LoadBalancer、Spring Boot Starter AOP、common 模块
- **端口：** 9500
- **数据源：** `cloudstroll_office_admin`（独立数据库），仅存储审计日志等管理后台数据，不存用户数据
- **已实现内容（v0.1.7）：**
  - **AdminAuthFilter 管理员认证过滤器**：实现 `OncePerRequestFilter`，对所有 `/api/v1/admin/**`（白名单路径除外）进行 JWT 解析和角色校验
    - 白名单路径放行（健康检查 `/api/v1/admin/health` 等）
    - 校验 `Authorization: Bearer <token>` 头，解析 JWT Claims
    - 校验用户角色是否包含 `SUPER_ADMIN` 或 `SYSTEM_ADMIN`
    - 校验通过后设置 `AdminContext` 上下文
  - **AdminContext 管理员请求上下文**：基于 ThreadLocal 实现，贯穿请求生命周期，在 `finally` 块中自动清理
    - 包含 `adminId`、`adminName`、`realName`、`roles` 等管理员身份信息
  - **AdminUserController 管理员用户管理接口**：9 个 RESTful API 端点
    - `GET /api/v1/admin/users` — 分页查询用户列表（关键词、状态、角色、时间范围筛选）
    - `GET /api/v1/admin/users/{userId}` — 查询用户详情
    - `POST /api/v1/admin/users` — 创建用户
    - `PUT /api/v1/admin/users/{userId}` — 编辑用户信息
    - `PUT /api/v1/admin/users/{userId}/status` — 启用/禁用用户
    - `PUT /api/v1/admin/users/{userId}/password/reset` — 重置用户密码
    - `PUT /api/v1/admin/users/{userId}/roles` — 分配用户角色
    - `GET /api/v1/admin/audit-logs` — 查询操作审计日志
    - `GET /api/v1/admin/health` — 健康检查
  - **AuthServiceClient（Feign 客户端）**：声明式 HTTP 客户端，调用 auth-service 的内部管理 API
    - 所有用户数据操作通过 Feign 调用 auth-service 实现，不直接访问 auth-service 的数据库
    - Feign 请求拦截器自动传递管理员身份 Token
  - **审计日志体系（`@AdminAuditLog` AOP）**：基于 Spring AOP 注解实现，不侵入业务逻辑代码
    - `AdminAuditLog` 注解：标记需要记录审计日志的方法
    - `AdminAuditLogAspect` 切面：环绕通知，记录操作详情、操作人、操作时间、操作结果
    - 审计日志持久化到 `cloudstroll_office_admin.t_admin_audit_log` 表
    - 支持操作类型枚举：`CREATE_USER`、`UPDATE_USER`、`DISABLE_USER`、`ENABLE_USER`、`RESET_PASSWORD`、`ASSIGN_ROLES` 等
    - 插入失败时异常隔离，不影响主业务操作
  - **管理员角色预置**：初始化脚本预置 `SUPER_ADMIN`（超级管理员）和 `SYSTEM_ADMIN`（系统管理员）角色，创建初始超级管理员账号（admin/Admin@123456）
- **服务间通信：** admin-service → auth-service（OpenFeign 同步调用）
  - 调用关系：admin-service 通过 `AuthServiceClient` Feign 接口调用 auth-service 的 `AdminUserController` API
  - 通信协议：HTTP/JSON，连接超时 5s，读取超时 10s
  - 鉴权方式：Feign 请求拦截器自动携带管理员 JWT Token 或内部服务 Token
  - 降级策略：Feign 调用失败时，admin-service 捕获异常并返回友好错误信息
- **说明：** v0.1.7 为首次实现，遵循项目标准包结构。用户数据不在 admin-service 数据库维护，通过 Feign 调用 auth-service 操作。当前版本权限校验为角色级别粗粒度控制，后续版本可扩展为细粒度权限校验。

### 2.7 Flutter 前端应用（cloudoffice-flutter-app）

- **职责：** 云漫智企面向最终用户的跨平台前端应用，提供用户认证（注册、登录、找回密码）等基础交互能力，与后端微服务通过 API 网关通信。支持 Web（Chrome）和 Windows（VS2022）双平台运行。
- **技术栈：** Flutter 3.x + Dart 3.x
- **构建平台：** Web（Chrome）、Windows（VS2022）
- **架构模式：** Screen-Provider-Repository 三层架构
  - Screen（页面层）：纯 UI 组件，通过 Provider 获取状态
  - Provider（状态管理层）：继承 ChangeNotifier，管理页面状态（loading/error/success）
  - Repository（数据仓库层）：封装 API 调用逻辑，调用 ApiClient 发送 HTTP 请求
- **核心层（core）：**
  - **ApiClient**：基于 Dio 的单例 HTTP 客户端，封装基础 URL（`http://localhost:9000`）、超时（连接 15s / 读取 30s）、拦截器
  - **ApiInterceptor**：请求拦截器自动注入 `Authorization: Bearer {token}`，响应拦截器处理 401 自动刷新 Token（并发锁防重复刷新）
  - **ApiResult**：对应后端统一响应体的 Dart 模型（泛型 `ApiResult<T>`，含 code/message/data/timestamp）
  - **SecureStorage**：基于 flutter_secure_storage 的安全存储封装，存储 Token 等敏感数据
  - **AppRouter**：基于 GoRouter 的声明式路由配置，含登录态路由守卫（已登录跳首页，未登录跳登录页）
- **功能模块（features）：**
  - **auth/**：认证模块
    - 页面：登录页（密码登录/验证码登录双模式 Tab 切换）、注册页（用户名注册/手机号注册双模式 Tab 切换）、找回密码页（两步流程：身份验证 → 重置密码）
    - 数据模型：LoginRequest、RegisterRequest、TokenPairDTO、RegisterResult 等
    - Provider：AuthProvider（登录/注册状态管理）、ForgotPasswordProvider（找回密码状态管理）
    - Repository：AuthRepository（封装 6 个 API 调用方法）
  - **home/**：首页模块（用户信息展示、退出登录）
- **共享组件（shared）：**
  - 公共 UI 组件：CustomTextField、PasswordField（含显示/隐藏切换）、VerificationCodeField（含验证码倒计时）、LoadingButton（加载状态按钮）、PasswordStrengthIndicator（密码强度指示器）
  - 常量定义：AppConstants（kApiBaseUrl、kPasswordMinLength 等）
- **依赖：**
  - 运行时依赖：dio（^5.x）、provider（^6.x）、flutter_secure_storage（^9.x）、go_router（^14.x）
  - 开发依赖：flutter_test、flutter_lints（^5.x）、mockito（^5.x）、build_runner
- **数据流：** Screen → Provider → Repository → ApiClient（Dio）→ HTTP → Gateway（:9000）→ auth-service → 数据库/Redis
- **客户端类型标识：** Web（Chrome）使用 `H5`、Windows（VS2022）使用 `WINDOWS`
- **说明：** Flutter 子项目独立位于 `cloudoffice-flutter-app/` 目录，不修改现有后端代码。v0.2.0 仅实现认证相关页面，业务功能页面在后续版本扩展。

### 模块关系图

```
┌─────────────────────────────────────────────────────────────────────┐
│                         cloudoffice-common                           │
│       (无业务依赖，所有服务模块的公共依赖，含新增枚举/DTO/错误码)         │
└─────────────────────────────────────────────────────────────────────┘
                    ▲           ▲           ▲           ▲
                    │依赖       │依赖       │依赖       │依赖
                    │           │           │           │
┌───────────┐ ┌───────────┐ ┌──────────┐ ┌──────────────┐ ┌────────────────┐
│  gateway  │ │auth-service│ │biz-service││system-service││ admin-service   │
│ (端口9000)│ │(端口9100) │ │(端口9200) ││ (端口9400)   ││ (端口9500)      │
│ AuthFilter│ │ RBAC+JWT  │ │ 骨架阶段   ││ 骨架阶段      ││ AdminAuthFilter │
│ Redis集成  │ │ Redis会话  │ │           ││              ││ OpenFeign客户端  │
│ 白名单扩展  │ │ 策略模式   │ │           ││              ││ AOP审计日志      │
│ admin路由  │ │ 密码管理   │ │           ││              ││ 独立数据库       │
│ (v0.1.7)   │ │ 验证码     │ │           ││              ││ 管理员CRUD      │
│            │ │ 管理API扩展 │ │           ││              ││ (v0.1.7)       │
└───────────┘ └──────┬─────┘ └──────────┘ └──────────────┘ └───────┬────────┘
      │              │  ▲                                          │
      │              │  │ OpenFeign                                │
      │              │  └──────────────────────────────────────────┘
      │  Redis查询   │  Redis写入
      ▼              ▼
┌──────────────────────────────────────┐
│           Redis 7.2.x                │
│   ┌──────────────────────────────┐  │
│   │ auth:session:{userId}:{type} │  │  ← 登录态会话
│   │ auth:token:blacklist:{sig}   │  │  ← Token 黑名单
│   │ auth:account:status:{id}     │  │  ← 账号状态缓存
│   │ auth:tenant:status:{id}      │  │  ← 租户状态缓存
│   │ auth:verification:{pur}:{tgt}│  │  ← 验证码缓存(v0.1.6)
│   └──────────────────────────────┘  │
└──────────────────────────────────────┘
                    │
                    └───────────┐
                                │
                    ┌───────────▼───────────┐
                    │    Nacos 注册中心       │
                    │  (服务发现与配置管理)     │
                    └───────────────────────┘
```

- **注意：** 各业务服务之间无直接代码依赖，服务间通信通过 OpenFeign（同步）或 RocketMQ（异步）在后续版本实现。v0.1.7 已实现 admin-service 与 auth-service 之间的 OpenFeign 同步通信。

---

## 3. 技术选型

### 3.1 技术栈全景

| 领域 | 技术方案 | 版本要求 | 选型理由 |
|------|---------|---------|---------|
| 编程语言 | OpenJDK | 21 LTS | 长期支持版本，支持虚拟线程、模式匹配、Record 等新特性，性能优异 |
| 构建工具 | Apache Maven | 3.9.x | 成熟的 Java 项目构建管理工具，多模块支持完善，与 IDEA 集成度高 |
| 微服务框架 | Spring Boot + Spring Cloud | 3.2.5 / 2023.0.1 | 业界主流微服务方案，生态成熟，社区活跃，与 Spring Cloud Alibaba 配合良好 |
| 注册/配置中心 | Nacos | 2.3.x | 支持服务注册发现与配置管理二合一，阿里云原生生态核心组件 |
| API 网关 | Spring Cloud Gateway | 内置于 Spring Cloud | 基于 Spring WebFlux 响应式编程，性能优于 Zuul，与 Nacos 原生集成 |
| 关系型数据库 | MariaDB | 10.6 LTS | MySQL 的完全兼容替代品，性能更优，协议兼容，社区版无功能阉割 |
| ORM 框架 | MyBatis-Plus | 3.5.6 | 增强型 MyBatis，提供代码生成器、分页插件、Lambda 查询，开发效率高 |
| 连接池 | HikariCP | 5.x | Spring Boot 默认连接池，性能业界最优，零额外配置即可使用 |
| 缓存 | Redis | 7.2.x | 高性能内存缓存，本期启用：Token 黑名单、登录态会话、账号/租户状态缓存 |
| 消息队列 | RocketMQ | 5.1.x | 阿里巴巴开源的高性能消息中间件，（本期预留，仅引入客户端依赖） |
| 分布式事务 | Seata | 2.0.x | AT 模式无侵入业务代码，与 Spring Cloud Alibaba 深度集成，（本期预留） |
| 认证授权 | Spring Security + JWT | 内置于 Spring Boot | 业界标准安全框架，v0.1.5 完整实现登录认证与 RBAC 权限管理 |
| JWT 库 | jjwt (io.jsonwebtoken) | 0.12.x | Spring 官方推荐 JWT 实现，支持 HS256/RS256 算法，v0.1.5 升级为 RS256 |
| JWT 签名算法 | RS256 (RSA with SHA-256) | 2048 位密钥 | 非对称加密，私钥签发公钥验签，解决 HS256 对称密钥泄漏风险 |
| API 文档 | SpringDoc (OpenAPI 3) | 2.5.0 | 自动生成 OpenAPI 3 规范文档，支持 Swagger UI 在线调试 |
| JSON 处理 | Jackson | 2.16.x | Spring Boot 默认 JSON 框架，性能高，与 Spring 深度集成 |
| 工具库 | Hutool | 5.8.26 | 功能全面的 Java 工具类库，减少重复造轮子 |
| 代码简化 | Lombok | 1.18.32 | 减少 Getter/Setter/Constructor 等样板代码 |
| 邮件发送（v0.1.6） | Spring Boot Starter Mail | 3.2.5 (继承 Boot Parent) | 邮箱验证码发送支持，本期提供模拟实现，后续对接 SMTP 服务 |
| 可观测性 | Prometheus + Grafana + SkyWalking | 最新 | 业界标准监控方案（本期规划，后续版本集成） |
| 容器化 | Docker + Docker Compose | 最新 | 标准化部署，开发/测试/生产环境一致性 |
| 前端框架 | Flutter | 3.x | 跨平台 UI 框架，一套代码支持 Web 和 Windows 双平台，Dart 语言高效开发 |
| 前端语言 | Dart | 3.x | Flutter 官方编程语言，支持 AOT/JIT 编译，类型安全，性能优异 |
| HTTP 客户端 | Dio | ^5.x | Dart 生态最流行的 HTTP 库，支持拦截器、请求重试、超时配置 |
| 状态管理 | Provider | ^6.x | Flutter 官方推荐的状态管理方案，简单易用，适合中小型应用 |
| 安全存储 | flutter_secure_storage | ^9.x | 跨平台安全存储，Windows 使用 DPAPI/Credential Manager，Web 回退加密存储 |
| 路由管理 | GoRouter | ^14.x | Flutter 官方推荐的声明式路由，支持路由守卫、深层链接、浏览器 URL |
| 前端构建 | Flutter Web | - | Chrome 浏览器运行，构建为静态 HTML/CSS/JS |
| 前端构建 | Flutter Windows | - | VS2022 + MSVC 构建为 Windows 原生桌面应用 |

### 3.2 架构决策记录（ADR）

| ADR编号 | 决策内容 | 选项对比 | 最终选择 | 理由 | 后果/权衡 |
|---------|---------|---------|---------|------|----------|
| ADR-001 | 架构风格选型 | 单体架构 vs 微服务架构 | 微服务架构 | ① 各业务域（认证/企业/系统）职责清晰，天然适合微服务拆分；② 支持独立开发、测试、部署和扩展，满足 NFR-003 服务解耦要求；③ 团队可并行开发不同服务，提升研发效率 | 引入了服务间通信（OpenFeign/RocketMQ）、分布式事务（Seata）、服务治理等额外的架构复杂度，需要更多的运维投入 |
| ADR-002 | 微服务框架选型 | Spring Cloud Alibaba vs Spring Cloud Netflix | Spring Cloud Alibaba | ① Netflix 组件多数进入维护期（Hystrix 停更、Ribbon 停更、Zuul 停更）；② Alibaba 组件（Nacos、Sentinel、Seata、RocketMQ）生态活跃，持续迭代；③ 国产技术栈，中文文档丰富，社区支持好 | 对阿里云生态的依赖性增强，但各组件均为开源项目，不存在厂商锁定风险 |
| ADR-003 | 注册/配置中心选型 | Nacos vs Eureka vs Zookeeper | Nacos | ① 同时支持服务注册发现和配置管理，减少运维组件数量；② Eureka 2.x 已停更；③ Nacos 支持配置动态刷新、命名空间隔离、灰度发布等高级特性；④ 与 Spring Cloud Alibaba 深度集成 | Nacos Server 需要额外部署维护，相比 Eureka 仅注册中心功能，部署成本略高 |
| ADR-004 | API 网关选型 | Spring Cloud Gateway vs APISIX vs Kong | Spring Cloud Gateway（本期） | ① 与 Spring Cloud 生态原生集成，开发配置一致性好；② 基于 WebFlux 响应式编程，性能高；③ 本阶段功能需求简单（路由转发 + CORS + 认证过滤器），Gateway 足够胜任 | 后期若需高级功能（动态路由、插件热加载），可迁移至 APISIX；Gateway 的配置变更需重启服务 |
| ADR-005 | 关系型数据库选型 | MariaDB vs MySQL vs PostgreSQL | MariaDB 10.6 LTS | ① 完全兼容 MySQL 协议和 SQL 语法，迁移零成本；② 相比 MySQL，MariaDB 有更优的查询优化器和性能（如子查询优化、窗口函数）；③ LTS 版本支持 5 年维护，社区版与商业版功能无差异 | MySQL 的流行度和生态资源略高于 MariaDB，但 MariaDB 在兼容性上无差异 |
| ADR-006 | ORM 框架选型 | MyBatis-Plus vs JPA/Hibernate | MyBatis-Plus 3.5.x | ① MyBatis-Plus 在 MyBatis 基础上提供代码生成器、Lambda 查询、分页插件、乐观锁插件等增强功能；② 相比 JPA，MyBatis 更贴近 SQL，便于 DBA 审查和优化 SQL；③ 团队对 MyBatis 熟悉度更高，学习成本低 | 相比 JPA，MyBatis-Plus 需要手写部分 XML 映射文件，自动化程度略低；关联查询需手动编写 |
| ADR-007 | 服务间同步通信 | OpenFeign + LoadBalancer vs RestTemplate + Ribbon | OpenFeign + Spring Cloud LoadBalancer | ① OpenFeign 声明式 HTTP 客户端，代码简洁，可读性好；② Spring Cloud 2023.x 已移除 Ribbon，官方推荐 LoadBalancer 替代；③ OpenFeign 与 Spring MVC 注解兼容，学习成本低 | 相比 RPC 框架（如 Dubbo），HTTP 通信性能略低，但本阶段业务规模下完全可接受 |
| ADR-008 | 主键生成策略 | 雪花算法 vs UUID vs 自增 ID | 雪花算法（MyBatis-Plus ID_WORKER） | ① 分布式环境下的唯一 ID 生成方案，不依赖数据库；② ID 为 Long 类型，相比 UUID（String）占用空间小，索引效率高；③ 趋势递增，利于 B+Tree 索引维护 | 需要配置工作机器 ID 避免冲突；时间回拨问题需额外处理（MP 已内置处理） |
| ADR-009 | 密码加密方案 | BCrypt vs SHA-256 vs MD5 | BCrypt | ① Spring Security 内置支持，开箱即用；② 自动加盐，抗彩虹表攻击；③ 可配置计算成本（strength），未来可增加难度；④ 相比 MD5/SHA 的快速计算特性，BCrypt 慢哈希更安全 | 密码验证性能较慢（约 10ms/次），但登录场景下可接受 |
| ADR-010 | 配置文件管理 | Nacos 配置中心 vs 本地配置文件 | 本地配置文件为主 + Nacos 配置中心骨架 | ① 本阶段为骨架搭建，功能简单，本地配置文件足够；② 预留 Nacos 配置中心 bootstrap.yml 配置，后续动态配置需求可直接启用；③ 敏感配置通过环境变量注入，不留存于代码仓库 | 配置变更需重启服务，本阶段可接受；后续版本启用配置中心后可热更新 |
| **ADR-011** | **JWT 签名算法选型** | **HS256 对称加密 vs RS256 非对称加密** | **RS256** | ① 非对称加密，认证服务持有私钥签发，网关+业务服务仅持公钥验签，私钥泄漏风险低；② 网关可以本地验签无需调用认证服务，减少网络依赖和延迟；③ 支持多服务（网关/业务服务）独立验签，无需共享密钥 | 密钥管理复杂度增加（密钥对生成和分发）；签名验证性能略低于 HS256（约 2-3 倍计算时间），但 Token 校验场景下完全可接受 |
| **ADR-012** | **Token 管理方案** | **纯 JWT 无状态 vs JWT + Redis 有状态** | **JWT + Redis 混合** | ① 纯 JWT 无法实现主动登出、踢人、Token 吊销等能力；② Redis 存储登录态和黑名单，支持实时生效的会话管理；③ 网关先做本地公钥验签（无状态快速校验），再查 Redis（有状态增强校验），兼顾性能与安全 | 引入 Redis 依赖，Redis 不可用时需降级处理；增加网络开销（每次请求需查询 Redis），但可通过缓存或本地缓存优化 |
| **ADR-013** | **网关认证过滤器位置** | **Gateway AuthFilter vs auth-service 拦截器 vs 业务服务各自校验** | **Gateway AuthFilter 集中校验** | ① 统一在网关层完成 Token 校验，业务服务零侵入；② 通过 Header 透传用户信息，业务服务无感知；③ 减少重复代码，单一变更点；④ 非阻塞响应式编程，不阻塞业务请求处理线程 | 网关层故障会影响所有请求，需保证网关高可用；网关需集成 Redis 查询能力 |
| **ADR-014** | **多端会话管理策略** | **同类型端互斥 vs 所有端互斥 vs 不限制** | **同类型端互斥（按设备分类）** | ① 符合实际使用场景（同一用户不会在两台 PC 上同时登录，但可以在 PC + 手机 + H5 上同时登录）；② 降低 Redis 存储压力；③ 通过 `ClientTypeEnum.isSameCategory()` 灵活扩展，新增客户端类型无需修改互斥逻辑 | 实现复杂度略高于"不限制"，但低于"所有端互斥"；需定义清晰的设备分类维度 |
| **ADR-015** | **Refresh Token 轮换策略** | **轮换（Rotation） vs 不轮换** | **轮换（每次刷新同时更换 Access Token 和 Refresh Token）** | ① 防止 Refresh Token 泄漏后的重放攻击；② 旧 Refresh Token 加入黑名单即时失效；③ 每个 Refresh Token 仅能使用一次，安全性更高 | 增加 Token 签发频率，但双 Token 刷新周期 7 天，影响有限；需维护 Refresh Token 黑名单 |
| **ADR-016** | **Redis 客户端选型** | **Jedis vs Lettuce** | **Lettuce + commons-pool2** | ① Spring Boot 默认集成 Lettuce，配置简化；② Lettuce 基于 Netty 异步非阻塞，适合 Spring Cloud Gateway 响应式模型；③ 支持连接池，性能稳定 | Lettuce 在极端高并发下偶有连接不稳定情况，可通过配置超时和重试缓解 |
| **ADR-017** | **认证模式扩展方案（v0.1.6）** | **策略模式 vs if-else 分支 vs 责任链模式** | **策略模式 + 工厂模式** | ① 每种登录/注册方式独立为策略类，职责单一，不超过 200 行；② 新增认证方式只需新增实现类并注册工厂，不修改现有核心逻辑（开闭原则）；③ 工厂类集中管理策略实例，运行时零额外开销 | 策略类数量随认证方式增多而线性增长，但每个策略类代码量少，可维护性好 |
| **ADR-018** | **验证码存储方案（v0.1.6）** | **Redis 存储 vs 数据库存储** | **Redis 优先 + 数据库回退** | ① Redis 利用 TTL 自动过期，无需定时清理任务；② Redis 读写性能远优于数据库，适合高频验证码校验场景；③ Redis 不可用时回退到数据库存储，保证可用性 | 验证码数据在 Redis 和数据库之间可能存在短暂不一致（Redis 故障切换时）；需确保验证码使用后立即标记，防重放 |
| **ADR-019** | **密码找回实现方案（v0.1.6）** | **独立密码重置令牌表 vs 验证码记录表覆盖** | **验证码记录表覆盖（不新增密码重置令牌表）** | ① 验证码本身已满足安全需求（一次性、5 分钟过期、target + purpose 匹配）；② 不额外增加数据库表，减少维护成本；③ 密码找回业务流程与验证码生成/校验逻辑完全复用现有 VerificationCodeManager | 验证码存储在数据库中（或 Redis），无独立的密码重置令牌抗重放能力，但验证码的一次性使用已满足安全要求 |
| **ADR-020** | **验证码发送渠道设计（v0.1.6）** | **直接引入短信/邮件 SDK vs 接口抽象 + 模拟实现** | **接口抽象 + 模拟实现** | ① VerificationCodeService 接口定义发送契约，与具体发送渠道解耦；② 模拟实现日志输出验证码，不依赖真实短信/邮件网关；③ 后续对接真实网关只需新增实现类并替换注入，不改动业务代码 | 模拟实现仅适用于开发/测试环境，生产环境需对接真实短信/邮件服务；接口抽象增加了间接层，但扩展性显著提升 |
| **ADR-021** | **管理中台服务独立（v0.1.7）** | **admin-service 独立微服务 vs auth-service 内嵌管理接口** | **独立微服务（admin-service）** | ① 管理中台与用户认证职责分离，遵循单一职责原则；② 独立微服务可独立扩缩容，不影响认证服务性能；③ 管理 API 与普通 API 物理隔离，安全边界清晰；④ 新增管理功能不影响 auth-service 的稳定性 | 引入服务间通信（OpenFeign）延迟，增加运维成本；管理功能需通过 Feign 调用 auth-service，增加网络依赖 |
| **ADR-022** | **admin-service 数据库策略（v0.1.7）** | **使用 auth-service 数据库 vs 独立数据库** | **独立数据库（cloudstroll_office_admin）** | ① 遵循微服务数据库独立原则，各服务独享数据存储；② auth-service 数据库变更不影响 admin-service；③ 审计日志等管理数据与用户认证数据物理隔离 | admin-service 需维护独立数据源配置；审计日志查询不能直接关联用户表，需通过 Feign 调用获取用户信息 |
| **ADR-023** | **admin-service 权限校验位置（v0.1.7）** | **网关层校验管理员角色 vs admin-service 内置过滤器校验** | **admin-service 内置 AdminAuthFilter 校验** | ① 管理员角色校验属于业务逻辑，放在网关层会污染网关的关注点；② admin-service 内置过滤器可获取完整的 JWT Claims 进行角色判断；③ 管理员角色校验与用户数据操作在同一个服务内，减少网关透传的 Header 数量 | 每个管理请求需额外在 admin-service 中校验角色，增加一次 JWT 解析开销；网关仍需做基础 Token 校验 |
| **ADR-024** | **管理员认证 Token 方案（v0.1.7）** | **网关透传用户 Token vs admin-service 独立 Token** | **复用 auth-service JWT + 网关透传** | ① 管理员使用与普通用户相同的登录接口获取 JWT Token，减少认证入口；② JWT 中已包含 roles 信息，admin-service 解析即可完成角色校验；③ 无需额外签发管理员专用 Token，降低复杂度 | 管理员 Token 与普通用户 Token 格式相同，需在 admin-service 中通过角色字段区分 |
| **ADR-025** | **审计日志实现方案（v0.1.7）** | **AOP 注解 vs 业务代码手动记录 vs 中间件拦截** | **AOP 注解（@AdminAuditLog）** | ① 注解声明式标记，不侵入业务逻辑代码；② AOP 环绕通知可捕获方法执行前后状态，自动记录成功/失败和异常信息；③ 注解可配置操作类型，扩展性强；④ 相比中间件拦截，实现简单，学习成本低 | AOP 仅对 Spring Bean 方法有效，需确保切面正确配置；相比中间件方案，无法拦截数据库级别的操作 |

| **ADR-026** | **Flutter 前端技术栈选型（v0.2.0）** | **Flutter vs React Web + Electron vs Vue + Tauri** | **Flutter** | ① 一套代码同时覆盖 Web 和 Windows，开发效率高；② Dart 语言在跨平台场景下表现优于 JavaScript/TypeScript；③ Flutter Web 基于 CanvasKit 渲染，UI 一致性高；④ 团队技术栈统一，降低维护成本 | Flutter Web 的 SEO 能力弱于传统 Web 框架；Flutter Windows 构建产物较大（约 50MB+）；Dart 生态第三方库丰富度低于 JS 生态 |


---

## 4. 数据流

### 4.1 核心业务数据流（v0.1.5 认证登录流程）

```
[客户端]
    │
    │ ① POST /api/v1/auth/login
    │ { loginName, password, tenantCode, clientType }
    ▼
[API 网关 (端口 9000)]
    │ 白名单路径，直接放行
    ▼
[认证服务 (端口 9100)]
    │
    │ ② 校验参数 & 校验验证码（预留）
    │ ③ 查询租户（t_auth_tenant）→ 校验租户状态
    │ ④ 查询用户（t_auth_user）→ 校验用户状态 & 账号有效期
    │ ⑤ BCrypt.matches(password, encryptedPassword) → 验证密码
    │    ├─ 失败 → 记录登录失败日志 → 返回 401 LOGIN_FAILED
    │    └─ 成功 →
    │         ⑥ 查询用户角色和权限（t_auth_user_role → t_auth_role → t_auth_role_permission → t_auth_permission）
    │         ⑦ 构建 LoginUserDTO（含 userId/tenantId/roles/permissions/clientType）
    │         ⑧ JwtUtils.generateAccessToken(LoginUserDTO) → RS256 签名 → Access Token (2h)
    │         ⑨ JwtUtils.generateRefreshToken(LoginUserDTO) → RS256 签名 → Refresh Token (7d)
    │         ⑩ LoginSessionService.createSession():
    │            ├─ 同端互斥：删除旧会话 + 旧 Token 加入黑名单
    │            ├─ 写入 Redis: auth:session:{userId}:{clientType} (TTL 7d)
    │            ├─ 写入 Redis: Auth:account:status:{userId} (缓存账号状态)
    │            └─ 写入 Redis: auth:tenant:status:{tenantId} (缓存租户状态)
    │         ⑪ 记录登录成功日志（t_auth_login_log）
    │         ⑫ 更新用户表 last_login_time / last_login_ip
    │         ⑬ 返回 TokenPairDTO（accessToken + refreshToken）
    ▼
[客户端] ←─── JSON 响应 { code: 200, data: { accessToken, refreshToken, ... } }


[客户端后续请求]
    │
    │ ① GET /api/v1/biz/employee (携带 Authorization: Bearer <accessToken>)
    ▼
[API 网关 (端口 9000)]
    │
    │ ② AuthFilter 拦截：
    │    ├─ 校验白名单 → 非白名单继续
    │    ├─ 校验 Authorization 头格式 → Bearer <token>
    │    ├─ RS256 公钥验签 → 解析 Claims
    │    │    ├─ 签名无效 → 返回 401 TOKEN_INVALID
    │    │    └─ 签名有效 →
    │    │         ├─ Token 过期 → 返回 401 TOKEN_EXPIRED
    │    │         └─ Token 有效 →
    │    │              ├─ 查询 Redis: auth:token:blacklist:{signature}
    │    │              │    ├─ 在黑名单中 → 返回 401 TOKEN_BLACKLISTED
    │    │              │    └─ 不在黑名单 →
    │    │              │         ├─ 查询 Redis: auth:session:{userId}:{clientType}
    │    │              │         │    ├─ 不存在 → 返回 401 SESSION_KICKED_OUT
    │    │              │         │    └─ 存在 →
    │    │              │         │         ├─ 查询 Redis: auth:account:status:{userId}
    │    │              │         │         │    ├─ 禁用/封禁 → 返回 403 ACCOUNT_DISABLED/BANNED
    │    │              │         │         │    └─ 正常 →
    │    │              │         │         │         ├─ 查询 Redis: auth:tenant:status:{tenantId}
    │    │              │         │         │         │    ├─ 禁用/过期 → 返回 403 TENANT_DISABLED/EXPIRED
    │    │              │         │         │         │    └─ 正常 →
    │    │              │         │         │         │         └─ ③ 放行并透传用户信息 Header
    │    │              │         │         │         │            (X-User-Id, X-Tenant-Id, X-User-Name, X-Client-Type, X-Roles, X-Permissions)
    ▼
[目标业务服务]
    │ ④ 从请求头获取用户信息，执行业务逻辑
    ▼
[客户端] ←─── JSON 响应
```

### 4.1.1 多模式登录数据流（v0.1.6 策略模式编排）

```
[客户端]
    │
    │ ① POST /api/v1/auth/login
    │ { loginMode: "PHONE_CODE" | "PHONE_PASSWORD" | "OAUTH" | "USERNAME_PASSWORD",
    │   phone / smsCode / oauthProvider / oauthCode / loginName / password,
    │   tenantCode, clientType }
    ▼
[API 网关 (端口 9000)]
    │ 白名单路径，直接放行
    ▼
[认证服务 - AuthenticationService]
    │
    │ ② LoginStrategyFactory.getStrategy(loginMode)
    │    ├─ loginMode="USERNAME_PASSWORD" → UsernamePasswordStrategy
    │    │   → 校验 loginName + password（BCrypt）
    │    ├─ loginMode="PHONE_CODE" → PhoneCodeLoginStrategy
    │    │   → 校验 phone + smsCode（VerificationCodeManager.verifyCode）
    │    ├─ loginMode="PHONE_PASSWORD" → PhonePasswordLoginStrategy
    │    │   → 校验 phone + password（BCrypt）
    │    └─ loginMode="OAUTH" → OAuthLoginStrategy
    │        → 校验 oauthProvider + oauthCode（OAuth 提供商验证）
    │
    │ ③ 校验通过 → 返回 AuthResult { userId, tenantId, roles, permissions }
    │
    │ ④ 统一认证后处理（所有模式共享）：
    │    ├─ 校验用户状态（含 account_settled 校验）
    │    ├─ 校验租户状态
    │    ├─ 构建 LoginUserDTO
    │    ├─ JwtUtils.generateAccessToken → Access Token (2h)
    │    ├─ JwtUtils.generateRefreshToken → Refresh Token (7d)
    │    ├─ 同端互斥处理（同类型端踢下线）
    │    ├─ 写入 Redis 登录态会话
    │    ├─ 缓存账号/租户状态
    │    ├─ 记录登录日志
    │    └─ 更新最后登录时间和 IP
    │
    │ ⑤ 返回 TokenPairDTO
    ▼
[客户端] ←─── JSON 响应 { code: 200, data: { accessToken, refreshToken, ... } }
```

### 4.1.2 验证码发送数据流（v0.1.6）

```
[客户端]
    │
    │ ① POST /api/v1/auth/verification-code/send
    │ { target: "138****1234" | "user@example.com",
    │   purpose: "REGISTER" | "LOGIN" | "RESET_PASSWORD" | "CHANGE_PHONE",
    │   mode: "SMS" | "EMAIL" }
    ▼
[API 网关 (端口 9000)]
    │ 白名单路径，直接放行
    ▼
[认证服务 - VerificationCodeManager]
    │
    │ ② isSendTooFrequent(target, purpose)
    │    ├─ 60秒内已发送 → 返回 429 SMS_SEND_TOO_FREQUENT
    │    └─ 未超过频率限制 →
    │         ③ generateCode(target, mode, purpose)
    │            ├─ 生成 6 位数字验证码
    │            ├─ 写入 t_auth_verification_code（或 Redis key）
    │            └─ 设置 TTL 5 分钟（或 expire_time）
    │         ④ VerificationCodeService.sendSmsCode/sendEmailCode
    │            ├─ SimulatedVerificationCodeService（模拟实现）：日志输出验证码
    │            └─ 未来对接真实短信/邮件网关
    │         ⑤ 返回发送成功
    ▼
[客户端] ←─── JSON 响应 { code: 200, message: "验证码已发送" }
```

### 4.1.3 密码找回数据流（v0.1.6）

```
[客户端]
    │
    │ ① POST /api/v1/auth/password/forgot/send-code
    │ { target: "138****1234", mode: "SMS" }
    ▼
[认证服务 - PasswordService]
    │ ② 校验 target 对应账号存在
    │ ③ VerificationCodeManager.generateCode → 生成验证码并发送
    │ ④ 返回发送成功
    ▼
[客户端] ←─── JSON 响应

    │
    │ ⑤ POST /api/v1/auth/password/forgot/reset
    │ { target, mode: "SMS", code, newPassword, confirmPassword }
    ▼
[认证服务 - PasswordService]
    │
    │ ⑥ VerificationCodeManager.verifyCode(target, code, purpose="RESET_PASSWORD")
    │    ├─ 验证码无效 → 返回 400 SMS_CODE_INVALID
    │    ├─ 验证码过期 → 返回 400 SMS_CODE_EXPIRED
    │    └─ 校验通过 → 标记验证码为已使用（used=1, used_time=now）
    │
    │ ⑦ BCrypt 加密新密码
    │ ⑧ 更新 t_auth_user.password + last_password_change_time
    │ ⑨ 清理该用户所有 Redis 登录态会话（强制重新登录）
    │ ⑩ 返回操作成功
    ▼
[客户端] ←─── JSON 响应 { code: 200, message: "密码重置成功" }
```

### 4.1.4 管理员请求认证数据流（v0.1.7）

```
[管理员客户端]
    │
    │ ① GET /api/v1/admin/users (携带 Authorization: Bearer <token>)
    ▼
[API 网关 (端口 9000)]
    │ 检查路由匹配：/api/v1/admin/** → cloudoffice-admin-service
    │ AuthFilter 基础 Token 校验（RS256 验签 + Redis 黑名单/登录态校验）
    ▼
[管理中台服务 (端口 9500)]
    │
    │ ② AdminAuthFilter 拦截（OncePerRequestFilter）：
    │    ├─ 校验白名单路径 → /api/v1/admin/health 放行
    │    ├─ 校验 Authorization 头格式 → Bearer <token>
    │    ├─ 解析 JWT Claims（认证服务 RS256 公钥验签）
    │    ├─ 校验 roles 字段是否包含 SUPRE_ADMIN 或 SYSTEM_ADMIN
    │    │    ├─ 不包含管理员角色 → 返回 403 ADMIN-0001
    │    │    └─ 包含管理员角色 →
    │    │         ③ 设置 AdminContext（adminId/adminName/realName/roles）
    │    │         ④ 放行请求到 Controller
    │    ▼
    │ ⑤ 业务方法执行（如列表查询/创建用户等）
    │    ├─ @AdminAuditLog 切面记录审计日志
    │    └─ AuthServiceClient Feign 调用 auth-service（如用户查询）
    │
    │ ⑥ 请求完成 → finally 块执行 AdminContext.clear()
    ▼
[管理员客户端] ←─── JSON 响应 { code: 200, data: { ... } }
```

### 4.1.5 OpenFeign 服务间调用数据流（v0.1.7）

```
[admin-service - AdminUserService]
    │
    │ ① 调用 AuthServiceClient.listUsers(queryParams)
    ▼
[admin-service - Feign 拦截器]
    │ ② FeignRequestInterceptor.apply():
    │    ├─ 从 AdminContext 获取当前管理员 JWT Token
    │    └─ 设置请求头 Authorization: Bearer <token>
    ▼
[HTTP 请求 → Nacos 负载均衡]
    │ ③ Spring Cloud LoadBalancer 从 Nacos 获取 auth-service 可用实例
    │ ④ 轮询策略选择目标实例
    ▼
[auth-service - AdminUserController]
    │
    │ ⑤ 接收请求，校验管理员身份和权限
    │ ⑥ 执行用户数据操作（查询用户表/角色表等）
    │ ⑦ 返回 ApiResult<PageResult<AdminUserVO>>
    ▼
[admin-service - AuthServiceClient]
    │
    │ ⑧ Feign 响应反序列化
    │ ⑨ 业务层处理返回数据（如手机号/邮箱脱敏）
    ▼
[admin-service - Controller]
    │ ⑩ 返回统一响应体给客户端
    │
    │ 超时/异常处理：
    │ ├─ 连接超时 5s → 抛出 RetryableException → 服务层捕获
    │ ├─ 读取超时 10s → 抛出 RetryableException → 服务层捕获
    │ └─ auth-service 不可用 → 负载均衡无可用实例 → 抛出异常 → 返回 ADMIN-0006
    ▼
[返回统一错误响应]
```

### 4.1.6 审计日志记录数据流（v0.1.7）

```
[管理员操作触发]
    │
    │ ① 业务方法执行（如 POST /api/v1/admin/users 创建用户）
    ▼
[AdminAuditLogAspect (环绕通知)]
    │
    │ ② 获取 AdminContext.getCurrentAdmin() → 当前操作人信息
    │ ③ 记录操作开始时间
    │ ④ 执行目标方法（proceed()）
    │    ├─ 执行成功 → 记录 result=SUCCESS, 返回结果
    │    └─ 抛出异常 → 记录 result=FAILURE, 异常信息
    │
    │ ⑤ 构建 AdminAuditLogEntity：
    │    ├─ admin_id / admin_name（操作人）
    │    ├─ action_type（操作类型：CREATE_USER/DISABLE_USER/RESET_PASSWORD 等）
    │    ├─ target_id / target_name（操作目标）
    │    ├─ detail（操作详情 JSON，截断至 1024 字符）
    │    ├─ result（SUCCESS / FAILURE）
    │    ├─ error_message（失败时的错误信息）
    │    ├─ request_ip / user_agent
    │    └─ create_time
    │
    │ ⑥ 异步写入 cloudstroll_office_admin.t_admin_audit_log
    │    └─ try-catch 隔离，写入失败仅记录 warn 日志，不影响主业务流程
    ▼
[继续执行原有业务逻辑]
```

### 4.2 模块间数据流转

| 数据流 | 发起方 | 接收方 | 通信方式 | 数据格式 | 说明 |
|--------|--------|--------|---------|---------|------|
| 注册服务实例 | 各微服务 | Nacos Server | gRPC/HTTP | 服务元数据 | 服务启动时自动注册 |
| 获取服务列表 | Gateway | Nacos Server | gRPC/HTTP | 服务实例列表 | 路由转发的服务发现 |
| 请求路由转发 | Gateway | 业务服务 | HTTP | JSON | 根据路径匹配规则转发 |
| Token验签公钥 | auth-service | Gateway | 配置共享 | Base64 公钥 RS256 | 通过配置文件/环境变量/配置中心共享 |
| 黑名单查询 | Gateway | Redis | RESP | String | 查询 Token 是否被吊销 |
| 登录态查询 | Gateway | Redis | RESP | String | 查询登录会话是否有效 |
| 账号/租户状态查询 | Gateway | Redis | RESP | String | 查询账号和租户状态 |
| 登录态写入 | auth-service | Redis | RESP | String (JSON) | 登录成功写入会话 |
| 黑名单写入 | auth-service | Redis | RESP | String | 登出/踢人时加入黑名单 |
| 登录日志写入 | auth-service | MariaDB | JDBC | Insert SQL | 记录登录日志审计 |
| 健康检查 | 客户端 | 各服务 | HTTP GET | JSON (ApiResult) | 确认服务存活状态 |
| 管理员请求路由转发（v0.1.7） | Gateway | admin-service | HTTP | JSON | 根据 `/api/v1/admin/**` 路由规则转发到 admin-service |
| 管理员用户查询（v0.1.7） | admin-service | auth-service | OpenFeign HTTP | JSON (ApiResult<PageResult>) | AdminUserService 通过 AuthServiceClient 调用 auth-service 获取用户数据 |
| 管理员创建用户（v0.1.7） | admin-service | auth-service | OpenFeign HTTP | JSON (CreateUserRequest) | admin-service 通过 Feign 调用 auth-service 创建用户 |
| 管理员编辑用户（v0.1.7） | admin-service | auth-service | OpenFeign HTTP | JSON (UpdateUserRequest) | admin-service 通过 Feign 调用 auth-service 编辑用户信息 |
| 启用/禁用用户（v0.1.7） | admin-service | auth-service | OpenFeign HTTP | JSON (UserStatusRequest) | admin-service 通过 Feign 调用 auth-service 修改用户状态 + 清除 Redis 会话 |
| 重置密码（v0.1.7） | admin-service | auth-service | OpenFeign HTTP | JSON (ResetPasswordRequest) | admin-service 通过 Feign 调用 auth-service 重置用户密码 + 清除 Redis 会话 |
| 角色分配（v0.1.7） | admin-service | auth-service | OpenFeign HTTP | JSON (AssignRolesRequest) | admin-service 通过 Feign 调用 auth-service 全量替换用户角色 + 清除 Redis 会话 |
| 审计日志写入（v0.1.7） | admin-service | MariaDB | JDBC | Insert SQL | @AdminAuditLog AOP 切面自动记录操作审计日志（try-catch 隔离） |
| 审计日志查询（v0.1.7） | admin-service | MariaDB | JDBC | Select SQL | 管理员查询审计日志列表 |
| API 文档 | 客户端 | 各服务 | HTTP GET | JSON/HTML | SpringDoc 自动生成 |
| 验证码生成/校验（v0.1.6） | auth-service | Redis/MariaDB | JDBC/RESP | Insert/Select | VerificationCodeManager 管理验证码生命周期 |
| 验证码发送（v0.1.6） | auth-service | 日志（模拟） | 日志输出 | String | SimulatedVerificationCodeService 输出验证码到日志 |
| OAuth 账号绑定查询（v0.1.6） | auth-service | MariaDB | JDBC | Select | OAuthAccountMapper 按 openId 查询绑定关系 |

### 4.3 数据存储流转

| 数据类型 | 产生阶段 | 存储位置 | 消费阶段 | 生命周期 |
|---------|---------|---------|---------|---------|
| JWT RS256 密钥对 | 部署配置 | 环境变量/配置文件 | 令牌签发（私钥）与校验（公钥） | 持久（定期轮换） |
| BCrypt 密码 | 用户注册 | `t_auth_user.password` | 登录验证 | 持久 |
| 用户会话（Session） | 登录成功 | Redis `auth:session:{userId}:{clientType}` | 每次请求校验 | 临时（TTL 7 天） |
| Token 黑名单 | 登出/踢人/刷新 | Redis `auth:token:blacklist:{signature}` | 每次请求校验 | 临时（TTL=Token 剩余有效期） |
| 账号状态缓存 | 登录/状态变更 | Redis `auth:account:status:{userId}` | 每次请求校验 | 手动管理（变更时更新/清除） |
| 租户状态缓存 | 登录/状态变更 | Redis `auth:tenant:status:{tenantId}` | 每次请求校验 | 手动管理（变更时更新/清除） |
| 登录日志 | 登录成功/失败 | MariaDB `t_auth_login_log` | 安全审计 | 持久 |
| 验证码（v0.1.6） | 验证码发送 | Redis `auth:verification:{purpose}:{target}` + MariaDB `t_auth_verification_code` | 注册/登录/密码找回/手机号变更 | 临时（TTL 5 分钟） |
| OAuth 账号绑定（v0.1.6） | OAuth 注册/绑定 | MariaDB `t_auth_oauth_account` | OAuth 登录/解绑 | 持久 |
| 业务数据 | 业务操作 | MariaDB | 业务查询 | 持久 |
| 管理员审计日志（v0.1.7） | 管理员操作 | MariaDB `cloudstroll_office_admin.t_admin_audit_log` | 审计日志查询 | 持久（不可修改/删除）|
| 管理员请求上下文（v0.1.7） | AdminAuthFilter 认证通过 | ThreadLocal (AdminContext) | 请求处理期间 | 临时（请求结束时 finally 清理）|

---

## 5. 数据架构

### 5.1 数据模型概览

v0.1.0 为骨架搭建阶段，v0.1.5 在 `cloudstroll_office_auth` 数据库中新增 7 张认证业务表，实现 RBAC 多租户权限模型和登录日志审计。v0.1.6 新增 2 张认证业务表（`t_auth_oauth_account`、`t_auth_verification_code`）并扩展 `t_auth_user` 表，支持多模式注册/登录、OAuth 账号绑定和验证码管理。v0.1.7 新增 `cloudstroll_office_admin` 数据库（用于存储管理中台审计日志等管理数据），并预置管理员角色和初始超级管理员账号数据到 `t_auth_role` 和 `t_auth_user` 表。

**认证服务数据库（cloudstroll_office_auth）表结构关系：**

```
┌─────────────────┐       ┌───────────────────┐
│   t_auth_tenant  │       │   t_auth_user      │
│─────────────────│       │───────────────────│
│ id (PK)         │◄──────│ tenant_id          │
│ tenant_name     │       │ id (PK)            │
│ tenant_code (UK)│       │ login_name         │
│ status          │       │ password(BCrypt)   │
│ expire_time     │       │ status             │
│ max_user_count  │       │ ...                │
└─────────────────┘       └────────┬──────────┘
                                   │
                                   │ 多对多
                                   ▼
                          ┌───────────────────┐       ┌───────────────────┐
                          │  t_auth_user_role  │       │  t_auth_role       │
                          │───────────────────│       │───────────────────│
                          │ id (PK)           │       │ id (PK)            │
                          │ user_id (FK)      │──────►│ tenant_id           │
                          │ role_id (FK)      │       │ role_name          │
                          │ UNIQUE(user,role) │       │ role_code (UK)     │
                          └───────────────────┘       │ status             │
                                                      └────────┬──────────┘
                                                               │
                                                               │ 多对多
                                                               ▼
                          ┌───────────────────┐       ┌───────────────────┐
                          │ t_auth_role_perm  │       │ t_auth_permission  │
                          │───────────────────│       │───────────────────│
                          │ id (PK)           │       │ id (PK)            │
                          │ role_id (FK)      │──────►│ parent_id          │
                          │ permission_id (FK)│       │ perm_name          │
                          │ UNIQUE(role,perm) │       │ perm_code (UK)     │
                          └───────────────────┘       │ perm_type          │
                                                      │ path               │
                                                      │ method             │
                                                      │ ...                │
                                                      └───────────────────┘

┌─────────────────────┐
│  t_auth_login_log    │
│─────────────────────│
│ id (PK)             │
│ tenant_id           │
│ user_id             │
│ login_name          │
│ login_ip            │
│ client_type         │
│ login_status        │
│ login_time          │
│ logout_time         │
│ fail_reason         │
│ ...                 │
└─────────────────────┘

**v0.1.6 新增表：**

```
┌──────────────────────────┐       ┌──────────────────────────────┐
│  t_auth_oauth_account     │       │  t_auth_verification_code     │
│──────────────────────────│       │──────────────────────────────│
│ id (PK)                  │       │ id (PK)                      │
│ user_id (FK) ────────────►───    │ target (手机号/邮箱)          │
│ oauth_provider           │   │   │ code (6位数字验证码)          │
│ oauth_open_id (UK)       │   │   │ send_mode (SMS / EMAIL)      │
│ oauth_union_id           │   │   │ purpose (REGISTER/LOGIN/     │
│ oauth_nickname           │   │   │          RESET_PASSWORD/     │
│ oauth_avatar             │   │   │          CHANGE_PHONE)       │
│ bound_time               │   │   │ expire_time                  │
│ ...                      │   │   │ used (0-未使用, 1-已使用)    │
└──────────────────────────┘   │   │ used_time                    │
                               │   │ send_count                   │
                               │   │ ...                          │
                               │   └──────────────────────────────┘
                               │
                                └─── t_auth_user 扩展字段：
                                     register_mode (VARCHAR(32))
                                     account_settled (TINYINT)
                                     phone_verified (TINYINT)
                                     email_verified (TINYINT)
                                     last_password_change_time (DATETIME)
```

**v0.1.7 新增数据库（cloudstroll_office_admin）：**

```
┌─────────────────────────────────────────┐
│  cloudstroll_office_admin 数据库          │
│─────────────────────────────────────────│
│                                         │
│  ┌──────────────────────────────────┐   │
│  │  t_admin_audit_log               │   │
│  │──────────────────────────────────│   │
│  │ id (PK, 雪花算法)                │   │
│  │ admin_id (BIGINT, 操作人ID)      │   │
│  │ admin_name (VARCHAR, 操作人名称)  │   │
│  │ action_type (VARCHAR, 操作类型)   │   │
│  │ target_id (BIGINT, 目标ID)       │   │
│  │ target_name (VARCHAR, 目标名称)   │   │
│  │ detail (JSON/VARCHAR, 操作详情)   │   │
│  │ result (TINYINT, 操作结果)        │   │
│  │ error_message (VARCHAR, 错误信息) │   │
│  │ request_ip (VARCHAR, 请求IP)     │   │
│  │ user_agent (VARCHAR, 用户代理)   │   │
│  │ create_time (DATETIME)           │   │
│  │ update_time (DATETIME)           │   │
│  │ deleted (TINYINT, 逻辑删除)      │   │
│  └──────────────────────────────────┘   │
│                                         │
│  索引：                                  │
│  idx_audit_admin_id (admin_id)          │
│  idx_audit_action_type (action_type)    │
│  idx_audit_target_id (target_id)        │
│  idx_audit_create_time (create_time)    │
└─────────────────────────────────────────┘
```

### 5.2 存储策略

| 数据类型 | 存储方案 | 理由 | 一致性要求 |
|---------|---------|------|-----------|
| 用户账号与认证数据 | MariaDB（auth 库） | 关系型数据，支持事务 ACID | 强一致性 |
| 租户信息 | MariaDB（auth 库） | 关系型数据，需要事务保证 | 强一致性 |
| 角色与权限数据 | MariaDB（auth 库） | 关系型数据，支持复杂关联查询 | 强一致性 |
| 登录日志审计 | MariaDB（auth 库） | 持久化存储，支持查询分析 | 最终一致性 |
| 企业业务数据 | MariaDB（biz 库） | 关系型数据，需 ACID 保证 | 强一致性 |
| 系统配置与日志 | MariaDB（system 库） | 关系型数据 | 最终一致性（日志可接受） |
| 用户登录会话 | Redis | 高速读写，TTL 自动过期 | 最终一致性 |
| Token 黑名单 | Redis | 高速读写，TTL 自动过期 | 最终一致性 |
| 账号/租户状态缓存 | Redis | 高速读取，实时更新 | 最终一致性 |
| OAuth 账号绑定（v0.1.6） | MariaDB（auth 库） | 关系型数据，支持按 openId 查询 | 强一致性 |
| 验证码记录（v0.1.6） | Redis（优先）+ MariaDB（回退） | Redis 自动过期减少清理负担，DB 兜底保证可用性 | 最终一致性 |
| 管理员审计日志（v0.1.7） | MariaDB（admin 库） | 管理操作审计，持久化存储，支持查询分析 | 最终一致性（插入失败不影响主业务）|

### 5.3 数据一致性策略

- **单服务内事务：** 使用本地数据库事务（`@Transactional`）保证 ACID
- **Redis 与数据库一致性：** 采用 Cache-Aside 模式，更新数据库后主动更新或清除 Redis 缓存（如账号状态变更时同步更新 Redis 缓存）
- **缓存降级：** Redis 不可用时，网关降级为仅做 JWT 公钥验签，不查询 Redis 黑名单和登录态（需配置降级策略）
- **跨服务分布式事务：** 使用 Seata AT 模式保证最终一致性（本期预留，后续引入）
- **消息队列异步通信：** RocketMQ 事务消息保证生产者本地事务与消息发送的原子性（后续集成）

### 5.4 v0.1.5 新增数据库表（v0.1.5 已创建）

| 表名 | 用途 | 关联用户故事 | 索引 |
|------|------|-------------|------|
| `t_auth_tenant` | 租户企业信息，支持状态控制和用户数限制 | US-007 | `uk_tenant_code`（tenant_code） |
| `t_auth_user` | 用户账号，多租户隔离，BCrypt 密码存储 | US-006 | `uk_tenant_login_name`（tenant_id+login_name）、`idx_tenant_status`（tenant_id+status）、`idx_phone`（phone） |
| `t_auth_role` | 角色定义，租户内隔离 | US-009 | `uk_tenant_role_code`（tenant_id+role_code） |
| `t_auth_permission` | 权限点定义，树形结构组织 | US-010 | `uk_perm_code`（perm_code） |
| `t_auth_user_role` | 用户-角色多对多关联 | US-011 | `uk_user_role`（user_id+role_id）、`idx_user_id`、`idx_role_id` |
| `t_auth_role_permission` | 角色-权限多对多关联 | US-012 | `uk_role_permission`（role_id+permission_id）、`idx_role_id`、`idx_permission_id` |
| `t_auth_login_log` | 登录日志审计 | US-022 | `idx_user_id`、`idx_tenant_id`、`idx_login_time` |

### 5.4.1 v0.1.6 新增/变更数据库表

| 表名 | 用途 | 关联用户故事 | 索引 |
|------|------|-------------|------|
| `t_auth_oauth_account` | OAuth 第三方账号关联表，记录用户与第三方平台的绑定关系 | US-011 | `uk_provider_openid`（oauth_provider+oauth_open_id）、`idx_user_id`（user_id） |
| `t_auth_verification_code` | 验证码记录表，支持验证码生成/校验/过期处理 | US-012 | `idx_target_purpose`（target+purpose）、`idx_expire_time`（expire_time） |
| `t_auth_user`（变更） | 用户表扩展字段：`register_mode`、`account_settled`、`phone_verified`、`email_verified`、`last_password_change_time` | US-013 | 保持 `idx_phone`、`idx_tenant_status`、`uk_tenant_login_name` 不变 |

### 5.4.2 v0.1.7 新增数据库表（cloudstroll_office_admin 数据库）

| 表名 | 用途 | 关联用户故事 | 索引 |
|------|------|-------------|------|
| `t_admin_audit_log` | 管理员关键操作审计日志记录（如创建/禁用/重置密码/角色分配等），不可修改或删除 | US-014 | `idx_audit_admin_id`（admin_id）、`idx_audit_action_type`（action_type）、`idx_audit_target_id`（target_id）、`idx_audit_create_time`（create_time） |

### 5.4.3 v0.1.7 管理员角色预置数据（auth 数据库）

| 表名 | 预置数据 | 说明 |
|------|---------|------|
| `t_auth_role` | `SUPER_ADMIN`(超级管理员)、`SYSTEM_ADMIN`(系统管理员) | 初始化脚本插入，使用 `INSERT IGNORE` 防重复 |
| `t_auth_user` | 初始超级管理员账号：loginName=admin, password=Admin@123456(BCrypt) | 初始化脚本插入 |
| `t_auth_user_role` | admin 用户关联 `SUPER_ADMIN` 角色 | 初始化脚本关联 |

### 5.5 Redis Key 设计

| Key 格式 | 类型 | TTL | 用途 | 操作方 |
|---------|------|-----|------|--------|
| `auth:session:{userId}:{clientType}` | String | 7 天（与 Refresh Token 一致） | 登录态会话缓存（JSON 含 accessToken/refreshToken/loginTime/ip/deviceInfo） | auth-service写入，gateway读取 |
| `auth:token:blacklist:{tokenSignature}` | String | Token 剩余有效期 | Token 黑名单（吊销的 Token） | auth-service写入，gateway读取 |
| `auth:account:status:{userId}` | String | 手动管理 | 账号状态缓存（加速校验，减少 DB 查询） | auth-service写入/更新，gateway读取 |
| `auth:tenant:status:{tenantId}` | String | 手动管理 | 租户状态缓存 | auth-service写入/更新，gateway读取 |
| `auth:verification:{purpose}:{target}`（v0.1.6） | String | 5 分钟（与验证码有效期一致） | 验证码缓存（6 位数字验证码，利用 Redis TTL 自动过期） | auth-service写入/校验，支持 TTL 自动清理 |
| `auth:verification:freq:{purpose}:{target}`（v0.1.6） | String | 60 秒 | 验证码发送频率控制 Key（用于频控校验 `isSendTooFrequent`） | auth-service写入/读取 |

### 5.6 数据库设计规范

| 类别 | 规则 |
|------|------|
| 数据库 | 每服务独立数据库，命名 `cloudstroll_office_{module}` |
| 表命名 | `t_{module}_{table_name}`（如 `t_auth_user`）|
| 字段命名 | 下划线命名法（如 `user_name`、`create_time`）|
| 主键 | 雪花算法（BIGINT），字段名统一 `id` |
| 公共字段 | 每表必须包含 `id`、`create_time`、`update_time`、`deleted`（逻辑删除）|
| 索引命名 | 普通索引 `idx_{table}_{column}`，唯一索引 `uk_{table}_{column}` |

---

## 6. 接口设计

### 6.1 外部接口

| 接口名称 | 协议 | 路径 | 认证方式 | 调用方 | 说明 |
|---------|------|------|---------|--------|------|
| 网关入口 | HTTP | `http://localhost:9000/api/v1/{module}/**` | JWT Bearer Token | Flutter 客户端/第三方 | 统一 API 入口，网关 AuthFilter 拦截校验 |
| 多模式登录 | HTTP POST | `/api/v1/auth/login` | 无（白名单） | 客户端 | 支持 4 种登录模式（USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH），通过 loginMode 字段区分，返回双 Token |
| 多模式注册 | HTTP POST | `/api/v1/auth/register` | 无（白名单） | 客户端 | 支持 5 种注册模式（USERNAME/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO），通过 registerMode 字段区分 |
| Token 刷新 | HTTP POST | `/api/v1/auth/refresh` | 无（白名单，需 Refresh Token） | 客户端 | 刷新 Access Token 和 Refresh Token |
| 用户登出 | HTTP POST | `/api/v1/auth/logout` | JWT | 客户端 | 主动登出，Token 入黑名单 |
| 强制踢人 | HTTP POST | `/api/v1/auth/kickout` | JWT（管理员） | 管理员 | 强制踢用户下线 |
| 修改密码（v0.1.6） | HTTP PUT | `/api/v1/auth/password/change` | JWT | 客户端 | 校验原密码后修改密码，加密存储，可选清理登录态 |
| 密码找回-发送验证码（v0.1.6） | HTTP POST | `/api/v1/auth/password/forgot/send-code` | 无（白名单） | 客户端 | 发送验证码至邮箱或手机 |
| 密码找回-重置密码（v0.1.6） | HTTP POST | `/api/v1/auth/password/forgot/reset` | 无（白名单） | 客户端 | 校验验证码后重置密码，清理所有登录态 |
| 修改手机号（v0.1.6） | HTTP PUT | `/api/v1/auth/phone/change` | JWT | 客户端 | 原手机号可用/已停用两种场景，双验证码校验 |
| 完善账号信息（v0.1.6） | HTTP PUT | `/api/v1/auth/account/settlement` | JWT | 客户端 | 两步注册第二步，补充用户名/密码/手机号 |
| 发送验证码（v0.1.6） | HTTP POST | `/api/v1/auth/verification-code/send` | 无（白名单） | 客户端 | 通用验证码发送，支持 REGISTER/LOGIN/RESET_PASSWORD/CHANGE_PHONE 用途 |
| 用户列表 | HTTP GET | `/api/v1/auth/users` | JWT（管理员） | 管理员 | 租户内用户分页查询 |
| 用户详情 | HTTP GET | `/api/v1/auth/users/{userId}` | JWT（管理员） | 管理员 | 用户基本信息+角色+权限 |
| 修改用户 | HTTP PUT | `/api/v1/auth/users/{userId}` | JWT（管理员） | 管理员 | 修改用户信息 |
| 修改用户状态 | HTTP PUT | `/api/v1/auth/users/{userId}/status` | JWT（管理员） | 管理员 | 禁用/封禁/解封用户 |
| 分配用户角色 | HTTP PUT | `/api/v1/auth/users/{userId}/roles` | JWT（管理员） | 管理员 | 全量更新用户角色 |
| 删除用户 | HTTP DELETE | `/api/v1/auth/users/{userId}` | JWT（管理员） | 管理员 | 逻辑删除用户 |
| 角色列表 | HTTP GET | `/api/v1/auth/roles` | JWT（管理员） | 管理员 | 租户内角色列表 |
| 创建角色 | HTTP POST | `/api/v1/auth/roles` | JWT（管理员） | 管理员 | 创建新角色 |
| 修改角色 | HTTP PUT | `/api/v1/auth/roles/{roleId}` | JWT（管理员） | 管理员 | 修改角色信息 |
| 分配角色权限 | HTTP PUT | `/api/v1/auth/roles/{roleId}/permissions` | JWT（管理员） | 管理员 | 全量更新角色权限 |
| 删除角色 | HTTP DELETE | `/api/v1/auth/roles/{roleId}` | JWT（管理员） | 管理员 | 逻辑删除角色 |
| 权限列表 | HTTP GET | `/api/v1/auth/permissions` | JWT（管理员） | 管理员 | 树形结构权限列表 |
| 创建权限 | HTTP POST | `/api/v1/auth/permissions` | JWT（管理员） | 管理员 | 创建新权限点 |
| 修改权限 | HTTP PUT | `/api/v1/auth/permissions/{permId}` | JWT（管理员） | 管理员 | 修改权限信息 |
| 删除权限 | HTTP DELETE | `/api/v1/auth/permissions/{permId}` | JWT（管理员） | 管理员 | 逻辑删除权限 |
| 认证-健康检查 | HTTP GET | `/api/v1/auth/health` | 无 | 客户端/监控 | 认证服务存活检测 |
| 企业-健康检查 | HTTP GET | `/api/v1/biz/health` | 无 | 客户端/监控 | 企业服务存活检测 |
| 系统-健康检查 | HTTP GET | `/api/v1/system/health` | 无 | 客户端/监控 | 系统服务存活检测 |
| 管理中台-健康检查（v0.1.7） | HTTP GET | `/api/v1/admin/health` | 无（白名单） | 管理员/监控 | 管理中台服务存活检测 |
| 用户列表查询（v0.1.7） | HTTP GET | `/api/v1/admin/users` | JWT（管理员角色） | 管理员 | 分页查询用户列表，支持关键词/状态/角色/时间范围筛选 |
| 用户详情查询（v0.1.7） | HTTP GET | `/api/v1/admin/users/{userId}` | JWT（管理员角色） | 管理员 | 查看用户完整信息（含角色/注册时间/最后登录等） |
| 创建用户（v0.1.7） | HTTP POST | `/api/v1/admin/users` | JWT（管理员角色） | 管理员 | 创建新用户（登录名/密码/姓名/手机号/邮箱/角色），注册模式 ADMIN_CREATE |
| 编辑用户（v0.1.7） | HTTP PUT | `/api/v1/admin/users/{userId}` | JWT（管理员角色） | 管理员 | 编辑用户基本信息（真实姓名/手机号/邮箱）|
| 启用/禁用用户（v0.1.7） | HTTP PUT | `/api/v1/admin/users/{userId}/status` | JWT（管理员角色） | 管理员 | 启用（status=0）或禁用（status=1）用户，禁用时清除 Redis 会话 |
| 重置用户密码（v0.1.7） | HTTP PUT | `/api/v1/admin/users/{userId}/password/reset` | JWT（管理员角色） | 管理员 | 重置指定用户密码，清除 Redis 会话 |
| 用户角色分配（v0.1.7） | HTTP PUT | `/api/v1/admin/users/{userId}/roles` | JWT（管理员角色） | 管理员 | 全量替换用户角色，清除 Redis 会话 |
| 审计日志查询（v0.1.7） | HTTP GET | `/api/v1/admin/audit-logs` | JWT（管理员角色） | 管理员 | 分页查询审计日志，支持时间范围/操作类型/管理员 ID 筛选 |
| API 文档 | HTTP GET | `/swagger-ui.html` 或 `/v3/api-docs` | 无（开发环境） | 开发者 | SpringDoc 在线文档 |

### 6.2 内部接口

| 接口名称 | 通信方式 | 数据格式 | 调用关系 | 说明 |
|---------|---------|---------|---------|------|
| 服务注册 | Nacos SDK | 服务元数据 | 各服务 → Nacos Server | 自动注册与心跳维持 |
| 配置拉取 | Nacos SDK | YAML/Properties | 各服务 → Nacos Server | bootstrap.yml 指定配置中心地址 |
| 服务发现 | Spring Cloud LoadBalancer | 服务实例列表 | Gateway → Nacos Server | 路由转发时动态获取服务地址 |
| Redis 黑名单查询 | RESP 协议 | String | Gateway → Redis | 查询 Token 是否被吊销 |
| Redis 登录态查询 | RESP 协议 | String (JSON) | Gateway → Redis | 查询用户登录会话 |
| Redis 状态缓存 | RESP 协议 | String | Gateway/auth-service → Redis | 查询账号/租户状态 |
| 验证码缓存/校验（v0.1.6） | RESP 协议 | String | auth-service → Redis | 验证码存储/校验（利用 TTL 自动过期） |
| OAuth 账号查询（v0.1.6） | JDBC | SQL | auth-service → MariaDB | 按 openId 查询 OAuth 绑定关系 |

### 6.3 接口契约（统一响应体）

```java
// 统一响应体
public class ApiResult<T> {
    private Integer code;       // 状态码（200 成功、400 参数错误、401 未认证、403 无权限、404 不存在、500 服务器错误）
    private String message;     // 提示信息（简体中文）
    private T data;             // 泛型数据
    private Long timestamp;     // 时间戳
}

// 统一分页响应
public class PageResult<T> {
    private List<T> records;    // 数据列表
    private Long total;         // 总记录数
    private Integer page;       // 当前页码
    private Integer pageSize;   // 每页大小
}

// 登录响应 TokenPairDTO
public class TokenPairDTO {
    private String accessToken;             // Access Token (RS256, 2h)
    private String refreshToken;            // Refresh Token (RS256, 7d)
    private Long accessTokenExpiresIn;      // Access Token 过期毫秒时间戳
    private Long refreshTokenExpiresIn;     // Refresh Token 过期毫秒时间戳
    private String tokenType;               // 固定值 "Bearer"
}

// 用户信息透传 Header（网关 → 下游服务）
// X-User-Id: 123456
// X-Tenant-Id: 1
// X-User-Name: admin
// X-Client-Type: WINDOWS
// X-Roles: admin,operator
// X-Permissions: system:user:list,system:user:create
```

### 6.4 API 路由表

| 路由路径 | 目标服务 | 负载均衡策略 | 说明 |
|---------|---------|------------|------|
| `/api/v1/auth/**` | `cloudoffice-auth-service` | 轮询 | 认证相关请求（含登录/注册/刷新/登出/踢人/用户管理/角色管理/权限管理） |
| `/api/v1/biz/**` | `cloudoffice-biz-service` | 轮询 | 企业业务请求 |
| `/api/v1/system/**` | `cloudoffice-system-service` | 轮询 | 系统管理请求 |
| `/api/v1/admin/**` | `cloudoffice-admin-service` | 轮询 | 管理中台请求（管理员认证、用户管理、审计日志等）（v0.1.7 新增） |

---

## 7. 非功能性需求落地（NFR Implementation）

| PRD-NFR编号 | 非功能性需求 | 架构决策 | 量化指标 |
| --------- | -------- | ------------- | -------------- |
| NFR-001 | 性能 - 模块启动时间 ≤ 30 秒 | 去除不必要的自动配置，懒加载非关键组件；各服务不强制依赖数据库连接，无 DB 时可启动（WARN 日志） | 单模块首次启动 ≤ 30 秒 |
| NFR-001 | 性能 - 健康检查接口响应时间 < 100ms | 健康检查控制器使用简单逻辑，不依赖外部中间件，直接返回内存状态信息 | 健康检查响应时间 < 100ms |
| NFR-001 | 性能 - Maven 编译时间 ≤ 30 秒 | 父 POM 统一依赖版本管理，子模块无硬编码版本；增量编译仅编译变更模块 | `mvn clean compile -pl cloudoffice-auth-service -am` ≤ 30 秒 |
| NFR-001 | 性能 - Token 校验响应时间 ≤ 10ms | 网关层 RS256 公钥本地验签（无状态）+ Redis 查询（响应式非阻塞） | Token 校验 ≤ 10ms |
| NFR-001 | 性能 - 登录接口响应时间 ≤ 500ms | BCrypt 密码校验 + RS256 双 Token 签发 + Redis 写入 + 登录日志写入 | 登录接口 ≤ 500ms |
| NFR-001 | 性能 - 单次登录 Redis 读写 ≤ 5 次 | 优化 Redis 操作顺序：1) 旧会话删除 2) 黑名单写入 3) 新会话写入 4) 账号状态缓存 5) 租户状态缓存 | Redis 读写次数 ≤ 5 次 |
| NFR-001 | 性能 - 策略调度层零额外开销（v0.1.6） | 策略实例预先初始化（Spring 容器管理），运行时无反射/动态加载开销 | 策略获取 O(1) 时间复杂度 |
| NFR-003 | 可扩展性 - 新增认证模式无需修改核心流程（v0.1.6） | 策略模式设计，新增登录/注册模式仅需创建策略实现类并注册到工厂 | 新增模式仅改动策略层 |
| NFR-004 | 可维护性 - 策略实现职责单一（v0.1.6） | 每个策略类不超过 200 行，使用构造器注入，禁止 @Autowired 字段注入 | 策略类 ≤ 200 行 |
| NFR-005 | 安全性 - 验证码一次性使用（v0.1.6） | 验证码校验后立即标记为已使用（used=1），防重放攻击 | 验证码不可重复使用 |
| NFR-005 | 安全性 - 验证码发送频率控制（v0.1.6） | 同一 target 同一用途 60 秒内不可重复发送 | 发送间隔 ≥ 60 秒 |
| NFR-005 | 安全性 - 密码管理安全（v0.1.6） | 新密码 BCrypt 加密（强度≥10），新旧密码不在日志明文输出，密码修改后清理登录态 | 安全合规 |
| NFR-001 | 可用性 - Nacos 连接容错 | Nacos 连接失败时服务启动失败并给出明确错误提示，指导开发者检查 Nacos 地址和运行状态 | 错误信息明确提示 Nacos 连接失败原因 |
| NFR-002 | 可靠性 - 全局异常兜底 | `@RestControllerAdvice` + `@ExceptionHandler(Exception.class)` 兜底所有未捕获异常，返回统一错误体，不泄露堆栈明细到客户端 | 100% 未捕获异常走通用兜底处理器 |
| NFR-002 | 可靠性 - Redis 熔断降级 | Redis 不可用时网关给出明确降级提示，不泄漏 Redis 连接详情和堆栈信息 | 无 Redis 时可返回"服务暂不可用" |
| NFR-002 | 可维护性 - API 文档 | SpringDoc 自动生成 OpenAPI 3 文档，支持在线调试 | 各服务 `/swagger-ui.html` 可访问 |
| NFR-003 | 可维护性 - 服务间解耦 | 各服务模块无直接代码依赖，仅通过 Nacos 服务发现 + HTTP API 通信 | 一个服务故障不影响其他服务启动和运行 |
| NFR-004 | 性能 - Maven 编译 | 父 POM 统一依赖版本管理，子模块无硬编码版本 | 首次完整编译 ≤ 120 秒，增量编译 ≤ 10 秒 |
| NFR-005 | 可维护性 - 代码规范一致性 | 统一包结构、命名规范、构造器注入、Lombok 使用规范 | 通过 Checkstyle 规则验证 |
| **NFR-006** | **安全性 - JWT RS256 非对称加密** | **RS256 私钥仅认证服务持有，公钥共享到网关和业务服务；三种密钥加载方式（环境变量 > Base64 > PEM 文件）** | **私钥泄漏风险降低为 0（网关无私钥）** |
| **NFR-006** | **安全性 - Token 黑名单实时生效** | **Redis 存储黑名单，网关每次请求校验；黑名单 TTL=Token 剩余有效期，自动过期清理** | **Token 吊销后立即失效，无需等待自然过期** |
| **NFR-006** | **安全性 - 防重放攻击** | **Refresh Token 轮换（Rotation），每次刷新旧 Refresh Token 加入黑名单** | **Refresh Token 仅能使用一次，防重放** |
| **NFR-007** | **可维护性 - 认证集中化** | **Token 签发统一在 auth-service，请求鉴权在 gateway AuthFilter，业务服务零侵入** | **新增业务服务无需实现认证逻辑** |
| 约束条件 | 安全性 - SQL 注入防护 | MyBatis-Plus 预编译机制，禁止拼接 SQL | 无 SQL 注入风险 |
| 约束条件 | 安全性 - 敏感配置 | JWT 密钥、数据库密码等通过环境变量 + 配置文件管理，禁止硬编码 | 代码仓库无明文敏感信息 |
| 约束条件 | 测试 - 无外部中间件独立运行 | 测试环境 bootstrap.yml 禁用 Nacos 服务发现和配置中心；排除 DataSourceAutoConfiguration | 测试可在无 Nacos/MariaDB/Redis 环境下 100% 通过 |

---

## 8. 部署与运维视图

### 8.1 部署架构

```
[用户终端]
    │
    ├─ Flutter Web (Chrome)         ←─── `flutter build web` → build/web/ 静态资源
    │                                    (部署至 Nginx / 静态服务器)
    │
    └─ Flutter Windows (VS2022)     ←─── `flutter build windows` → build/windows/runner/Release/
                                         (分发为 Windows 可执行文件)

[开发者本地环境 / CI/CD]
    │
    ├─ Docker Compose 编排（后端微服务）
    │
    ▼
┌────────────────────────────────────────────────────────────────────────────┐
│                           Docker 宿主机                                     │
│                                                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  Nacos 2.3.x │  │  MariaDB    │  │  MariaDB    │  │  Redis 7.2.x│       │
│  │  端口: 8848  │  │  10.6 (auth)│  │  10.6 (admin)│  │  端口: 6379 │       │
│  └─────────────┘  │  端口: 3306  │  │  (v0.1.7)    │  └─────────────┘       │
│                   └─────────────┘  └─────────────┘                        │
│                                                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐  ┌──────────────┐│
│  │   Gateway   │  │ Auth Service│  │  Biz Service      │  │ Admin Service││
│  │   :9000     │  │   :9100     │  │   :9200           │  │   :9500     ││
│  └─────────────┘  └─────────────┘  └──────────────────┘  │  (v0.1.7)   ││
│                                                           └──────────────┘│
│  ┌──────────────────────────────────────────────────────────────┐         │
│  │                      System Service                           │         │
│  │                          :9400                                │         │
│  └──────────────────────────────────────────────────────────────┘         │
└────────────────────────────────────────────────────────────────────────────┘


Flutter 前端运行时与后端通信方式：
- Web 平台：Flutter Web 应用 → HTTP API → localhost:9000（网关）
  - 浏览器直接访问网关地址，需网关配置 CORS 允许 localhost 来源
- Windows 平台：Flutter Windows 桌面应用 → HTTP API → localhost:9000（网关）
  - 桌面应用无 CORS 限制，HTTP 直连网关

```

### 8.2 环境划分

| 环境 | 用途 | 部署方式 | 数据策略 |
| ----- | ---- | ------- | -------- |
| 开发环境（dev） | 本地开发调试 | 本地 IDE 直接启动 / Docker Compose | 各开发者独立，数据隔离 |
| 测试环境（test） | 集成测试 / 功能验证 | Docker Compose / CI 服务器 | 测试数据，定期重置 |
| 生产环境（prod） | 线上正式运行 | Docker / Kubernetes（后续） | 生产数据，主从备份 |

### 8.3 可观测性

| 类型 | 方案 | 采集内容 | 当前阶段 |
| ---- | ----------------------- | ------------- | -------- |
| 日志 | Logback（slf4j）| 业务日志/错误日志/访问日志 | ✔ 本期启用 |
| 指标 | Prometheus + Grafana | JVM 指标/QPS/延迟/错误率 | ⏳ 后续版本 |
| 链路追踪 | SkyWalking | 请求全链路追踪 | ⏳ 后续版本 |
| 告警 | 钉钉/企业微信 | SLA 违反/错误阈值 | ⏳ 后续版本 |

### 8.4 灾难恢复

| 场景 | RPO | RTO | 恢复策略 | 当前阶段 |
| ----- | ---- | ---- | --------- | -------- |
| 单服务进程崩溃 | - | ≤ 30 秒 | Docker 自动重启策略（restart: always） | ✔ 本期规划 |
| Redis 故障 | - | ≤ 30 秒 | Docker 自动重启 + 持久化 RDB/AOF 恢复 | ✔ 本期规划 |
| 数据库故障 | ≤ 1 小时 | ≤ 30 分钟 | MariaDB 主从同步 + 定期全量备份 | ⏳ 规划中 |
| 完整站点故障 | ≤ 24 小时 | ≤ 4 小时 | 备份恢复 + 基础设施即代码重建 | ⏳ 规划中 |

---

## 9. 安全架构

### 9.1 安全分层

| 层次 | 防护措施 | 实现方式 | 当前阶段 |
| --- | ------ | -------------------- | -------- |
| 传输层 | 加密传输 | HTTPS（后续配置证书）/ 内网 HTTP | ⏳ 后续配置 |
| 认证层 | 身份验证 | JWT RS256 双 Token（Access Token 2h + Refresh Token 7d）+ Redis 登录态会话 | ✔ v0.1.5 完整实现 |
| 授权层 | 权限控制 | RBAC 多租户权限模型（用户-角色-权限三层关联）+ 网关 Header 透传 + 后续集成 @PreAuthorize | ✔ v0.1.5 实现 RBAC 数据模型 |
| 数据层 | 数据保护 | BCrypt 密码加密、敏感配置环境变量注入、JWT 私钥安全存储 | ✔ 本期启用 |
| 审计层 | 操作审计 | 登录日志审计（时间/IP/设备/状态）+ 关键操作日志记录 | ✔ v0.1.5 实现登录日志 |

### 9.2 认证授权架构（v0.1.5）

```
┌──────────┐        ┌──────────────────┐        ┌───────────────────┐
│  客户端   │ ──────▶│  Gateway          │ ──────▶│  auth-service      │
│ (6端类型) │        │  AuthFilter       │        │  (RS256 私钥)      │
└──────────┘        │  (RS256 公钥验签)  │        └───────────────────┘
      ▲             │  Redis 黑名单/登录态│                │
      │             │  账号/租户状态校验  │                │
      │             │  用户信息 Header   │                │
      │             └──────────────────┘                │
      │                         │                       │
      │                         ▼                       ▼
      │              ┌──────────────────┐      ┌───────────────────┐
      │              │  业务服务(无感知)   │      │  Redis 7.2.x      │
      │              │  从Header获取用户  │      │  Session/黑名单    │
      │              └──────────────────┘      └───────────────────┘
      │                                                    │
      └────────────────── JSON 响应 ────────────────────────┘

认证流程（v0.1.5 完整实现）：
① POST /api/v1/auth/login
   → 白名单放行 → auth-service 校验凭证
   → RS256 私钥签发 Access Token(2h) + Refresh Token(7d)
   → Redis 写入登录态会话 + 账号状态缓存
   → MariaDB 写入登录日志审计
   
② 携带 Token 访问业务 API
   → Gateway AuthFilter 拦截
   → RS256 公钥验签（无状态，快速校验）
   → Redis 查询黑名单 + 登录态 + 账号状态 + 租户状态（有状态，增强校验）
   → 校验通过 → 放行并透传用户 Header

③ Access Token 过期 → 调用 POST /api/v1/auth/refresh
   → 公钥验签 Refresh Token
   → 校验黑名单（防重放）
   → 签发新双 Token（轮换）
   → 旧 Refresh Token 加入黑名单
   → 更新 Redis 登录态
```

### 9.3 敏感数据处理

| 数据类型 | 处理方式 | 存储位置 | 当前阶段 |
| -------- | ------- | ---------- | -------- |
| JWT RSA 私钥 | 环境变量/配置文件 Base64/PEM 文件 | 认证服务配置 | ✔ v0.1.5 实现 |
| JWT RSA 公钥 | 环境变量/配置文件/PEM 文件 | 网关 + 认证服务配置 | ✔ v0.1.5 实现 |
| 用户密码 | BCrypt 哈希加密（强度系数 ≥ 10）| MariaDB `t_auth_user.password` | ✔ v0.1.5 实现 |
| Access Token | RS256 签名，JWT 标准格式 | 客户端持有 + Redis 会话（摘要） | ✔ v0.1.5 实现 |
| Refresh Token | RS256 签名 + tokenVersion 轮换 | 客户端持有 + Redis 黑名单（摘要） | ✔ v0.1.5 实现 |
| 数据库密码 | 环境变量注入 | 环境变量 / Nacos 配置中心 | ✔ 本期规范要求 |
| 个人身份信息 | 脱敏/加密（后续实现） | 加密数据库 | ⏳ 后续版本 |

### 9.4 Token 生命周期管理

```
  用户登录                            Access Token 过期
     │                                      │
     ▼                                      ▼
┌──────────────────────────────────────────────────────────────────────┐
│                         Access Token (2h)                            │
│   RS256 签名 | sub=用户ID | tenantId | clientType | roles | perms   │
└──────────────────────────────────────────────────────────────────────┘
     │                                      │
     │  Refresh Token (7d)                  │  刷新接口
     │  RS256 签名 | sub=用户ID | tokenVersion  │  轮换新旧 Token
     │                                      ▼
     │                              ┌──────────────────────┐
     │                              │  旧 Token 加入黑名单    │
     │                              │  新双 Token 签发       │
     │                              └──────────────────────┘
     │
     ▼
┌──────────────────────────────────────────────────────────────────────┐
│                       Refresh Token 过期（7天后）                      │
│                       → 需重新登录                                    │
└──────────────────────────────────────────────────────────────────────┘

            主动登出 / 强制踢人 / 账号封禁
                    │
                    ▼
    ┌──────────────────────────────┐
    │  Token 加入 Redis 黑名单       │
    │  (TTL = Token 剩余有效期)      │
    │  登录态 Redis Key 删除         │
    │  下次请求 → 网关返回 401/403   │
    └──────────────────────────────┘
```

---

## 10. 目录结构

```
CloudStrollOffice/
├── pom.xml                                    # 父 POM（依赖版本统一管理，定义 5 个子模块）
├── opencode.json                              # OpenCode AI 开发工具配置
├── .gitignore                                 # Git 忽略规则
├── .editorconfig                              # 跨编辑器代码风格配置
├── checkstyle.xml                             # Checkstyle 规则文件
│
├── .opencode/                                 # AI 开发工具配置目录
│   ├── agents/                                # Agent 配置
│   └── skills/                                # 技能实现
│
├── docs/                                      # 项目文档目录
│   ├── project.md                             # 项目信息文档
│   ├── architecture.md                        # 架构文档（本文件）
│   ├── origin-requires/                       # 原始需求文档
│   ├── requires/                              # 需求文档
│   ├── prds/                                  # PRD 文档
│   ├── sds/                                   # 技术规格说明书
│   ├── tasks/                                 # 任务清单
│   └── prompts/                               # AI 交互历史记录
│
├── cloudoffice-common/                        # 公共模块（通用组件、工具类）
│   ├── pom.xml
│   └── src/main/java/org/cloudstrolling/cloudoffice/common/
│       ├── model/
│       │   ├── ApiResult.java                 # 统一响应体
│       │   ├── BaseEntity.java                # 基础实体（id/createTime/updateTime/deleted）
│       │   ├── ErrorCode.java                 # 错误码接口（契约）
│       │   └── PageResult.java                # 分页结果封装
│       ├── exception/
│       │   ├── BaseException.java             # 异常抽象基类
│       │   ├── BusinessException.java         # 业务异常
│       │   ├── AuthException.java             # 认证异常（401）
│       │   ├── GlobalExceptionHandler.java    # 全局异常处理器
│       │   └── ErrorCode.java                 # 错误码枚举（含通用+认证授权 33+ 错误码，v0.1.6 扩展 AUTH-0020~AUTH-0033）
│       ├── enums/
│       │   ├── ClientTypeEnum.java            # [新] 客户端类型枚举（6种，含设备分类）
│       │   ├── RegisterModeEnum.java          # [v0.1.6] 注册模式枚举（5种注册模式）
│       │   ├── LoginModeEnum.java             # [v0.1.6] 登录模式枚举（4种登录模式）
│       │   └── OAuthProviderEnum.java         # [v0.1.6] OAuth 提供商枚举（微信/钉钉/企业微信/支付宝）
│       ├── dto/
│       │   ├── TokenPairDTO.java              # [新] 双 Token 数据传输对象
│       │   └── LoginUserDTO.java              # [新] 登录用户信息传输对象
│       ├── config/
│       │   ├── MyBatisPlusConfig.java         # MyBatis-Plus 配置
│       │   └── SpringDocConfig.java           # SpringDoc OpenAPI 3 配置
│       ├── constant/
│       │   └── RedisKeyConstants.java         # [新] Redis Key 常量管理
│       └── util/
│           └── JsonUtils.java                 # JSON 工具类
│
├── cloudoffice-gateway/                       # API 网关（端口 9000）
│   ├── pom.xml                                # [更新] 新增 Redis 依赖
│   └── src/
│       ├── main/java/org/cloudstrolling/cloudoffice/gateway/
│       │   ├── GatewayApplication.java        # 网关启动类
│       │   ├── filter/
│       │   │   └── AuthFilter.java            # [新] 全局认证过滤器（GlobalFilter + Ordered）
│       │   └── config/
│       │       ├── RedisConfig.java           # [新] RedisTemplate Bean 配置（响应式）
│       │       └── RsaKeyConfig.java          # [新] RSA 公钥加载配置
│       └── main/resources/
│           ├── bootstrap.yml                  # Nacos 注册/配置中心配置
│           └── application.yml                # [更新] 新增 Redis 配置 + RSA 公钥 + 白名单配置
│
├── cloudoffice-auth-service/                  # 认证服务（端口 9100）
│   ├── pom.xml                                # [更新] 新增 Redis/MyBatis-Plus/MariaDB 依赖
│   └── src/
│       ├── main/java/org/cloudstrolling/cloudoffice/auth/
│       │   ├── AuthApplication.java           # 认证服务启动类
│       │   ├── config/
│       │   │   ├── SecurityConfig.java        # Spring Security 安全配置（BCrypt/无状态/CSRF）
│       │   │   ├── OAuth2Config.java          # OAuth2 授权服务器骨架配置（预留）
│       │   │   ├── RsaKeyConfig.java          # [新] RSA 密钥对加载与校验配置类
│       │   │   └── MyBatisPlusConfig.java     # [新] MyBatis-Plus 配置（自动填充/分页）
│       │   ├── controller/
│       │   │   ├── HealthController.java      # 健康检查控制器
│       │   │   ├── AuthController.java        # [新] 登录/注册/刷新/登出/踢人/密码管理/手机号变更/完善账号/验证码发送接口（v0.1.6 扩展）
│       │   │   ├── UserController.java        # [新] 用户管理接口（CRUD/状态/角色分配）
│       │   │   ├── RoleController.java        # [新] 角色管理接口（CRUD/权限分配）
│       │   │   └── PermissionController.java  # [新] 权限管理接口（CRUD/树形查询）
│       │   ├── service/
│       │   │   ├── AuthenticationService.java # [v0.1.6] 统一认证编排服务（策略校验→统一后处理）
│       │   │   ├── LoginService.java          # [新] 登录/登出业务逻辑接口
│       │   │   ├── TokenService.java          # [新] Token 刷新/校验业务逻辑接口
│       │   │   ├── UserService.java           # [新] 用户管理业务逻辑接口（v0.1.6 扩展完善账号）
│       │   │   ├── PasswordService.java       # [v0.1.6] 密码管理服务（修改/找回）
│       │   │   ├── VerificationCodeService.java # [v0.1.6] 验证码发送服务接口
│       │   │   ├── VerificationCodeManager.java # [v0.1.6] 验证码生成/校验/过期管理
│       │   │   ├── RoleService.java           # [新] 角色管理业务逻辑接口
│       │   │   ├── PermissionService.java     # [新] 权限管理业务逻辑接口
│       │   │   ├── LoginSessionService.java   # [新] Redis 登录态管理服务接口
│       │   │   ├── LoginLogService.java       # [新] 登录日志审计服务接口
│       │   │   ├── strategy/                  # [v0.1.6] 策略模式包
│       │   │   │   ├── LoginStrategy.java           # 登录策略接口
│       │   │   │   ├── LoginStrategyFactory.java    # 登录策略工厂
│       │   │   │   ├── UsernamePasswordStrategy.java # 用户名+密码登录策略
│       │   │   │   ├── PhoneCodeLoginStrategy.java  # 手机+验证码登录策略
│       │   │   │   ├── PhonePasswordLoginStrategy.java # 手机+密码登录策略
│       │   │   │   ├── OAuthLoginStrategy.java      # OAuth 登录策略
│       │   │   │   ├── RegisterStrategy.java        # 注册策略接口
│       │   │   │   ├── RegisterStrategyFactory.java # 注册策略工厂
│       │   │   │   ├── UsernamePwdStrategy.java     # 用户名密码注册策略
│       │   │   │   ├── PhoneCodeStrategy.java       # 手机验证码注册策略
│       │   │   │   ├── OAuthRegisterStrategy.java   # OAuth 注册策略
│       │   │   │   ├── PhoneSetUsernameStrategy.java # 手机注册后设用户名策略
│       │   │   │   └── OAuthSetInfoStrategy.java    # OAuth 注册后完善信息策略
│       │   │   └── impl/                      # 实现类目录
│       │   │       ├── LoginServiceImpl.java
│       │   │       ├── TokenServiceImpl.java
│       │   │       ├── UserServiceImpl.java    # [v0.1.6] 扩展完善账号/手机号变更
│       │   │       ├── PasswordServiceImpl.java # [v0.1.6] 密码管理实现
│       │   │       ├── SimulatedVerificationCodeServiceImpl.java # [v0.1.6] 验证码模拟发送实现
│       │   │       ├── RoleServiceImpl.java
│       │   │       ├── PermissionServiceImpl.java
│       │   │       ├── LoginSessionServiceImpl.java
│       │   │       └── LoginLogServiceImpl.java
│       │   ├── mapper/
│       │   │   ├── UserMapper.java            # [新] 用户数据访问（v0.1.6 扩展查询方法）
│       │   │   ├── TenantMapper.java          # [新] 租户数据访问
│       │   │   ├── RoleMapper.java            # [新] 角色数据访问
│       │   │   ├── PermissionMapper.java      # [新] 权限数据访问
│       │   │   ├── UserRoleMapper.java        # [新] 用户-角色关联数据访问
│       │   │   ├── RolePermissionMapper.java  # [新] 角色-权限关联数据访问
│       │   │   ├── LoginLogMapper.java        # [新] 登录日志数据访问
│       │   │   ├── OAuthAccountMapper.java    # [v0.1.6] OAuth 账号关联 Mapper
│       │   │   └── VerificationCodeMapper.java # [v0.1.6] 验证码记录 Mapper
│       │   ├── entity/
│       │   │   ├── UserEntity.java            # [新] 用户实体（v0.1.6 扩展 register_mode/account_settled/phone_verified/email_verified/last_password_change_time）
│       │   │   ├── TenantEntity.java          # [新] 租户实体
│       │   │   ├── RoleEntity.java            # [新] 角色实体
│       │   │   ├── PermissionEntity.java      # [新] 权限实体
│       │   │   ├── UserRoleEntity.java        # [新] 用户-角色关联实体
│       │   │   ├── RolePermissionEntity.java  # [新] 角色-权限关联实体
│       │   │   ├── LoginLogEntity.java        # [新] 登录日志实体
│       │   │   ├── OAuthAccountEntity.java    # [v0.1.6] OAuth 账号关联实体（t_auth_oauth_account）
│       │   │   └── VerificationCodeEntity.java # [v0.1.6] 验证码记录实体（t_auth_verification_code）
│       │   ├── dto/
│       │   │   ├── LoginRequest.java          # [v0.1.6] 扩展支持多种登录模式
│       │   │   ├── RegisterRequest.java       # [v0.1.6] 扩展支持多种注册模式
│       │   │   ├── PasswordChangeRequest.java # [v0.1.6] 修改密码 DTO
│       │   │   ├── PasswordForgotRequest.java # [v0.1.6] 密码找回 DTO
│       │   │   ├── SendVerificationCodeRequest.java # [v0.1.6] 发送验证码 DTO
│       │   │   ├── PhoneChangeRequest.java    # [v0.1.6] 修改手机号 DTO
│       │   │   ├── AccountSettlementRequest.java # [v0.1.6] 完善账号信息 DTO
│       │   │   ├── AuthResult.java            # [v0.1.6] 策略认证结果 DTO
│       │   │   ├── RegisterResult.java        # [v0.1.6] 注册结果 DTO
│       │   │   ├── ... (其他 v0.1.5 DTO)
│       │   │   └── dto/result/               # 策略结果 DTO 目录
│       │   ├── vo/                            # [新] 视图对象
│       │   ├── enums/                         # [新] 业务枚举
│       │   ├── exception/                     # [新] 认证服务异常
│       │   └── util/
│       │       └── JwtUtils.java              # [重构] JWT 工具类（HS256→RS256，双 Token）
│       └── main/resources/
│           ├── bootstrap.yml                  # Nacos 配置
│           └── application.yml                # [更新] 新增数据源/Redis/RS256密钥/验证码配置
│
├── cloudoffice-admin-service/                 # 管理中台服务（端口 9500）v0.1.7
│   ├── pom.xml                                # [新] 父模块 POM（含 OpenFeign/AOP/MyBatis-Plus 依赖）
│   └── src/
│       ├── main/java/org/cloudstrolling/cloudoffice/admin/
│       │   ├── AdminApplication.java          # [新] 管理中台服务启动入口
│       │   ├── config/
│       │   │   ├── AdminWebConfig.java        # [新] Web 配置（过滤器注册/白名单/CORS）
│       │   │   └── FeignConfig.java           # [新] Feign 配置（请求拦截器/超时/重试）
│       │   ├── controller/
│       │   │   ├── AdminUserController.java   # [新] 管理员用户管理控制器（7+ 个端点）
│       │   │   ├── AdminAuditLogController.java  # [新] 审计日志查询控制器
│       │   │   └── HealthController.java      # [新] 健康检查控制器
│       │   ├── service/
│       │   │   ├── AdminUserService.java      # [新] 用户管理服务接口
│       │   │   └── AdminAuditLogService.java  # [新] 审计日志服务接口
│       │   │   └── impl/
│       │   │       ├── AdminUserServiceImpl.java    # [新] 用户管理服务实现（Feign 调用编排）
│       │   │       └── AdminAuditLogServiceImpl.java # [新] 审计日志服务实现
│       │   ├── feign/
│       │   │   └── AuthServiceClient.java     # [新] Feign 客户端接口（调用 auth-service 管理 API）
│       │   ├── filter/
│       │   │   └── AdminAuthFilter.java       # [新] 管理员认证过滤器（JWT 解析 + 角色校验）
│       │   ├── interceptor/
│       │   │   └── FeignAuthInterceptor.java  # [新] Feign 请求拦截器（传递管理员 Token）
│       │   ├── annotation/
│       │   │   └── AdminAuditLog.java         # [新] 审计日志注解
│       │   ├── aspect/
│       │   │   └── AdminAuditLogAspect.java   # [新] 审计日志 AOP 切面
│       │   ├── entity/
│       │   │   └── AdminAuditLogEntity.java   # [新] 审计日志实体（t_admin_audit_log）
│       │   ├── dto/
│       │   │   ├── UserQueryRequest.java      # [新] 用户查询参数 DTO
│       │   │   ├── CreateUserRequest.java     # [新] 创建用户请求 DTO
│       │   │   ├── UpdateUserRequest.java     # [新] 编辑用户请求 DTO
│       │   │   ├── UpdateUserStatusRequest.java   # [新] 状态更新请求 DTO
│       │   │   ├── ResetPasswordRequest.java  # [新] 重置密码请求 DTO
│       │   │   └── AssignRolesRequest.java    # [新] 角色分配请求 DTO
│       │   ├── vo/
│       │   │   ├── UserVO.java               # [新] 用户列表 VO（含脱敏处理）
│       │   │   └── UserDetailVO.java         # [新] 用户详情 VO
│       │   ├── enums/
│       │   │   └── AdminActionTypeEnum.java   # [新] 管理操作类型枚举
│       │   ├── exception/
│       │   │   ├── AdminException.java        # [新] 管理中台业务异常
│       │   │   └── AdminErrorCode.java        # [新] 管理中台错误码枚举（ADMIN-0001~ADMIN-0007）
│       │   ├── mapper/
│       │   │   └── AdminAuditLogMapper.java   # [新] 审计日志 Mapper
│       │   └── util/
│       │       └── AdminContext.java          # [新] 管理员请求上下文（ThreadLocal）
│       └── main/resources/
│           ├── bootstrap.yml                  # [新] Nacos 注册/配置中心配置
│           └── application.yml                # [新] 应用配置（端口 9500、数据源、Feign、日志等）
│       └── test/
│           └── java/org/cloudstrolling/cloudoffice/admin/
│               └── AdminApplicationTest.java  # [新] 应用启动测试
│
├── cloudoffice-biz-service/                   # 企业服务（端口 9200）
│   └── src/main/java/org/cloudstrolling/cloudoffice/biz/...（同 v0.1.0，未变更）
│
├── cloudoffice-system-service/                # 系统服务（端口 9400）v0.1.4
│   └── src/...（同 v0.1.4，未变更）
│
├── cloudoffice-flutter-app/                   # Flutter 前端子项目（v0.2.0）
│   ├── pubspec.yaml                           # 依赖配置（dio/provider/flutter_secure_storage/go_router）
│   ├── analysis_options.yaml                  # Dart 静态分析规则
│   ├── lib/
│   │   ├── main.dart                          # 应用入口
│   │   ├── app.dart                           # MaterialApp 配置（主题、路由）
│   │   ├── config/
│   │   │   ├── api_config.dart                # API 基础配置（网关地址、超时时间）
│   │   │   └── theme_config.dart              # 主题配置（颜色、字体、组件样式）
│   │   ├── core/
│   │   │   ├── http/
│   │   │   │   ├── api_client.dart            # Dio 实例封装（单例模式）
│   │   │   │   ├── api_interceptor.dart       # 请求/响应拦截器（Token 注入/401 自动刷新）
│   │   │   │   └── api_result.dart            # 统一响应模型（ApiResult<T>）
│   │   │   ├── router/
│   │   │   │   └── app_router.dart            # GoRouter 路由表（含登录态路由守卫）
│   │   │   ├── storage/
│   │   │   │   └── secure_storage.dart        # 安全存储封装（flutter_secure_storage）
│   │   │   └── utils/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   │   ├── models/                    # 数据模型（LoginRequest/RegisterRequest/TokenPairDTO 等）
│   │   │   │   ├── providers/                 # 状态管理（AuthProvider/ForgotPasswordProvider）
│   │   │   │   ├── repositories/              # 数据仓库（AuthRepository）
│   │   │   │   └── screens/                   # 页面（LoginScreen/RegisterScreen/ForgotPasswordScreen）
│   │   │   └── home/
│   │   │       ├── providers/                 # 首页状态管理（HomeProvider）
│   │   │       └── screens/                   # 首页页面（HomeScreen）
│   │   └── shared/
│   │       ├── widgets/                       # 公共 UI 组件（CustomTextField/PasswordField/VerificationCodeField/LoadingButton/PasswordStrengthIndicator）
│   │       └── constants/                     # 常量定义
│   ├── test/                                  # 测试目录
│   │   ├── core/http/
│   │   ├── features/auth/
│   │   │   ├── repositories/
│   │   │   └── providers/
│   │   └── shared/widgets/
│   ├── web/                                   # Web 平台配置（index.html、manifest.json）
│   └── windows/                               # Windows 平台配置（CMakeLists.txt、runner/）
│
├── scripts/                                   # 脚本与模板
│   ├── docker/                                # Docker 部署模板
│   │   ├── gateway/Dockerfile
│   │   ├── auth-service/Dockerfile
│   │   ├── biz-service/Dockerfile
│   │   ├── system-service/Dockerfile
│   │   ├── admin-service/Dockerfile           # [v0.1.7] 管理中台服务 Dockerfile
│   │   └── docker-compose.yml                 # Compose 编排（含 Nacos/MariaDB/Redis）
│   └── sql/
│       ├── init.sql                           # 数据库初始化脚本模板（v0.1.0）
│       ├── auth-init-v0.1.5.sql               # [新] 认证服务 7 张表建表 DDL
│       ├── auth-init-v0.1.6.sql               # [v0.1.6] 认证服务新增表 DDL + t_auth_user 扩展字段变更
│       ├── schema_admin.sql                   # [v0.1.7] admin-service DDL（cloudstroll_office_admin 数据库建库 + t_admin_audit_log 建表）
│       └── init_admin_data.sql                # [v0.1.7] 管理员角色预置和初始超级管理员账号初始化脚本
│
└── .idea/                                     # IDEA 统一配置
    ├── codeStyles/
    │   ├── Project.xml                        # 代码风格（Alibaba 规范）
    │   └── codeStyleConfig.xml                # 代码风格引用配置
    └── runConfigurations/                     # 运行配置
        ├── GatewayApplication.xml
        ├── AuthApplication.xml
        ├── BizApplication.xml
        └── SystemApplication.xml
```

---

## 11. 架构质量属性

| 质量属性 | 实现策略 | 验证方式 |
| -------- | ----------------- | ----------- |
| **可维护性** | 微服务拆分 + 标准包结构 + 统一编码规范 + Checkstyle 自动化检查；Redis Key 统一常量管理；错误码统一枚举管理 | 代码审查 / Checkstyle 检查 / SonarQube 扫描 |
| **可测试性** | 构造器注入 + 接口隔离 + ApiResult 统一响应体；RSA 密钥测试配置；H2 内存数据库 / Mockito 模拟 | 单元测试覆盖率 ≥ 80% / JUnit 5 + Mockito |
| **可扩展性** | 微服务架构 + Nacos 服务发现 + 无状态设计；`ClientTypeEnum` 新增枚举值即可扩展客户端类型；白名单路径可配置化 | 新增服务模块只需注册到 Nacos 即可加入集群 |
| **可靠性** | 全局异常兜底 + ApiResult 统一错误返回 + 不泄露堆栈到客户端；Redis 连接失败降级处理 | 异常场景测试 / 错误码覆盖验证 |
| **可移植性** | 容器化部署（Docker）+ Maven 多模块 + 配置与环境解耦（Nacos/环境变量）；密钥加载支持环境变量/Base64/PEM 三种方式 | 跨环境部署验证（dev/test/prod）|
| **性能** | 各服务独立启动 + 懒加载配置；网关 RS256 本地验签（无状态）+ Redis 响应式查询 | Token 校验 ≤ 10ms / 登录接口 ≤ 500ms / 启动时间 ≤ 30 秒 |
| **安全性** | BCrypt 密码加密 + JWT RS256 非对称签名 + 双 Token 轮换 + Redis 黑名单实时吊销 + 多租户隔离 + @PreAuthorize 预留 | 安全审查 / 渗透测试（后续）|

---

## 12. 附录

### A. 接口规范模板

```java
// 统一响应体格式
public class ApiResult<T> {
    private Integer code;       // 状态码
    private String message;     // 提示信息（简体中文）
    private T data;             // 数据
    private Long timestamp;     // 时间戳
}

// 分页响应格式
public class PageResult<T> {
    private List<T> records;    // 数据列表
    private Long total;         // 总记录数
    private Integer page;       // 当前页码
    private Integer pageSize;   // 每页大小
}

// 双 Token 响应格式
public class TokenPairDTO {
    private String accessToken;
    private String refreshToken;
    private Long accessTokenExpiresIn;
    private Long refreshTokenExpiresIn;
    private String tokenType;   // "Bearer"
}
```

### B. 文档命名规范

| 文档类型 | 目录 | 文件名格式 | 示例 |
| ----- | ---- | -------- | ------ |
| 需求文档 | `docs/requires/` | `{ProjectName}-requirement-v{version}.md` | `CloudStrollOffice-requirement-v0.1.5.md` |
| PRD 文档 | `docs/prds/` | `{ProjectName}-prd-v{version}.md` | `CloudStrollOffice-prd-v0.1.5.md` |
| 架构文档 | `docs/` | `architecture.md` | `architecture.md` |
| 技术规格 | `docs/sds/` | `{ProjectName}-sds-v{version}.md` | `CloudStrollOffice-sds-v0.1.5.md` |
| 数据库设计 | `docs/` | `dbd.md` | `dbd.md` |
| 项目信息 | `docs/` | `project.md` | `project.md` |

### C. 版本号规则

- **格式：** `v{主版本}.{次版本}.{修订号}`
- **递增规则：**
  - **主版本：** 架构重大变更、不兼容的 API 修改
  - **次版本：** 新功能添加、API 扩展（向下兼容）
  - **修订号：** Bug 修复、性能优化（向下兼容）

### D. 参考文档

- `docs/requires/CloudStrollOffice-requirement-v0.2.0.md` — Flutter 前端需求文档 v0.2.0
- `docs/prds/CloudStrollOffice-prd-v0.2.0.md` — Flutter 前端 PRD 文档 v0.2.0
- `docs/requires/CloudStrollOffice-requirement-v0.1.7.md` — 管理中台需求文档 v0.1.7
- `docs/prds/CloudStrollOffice-prd-v0.1.7.md` — 管理中台 PRD 文档 v0.1.7
- `docs/requires/CloudStrollOffice-requirement-v0.1.6.md` — 用户认证增强需求文档 v0.1.6
- `docs/prds/CloudStrollOffice-prd-v0.1.6.md` — 用户认证增强 PRD 文档 v0.1.6
- `docs/requires/CloudStrollOffice-requirement-v0.1.5.md` — 登录认证与权限管理需求文档 v0.1.5
- `docs/prds/CloudStrollOffice-prd-v0.1.5.md` — 登录认证与权限管理 PRD 文档 v0.1.5
- `docs/requires/CloudStrollOffice-requirement-v0.1.0.md` — 需求文档 v0.1.0
- `docs/prds/CloudStrollOffice-prd-v0.1.0.md` — PRD 文档 v0.1.0
- `docs/origin-requires/origin-requires0.1.0.md` — 原始需求文档
- `docs/project.md` — 项目信息与编码规范
- `docs/architecture.md` — 架构文档（本书）
- `opencode.json` — OpenCode AI 配置

---

## 13. 变更记录

| 变更日期 | 版本号 | 变更说明 |
|---------|-------|---------|
| 2026-06-24 | v0.2.0 | 新增 Flutter 前端架构：新增 2.7 节 cloudoffice-flutter-app 模块设计（Screen-Provider-Repository 三层架构、核心层/功能模块/共享组件）；更新 1.1 节系统定位（追加 Flutter 前端描述）；更新 1.2 节架构风格（新增前端架构风格和跨平台策略）；更新 1.3 节架构层次图（客户端层标注 Flutter Web + Flutter Windows）；更新 1.4 节核心架构特点（新增 4 条 Flutter 前端特点）；更新 3.1 节技术栈全景（新增 Flutter/Dart/Dio/Provider/GoRouter 等 9 项前端技术栈）；新增 ADR-026 Flutter 前端技术栈选型；更新 8.1 节部署架构（新增 Flutter 前端终端层）；更新 10 节目录结构（新增 cloudoffice-flutter-app/ 子项目完整目录） |
| 2026-06-24 | v0.1.7 | 基于 v0.1.7 PRD 更新架构文档：新增 2.6 节 cloudoffice-admin-service 模块设计（管理员认证与权限校验、用户管理 CRUD、审计日志、Feign 通信）；更新系统架构层次图（新增 admin-service 和 admin 数据库层）；更新模块关系图（新增 admin-service + OpenFeign 调用关系）；新增 ADR-021~ADR-025 架构决策记录（admin-service 独立策略、独立数据库、权限校验位置、Token 方案、AOP 审计日志）；新增 4.1.4~4.1.6 数据流图（管理员请求认证、OpenFeign 服务间调用、审计日志记录）；新增 4.2 节 admin-service 相关模块间数据流转表；新增 5.1 节 cloudstroll_office_admin 数据库设计（t_admin_audit_log 表）；新增 5.4.2~5.4.3 节 v0.1.7 数据库表和角色预置数据；新增 6.1 节 admin-service API 端点（9 个端点）；更新 6.4 节 API 路由表（新增 `/api/v1/admin/**` 路由）；更新 2.2 节网关白名单和白名单路径扩展；更新部署架构图（新增 admin-service 和 admin 数据库）；更新 10 节目录结构（新增 admin-service 模块和 SQL 脚本）；更新参考文档列表 |
| 2026-06-23 | v0.1.6 | 基于 v0.1.6 PRD 更新架构文档：新增策略模式认证架构（LoginStrategy/RegisterStrategy 接口、4 种登录模式 + 5 种注册模式实现类、策略工厂）；新增统一认证服务层 AuthenticationService；新增密码管理（修改密码/密码找回）；新增验证码管理服务（VerificationCodeService + VerificationCodeManager）；新增手机号变更功能；扩展公共模块（RegisterModeEnum/LoginModeEnum/OAuthProviderEnum 枚举、AUTH-0020~AUTH-0033 错误码）；新增 2 张数据库表（t_auth_oauth_account、t_auth_verification_code）；扩展 t_auth_user 表（5 个新增字段）；新增 8 个 API 端点（含登录/注册扩展）；新增 ADR-017~ADR-020 架构决策记录；更新网关白名单；新增 spring-boot-starter-mail 依赖 |
| 2026-06-19 | v0.1.4 | 基于PRD更新系统服务模块架构描述——启动入口、健康检查响应体version字段、骨架结构、测试架构；补充NFR指标（健康检查响应时间、编译时间、测试独立性） |
| 2026-06-19 | v0.1.0 | 移除cloud-service微服务模块 |
