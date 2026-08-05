# 接口设计文档（API）
**项目名称**：云漫智企（CloudStrollOffice，英文缩写 cso）
**版本号**：v0.0.1（初始化归档版本，对应实际业务版本 v0.1.6）
**日期**：2026-08-05
**编写人**：TL

## 1. 接口清单

> 统一前缀：`/api/v1/{module}`（module = auth / biz / system）。网关（端口 9000）为唯一对外入口，按路由前缀转发至各服务：`/api/v1/auth/**` → auth-service(9100)、`/api/v1/biz/**` → biz-service(9200)、`/api/v1/system/**` → system-service(9400)。

### 1.1 认证管理接口（AuthController，前缀 /api/v1/auth）

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- | --- |
| API-001 | 用户登录 | POST | /api/v1/auth/login | 多模式登录（4 种模式），签发双 Token，白名单 |
| API-002 | 用户注册 | POST | /api/v1/auth/register | 多模式注册（5 种模式），返回用户信息 + Token 对，白名单 |
| API-003 | 刷新 Token | POST | /api/v1/auth/refresh | Refresh Token 轮换，返回新双 Token，白名单 |
| API-004 | 用户登出 | POST | /api/v1/auth/logout | 登出幂等，Token 入黑名单并清除登录态 |
| API-005 | 强制踢人 | POST | /api/v1/auth/kickout | 管理员强制指定用户下线（指定端/所有端） |
| API-006 | 修改密码 | PUT | /api/v1/auth/password/change | 校验旧密码修改新密码，成功后清除所有登录态 |
| API-007 | 密码找回-发送验证码 | POST | /api/v1/auth/password/forgot/send-code | 向手机号/邮箱发送重置验证码，白名单 |
| API-008 | 密码找回-重置密码 | POST | /api/v1/auth/password/forgot/reset | 校验验证码后重置密码，成功后清除所有登录态，白名单 |
| API-009 | 修改手机号 | PUT | /api/v1/auth/phone/change | 原手机可用走短信验证、原手机停用走邮箱验证 |
| API-010 | 完善账号信息 | PUT | /api/v1/auth/account/settlement | 两步注册第二步，补全登录名/密码/手机号 |
| API-011 | 发送验证码 | POST | /api/v1/auth/verification-code/send | 短信/邮箱验证码，支持多种用途，白名单 |

### 1.2 用户管理接口（UserController，前缀 /api/v1/auth/users）

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- | --- |
| API-012 | 分页查询用户列表 | GET | /api/v1/auth/users | 按登录名/用户名模糊搜索，创建时间倒序 |
| API-013 | 获取用户详情 | GET | /api/v1/auth/users/{id} | 返回用户基本信息及角色编码列表 |
| API-014 | 更新用户信息 | PUT | /api/v1/auth/users/{id} | 更新用户名/手机号/邮箱（不含密码） |
| API-015 | 逻辑删除用户 | DELETE | /api/v1/auth/users/{id} | 标记 deleted=1，查询不可见 |
| API-016 | 分配用户角色 | PUT | /api/v1/auth/users/{id}/roles | 全量更新用户-角色关联（先删后插） |
| API-017 | 变更用户状态 | PUT | /api/v1/auth/users/{id}/status | 0 正常 / 1 停用 / 2 锁定 / 3 封禁 |

### 1.3 角色管理接口（RoleController，前缀 /api/v1/auth/roles）

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- | --- |
| API-018 | 分页查询角色列表 | GET | /api/v1/auth/roles | 按租户 ID 分页查询 |
| API-019 | 查询所有角色 | GET | /api/v1/auth/roles/list | 不分页查询租户下全部角色 |
| API-020 | 查询角色详情 | GET | /api/v1/auth/roles/{id} | 按 ID 查询角色详情 |
| API-021 | 创建角色 | POST | /api/v1/auth/roles | 需指定 tenantId、roleName、roleCode |
| API-022 | 更新角色 | PUT | /api/v1/auth/roles/{id} | 更新角色信息 |
| API-023 | 删除角色 | DELETE | /api/v1/auth/roles/{id} | 逻辑删除，已被分配则阻止删除 |
| API-024 | 分配角色权限 | PUT | /api/v1/auth/roles/{id}/permissions | 全量更新角色-权限关联（先删后插） |

### 1.4 权限管理接口（PermissionController，前缀 /api/v1/auth/permissions）

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- | --- |
| API-025 | 树形权限列表 | GET | /api/v1/auth/permissions/tree | 按 parent_id 组织树形权限结构 |
| API-026 | 所有权限列表 | GET | /api/v1/auth/permissions/list | 平铺权限列表 |
| API-027 | 权限详情 | GET | /api/v1/auth/permissions/{id} | 按 ID 查询权限 |
| API-028 | 创建权限 | POST | /api/v1/auth/permissions | perm_code 全局唯一，201 响应 |
| API-029 | 更新权限 | PUT | /api/v1/auth/permissions/{id} | 按 ID 更新权限 |
| API-030 | 删除权限 | DELETE | /api/v1/auth/permissions/{id} | 逻辑删除，已被角色关联则阻止删除 |

### 1.5 健康检查接口（HealthController，前缀 /api/v1/{module}/health）

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- | --- |
| API-031 | 认证服务健康检查 | GET | /api/v1/auth/health | 返回服务名/状态/版本/时间戳，白名单 |
| API-032 | 企业服务健康检查 | GET | /api/v1/biz/health | 返回服务名/状态/版本/时间戳 |
| API-033 | 系统服务健康检查 | GET | /api/v1/system/health | 返回服务名/状态/版本/时间戳 |

## 2. 接口版本策略

- **URL 版本路径**：接口统一使用 `/api/v1/{module}/{resource}` 前缀版本化，`v1` 表示第一版接口契约；后续不兼容变更升级为 `v2` 前缀，与旧版本共存。
- **版本协商方式**：不采用 Header/参数协商，以 URL 路径为主（服务端路由由网关按 `/api/v1/{module}/**` 分发）。
- **兼容策略**：同一大版本内保持向后兼容，新增字段不影响旧客户端；废弃接口至少保留一个版本周期后再下线；`v0.0.1` 为初始化归档版本，完整固化业务版本 v0.1.6 的全部接口契约，作为后续迭代基线。
- **文档工具**：认证服务集成 SpringDoc（OpenAPI 3），在线调试地址 `/swagger-ui.html`、OpenAPI 文档 `/v3/api-docs/**`（网关白名单）。

