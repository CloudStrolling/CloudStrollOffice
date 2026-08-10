# 详细设计文档（LLD）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：0.0.1
**日期**：2026-08-07
**编写人**：TL

> 说明：LLD 聚焦整体业务逻辑的详细设计（模块划分、业务流程、核心业务逻辑、业务规则等）；接口（API）的详细设计由 API 设计文档单独负责，LLD 中不重复编写接口定义、请求/响应参数等内容。

## 1. 模块概述

本版本（v0.0.1 初始化基线，反推存量代码 v0.1.6 能力）以**统一认证授权**为平台底座，由六个 Maven/工程模块构成：

| 模块 | 定位 | 核心职责 |
| --- | --- | --- |
| cloudoffice-common | 公共依赖层（jar） | 统一响应体 ApiResult/PageResult、统一异常体系（BaseException→BusinessException/AuthException，29 个错误码）、枚举常量（登录/注册/客户端/OAuth）、Redis Key 规范、跨服务 DTO（LoginUserDTO/TokenPairDTO）、SpringDoc 配置 |
| cloudoffice-gateway | API 网关（:9000） | 统一路由 `/api/v1/{module}/**`；AuthFilter 全局认证过滤器执行 9 步校验；白名单放行、用户信息 Header 透传、CORS；响应式 Redis 校验 |
| cloudoffice-auth-service | 认证授权服务（:9100） | 登录/注册编排（策略工厂 4 登录 + 5 注册）、JWT RS256 双 Token 签发与轮换、Redis 会话管理（会话/黑名单/状态缓存）、密码管理、手机号变更、验证码管理、RBAC 用户/角色/权限管理、登录日志审计、健康检查 |
| cloudoffice-biz-service | 企业服务骨架（:9200） | 健康检查；为后续企业信息/人事/工作流/薪酬业务预留扩展空间 |
| cloudoffice-system-service | 系统服务骨架（:9400） | 健康检查；为后续系统配置/审计业务预留扩展空间 |
| cloudoffice-flutter-app | 多端客户端（Flutter Web/Windows） | 登录/注册/忘记密码/首页认证页面、provider 状态管理、dio 网络层（ApiClient/ApiInterceptor 自动刷新）、Token 安全存储、go_router 路由守卫 |

**模块间协作关系**：客户端统一请求网关 :9000；网关按模块前缀路由至对应微服务；auth-service 为业务数据与认证逻辑核心，读写 MariaDB（认证库 9 张表）与 Redis（会话/黑名单/状态/验证码）；gateway 与 auth-service 共享 RSA 公钥验签；所有模块仅依赖 common，禁止互相依赖（ADR-001）。

## 2. 模块划分与职责

### 2.1 模块依赖关系

```mermaid
flowchart LR
    FE["cloudoffice-flutter-app<br/>Flutter 客户端"] -->|"HTTP :9000 /api/v1/**"| GW["cloudoffice-gateway<br/>AuthFilter 9 步认证"]
    GW -->|"lb://cloudoffice-auth-service"| AUTH["cloudoffice-auth-service<br/>认证授权服务"]
    GW -->|"lb://cloudoffice-biz-service"| BIZ["cloudoffice-biz-service<br/>企业服务骨架"]
    GW -->|"lb://cloudoffice-system-service"| SYS["cloudoffice-system-service<br/>系统服务骨架"]
    AUTH -->|"依赖"| COM["cloudoffice-common<br/>公共层"]
    GW -->|"依赖"| COM
    BIZ -->|"依赖"| COM
    SYS -->|"依赖"| COM
    AUTH -->|"JDBC"| MDB[("MariaDB<br/>cloudstroll_office_auth 9 表")]
    AUTH -->|"会话/黑名单/状态/验证码"| REDIS[("Redis 7.2")]
    GW -->|"响应式校验"| REDIS
```

### 2.2 auth-service 内部组件职责

| 组件 | 职责 | 关键类 |
| --- | --- | --- |
| Controller 层 | REST 入口与参数校验 | AuthController、UserController、RoleController、PermissionController、HealthController |
| 编排服务 | 统一编排登录/注册主流程（策略认证→状态校验→Token→会话→日志） | AuthenticationService |
| 策略工厂 | 按 loginMode/registerMode 分发至具体策略；新增方式仅需新增策略实现（ADR-005） | LoginStrategyFactory、RegisterStrategyFactory |
| 登录策略 | 4 种登录：用户名密码/手机验证码/手机+密码/OAuth | UsernamePasswordStrategy、PhoneCodeLoginStrategy、PhonePasswordLoginStrategy、OAuthLoginStrategy |
| 注册策略 | 5 种注册：用户名密码/手机验证码/OAuth/手机设用户名/OAuth 补全信息 | UsernamePwdRegisterStrategy、PhoneCodeRegisterStrategy、OAuthRegisterStrategy、PhoneSetUsernameStrategy、OAuthSetInfoStrategy |
| 登录业务服务 | 登录、登出（幂等）、强制踢人（管理员校验/指定端/所有端） | LoginService（LoginServiceImpl） |
| Token 服务 | JWT RS256 双 Token 签发、解析、刷新轮换、黑名单吊销 | TokenService（TokenServiceImpl）、JwtUtils |
| 会话服务 | Redis 登录态创建/查询/移除/全端移除、Token 黑名单、账号/租户状态缓存 | LoginSessionService（LoginSessionServiceImpl） |
| 验证码服务 | 生成（6 位数字）、发送（模拟/真实通道）、校验（一次性/防暴力）、频率控制、过期清理 | VerificationCodeManager（VerificationCodeManagerImpl）、VerificationCodeService、SimulatedVerificationCodeService |
| 业务服务 | 密码管理、RBAC 用户/角色/权限管理、登录日志审计 | PasswordService、UserService、RoleService、PermissionService、LoginLogService |
| Mapper 层 | 9 张表数据访问（MyBatis-Plus） | User/Tenant/Role/Permission/UserRole/RolePermission/LoginLog/OAuthAccount/VerificationCodeMapper |
| 配置层 | 安全、RSA 密钥、Redis、MyBatis-Plus、密码策略、验证码策略、OAuth 骨架 | SecurityConfig、RsaKeyConfig、RedisConfig、MyBatisPlusConfig、PasswordProperties、VerificationCodeProperties、OAuth2Config |

### 2.3 gateway 内部组件职责

| 组件 | 职责 |
| --- | --- |
| AuthFilter（GlobalFilter） | 全局 9 步认证：白名单→Bearer 格式→RS256 验签→tokenType→黑名单→登录态→账号状态→租户状态→Header 透传；统一 401/403 ApiResult 错误响应 |
| AuthProperties | 白名单路径配置（Ant 匹配） |
| RsaKeyConfig | RSA 公钥加载（环境变量注入） |
| RedisConfig | ReactiveRedisTemplate（响应式非阻塞校验，ADR-002） |

## 3. 类图

```mermaid
classDiagram
    class AuthenticationService {
        +authenticate(LoginRequest) TokenPairDTO
        +register(RegisterRequest) RegisterResult
        -checkTenantStatus(TenantEntity)
        -checkUserStatus(UserEntity)
        -processMutualExclusion(Long, ClientTypeEnum)
    }
    class LoginStrategyFactory {
        +getStrategy(String) LoginStrategy
    }
    class RegisterStrategyFactory {
        +getStrategy(String) RegisterStrategy
    }
    class LoginStrategy {
        <<interface>>
        +authenticate(LoginRequest) AuthResult
    }
    class RegisterStrategy {
        <<interface>>
        +register(RegisterRequest) RegisterResult
    }
    class TokenService {
        <<interface>>
        +refresh(String, String) TokenPairDTO
    }
    class LoginSessionService {
        <<interface>>
        +createSession(Long, String, LoginUserDTO, long)
        +getSession(Long, String) LoginUserDTO
        +removeSession(Long, String)
        +removeAllSessions(Long)
        +addToBlacklist(String, long)
        +setAccountStatus(Long, Integer)
        +setTenantStatus(Long, Integer)
    }
    class LoginService {
        <<interface>>
        +login(LoginRequest) TokenPairDTO
        +logout(String, String)
        +kickout(Long, String)
    }
    class VerificationCodeManager {
        <<interface>>
        +generateCode(String, String, String) String
        +verifyCode(String, String, String) boolean
        +isSendTooFrequent(String, String) boolean
        +cleanExpiredCodes()
    }
    class JwtUtils {
        +generateAccessToken(LoginUserDTO) String
        +generateRefreshToken(LoginUserDTO) String
        +parseAccessToken(String) Claims
        +parseRefreshToken(String) Claims
        +getTokenSignature(String) String
    }
    class LoginUserDTO {
        +Long userId
        +Long tenantId
        +String userName
        +String clientType
        +List roles
        +List permissions
    }
    class TokenPairDTO {
        +String accessToken
        +String refreshToken
        +long accessTokenExpireIn
        +long refreshTokenExpireIn
        +String tokenType
    }
    class AuthFilter {
        +filter(ServerWebExchange, GatewayFilterChain) Mono
        -isWhiteListPath(String) boolean
        -checkBlacklist(String) Mono
        -checkSession(Long, String) Mono
        -checkAccountStatus(Long) Mono
        -checkTenantStatus(Long) Mono
        -forwardWithHeaders(...) Mono
    }
    class UserEntity
    class TenantEntity
    class RoleEntity
    class PermissionEntity
    class LoginLogEntity
    class VerificationCodeEntity

    AuthenticationService --> LoginStrategyFactory
    AuthenticationService --> RegisterStrategyFactory
    AuthenticationService --> TokenService
    AuthenticationService --> LoginSessionService
    AuthenticationService --> LoginLogService
    AuthenticationService --> UserEntity
    AuthenticationService --> TenantEntity
    LoginStrategyFactory --> LoginStrategy
    RegisterStrategyFactory --> RegisterStrategy
    TokenService --> JwtUtils
    TokenService --> LoginSessionService
    LoginService --> JwtUtils
    LoginService --> LoginSessionService
    LoginSessionService --> LoginUserDTO
    JwtUtils --> LoginUserDTO
    JwtUtils --> TokenPairDTO
    AuthFilter --> JwtUtils : 公钥验签
    AuthFilter --> LoginSessionService : Redis 校验
    UserEntity ..> LoginUserDTO : 构建
    LoginLogService --> LoginLogEntity
    VerificationCodeManager --> VerificationCodeEntity
```

## 4. 核心业务流程时序图

### 4.1 多模式登录流程（F-002）

```mermaid
sequenceDiagram
    autonumber
    actor U as 终端用户（客户端）
    participant GW as 网关 AuthFilter
    participant AS as AuthenticationService
    participant LF as LoginStrategyFactory
    participant TS as TokenService/JwtUtils
    participant LS as LoginSessionService
    participant DB as MariaDB
    participant RD as Redis

    U->>GW: 登录请求（loginMode/clientType/tenantCode/凭据）
    GW->>GW: 第 1 步：白名单判断，命中放行
    GW->>AS: 转发登录请求
    AS->>LF: getStrategy(loginMode) 获取登录策略
    LF->>AS: 策略实例
    AS->>DB: 策略认证：租户/账号/凭据校验（BCrypt/验证码/OAuth）
    AS->>AS: 校验租户状态（禁用/过期）
    AS->>AS: 校验用户状态（禁用/锁定/封禁/过期）
    AS->>AS: 校验账号信息完善度 accountSettled
    AS->>DB: 查询角色与权限（selectRoleCodesByUserId/selectPermissionCodesByUserId）
    AS->>TS: 签发 Access(2h) + Refresh(7d) 双 Token
    AS->>RD: 同端互斥：清理同设备分类旧会话（removeSession）
    AS->>RD: 创建登录态会话 auth:session:{userId}:{clientType}（TTL=7d）
    AS->>RD: 缓存账号/租户状态
    AS->>DB: 记录登录成功日志 + 更新 lastLoginTime/lastLoginIp
    AS->>GW: 返回 TokenPairDTO（Bearer 双 Token + 过期时间）
    GW->>U: ApiResult 统一响应
```

### 4.2 注册流程（含两步注册，F-001）

```mermaid
sequenceDiagram
    autonumber
    actor V as 访客
    participant GW as 网关
    participant AS as AuthenticationService
    participant RF as RegisterStrategyFactory
    participant DB as MariaDB
    participant VM as VerificationCodeManager

    V->>GW: 注册请求（registerMode + 参数）
    GW->>AS: 白名单放行并转发
    AS->>RF: getStrategy(registerMode) 获取注册策略
    RF->>AS: 策略实例
    AS->>DB: 策略校验：参数/唯一性（登录名/手机号租户内唯一）
    alt 手机验证码模式
        V->>VM: 发送验证码（60s 频率限制）
        VM-->>V: 验证码（模拟模式直接返回/真实模式发送）
        AS->>VM: verifyCode 校验（一次性）
    end
    AS->>DB: 创建账号（register_mode 记录来源）+ 分配默认角色
    alt 两步注册（OAuth/手机先注册，信息不完整）
        AS-->>V: 返回账号状态未完善（account_settled=0）
        V->>AS: 完善账号信息（补全登录名/密码/手机号）
        AS->>DB: 更新账号信息，account_settled=1
    end
    AS->>AS: 签发双 Token 自动登录
    AS-->>GW: 返回用户信息与双 Token
    GW-->>V: ApiResult 统一响应
```

### 4.3 网关认证流程（9 步校验，F-005）

```mermaid
sequenceDiagram
    autonumber
    actor C as 客户端
    participant AF as AuthFilter
    participant RD as Redis
    participant SVC as 下游服务

    C->>AF: 请求受保护资源（Authorization: Bearer {accessToken}）
    AF->>AF: ① 白名单判断（命中直接放行）
    AF->>AF: ② Bearer 格式校验（缺失/非 Bearer 前缀 → 401）
    AF->>AF: ③ RS256 公钥验签 + 解析 Claims（过期/无效 → 401）
    AF->>AF: ④ tokenType 校验（必须为 access → 401）
    AF->>RD: ⑤ 黑名单校验 auth:blacklist:{signature}（命中 → 401）
    AF->>RD: ⑥ 登录态校验 auth:session:{userId}:{clientType}（不存在 → 401）
    AF->>RD: ⑦ 账号状态校验 auth:account:status:{userId}（禁用/锁定/封禁 → 403）
    AF->>RD: ⑧ 租户状态校验 auth:tenant:status:{tenantId}（禁用/过期 → 403）
    AF->>AF: ⑨ 透传 X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions
    AF->>SVC: 放行请求（带用户信息 Header）
    SVC-->>C: ApiResult 统一响应
```

### 4.4 Token 刷新与轮换流程（F-003）

```mermaid
sequenceDiagram
    autonumber
    actor C as 客户端
    participant TS as TokenServiceImpl
    participant DB as MariaDB
    participant LS as LoginSessionService
    participant RD as Redis

    C->>TS: 携带 Refresh Token 请求刷新（tokenType=refresh）
    TS->>TS: RS256 验签 + tokenType 校验（过期/无效 → AUTH-0004/0005）
    TS->>RD: 黑名单校验（已吊销 → TOKEN_BLACKLISTED）
    TS->>DB: 查询用户（逻辑删除过滤）+ 状态校验
    TS->>DB: 查询租户 + 状态校验
    TS->>DB: 查询最新角色/权限
    TS->>TS: 签发新 Access(2h) + Refresh(7d)
    TS->>RD: 旧 Refresh Token 入黑名单（TTL=剩余有效期，防重放）
    TS->>RD: 更新登录态会话（先 remove 再 create）
    TS-->>C: 返回新 TokenPairDTO
```

### 4.5 会话安全控制流程（登出/踢人/密码重置，F-004/F-006）

```mermaid
sequenceDiagram
    autonumber
    actor U as 用户
    actor AD as 管理员
    participant LS as LoginServiceImpl
    participant PW as PasswordService
    participant SESS as LoginSessionService
    participant RD as Redis

    par 用户登出（幂等）
        U->>LS: logout(accessToken, clientType)
        LS->>SESS: Access Token 入黑名单（TTL=剩余有效期）
        LS->>SESS: removeSession(userId, clientType)
        LS->>DB: 更新登录日志登出时间（失败不影响主流程）
    and 管理员强制踢人
        AD->>LS: kickout(targetUserId, clientType?)
        LS->>LS: 校验操作者管理员角色（X-Roles 含 admin，否则 403）
        alt clientType 非空
            LS->>SESS: removeSession(targetUserId, clientType)
        else clientType 为空
            LS->>SESS: removeAllSessions(targetUserId)（SCAN 匹配 auth:session:{userId}:*）
        end
        LS->>DB: 记录踢人审计日志（loginResult=2）
    and 密码修改/找回成功
        PW->>SESS: removeAllSessions(userId)（全端下线，需重新登录）
    end
```

## 5. 状态图

### 5.1 账号状态流转（UserEntity.status）

```mermaid
stateDiagram-v2
    [*] --> 正常 : 创建用户/注册成功
    正常 --> 禁用 : 管理员操作（status=1）
    正常 --> 锁定 : 安全策略（status=2）
    正常 --> 封禁 : 管理员封禁（status=3）
    正常 --> 过期 : 有效期到期（status=4）
    禁用 --> 正常 : 解封/解禁
    锁定 --> 正常 : 解锁
    封禁 --> 正常 : 解封
    过期 --> 正常 : 续期
    禁用 --> [*] : 删除（逻辑删除）
    锁定 --> [*] : 删除
    封禁 --> [*] : 删除
    过期 --> [*] : 删除
    正常 --> [*] : 删除
```

### 5.2 租户状态流转（TenantEntity.status）

```mermaid
stateDiagram-v2
    [*] --> 正常 : 创建租户（status=0）
    正常 --> 禁用 : 停用（status=1）
    正常 --> 过期 : 到期（status=2）
    禁用 --> 正常 : 启用
    过期 --> 正常 : 续期
    禁用 --> [*] : 删除
    过期 --> [*] : 删除
    正常 --> [*] : 删除
```

### 5.3 验证码状态流转（VerificationCodeEntity）

```mermaid
stateDiagram-v2
    [*] --> 未使用 : 生成（used=0）
    未使用 --> 已使用 : 校验成功（used=1，一次性）
    未使用 --> 已过期 : 超过 5 分钟
    已过期 --> [*] : 后台定时清理（cleanExpiredCodes）
    已使用 --> [*] : 保留审计记录
```

### 5.4 Token 生命周期

```mermaid
stateDiagram-v2
    [*] --> 有效 : 签发（RS256 私钥签名）
    有效 --> 已过期 : 到达有效期（Access 2h / Refresh 7d）
    有效 --> 已吊销 : 登出/踢人/轮换/密码重置（入黑名单）
    已过期 --> [*] : 客户端重新认证
    已吊销 --> [*] : 客户端重新认证
```

## 6. 核心业务逻辑

### 6.1 登录认证编排（AuthenticationService.authenticate）

```
功能：统一登录认证主流程
输入：LoginRequest（loginMode、clientType、tenantCode、凭据）
输出：TokenPairDTO（双 Token + 过期时间）

流程：
1. strategy = loginStrategyFactory.getStrategy(request.loginMode)   // 策略分发，无效模式抛 LOGIN_MODE_INVALID
2. authResult = strategy.authenticate(request)                       // 策略内认证（用户名密码/手机验证码/手机+密码/OAuth）
3. user = userMapper.selectById(authResult.userId)；tenant = tenantMapper.selectById(authResult.tenantId)
4. checkTenantStatus(tenant)        // 租户 status==1 禁用、expireTime 早于当前 → 拒绝
5. checkUserStatus(user)            // 用户 status：1 禁用/2 锁定/3 封禁/4 过期 → 拒绝
6. if (user.accountSettled == 0) 抛 ACCOUNT_NOT_SETTLED            // 两步注册未完善
7. roles = authResult.roles ?? selectRoleCodesByUserId；permissions = authResult.permissions ?? selectPermissionCodesByUserId
8. loginUser = LoginUserDTO(userId, tenantId, userName, clientType, roles, permissions)
9. accessToken = jwtUtils.generateAccessToken(loginUser)            // claims: sub/tenantId/clientType/tokenType=access/roles/permissions
   refreshToken = jwtUtils.generateRefreshToken(loginUser)          // claims: tokenType=refresh/tokenVersion(雪花,防重放)
10. processMutualExclusion(userId, clientType)                      // 同端互斥：遍历同设备分类客户端类型清理旧会话
11. loginSessionService.createSession(userId, clientType, loginUser, refreshTokenExpiration)  // Redis 会话 TTL=7d
12. setAccountStatus(userId, user.status)；setTenantStatus(tenantId, tenant.status)          // 状态缓存（网关实时校验）
13. loginLogService.recordLoginSuccess(...)                          // 登录成功日志
14. user.lastLoginTime/lastLoginIp 更新
15. return tokenPair
```

### 6.2 Token 刷新轮换（TokenServiceImpl.refresh）

```
功能：Refresh Token 轮换刷新
输入：refreshToken、clientType
输出：新 TokenPairDTO

流程：
1. 参数校验 refreshToken 非空
2. claims = jwtUtils.parseRefreshToken(refreshToken)   // RS256 验签 + tokenType=refresh；过期→REFRESH_TOKEN_EXPIRED，无效→REFRESH_TOKEN_INVALID
3. signature = getTokenSignature(refreshToken)         // SHA-256 指纹
4. if (loginSessionService.isBlacklisted(signature)) 抛 TOKEN_BLACKLISTED   // 防重放
5. 提取 userId/tenantId/clientType；查询用户+租户并校验状态
6. 查询最新角色权限（刷新时重新拉取，保证权限变更生效）
7. 签发新双 Token（Access 2h + Refresh 7d，新 tokenVersion）
8. loginSessionService.addToBlacklist(oldSignature, 剩余有效期)   // 旧 Refresh 立即吊销
9. removeSession + createSession 更新登录态会话
10. return 新 TokenPairDTO
```

### 6.3 网关 9 步认证（AuthFilter.filter）

```
功能：全部非白名单请求的统一认证拦截
输入：ServerWebExchange（请求）
输出：放行（透传 Header）或 401/403 统一错误响应

流程：
1. 白名单 Ant 匹配（登录/注册/刷新/验证码/找回/健康检查/OpenAPI）→ 直接放行
2. Authorization 头缺失或非 "Bearer " 前缀 → 401 TOKEN_INVALID
3. RS256 公钥验签解析 Claims（ExpiredJwtException→TOKEN_EXPIRED；JwtException→TOKEN_INVALID）
4. claims.tokenType != "access" → 401 TOKEN_INVALID
5. Redis 黑名单命中 → 401 TOKEN_BLACKLISTED
6. Redis 登录态不存在 → 401 SESSION_KICKED_OUT
7. 账号状态缓存 1/2/3 → 403 ACCOUNT_DISABLED/LOCKED/BANNED
8. 租户状态缓存 1/2 → 403 TENANT_DISABLED/TENANT_EXPIRED
9. 透传 X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions 后放行
```

### 6.4 验证码管理（VerificationCodeManagerImpl）

```
功能：验证码全生命周期管理
配置：长度 6 位（首位不为 0）、有效期 300s、发送间隔 60s、模拟模式 VERIFICATION_CODE_MOCK

生成 generateCode(target, mode, purpose)：
1. code = ThreadLocalRandom(100000, 999999)
2. 写库 t_auth_verification_code（used=0，expireTime=now+300s）
3. 写 Redis 缓存 auth:verification:{purpose}:{target}（TTL=300s）
4. 写频率标记 auth:verification:freq:{purpose}:{target}（TTL=60s）

发送 sendVerificationCode：
1. isSendTooFrequent(target, purpose) 命中频率标记 → SMS_SEND_TOO_FREQUENT（429）
2. 模拟模式 → SimulatedVerificationCodeService 直接返回固定验证码
3. 真实模式 → 短信/邮件通道（生产切换）

校验 verifyCode(target, code, purpose)：
1. 查最新未使用验证码（按 target+purpose）
2. 校验：实体非空 → 未过期 → 未使用 → code 匹配
3. 校验通过 → updateUsedStatus(used=1) 一次性失效

清理 cleanExpiredCodes：deleteExpired(now) 定时清理过期记录
```

### 6.5 登出与强制踢人（LoginServiceImpl）

```
登出 logout(accessToken, clientType)（幂等）：
1. parseAccessToken 解析用户与过期时间
2. Token 签名指纹入黑名单（TTL=剩余有效期）
3. removeSession(userId, clientType)
4. 更新登录日志登出时间
5. 任何异常仅记录警告，不向外抛出（重复登出/Token 已失效不报错）

强制踢人 kickout(targetUserId, clientType)：
1. 从请求头 X-Roles 解析操作者，非 admin 角色 → PERMISSION_DENIED（403）
2. 校验目标用户存在
3. clientType 非空 → removeSession(指定端)；为空 → removeAllSessions(SCAN 匹配 auth:session:{userId}:*)
4. 记录踢人审计日志（loginResult=2，failReason=管理员强制踢人；日志失败不影响主流程）
```

### 6.6 RBAC 权限计算（用户-角色-权限）

```
权限模型：用户 --(t_auth_user_role 多对多)--> 角色 --(t_auth_role_permission 多对多)--> 权限（树形 t_auth_permission）
权限计算：
  roles(userId)       = selectRoleCodesByUserId(userId)      // 角色编码列表
  permissions(userId) = selectPermissionCodesByUserId(userId) // 用户所分配角色权限的并集
落点：
  · 登录/刷新时写入 JWT claims（roles/permissions）
  · 网关校验后透传 X-Roles/X-Permissions 至下游
  · 本版本提供模型与数据管理 API，接口级鉴权注解随业务版本演进
多租户约束：用户名/角色编码按租户唯一；查询均带 tenant 条件限定数据空间
```

## 7. 业务规则与约束