## 3. 认证鉴权机制

- **认证方式**：JWT RS256 双 Token。Access Token 有效期 2 小时，Refresh Token 有效期 7 天；RSA 2048 位密钥对，认证服务私钥签名、网关公钥验签。
- **Token 传递**：受保护接口请求头必须携带 `Authorization: Bearer <accessToken>`；刷新接口在请求体中传 Refresh Token。
- **网关统一认证（AuthFilter 9 步校验）**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → `tokenType=access` 校验 → Redis 黑名单检查 → 登录态校验 → 账号状态校验（封禁 403）→ 租户状态校验（禁用 403）→ 用户信息 Header 透传。
- **用户信息透传 Header**：网关校验通过后向下游服务透传以下请求头，业务服务据此识别当前用户（禁止业务服务自行解析 Token）：
  | Header 名称 | 说明 |
  | --- | --- |
  | X-User-Id | 当前登录用户 ID |
  | X-Tenant-Id | 当前租户 ID |
  | X-User-Name | 当前登录名 |
  | X-Client-Type | 客户端类型 |
  | X-Roles | 角色编码列表 |
  | X-Permissions | 权限编码列表 |
- **角色权限**：管理类接口（用户/角色/权限 CRUD、踢人）由管理员角色（SUPER_ADMIN/企业管理员）操作，非法访问返回 403（PERMISSION_DENIED）；业务服务按透传 Header 做租户隔离与数据过滤。
- **过期与刷新**：Access Token 过期后调用 `POST /api/v1/auth/refresh` 轮换；刷新成功后旧 Refresh Token 立即加入黑名单防重放；刷新失败（过期/无效/黑名单）需重新登录。
- **会话失效实时性**：登出、踢人、改密、重置密码、账号封禁、租户停用均实时写入 Redis 黑名单/状态缓存，网关校验即刻生效。
- **白名单路径**（无需 Token）：
  | 路径 | 说明 |
  | --- | --- |
  | POST /api/v1/auth/login | 登录 |
  | POST /api/v1/auth/register | 注册 |
  | POST /api/v1/auth/refresh | Token 刷新 |
  | POST /api/v1/auth/verification-code/send | 发送验证码 |
  | POST /api/v1/auth/password/forgot/send-code | 密码找回-发送验证码 |
  | POST /api/v1/auth/password/forgot/reset | 密码找回-重置密码 |
  | GET /api/v1/auth/health | 认证服务健康检查 |
  | /swagger-ui/**、/v3/api-docs/**、/webjars/**、/favicon.ico | 接口文档与静态资源 |

## 4. 通用错误码定义

> 统一响应体 `ApiResult<T>`：`code`（业务码）、`message`（提示）、`data`（数据）、`timestamp`（毫秒时间戳）。分页响应 `PageResult<T>`：`records`（列表）、`total`（总数）、`page`（页码）、`pageSize`（每页条数）。

### 4.1 基础 HTTP 错误码

| 错误码 | HTTP 状态码 | 说明 |
| --- | --- | --- |
| 200 | 200 | 操作成功 |
| 400 | 400 | 请求参数错误（BAD_REQUEST） |
| 401 | 401 | 未授权，请先登录（UNAUTHORIZED） |
| 403 | 403 | 权限不足（FORBIDDEN） |
| 404 | 404 | 资源不存在（NOT_FOUND） |
| 405 | 405 | 请求方法不支持（METHOD_NOT_ALLOWED） |
| 409 | 409 | 资源冲突（CONFLICT） |
| 429 | 429 | 请求频率过高（TOO_MANY_REQUESTS） |
| 500 | 500 | 系统繁忙，请稍后重试（INTERNAL_ERROR） |
| 503 | 503 | 服务暂不可用（SERVICE_UNAVAILABLE） |

### 4.2 认证授权错误码（AUTH-0001 ~ AUTH-0019）

| 业务错误码 | HTTP 状态码 | 说明 |
| --- | --- | --- |
| AUTH-0001 | 401 | 令牌已过期，请刷新令牌（TOKEN_EXPIRED） |
| AUTH-0002 | 401 | 令牌无效（TOKEN_INVALID） |
| AUTH-0003 | 401 | 令牌已被吊销（TOKEN_BLACKLISTED） |
| AUTH-0004 | 401 | 刷新令牌已过期，请重新登录（REFRESH_TOKEN_EXPIRED） |
| AUTH-0005 | 401 | 刷新令牌无效（REFRESH_TOKEN_INVALID） |
| AUTH-0006 | 403 | 账号已被禁用（ACCOUNT_DISABLED） |
| AUTH-0007 | 403 | 账号已被锁定（ACCOUNT_LOCKED） |
| AUTH-0008 | 403 | 账号已被封禁（ACCOUNT_BANNED） |
| AUTH-0009 | 403 | 账号已过期（ACCOUNT_EXPIRED） |
| AUTH-0010 | 401 | 用户名或密码错误（LOGIN_FAILED） |
| AUTH-0011 | 400 | 验证码错误（CAPTCHA_ERROR） |
| AUTH-0012 | 400 | 无效的客户端类型（CLIENT_TYPE_INVALID） |
| AUTH-0013 | 401 | 账号已在其他设备登录，您已被踢下线（SESSION_KICKED_OUT） |
| AUTH-0014 | 403 | 租户已被禁用（TENANT_DISABLED） |
| AUTH-0015 | 403 | 租户已过期（TENANT_EXPIRED） |
| AUTH-0016 | 403 | 权限不足（PERMISSION_DENIED） |
| AUTH-0017 | 404 | 角色不存在（ROLE_NOT_FOUND） |
| AUTH-0018 | 404 | 用户不存在（USER_NOT_FOUND） |
| AUTH-0019 | 400 | 验证码已过期（CAPTCHA_EXPIRED） |

### 4.3 密码/验证码/OAuth/手机号/模式错误码（AUTH-0020 ~ AUTH-0033）

| 业务错误码 | HTTP 状态码 | 说明 |
| --- | --- | --- |
| AUTH-0020 | 400 | 密码重置令牌无效（PASSWORD_RESET_TOKEN_INVALID） |
| AUTH-0021 | 400 | 密码重置令牌已过期（PASSWORD_RESET_TOKEN_EXPIRED） |
| AUTH-0022 | 400 | 原密码错误（OLD_PASSWORD_INCORRECT） |
| AUTH-0023 | 400 | 短信验证码无效（SMS_CODE_INVALID） |
| AUTH-0024 | 400 | 短信验证码已过期（SMS_CODE_EXPIRED） |
| AUTH-0025 | 429 | 验证码发送过于频繁（SMS_SEND_TOO_FREQUENT） |
| AUTH-0026 | 401 | 第三方登录失败（OAUTH_LOGIN_FAILED） |
| AUTH-0027 | 404 | 第三方账号未绑定（OAUTH_ACCOUNT_NOT_BOUND） |
| AUTH-0028 | 409 | 手机号已被其他账号绑定（PHONE_ALREADY_BOUND） |
| AUTH-0029 | 409 | 第三方账号已被其他用户绑定（OAUTH_ACCOUNT_ALREADY_BOUND） |
| AUTH-0030 | 403 | 需要邮箱验证（EMAIL_VERIFICATION_REQUIRED） |
| AUTH-0031 | 403 | 账号信息未完善，请先补充资料（ACCOUNT_NOT_SETTLED） |
| AUTH-0032 | 400 | 无效的注册模式（REGISTER_MODE_INVALID） |
| AUTH-0033 | 400 | 无效的登录模式（LOGIN_MODE_INVALID） |

## 5. 接口详细定义

### 5.1 用户登录（API-001）

**接口**：`POST /api/v1/auth/login`
**功能描述**：多模式登录。支持 4 种登录模式：用户名密码（USERNAME_PASSWORD）、手机验证码（PHONE_CODE）、手机+密码（PHONE_PASSWORD）、OAuth 第三方（OAUTH）。登录执行 13 步完整流程（参数校验 → 策略校验 → 租户/账号状态校验 → 会话管理（同端互斥/多端共存）→ 签发双 Token），成功返回 Token 对，失败记录登录日志。属于网关白名单。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| loginMode | string | 否 | Body | 登录模式，默认 USERNAME_PASSWORD；可选 USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH |
| loginName | string | 条件 | Body | 登录名 4-64 字符，USERNAME_PASSWORD/PHONE_PASSWORD 模式必填 |
| password | string | 条件 | Body | 密码 8-64 字符，USERNAME_PASSWORD/PHONE_PASSWORD 模式必填 |
| phone | string | 条件 | Body | 手机号，PHONE_CODE 模式必填 |
| smsCode | string | 条件 | Body | 短信验证码，PHONE_CODE 模式必填 |
| oauthProvider | string | 条件 | Body | OAuth 提供商（如 wechat），OAUTH 模式必填 |
| oauthCode | string | 条件 | Body | OAuth 授权码，OAUTH 模式必填 |
| tenantCode | string | 是 | Body | 租户编码，所有模式必填 |
| clientType | string | 是 | Body | 客户端类型：WINDOWS/UBUNTU/H5/ANDROID/IOS/WECHAT_MINI |

**请求示例**：
```json
{
  "loginMode": "USERNAME_PASSWORD",
  "loginName": "admin",
  "password": "admin123",
  "tenantCode": "default",
  "clientType": "WINDOWS"
}
```

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data.accessToken | string | Access Token（有效期 2 小时） |
| data.refreshToken | string | Refresh Token（有效期 7 天） |
| data.accessTokenExpireIn | long | Access Token 过期秒数 |
| data.refreshTokenExpireIn | long | Refresh Token 过期秒数 |
| data.tokenType | string | Token 类型，固定 Bearer |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9.xxx",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9.xxx",
    "accessTokenExpireIn": 7200,
    "refreshTokenExpireIn": 604800,
    "tokenType": "Bearer"
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 400 | 请求参数错误 |
| AUTH-0010 | 用户名或密码错误 |
| AUTH-0011 / AUTH-0019 | 验证码错误 / 验证码已过期 |
| AUTH-0012 | 无效的客户端类型 |
| AUTH-0006~0009 | 账号状态异常（禁用/锁定/封禁/过期） |
| AUTH-0014 / AUTH-0015 | 租户状态异常（禁用/过期） |
| AUTH-0026 / AUTH-0027 | OAuth 登录失败 / 第三方账号未绑定 |
| AUTH-0033 | 无效的登录模式 |
| AUTH-0031 | 账号信息未完善（两步注册需补全） |

**权限要求**：白名单，无需 Token。

### 5.2 用户注册（API-002）

**接口**：`POST /api/v1/auth/register`
**功能描述**：多模式注册。支持 5 种注册模式：用户名密码（USERNAME）、手机验证码（PHONE_CODE）、OAuth（OAUTH）、手机号设用户名（PHONE_SET_USERNAME）、OAuth 补全信息（OAUTH_SET_INFO）。注册成功分配默认角色并返回用户信息 + Token 对；两步注册账号状态为未完善（accountSettled=false），登录后需调用 API-010 补全。属于网关白名单。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| registerMode | string | 否 | Body | 注册模式，默认 USERNAME；可选 USERNAME/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO |
| loginName | string | 条件 | Body | 登录名 4-64 字符（仅字母数字下划线），USERNAME/PHONE_SET_USERNAME 模式必填 |
| password | string | 条件 | Body | 密码 8-64 字符，USERNAME/OAUTH_SET_INFO 模式必填 |
| userName | string | 否 | Body | 用户姓名，最长 50 字符 |
| phone | string | 条件 | Body | 手机号，PHONE_CODE/PHONE_SET_USERNAME 模式必填 |
| email | string | 条件 | Body | 邮箱，邮箱注册场景使用 |
| smsCode | string | 条件 | Body | 短信验证码，PHONE_CODE 模式必填 |
| oauthProvider | string | 条件 | Body | OAuth 提供商，OAUTH/OAUTH_SET_INFO 模式必填 |
| oauthCode | string | 条件 | Body | OAuth 授权码，OAUTH/OAUTH_SET_INFO 模式必填 |
| tenantCode | string | 是 | Body | 租户编码，所有模式必填 |

**请求示例**：
```json
{
  "registerMode": "USERNAME",
  "loginName": "newuser",
  "password": "password123",
  "userName": "张三",
  "tenantCode": "default"
}
```

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data.userId | long | 用户 ID |
| data.loginName | string | 登录名 |
| data.userName | string | 用户姓名 |
| data.accountSettled | boolean | 账号是否完善（false 需调用 API-010 补全） |
| data.tokenPair | object | Token 对（结构同 API-001 data） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": 1001,
    "loginName": "newuser",
    "userName": "张三",
    "accountSettled": true,
    "tokenPair": {
      "accessToken": "eyJhbGciOiJSUzI1NiJ9.xxx",
      "refreshToken": "eyJhbGciOiJSUzI1NiJ9.xxx",
      "accessTokenExpireIn": 7200,
      "refreshTokenExpireIn": 604800,
      "tokenType": "Bearer"
    }
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 400 | 请求参数错误（登录名格式/长度、密码策略） |
| 409 | 用户名在租户内已存在（唯一性冲突） |
| AUTH-0011 / AUTH-0019 | 验证码错误 / 验证码已过期 |
| AUTH-0028 | 手机号已被其他账号绑定 |
| AUTH-0029 | 第三方账号已被其他用户绑定 |
| AUTH-0032 | 无效的注册模式 |

**权限要求**：白名单，无需 Token。

### 5.3 刷新 Token（API-003）

**接口**：`POST /api/v1/auth/refresh`
**功能描述**：使用 Refresh Token 换发新的双 Token 对（轮换机制），旧 Refresh Token 立即加入黑名单防止重放攻击。属于网关白名单。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| refreshToken | string | 是 | Body | Refresh Token 字符串 |

**请求示例**：
```json
{
  "refreshToken": "eyJhbGciOiJSUzI1NiJ9.xxx"
}
```

**响应参数**：同 API-001 响应（新的双 Token 对）。

**响应示例**：
```json
{
  "code": 200,
  "message": "刷新成功",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9.xxx",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9.xxx",
    "accessTokenExpireIn": 7200,
    "refreshTokenExpireIn": 604800,
    "tokenType": "Bearer"
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0004 | 刷新令牌已过期，请重新登录 |
| AUTH-0005 | 刷新令牌无效 |
| AUTH-0003 | 刷新令牌已被吊销（黑名单） |

**权限要求**：白名单（刷新接口无需携带 Access Token）。

### 5.4 用户登出（API-004）

**接口**：`POST /api/v1/auth/logout`
**功能描述**：将当前 Access Token 加入黑名单并清除登录态，支持幂等（重复登出返回成功）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：无（当前用户从 Authorization 头提取）。

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 登出成功 |
| data | null | 无数据 |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "登出成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0002 | 令牌无效（Authorization 头缺失或格式错误） |

**权限要求**：需登录（非白名单）。

### 5.5 强制踢人（API-005）

**接口**：`POST /api/v1/auth/kickout`
**功能描述**：管理员强制指定用户下线。指定 clientType 踢指定端，不指定则踢所有端；目标用户后续请求被网关黑名单拦截返回 401。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | long | 是 | Body | 目标用户 ID |
| clientType | string | 否 | Body | 客户端类型；空则踢所有端 |

**请求示例**：
```json
{
  "userId": 1001,
  "clientType": "WINDOWS"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 400 | 请求参数错误（userId 为空） |
| AUTH-0016 | 权限不足（非管理员） |

**权限要求**：需登录，管理员角色操作。

### 5.6 修改密码（API-006）

**接口**：`PUT /api/v1/auth/password/change`
**功能描述**：当前登录用户修改自己的密码。校验旧密码正确性，新密码满足 8-64 位策略，修改成功后清除该用户所有登录态会话（需重新登录）。当前用户 ID 从网关透传 X-User-Id 头获取。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| oldPassword | string | 是 | Body | 旧密码 |
| newPassword | string | 是 | Body | 新密码 8-64 字符 |
| confirmPassword | string | 是 | Body | 确认新密码，需与新密码一致 |

**请求示例**：
```json
{
  "oldPassword": "oldPassword123",
  "newPassword": "newPassword456",
  "confirmPassword": "newPassword456"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 400 | 请求参数错误（新密码不符合 8-64 位策略、确认密码不一致） |
| AUTH-0022 | 原密码错误 |
| 401 | 未授权（缺少 X-User-Id 透传头） |

**权限要求**：需登录（非白名单）。

### 5.7 密码找回-发送验证码（API-007）

**接口**：`POST /api/v1/auth/password/forgot/send-code`
**功能描述**：通过手机短信或邮箱发送密码重置验证码。目标对应的账号需存在，否则返回用户不存在错误。验证码 6 位数字、5 分钟过期、60 秒频率限制。属于网关白名单。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| target | string | 是 | Body | 验证码接收目标（手机号或邮箱） |
| purpose | string | 是 | Body | 用途 RESET_PASSWORD |
| mode | string | 是 | Body | 发送方式 SMS / EMAIL |

**请求示例**：
```json
{
  "target": "13800138000",
  "purpose": "RESET_PASSWORD",
  "mode": "SMS"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0018 | 用户不存在（目标账号不存在） |
| AUTH-0025 | 验证码发送过于频繁（60 秒内重复发送） |

**权限要求**：白名单，无需 Token。

### 5.8 密码找回-重置密码（API-008）

**接口**：`POST /api/v1/auth/password/forgot/reset`
**功能描述**：通过验证码重置密码。校验验证码有效性（一次性）后更新密码（BCrypt 加密），并清除该用户所有登录态会话。属于网关白名单。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| mode | string | 是 | Body | 验证方式 EMAIL / SMS |
| target | string | 是 | Body | 验证目标（手机号或邮箱） |
| code | string | 是 | Body | 验证码 |
| newPassword | string | 是 | Body | 新密码 8-64 字符 |

**请求示例**：
```json
{
  "mode": "SMS",
  "target": "13800138000",
  "code": "123456",
  "newPassword": "newPassword456"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0011 | 验证码错误 |
| AUTH-0019 | 验证码已过期 |
| AUTH-0023 / AUTH-0024 | 短信验证码无效 / 已过期 |
| AUTH-0018 | 用户不存在 |
| 400 | 新密码不符合 8-64 位策略 |

**权限要求**：白名单，无需 Token。

### 5.9 修改手机号（API-009）

**接口**：`PUT /api/v1/auth/phone/change`
**功能描述**：当前登录用户更换绑定手机号。原手机可用：通过旧手机短信验证码验证后变更；原手机停用：通过已绑定邮箱验证码验证后变更。新手机号在租户内不可与其他用户重复。当前用户 ID 从 X-User-Id 头获取。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| newPhone | string | 是 | Body | 新手机号 |
| oldPhoneCode | string | 条件 | Body | 旧手机号验证码（已绑定手机号时必填） |
| newPhoneCode | string | 是 | Body | 新手机号验证码 |
| emailCode | string | 条件 | Body | 邮箱验证码（未绑定手机号、仅绑定邮箱时必填） |

**请求示例**：
```json
{
  "newPhone": "13900139000",
  "oldPhoneCode": "654321",
  "newPhoneCode": "123456"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0023 / AUTH-0024 | 验证码无效 / 已过期 |
| AUTH-0028 | 新手机号已被其他账号绑定 |
| 400 | 请求参数错误 |

**权限要求**：需登录（非白名单）。

### 5.10 完善账号信息（API-010）

**接口**：`PUT /api/v1/auth/account/settlement`
**功能描述**：两步注册第二步。用户在首次登录或信息不完整时补全账号信息（登录名、密码、手机号）。校验请求 userId 与当前登录用户（X-User-Id）一致，账号未完善时才可补全，补全后 account_settled=true。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | long | 是 | Body | 用户 ID（须与当前登录用户一致） |
| loginName | string | 否 | Body | 登录名 4-64 字符 |
| password | string | 否 | Body | 密码 8-64 字符 |
| phone | string | 否 | Body | 手机号 |
| smsCode | string | 否 | Body | 短信验证码 |

**请求示例**：
```json
{
  "userId": 1001,
  "loginName": "newuser",
  "password": "password123",
  "phone": "13800138000",
  "smsCode": "123456"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 400 | 请求参数错误 / 用户 ID 不匹配 |
| AUTH-0031 | 账号已完善，不可重复补全（或账号未完善需先补全） |
| AUTH-0028 | 手机号已被其他账号绑定 |

**权限要求**：需登录（非白名单）。

### 5.11 发送验证码（API-011）

**接口**：`POST /api/v1/auth/verification-code/send`
**功能描述**：向指定目标（手机号或邮箱）发送验证码，支持多种用途：注册（REGISTER）、登录（LOGIN）、重置密码（RESET_PASSWORD）、更换手机号（CHANGE_PHONE）。验证码 6 位数字、5 分钟过期、60 秒频率限制、一次性使用；开发环境支持模拟模式（VERIFICATION_CODE_MOCK=true）。属于网关白名单。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| target | string | 是 | Body | 验证码接收目标（手机号或邮箱） |
| purpose | string | 是 | Body | 用途 REGISTER / LOGIN / RESET_PASSWORD / CHANGE_PHONE |
| mode | string | 是 | Body | 发送方式 SMS / EMAIL |

**请求示例**：
```json
{
  "target": "13800138000",
  "purpose": "REGISTER",
  "mode": "SMS"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0025 | 验证码发送过于频繁（60 秒内同一目标同一用途） |
| 400 | 请求参数错误（target/purpose/mode 为空） |

**权限要求**：白名单，无需 Token。

### 5.12 分页查询用户列表（API-012）

**接口**：`GET /api/v1/auth/users`
**功能描述**：分页查询用户列表，支持按 login_name 和 user_name 模糊搜索，结果按创建时间降序排列。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| X-Tenant-Id | long | 是 | 租户 ID（网关透传） |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| page | int | 否 | Query | 页码从 1 开始，默认 1 |
| pageSize | int | 否 | Query | 每页条数，默认 10 |
| keyword | string | 否 | Query | 搜索关键词（登录名/用户名模糊匹配） |

**请求示例**：`GET /api/v1/auth/users?page=1&pageSize=10&keyword=张`

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data.records | array | 用户列表（UserEntity，不含密码） |
| data.total | long | 总条数 |
| data.page | int | 当前页码 |
| data.pageSize | int | 每页条数 |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1001,
        "tenantId": 1,
        "loginName": "admin",
        "userName": "张三",
        "phone": "13800138000",
        "email": "zhangsan@example.com",
        "status": 0,
        "accountSettled": true
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 10
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 401 | 未授权（Token 缺失/无效） |
| AUTH-0016 | 权限不足 |

**权限要求**：需登录，管理员角色操作。

### 5.13 获取用户详情（API-013）

**接口**：`GET /api/v1/auth/users/{id}`
**功能描述**：按 ID 查询用户详情，返回用户基本信息及角色编码列表，不返回密码。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 用户 ID |

**请求示例**：`GET /api/v1/auth/users/1001`

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功；404 用户不存在 |
| message | string | 提示信息 |
| data | object | 用户详情（UserEntity，不含密码） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1001,
    "tenantId": 1,
    "loginName": "admin",
    "userName": "张三",
    "phone": "13800138000",
    "email": "zhangsan@example.com",
    "status": 0,
    "accountSettled": true
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0018 | 用户不存在 |

**权限要求**：需登录，管理员角色操作。

### 5.14 更新用户信息（API-014）

**接口**：`PUT /api/v1/auth/users/{id}`
**功能描述**：更新用户基本信息（用户名、手机号、邮箱）。密码变更必须通过独立的密码修改接口（API-006）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 用户 ID |
| userName | string | 否 | Body | 用户姓名 |
| phone | string | 否 | Body | 手机号 |
| email | string | 否 | Body | 邮箱 |

**请求示例**：
```json
{
  "userName": "李四",
  "phone": "13700137000",
  "email": "lisi@example.com"
}
```

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | object | 更新后的用户信息（UserEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1001,
    "tenantId": 1,
    "loginName": "admin",
    "userName": "李四",
    "phone": "13700137000",
    "email": "lisi@example.com",
    "status": 0,
    "accountSettled": true
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0018 | 用户不存在 |
| AUTH-0028 | 手机号已被其他账号绑定 |

**权限要求**：需登录，管理员角色操作。

### 5.15 逻辑删除用户（API-015）

**接口**：`DELETE /api/v1/auth/users/{id}`
**功能描述**：将用户标记为已删除状态（deleted=1），已删除用户无法通过查询接口获取。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 用户 ID |

**请求示例**：`DELETE /api/v1/auth/users/1001`

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0018 | 用户不存在 |

**权限要求**：需登录，管理员角色操作。

### 5.16 分配用户角色（API-016）

**接口**：`PUT /api/v1/auth/users/{id}/roles`
**功能描述**：全量更新用户角色（先删后插）：先删除用户现有角色关联，再插入传入的角色 ID 列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 用户 ID |
| roleIds | array | 是 | Body | 角色 ID 列表 |

**请求示例**：
```json
{
  "roleIds": [101, 102]
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0017 | 角色不存在 |
| AUTH-0018 | 用户不存在 |

**权限要求**：需登录，管理员角色操作。

### 5.17 变更用户状态（API-017）

**接口**：`PUT /api/v1/auth/users/{id}/status`
**功能描述**：变更用户账号状态：0 恢复正常 / 1 停用 / 2 锁定（同步更新 Redis 缓存）/ 3 封禁（同步清除所有登录态会话）。封禁后网关校验账号状态缓存即时拦截。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 用户 ID |
| status | int | 是 | Body | 0-正常 / 1-停用 / 2-锁定 / 3-封禁（范围 0-3） |
| lockReason | string | 否 | Body | 锁定/封禁原因 |

**请求示例**：
```json
{
  "status": 3,
  "lockReason": "违规操作，封禁处理"
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 400 | 状态值超出 0-3 范围 |
| AUTH-0018 | 用户不存在 |

**权限要求**：需登录，管理员角色操作。

### 5.18 分页查询角色列表（API-018）

**接口**：`GET /api/v1/auth/roles`
**功能描述**：按租户 ID 分页查询角色列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| page | int | 否 | Query | 页码从 1 开始，默认 1 |
| pageSize | int | 否 | Query | 每页条数，默认 10 |
| tenantId | long | 是 | Query | 租户 ID |

**请求示例**：`GET /api/v1/auth/roles?page=1&pageSize=10&tenantId=1`

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data.records | array | 角色列表（RoleEntity） |
| data.total | long | 总条数 |
| data.page | int | 当前页码 |
| data.pageSize | int | 每页条数 |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 101,
        "tenantId": 1,
        "roleCode": "SUPER_ADMIN",
        "roleName": "超级管理员",
        "status": 1
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 10
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 401 | 未授权 |
| AUTH-0016 | 权限不足 |

**权限要求**：需登录，管理员角色操作。

### 5.19 查询所有角色（API-019）

**接口**：`GET /api/v1/auth/roles/list`
**功能描述**：按租户 ID 查询所有角色（不分页），用于下拉选择等场景。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| tenantId | long | 是 | Query | 租户 ID |

**请求示例**：`GET /api/v1/auth/roles/list?tenantId=1`

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | array | 角色列表（RoleEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 101,
      "tenantId": 1,
      "roleCode": "SUPER_ADMIN",
      "roleName": "超级管理员",
      "status": 1
    }
  ],
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 401 | 未授权 |
| AUTH-0016 | 权限不足 |

**权限要求**：需登录，管理员角色操作。

### 5.20 查询角色详情（API-020）

**接口**：`GET /api/v1/auth/roles/{id}`
**功能描述**：按角色 ID 查询角色详细信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 角色 ID |

**请求示例**：`GET /api/v1/auth/roles/101`

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | object | 角色详情（RoleEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 101,
    "tenantId": 1,
    "roleCode": "SUPER_ADMIN",
    "roleName": "超级管理员",
    "status": 1
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0017 | 角色不存在 |

**权限要求**：需登录，管理员角色操作。

### 5.21 创建角色（API-021）

**接口**：`POST /api/v1/auth/roles`
**功能描述**：创建新角色，需指定租户 ID、角色名称和角色编码（租户内编码唯一）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| tenantId | long | 是 | Body | 租户 ID |
| roleName | string | 是 | Body | 角色名称 |
| roleCode | string | 是 | Body | 角色编码（租户内唯一） |
| status | int | 否 | Body | 状态（默认启用） |

**请求示例**：
```json
{
  "tenantId": 1,
  "roleCode": "HR",
  "roleName": "人事专员",
  "status": 1
}
```

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | object | 创建后的角色信息（RoleEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 103,
    "tenantId": 1,
    "roleCode": "HR",
    "roleName": "人事专员",
    "status": 1
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 409 | 角色编码在租户内重复（资源冲突） |
| 400 | 请求参数错误 |

**权限要求**：需登录，管理员角色操作。

### 5.22 更新角色（API-022）

**接口**：`PUT /api/v1/auth/roles/{id}`
**功能描述**：按角色 ID 更新角色信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 角色 ID |
| roleName | string | 否 | Body | 角色名称 |
| roleCode | string | 否 | Body | 角色编码 |
| status | int | 否 | Body | 状态 |

**请求示例**：
```json
{
  "roleName": "人事主管",
  "status": 1
}
```

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | object | 更新后的角色信息（RoleEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 103,
    "tenantId": 1,
    "roleCode": "HR",
    "roleName": "人事主管",
    "status": 1
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0017 | 角色不存在 |
| 409 | 角色编码在租户内重复 |

**权限要求**：需登录，管理员角色操作。

### 5.23 删除角色（API-023）

**接口**：`DELETE /api/v1/auth/roles/{id}`
**功能描述**：逻辑删除角色。若角色已被分配给用户，则阻止删除并返回错误提示。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 角色 ID |

**请求示例**：`DELETE /api/v1/auth/roles/103`

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0017 | 角色不存在 |
| 409 | 角色已被分配，阻止删除（资源冲突） |

**权限要求**：需登录，管理员角色操作。

### 5.24 分配角色权限（API-024）

**接口**：`PUT /api/v1/auth/roles/{id}/permissions`
**功能描述**：全量更新角色权限关联（先删后插）：先删除当前角色的所有权限关联，再批量插入新的权限关联。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 角色 ID |
| permissionIds | array | 是 | Body | 权限 ID 列表 |

**请求示例**：
```json
{
  "permissionIds": [201, 202, 203]
}
```

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0017 | 角色不存在 |
| 400 | 请求参数错误 |

**权限要求**：需登录，管理员角色操作。

### 5.25 树形权限列表（API-025）

**接口**：`GET /api/v1/auth/permissions/tree`
**功能描述**：获取按 parent_id 自关联组织的树形权限结构，每个父权限包含子权限列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：无。

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | array | 树形权限列表（PermissionVO，含 children） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 201,
      "permCode": "user:list",
      "permName": "用户列表",
      "parentId": 0,
      "type": 1,
      "sort": 1,
      "children": [
        {
          "id": 202,
          "permCode": "user:create",
          "permName": "创建用户",
          "parentId": 201,
          "type": 2,
          "sort": 1,
          "children": []
        }
      ]
    }
  ],
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 401 | 未授权 |
| AUTH-0016 | 权限不足 |

**权限要求**：需登录，管理员角色操作。

### 5.26 所有权限列表（API-026）

**接口**：`GET /api/v1/auth/permissions/list`
**功能描述**：获取所有权限的平铺列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：无。

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | array | 权限列表（PermissionEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 201,
      "permCode": "user:list",
      "permName": "用户列表",
      "parentId": 0,
      "type": 1,
      "sort": 1
    }
  ],
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 401 | 未授权 |
| AUTH-0016 | 权限不足 |

**权限要求**：需登录，管理员角色操作。

### 5.27 权限详情（API-027）

**接口**：`GET /api/v1/auth/permissions/{id}`
**功能描述**：按权限 ID 获取权限详细信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 权限 ID |

**请求示例**：`GET /api/v1/auth/permissions/201`

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功；404 权限不存在 |
| message | string | 提示信息 |
| data | object | 权限信息（PermissionEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 201,
    "permCode": "user:list",
    "permName": "用户列表",
    "parentId": 0,
    "type": 1,
    "sort": 1
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 404 | 权限不存在 |

**权限要求**：需登录，管理员角色操作。

### 5.28 创建权限（API-028）

**接口**：`POST /api/v1/auth/permissions`
**功能描述**：创建新的权限点，perm_code 必须全局唯一。创建成功返回 HTTP 201。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| permCode | string | 是 | Body | 权限编码（全局唯一） |
| permName | string | 是 | Body | 权限名称 |
| parentId | long | 否 | Body | 父权限 ID（0 为根） |
| type | int | 否 | Body | 权限类型（菜单/按钮等） |
| sort | int | 否 | Body | 排序号 |

**请求示例**：
```json
{
  "permCode": "role:create",
  "permName": "创建角色",
  "parentId": 0,
  "type": 2,
  "sort": 3
}
```

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功（HTTP 201） |
| message | string | 提示信息 |
| data | object | 创建后的权限信息（PermissionEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 205,
    "permCode": "role:create",
    "permName": "创建角色",
    "parentId": 0,
    "type": 2,
    "sort": 3
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 409 | 权限编码重复（全局唯一冲突） |
| 400 | 请求参数错误 |

**权限要求**：需登录，管理员角色操作。

### 5.29 更新权限（API-029）

**接口**：`PUT /api/v1/auth/permissions/{id}`
**功能描述**：按权限 ID 更新权限信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |
| Content-Type | string | 是 | application/json |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 权限 ID |
| permCode | string | 否 | Body | 权限编码 |
| permName | string | 否 | Body | 权限名称 |
| parentId | long | 否 | Body | 父权限 ID |
| type | int | 否 | Body | 权限类型 |
| sort | int | 否 | Body | 排序号 |

**请求示例**：
```json
{
  "permName": "创建角色（含权限分配）",
  "sort": 4
}
```

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data | object | 更新后的权限信息（PermissionEntity） |
| timestamp | long | 时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 205,
    "permCode": "role:create",
    "permName": "创建角色（含权限分配）",
    "parentId": 0,
    "type": 2,
    "sort": 4
  },
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 404 | 权限不存在 |
| 409 | 权限编码重复 |

**权限要求**：需登录，管理员角色操作。

### 5.30 删除权限（API-030）

**接口**：`DELETE /api/v1/auth/permissions/{id}`
**功能描述**：逻辑删除权限。若权限已被角色关联，则阻止删除。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer <accessToken> |

**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | Path | 权限 ID |

**请求示例**：`DELETE /api/v1/auth/permissions/205`

**响应参数**：code=200、message=操作成功、data=null。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": null,
  "timestamp": 1785225600000
}
```

**错误码**：
| 错误码 | 说明 |
| --- | --- |
| 404 | 权限不存在 |
| 409 | 权限已被角色关联，阻止删除（资源冲突） |

**权限要求**：需登录，管理员角色操作。

### 5.31 认证服务健康检查（API-031）

**接口**：`GET /api/v1/auth/health`
**功能描述**：返回认证服务运行状态、名称、版本和时间戳，供运维监控与容器探活使用。属于网关白名单。
**请求头**：无。
**请求参数**：无。

**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | int | 200 成功 |
| message | string | 提示信息 |
| data.service | string | 服务名（cloudoffice-auth-service） |
| data.status | string | 状态（UP） |
| data.version | string | 版本号 |
| data.timestamp | string | 时间戳（ISO-8601） |
| timestamp | long | 响应时间戳（毫秒） |

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-auth-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": "2026-08-05T08:00:00.000Z"
  },
  "timestamp": 1785225600000
}
```

**错误码**：无（服务不可用时返回 503）。

**权限要求**：白名单，无需 Token。

### 5.32 企业服务健康检查（API-032）

**接口**：`GET /api/v1/biz/health`
**功能描述**：返回企业服务运行状态、名称、版本和时间戳，供运维监控与容器探活使用。
**请求头**：无。
**请求参数**：无。

**响应参数**：同 API-031（service 为 cloudoffice-biz-service）。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-biz-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": "2026-08-05T08:00:00.000Z"
  },
  "timestamp": 1785225600000
}
```

**错误码**：无（服务不可用时返回 503）。

**权限要求**：白名单，无需 Token。

### 5.33 系统服务健康检查（API-033）

**接口**：`GET /api/v1/system/health`
**功能描述**：返回系统服务运行状态、名称、版本和时间戳，供运维监控与容器探活（K8s 就绪/存活探针）使用。
**请求头**：无。
**请求参数**：无。

**响应参数**：同 API-031（service 为 cloudoffice-system-service，timestamp 为毫秒时间戳）。

**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-system-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": 1785225600000
  },
  "timestamp": 1785225600000
}
```

**错误码**：无（服务不可用时返回 503）。

**权限要求**：白名单，无需 Token。

## 6. 状态码映射

| HTTP 状态码 | 业务码（code） | 场景 | 输出 |
| --- | --- | --- | --- |
| 200 | 200 | 业务成功 | ApiResult（正常响应体） |
| 201 | 200 | 创建成功（PermissionController#create） | ApiResult |
| 400 | 400 / AUTH-0011 / AUTH-0019 / AUTH-0022 / AUTH-0023 / AUTH-0024 / AUTH-0032 / AUTH-0033 | 参数校验失败、验证码错误/过期、原密码错误、无效模式 | ApiResult（全局异常处理） |
| 401 | 401 / AUTH-0001~0005 / AUTH-0010 / AUTH-0013 / AUTH-0026 | Token 缺失/无效/过期/黑名单、登录失败、被踢、OAuth 失败 | 网关/认证服务自定义 JSON 响应体 |
| 403 | 403 / AUTH-0006~0009 / AUTH-0014~0016 / AUTH-0030 / AUTH-0031 | 账号/租户状态异常、权限不足、需邮箱验证、账号未完善 | 自定义 JSON 响应体 |
| 404 | 404 / AUTH-0017 / AUTH-0018 / AUTH-0027 | 资源/用户/角色/权限不存在、第三方账号未绑定 | ApiResult |
| 409 | 409 / AUTH-0028 / AUTH-0029 | 唯一性冲突、手机号/OAuth 已被绑定、删除被引用资源 | ApiResult |
| 429 | 429 / AUTH-0025 | 请求频率过高、验证码发送过于频繁 | ApiResult |
| 500 | 500 | 系统内部错误（兜底不泄露堆栈） | ApiResult（GlobalExceptionHandler） |
| 503 | 503 | 服务暂不可用 | ApiResult |

> 说明：业务码与 HTTP 状态码基本对齐（AUTH 错误码的 HTTP 状态码见第 4 节表格），网关对 401/403 直接输出自定义 JSON 不进入业务服务；业务服务内异常由 GlobalExceptionHandler 统一封装为标准 ApiResult。

## 7. 限流策略

| 限流项 | 规则 | 阈值 | 超限处理 |
| --- | --- | --- | --- |
| 验证码发送 | 同一目标（手机号/邮箱）+ 同一用途 60 秒内仅可发送一次（Redis 频率计数，VERIFICATION_CODE_SEND_INTERVAL 可配置） | 60 秒/次 | 返回 AUTH-0025（验证码发送过于频繁） |
| 登录尝试 | 登录失败记录登录日志，连续失败场景由登录策略/账号状态机制管控 | 按账号状态策略 | 触发锁定（状态 2）/封禁（状态 3）后由网关状态校验拦截 |
| 验证码校验 | 验证码一次性使用、5 分钟过期（VERIFICATION_CODE_EXPIRE_SECONDS 可配置） | 6 位数字 | 校验失败返回 AUTH-0011/AUTH-0019/AUTH-0023/AUTH-0024 |
| 全局限流 | 网关层默认无额外限流（当前版本依赖容器/负载均衡层） | 无 | 503（SERVICE_UNAVAILABLE） |

## 8. 示例代码

### 8.1 cURL 示例

**登录（获取双 Token）**：
```bash
curl -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "loginMode": "USERNAME_PASSWORD",
    "loginName": "admin",
    "password": "admin123",
    "tenantCode": "default",
    "clientType": "WINDOWS"
  }'
```

**携带 Token 访问受保护接口（分页查询用户）**：
```bash
curl -X GET "http://localhost:9000/api/v1/auth/users?page=1&pageSize=10" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiJ9.xxx" \
  -H "X-Tenant-Id: 1"
```

**刷新 Token**：
```bash
curl -X POST http://localhost:9000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken": "eyJhbGciOiJSUzI1NiJ9.xxx"}'
```

**登出**：
```bash
curl -X POST http://localhost:9000/api/v1/auth/logout \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiJ9.xxx"
```

### 8.2 Flutter 客户端调用示例（Dart）

```dart
// 登录：返回双 Token，客户端拦截器自动注入 Authorization 头
final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/login'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'loginMode': 'USERNAME_PASSWORD',
    'loginName': 'admin',
    'password': 'admin123',
    'tenantCode': 'default',
    'clientType': 'ANDROID',
  }),
);
final result = ApiResult.fromJson(jsonDecode(response.body));
if (result.code == 200) {
  final tokenPair = TokenPair.fromJson(result.data);
  await SecureStorage.saveTokenPair(tokenPair); // Token 安全存储
}
```

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