| 类别 | 规则 | 来源/落点 |
| --- | --- | --- |
| 密码策略 | 长度 8-64 字符（PasswordProperties）；BCrypt 加密存储，禁止明文；修改密码时新旧密码不得相同；日志禁止输出密码 | FR-006/NFR-003 |
| 唯一性 | 登录名/手机号在租户内唯一；角色编码在租户内唯一；权限编码全局唯一 | FR-001/FR-009~013 |
| 登录模式 | 4 种：USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH；无效模式抛 LOGIN_MODE_INVALID | FR-002 |
| 注册模式 | 5 种：USERNAME/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO；无效模式抛 REGISTER_MODE_INVALID | FR-001 |
| 客户端类型 | 6 种：Windows/Ubuntu/H5/Android/iOS/WeChatMini；无效类型抛 CLIENT_TYPE_INVALID | FR-002 |
| 会话策略 | 同端互斥（同一设备分类只保留最新会话，旧 Token 会话清除）；多端共存（不同设备分类可同时在线） | FR-002/FR-004 |
| Token 规则 | Access 2h + Refresh 7d；RS256（RSA 2048）；Refresh 轮换后旧 Token 立即入黑名单（TTL=剩余有效期）；黑名单按 Token SHA-256 签名指纹存储 | FR-003/NFR-005 |
| 状态规则 | 用户状态：0 正常/1 禁用/2 锁定/3 封禁/4 过期；租户状态：0 正常/1 禁用/2 过期；封禁/停用实时生效（Redis 缓存 + 网关校验） | FR-010/FR-011 |
| 验证码规则 | 6 位数字、5 分钟有效、60 秒发送间隔、一次性失效、按用途隔离（REGISTER/LOGIN/RESET_PASSWORD/CHANGE_PHONE 等）、错误次数限制防暴力尝试 | FR-008 |
| 防枚举 | 登录失败统一提示（"用户名或密码错误"），不泄露账号是否存在 | FR-002/NFR-005 |
| 两步注册 | account_settled=0 用户登录被拒（ACCOUNT_NOT_SETTLED），须先补全登录名/密码/手机号 | FR-001 |
| 账号安全 | 密码修改/找回成功后清除该用户全部客户端类型登录态；管理员踢人须拥有 admin 角色 | FR-004/FR-006 |
| 多租户 | 登录/注册必带 tenantCode；数据查询与操作限定当前租户空间；初始默认租户 DEFAULT、超级管理员 admin/admin123（部署后立即修改） | FR-010 |
| 架构约束 | 模块间只依赖 common，禁止互相依赖；API 统一 /api/v1/{module}/**；响应统一 ApiResult | FR-018/ADR-001 |
| 脱敏约束 | 日志中手机号/邮箱/Tenant 签名脱敏输出；Token 签名日志显示前 8 位+**** | NFR-004 |

## 8. 业务数据流

### 8.1 登录认证数据流

```
客户端（loginMode/clientType/tenantCode/凭据）
  → 网关 AuthFilter（白名单放行，转发）
  → AuthenticationService（策略认证 → 状态校验 → 构建 LoginUserDTO）
      ├─→ MariaDB：t_auth_tenant（租户状态）/ t_auth_user（账号凭据 BCrypt 比对、状态）/ 角色权限关联（RBAC 并集）
      ├─→ Redis：同端互斥清理 → auth:session:{userId}:{clientType}（LoginUserDTO，TTL=7d）
      ├─→ Redis：auth:account:status:{userId} / auth:tenant:status:{tenantId}（状态缓存）
      ├─→ JwtUtils：RSA 私钥签名签发双 Token（RSA_PRIVATE_KEY 环境变量注入）
      ├─→ MariaDB：t_auth_login_log（成功日志）+ t_auth_user（lastLoginTime/lastLoginIp）
      └─→ 返回 TokenPairDTO → 网关 → 客户端（flutter_secure_storage 安全存储）
```

### 8.2 业务访问数据流（已登录）

```
客户端（Authorization: Bearer {accessToken}）
  → 网关 AuthFilter：①~④ 本地校验（白名单/格式/RS256 验签/tokenType）
  → Redis：⑤ 黑名单 → ⑥ 登录态 → ⑦ 账号状态 → ⑧ 租户状态（ReactiveRedisTemplate 响应式）
  → 网关：⑨ 写入 X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions
  → 下游服务（auth/biz/system）：从请求头读取用户上下文，返回 ApiResult
  → 客户端：ApiInterceptor 收到 401 时携带 Refresh Token 调 /api/v1/auth/refresh 重试原请求
```

### 8.3 验证码数据流

```
发送请求（target/purpose）
  → VerificationCodeManager：频率标记校验（Redis）→ 生成 6 位码
  → MariaDB：t_auth_verification_code（used=0，expireTime=now+300s）
  → Redis：auth:verification:{purpose}:{target}（TTL=300s）+ auth:verification:freq:{purpose}:{target}（TTL=60s）
  → 发送通道：SimulatedVerificationCodeService（开发模拟）/ 短信·邮件（生产）
校验请求（target/code/purpose）
  → 查最新未使用记录 → 校验过期/已用/内容 → 置 used=1（一次性）→ 返回校验结果
```

## 9. 数据结构定义

### 9.1 跨服务传输对象（common）

| 结构 | 关键字段 | 用途 |
| --- | --- | --- |
| LoginUserDTO | userId、tenantId、userName、clientType、roles（List\<String\>）、permissions（List\<String\>） | 登录用户上下文；Redis 会话存储载体；网关 Header 透传来源 |
| TokenPairDTO | accessToken、refreshToken、accessTokenExpireIn、refreshTokenExpireIn、tokenType="Bearer" | 登录/注册/刷新统一返回的双 Token 载体 |
| ApiResult\<T\> | code、message、data、timestamp | 全接口统一响应体 |
| PageResult\<T\> | records、total、page、size | 分页统一结构 |

### 9.2 认证策略结果（auth-service 内部）

| 结构 | 关键字段 | 用途 |
| --- | --- | --- |
| AuthResult | userId、tenantId、roles、permissions | 登录策略认证结果，供编排服务构建 LoginUserDTO |
| RegisterResult | 用户信息 + TokenPairDTO | 注册策略结果，供编排服务返回 |

### 9.3 JWT Claims 载荷

| Claim | Access Token | Refresh Token |
| --- | --- | --- |
| sub | userId | userId |
| tenantId | √ | √ |
| clientType | √ | √ |
| tokenType | "access" | "refresh" |
| roles / permissions | √ | - |
| tokenVersion | - | 雪花算法唯一值（防重放） |
| iat / exp | 签发/2h | 签发/7d |

### 9.4 Redis Key 规范（RedisKeyConstants 统一管理）

| Key | 格式 | TTL | 用途 |
| --- | --- | --- | --- |
| 登录态会话 | auth:session:{userId}:{clientType} | 7d（刷新续期） | 网关登录态校验 |
| Token 黑名单 | auth:blacklist:{signature} | Token 剩余有效期 | 登出/踢人/轮换吊销 |
| 账号状态缓存 | auth:account:status:{userId} | 无（随状态变更更新） | 网关实时账号状态校验 |
| 租户状态缓存 | auth:tenant:status:{tenantId} | 无（随状态变更更新） | 网关实时租户状态校验 |
| 验证码缓存 | auth:verification:{purpose}:{target} | 300s | 验证码临时存储 |
| 验证码频率标记 | auth:verification:freq:{purpose}:{target} | 60s | 发送频率控制 |

## 10. 异常处理策略

### 10.1 异常体系（common）

```
BaseException（抽象基类）
├── BusinessException    // 业务异常（状态异常、租户异常、唯一性冲突等）
└── AuthException        // 认证异常（Token 无效/过期/黑名单、登录失败等）
错误码：ErrorCode 枚举共 29 个
  · HTTP 类：200/400/401/403/404/405/409/429/500/503
  · AUTH-0001~0019：Token/账号状态/登录/验证码/租户/权限类（19 个）
  · AUTH-0020~0033：密码重置/OAuth/手机号/账号未完善/模式无效类（14 个）
兜底：GlobalExceptionHandler（@RestControllerAdvice）统一捕获 10+ 类异常：
  参数校验（MethodArgumentNotValidException/BindException）、类型转换、非法参数、
  业务异常、认证异常、兜底 Exception → 统一 ApiResult 响应，不泄露堆栈（NFR-007）
```

### 10.2 异常分类与处理

| 异常类别 | 典型场景 | 错误码/HTTP | 处理方式 |
| --- | --- | --- | --- |
| 认证异常 | Token 缺失/无效/过期/黑名单、登录失败 | AUTH-0001~0010（401） | AuthException 抛出，网关/服务统一 401 |
| 状态异常 | 账号禁用/锁定/封禁/过期、租户禁用/过期 | AUTH-0006~0009、0014~0015（403） | BusinessException 抛出，403 |
| 验证码异常 | 验证码错误/过期、发送频繁 | AUTH-0011/0019/0023~0025 | BusinessException 抛出，400/429 |
| 账号安全异常 | 原密码错误、手机号已绑定、账号未完善 | AUTH-0022/0028~0031 | BusinessException 抛出，400/403/409 |
| 参数异常 | 参数缺失/格式错误/长度不符 | BAD_REQUEST（400） | 框架参数校验 + 全局处理器 |
| 权限异常 | 非管理员踢人、越权操作 | PERMISSION_DENIED（403） | 业务校验抛出 |
| 未预期异常 | 运行时异常、中间件故障 | INTERNAL_ERROR（500） | 全局兜底，日志记录，响应不泄露细节 |

### 10.3 容错降级（关键路径）

- Redis 会话/状态写入失败：记录 error 日志，不影响登录主流程返回（会话后续由刷新/网关兜底）
- 同端互斥处理失败：记录 error 日志，不阻断登录
- 登出异常：幂等处理，仅警告不抛出
- 踢人审计日志失败：不影响踢人主流程
- 验证码 Redis 频率检查异常：放行（避免阻塞正常发送）

## 11. 日志规范

| 业务路径 | 日志级别 | 日志内容要求 |
| --- | --- | --- |
| 登录 | info / warn | 成功：userId/tenantId/clientType/ip；失败：登录名、失败原因（密码错误等），禁止记录密码 |
| 注册 | info / warn | 成功：userId/tenantId/registerMode；失败：唯一性冲突原因 |
| Token 签发/刷新 | info / debug | 成功：userId/clientType；黑名单命中：签名脱敏（前 8 位+****） |
| 会话管理 | info / debug | 创建/移除：userId/clientType/TTL；全端移除：userId/删除数量 |
| 强制踢人 | info / warn | 操作者/目标用户/客户端类型/拒绝原因（非管理员） |
| 验证码 | info / warn | 目标脱敏（138****0000、a***@example.com）、purpose、过期时间；禁止输出验证码明文 |
| 密码管理 | warn | 修改/找回事件，禁止输出新旧密码 |
| 网关认证 | debug / warn / error | 校验通过/失败路径、userId、错误类别；响应体不泄露堆栈 |
| 全局兜底 | error | 异常堆栈记录到日志（服务端可见），响应仅返回统一错误码 |

**红线**：日志禁止输出密码、Token 原文、RSA 私钥等敏感信息（NFR-004）；手机号/邮箱/Token 签名输出前一律脱敏。

## 12. 性能优化点

| 风险点 | 现状/手段 | 优化方向 |
| --- | --- | --- |
| 网关认证热路径 | 9 步校验中 5 步为 Redis 读取，使用 ReactiveRedisTemplate 响应式非阻塞，不阻塞事件循环（ADR-002）；单请求额外耗时 ≤20ms（NFR-001） | 可引入本地缓存（Caffeine）缓存账号/租户状态，进一步降低 Redis 往返 |
| 会话/状态高频读写 | Redis 承载全部热路径数据（会话/黑名单/状态/验证码），单次读写 ≤10ms（NFR-002） | 黑名单可采用 TTL 精准过期，避免长 TTL 垃圾 Key |
| 登录/注册同步事务 | 登录流程为同步事务处理，登录/刷新 P95 ≤500ms（NFR-001） | 后续版本登录日志写入可异步化（MQ），降低事务时长 |
| RBAC 权限查询 | 登录/刷新时实时查询角色权限并写入 JWT | 权限变更低频场景可引入缓存，减少 DB 查询 |
| 全端下线 SCAN | removeAllSessions 使用 Redis SCAN 匹配删除，避免 KEYS 阻塞 | 可维护用户会话索引集合（SET），O(1) 定位会话 |
| 登录日志增长 | t_auth_login_log 随使用持续增长 | 后续版本规划日志归档与分区策略 |
| 数据库连接池 | auth-service HikariCP（max 20/min 5）、Redis 连接池（auth 16/gateway 8） | 按流量动态调优连接池参数 |
| 验证码清理 | cleanExpiredCodes 定时清理过期记录 | 可结合 Redis TTL 自动过期，DB 清理降频 |

## 13. 单元测试策略

### 13.1 测试范围与工具

- 框架：JUnit 5 + Mockito（NFR-010）；认证服务全量测试 200+ 用例
- 被测对象：auth-service 核心逻辑（策略、编排、Token、会话、验证码、密码、RBAC 管理、日志）与 common（异常/响应）

### 13.2 用例划分

| 被测模块 | 用例方向 | 覆盖目标 |
| --- | --- | --- |
| 登录策略（4 种） | 成功/失败：凭据正确、密码错误、验证码错误/过期、OAuth 未绑定、无效模式 | 每种策略成功与全部失败分支 |
| 注册策略（5 种） | 成功/失败：唯一性冲突、参数非法、两步注册补全、默认角色分配 | 每种策略成功与全部失败分支 |
| AuthenticationService | 状态校验矩阵：用户 5 状态 × 租户 3 状态 × 未完善账号；同端互斥、多端共存；Redis 失败容错 | 状态机全分支、互斥/共存策略、容错路径 |
| TokenService | 刷新成功、Token 过期/无效/黑名单、轮换后旧 Token 防重放、状态变更拦截刷新 | 轮换机制与安全边界 |
| JwtUtils | 双 Token 签发解析、tokenType 校验、过期校验、签名指纹一致性 | 载荷字段与异常分支 |
| LoginSessionService | 会话创建/查询/移除/全端移除、黑名单增查、状态缓存读写 | Redis 各操作与类型转换兜底 |
| VerificationCodeManager | 生成、频率限制、有效期、一次性失效、用途隔离、过期清理 | 验证码全生命周期 |
| LoginService（登出/踢人） | 登出幂等、黑名单写入、踢人权限校验（admin/非 admin）、指定端/所有端 | 会话安全控制主流程 |
| PasswordService | 旧密码校验、新密码策略、全端下线触发 | 密码管理规则 |
| RBAC 服务 | 用户/角色/权限 CRUD、唯一性、关联分配、删除关联处理 | 管理操作与数据一致性 |
| common | ApiResult/PageResult 序列化、异常体系映射、错误码完整性 | 统一契约与 29 错误码 |

### 13.3 边界与异常用例

- 空值/超长/非法枚举（loginMode/registerMode/clientType）→ 对应错误码
- 密码边界：7 位/8 位/64 位/65 位
- 验证码边界：59s/60s/61s 频率、299s/300s/301s 有效期、重复使用
- Token 边界：即将过期、已过期、错误签名、错误 tokenType、黑名单命中
- 用户/租户状态全矩阵：0/1/2/3/4 × 0/1/2
- Redis 不可用降级：会话写入失败、频率检查异常放行

### 13.4 覆盖目标

- 核心认证链路（登录/注册/刷新/登出/踢人）分支覆盖率 ≥ 90%
- 策略工厂与 9 种策略实现全覆盖（成功 + 失败分支）
- 验证码生命周期与 Token 轮换安全边界全覆盖
- 状态机（用户/租户/验证码/Token）全部状态迁移有对应用例
- 回归测试与版本测试用例文档联动，全部通过方可交付（验收标准 10）

---

# 版本 v0.2.5：部署资产集中化（2026-08-09）

**版本号**：v0.2.5
**日期**：2026-08-09
**编写人**：TL

> 说明：LLD 聚焦整体业务逻辑的详细设计（模块划分、业务流程、核心业务逻辑、业务规则等）；接口（API）的详细设计由 API 设计文档单独负责，LLD 中不重复编写接口定义、请求/响应参数等内容。本版本（v0.2.5）为工程构建与部署资产集中化改造，不涉及任何接口变更，无新增 API。

## 1. 模块概述

本版本（v0.2.5）以**部署资产集中化**为目标（SAD G-A6、ADR-013），对现有工程的构建输出与部署资产布局进行整体重构，不新增业务功能模块，不改动任何运行时代码与接口契约。改造范围划分为五个工程级模块：

| 模块 | 类型 | 核心职责 |
| --- | --- | --- |
| deploy 目录 | 工程目录（根目录级） | 全部最终构建产物（后端 jar 包、客户端安装文件/exe）、环境配置（env.json/env.example.json）与部署运维脚本（deploy/scripts 下 .sh/.ps1）的唯一落点；禁止存放源代码与中间产物 |
| Maven 构建产物输出配置 | 构建配置（根 pom.xml + 各模块 pom.xml） | 使 auth-service、biz-service、system-service、gateway 四个可执行模块 `mvn package` 生成的最终可运行 jar 包输出到 `deploy` 目录；仅复制最终产物，隔离 target 中间产物 |
| Flutter 客户端构建产物输出配置 | 构建配置（cloudoffice-flutter-app） | 使客户端构建生成的安装文件/exe 等最终可交付产物输出到 `deploy` 目录；构建缓存与过程文件不进入 deploy |
| 环境配置迁移 | 文件迁移 | 将根目录 `env.json`、`env.example.json` 迁移至 `deploy` 目录，并保证部署脚本引用同步适配 |
| 部署脚本迁移与路径适配 | 文件迁移 | 将根目录 `scripts` 下全部 .sh/.ps1 迁移至 `deploy/scripts` 子目录，同步调整脚本内部路径引用，保证迁移后脚本功能与迁移前一致 |

**模块间协作关系**：构建配置模块产出最终产物 → 落盘 deploy；环境配置迁移与脚本迁移 → 落盘 deploy 与 deploy/scripts；deploy 目录作为唯一汇聚点，供运维/部署/交付人员单目录获取全部可交付资产。本版本完成后，deploy 目录成为"产物集中、纯净交付、迁移无损"的唯一出口（SAD 部署资产约束）。

## 2. 模块划分与职责

### 2.1 模块依赖关系

```mermaid
flowchart LR
    ROOT["项目根目录"] --> DEP["deploy 目录（唯一落点）"]
    ROOT -->|"迁移"| DEP
    ROOT -->|"迁移"| SCR["deploy/scripts"]
    MVN["Maven 多模块构建<br/>gateway/auth/biz/system"] -->|"package 最终 jar 包"| DEP
    FLT["Flutter 客户端构建<br/>cloudoffice-flutter-app"] -->|"安装文件/exe 最终产物"| DEP
    ENV["根目录 env.json / env.example.json"] -->|"迁移"| DEP
    SCRIPTS["根目录 scripts/*.sh *.ps1"] -->|"迁移"| SCR
    DEP -->|"运维/部署/交付使用"| OPS["运维人员 / 部署工程师 / 交付人员"]
```

### 2.2 各模块内部职责

| 模块 | 内部构成 | 职责说明 |
| --- | --- | --- |
| deploy 目录 | deploy/ 根目录、deploy/scripts/ 子目录 | 根目录存放最终 jar 包、客户端安装文件/exe、env.json、env.example.json；scripts 子目录存放全部 .sh/.ps1 部署运维脚本；不放置任何源代码、target 目录、编译临时文件、测试产物 |
| Maven 构建产物输出配置 | 根 pom.xml（统一管理）、四个可执行模块 pom.xml（gateway/auth/biz/system） | 在 package 阶段将各模块最终可执行 jar 复制/输出至 `deploy` 目录（实现方式可由 maven-antrun-plugin、maven-copy 类插件或构建配置输出目录承担，由编码阶段确定）；产物命名保持模块可辨识（如 `cloudoffice-gateway.jar`、`cloudoffice-auth-service.jar` 等），避免同名覆盖；复制动作仅针对最终 jar 文件，禁止整目录递归复制 target |
| Flutter 客户端构建产物输出配置 | 客户端构建脚本/配置文件 | 构建成功后将安装文件/exe（Windows 安装程序、Web 部署包等）复制到 `deploy` 目录；构建缓存、编译过程文件不进入 deploy |
| 环境配置迁移 | deploy/env.json、deploy/env.example.json | 迁移后根目录不再保留两文件；所有依赖脚本的引用路径统一指向 deploy 下新位置 |
| 部署脚本迁移与路径适配 | deploy/scripts/ 下 21 个脚本（10 个 .sh + 11 个 .ps1） | 迁移根目录 scripts 下全部 sh/ps1；脚本内部引用的 env.json、keys 密钥目录、jar 包路径等同步适配为 deploy 相对路径；scripts 下非 sh/ps1 内容（API-TEST/、docker/、sql/、deployment-guide.md）保持原位不迁移 |

### 2.3 迁移资产清单（现状核对）

| 资产项 | 迁移前位置 | 迁移后位置 | 数量/说明 |
| --- | --- | --- | --- |
| 环境配置实际文件 | 根目录 env.json | deploy/env.json | 1 个 |
| 环境配置模板 | 根目录 env.example.json | deploy/env.example.json | 1 个 |
| 部署运维脚本（.sh） | scripts/ | deploy/scripts/ | 9 个：load-env.sh、deploy-check-env.sh、deploy-db-init.sh、deploy-rsa-keygen.sh、deploy-start-auth.sh、deploy-start-biz.sh、deploy-start-gateway.sh、deploy-start-services.sh、deploy-start-system.sh（弃用脚本残留已于 v0.2.7 移除） |
| 部署运维脚本（.ps1） | scripts/ | deploy/scripts/ | 9 个：load-env.ps1、deploy-check-env.ps1、deploy-db-init.ps1、deploy-rsa-keygen.ps1、deploy-start-auth.ps1、deploy-start-biz.ps1、deploy-start-gateway.ps1、deploy-start-services.ps1、deploy-start-system.ps1（弃用脚本残留已于 v0.2.7 移除） |
| 非脚本资产 | scripts/API-TEST/、scripts/docker/、scripts/sql/、scripts/deployment-guide.md | 不迁移 | 保持原位 |
| 后端最终 jar 包 | 各模块 target/ | deploy/ | gateway/auth/biz/system 四个最终可执行包 |
| 客户端安装产物 | 客户端构建输出目录 | deploy/ | 安装文件/exe 等最终可交付产物 |
| 构建中间产物 | 各模块 target/、客户端构建临时目录 | 不进入 deploy | 编译临时文件、测试产物、过程文件 |

## 3. 类图

本版本无新增运行时代码，核心"对象"为构建配置与目录结构。以下用 Mermaid classDiagram 描述构建配置逻辑对象及其关系（Maven 插件任务配置与 Flutter 构建脚本）：

```mermaid
classDiagram
    class MavenRootPom {
        +modules: common/gateway/auth/biz/system
        +deployDir: ${project.basedir}/../deploy
        +packagePhaseOutput() 统一产物输出配置
    }
    class ModulePom {
        +artifactId: cloudoffice-{module}
        +finalName: 最终 jar 命名
        +deployOutputTask() 复制最终 jar 至 deploy
        +executionPhase: package
    }
    class AntrunCopyTask {
        +targetDir: deploy/
        +source: target/cloudoffice-{module}.jar
        +overwrite: true
        +copySingleArtifact() 仅复制最终产物
    }
    class FlutterBuildScript {
        +windowsInstaller: 安装程序 exe
        +webBundle: Web 部署包
        +outputDir: deploy/
        +copyFinalArtifacts() 复制最终可交付产物
    }
    class DeployDirStructure {
        +deploy/env.json
        +deploy/env.example.json
        +deploy/scripts/*.sh
        +deploy/scripts/*.ps1
        +deploy/*.jar
        +deploy/*.exe
        +validatePurity() 中间产物检查
    }
    class DeployScript {
        +envPath: deploy/env.json 相对路径
        +keysPath: deploy/../keys 或 keys 相对路径
        +jarPath: deploy/*.jar 相对路径
        +resolvePaths() 路径解析适配
    }

    MavenRootPom --> ModulePom : 统一配置继承
    ModulePom --> AntrunCopyTask : package 阶段执行
    FlutterBuildScript --> DeployDirStructure : 输出最终产物
    AntrunCopyTask --> DeployDirStructure : 复制最终 jar
    DeployScript --> DeployDirStructure : 引用部署资产
```

## 4. 核心业务流程时序图

### 4.1 后端 Maven 构建产物输出流程（F-002/F-004）

```mermaid
sequenceDiagram
    autonumber
    actor DEV as 开发工程师
    participant MVN as Maven 构建（根 pom + 模块 pom）
    participant TARGET as 各模块 target/（中间产物）
    participant DEP as deploy/（最终产物）

    DEV->>MVN: mvn package（多模块构建）
    MVN->>MVN: 编译/打包生成各模块最终可执行 jar（target/ 内）
    MVN->>MVN: package 阶段触发产物输出任务（如 maven-antrun-plugin copy）
    MVN->>TARGET: 读取最终 jar 文件（仅最终产物，非整目录）
    MVN->>DEP: 复制 cloudoffice-gateway.jar / auth-service.jar / biz-service.jar / system-service.jar
    MVN-->>DEV: 构建成功，deploy 目录出现 4 个最终 jar
    DEV->>DEP: 校验：deploy 内无 target 类中间目录、无编译临时文件、无测试产物
```

### 4.2 Flutter 客户端构建产物输出流程（F-003/F-004）

```mermaid
sequenceDiagram
    autonumber
    actor DEV as 客户端开发工程师
    participant FLT as Flutter 构建（cloudoffice-flutter-app）
    participant TMP as 客户端构建输出目录（临时产物）
    participant DEP as deploy/（最终产物）

    DEV->>FLT: 执行客户端构建（Windows/Web）
    FLT->>TMP: 生成安装程序 exe / Web 部署包等产物
    FLT->>DEP: 复制最终可交付产物（安装文件/exe）至 deploy
    FLT-->>DEV: 构建成功，deploy 目录出现客户端安装产物
    DEV->>DEP: 校验：构建缓存/过程文件未混入 deploy
```

### 4.3 环境配置与部署脚本迁移流程（F-001/F-005/F-006/F-007）

```mermaid
sequenceDiagram
    autonumber
    participant OP as 实施人员（本版本改造）
    participant ROOT as 项目根目录
    participant DEP as deploy/
    participant SCR as deploy/scripts/

    OP->>ROOT: 新建 deploy 目录（已存在则复用）
    OP->>ROOT: 迁移 env.json → deploy/env.json；env.example.json → deploy/env.example.json
    OP->>ROOT: 根目录不再保留 env.json / env.example.json
    OP->>ROOT: 新建 deploy/scripts 子目录
    OP->>ROOT: 迁移 scripts 下全部 .sh/.ps1（21 个）至 deploy/scripts
    OP->>ROOT: scripts 下 API-TEST/ docker/ sql/ deployment-guide.md 保持原位
    OP->>SCR: 同步适配脚本内路径引用（env.json、keys、jar 包等）
    OP->>SCR: 验证脚本可执行（load-env、deploy-check-env 等冒烟验证）
    OP->>DEP: 校验 deploy 目录结构完整（AC-1/AC-5/AC-6/AC-7）
```

## 5. 状态图

### 5.1 构建产物生命周期（deploy 目录内资产）

```mermaid
stateDiagram-v2
    [*] --> 构建中 : 执行 mvn package / Flutter 构建
    构建中 --> 待输出 : 生成最终产物（target/ 或构建输出目录）
    待输出 --> 已落盘 : 复制最终产物至 deploy（copy 任务/脚本）
    已落盘 --> 已交付 : 交付人员从 deploy 收集
    已落盘 --> 已更新 : 下一版本重新构建覆盖（overwrite）
    构建中 --> 构建失败 : 编译/打包异常
    构建失败 --> 构建中 : 修复后重新构建
    待输出 --> 中间产物 : 被误复制（整目录复制/过程文件）
    中间产物 --> 待输出 : 修正构建配置仅输出最终产物
```

### 5.2 脚本迁移状态流转

```mermaid
stateDiagram-v2
    [*] --> 待迁移 : scripts/ 下 .sh/.ps1 文件
    待迁移 --> 已迁移 : 移动至 deploy/scripts/
    已迁移 --> 已适配 : 脚本内路径引用同步更新
    已适配 --> 已验证 : 冒烟执行通过（load-env/deploy-check-env）
    已验证 --> [*] : 迁移完成
    已适配 --> 回退修正 : 路径引用错误
    回退修正 --> 已适配 : 修正后重新验证
```

## 6. 核心业务逻辑

### 6.1 后端 Maven 产物输出（F-002/F-004）

```
功能：mvn package 后将最终可执行 jar 输出到 deploy，隔离中间产物
执行时机：package 阶段（模块构建完成后）
输入：各模块 target/ 下最终可执行 jar
输出：deploy/cloudoffice-{module}.jar

逻辑：
1. 确定输出目录 deployDir = ${project.parent.basedir}/deploy（根目录相对定位，模块构建不受工作目录影响）
2. 各可执行模块（gateway/auth-service/biz-service/system-service）在 package 阶段执行产物输出任务：
   a. 仅取 target/ 下的最终 jar 文件（与 finalName 一致的产物，如 cloudoffice-gateway.jar）
   b. 复制到 deployDir，overwrite=true（重复构建覆盖旧版本）
   c. 禁止整目录递归复制 target/（防止编译类、测试报告等中间产物混入）
3. common 模块为库依赖，不产生可执行产物，不参与输出
4. 构建产物命名保持 artifactId 可辨识，避免四个服务同名覆盖

校验（构建后）：
- deploy/ 下存在 4 个最终 jar（AC-2）
- deploy/ 下不存在 target 类目录、*.class、测试报告等中间产物（AC-4）
```

### 6.2 客户端 Flutter 产物输出（F-003/F-004）

```
功能：客户端构建后将最终可交付产物输出到 deploy
输入：Flutter 构建输出目录中的安装程序 exe / Web 部署包
输出：deploy/ 下客户端安装产物

逻辑：
1. 构建命令生成最终产物（如 Windows 安装程序 .exe、Web 构建包）
2. 构建脚本/配置将最终产物复制到 deploy/
3. 仅复制最终可交付产物文件，构建缓存（build/ 目录）、过程文件不进入 deploy

校验（构建后）：
- deploy/ 下存在客户端安装产物（AC-3）
- deploy/ 下无构建缓存与过程文件（AC-4）
```

### 6.3 环境配置与脚本迁移（F-005/F-006/F-007）

```
功能：env 配置与部署脚本集中迁移并保证功能无损
迁移清单：
- env.json / env.example.json → deploy/
- scripts/ 下全部 .sh/.ps1（21 个）→ deploy/scripts/
- scripts/ 下 API-TEST/、docker/、sql/、deployment-guide.md → 不迁移

路径适配规则（保证 AC-7）：
1. 脚本内对 env.json / env.example.json 的引用：由"根目录相对路径"改为"deploy 目录相对路径"
   例如：scripts 内引用 ../env.json → 新脚本内引用 ../env.json（deploy/scripts 上级即 deploy，语义一致），
   或采用"以脚本所在目录为基准向上解析"的定位方式，由编码阶段按脚本实际写法统一适配
2. 脚本内对 keys 密钥目录的引用：保持 keys 目录位于根目录（deploy 上级）的现状，路径同步换算
3. 脚本内对 jar 包的引用：jar 包统一位于 deploy/，脚本引用改为 deploy 相对路径
4. load-env.sh / load-env.ps1 作为共享环境加载入口，被其他脚本 source/调用，路径适配后必须保证全部调用方一致

验证：
- deploy/scripts 下脚本可执行（冒烟：load-env → deploy-check-env）（AC-7）
- 根目录 scripts 下不再保留 .sh/.ps1（AC-6）
- 根目录不再保留 env.json / env.example.json（AC-5）
```

## 7. 业务规则与约束

| 类别 | 规则 | 来源/落点 |
| --- | --- | --- |
| 目录唯一落点 | 根目录 `deploy` 为最终构建产物、环境配置、部署脚本的唯一落点；源代码与构建配置保留在根目录及模块目录 | SAD G-A6 / ADR-013 |
| 目录纯净性 | deploy 内禁止出现 target 类中间目录、编译临时文件、测试产物、构建缓存/过程文件；只允许最终产物（jar、安装文件/exe、env 配置、部署脚本）进入 | SAD 部署资产约束 / PRD F-004 / AC-4 |
| 复制粒度 | 产物生成必须"仅复制最终产物文件"，严禁整目录递归复制构建输出目录 | PRD F-004 / AC-4 |
| 产物命名 | 后端 jar 命名保持模块可辨识（artifact 命名，如 cloudoffice-auth-service.jar），避免四个服务同名覆盖；重复构建 overwrite 覆盖旧版本 | PRD F-002 / AC-2 |
| 目录复用 | deploy 目录已存在时复用现有目录，不重复创建、不覆盖已有有效内容 | PRD US-001 边界 |
| 构建失败 | 构建失败不产生最终产物，deploy 不落盘失败产物 | PRD US-001 边界 |
| 迁移范围 | 仅迁移 scripts 下 .sh/.ps1；API-TEST/、docker/、sql/、deployment-guide.md 等非脚本内容保持原位，不得迁移 | PRD F-007 / AC-6 |
| 迁移完整性 | 迁移后根目录 scripts 下不再保留已迁移的 .sh/.ps1；根目录不再保留 env.json、env.example.json | PRD F-005/F-007 / AC-5/AC-6 |
| 路径适配 | 迁移后脚本内对 env.json、keys 密钥目录、jar 包等路径引用必须同步适配，保证部署运维功能与迁移前一致 | SAD 部署资产约束 / PRD F-007 / AC-7 |
| 接口契约 | 本版本不新增/不修改任何接口定义，不改变运行时代码行为 | SAD v0.2.5 范围 |
| 架构约束 | 构建配置调整不改变模块依赖关系（服务间仍只依赖 common），不影响服务注册与路由 | ADR-001 |

## 8. 业务数据流

### 8.1 构建产物流向

```
Maven 各模块（gateway/auth/biz/system）
  → 编译 → target/（中间产物，停留原地）
  → package 最终可执行 jar（target/ 内）
  → 产物输出任务（仅复制最终 jar 文件）
  → deploy/  ← 唯一汇聚点

Flutter 客户端（cloudoffice-flutter-app）
  → 构建（build/ 缓存与过程文件，停留原地）
  → 安装文件/exe 等最终产物
  → deploy/  ← 唯一汇聚点

交付人员 → deploy/（单目录收集全部可交付资产）
```

### 8.2 部署资产流向（迁移后）

```
deploy/env.json、deploy/env.example.json  ← 根目录迁移
deploy/scripts/*.sh、*.ps1（21 个）      ← scripts/ 迁移 + 路径适配
deploy/scripts 脚本
  → 引用 deploy/env.json（环境变量加载）
  → 引用 keys/（RSA 密钥，位于 deploy 上级根目录）
  → 引用 deploy/*.jar（启动服务）
  → 执行部署运维（check-env / db-init / rsa-keygen / start-* / load-env）
```

### 8.3 中间产物隔离流

```
构建中间产物（target/、build/、编译临时文件、测试产物）
  → 一律停留在原构建输出位置
  → 禁止被复制/输出至 deploy（构建配置与复制动作双重约束）
  → 构建后校验（deploy 纯净性检查）作为兜底
```

## 9. 数据结构定义

### 9.1 deploy 目录结构（迁移/构建完成后目标形态）

| 路径 | 类型 | 内容说明 |
| --- | --- | --- |
| deploy/env.json | 文件 | 实际环境配置（迁移自根目录） |
| deploy/env.example.json | 文件 | 环境配置模板（迁移自根目录） |
| deploy/cloudoffice-gateway.jar | 文件 | 网关最终可执行包 |
| deploy/cloudoffice-auth-service.jar | 文件 | 认证服务最终可执行包 |
| deploy/cloudoffice-biz-service.jar | 文件 | 企业服务最终可执行包 |
| deploy/cloudoffice-system-service.jar | 文件 | 系统服务最终可执行包 |
| deploy/{客户端安装产物} | 文件 | Flutter 构建安装文件/exe 等 |
| deploy/scripts/*.sh | 文件 | 部署运维脚本（Linux/macOS） |
| deploy/scripts/*.ps1 | 文件 | 部署运维脚本（Windows） |
| deploy/（禁止项） | - | target 类目录、编译临时文件、测试产物、构建缓存/过程文件 |

### 9.2 脚本路径引用约定（迁移后）

| 引用对象 | 迁移前写法示例 | 迁移后定位约定 |
| --- | --- | --- |
| env.json | 根目录相对/绝对路径 | 以脚本自身位置（deploy/scripts）向上定位至 deploy/env.json |
| keys 密钥目录 | 根目录 keys/ | 由 deploy/scripts 向上两级定位至根目录 keys/（keys 目录保持在根目录） |
| jar 包 | 各模块 target/ 路径 | 统一定位至 deploy/ 下模块 jar |
| 数据库初始化 SQL | scripts/sql/ | 保持原 scripts/sql/ 位置，引用相应换算 |

## 10. 异常处理策略

| 异常类别 | 典型场景 | 处理方式 |
| --- | --- | --- |
| 构建失败 | Maven 编译/打包失败、Flutter 构建失败 | 构建进程报错退出，deploy 不落盘失败产物；开发人员修复后重新构建（US-001 边界） |
| 产物复制失败 | copy 任务目标目录不可写、磁盘空间不足 | 构建报错，明确输出失败原因与目标路径；不产生半成品产物（或产生后由校验发现并清理） |
| 中间产物误复制 | 构建配置误将整目录复制 | 构建后纯净性校验兜底发现，修正构建配置仅输出最终产物（PRD 流程图 J/K 分支） |
| 脚本路径引用失效 | 迁移后脚本找不到 env.json/jar/keys | 迁移阶段逐一适配路径；验证阶段冒烟执行（load-env → deploy-check-env）提前发现，修正后重新验证 |
| 迁移冲突 | deploy 目录已存在且内容与预期不符 | 复用现有目录，核对内容；不覆盖已有有效内容（US-001 边界） |
| 同名产物覆盖 | 多模块同名 jar | 命名规则规避（模块可辨识命名），构建配置保证不发生误覆盖 |

## 11. 日志规范

| 业务路径 | 日志级别 | 日志内容要求 |
| --- | --- | --- |
| Maven 产物输出 | info | 复制源文件、目标 deploy 路径、复制结果（成功/失败） |
| Flutter 产物输出 | info | 最终产物文件、目标 deploy 路径、复制结果 |
| 产物复制失败 | error | 失败原因、源/目标路径（供修复定位） |
| 中间产物过滤 | debug | 被排除的非最终产物清单（调试用） |
| 脚本迁移 | info | 迁移文件清单、路径适配前后对照（迁移执行阶段人工/脚本记录） |
| 脚本验证执行 | info / error | 冒烟执行结果（load-env、deploy-check-env 等），失败输出错误原因 |

## 12. 性能优化点

| 风险点 | 手段 |
| --- | --- |
| 全量构建产物重复复制 | 产物输出任务仅复制最终 jar 文件（小体积、数量固定 4 个），不复制整个 target 目录，复制开销恒定且极小 |
| 构建与产物输出耦合 | 产物输出绑定 package 阶段执行，构建链路清晰；中间产物留在 target 由 Maven 生命周期管理，deploy 无需清理逻辑 |
| 多模块重复构建 | 根 pom 统一配置产物输出，各模块继承，避免各模块各自实现造成差异与重复 |
| 脚本迁移人工适配易错 | 迁移清单与路径引用约定统一管理（见 9.2），验证阶段冒烟执行提前发现问题，降低回归成本 |

## 13. 单元测试策略

### 13.1 测试范围与工具

本版本为工程构建与目录迁移改造，测试以**构建验证与目录结构校验**为主（无新增运行时代码，不涉及 JUnit 业务单测）：

- Maven 构建验证：执行 `mvn package`，校验 deploy 目录产物落位与纯净性（AC-2/AC-4）
- Flutter 构建验证：执行客户端构建，校验安装产物落位与纯净性（AC-3/AC-4）
- 目录结构校验：检查 deploy 目录结构完整性（AC-1/AC-5/AC-6）
- 脚本冒烟验证：执行 deploy/scripts 下 load-env、deploy-check-env 等脚本，校验路径引用正确（AC-7）

### 13.2 用例划分

| 被测对象 | 用例方向 | 验收关联 |
| --- | --- | --- |
| deploy 目录结构 | 存在性、包含 env.json/env.example.json/scripts 子目录 | AC-1 |
| Maven 构建产物 | package 后 deploy 存在 4 个最终 jar（gateway/auth/biz/system） | AC-2 |
| Flutter 构建产物 | 构建后 deploy 存在安装文件/exe 最终产物 | AC-3 |
| deploy 纯净性 | 无 target 类目录、无编译临时文件、无测试产物、无构建缓存 | AC-4 |
| 环境配置迁移 | 根目录无 env.json/env.example.json，deploy 下存在 | AC-5 |
| 脚本迁移 | scripts 下 21 个 sh/ps1 全部位于 deploy/scripts；根目录 scripts 下不再保留；API-TEST/docker/sql/deployment-guide.md 未迁移 | AC-6 |
| 脚本路径适配 | 冒烟执行 load-env、deploy-check-env 等脚本成功，env.json 加载正常 | AC-7 |

### 13.3 边界与异常用例

- deploy 目录已存在 → 复用不覆盖（US-001 边界）
- 构建失败 → deploy 不产生失败产物（US-001 边界）
- 脚本引用旧路径 → 适配失败场景可被冒烟执行发现并修正（AC-7）
- 中间产物误复制 → 纯净性校验发现并修正构建配置（PRD 流程图 J/K 分支）

### 13.4 覆盖目标

- 全部 7 条验收标准（AC-1 ~ AC-7）均有对应校验用例
- 构建产物落位、目录纯净性、迁移完整性、脚本可执行性四条主线全部覆盖
- 校验结果记录至版本测试用例文档，全部通过方可交付

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->

---

# 版本 v0.2.6：服务启动修复与 API 回归闭环（2026-08-09）

**版本号**：v0.2.6
**日期**：2026-08-09
**编写人**：TL

> 说明：LLD 聚焦整体业务逻辑的详细设计（模块划分、业务流程、核心业务逻辑、业务规则等）；接口（API）的详细设计由 API 设计文档单独负责，LLD 中不重复编写接口定义、请求/响应参数等内容。本版本（v0.2.6）为部署与配置缺陷修复工程版本（需求来源：docs/cso-v0.2.5/regression-api-test.md 记录的回归测试问题），不涉及任何接口变更，无新增 API（API 契约 API-001~API-033 完整保留）。

## 1. 模块概述

本版本（v0.2.6）聚焦修复 v0.0.1 基线遗留的两项部署/配置缺陷（v0.2.5 回归报告审核项 T-02），目标为"4 个服务全部可启动 + API 测试闭环"（SAD ADR-014/ADR-015、PRD G-1~G-3）：

1. **bootstrap 配置引导依赖缺失**：全项目 pom 均未引入 `spring-cloud-starter-bootstrap`，Spring Boot 3.x 下 bootstrap.yml（含 Nacos discovery/config server-addr）默认不加载，auth/biz/system 启动报 `No spring.config.import property has been defined`，Nacos 配置引导链路断裂；
2. **RSA 密钥格式契约不匹配**：deploy/env.json 注入的 `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 为 PEM 文件整体 Base64（多行、含 BEGIN/END 标记），与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 严格解码契约（期望 DER 编码单行 Base64）不一致，网关启动报 `RSA 公钥解析失败（Unable to decode key / extra data at the end）`。

本版本业务逻辑划分为四个工程级模块，遵循"最小修复、契约不变"（PRD 核心设计理念）原则，不新增任何业务功能，不触碰接口层（Controller/DTO/响应体）与客户端 lib/ 运行时代码：

| 模块 | 类型 | 核心职责 |
| --- | --- | --- |
| bootstrap 配置引导修复 | 构建/依赖配置（根 pom.xml + 4 个服务模块 pom） | 引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml 在 Spring Boot 3.x 下的加载，打通 Nacos discovery/config 引导链路，消除 `No spring.config.import property has been defined` 启动报错（F-001） |
| RSA 密钥格式契约统一 | 脚本+配置（deploy/scripts/deploy-rsa-keygen.ps1、deploy/env.json） | 密钥生成脚本输出与 Java 端 RsaKeyConfig 解码逻辑保持同一格式契约（DER 编码单行 Base64，无 PEM 头尾、无换行），消除 `RSA 公钥解析失败`（F-002） |
| 服务启动与健康检查验证 | 部署链路（gateway/auth/biz/system + Nacos/MariaDB/Redis） | 重新构建 4 个服务 jar，按部署文档标准流程启动并注册到 Nacos，健康检查全部通过，启动日志无两项缺陷报错（F-003） |
| 接口回归验证闭环 | 测试资产（scripts/API-TEST/cso-api-test-v0.0.1.py、cso-api-test-v0.2.5.py） | 服务可用前提下补跑 v0.0.1 基线回归（TC-001~045，PASS=45、FAIL=0）并复核 v0.2.5 回归（TC-046~051，PASS=26、FAIL=0），输出 v0.2.6 回归报告，API 测试全部跑通（F-004/F-005） |

**模块间协作关系**：bootstrap 依赖修复 + RSA 密钥契约统一 → 重新构建并启动 4 个服务（Nacos 注册、MariaDB/Redis 依赖可用）→ 服务健康检查通过 → 执行接口回归脚本（TC-001~045 补跑 + TC-046~051 复核）→ 输出回归报告闭环。四个模块之间存在严格的先后依赖：前两个模块的修复成果是服务启动验证的前提，服务启动验证又是接口回归闭环的前提。

## 2. 模块划分与职责

### 2.1 模块依赖关系

```mermaid
flowchart LR
    POM["根 pom.xml + 4 个服务模块 pom<br/>引入 spring-cloud-starter-bootstrap"] -->|"F-001 构建通过"| BUILD["重新构建 4 个服务 jar<br/>gateway/auth/biz/system"]
    PS1["deploy/scripts/deploy-rsa-keygen.ps1<br/>输出 DER 单行 Base64"] -->|"F-002 生成密钥"| ENV["deploy/env.json<br/>RSA_PUBLIC_KEY / RSA_PRIVATE_KEY"]
    ENV -->|"环境变量注入"| START["服务启动链路<br/>bootstrap.yml 引导 + RsaKeyConfig 解析"]
    BUILD -->|"F-003 部署启动"| START
    START -->|"健康检查通过"| T001["cso-api-test-v0.0.1.py<br/>TC-001~045 动态回归"]
    START -->|"契约不变"| T046["cso-api-test-v0.2.5.py<br/>TC-046~051 复核"]
    T001 -->|"F-004 PASS=45"| RPT["v0.2.6 回归报告<br/>regression-api-test.md"]
    T046 -->|"F-005 PASS=26"| RPT
    RPT -->|"API 测试全部跑通"| DONE["验收完成"]
```

### 2.2 各模块内部职责

| 模块 | 内部构成 | 职责说明 |
| --- | --- | --- |
| bootstrap 配置引导修复 | 根 pom.xml（dependencyManagement 统一管理）、四个服务模块 pom（gateway/auth/biz/system） | 各服务模块实际引入 `spring-cloud-starter-bootstrap`（仅根 pom 声明 dependencyManagement 而不在模块引入仍会报 import-check 错误）；引入后 bootstrap.yml 恢复生效，`spring.cloud.nacos.discovery.server-addr` 与 `spring.cloud.nacos.config.server-addr` 可被加载；不得改变既有接口契约与业务代码逻辑 |
| RSA 密钥格式契约统一 | deploy/scripts/deploy-rsa-keygen.ps1（密钥生成脚本）、deploy/env.json（密钥注入载体）、RsaKeyConfig（gateway/auth 密钥解析） | 脚本输出与环境注入的密钥值必须与 Java 端解码契约严格一致：DER 编码单行 Base64（无 PEM 头尾、无换行），`Base64.getDecoder()` 可直接解码、`X509EncodedKeySpec`（公钥）/`PKCS8EncodedKeySpec`（私钥）可构造 KeySpec；私钥不得入库、不得写入日志 |
| 服务启动与健康检查验证 | 4 个服务 jar、Nacos（注册中心）、MariaDB、Redis、部署脚本（deploy/scripts/deploy-start-*.ps1/.sh） | 按部署文档标准流程启动：env.json 环境变量 + Nacos 注册 + MariaDB/Redis 依赖；启动日志不得再出现 `No spring.config.import property has been defined` 与 `RSA 公钥解析失败`；各服务健康检查返回正常状态；Nacos 控制台可见 4 个服务实例 |
| 接口回归验证闭环 | scripts/API-TEST/cso-api-test-v0.0.1.py（TC-001~045）、cso-api-test-v0.2.5.py（TC-046~051）、docs/cso-v0.2.6/regression-api-test.md（回归报告） | v0.0.1 基线脚本补跑：网关（9000）与认证服务（9100）可访问，admin/admin123 可用，TC-001~045 全部动态执行通过（PASS=45、FAIL=0），消除"待执行/环境阻塞"历史状态；v0.2.5 脚本复核保持 PASS=26、FAIL=0；回归结果记录到 v0.2.6 回归报告 |

### 2.3 修复范围与红线（不得触碰）

| 资产类别 | 范围约束 | 说明 |
| --- | --- | --- |
| 接口层 | 禁止改动 | Controller/DTO/响应体（ApiResult/PageResult）零改动，API-001~API-033 契约完整保留（PRD F-005） |
| 客户端运行时代码 | 禁止改动 | cloudoffice-flutter-app lib/ 代码零改动，客户端构建产物保持原状 |
| 业务代码逻辑 | 禁止改动 | auth-service 认证/Token/会话/验证码/RBAC 等业务逻辑不变 |
| 数据库结构 | 禁止改动 | 不新增数据表、不修改表结构（PRD 数据需求：9 张表结构不变） |
| 允许改动 | 仅限 | 构建/依赖配置（pom）、密钥生成脚本（deploy-rsa-keygen.ps1）、环境配置（deploy/env.json）、部署/回归验证流程与测试资产 |

## 3. 类图

本版本无新增业务运行时代码，核心"对象"为构建依赖配置、密钥契约与启动验证逻辑。以下用 Mermaid classDiagram 描述相关逻辑对象及其关系（RsaKeyConfig 为既有类，此处描述其与本版本契约的关系）：

```mermaid
classDiagram
    class RootPom {
        +springCloudAlibabaVersion: 2023.0.1.0
        +dependencyManagement: spring-cloud-starter-bootstrap 统一声明
        +modulePoms: common/gateway/auth/biz/system
    }
    class ModulePom {
        +artifactId: cloudoffice-{gateway|auth-service|biz-service|system-service}
        +dependencies: spring-cloud-starter-bootstrap（实际引入）
        +bootstrapLoad(): bootstrap.yml 在 Spring Boot 3.x 下生效
    }
    class BootstrapYml {
        +spring.cloud.nacos.discovery.server-addr
        +spring.cloud.nacos.config.server-addr
        +spring.application.name
        +loadOrder: 先于 application.yml 加载
    }
    class RsaKeygenScript {
        +outputFormat: DER 编码单行 Base64（无 PEM 头尾、无换行）
        +publicKey: RSA_PUBLIC_KEY
        +privateKey: RSA_PRIVATE_KEY
        +writeToEnvJson(): 注入 deploy/env.json
    }
    class EnvJson {
        +RSA_PUBLIC_KEY: DER 单行 Base64
        +RSA_PRIVATE_KEY: DER 单行 Base64
        +DB/REDIS/NACOS 连接参数: 保持不变
    }
    class RsaKeyConfig {
        +publicKey: 由 RSA_PUBLIC_KEY 解码
        +privateKey: 由 RSA_PRIVATE_KEY 解码
        +decodePublicKey(): Base64.getDecoder() + X509EncodedKeySpec
        +decodePrivateKey(): Base64.getDecoder() + PKCS8EncodedKeySpec
    }
    class JwtUtils {
        +sign(): RSA 私钥签名（RS256）
        +verify(): RSA 公钥验签
    }
    class HealthCheck {
        +serviceName
        +status: 正常
        +version
        +timestamp
    }
    class ApiTestScript {
        +baselineScript: cso-api-test-v0.0.1.py（TC-001~045）
        +v025Script: cso-api-test-v0.2.5.py（TC-046~051）
        +run(): 动态执行全部用例
        +report(): 结果写入 regression-api-test.md
    }

    RootPom --> ModulePom : dependencyManagement 声明
    ModulePom --> BootstrapYml : 依赖引入后加载
    RsaKeygenScript --> EnvJson : 生成并注入（契约一致）
    EnvJson --> RsaKeyConfig : 环境变量注入
    RsaKeyConfig --> JwtUtils : 提供密钥
    BootstrapYml --> HealthCheck : 服务启动后暴露
    HealthCheck --> ApiTestScript : 前置条件
    ApiTestScript --> RsaKeyConfig : 登录/验签链路验证
```

## 4. 核心业务流程时序图

### 4.1 修复后服务启动流程（F-001/F-003）

```mermaid
sequenceDiagram
    autonumber
    actor OP as 运维/部署人员
    participant MVN as Maven 构建
    participant BOOT as spring-cloud-starter-bootstrap 引导
    participant YML as bootstrap.yml（Nacos server-addr）
    participant NACOS as Nacos 2.3
    participant SVC as 服务实例（gateway/auth/biz/system）
    participant MDB as MariaDB/Redis

    OP->>MVN: 引入 spring-cloud-starter-bootstrap 后 mvn package
    MVN-->>OP: 4 个服务 jar 构建成功（deploy/ 目录）
    OP->>SVC: 按部署脚本启动（env.json 环境变量注入）
    SVC->>BOOT: 启动上下文初始化
    BOOT->>YML: 加载 bootstrap.yml（先于 application.yml）
    YML->>NACOS: 读取 Nacos config server-addr + discovery server-addr
    SVC->>NACOS: 注册服务实例（服务名/ip/端口）
    SVC->>MDB: 依赖可用性校验（auth 连库/全部连 Redis）
    SVC->>SVC: 启动完成，无 import-check / RSA 解析报错
    OP->>SVC: 访问健康检查端点（经网关或直连）
    SVC-->>OP: 服务名/状态正常/版本/时间戳
    NACOS-->>OP: 控制台可见 4 个服务实例
```

### 4.2 RSA 密钥生成/注入/解析流程（F-002）

```mermaid
sequenceDiagram
    autonumber
    actor OP as 运维/部署人员
    participant PS1 as deploy-rsa-keygen.ps1
    participant FILE as 密钥输出（DER 单行 Base64）
    participant ENV as deploy/env.json
    participant CFG as RsaKeyConfig（gateway/auth）
    participant JWT as JwtUtils/JWT RS256 链路

    OP->>PS1: 执行密钥生成脚本
    PS1->>FILE: 生成 RSA 2048 密钥对
    FILE->>FILE: 公钥 DER → Base64 单行（无 BEGIN/END、无换行）
    FILE->>FILE: 私钥 PKCS8 DER → Base64 单行
    PS1->>ENV: 写入 RSA_PUBLIC_KEY / RSA_PRIVATE_KEY
    OP->>ENV: 确认 env.json 密钥为单行 Base64 契约
    ENV->>CFG: 环境变量注入
    CFG->>CFG: Base64.getDecoder() 解码 → X509/PKCS8EncodedKeySpec 构造
    CFG->>JWT: 提供公钥（验签）/私钥（auth 签名）
    JWT->>JWT: 登录签发 RS256 签名 / 网关验签通过
    JWT-->>OP: 网关启动无 "RSA 公钥解析失败"，签名验签链路正常
```

### 4.3 v0.0.1 基线接口回归闭环流程（F-004）

```mermaid
sequenceDiagram
    autonumber
    actor TE as 测试工程师
    participant GW as 网关（9000）
    participant AS as 认证服务（9100）
    participant SCRIPT as cso-api-test-v0.0.1.py
    participant MDB as MariaDB
    participant RD as Redis

    TE->>GW: 确认 4 服务健康检查通过、Nacos 已注册
    TE->>SCRIPT: 执行 python cso-api-test-v0.0.1.py http://localhost:9000
    SCRIPT->>GW: admin 登录（白名单放行）
    GW->>AS: 转发登录（RS256 签名链路验证）
    AS->>MDB: 查询租户/用户/角色权限
    AS->>RD: 会话/状态缓存
    AS-->>SCRIPT: 返回双 Token
    SCRIPT->>SCRIPT: TC-001~045 依次执行（登录/刷新/登出/用户/角色/权限/网关鉴权/健康检查）
    SCRIPT-->>TE: 退出码 0，PASS=45、FAIL=0
    TE->>TE: 汇总结果写入 v0.2.6 回归报告，闭环历史"环境阻塞"状态
```

### 4.4 既有契约无回归复核流程（F-005）

```mermaid
sequenceDiagram
    autonumber
    participant TE as 测试工程师
    participant GIT as git 变更清单
    participant DOC as API 设计文档（v0.2.6 无变更）
    participant SCRIPT as cso-api-test-v0.2.5.py

    TE->>GIT: 核对变更清单：无 Controller/DTO/响应体改动
    TE->>GIT: 核对变更清单：无客户端 lib/ 运行时代码改动
    TE->>DOC: 静态核对：API-001~API-033 完整保留、无新增/变更/删除
    TE->>SCRIPT: 执行 python cso-api-test-v0.2.5.py <项目根>
    SCRIPT-->>TE: TC-046~051 保持 PASS=26、FAIL=0
    TE->>TE: 双重确认（静态 + 动态）无回归，记录回归报告
```

## 5. 状态图

### 5.1 服务启动状态流转（本版本修复目标）

```mermaid
stateDiagram-v2
    [*] --> 构建失败 : mvn package 异常（依赖引入错误）
    构建失败 --> 构建成功 : 修正 pom 依赖后重新构建
    [*] --> 构建成功 : 引入 bootstrap 依赖后构建通过
    构建成功 --> 启动失败 : Nacos 不可达 / 密钥解析失败 / 依赖缺失
    启动失败 --> 启动成功 : 按启动日志定位修复（bootstrap/RSA/基础设施）
    启动失败 --> 启动失败 : 未修复缺陷重复启动（历史状态，v0.2.5 回归暴露）
    启动成功 --> 已注册 : 服务注册到 Nacos
    已注册 --> 健康通过 : /api/v1/{auth|biz|system}/health 返回正常
    健康通过 --> [*] : 回归前置条件就绪
    健康通过 --> 回归闭环 : TC-001~051 全部动态执行通过
    回归闭环 --> [*] : v0.2.6 验收完成
```

### 5.2 RSA 密钥格式契约状态流转

```mermaid
stateDiagram-v2
    [*] --> PEM整体Base64 : v0.0.1 历史 env.json（多行、含 BEGIN/END，v0.2.5 回归暴露）
    PEM整体Base64 --> 契约不一致 : 与 Java 严格解码契约不匹配
    契约不一致 --> 启动崩溃 : 网关报 RSA 公钥解析失败（Unable to decode key）
    启动崩溃 --> DER单行Base64 : v0.2.6 修复：deploy-rsa-keygen.ps1 重生成/重注入
    DER单行Base64 --> 契约一致 : Base64.getDecoder() 可直接解码
    契约一致 --> 解析成功 : X509/PKCS8EncodedKeySpec 构造密钥
    解析成功 --> 验签正常 : 登录签发（私钥）/网关验签（公钥）链路工作
    验签正常 --> [*] : 缺陷闭环
    解析成功 --> 配对失败 : 公钥私钥不配对（重新成对生成）
    配对失败 --> DER单行Base64 : 重新执行密钥生成脚本
```

### 5.3 回归用例状态流转（TC-001~045）

```mermaid
stateDiagram-v2
    [*] --> 待执行 : v0.0.1 阶段汇总（从未动态闭环）
    待执行 --> 环境阻塞 : 服务无法启动（v0.2.5 回归记录）
    环境阻塞 --> 动态执行 : v0.2.6 服务修复可用后补跑
    动态执行 --> 通过 : 断言全部满足（PASS）
    动态执行 --> 失败 : 断言不满足（FAIL，测试数据冲突等）
    失败 --> 动态执行 : 清理测试数据后重跑
    通过 --> [*] : TC-001~045 全部通过，回归闭环
```

## 6. 核心业务逻辑

### 6.1 bootstrap 配置引导依赖引入（F-001）

```
功能：恢复 bootstrap.yml 在 Spring Boot 3.x 下的加载，打通 Nacos 配置引导链路
目标：消除 auth/biz/system 启动报错 "No spring.config.import property has been defined"

方案选择（须保证最终效果一致）：
方案 A（推荐，本版本采用）：
1. 根 pom dependencyManagement 声明 spring-cloud-starter-bootstrap（版本随 Spring Cloud 2023.0.1 管理）
2. 四个服务模块（gateway/auth/biz/system）pom 实际引入该依赖
   —— 注意：仅根 pom 声明 dependencyManagement 而未在模块引入，启动仍报 import-check 错误
方案 B（备选）：
1. 各服务 bootstrap.yml/application.yml 配置 spring.config.import=optional:nacos:${...}
2. 同时关闭 nacos-config 的 import-check 强校验
   —— 注意：只配置 import 而不关闭校验仍会报错

执行检查（验收）：
- 构建通过：mvn package 无依赖解析错误
- 启动日志：不再出现 "No spring.config.import property has been defined"
- bootstrap.yml 生效：spring.cloud.nacos.discovery.server-addr / spring.cloud.nacos.config.server-addr 被加载
- 服务注册：Nacos 控制台可见 4 个服务实例
```

### 6.2 RSA 密钥生成与注入（F-002）

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

### 6.3 RsaKeyConfig 密钥解析（F-002，既有代码逻辑）

```
功能：gateway/auth 启动时从环境变量加载 RSA 密钥（本版本不改代码，契约由脚本侧对齐）

逻辑（既有，保持不动）：
1. 读环境变量 RSA_PUBLIC_KEY / RSA_PRIVATE_KEY（或 @Value 注入）
2. decodePublicKey：Base64.getDecoder().decode(RSA_PUBLIC_KEY) → X509EncodedKeySpec → KeyFactory RSA 生成公钥
3. decodePrivateKey：Base64.getDecoder().decode(RSA_PRIVATE_KEY) → PKCS8EncodedKeySpec → KeyFactory RSA 生成私钥
4. 解析失败 → 抛启动异常，服务终止（防止无密钥运行）

本版本契约：env.json 注入值 = 脚本输出值 = 严格 DER 单行 Base64，两端一致，运行时代码零改动。
```

### 6.4 服务启动与健康检查验证（F-003）

```
功能：验证 4 个服务修复后全部可启动、可注册、可探活
执行流程：
1. 构建：mvn package（根目录），确认 deploy/ 下 4 个最终 jar 更新
2. 启动：按部署脚本（deploy/scripts/deploy-start-*.ps1/.sh）逐个启动，env.json 环境变量注入
3. 检查启动日志：
   - 无 "No spring.config.import property has been defined"
   - 无 "RSA 公钥解析失败"
   - 无其他致命错误（Nacos 连接、端口占用等）
4. 注册检查：Nacos 控制台可见 gateway/auth/biz/system 4 个实例（服务名 cloudoffice-*）
5. 健康检查：访问 /api/v1/{auth|biz|system}/health，状态为正常
6. 任一环节失败 → 按日志定位：bootstrap 依赖 / RSA 密钥 / 基础设施，修复后重新构建启动

失败排查顺序（PRD 流程图 G/J 分支）：
① 依赖问题（import-check）→ 6.1 方案检查
② 密钥问题（RSA 解析失败）→ 6.2 重新生成注入
③ 基础设施（Nacos/MariaDB/Redis 不可达）→ 先保障基础设施可用
```

### 6.5 接口回归闭环执行（F-004/F-005）

```
功能：服务可用后完成 v0.0.1 基线动态回归与既有契约复核
执行流程：
1. 前置确认：网关（9000）、auth-service（9100）可访问；MariaDB/Redis/Nacos 正常；admin/admin123 可用
2. 基线回归：python cso-api-test-v0.0.1.py http://localhost:9000
   - TC-001~045 全部动态执行，断言全部通过
   - 期望结果：退出码 0，PASS=45、FAIL=0
3. 契约复核：python cso-api-test-v0.2.5.py <项目根>
   - TC-046~051 保持通过，期望 PASS=26、FAIL=0（TC-046-3 健康检查为可选场景，SKIP 不视为失败）
4. 结果汇总：写入 docs/cso-v0.2.6/regression-api-test.md
   - 记录 TC-001~051 执行明细、通过/失败统计、根因闭环说明、签名确认
5. 失败处理：个别用例因测试数据冲突失败 → 记录并清理测试数据后重跑，直至全部通过
```

## 7. 业务规则与约束

| 类别 | 规则 | 来源/落点 |
| --- | --- | --- |
| 依赖引入 | 四个服务模块（gateway/auth/biz/system）必须实际引入 `spring-cloud-starter-bootstrap`；仅根 pom dependencyManagement 声明不生效，启动仍报 import-check | SAD 设计约束/ADR-014、PRD F-001、US-001 |
| 配置引导 | 引入后 bootstrap.yml 必须生效：Nacos discovery/config server-addr 可加载；服务启动日志不得出现 `No spring.config.import property has been defined` | PRD F-001/F-003、US-001 |
| 密钥格式契约 | `RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 统一为 DER 编码单行 Base64（无 PEM 头尾、无换行）；与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约严格一致 | SAD 安全约束/ADR-015、PRD F-002、US-002 |
| 密钥配对 | 公钥与私钥必须成对生成，公钥验签/私钥签名配对一致；密钥损坏/截断导致解析失败时服务启动失败，须重新生成注入 | PRD US-002 边界 |
| 密钥安全 | 私钥不得入库、不得写入日志；密钥仍通过环境变量/配置文件注入，禁止硬编码 | SAD 安全约束、PRD F-002 |
| 修复范围 | 仅允许构建/依赖配置、密钥生成脚本、环境配置、部署/回归验证流程变更；禁止改动接口层（Controller/DTO/响应体）、客户端 lib/ 运行时代码、数据库表结构、业务代码逻辑 | PRD F-005、验收标准 6 |
| 数据约束 | 本版本不新增数据表、不修改表结构；MariaDB 9 张表与 Redis 缓存数据结构不变 | PRD 数据需求 |
| 启动验证 | 4 个服务全部启动成功并注册到 Nacos；健康检查全部返回正常；启动日志无两项缺陷报错 | PRD F-003、验收标准 3 |
| 回归闭环 | TC-001~045 全部动态执行通过（PASS=45、FAIL=0），消除历史"待执行/环境阻塞"状态；TC-046~051 保持 PASS=26、FAIL=0 | PRD F-004/F-005、US-003/US-004 |
| 结果记录 | 回归结果必须记录到 v0.2.6 接口回归报告（docs/cso-v0.2.6/regression-api-test.md） | PRD F-004、验收标准 7 |
| 架构约束 | 修复不改变模块依赖关系（服务间仍只依赖 common），不改变服务注册与路由（/api/v1/{module}/**） | ADR-001、API v0.2.6 |

## 8. 业务数据流

### 8.1 RSA 密钥数据流（本版本修复链路）

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

### 8.2 配置引导数据流（F-001 修复后）

```
服务启动（gateway/auth/biz/system）
  → spring-cloud-starter-bootstrap（依赖引入后生效）
  → bootstrap.yml 先于 application.yml 加载
  → spring.cloud.nacos.discovery.server-addr / spring.cloud.nacos.config.server-addr 生效
  → Nacos 注册中心注册实例（服务名 cloudoffice-{module}）
  → 服务实例可被发现、被网关 lb 路由
```

### 8.3 回归验证数据流

```
服务可用（4 服务健康通过 + Nacos 注册）
  → cso-api-test-v0.0.1.py http://localhost:9000
  → 网关（9000）→ 认证服务（9100）→ MariaDB（租户/用户/角色权限）/ Redis（会话/状态/验证码）
  → TC-001~045 断言结果（PASS=45、FAIL=0）
  → cso-api-test-v0.2.5.py <项目根> → TC-046~051（PASS=26、FAIL=0）
  → docs/cso-v0.2.6/regression-api-test.md（回归报告闭环）
```

## 9. 数据结构定义

### 9.1 RSA 密钥格式契约（env.json 注入值）

| 字段 | 格式要求 | 说明 |
| --- | --- | --- |
| RSA_PUBLIC_KEY | DER 编码单行 Base64 | X.509 SubjectPublicKeyInfo 经 Base64 编码；无 `-----BEGIN PUBLIC KEY-----` 头尾、无换行；Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec` 可解码 |
| RSA_PRIVATE_KEY | DER 编码单行 Base64 | PKCS#8 PrivateKeyInfo 经 Base64 编码；无 `-----BEGIN PRIVATE KEY-----` 头尾、无换行；Java 端 `Base64.getDecoder()` + `PKCS8EncodedKeySpec` 可解码 |

> 反例（v0.0.1 历史缺陷，本版本消除）：PEM 文件整体 Base64（多行、含 BEGIN/END 标记与 \r\n），`Base64.getDecoder()` 严格解码报 `extra data at the end`。

### 9.2 bootstrap 引导配置（bootstrap.yml，既有资产）

| 配置项 | 说明 |
| --- | --- |
| spring.application.name | 服务名（cloudoffice-gateway/auth-service/biz-service/system-service），Nacos 注册名 |
| spring.cloud.nacos.discovery.server-addr | Nacos 注册中心地址 |
| spring.cloud.nacos.config.server-addr | Nacos 配置中心地址 |

### 9.3 环境配置结构（deploy/env.json，本版本仅密钥值变更）

| 字段 | 变更情况 | 说明 |
| --- | --- | --- |
| RSA_PUBLIC_KEY | 变更（PEM 整体 Base64 → DER 单行 Base64） | 与 Java 解码契约一致 |
| RSA_PRIVATE_KEY | 变更（PEM 整体 Base64 → DER 单行 Base64） | 与 Java 解码契约一致 |
| 数据库连接参数 | 不变 | MariaDB host/port/user/password 等 |
| Redis 连接参数 | 不变 | Redis host/port/password 等 |
| Nacos 连接参数 | 不变 | Nacos server-addr 等 |

### 9.4 回归验证数据结构（回归报告）

| 结构 | 关键字段 | 用途 |
| --- | --- | --- |
| 脚本执行记录 | 脚本名、执行命令、用例数、通过、失败、跳过、结果 | 回归报告脚本清单 |
| 用例明细 | 用例编号（TC-001~051）、断言项、结果 | 逐用例回归记录 |
| 根因闭环说明 | 缺陷项、根因、修复内容、验证结果 | 记录 T-02 两项缺陷闭环 |

## 10. 异常处理策略

| 异常类别 | 典型场景 | 处理方式 |
| --- | --- | --- |
| import-check 启动失败 | 模块未实际引入 bootstrap 依赖，启动报 `No spring.config.import property has been defined` | 检查 6.1 方案 A 模块 pom 实际引入；采用方案 B 时检查 import-check 是否关闭（PRD US-001 边界） |
| RSA 密钥解析失败 | 密钥仍为 PEM 整体 Base64、多行含换行、损坏/截断 | 按 6.2 重新执行 deploy-rsa-keygen.ps1 生成 DER 单行 Base64 并注入 env.json；确认无 BEGIN/END 与换行（US-002 边界） |
| 公钥私钥不配对 | 误混用非成对密钥，登录签发后网关验签失败（401） | 成对重新生成并注入，重启服务 |
| Nacos 不可达 | 服务启动报连接 Nacos 异常 | 先保障基础设施可用（Nacos 8848 已启动且网络可达）后重试（US-001 边界） |
| 基础设施依赖异常 | MariaDB/Redis 不可达导致服务启动失败 | 检查 MariaDB 3306、Redis 6379 状态，恢复后重启服务 |
| 构建失败 | 依赖引入错误导致 mvn package 失败 | 修正 pom 后重新构建；deploy 不落盘失败产物 |
| 回归脚本连接拒绝 | 服务未启动时执行 cso-api-test-v0.0.1.py 崩溃（退出码 1） | 回到 6.4 服务启动验证，确认网关/认证服务可访问后再执行（US-003 边界） |
| 回归用例数据冲突 | 个别用例因测试数据残留失败 | 记录失败用例，清理测试数据（用户/验证码缓存等）后重跑，直至全部通过（US-003 边界） |
| 既有契约意外回归 | 修复过程意外改动接口层/客户端代码 | 回退改动，重新构建验证，回归报告中说明（US-004 边界） |

## 11. 日志规范

| 业务路径 | 日志级别 | 日志内容要求 |
| --- | --- | --- |
| Maven 构建 | info | 依赖解析、模块编译打包结果；引入 bootstrap 依赖后构建成功标志 |
| 服务启动（bootstrap 引导） | info / error | bootstrap.yml 加载路径、Nacos server-addr；import-check 报错需完整记录（定位修复依据） |
| RSA 密钥加载 | info / error | 密钥加载结果（成功/失败）；失败原因（解码异常、格式问题）；**禁止输出密钥内容**（红线） |
| 服务注册 | info | 服务名、实例 ip/端口、注册成功标志 |
| 健康检查 | info | 服务名、状态、版本、时间戳 |
| 回归脚本执行 | info / error | 脚本名、执行命令、用例通过/失败统计；失败用例编号与断言详情 |
| 回归报告 | info | 结果汇总写入路径、闭环说明（T-02 两项缺陷修复记录） |

**红线**：日志禁止输出 RSA 私钥、Token 原文、密码等敏感信息（NFR-004）；密钥内容不得以任何形式（debug 级亦不可）写入日志。

## 12. 性能优化点

| 风险点 | 手段 |
| --- | --- |
| bootstrap 引导对启动时长的影响 | 仅引入依赖恢复既有 bootstrap.yml 加载机制，不新增配置扫描与额外 IO，启动时长与 v0.0.1 设计一致 |
| 密钥解析开销 | RsaKeyConfig 启动时一次性解析密钥并缓存为 Bean，运行期零重复解析；本版本不改代码，契约对齐后无额外开销 |
| 密钥重新生成频率 | 仅部署/密钥轮换时执行 deploy-rsa-keygen.ps1，脚本输出契约固定，无重复手工处理成本 |
| 回归脚本全量执行 | TC-001~045 动态回归为一次全量执行（版本级验证），脚本按顺序执行不引入额外并发负载；失败重跑仅针对失败用例清理后复跑 |
| 服务重启成本 | 修复完成后一次性重启 4 个服务完成验证，后续正常迭代不重复执行本版本修复流程 |

## 13. 单元测试策略

### 13.1 测试范围与工具

本版本为部署/配置缺陷修复版本，测试以**启动验证、契约校验与接口回归**为主：

- 构建验证：`mvn package` 构建通过，deploy/ 下 4 个服务 jar 更新落位；
- 密钥契约校验：deploy-rsa-keygen.ps1 输出值满足 DER 单行 Base64 契约（无 BEGIN/END、无换行、可严格 Base64 解码）；
- 启动验证：4 个服务按部署文档启动成功，启动日志无 import-check 与 RSA 解析报错，Nacos 注册可见；
- 健康检查：`/api/v1/{auth|biz|system}/health` 返回正常状态；
- 接口回归：cso-api-test-v0.0.1.py（TC-001~045）PASS=45、FAIL=0；cso-api-test-v0.2.5.py（TC-046~051）PASS=26、FAIL=0。

### 13.2 用例划分

| 被测对象 | 用例方向 | 验收关联 |
| --- | --- | --- |
| 根 pom / 模块 pom | 4 个服务模块实际引入 spring-cloud-starter-bootstrap；依赖解析无冲突 | 验收标准 1 / US-001 |
| bootstrap.yml 引导 | 启动日志无 `No spring.config.import property has been defined`；Nacos server-addr 加载 | 验收标准 1、3 / US-001 |
| deploy-rsa-keygen.ps1 输出 | 输出为 DER 单行 Base64：无 `-----BEGIN/END` 子串、无换行符、可被严格 Base64 解码 | 验收标准 2 / US-002 |
| RsaKeyConfig 解析 | 注入 DER 单行 Base64 后 gateway/auth 启动无 `RSA 公钥解析失败`；RS256 签名验签链路正常 | 验收标准 2、3 / US-002 |
| 服务启动 | 4 个服务全部启动成功、注册到 Nacos、健康检查正常 | 验收标准 3 / US-001 |
| 基线接口回归 | cso-api-test-v0.0.1.py 执行退出码 0，TC-001~045 全部 PASS | 验收标准 4 / US-003 |
| 既有契约复核 | cso-api-test-v0.2.5.py 执行 TC-046~051 保持 PASS=26、FAIL=0；git 变更清单无接口层与客户端运行时代码改动 | 验收标准 5、6 / US-004 |
| 回归报告 | docs/cso-v0.2.6/regression-api-test.md 输出，记录 TC-001~051 动态执行结果 | 验收标准 7 |

### 13.3 边界与异常用例

- 密钥含 `-----BEGIN` 头尾 → 契约校验失败，重新生成单行格式（US-002 边界）；
- 密钥多行/含 \r\n → 严格解码失败（extra data at the end），重生成后通过；
- 公钥私钥不配对 → 登录签发后网关验签 401，成对重生成；
- 模块未实际引入依赖（仅根 pom 声明）→ 启动仍报 import-check，按 6.1 修正；
- 回归环境数据残留（用户/验证码缓存）→ 清理后重跑直至全部通过（US-003 边界）；
- TC-046-3 健康检查（可选场景）→ 服务未启动时按脚本约定 SKIP，不视为失败（US-004 边界）；
- 修复过程意外改动接口层/客户端代码 → 回退，回归报告中说明（US-004 边界）。

### 13.4 覆盖目标

- 全部 7 条验收标准（PRD 第 7 章）均有对应校验用例；
- 两项缺陷（T-02：bootstrap 依赖缺失、RSA 密钥格式契约不匹配）闭环验证全覆盖；
- 回归结果记录至 v0.2.6 版本测试用例文档与接口回归报告，全部通过方可交付。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->

---

# 版本 v0.2.7：部署脚本体系重构与仓库清洁度治理（2026-08-10）

**版本号**：v0.2.7
**日期**：2026-08-10
**编写人**：TL

> 说明：LLD 聚焦整体业务逻辑的详细设计（模块划分、业务流程、核心业务逻辑、业务规则等）；接口（API）的详细设计由 API 设计文档单独负责，LLD 中不重复编写接口定义、请求/响应参数等内容。本版本为部署脚本体系重构与仓库清洁度治理版本，不新增后端业务接口，设计对象为 `deploy/scripts` 脚本体系（.ps1/.sh 双平台）与 `.gitignore` 治理方案。

## 1. 模块概述

v0.2.7 聚焦**部署运维自动化**与**仓库整洁度治理**两大目标，全部改动集中在部署资产层（deploy/scripts 与项目根目录 .gitignore），不涉及后端架构、接口契约与数据库结构变更。

本版本模块划分如下：

| 模块 | 脚本/文件 | 职责 |
| --- | --- | --- |
| 配置加载模块 | load-env.ps1 / load-env.sh | 从 `deploy/env.json` 统一加载环境配置为会话环境变量，是所有脚本的前置依赖 |
| 环境可用性检查模块 | deploy-check-env.ps1 / deploy-check-env.sh | 检查 JDK/MariaDB/Redis/Nacos 四类环境是否已安装且可达，并输出运行状态 |
| 基础设施运行状态检查与一键启动模块 | deploy-start-services.ps1 / deploy-start-services.sh | 检测 MariaDB/Redis/Nacos 是否运行，对未运行的服务按序自动启动并探测确认 |
| 后端服务按序一键启动模块 | deploy-start-all.ps1 / deploy-start-all.sh | 校验 jar 包与关键环境变量后，按 gateway→auth→biz→system 顺序一键启动全部 Java 后台服务 |
| 单服务启动模块 | deploy-start-gateway.ps1/.sh、deploy-start-auth.ps1/.sh、deploy-start-biz.ps1/.sh、deploy-start-system.ps1/.sh | 单独启动某一个后端服务，行为与一键启动对应服务逻辑一致 |
| RSA 密钥生成模块 | deploy-rsa-keygen.ps1 / deploy-rsa-keygen.sh | 生成 RSA 2048 密钥对，输出 DER 编码单行 Base64（公钥 X.509 / 私钥 PKCS#8，契约 ADR-015） |
| 仓库治理模块 | 项目根目录 .gitignore | 排除生成、测试、调试过程中的临时文件与中间文件，保持仓库整洁可审计 |

模块协作关系：`load-env` 是全部脚本的统一入口前置；`deploy-check-env` 给出可用性与运行状态结论；`deploy-start-services` 依据运行状态拉起基础设施；`deploy-start-all` 在基础设施就绪后按序拉起后端服务；单服务启动脚本与 `deploy-start-all` 中对应服务启动逻辑复用同一套契约。

## 2. 模块划分与职责

### 2.1 模块依赖关系

```mermaid
flowchart TD
    EVN["deploy/env.json<br/>（唯一配置源）"]
    LOAD["load-env.ps1 / .sh<br/>（统一配置加载）"]
    CE["deploy-check-env<br/>（可用性 + 运行状态检查）"]
    SS["deploy-start-services<br/>（基础设施一键启动）"]
    SA["deploy-start-all<br/>（后端服务按序一键启动）"]
    SG["deploy-start-gateway/auth/biz/system<br/>（单服务启动）"]
    RK["deploy-rsa-keygen<br/>（RSA 密钥生成）"]
    GI[".gitignore<br/>（仓库治理）"]

    EVN --> LOAD
    LOAD --> CE
    LOAD --> SS
    LOAD --> SA
    LOAD --> SG
    RK --> EVN
    CE -->|"运行状态结论"| SS
    SS -->|"基础设施就绪"| SA
    SA -->|"复用启动逻辑"| SG
```

### 2.2 各模块职责边界

| 模块 | 输入 | 处理 | 输出 | 边界说明 |
| --- | --- | --- | --- | --- |
| load-env | deploy/env.json | 解析 JSON 键值对 → 设置会话环境变量；缺失/关键项缺失时报错 | 环境变量集合 | 只负责加载，不执行检测与启动；不得硬编码任何地址/凭据 |
| deploy-check-env | load-env 后的环境变量 | 四类环境可用性检测 + 运行状态检测 | 通过/警告/失败分级汇总 + 退出码 | 只检查不启动；运行状态供 start-services 使用 |
| deploy-start-services | load-env 后的环境变量 | 检测运行状态 → 按序启动未运行的基础设施 → 探测确认 | 各服务状态汇总 + 退出码 | 只启动基础设施（MariaDB/Redis/Nacos），不启动后端服务；JDK 不启动 |
| deploy-start-all | load-env 后的环境变量 + 4 个 jar 包 | 前置校验 → 按序启动 4 个服务 → 逐个健康确认 | 启动结果与健康状态汇总 + 退出码 | 假设基础设施已就绪（可由 start-services 先行拉起）；失败即停 |
| deploy-start-{svc} | load-env 后的环境变量 + 对应 jar 包 | 校验本服务关键变量与 jar → 启动 | 单服务启动结果 + 退出码 | 与 start-all 对应服务逻辑一致，供按需单独启动 |
| deploy-rsa-keygen | openssl / .NET 加密库（平台自带） | 生成 RSA 2048 → 输出 DER 单行 Base64 | RSA_PUBLIC_KEY / RSA_PRIVATE_KEY | 不读取 env.json，输出供手工注入 env.json（配置驱动由 load-env 侧保障） |
| .gitignore | 项目文件清单 | 识别临时/中间文件 → 分区补充规则 → git status 验证 | 忽略规则 | 不得误伤源码、文档、模板与配置模板（env.example.json、.gitkeep） |

## 3. 类图

脚本体系非面向对象实现，此处以类图表达各脚本模块的职责对象及其交互关系（脚本视为"执行对象"，方法视为关键处理函数）。

```mermaid
classDiagram
    class EnvLoader {
        +load() boolean
        +validateRequired(keys) string[]
        -parseJson(file) map
        -setEnvVar(key, value)
    }
    class CheckEnv {
        +checkAll() Summary
        -checkJdk() CheckResult
        -checkMariaDB() CheckResult
        -checkRedis() CheckResult
        -checkNacos() CheckResult
        -checkRunningStatus() StatusResult
    }
    class StartServices {
        +startAll() Summary
        -startMariaDB() StartResult
        -startRedis() StartResult
        -startNacos() StartResult
        -probeConfirm(target) boolean
    }
    class StartAll {
        +startAllBackend() Summary
        -validateJars() string[]
        -validateEnv() string[]
        -startService(name, port) StartResult
        -healthConfirm(name, port) boolean
    }
    class StartSingle {
        +start(name) StartResult
        -validateSingle(name) string[]
        -runJava(jar, opts) pid
    }
    class RsaKeygen {
        +generate(platform) KeyPair
        -toDerSingleLine(der) string
        -printResult(pub, priv)
    }
    class OutputUtil {
        +pass(msg)
        +warn(msg)
        +fail(msg)
        +summary(pass, warn, fail)
        +exitCode(failCount, warnCount) int
    }
    class MaskUtil {
        +maskPassword(cmd) string
    }

    CheckEnv --> EnvLoader : 依赖
    StartServices --> EnvLoader : 依赖
    StartAll --> EnvLoader : 依赖
    StartSingle --> EnvLoader : 依赖
    CheckEnv --> OutputUtil : 输出分级
    StartServices --> OutputUtil : 输出分级
    StartAll --> OutputUtil : 输出分级
    StartSingle --> OutputUtil : 输出分级
    StartServices --> MaskUtil : 口令掩码
    StartAll --> MaskUtil : 口令掩码
    StartAll --> StartSingle : 复用单服务启动逻辑
```

## 4. 核心业务流程时序图

### 4.1 环境可用性检查流程（deploy-check-env）

```mermaid
sequenceDiagram
    participant O as 运维人员
    participant CE as deploy-check-env
    participant LE as load-env
    participant EVN as env.json
    participant JDK as JDK 环境
    participant MDB as MariaDB
    participant RDS as Redis
    participant NCS as Nacos

    O->>CE: 执行 deploy-check-env.ps1/.sh
    CE->>LE: 加载 env.json 并校验关键配置
    LE->>EVN: 读取配置
    EVN-->>LE: 返回键值对
    LE-->>CE: 配置加载完成（缺失则报错退出非零）
    CE->>JDK: 检查 java 命令 / JAVA_HOME / 版本 21
    JDK-->>CE: 可用性结果（通过/失败）
    CE->>MDB: 三重检测 + SELECT 1
    MDB-->>CE: 可用性结果
    CE->>RDS: 三重检测 + redis-cli ping
    RDS-->>CE: 可用性结果
    CE->>NCS: NACOS_HOME/startup 脚本 + HTTP 探测
    NCS-->>CE: 可用性结果（未启动计警告）
    CE->>CE: 运行状态检测（进程/服务/TCP/HTTP）
    CE-->>O: 输出通过/警告/失败汇总 + 退出码
```

### 4.2 基础设施一键启动流程（deploy-start-services）

```mermaid
sequenceDiagram
    participant O as 运维人员
    participant SS as deploy-start-services
    participant LE as load-env
    participant MDB as MariaDB
    participant RDS as Redis
    participant NCS as Nacos

    O->>SS: 执行 deploy-start-services.ps1/.sh
    SS->>LE: 加载 env.json 并校验关键配置
    LE-->>SS: 配置加载完成
    SS->>SS: 检测 MariaDB/Redis/Nacos 运行状态
    alt MariaDB 未运行且已安装
        SS->>MDB: 启动（系统服务优先→可执行文件）
        SS->>MDB: 再次探测确认（进程/TCP/SELECT 1）
        MDB-->>SS: 确认结果
    end
    alt Redis 未运行且已安装
        SS->>RDS: 启动（系统服务优先→redis-server）
        SS->>RDS: 再次探测确认（进程/TCP/ping）
        RDS-->>SS: 确认结果
    end
    alt Nacos 未运行且已安装
        SS->>NCS: 执行 NACOS_HOME/bin/startup.cmd/.sh
        SS->>NCS: 再次 HTTP 探测确认
        NCS-->>SS: 确认结果
    end
    SS-->>O: 输出各服务状态汇总 + 退出码
```

### 4.3 后端服务按序一键启动流程（deploy-start-all）

```mermaid
sequenceDiagram
    participant O as 运维人员
    participant SA as deploy-start-all
    participant LE as load-env
    participant G as gateway(:9000)
    participant A as auth(:9100)
    participant B as biz(:9200)
    participant S as system(:9400)

    O->>SA: 执行 deploy-start-all.ps1/.sh
    SA->>LE: 加载 env.json
    LE-->>SA: 配置加载完成
    SA->>SA: 校验 4 个 jar 包存在
    SA->>SA: 校验关键环境变量（NACOS_ADDR/RSA 密钥/DB_PASSWORD）
    alt 校验不通过
        SA-->>O: 输出缺失项与处理提示，退出非零
    else 校验通过
        SA->>G: 启动 gateway（java -jar）
        SA->>G: 健康确认（端口/HTTP）
        G-->>SA: gateway 健康
        SA->>A: 启动 auth
        SA->>A: 健康确认
        A-->>SA: auth 健康
        SA->>B: 启动 biz
        SA->>B: 健康确认
        B-->>SA: biz 健康
        SA->>S: 启动 system
        SA->>S: 健康确认
        S-->>SA: system 健康
        SA-->>O: 输出 4 服务启动结果与健康状态汇总，退出 0
    end
```

## 5. 状态图

### 5.1 基础设施/服务运行状态机

```mermaid
stateDiagram-v2
    [*] --> 未安装: 检测命令/服务/进程均未命中
    未安装 --> [*]: 不可启动，输出"未安装，请先安装"
    [*] --> 已安装未运行: 安装检测命中但运行探测失败
    已安装未运行 --> 启动中: start-services 发起启动
    启动中 --> 运行中: 启动后探测确认成功
    启动中 --> 启动失败: 启动超时/命令失败
    启动失败 --> 启动中: 重试（按脚本约定次数）
    运行中 --> 运行中: 一键启动时检测已运行，跳过启动（幂等）
    运行中 --> 健康: start-all 健康确认通过
    健康 --> [*]: 输出汇总
```

### 5.2 脚本执行状态机

```mermaid
stateDiagram-v2
    [*] --> 加载配置: 执行脚本
    加载配置 --> 校验关键配置: load-env 成功
    加载配置 --> 配置缺失: env.json 缺失/关键项缺失
    配置缺失 --> [*]: 输出错误提示，退出非零
    校验关键配置 --> 执行检查/启动: 校验通过
    执行检查/启动 --> 输出汇总: 全部步骤完成
    执行检查/启动 --> 失败即停: 关键步骤失败（start-all 默认策略）
    失败即停 --> [*]: 输出错误提示，退出非零
    输出汇总 --> [*]: 存在失败项退出非零，否则退出 0
```

## 6. 核心业务逻辑

### 6.1 配置加载逻辑（load-env）

```text
function load-env():
    envJsonPath = $ProjectDir/env.json 或 $PROJECT_DIR/env.json
    if envJsonPath 不存在:
        输出错误："未找到 env.json，请复制 env.example.json 为 env.json 并填写配置"
        exit 1
    envMap = 解析 envJsonPath（PowerShell: ConvertFrom-Json；Bash: python/jq 或 grep 解析）
    for key, value in envMap:
        设置会话环境变量 key = value
    validateRequired(["NACOS_ADDR", "NACOS_HOME", "DB_HOST", "DB_PORT",
                      "DB_USERNAME", "DB_PASSWORD", "REDIS_HOST", "REDIS_PORT"])
    if 缺失项 nonEmpty:
        逐个列出缺失项，输出错误提示
        exit 1
    return 0
```

### 6.2 可用性检查逻辑（deploy-check-env）

```text
function checkAll():
    results = []
    results.append(checkJdk())      # java 命令可执行 && JAVA_HOME 有效 && 版本包含 "21"
    results.append(checkMariaDB())  # 三重检测命中任一 → 已安装；SELECT 1 验证连通
    results.append(checkRedis())    # 三重检测命中任一 → 已安装；redis-cli ping = PONG
    results.append(checkNacos())    # NACOS_HOME/bin/startup.cmd|sh 存在 → 已安装；HTTP 探测含 "Nacos"
    running = checkRunningStatus()  # 进程/系统服务/TCP/HTTP 运行状态
    汇总输出：通过/警告/失败分级 + 运行状态列
    按 6.5 退出码约定返回
```

三重检测（MariaDB/Redis）命中规则：命令可执行（mariadb/mysql/mysqld/mariadbd 或 redis-cli/redis-server）→ 已安装；系统服务（DB_SERVICE_NAME/REDIS_SERVICE_NAME，逗号分隔多值）存在 → 已安装；进程（DB_PROCESS_NAME/REDIS_PROCESS_NAME，逗号分隔多值）存在 → 已安装；任一命中即通过安装检测。

Nacos 可用性特例：已安装但 HTTP 探测失败 → 计"警告（未运行）"，不误判为未安装，与运行状态检测衔接。

### 6.3 运行状态检测逻辑

```text
function checkRunningStatus():
    JDK: 复用 checkJdk 结论，可用即视为就绪（无启动概念）
    MariaDB: DB_PROCESS_NAME 进程存在 || DB_SERVICE_NAME 服务 Running || TCP:3306 可达 → 运行中
    Redis:   REDIS_PROCESS_NAME 进程存在 || REDIS_SERVICE_NAME 服务 Running || TCP:6379 可达 → 运行中
    Nacos:   HTTP http://NACOS_ADDR/nacos/ 返回含 "Nacos" → 运行中
             否则检测 java 进程命令行含 nacos 关键字 → 运行中（辅助）
    return 各服务状态：运行中 / 未运行 / 未安装
```

### 6.4 基础设施一键启动逻辑（deploy-start-services）

```text
function startAll():
    load-env()
    对 MariaDB/Redis/Nacos 分别检测运行状态
    未安装 → 输出"未安装，请先安装"，计入失败，不尝试启动
    运行中 → 跳过（幂等），输出"已运行"
    未运行 → 按启动顺序执行：
        MariaDB: Start-Service $DB_SERVICE_NAME（Windows）优先，
                 systemctl start（Linux）优先，否则 Start-Process mysqld/mariadbd / 后台启动
        Redis:   Start-Service / systemctl 优先，否则 redis-server（后台）
        Nacos:   执行 NACOS_HOME/bin/startup.cmd（Windows，standalone）
                 或 bash NACOS_HOME/bin/startup.sh（Linux）
    每次启动后再次探测确认（进程/TCP/ping/HTTP），确认成功输出"通过"
    启动超时或失败输出"警告/失败"并给出处理建议，不得报假成功
    输出各服务状态汇总，按退出码约定返回
```

启动顺序固定：MariaDB → Redis → Nacos（数据库与缓存先于注册中心，避免服务注册依赖缺失）。

### 6.5 后端服务按序一键启动逻辑（deploy-start-all）

```text
function startAllBackend():
    load-env()
    missingJars = 校验 4 个 jar 存在（deploy/cloudoffice-gateway.jar 等）
    missingVars = 校验关键变量（NACOS_ADDR、RSA_PUBLIC_KEY、RSA_PRIVATE_KEY、DB_PASSWORD 等）
    if missingJars 或 missingVars 非空:
        输出缺失项与处理提示，exit 1（不启动任何服务）
    for svc in [gateway(9000), auth(9100), biz(9200), system(9400)]:
        startService(svc): java -Xms256m -Xmx512m -jar <jar>
            Windows: Start-Process 独立窗口/后台；Linux: nohup/后台，记录 PID 或日志文件
        if not healthConfirm(svc, port):
            输出错误提示，停止后续启动，exit 1
    if 全部健康: 输出 4 服务启动结果与健康状态汇总，exit 0
```

健康确认方式：HTTP 探测（如经网关 `http://localhost:9000/api/v1/{auth|biz|system}/health`）或各服务端口探测；按等待重试次数/超时重试，仍失败则失败即停。

### 6.6 RSA 密钥生成逻辑（deploy-rsa-keygen）

```text
function generate():
    keyPair = 生成 RSA 2048（Windows: System.Security.Cryptography.RSA；Linux: openssl genrsa 2048）
    公钥 = DER 编码 X.509 SubjectPublicKeyInfo，转单行 Base64（无 PEM 头尾、无换行）
    私钥 = DER 编码 PKCS#8 PrivateKeyInfo，转单行 Base64（无 PEM 头尾、无换行）
    输出：
        RSA_PUBLIC_KEY=<单行 Base64>
        RSA_PRIVATE_KEY=<单行 Base64>
    契约自校验：输出不含 "-----BEGIN"，不含换行，可被严格 Base64 解码
    （.sh 与 .ps1 输出格式完全一致，符合 ADR-015）
```

### 6.7 输出分级与退出码约定

```text
输出分级：
    [通过] <信息>   （绿色，成功）
    [警告] <信息>   （黄色，可继续，如 Nacos 已安装未运行）
    [失败] <信息>   （红色，处理建议 + 计入失败汇总）
    汇总行：通过 N 项 / 警告 M 项 / 失败 K 项

退出码约定：
    failCount == 0 → exit 0（全部通过；存在警告但无失败按约定 exit 0 并提示警告）
    failCount > 0  → exit 1（存在失败项）
    关键步骤失败（env.json 缺失、校验不通过、启动失败即停）→ exit 1
```

### 6.8 .gitignore 治理逻辑

```text
1. 整体检查项目根目录文件与子目录，识别生成、测试、调试过程文件：
   - JVM/应用调试产物：*.hprof、堆转储、hs_err_pid*.log、dump 目录
   - 测试产物与缓存：__pycache__/.pytest_cache（已有）、surefire-reports、
     接口测试中间文件（token 缓存、临时报告）
   - 构建过程中间产物：.flattened-pom.xml、*.lastUpdated、maven-status/、
     dependency-reduced-pom.xml 等
   - 工具残留：抓包/API 调试会话文件（*.saz、*.chls、*.har、会话缓存等）
2. 按现有 .gitignore 分区风格新增规则（带路径前缀或精确模式）
3. 治理后执行 git status 验证：临时/中间文件不再出现在待提交清单
4. 复核：不误伤 env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档
```

## 7. 业务规则与约束

| 编号 | 规则/约束 | 说明 |
| --- | --- | --- |
| R-01 | 配置驱动 | 全部脚本统一经 load-env 从 deploy/env.json 加载配置；脚本内不得硬编码环境地址（如 192.168.1.100）与凭据 |
| R-02 | 退出码约定 | 全部通过退出 0；存在失败项退出非零（1）；关键步骤失败退出 1 |
| R-03 | 输出分级 | 通过（绿）/警告（黄）/失败（红）三级前缀；汇总显示通过/警告/失败计数 |
| R-04 | 双平台对齐 | .ps1 与 .sh 同名脚本行为一致，可通过语法与契约自校验 |
| R-05 | RSA 密钥契约（ADR-015） | 密钥为 DER 编码单行 Base64（公钥 X.509 / 私钥 PKCS#8），无 PEM 头尾、无换行，与 Java 端 `Base64.getDecoder()` + `X509EncodedKeySpec`/`PKCS8EncodedKeySpec` 解码契约一致 |
| R-06 | 口令掩码 | DB_PASSWORD/REDIS_PASSWORD 不得明文打印，命令中口令以掩码（`****`）显示 |
| R-07 | 部署顺序 | 基础设施：MariaDB → Redis → Nacos；后端服务：gateway(9000) → auth(9100) → biz(9200) → system(9400) |
| R-08 | 结果可确认 | 基础设施启动后再次探测确认；后端服务启动后健康确认，不得报假成功 |
| R-09 | 失败即停 | start-all 默认策略：任一服务启动/健康失败即停止后续启动，输出明确错误提示 |
| R-10 | 幂等启动 | 已运行的服务跳过启动，直接确认并输出"已运行" |
| R-11 | JDK 无启动概念 | JDK 仅检查可用性（命令 + JAVA_HOME + 版本 21），不执行启动操作 |
| R-12 | 未安装不可启动 | 未安装的服务不得尝试启动，输出"未安装，请先安装"并计入失败 |
| R-13 | 弃用脚本清理 | 删除/弃用 deploy-env.ps1、deploy-env-template.ps1/.sh 等残留脚本，避免与 load-env 双份配置逻辑混淆；移除后同步检查引用关系 |
| R-14 | 前置检查对齐 | deploy-check-env 检查范围与"可用性检查 + 运行状态检查"对齐（F-002~F-006），移除无关检查项（如 Maven/Git 版本检查）或降为可选信息 |
| R-15 | 仓库治理不误伤 | .gitignore 新增规则不得误伤应入库文件（env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档） |
| R-16 | 版权头 | 脚本文件保留 SPDX-License-Identifier（Apache-2.0）与版权声明，简体中文注释 |

## 8. 业务数据流

### 8.1 脚本配置数据流

```mermaid
flowchart LR
    EJ["deploy/env.example.json<br/>（模板，入库）"] -->|"复制并填写"| EVN["deploy/env.json<br/>（本地配置，不入库）"]
    EVN -->|"load-env 解析"| ENV["会话环境变量<br/>NACOS_ADDR/NACOS_HOME/DB_*/REDIS_*/RSA_*"]
    ENV --> CE["deploy-check-env"]
    ENV --> SS["deploy-start-services"]
    ENV --> SA["deploy-start-all"]
    ENV --> SG["deploy-start-{svc}"]
    RK["deploy-rsa-keygen"] -->|"输出 DER 单行 Base64 密钥"| EVN
    CE -->|"运行状态结论"| SS
    SS -->|"基础设施就绪"| SA
    SA -->|"启动结果"| SUM["输出汇总（通过/警告/失败）"]
```

### 8.2 .gitignore 治理数据流

```text
项目文件清单 → 识别生成/测试/调试过程文件（JVM 调试产物、测试缓存、构建中间产物、工具残留）
           → 按分区新增忽略规则（带路径前缀/精确模式）
           → git status 验证（临时/中间文件消失）
           → 复核应入库文件未被误伤
```

## 9. 数据结构定义

### 9.1 env.json 关键配置项

| 配置项 | 类型 | 说明 | 使用脚本 |
| --- | --- | --- | --- |
| NACOS_ADDR | string | Nacos 地址 host:port | check-env / start-services / start-all / start-{svc} |
| NACOS_HOME | string | Nacos 安装目录（检测/启动脚本定位） | check-env / start-services |
| DB_HOST / DB_PORT | string / number | 数据库地址与端口 | check-env / start-all / start-{svc} |
| DB_USERNAME / DB_PASSWORD | string | 数据库账号口令（口令掩码） | check-env / start-all / start-{svc} |
| DB_USER | string | 数据库兼容账号项（biz 服务使用，与 DB_USERNAME 差异保持现状） | start-biz |
| DB_SERVICE_NAME / DB_PROCESS_NAME | string | 数据库系统服务/进程名（逗号分隔多值） | check-env / start-services |
| REDIS_HOST / REDIS_PORT | string / number | Redis 地址与端口 | check-env / start-services |
| REDIS_PASSWORD | string | Redis 口令（掩码，客户端支持时使用） | check-env / start-services |
| REDIS_DATABASE | number | Redis 数据库索引 | check-env |
| REDIS_SERVICE_NAME / REDIS_PROCESS_NAME | string | Redis 系统服务/进程名（逗号分隔多值） | check-env / start-services |
| RSA_PRIVATE_KEY / RSA_PUBLIC_KEY | string | DER 编码单行 Base64 密钥（ADR-015） | start-all / start-{gateway,auth} |
| VERIFICATION_CODE_* / PASSWORD_MIN_LENGTH 等 | string/number | 应用参数（脚本不改写） | 不直接使用 |

### 9.2 脚本内部结构

| 结构 | 字段 | 说明 |
| --- | --- | --- |
| CheckResult | name / installed / reachable / detail | 单项可用性检查结果（名称、是否安装、是否可达、明细） |
| StatusResult | name / status | 运行状态结果（运行中/未运行/未安装） |
| StartResult | name / started / confirmed / detail | 启动结果（服务名、是否启动、是否确认、明细） |
| Summary | pass / warn / fail / items | 汇总（通过/警告/失败计数与明细项） |

## 10. 异常处理策略

| 异常场景 | 分类 | 处理方式 | 退出码 |
| --- | --- | --- | --- |
| env.json 不存在 | 配置异常 | 输出错误提示（复制 env.example.json 并填写配置） | 1 |
| 关键配置项缺失 | 配置异常 | 逐个列出缺失项，输出处理提示 | 1 |
| 命令不存在（java/mysql/redis-cli 等） | 环境缺失 | 输出"失败"并给出安装/配置建议（如安装 JDK 21） | 1 |
| JDK 版本非 21 | 环境不符 | 输出"失败"并提示安装 JDK 21 | 1 |
| MariaDB 已安装但 SELECT 1 失败 | 连通异常 | 输出"失败"提示检查 DB_HOST/DB_PORT/DB_USERNAME/DB_PASSWORD | 1 |
| Redis 已安装但 ping 不通 | 连通异常 | 输出"失败"提示检查 REDIS_HOST/REDIS_PORT/REDIS_PASSWORD | 1 |
| Nacos 已安装但 HTTP 探测失败 | 未运行 | 输出"警告（未运行）"，与运行状态检测衔接 | 0（提示警告） |
| 服务启动超时/失败 | 启动异常 | 输出"警告/失败"并给出等待重试/手动检查建议，不报假成功 | 1 |
| 启动需要管理员权限 | 权限异常 | 输出权限提示，指导以管理员身份执行 | 1 |
| 端口被占用（9000/9100/9200/9400） | 运行冲突 | 提示检查端口占用并指导处理 | 1 |
| 服务未安装 | 环境缺失 | 不尝试启动，输出"未安装，请先安装"并计入失败 | 1 |
| jar 包缺失 / 关键变量缺失 | 前置校验失败 | 输出缺失项与处理提示，不启动任何服务 | 1 |
| 后端服务健康确认失败 | 启动异常 | 重试（约定次数/超时）后仍失败 → 失败即停，输出错误提示 | 1 |

## 11. 日志规范

| 输出类型 | 格式 | 级别说明 |
| --- | --- | --- |
| 成功 | `[通过] <信息>`（绿色） | 检查/启动/确认成功 |
| 警告 | `[警告] <信息>`（黄色） | 可继续但需关注（如 Nacos 已安装未运行、启动超时） |
| 失败 | `[失败] <信息>`（红色，含处理建议） | 检查失败/启动失败/校验失败 |
| 汇总 | `通过 N 项 / 警告 M 项 / 失败 K 项` | 脚本末尾统一输出 |
| 启动确认 | `[启动] <服务名> :<端口> ...` | start-all 每服务启动与健康确认路径 |

日志纪律：口令与私钥一律掩码/不输出（DB_PASSWORD、REDIS_PASSWORD、RSA_PRIVATE_KEY 明文禁止出现在输出）；关键路径（load-env 加载、每项检查、每服务启动与健康确认、退出码）必须有输出；颜色输出在非交互终端自动降级为纯文本（可配置开关）。

## 12. 性能优化点

| 优化点 | 措施 |
| --- | --- |
| 健康确认等待 | 设置等待重试次数与单次等待超时（如 3 次 × 5 秒），避免无限等待；超时后失败即停 |
| 幂等启动 | 已运行的服务跳过启动直接确认，避免重复启动开销与端口冲突 |
| 检查顺序 | 先轻量命令检测（命令存在性）再重量级探测（SELECT 1/ping/HTTP），失败项及时短路 |
| 探测频率 | 探测间隔（如 1~2 秒）适度，避免启动等待期间高频空转 |
| 脚本开销 | 脚本仅做编排与探测，无额外进程驻留；启动的后台服务由系统管理（服务/进程），脚本退出不误杀 |
| 双平台复用 | 同一契约逻辑在 .ps1/.sh 内最小重复实现，避免维护两套不一致逻辑 |

## 13. 单元测试策略

### 13.1 测试范围与工具

本版本为部署脚本重构与仓库治理版本，测试以**脚本语法校验、契约自校验与行为验证**为主：

- 语法校验：全部 .ps1 通过 PowerShell 语法解析（`[System.Management.Automation.PSParser]` 或 `powershell -NoProfile -Command` 预检）；全部 .sh 通过 `bash -n` 校验；
- 契约自校验：deploy-rsa-keygen.ps1/.sh 输出满足 DER 单行 Base64 契约（无 BEGIN/END、无换行、可严格 Base64 解码、公钥私钥配对）；
- 行为验证：在部署环境依次执行 deploy-check-env → deploy-start-services → deploy-start-all，核对输出分级与退出码；
- 仓库治理验证：更新 .gitignore 后执行 `git status`，确认无临时/中间文件，且应入库文件未缺失。

### 13.2 用例划分

| 被测对象 | 用例方向 | 验收关联 |
| --- | --- | --- |
| load-env | env.json 存在时正确加载全部键值对；缺失时退出非零并提示 | 验收标准 1 / US-001 |
| load-env | 关键配置缺失时逐个列出缺失项并退出非零 | 验收标准 1 / US-001 |
| deploy-check-env | JDK 命令/JAVA_HOME/版本 21 检测；版本不符输出失败并提示 | 验收标准 2 / US-001 |
| deploy-check-env | MariaDB 三重检测 + SELECT 1；已安装不可连接输出失败 | 验收标准 2 / US-001 |
| deploy-check-env | Redis 三重检测 + ping；Nacos NACOS_HOME/startup + HTTP 探测 | 验收标准 2 / US-001 |
| deploy-check-env | Nacos 已安装未启动计警告（非未安装）；存在失败项退出非零 | 验收标准 2 / US-001 |
| deploy-start-services | MariaDB/Redis/Nacos 未运行时自动启动并探测确认，无假成功 | 验收标准 3 / US-002 |
| deploy-start-services | 启动方式优先级（系统服务→可执行文件）；未安装不尝试启动 | 验收标准 3 / US-002 |
| deploy-start-services | JDK 仅输出可用性结论，不执行启动 | 验收标准 3 / US-002 |
| deploy-start-all | 前置校验（jar 包 + 关键变量）失败时输出缺失项退出非零 | 验收标准 4 / US-003 |
| deploy-start-all | 按 gateway→auth→biz→system 顺序启动，逐服务健康确认后继续 | 验收标准 4 / US-003 |
| deploy-start-all | 任一步骤失败失败即停，输出错误提示；全部成功输出汇总退出 0 | 验收标准 4 / US-003 |
| 单服务启动 | deploy-start-gateway/auth/biz/system 各自独立可用，行为与一键一致 | 验收标准 5 / US-003 |
| deploy-rsa-keygen | .ps1/.sh 输出契约一致（DER 单行 Base64），与 Java 端解码契约一致 | 验收标准 6 / US-004 |
| 弃用脚本清理 | deploy-env.ps1/deploy-env-template.ps1/.sh 已移除或明确弃用，引用关系同步更新 | 验收标准 6 / US-004 |
| 输出与退出码 | 双平台输出分级（通过/警告/失败）与退出码约定一致 | 验收标准 7 / US-004 |
| .gitignore | JVM 调试产物/测试缓存/构建中间产物/工具残留规则覆盖，git status 无过程文件 | 验收标准 8 / US-005 |
| .gitignore | 不误伤 env.example.json、.gitkeep、pom.xml、bootstrap.yml、源码与文档 | 验收标准 8 / US-005 |

### 13.3 边界与异常用例

- env.json 为非法 JSON → load-env 解析失败退出非零并提示；
- 密码出现在命令中 → 日志以掩码显示，输出不含 DB_PASSWORD/REDIS_PASSWORD 明文；
- 密钥含 PEM 头尾/多行 → 契约自校验失败，重新生成单行格式（US-004 边界）；
- 公钥私钥不配对 → RSA 校验失败，成对重新生成；
- 服务启动超时 → 输出警告并给出重试/手动检查建议，不报假成功（US-002 边界）；
- 端口被占用 → 提示检查端口占用并指导处理（US-003 边界）；
- .gitignore 新增规则误伤应入库文件 → git status 复核发现后修正为路径前缀/精确模式（US-005 边界）；
- 已跟踪文件被新规则忽略 → 新规则只影响未跟踪文件；如需停止跟踪既有文件需 `git rm --cached` 并确认（US-005 边界）。

### 13.4 覆盖目标

- PRD 第 7 章 8 条验收标准均有对应校验用例；
- 5 个用户故事（US-001~US-005）的验收标准全覆盖；
- 双平台（Windows PowerShell / Linux Bash）脚本语法与契约自校验全部通过；
- `git status` 治理验证通过后方可交付。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->