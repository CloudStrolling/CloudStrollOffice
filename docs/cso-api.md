# 接口设计文档（API）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：0.0.1
**日期**：2026-08-07
**编写人**：SA（初始化阶段按存量代码反推）

## 1. 接口清单

> 本版本共 **33 个接口**，按模块分组：认证管理 11 个、用户管理 6 个、角色管理 7 个、权限管理 6 个、健康检查 3 个。
> 全部接口统一返回 `ApiResult<T>` 结构（code/message/data/timestamp），分页接口 data 为 `PageResult<T>`。
> 网关统一入口 `http://{gateway-host}:9000`，服务间通过 Nacos 注册发现路由。

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- | --- |
| API-001 | 用户登录 | POST | /api/v1/auth/login | 4 种登录模式（用户名密码/手机验证码/OAuth），签发双 Token | 白名单 |
| API-002 | 用户注册 | POST | /api/v1/auth/register | 5 种注册策略，返回用户信息与双 Token | 白名单 |
| API-003 | 刷新 Token | POST | /api/v1/auth/refresh | Refresh Token 轮换，旧 Token 入黑名单 | 白名单 |
| API-004 | 用户登出 | POST | /api/v1/auth/logout | Token 入黑名单并清除登录态，幂等 | 需认证 |
| API-005 | 强制踢人 | POST | /api/v1/auth/kickout | 管理员踢指定端或所有端 | 需认证 |
| API-006 | 修改密码 | PUT | /api/v1/auth/password/change | 校验旧密码，成功后清除全部登录态 | 需认证 |
| API-007 | 密码找回-发送验证码 | POST | /api/v1/auth/password/forgot/send-code | 手机短信或邮箱发送重置验证码 | 白名单 |
| API-008 | 密码找回-重置密码 | POST | /api/v1/auth/password/forgot/reset | 校验验证码后重置密码 | 白名单 |
| API-009 | 修改手机号 | PUT | /api/v1/auth/phone/change | 原手机短信验证码或邮箱验证码校验 | 需认证 |
| API-010 | 完善账号信息 | PUT | /api/v1/auth/account/settlement | 两步注册第二步，补全登录名/密码/手机号 | 需认证 |
| API-011 | 发送验证码 | POST | /api/v1/auth/verification-code/send | 注册/登录/重置密码/换绑手机用途，60 秒限频 | 白名单 |
| API-012 | 认证服务健康检查 | GET | /api/v1/auth/health | 服务名/状态/版本/时间戳 | 白名单 |
| API-013 | 分页查询用户列表 | GET | /api/v1/auth/users | 按租户分页，支持关键字模糊搜索 | 需认证 |
| API-014 | 获取用户详情 | GET | /api/v1/auth/users/{id} | 返回用户信息及角色编码列表 | 需认证 |
| API-015 | 更新用户信息 | PUT | /api/v1/auth/users/{id} | 更新姓名/手机号/邮箱（不含密码） | 需认证 |
| API-016 | 逻辑删除用户 | DELETE | /api/v1/auth/users/{id} | 标记 deleted=1 | 需认证 |
| API-017 | 分配用户角色 | PUT | /api/v1/auth/users/{id}/roles | 全量更新（先删后插） | 需认证 |
| API-018 | 变更用户状态 | PUT | /api/v1/auth/users/{id}/status | 0-正常/1-停用/2-锁定/3-封禁 | 需认证 |
| API-019 | 分页查询角色列表 | GET | /api/v1/auth/roles | 按租户分页 | 需认证 |
| API-020 | 查询所有角色 | GET | /api/v1/auth/roles/list | 按租户查询，不分页 | 需认证 |
| API-021 | 获取角色详情 | GET | /api/v1/auth/roles/{id} | 按 ID 查询角色 | 需认证 |
| API-022 | 创建角色 | POST | /api/v1/auth/roles | 角色编码租户内唯一 | 需认证 |
| API-023 | 更新角色 | PUT | /api/v1/auth/roles/{id} | 更新角色信息 | 需认证 |
| API-024 | 删除角色 | DELETE | /api/v1/auth/roles/{id} | 已被用户分配则阻止删除 | 需认证 |
| API-025 | 分配角色权限 | PUT | /api/v1/auth/roles/{id}/permissions | 全量更新权限关联（先删后插） | 需认证 |
| API-026 | 树形权限列表 | GET | /api/v1/auth/permissions/tree | 按 parentId 自关联树形结构 | 需认证 |
| API-027 | 所有权限列表 | GET | /api/v1/auth/permissions/list | 平铺列表 | 需认证 |
| API-028 | 获取权限详情 | GET | /api/v1/auth/permissions/{id} | 按 ID 查询权限 | 需认证 |
| API-029 | 创建权限 | POST | /api/v1/auth/permissions | permCode 全局唯一，返回 201 | 需认证 |
| API-030 | 更新权限 | PUT | /api/v1/auth/permissions/{id} | 更新权限信息 | 需认证 |
| API-031 | 删除权限 | DELETE | /api/v1/auth/permissions/{id} | 已被角色关联则阻止删除 | 需认证 |
| API-032 | 企业服务健康检查 | GET | /api/v1/biz/health | 企业服务骨架探活 | 需认证（见备注） |
| API-033 | 系统服务健康检查 | GET | /api/v1/system/health | 系统服务骨架探活 | 需认证（见备注） |

> 备注：当前网关白名单仅配置了 `/api/v1/auth/health`（API-012）；`/api/v1/biz/health` 与 `/api/v1/system/health` 未加入白名单，直连服务端口可免认证访问，经网关访问需携带有效 Token（后续版本可将其加入白名单，与 PRD 目标对齐）。

## 2. 接口版本策略

- **URL 版本路径**：所有接口统一前缀 `/api/v1/{module}/{resource}`，`{module}` 为业务模块标识（auth/biz/system），`v1` 为 API 主版本号。
- **网关路由**：Spring Cloud Gateway 通过 Nacos 服务发现路由：`/api/v1/auth/**` → `cloudoffice-auth-service`（:9100）、`/api/v1/biz/**` → `cloudoffice-biz-service`（:9200）、`/api/v1/system/**` → `cloudoffice-system-service`（:9400）。
- **兼容策略**：v1 内保持向后兼容，新功能只允许新增端点与可选字段，禁止修改既有端点语义；发生破坏性变更（删除/重命名端点、必填字段变化、响应结构变化）时升级主版本号至 v2。
- **在线文档**：各服务通过 SpringDoc OpenAPI 3 生成 Swagger UI（`/swagger-ui.html`、`/v3/api-docs/**`，网关白名单放行），按模块分组在线调试。

## 3. 认证鉴权机制

- **认证方式**：JWT RS256（RSA 2048 位非对称签名）双 Token 机制：
  - **Access Token**：有效期 2 小时，载荷含 userId(sub)、tenantId、userName、clientType、tokenType=access、roles、permissions。
  - **Refresh Token**：有效期 7 天，载荷含 clientType、tokenType=refresh；每次刷新轮换（旧 Refresh Token 签名入 Redis 黑名单防重放）。
- **Token 传递**：客户端在 `Authorization` 请求头携带 `Bearer {accessToken}`；登录/刷新成功后返回的 `tokenType` 固定为 `Bearer`。
- **网关全局认证（9 步校验）**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验（必须为 access）→ Redis 黑名单校验 → 登录态校验 → 账号状态校验（封禁/禁用/锁定返回 403）→ 租户状态校验（停用/过期返回 403）→ 用户信息 Header 透传。
- **Header 透传（下游服务消费）**：
  | Header | 说明 |
  | --- | --- |
  | X-User-Id | 用户 ID（Long） |
  | X-Tenant-Id | 租户 ID（Long） |
  | X-User-Name | 用户姓名 |
  | X-Client-Type | 客户端类型（WINDOWS/UBUNTU/H5/ANDROID/IOS/WECHAT_MINI） |
  | X-Roles | 角色编码列表（逗号分隔） |
  | X-Permissions | 权限标识列表（逗号分隔） |
- **白名单端点（无需认证，网关直接放行）**：
  `/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`、`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`、`/webjars/**`。
- **Token 过期与刷新**：客户端收到 401 后使用 Refresh Token 调用 API-003 获取新 Token 对并重试原请求；Refresh Token 也失效时清除本地 Token 并跳转登录页。
- **角色权限**：本版本提供 RBAC 模型与数据管理 API（用户-角色-权限三层关联），接口级权限点校验（鉴权注解）随业务版本演进。

## 4. 通用错误码定义

> 统一响应体 `ApiResult<T>`：`code`（状态码）、`message`（提示信息）、`data`（业务数据）、`timestamp`（毫秒时间戳）。错误码枚举定义于 `cloudoffice-common` 的 `ErrorCode`，共 33 个（10 个基础 + 23 个认证授权类）。

### 4.1 基础错误码（HTTP 状态码映射）
| 错误码 | 说明 |
| --- | --- |
| 200 | 操作成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，请先登录 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 405 | 请求方法不支持 |
| 409 | 资源冲突 |
| 429 | 请求频率过高 |
| 500 | 系统繁忙，请稍后重试 |
| 503 | 服务暂不可用 |

### 4.2 认证授权错误码（业务编码 AUTH-XXXX）
| 业务编码 | 状态码 | 说明 |
| --- | --- | --- |
| AUTH-0001 | 401 | 令牌已过期，请刷新令牌 |
| AUTH-0002 | 401 | 令牌无效 |
| AUTH-0003 | 401 | 令牌已被吊销 |
| AUTH-0004 | 401 | 刷新令牌已过期，请重新登录 |
| AUTH-0005 | 401 | 刷新令牌无效 |
| AUTH-0006 | 403 | 账号已被禁用 |
| AUTH-0007 | 403 | 账号已被锁定 |
| AUTH-0008 | 403 | 账号已被封禁 |
| AUTH-0009 | 403 | 账号已过期 |
| AUTH-0010 | 401 | 用户名或密码错误 |
| AUTH-0011 | 400 | 验证码错误 |
| AUTH-0012 | 400 | 无效的客户端类型 |
| AUTH-0013 | 401 | 账号已在其他设备登录，您已被踢下线 |
| AUTH-0014 | 403 | 租户已被禁用 |
| AUTH-0015 | 403 | 租户已过期 |
| AUTH-0016 | 403 | 权限不足 |
| AUTH-0017 | 404 | 角色不存在 |
| AUTH-0018 | 404 | 用户不存在 |
| AUTH-0019 | 400 | 验证码已过期 |
| AUTH-0020 | 400 | 密码重置令牌无效 |
| AUTH-0021 | 400 | 密码重置令牌已过期 |
| AUTH-0022 | 400 | 原密码错误 |
| AUTH-0023 | 400 | 短信验证码无效 |
| AUTH-0024 | 400 | 短信验证码已过期 |
| AUTH-0025 | 429 | 验证码发送过于频繁 |
| AUTH-0026 | 401 | 第三方登录失败 |
| AUTH-0027 | 404 | 第三方账号未绑定 |
| AUTH-0028 | 409 | 手机号已被其他账号绑定 |
| AUTH-0029 | 409 | 第三方账号已被其他用户绑定 |
| AUTH-0030 | 403 | 需要邮箱验证 |
| AUTH-0031 | 403 | 账号信息未完善，请先补充资料 |
| AUTH-0032 | 400 | 无效的注册模式 |
| AUTH-0033 | 400 | 无效的登录模式 |

### 4.3 统一分页结构 PageResult<T>
```json
{ "records": [], "total": 0, "page": 1, "pageSize": 10 }
```

## 5. 接口详细定义

### 5.1 用户登录（API-001）
**接口**：`POST /api/v1/auth/login`（白名单，无需认证）
**功能描述**：支持 4 种登录模式：USERNAME_PASSWORD（用户名密码）、SMS（手机验证码）、PHONE_PASSWORD（手机+密码）、OAUTH（第三方）。校验顺序：租户状态 → 账号状态 → 凭据；同端互斥（同 clientType 旧会话入黑名单）；成功签发 JWT RS256 双 Token 并创建 Redis 登录态会话、记录登录日志。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| loginMode | string | 否 | body | 登录模式，默认 USERNAME_PASSWORD；可选 USERNAME_PASSWORD/SMS/PHONE_PASSWORD/OAUTH |
| loginName | string | 条件 | body | 登录名（USERNAME_PASSWORD 模式必填，4-64 字符） |
| password | string | 条件 | body | 密码（USERNAME_PASSWORD 模式必填，8-64 字符） |
| phone | string | 条件 | body | 手机号（SMS/PHONE_PASSWORD 模式必填） |
| smsCode | string | 条件 | body | 短信验证码（SMS 模式必填） |
| oauthProvider | string | 条件 | body | OAuth 提供商（OAUTH 模式必填，如 wechat） |
| oauthCode | string | 条件 | body | OAuth 授权码（OAUTH 模式必填） |
| tenantCode | string | 是 | body | 租户编码，所有模式必填 |
| clientType | string | 是 | body | 客户端类型：WINDOWS/UBUNTU/H5/ANDROID/IOS/WECHAT_MINI |
**请求示例**：
```json
{
  "loginMode": "USERNAME_PASSWORD",
  "loginName": "admin",
  "password": "password123",
  "tenantCode": "default",
  "clientType": "WINDOWS"
}
```
**响应参数**（data 为 TokenPairDTO）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| accessToken | string | Access Token（有效期 2 小时） |
| refreshToken | string | Refresh Token（有效期 7 天） |
| accessTokenExpireIn | long | Access Token 过期时间（秒） |
| refreshTokenExpireIn | long | Refresh Token 过期时间（秒） |
| tokenType | string | 固定为 "Bearer" |
**响应示例**：
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9...",
    "accessTokenExpireIn": 7200,
    "refreshTokenExpireIn": 604800,
    "tokenType": "Bearer"
  },
  "timestamp": 1723000000000
}
```
**错误码**：AUTH-0006/0007/0008/0009（账号状态）、AUTH-0010（凭据错误）、AUTH-0011/0019/0023/0024（验证码）、AUTH-0012（客户端类型）、AUTH-0013（同端互斥提示）、AUTH-0014/0015（租户状态）、AUTH-0026/0027（OAuth）、AUTH-0031（账号未完善）、AUTH-0033（登录模式无效）、400（参数错误）

### 5.2 用户注册（API-002）
**接口**：`POST /api/v1/auth/register`（白名单，无需认证）
**功能描述**：支持 5 种注册策略：USERNAME（用户名密码）、PHONE（手机验证码）、EMAIL（邮箱）、OAUTH（第三方）、两步注册（先创建账号后补全信息）。校验登录名/手机号租户内唯一；注册成功分配默认角色、签发双 Token 自动登录。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| registerMode | string | 否 | body | 注册模式，默认 USERNAME；可选 USERNAME/PHONE/EMAIL/OAUTH |
| loginName | string | 条件 | body | 登录名（USERNAME 模式必填，4-64 字符，字母数字下划线） |
| password | string | 条件 | body | 密码（USERNAME/EMAIL 模式必填，8-64 字符） |
| userName | string | 是 | body | 用户姓名（所有模式必填，≤50 字符） |
| phone | string | 条件 | body | 手机号（PHONE 模式必填） |
| email | string | 条件 | body | 邮箱（EMAIL 模式必填） |
| smsCode | string | 条件 | body | 短信验证码（PHONE 模式必填） |
| oauthProvider | string | 条件 | body | OAuth 提供商（OAUTH 模式必填） |
| oauthCode | string | 条件 | body | OAuth 授权码（OAUTH 模式必填） |
| tenantCode | string | 是 | body | 租户编码，所有模式必填 |
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
**响应参数**（data 为 RegisterResult）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| userId | long | 用户 ID |
| loginName | string | 登录名 |
| userName | string | 用户姓名 |
| accountSettled | boolean | 账号信息是否完整（true=完整，false=需补全） |
| tokenPair | object | 双 Token（结构同 API-001） |
**响应示例**：
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": 1,
    "loginName": "newuser",
    "userName": "张三",
    "accountSettled": true,
    "tokenPair": {
      "accessToken": "eyJhbGciOiJSUzI1NiJ9...",
      "refreshToken": "eyJhbGciOiJSUzI1NiJ9...",
      "accessTokenExpireIn": 7200,
      "refreshTokenExpireIn": 604800,
      "tokenType": "Bearer"
    }
  },
  "timestamp": 1723000000000
}
```
**错误码**：AUTH-0011/0019/0023/0024（验证码）、AUTH-0014/0015（租户）、AUTH-0018（用户不存在）、AUTH-0028（手机号已绑定）、AUTH-0029（第三方已绑定）、AUTH-0032（注册模式无效）、400（参数/唯一性错误）

### 5.3 刷新 Token（API-003）
**接口**：`POST /api/v1/auth/refresh`（白名单，无需认证）
**功能描述**：使用 Refresh Token 申请新的双 Token 对；校验签名、有效期、黑名单与 tokenType=refresh 后轮换签发，旧 Refresh Token 签名立即入黑名单防重放。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| refreshToken | string | 是 | body | Refresh Token，不能为空 |
**请求示例**：
```json
{ "refreshToken": "eyJhbGciOiJSUzI1NiJ9..." }
```
**响应参数**：同 API-001（新的 TokenPairDTO）。
**响应示例**：
```json
{
  "code": 200,
  "message": "刷新成功",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9...",
    "accessTokenExpireIn": 7200,
    "refreshTokenExpireIn": 604800,
    "tokenType": "Bearer"
  },
  "timestamp": 1723000000000
}
```
**错误码**：AUTH-0004（刷新令牌过期）、AUTH-0005（刷新令牌无效）、AUTH-0003（令牌被吊销）、400（参数错误）

### 5.4 用户登出（API-004）
**接口**：`POST /api/v1/auth/logout`
**功能描述**：将当前 Access Token 签名加入 Redis 黑名单并清除登录态会话；幂等设计，重复登出不报错。当前用户从网关透传的 Authorization 头中提取（服务端不再依赖 X-User-Id 取用户，而是解析 Token）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：无（Body 为空）。
**请求示例**：`POST /api/v1/auth/logout`（Header: Authorization: Bearer eyJ...）
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "登出成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0002（Token 格式/无效）、401（未授权）

### 5.5 强制踢人（API-005）
**接口**：`POST /api/v1/auth/kickout`
**功能描述**：管理员强制指定用户下线。clientType 非空时踢指定端，为空时踢所有端；被踢用户下一次请求立即失效（黑名单/会话校验拦截）；幂等。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | long | 是 | body | 目标用户 ID |
| clientType | string | 否 | body | 客户端类型；为空表示踢所有端 |
**请求示例**：
```json
{ "userId": 1, "clientType": "H5" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：400（参数错误）、401（未授权）、403（权限不足）

### 5.6 修改密码（API-006）
**接口**：`PUT /api/v1/auth/password/change`
**功能描述**：当前登录用户修改密码。校验旧密码 BCrypt 匹配与新密码策略（8-64 字符、与旧密码不同）；成功后清除该用户全部客户端类型的登录态会话。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| oldPassword | string | 是 | body | 旧密码 |
| newPassword | string | 是 | body | 新密码（8-64 字符） |
| confirmPassword | string | 是 | body | 确认新密码，需与新密码一致 |
**请求示例**：
```json
{ "oldPassword": "oldPassword123", "newPassword": "newPassword456", "confirmPassword": "newPassword456" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0022（原密码错误）、400（参数/新密码与旧密码相同）、401（未授权）

### 5.7 密码找回-发送验证码（API-007）
**接口**：`POST /api/v1/auth/password/forgot/send-code`（白名单，无需认证）
**功能描述**：向目标手机号或邮箱发送密码重置验证码；受 60 秒发送频率限制与 5 分钟有效期约束；目标账号不存在返回用户不存在错误。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| target | string | 是 | body | 验证码接收目标（手机号或邮箱） |
| purpose | string | 是 | body | 用途：REGISTER/LOGIN/RESET_PASSWORD/CHANGE_PHONE（此处为 RESET_PASSWORD） |
| mode | string | 是 | body | 发送方式：SMS/EMAIL |
**请求示例**：
```json
{ "target": "13800138000", "purpose": "RESET_PASSWORD", "mode": "SMS" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0018（用户不存在）、AUTH-0025（发送过于频繁）、400（参数错误）

### 5.8 密码找回-重置密码（API-008）
**接口**：`POST /api/v1/auth/password/forgot/reset`（白名单，无需认证）
**功能描述**：校验目标与验证码后设置新密码（8-64 字符）；成功后清除该用户全部登录态会话。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| mode | string | 是 | body | 验证方式：EMAIL/SMS |
| target | string | 是 | body | 验证目标（手机号或邮箱） |
| code | string | 是 | body | 验证码 |
| newPassword | string | 是 | body | 新密码（8-64 字符） |
**请求示例**：
```json
{ "mode": "SMS", "target": "13800138000", "code": "123456", "newPassword": "newPassword456" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0011/0019/0023/0024（验证码错误/过期）、400（参数错误）

### 5.9 修改手机号（API-009）
**接口**：`PUT /api/v1/auth/phone/change`
**功能描述**：当前登录用户更换手机号。已绑定手机号时校验旧手机号验证码；未绑定手机号时校验邮箱验证码；新手机号租户内唯一。当前用户 ID 从网关透传头 X-User-Id 获取。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| newPhone | string | 是 | body | 新手机号 |
| oldPhoneCode | string | 条件 | body | 旧手机号验证码（已绑定手机号时必填） |
| newPhoneCode | string | 是 | body | 新手机号验证码 |
| emailCode | string | 条件 | body | 邮箱验证码（未绑定手机号、仅绑定邮箱时必填） |
**请求示例**：
```json
{ "newPhone": "13900139000", "oldPhoneCode": "654321", "newPhoneCode": "123456" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0011/0019/0023/0024（验证码错误/过期）、AUTH-0028（新手机号已被绑定）、401（未授权）

### 5.10 完善账号信息（API-010）
**接口**：`PUT /api/v1/auth/account/settlement`
**功能描述**：两步注册第二步。当前登录用户补全登录名、密码、手机号；校验请求体 userId 与当前用户（X-User-Id）一致，且账号未完善（account_settled=false）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | long | 是 | body | 用户 ID（须与当前登录用户一致） |
| loginName | string | 否 | body | 登录名 |
| password | string | 否 | body | 密码 |
| phone | string | 否 | body | 手机号 |
| smsCode | string | 否 | body | 短信验证码 |
**请求示例**：
```json
{ "userId": 1, "loginName": "newuser", "password": "password123", "phone": "13800138000", "smsCode": "123456" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0031（账号信息未完善前置校验）、400（参数错误/用户 ID 不匹配）、401（未授权）

### 5.11 发送验证码（API-011）
**接口**：`POST /api/v1/auth/verification-code/send`（白名单，无需认证）
**功能描述**：向目标（手机号/邮箱）发送验证码，用途覆盖注册、登录、重置密码、更换手机号；60 秒发送频率限制、5 分钟有效期、模拟模式（VERIFICATION_CODE_MOCK=true）直接返回固定验证码。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| target | string | 是 | body | 验证码接收目标（手机号或邮箱） |
| purpose | string | 是 | body | 用途：REGISTER/LOGIN/RESET_PASSWORD/CHANGE_PHONE |
| mode | string | 是 | body | 发送方式：SMS/EMAIL |
**请求示例**：
```json
{ "target": "13800138000", "purpose": "REGISTER", "mode": "SMS" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0025（发送过于频繁）、400（参数错误）

### 5.12 认证服务健康检查（API-012）
**接口**：`GET /api/v1/auth/health`（白名单，无需认证）
**功能描述**：返回认证服务运行状态、服务名、版本与时间戳，供部署脚本与监控探活。
**请求头**：无。
**请求参数**：无。
**请求示例**：`GET /api/v1/auth/health`
**响应参数**（data 为 Map）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| service | string | 服务名（cloudoffice-auth-service） |
| status | string | 状态（UP） |
| version | string | 版本号 |
| timestamp | string | 时间戳（ISO 格式） |
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-auth-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": "2026-08-07T08:00:00.000Z"
  },
  "timestamp": 1723000000000
}
```
**错误码**：500（服务异常）、503（服务不可用）

### 5.13 分页查询用户列表（API-013）
**接口**：`GET /api/v1/auth/users`
**功能描述**：按租户分页查询用户列表，支持 login_name/user_name 模糊搜索，按创建时间降序；租户 ID 从网关透传头 X-Tenant-Id 获取。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| X-Tenant-Id | long | 是 | 租户 ID（网关透传） |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| page | int | 否 | query | 页码（从 1 开始，默认 1） |
| pageSize | int | 否 | query | 每页条数（默认 10） |
| keyword | string | 否 | query | 搜索关键词（登录名/姓名） |
**请求示例**：`GET /api/v1/auth/users?page=1&pageSize=10&keyword=admin`
**响应参数**（data 为 PageResult\<UserEntity\>）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| records | array | 用户列表（字段见下方 UserEntity 说明） |
| total | long | 总记录数 |
| page | int | 当前页码 |
| pageSize | int | 每页大小 |
**UserEntity 关键字段**：id、tenantId、loginName、userName、phone、email、avatar、status（0-正常/1-停用/2-锁定/3-封禁）、lockReason、lastLoginTime、lastLoginIp、registerMode、accountSettled（0/1）、phoneVerified（0/1）、emailVerified（0/1）、roleCodes（角色编码列表，非库字段）、createTime、updateTime
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1,
        "tenantId": 1,
        "loginName": "admin",
        "userName": "管理员",
        "phone": "13800138000",
        "email": "admin@example.com",
        "status": 0,
        "accountSettled": 1,
        "roleCodes": ["SUPER_ADMIN"],
        "createTime": "2026-08-01T10:00:00"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 10
  },
  "timestamp": 1723000000000
}
```
**错误码**：401（未授权）、403（权限不足/租户异常）、400（参数错误）

### 5.14 获取用户详情（API-014）
**接口**：`GET /api/v1/auth/users/{id}`
**功能描述**：按用户 ID 返回用户基本信息（不含密码）及角色编码列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 用户 ID |
**请求示例**：`GET /api/v1/auth/users/1`
**响应参数**：data 为 UserEntity（字段见 API-013）。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "id": 1,
    "tenantId": 1,
    "loginName": "admin",
    "userName": "管理员",
    "phone": "13800138000",
    "email": "admin@example.com",
    "status": 0,
    "accountSettled": 1,
    "roleCodes": ["SUPER_ADMIN"],
    "createTime": "2026-08-01T10:00:00"
  },
  "timestamp": 1723000000000
}
```
**错误码**：AUTH-0018（用户不存在）、401（未授权）

### 5.15 更新用户信息（API-015）
**接口**：`PUT /api/v1/auth/users/{id}`
**功能描述**：更新用户基本信息（姓名、手机号、邮箱），密码变更需走独立接口（API-006）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 用户 ID |
| userName | string | 否 | body | 用户姓名（≤50 字符） |
| phone | string | 否 | body | 手机号 |
| email | string | 否 | body | 邮箱 |
**请求示例**：
```json
{ "userName": "李四", "phone": "13800138000", "email": "lisi@example.com" }
```
**响应参数**：data 为更新后的 UserEntity。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { "id": 1, "loginName": "admin", "userName": "李四", "status": 0 },
  "timestamp": 1723000000000
}
```
**错误码**：AUTH-0018（用户不存在）、AUTH-0028（手机号冲突）、400（参数错误）、401（未授权）

### 5.16 逻辑删除用户（API-016）
**接口**：`DELETE /api/v1/auth/users/{id}`
**功能描述**：将用户标记为已删除（deleted=1），已删除用户不可通过查询接口获取。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 用户 ID |
**请求示例**：`DELETE /api/v1/auth/users/1`
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0018（用户不存在）、401（未授权）、403（权限不足）

### 5.17 分配用户角色（API-017）
**接口**：`PUT /api/v1/auth/users/{id}/roles`
**功能描述**：全量更新用户角色关联（先删后插），传入完整角色 ID 列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 用户 ID |
| roleIds | array&lt;long&gt; | 是 | body | 角色 ID 列表 |
**请求示例**：
```json
{ "roleIds": [1, 2] }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0017（角色不存在）、400（参数错误）、401（未授权）

### 5.18 变更用户状态（API-018）
**接口**：`PUT /api/v1/auth/users/{id}/status`
**功能描述**：变更用户状态：0-恢复正常、1-停用、2-锁定（同步更新 Redis 状态缓存）、3-封禁（同步清除所有登录态会话）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 用户 ID |
| status | int | 是 | body | 目标状态（0-正常，1-停用，2-锁定，3-封禁） |
| lockReason | string | 否 | body | 锁定/封禁原因 |
**请求示例**：
```json
{ "status": 3, "lockReason": "违规操作" }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0018（用户不存在）、400（参数错误，状态值范围 0-3）、401（未授权）、403（权限不足）

### 5.19 分页查询角色列表（API-019）
**接口**：`GET /api/v1/auth/roles`
**功能描述**：按租户 ID 分页查询角色列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| page | int | 否 | query | 页码（从 1 开始，默认 1） |
| pageSize | int | 否 | query | 每页大小（默认 10） |
| tenantId | long | 是 | query | 租户 ID |
**请求示例**：`GET /api/v1/auth/roles?page=1&pageSize=10&tenantId=1`
**响应参数**（data 为 PageResult\<RoleEntity\>）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| records | array | 角色列表 |
| total | long | 总记录数 |
| page | int | 当前页码 |
| pageSize | int | 每页大小 |
**RoleEntity 关键字段**：id、tenantId、roleName、roleCode（租户内唯一）、description、sortOrder、status（0-正常/1-停用）、createTime、updateTime
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      { "id": 1, "tenantId": 1, "roleName": "超级管理员", "roleCode": "SUPER_ADMIN", "status": 0 }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 10
  },
  "timestamp": 1723000000000
}
```
**错误码**：400（参数错误）、401（未授权）、403（权限不足）

### 5.20 查询所有角色（API-020）
**接口**：`GET /api/v1/auth/roles/list`
**功能描述**：按租户 ID 查询所有角色（不分页），用于下拉选择等场景。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| tenantId | long | 是 | query | 租户 ID |
**请求示例**：`GET /api/v1/auth/roles/list?tenantId=1`
**响应参数**：data 为 RoleEntity 数组。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    { "id": 1, "tenantId": 1, "roleName": "超级管理员", "roleCode": "SUPER_ADMIN", "status": 0 }
  ],
  "timestamp": 1723000000000
}
```
**错误码**：400（参数错误）、401（未授权）

### 5.21 获取角色详情（API-021）
**接口**：`GET /api/v1/auth/roles/{id}`
**功能描述**：按角色 ID 查询角色详细信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 角色 ID |
**请求示例**：`GET /api/v1/auth/roles/1`
**响应参数**：data 为 RoleEntity。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { "id": 1, "tenantId": 1, "roleName": "超级管理员", "roleCode": "SUPER_ADMIN", "status": 0 },
  "timestamp": 1723000000000
}
```
**错误码**：AUTH-0017（角色不存在）、401（未授权）

### 5.22 创建角色（API-022）
**接口**：`POST /api/v1/auth/roles`
**功能描述**：创建新角色，需指定租户 ID、角色名称与角色编码；角色编码在租户内唯一。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**（body 为 RoleEntity 核心字段）：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| tenantId | long | 是 | body | 租户 ID |
| roleName | string | 是 | body | 角色名称 |
| roleCode | string | 是 | body | 角色编码（租户内唯一） |
| description | string | 否 | body | 角色描述 |
| sortOrder | int | 否 | body | 排序号 |
| status | int | 否 | body | 状态（0-正常，默认 0） |
**请求示例**：
```json
{ "tenantId": 1, "roleName": "人事专员", "roleCode": "HR_SPECIALIST", "description": "人事管理角色" }
```
**响应参数**：data 为创建后的 RoleEntity。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { "id": 2, "tenantId": 1, "roleName": "人事专员", "roleCode": "HR_SPECIALIST", "status": 0 },
  "timestamp": 1723000000000
}
```
**错误码**：409（角色编码重复/资源冲突）、400（参数错误）、401（未授权）

### 5.23 更新角色（API-023）
**接口**：`PUT /api/v1/auth/roles/{id}`
**功能描述**：按角色 ID 更新角色信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 角色 ID |
| roleName | string | 否 | body | 角色名称 |
| roleCode | string | 否 | body | 角色编码 |
| description | string | 否 | body | 角色描述 |
| sortOrder | int | 否 | body | 排序号 |
| status | int | 否 | body | 状态（0-正常，1-停用） |
**请求示例**：
```json
{ "roleName": "高级人事专员", "description": "人事管理高级角色" }
```
**响应参数**：data 为更新后的 RoleEntity。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { "id": 2, "tenantId": 1, "roleName": "高级人事专员", "roleCode": "HR_SPECIALIST", "status": 0 },
  "timestamp": 1723000000000
}
```
**错误码**：AUTH-0017（角色不存在）、409（角色编码冲突）、400（参数错误）、401（未授权）

### 5.24 删除角色（API-024）
**接口**：`DELETE /api/v1/auth/roles/{id}`
**功能描述**：逻辑删除角色；若角色已被用户分配则返回错误阻止删除（防止脏数据）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 角色 ID |
**请求示例**：`DELETE /api/v1/auth/roles/2`
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0017（角色不存在）、409（角色已被分配）、401（未授权）

### 5.25 分配角色权限（API-025）
**接口**：`PUT /api/v1/auth/roles/{id}/permissions`
**功能描述**：全量更新角色权限关联（先删后插），传入权限 ID 列表；分配后该角色下所有用户权限即时更新。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 角色 ID |
| permissionIds | array&lt;long&gt; | 是 | body | 权限 ID 列表（Map 结构） |
**请求示例**：
```json
{ "permissionIds": [1, 2, 3] }
```
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：AUTH-0017（角色不存在）、400（参数错误）、401（未授权）

### 5.26 树形权限列表（API-026）
**接口**：`GET /api/v1/auth/permissions/tree`
**功能描述**：获取按 parentId 自关联组织的树形权限结构，每个父权限包含 children 子权限列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：无。
**请求示例**：`GET /api/v1/auth/permissions/tree`
**响应参数**（data 为 PermissionVO 数组）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| id | long | 权限 ID |
| permName | string | 权限名称 |
| permCode | string | 权限编码 |
| permType | int | 类型（1-菜单，2-按钮，3-API） |
| parentId | long | 父权限 ID |
| path/component/icon | string | 前端路由/组件/图标 |
| sortOrder | int | 排序号 |
| status | int | 状态（0-正常，1-停用） |
| children | array | 子权限列表（树形递归） |
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 1,
      "permName": "用户管理",
      "permCode": "user:manage",
      "permType": 1,
      "parentId": 0,
      "status": 0,
      "children": [
        { "id": 2, "permName": "创建用户", "permCode": "user:create", "permType": 2, "parentId": 1, "status": 0, "children": [] }
      ]
    }
  ],
  "timestamp": 1723000000000
}
```
**错误码**：401（未授权）

### 5.27 所有权限列表（API-027）
**接口**：`GET /api/v1/auth/permissions/list`
**功能描述**：获取所有权限的平铺列表。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：无。
**请求示例**：`GET /api/v1/auth/permissions/list`
**响应参数**：data 为 PermissionEntity 数组（字段见 API-026，无 children）。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    { "id": 1, "permName": "用户管理", "permCode": "user:manage", "permType": 1, "parentId": 0, "status": 0 }
  ],
  "timestamp": 1723000000000
}
```
**错误码**：401（未授权）

### 5.28 获取权限详情（API-028）
**接口**：`GET /api/v1/auth/permissions/{id}`
**功能描述**：按权限 ID 获取权限详细信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 权限 ID |
**请求示例**：`GET /api/v1/auth/permissions/1`
**响应参数**：data 为 PermissionEntity；权限不存在时返回 code=404、message=权限不存在。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { "id": 1, "permName": "用户管理", "permCode": "user:manage", "permType": 1, "parentId": 0, "status": 0 },
  "timestamp": 1723000000000
}
```
**错误码**：404（权限不存在）、401（未授权）

### 5.29 创建权限（API-029）
**接口**：`POST /api/v1/auth/permissions`
**功能描述**：创建新的权限点；permCode 全局唯一；创建成功返回 HTTP 201。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**（body 为 PermissionEntity 核心字段）：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| permName | string | 是 | body | 权限名称 |
| permCode | string | 是 | body | 权限编码（全局唯一） |
| permType | int | 是 | body | 类型（1-菜单，2-按钮，3-API） |
| parentId | long | 否 | body | 父权限 ID（顶级为 0） |
| path/component/icon | string | 否 | body | 前端路由/组件/图标 |
| sortOrder | int | 否 | body | 排序号 |
| status | int | 否 | body | 状态（0-正常） |
**请求示例**：
```json
{ "permName": "删除用户", "permCode": "user:delete", "permType": 2, "parentId": 1, "sortOrder": 1 }
```
**响应参数**：data 为创建后的 PermissionEntity。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { "id": 3, "permName": "删除用户", "permCode": "user:delete", "permType": 2, "parentId": 1, "status": 0 },
  "timestamp": 1723000000000
}
```
**错误码**：409（权限编码重复）、400（参数错误）、401（未授权）

### 5.30 更新权限（API-030）
**接口**：`PUT /api/v1/auth/permissions/{id}`
**功能描述**：按权限 ID 更新权限信息。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
| Content-Type | string | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 权限 ID |
| permName | string | 否 | body | 权限名称 |
| permCode | string | 否 | body | 权限编码 |
| permType | int | 否 | body | 类型 |
| parentId | long | 否 | body | 父权限 ID |
| sortOrder | int | 否 | body | 排序号 |
| status | int | 否 | body | 状态 |
**请求示例**：
```json
{ "permName": "删除用户（物理）", "sortOrder": 2 }
```
**响应参数**：data 为更新后的 PermissionEntity。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": { "id": 3, "permName": "删除用户（物理）", "permCode": "user:delete", "permType": 2, "parentId": 1, "status": 0 },
  "timestamp": 1723000000000
}
```
**错误码**：404（权限不存在）、409（权限编码冲突）、400（参数错误）、401（未授权）

### 5.31 删除权限（API-031）
**接口**：`DELETE /api/v1/auth/permissions/{id}`
**功能描述**：逻辑删除权限；若权限已被角色关联则阻止删除。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| id | long | 是 | path | 权限 ID |
**请求示例**：`DELETE /api/v1/auth/permissions/3`
**响应参数**：无（data 为 null）。
**响应示例**：
```json
{ "code": 200, "message": "操作成功", "data": null, "timestamp": 1723000000000 }
```
**错误码**：409（权限已被角色关联）、404（权限不存在）、401（未授权）

### 5.32 企业服务健康检查（API-032）
**接口**：`GET /api/v1/biz/health`
**功能描述**：返回企业服务（骨架）运行状态、服务名、版本与时间戳。
**请求头**：无（经网关访问需携带 Bearer Token，直连服务端口 9200 免认证）。
**请求参数**：无。
**请求示例**：`GET /api/v1/biz/health`
**响应参数**（data 为 Map）：service、status、version、timestamp（同 API-012）。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-biz-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": "2026-08-07T08:00:00.000Z"
  },
  "timestamp": 1723000000000
}
```
**错误码**：500（服务异常）、503（服务不可用）

### 5.33 系统服务健康检查（API-033）
**接口**：`GET /api/v1/system/health`
**功能描述**：返回系统服务（骨架）运行状态、服务名、版本与时间戳。
**请求头**：无（经网关访问需携带 Bearer Token，直连服务端口 9400 免认证）。
**请求参数**：无。
**请求示例**：`GET /api/v1/system/health`
**响应参数**（data 为 Map）：service、status、version、timestamp（同 API-012，timestamp 为毫秒时间戳）。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-system-service",
    "status": "UP",
    "version": "0.0.1-SNAPSHOT",
    "timestamp": 1723000000000
  },
  "timestamp": 1723000000000
}
```
**错误码**：500（服务异常）、503（服务不可用）

## 6. 状态码映射

| HTTP 状态码 | 业务码 | 场景 |
| --- | --- | --- |
| 200 | 200 | 成功（含逻辑删除、登出等幂等操作） |
| 201 | 200 | 创建权限成功（@ResponseStatus CREATED，body 内 code 仍为 200） |
| 400 | 400 / AUTH-0011 / AUTH-0012 / AUTH-0019 / AUTH-0020 / AUTH-0021 / AUTH-0022 / AUTH-0023 / AUTH-0024 / AUTH-0032 / AUTH-0033 | 参数校验失败、验证码错误/过期、模式无效、原密码错误等 |
| 401 | 401 / AUTH-0001~0005 / AUTH-0010 / AUTH-0013 / AUTH-0026 | 未认证、Token 过期/无效/黑名单、凭据错误、被踢下线 |
| 403 | 403 / AUTH-0006~0009 / AUTH-0014 / AUTH-0015 / AUTH-0016 / AUTH-0030 / AUTH-0031 | 账号/租户状态异常、权限不足、需邮箱验证、账号未完善 |
| 404 | 404 / AUTH-0017 / AUTH-0018 / AUTH-0027 | 用户/角色/资源不存在、第三方账号未绑定 |
| 409 | 409 / AUTH-0028 / AUTH-0029 | 手机号/第三方账号已绑定、资源冲突（编码重复、关联阻止删除） |
| 429 | 429 / AUTH-0025 | 验证码发送过于频繁 |
| 500 | 500 | 系统内部错误（全局兜底，不泄露堆栈） |
| 503 | 503 | 服务暂不可用 |

## 7. 限流策略

- **验证码发送限频**：同一目标（手机号/邮箱）60 秒内禁止重复发送（`VERIFICATION_CODE_SEND_INTERVAL`，默认 60 秒），超限返回 AUTH-0025（429）；验证码有效期 5 分钟（`VERIFICATION_CODE_EXPIRE_SECONDS`，默认 300 秒），一次性失效。
- **网关级限流**：本版本网关未配置 RequestRateLimiter 限流器，登录/注册接口建议客户端做本地防抖与失败退避；后续版本引入 Spring Cloud Gateway RequestRateLimiter 对登录/验证码等敏感端点按 IP/用户限流。
- **登录失败策略**：登录失败统一返回 AUTH-0010（用户名或密码错误），不泄露具体原因，防账号枚举；失败事件记录登录日志供审计。

## 8. 示例代码

### 8.1 Flutter（dio）登录调用示例
```dart
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  baseUrl: 'http://localhost:9000',
  connectTimeout: const Duration(seconds: 10),
));

Future<void> login() async {
  final response = await dio.post(
    '/api/v1/auth/login',
    data: {
      'loginMode': 'USERNAME_PASSWORD',
      'loginName': 'admin',
      'password': 'password123',
      'tenantCode': 'default',
      'clientType': 'WINDOWS',
    },
  );
  // response.data: { code, message, data: { accessToken, refreshToken, ... }, timestamp }
  final accessToken = response.data['data']['accessToken'];
  // 客户端应将 accessToken / refreshToken 通过 flutter_secure_storage_x 安全存储，
  // 并在后续请求中携带 Authorization: Bearer $accessToken；
  // 收到 401 时用 refreshToken 调用 /api/v1/auth/refresh 自动续期并重试。
}
```

### 8.2 curl 调用示例
```bash
# 1. 登录获取 Token
curl -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"loginMode":"USERNAME_PASSWORD","loginName":"admin","password":"password123","tenantCode":"default","clientType":"WINDOWS"}'

# 2. 携带 Token 分页查询用户（网关透传 X-Tenant-Id 由认证服务处理）
curl -X GET "http://localhost:9000/api/v1/auth/users?page=1&pageSize=10" \
  -H "Authorization: Bearer {accessToken}"

# 3. 刷新 Token
curl -X POST http://localhost:9000/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refreshToken":"{refreshToken}"}'
```

### 8.3 错误响应示例（网关拦截 401）
```json
{ "code": 401, "message": "令牌已过期，请刷新令牌", "data": null, "timestamp": 1723000000000 }
```

---

# 版本 v0.2.5：部署资产集中化（2026-08-09）

> **本版本（v0.2.5）无新增接口、无接口变更、无接口删除。**
>
> 本版本需求（F-001~F-007）全部为工程目录结构与构建配置调整：新建根目录 `deploy` 作为最终构建产物唯一落点、后端 jar 包与客户端安装产物统一输出到 deploy、`env.json`/`env.example.json` 迁移、`deploy/scripts` 子目录建立及 scripts 下全部 .sh/.ps1 脚本迁移。以上均为构建配置、部署脚本与环境配置的调整，**不涉及任何 HTTP 接口**。
>
> 现有接口体系保持本文档上文（v0.0.1）定义的 **33 个接口**（API-001~API-033：认证管理 11 个、用户管理 6 个、角色管理 7 个、权限管理 6 个、健康检查 3 个）不变，网关路由、认证鉴权、统一响应体（ApiResult）等接口契约均不受影响。

## 1. 接口清单

本版本新增接口：**无**。

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- | --- |
| （无新增） | — | — | — | 本版本无新增接口，完整接口清单见本文档上文 v0.0.1 章节 | — |

## 2. 接口版本策略

- 沿用现有策略：所有接口统一前缀 `/api/v1/{module}/{resource}`，`{module}` 为业务模块标识（auth/biz/system），`v1` 为 API 主版本号。
- 本版本未新增端点、未修改既有端点语义，`v1` 版本号保持不变，无兼容性影响。
- 在线文档：各服务 SpringDoc OpenAPI 3 生成的 Swagger UI（`/swagger-ui.html`、`/v3/api-docs/**`）继续可用，接口文档内容与本版本无关。

## 3. 认证鉴权机制

- 本版本不调整任何认证鉴权机制，沿用现有 JWT RS256 双 Token 机制、网关 AuthFilter 9 步校验、白名单端点与 Header 透传规则（详见本文档上文第 3 章）。
- 构建与部署脚本迁移至 `deploy/scripts` 后，脚本中的密钥环境变量注入（RSA_PRIVATE_KEY/RSA_PUBLIC_KEY 等）与 jar 包路径引用同步适配，认证服务功能不受影响。

## 4. 通用错误码定义

- 本版本无新增错误码，统一错误码体系（10 个基础错误码 + 23 个认证授权错误码）保持不变，详见本文档上文第 4 章。

## 5. 接口详细定义

本版本无新增接口，无接口详细定义需要补充。全部接口详细定义见本文档上文第 5 章。

## 6. 状态码映射

- 本版本无变更，HTTP 状态码与业务错误码映射关系与本文档上文第 6 章一致。

## 7. 限流策略

- 本版本无变更，验证码发送 60 秒频率限制等既有限流策略保持与本文档上文第 7 章一致；接口级限流（RequestRateLimiter）仍按后续版本规划。

## 8. 示例代码

- 本版本无新增接口，客户端调用示例与本文档上文第 8 章一致；部署脚本迁移至 `deploy/scripts` 后，脚本中调用健康检查接口（如 `/api/v1/auth/health`）的地址引用保持不变。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->

---

# 版本 v0.2.6：服务启动修复与 API 回归闭环（2026-08-09）

**版本号**：v0.2.6
**日期**：2026-08-09
**编写人**：TL

## 0. 版本变更说明（v0.2.6）

**本版本（v0.2.6）无新增接口、无接口变更、无接口删除。**

v0.2.6 为"部署与配置缺陷修复"工程版本（需求来源：docs/cso-v0.2.5/regression-api-test.md 记录的回归测试问题），变更范围如下（详见 PRD v0.2.6 与 SAD v0.2.6）：
- **F-001 引入 bootstrap 配置引导依赖**：全项目 pom 引入 `spring-cloud-starter-bootstrap`，恢复 bootstrap.yml（含 Nacos discovery/config server-addr）在 Spring Boot 3.x 下的加载（SAD ADR-014）；
- **F-002 修复 RSA 密钥格式契约**：deploy-rsa-keygen.ps1 生成/env.json 注入的 `RSA_PUBLIC_KEY`、`RSA_PRIVATE_KEY` 由 PEM 整体 Base64 统一为 DER 编码单行 Base64，与 Java 端 RsaKeyConfig 解码契约严格一致（SAD ADR-015）；
- **F-003~F-005 验证闭环**：4 服务启动与健康检查验证、v0.0.1 基线接口回归（TC-001~045）、既有接口契约无回归保障（TC-046~051）。

以上变更均为**构建/依赖配置与密钥格式契约类修复**，**不触碰接口层（Controller/DTO/响应体）**，对外接口契约 **API-001~API-033 完整保留，客户端运行时代码零改动**（PRD v0.2.6 F-005 与验收标准第 6 条）。本版本接口设计完全沿用本文档上文（v0.0.1 基线，v0.2.5 确认无变更后继续沿用）。

## 1. 接口清单

> 沿用本文档上文（v0.0.1）第 1 章接口清单，本版本无新增/变更/删除，共 **33 个接口**。
> 全部接口统一返回 `ApiResult<T>` 结构（code/message/data/timestamp），分页接口 data 为 `PageResult<T>`。
> 网关统一入口 `http://{gateway-host}:9000`，服务间通过 Nacos 注册发现路由。

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- | --- |
| API-001 | 用户登录 | POST | /api/v1/auth/login | 4 种登录模式（用户名密码/手机验证码/OAuth），签发双 Token | 白名单 |
| API-002 | 用户注册 | POST | /api/v1/auth/register | 5 种注册策略，返回用户信息与双 Token | 白名单 |
| API-003 | 刷新 Token | POST | /api/v1/auth/refresh | Refresh Token 轮换，旧 Token 入黑名单 | 白名单 |
| API-004 | 用户登出 | POST | /api/v1/auth/logout | Token 入黑名单并清除登录态，幂等 | 需认证 |
| API-005 | 强制踢人 | POST | /api/v1/auth/kickout | 管理员踢指定端或所有端 | 需认证 |
| API-006 | 修改密码 | PUT | /api/v1/auth/password/change | 校验旧密码，成功后清除全部登录态 | 需认证 |
| API-007 | 密码找回-发送验证码 | POST | /api/v1/auth/password/forgot/send-code | 手机短信或邮箱发送重置验证码 | 白名单 |
| API-008 | 密码找回-重置密码 | POST | /api/v1/auth/password/forgot/reset | 校验验证码后重置密码 | 白名单 |
| API-009 | 修改手机号 | PUT | /api/v1/auth/phone/change | 原手机短信验证码或邮箱验证码校验 | 需认证 |
| API-010 | 完善账号信息 | PUT | /api/v1/auth/account/settlement | 两步注册第二步，补全登录名/密码/手机号 | 需认证 |
| API-011 | 发送验证码 | POST | /api/v1/auth/verification-code/send | 注册/登录/重置密码/换绑手机用途，60 秒限频 | 白名单 |
| API-012 | 认证服务健康检查 | GET | /api/v1/auth/health | 服务名/状态/版本/时间戳 | 白名单 |
| API-013 | 分页查询用户列表 | GET | /api/v1/auth/users | 按租户分页，支持关键字模糊搜索 | 需认证 |
| API-014 | 获取用户详情 | GET | /api/v1/auth/users/{id} | 返回用户信息及角色编码列表 | 需认证 |
| API-015 | 更新用户信息 | PUT | /api/v1/auth/users/{id} | 更新姓名/手机号/邮箱（不含密码） | 需认证 |
| API-016 | 逻辑删除用户 | DELETE | /api/v1/auth/users/{id} | 标记 deleted=1 | 需认证 |
| API-017 | 分配用户角色 | PUT | /api/v1/auth/users/{id}/roles | 全量更新（先删后插） | 需认证 |
| API-018 | 变更用户状态 | PUT | /api/v1/auth/users/{id}/status | 0-正常/1-停用/2-锁定/3-封禁 | 需认证 |
| API-019 | 分页查询角色列表 | GET | /api/v1/auth/roles | 按租户分页 | 需认证 |
| API-020 | 查询所有角色 | GET | /api/v1/auth/roles/list | 按租户查询，不分页 | 需认证 |
| API-021 | 获取角色详情 | GET | /api/v1/auth/roles/{id} | 按 ID 查询角色 | 需认证 |
| API-022 | 创建角色 | POST | /api/v1/auth/roles | 角色编码租户内唯一 | 需认证 |
| API-023 | 更新角色 | PUT | /api/v1/auth/roles/{id} | 更新角色信息 | 需认证 |
| API-024 | 删除角色 | DELETE | /api/v1/auth/roles/{id} | 已被用户分配则阻止删除 | 需认证 |
| API-025 | 分配角色权限 | PUT | /api/v1/auth/roles/{id}/permissions | 全量更新权限关联（先删后插） | 需认证 |
| API-026 | 树形权限列表 | GET | /api/v1/auth/permissions/tree | 按 parentId 自关联树形结构 | 需认证 |
| API-027 | 所有权限列表 | GET | /api/v1/auth/permissions/list | 平铺列表 | 需认证 |
| API-028 | 获取权限详情 | GET | /api/v1/auth/permissions/{id} | 按 ID 查询权限 | 需认证 |
| API-029 | 创建权限 | POST | /api/v1/auth/permissions | permCode 全局唯一，返回 201 | 需认证 |
| API-030 | 更新权限 | PUT | /api/v1/auth/permissions/{id} | 更新权限信息 | 需认证 |
| API-031 | 删除权限 | DELETE | /api/v1/auth/permissions/{id} | 已被角色关联则阻止删除 | 需认证 |
| API-032 | 企业服务健康检查 | GET | /api/v1/biz/health | 企业服务骨架探活 | 需认证（见备注） |
| API-033 | 系统服务健康检查 | GET | /api/v1/system/health | 系统服务骨架探活 | 需认证（见备注） |

> 备注：当前网关白名单仅配置了 `/api/v1/auth/health`（API-012）；`/api/v1/biz/health` 与 `/api/v1/system/health` 未加入白名单，直连服务端口可免认证访问，经网关访问需携带有效 Token（后续版本可将其加入白名单，与 PRD 目标对齐）。本版本维持该现状，不做变更。

## 2. 接口版本策略

沿用本文档上文（v0.0.1）第 2 章，本版本无变更：
- **URL 版本路径**：所有接口统一前缀 `/api/v1/{module}/{resource}`，`v1` 为 API 主版本号。
- **网关路由**：`/api/v1/auth/**` → `cloudoffice-auth-service`（:9100）、`/api/v1/biz/**` → `cloudoffice-biz-service`（:9200）、`/api/v1/system/**` → `cloudoffice-system-service`（:9400）。
- **兼容策略**：v1 内保持向后兼容；本版本无任何端点新增、删除或语义变更，契约 API-001~API-033 完整保留。
- **在线文档**：SpringDoc OpenAPI 3 Swagger UI（`/swagger-ui.html`、`/v3/api-docs/**`，网关白名单放行）。

## 3. 认证鉴权机制

沿用本文档上文（v0.0.1）第 3 章，本版本无变更：
- **认证方式**：JWT RS256（RSA 2048 位非对称签名）双 Token 机制（Access 2h + Refresh 7d，刷新轮换防重放）。
- **Token 传递**：`Authorization: Bearer {accessToken}` 请求头传递。
- **网关全局认证（9 步校验）**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单校验 → 登录态校验 → 账号状态校验 → 租户状态校验 → Header 透传（X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions）。
- **白名单端点**：`/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`、`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`、`/webjars/**`。
- **v0.2.6 特别说明（密钥契约）**：本版本修复 RSA 密钥格式契约（SAD ADR-015）——`RSA_PUBLIC_KEY`/`RSA_PRIVATE_KEY` 统一为 DER 编码单行 Base64，由 deploy-rsa-keygen.ps1 生成并注入 deploy/env.json；该修复仅影响服务端密钥加载配置，**不改变 Token 结构、验签流程与接口请求/响应契约**，客户端无需任何修改。

## 4. 通用错误码定义

沿用本文档上文（v0.0.1）第 4 章，本版本无变更：
- 统一响应体 `ApiResult<T>`（code/message/data/timestamp），错误码枚举定义于 `cloudoffice-common` 的 `ErrorCode`。

### 4.1 基础错误码（HTTP 状态码映射）
| 错误码 | 说明 |
| --- | --- |
| 200 | 操作成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，请先登录 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 405 | 请求方法不支持 |
| 409 | 资源冲突 |
| 429 | 请求频率过高 |
| 500 | 系统繁忙，请稍后重试 |
| 503 | 服务暂不可用 |

### 4.2 认证授权错误码（业务编码 AUTH-XXXX，共 23 个）
| 业务编码 | 状态码 | 说明 |
| --- | --- | --- |
| AUTH-0001 | 401 | 令牌已过期，请刷新令牌 |
| AUTH-0002 | 401 | 令牌无效 |
| AUTH-0003 | 401 | 令牌已被吊销 |
| AUTH-0004 | 401 | 刷新令牌已过期，请重新登录 |
| AUTH-0005 | 401 | 刷新令牌无效 |
| AUTH-0006 | 403 | 账号已被禁用 |
| AUTH-0007 | 403 | 账号已被锁定 |
| AUTH-0008 | 403 | 账号已被封禁 |
| AUTH-0009 | 403 | 账号已过期 |
| AUTH-0010 | 401 | 用户名或密码错误 |
| AUTH-0011 | 400 | 验证码错误 |
| AUTH-0012 | 400 | 无效的客户端类型 |
| AUTH-0013 | 401 | 账号已在其他设备登录，您已被踢下线 |
| AUTH-0014 | 403 | 租户已被禁用 |
| AUTH-0015 | 403 | 租户已过期 |
| AUTH-0016 | 403 | 权限不足 |
| AUTH-0017 | 404 | 角色不存在 |
| AUTH-0018 | 404 | 用户不存在 |
| AUTH-0019 | 400 | 验证码已过期 |
| AUTH-0020 | 400 | 密码重置令牌无效 |
| AUTH-0021 | 400 | 密码重置令牌已过期 |
| AUTH-0022 | 409 | 用户名已存在 |
| AUTH-0023 | 409 | 手机号已被注册 |

## 5. 接口详细定义

**本版本（v0.2.6）无新增接口**，API-001~API-033 的接口详细定义（请求头/请求参数/请求示例/响应参数/响应示例/错误码）**完全沿用本文档上文（v0.0.1）第 5 章**，本版本不做重复编写与任何变更。

## 6. 状态码映射

沿用本文档上文（v0.0.1）第 6 章，本版本无变更：
- HTTP 状态码与业务错误码映射关系保持不变（200/400/401/403/404/405/409/429/500/503 + AUTH-0001~0023）。

## 7. 限流策略

沿用本文档上文（v0.0.1）第 7 章，本版本无变更：
- 验证码发送类接口（API-007/API-011）60 秒发送频率限制、5 分钟有效期、错误次数限制防暴力尝试；
- 其余接口按业务规则限流，本版本不引入网关 RequestRateLimiter（规划后续版本）。

## 8. 示例代码

沿用本文档上文（v0.0.1）第 8 章示例代码（curl/Java/Flutter dio 调用示例），本版本无变更。

---

**契约一致性说明（v0.2.6）**：本版本修复范围严格限定于构建/依赖配置（bootstrap 依赖）与密钥格式契约（RSA DER 单行 Base64），未触碰任何 Controller/DTO/响应体；API 契约静态（本文档与主文档逐项核对）与动态（cso-api-test-v0.0.1.py TC-001~045、cso-api-test-v0.2.5.py TC-046~051 回归）双重确认无回归。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->

---

# 版本 v0.2.7：部署脚本体系重构与仓库清洁度治理（2026-08-10）

**版本号**：v0.2.7
**日期**：2026-08-10
**编写人**：TL

## 0. 版本变更说明（v0.2.7）

**本版本（v0.2.7）无新增接口、无接口变更、无接口删除。**

v0.2.7 为"部署脚本体系重构与仓库清洁度治理"工程版本（需求来源：用户输入——检查并重构 `deploy\scripts` 目录下所有脚本，实现环境可用性检查、基础设施一键启动、后端服务按序一键启动三大能力，并治理 `.gitignore` 排除临时/中间文件），变更范围如下（详见 PRD v0.2.7 与 SAD v0.2.7 ADR-016）：
- **F-001 env.json 配置加载统一**：新增 `load-env.ps1` / `load-env.sh` 统一从 `deploy/env.json` 加载环境配置（NACOS_ADDR/NACOS_HOME/DB_*/REDIS_*/RSA 密钥等），脚本内不硬编码环境地址与凭据；
- **F-002~F-005 环境可用性检查**：`deploy-check-env.ps1` / `.sh` 基于 env.json 检查 JDK（命令 + JAVA_HOME + 版本 21）、MariaDB（命令/服务/进程 + SELECT 1）、Redis（命令/服务/进程 + redis-cli ping）、Nacos（NACOS_HOME/startup 脚本 + HTTP 探测）可用性；
- **F-006~F-007 基础设施运行状态检查与一键启动**：`deploy-start-services.ps1` / `.sh` 检测未运行的 MariaDB/Redis/Nacos 并自动启动（系统服务优先，其次可执行文件/NACOS_HOME 启动脚本），启动后再次探测确认；
- **F-008~F-009 后端服务按序一键启动**：`deploy-start-all.ps1` / `.sh` 按 gateway → auth → biz → system 顺序一键启动 4 个后端服务，逐服务健康确认；单服务启动脚本（deploy-start-gateway/auth/biz/system）保持可用；
- **F-010~F-011 脚本契约与输出规范**：移除硬编码默认地址与弃用脚本残留（deploy-env.ps1 / deploy-env-template.ps1），.sh 与 .ps1 密钥输出契约对齐（DER 单行 Base64，不破坏 ADR-015），输出分级（通过/警告/失败）与退出码约定（失败非零）统一；
- **F-012 .gitignore 临时/中间文件治理**：在 `.gitignore` 中补充生成、测试、调试过程中的临时/中间文件排除规则（JVM 调试产物、测试缓存、构建中间产物、工具残留等）。

以上变更均为**部署运维层脚本重构与仓库治理类工作**，**不触碰接口层（Controller/DTO/响应体）**，对外接口契约 **API-001~API-033 完整保留，客户端运行时代码零改动**（PRD v0.2.7 第 6 章数据需求明确：不新增业务数据表、不修改既有表结构；SAD ADR-016 明确：仅涉及部署运维层，不改变后端架构、接口契约与数据库设计）。本版本接口设计完全沿用主文档 `docs/cso-api.md`（v0.0.1 基线，v0.2.5 / v0.2.6 确认无变更后继续沿用）。

## 1. 接口清单

> 沿用本文档上文（v0.0.1）第 1 章接口清单，本版本无新增/变更/删除，共 **33 个接口**。
> 全部接口统一返回 `ApiResult<T>` 结构（code/message/data/timestamp），分页接口 data 为 `PageResult<T>`。
> 网关统一入口 `http://{gateway-host}:9000`，服务间通过 Nacos 注册发现路由。

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- | --- |
| API-001 | 用户登录 | POST | /api/v1/auth/login | 4 种登录模式（用户名密码/手机验证码/OAuth），签发双 Token | 白名单 |
| API-002 | 用户注册 | POST | /api/v1/auth/register | 5 种注册策略，返回用户信息与双 Token | 白名单 |
| API-003 | 刷新 Token | POST | /api/v1/auth/refresh | Refresh Token 轮换，旧 Token 入黑名单 | 白名单 |
| API-004 | 用户登出 | POST | /api/v1/auth/logout | Token 入黑名单并清除登录态，幂等 | 需认证 |
| API-005 | 强制踢人 | POST | /api/v1/auth/kickout | 管理员踢指定端或所有端 | 需认证 |
| API-006 | 修改密码 | PUT | /api/v1/auth/password/change | 校验旧密码，成功后清除全部登录态 | 需认证 |
| API-007 | 密码找回-发送验证码 | POST | /api/v1/auth/password/forgot/send-code | 手机短信或邮箱发送重置验证码 | 白名单 |
| API-008 | 密码找回-重置密码 | POST | /api/v1/auth/password/forgot/reset | 校验验证码后重置密码 | 白名单 |
| API-009 | 修改手机号 | PUT | /api/v1/auth/phone/change | 原手机短信验证码或邮箱验证码校验 | 需认证 |
| API-010 | 完善账号信息 | PUT | /api/v1/auth/account/settlement | 两步注册第二步，补全登录名/密码/手机号 | 需认证 |
| API-011 | 发送验证码 | POST | /api/v1/auth/verification-code/send | 注册/登录/重置密码/换绑手机用途，60 秒限频 | 白名单 |
| API-012 | 认证服务健康检查 | GET | /api/v1/auth/health | 服务名/状态/版本/时间戳 | 白名单 |
| API-013 | 分页查询用户列表 | GET | /api/v1/auth/users | 按租户分页，支持关键字模糊搜索 | 需认证 |
| API-014 | 获取用户详情 | GET | /api/v1/auth/users/{id} | 返回用户信息及角色编码列表 | 需认证 |
| API-015 | 更新用户信息 | PUT | /api/v1/auth/users/{id} | 更新姓名/手机号/邮箱（不含密码） | 需认证 |
| API-016 | 逻辑删除用户 | DELETE | /api/v1/auth/users/{id} | 标记 deleted=1 | 需认证 |
| API-017 | 分配用户角色 | PUT | /api/v1/auth/users/{id}/roles | 全量更新（先删后插） | 需认证 |
| API-018 | 变更用户状态 | PUT | /api/v1/auth/users/{id}/status | 0-正常/1-停用/2-锁定/3-封禁 | 需认证 |
| API-019 | 分页查询角色列表 | GET | /api/v1/auth/roles | 按租户分页 | 需认证 |
| API-020 | 查询所有角色 | GET | /api/v1/auth/roles/list | 按租户查询，不分页 | 需认证 |
| API-021 | 获取角色详情 | GET | /api/v1/auth/roles/{id} | 按 ID 查询角色 | 需认证 |
| API-022 | 创建角色 | POST | /api/v1/auth/roles | 角色编码租户内唯一 | 需认证 |
| API-023 | 更新角色 | PUT | /api/v1/auth/roles/{id} | 更新角色信息 | 需认证 |
| API-024 | 删除角色 | DELETE | /api/v1/auth/roles/{id} | 已被用户分配则阻止删除 | 需认证 |
| API-025 | 分配角色权限 | PUT | /api/v1/auth/roles/{id}/permissions | 全量更新权限关联（先删后插） | 需认证 |
| API-026 | 树形权限列表 | GET | /api/v1/auth/permissions/tree | 按 parentId 自关联树形结构 | 需认证 |
| API-027 | 所有权限列表 | GET | /api/v1/auth/permissions/list | 平铺列表 | 需认证 |
| API-028 | 获取权限详情 | GET | /api/v1/auth/permissions/{id} | 按 ID 查询权限 | 需认证 |
| API-029 | 创建权限 | POST | /api/v1/auth/permissions | permCode 全局唯一，返回 201 | 需认证 |
| API-030 | 更新权限 | PUT | /api/v1/auth/permissions/{id} | 更新权限信息 | 需认证 |
| API-031 | 删除权限 | DELETE | /api/v1/auth/permissions/{id} | 已被角色关联则阻止删除 | 需认证 |
| API-032 | 企业服务健康检查 | GET | /api/v1/biz/health | 企业服务骨架探活 | 需认证（见备注） |
| API-033 | 系统服务健康检查 | GET | /api/v1/system/health | 系统服务骨架探活 | 需认证（见备注） |

> 备注：当前网关白名单仅配置了 `/api/v1/auth/health`（API-012）；`/api/v1/biz/health` 与 `/api/v1/system/health` 未加入白名单，直连服务端口可免认证访问，经网关访问需携带有效 Token（后续版本可将其加入白名单，与 PRD 目标对齐）。本版本维持该现状，不做变更。

## 2. 接口版本策略

沿用本文档上文（v0.0.1）第 2 章，本版本无变更：
- **URL 版本路径**：所有接口统一前缀 `/api/v1/{module}/{resource}`，`v1` 为 API 主版本号。
- **网关路由**：`/api/v1/auth/**` → `cloudoffice-auth-service`（:9100）、`/api/v1/biz/**` → `cloudoffice-biz-service`（:9200）、`/api/v1/system/**` → `cloudoffice-system-service`（:9400）。
- **兼容策略**：v1 内保持向后兼容；本版本无任何端点新增、删除或语义变更，契约 API-001~API-033 完整保留。
- **在线文档**：SpringDoc OpenAPI 3 Swagger UI（`/swagger-ui.html`、`/v3/api-docs/**`，网关白名单放行）。

## 3. 认证鉴权机制

沿用本文档上文（v0.0.1）第 3 章，本版本无变更：
- **认证方式**：JWT RS256（RSA 2048 位非对称签名）双 Token 机制（Access 2h + Refresh 7d，刷新轮换防重放）。
- **Token 传递**：`Authorization: Bearer {accessToken}` 请求头传递。
- **网关全局认证（9 步校验）**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验 → Redis 黑名单校验 → 登录态校验 → 账号状态校验 → 租户状态校验 → Header 透传（X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions）。
- **白名单端点**：`/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`、`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`、`/webjars/**`。
- **v0.2.7 特别说明（脚本契约）**：本版本重构部署脚本体系，`deploy-start-all` / `deploy-start-{svc}` 启动后端服务后通过 HTTP 探测健康检查接口（如 `/api/v1/auth/health`）确认服务就绪；脚本仅调用既有健康检查接口做部署确认，**不新增、不修改任何认证鉴权机制与接口请求/响应契约**，客户端无需任何修改。

## 4. 通用错误码定义

沿用本文档上文（v0.0.1）第 4 章，本版本无变更：
- 统一响应体 `ApiResult<T>`（code/message/data/timestamp），错误码枚举定义于 `cloudoffice-common` 的 `ErrorCode`。

### 4.1 基础错误码（HTTP 状态码映射）
| 错误码 | 说明 |
| --- | --- |
| 200 | 操作成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，请先登录 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 405 | 请求方法不支持 |
| 409 | 资源冲突 |
| 429 | 请求频率过高 |
| 500 | 系统繁忙，请稍后重试 |
| 503 | 服务暂不可用 |

### 4.2 认证授权错误码（业务编码 AUTH-XXXX，共 23 个）
| 业务编码 | 状态码 | 说明 |
| --- | --- | --- |
| AUTH-0001 | 401 | 令牌已过期，请刷新令牌 |
| AUTH-0002 | 401 | 令牌无效 |
| AUTH-0003 | 401 | 令牌已被吊销 |
| AUTH-0004 | 401 | 刷新令牌已过期，请重新登录 |
| AUTH-0005 | 401 | 刷新令牌无效 |
| AUTH-0006 | 403 | 账号已被禁用 |
| AUTH-0007 | 403 | 账号已被锁定 |
| AUTH-0008 | 403 | 账号已被封禁 |
| AUTH-0009 | 403 | 账号已过期 |
| AUTH-0010 | 401 | 用户名或密码错误 |
| AUTH-0011 | 400 | 验证码错误 |
| AUTH-0012 | 400 | 无效的客户端类型 |
| AUTH-0013 | 401 | 账号已在其他设备登录，您已被踢下线 |
| AUTH-0014 | 403 | 租户已被禁用 |
| AUTH-0015 | 403 | 租户已过期 |
| AUTH-0016 | 403 | 权限不足 |
| AUTH-0017 | 404 | 角色不存在 |
| AUTH-0018 | 404 | 用户不存在 |
| AUTH-0019 | 400 | 验证码已过期 |
| AUTH-0020 | 400 | 密码重置令牌无效 |
| AUTH-0021 | 400 | 密码重置令牌已过期 |
| AUTH-0022 | 409 | 用户名已存在 |
| AUTH-0023 | 409 | 手机号已被注册 |

## 5. 接口详细定义

**本版本（v0.2.7）无新增接口**，API-001~API-033 的接口详细定义（请求头/请求参数/请求示例/响应参数/响应示例/错误码）**完全沿用本文档上文（v0.0.1）第 5 章**，本版本不做重复编写与任何变更。

## 6. 状态码映射

沿用本文档上文（v0.0.1）第 6 章，本版本无变更：
- HTTP 状态码与业务错误码映射关系保持不变（200/400/401/403/404/405/409/429/500/503 + AUTH-0001~0023）。

## 7. 限流策略

沿用本文档上文（v0.0.1）第 7 章，本版本无变更：
- 验证码发送类接口（API-007/API-011）60 秒发送频率限制、5 分钟有效期、错误次数限制防暴力尝试；
- 其余接口按业务规则限流，本版本不引入网关 RequestRateLimiter（规划后续版本）。

## 8. 示例代码

沿用本文档上文（v0.0.1）第 8 章示例代码（curl/Java/Flutter dio 调用示例），本版本无变更。

---

**契约一致性说明（v0.2.7）**：本版本变更范围严格限定于部署运维层脚本重构（load-env / deploy-check-env / deploy-start-services / deploy-start-all / deploy-start-{svc} / deploy-rsa-keygen 双平台对齐）与仓库治理（.gitignore 补充临时/中间文件排除规则），未触碰任何 Controller/DTO/响应体；API 契约 API-001~API-033 经本文档与主文档逐项核对静态确认无变更，动态回归由 v0.2.7 回归测试（既有接口回归）进一步确认无回归。

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->

---

# 版本 v0.2.8：cloudoffice-common 服务化改造与通用配置管理接口先行（2026-08-13）

**版本号**：v0.2.8
**日期**：2026-08-13
**编写人**：TL

## 0. 版本变更说明（v0.2.8）

**本版本（v0.2.8）新增接口 3 个（API-034~API-036），无接口变更、无接口删除。**

v0.2.8 为"cloudoffice-common 服务化改造与通用配置管理接口先行"版本（需求来源：URS v0.2.8 / PRD v0.2.8 / SAD v0.2.8 ADR-017/ADR-018/ADR-019），接口变更范围如下：

- **新增 common 服务健康检查接口（API-034）**：cloudoffice-common 服务化后提供与其他微服务一致的健康检查端点 `GET /api/v1/common/health`（白名单放行），供部署脚本（deploy-start-all）与监控探活；
- **新增通用配置管理查询接口（API-035 / API-036）**：在 cloudoffice-common 中新增通用配置管理查询接口 `GET /api/v1/common/config`（条件过滤 + 分页）与 `GET /api/v1/common/config/{serviceName}`（按微服务名称查询），统一管理 gateway/auth-service/biz-service/system-service/common 五个微服务在不同业务场景下的所有运行时配置（启动环境变量除外）；
- **网关路由扩展**：网关新增 `/api/v1/common/**` → `lb://cloudoffice-common`（Nacos 服务发现负载均衡）路由规则，使 common 健康检查与配置查询请求可经网关转发；
- **网关白名单扩展**：`/api/v1/common/health` 加入网关 AuthFilter 白名单（无 Token 访问）；`/api/v1/common/config` 与 `/api/v1/common/config/{serviceName}` 不在白名单中，需经 AuthFilter 认证（携带合法 Bearer Token）。

以上变更**仅新增接口与网关路由/白名单配置**，**不修改**既有 API-001~API-033 的接口契约；既有 33 个接口（认证管理 11 个、用户管理 6 个、角色管理 7 个、权限管理 6 个、健康检查 3 个）完整保留，客户端运行时代码零改动。本版本接口设计在沿用主文档 `docs/cso-api.md`（v0.0.1 基线）的基础上追加 common 服务接口。

> 配置数据存储结构（`t_common_config` 表）详见 DBD v0.2.8（`docs/cso-v0.2.8/cso-dbd-v0.2.8.md` 第 5.2.1 节），本接口文档中的配置项字段（ConfigItemVO）与之一一对应。

## 1. 接口清单

> 本版本共 **新增 3 个接口**，累计 **36 个接口**（API-001~API-036）。
> 全部接口统一返回 `ApiResult<T>` 结构（code/message/data/timestamp），分页接口 data 为 `PageResult<T>`。
> 网关统一入口 `http://{gateway-host}:9000`，服务间通过 Nacos 注册发现路由。

本版本新增接口：

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 | 认证 |
| --- | --- | --- | --- | --- | --- |
| API-034 | common 服务健康检查 | GET | /api/v1/common/health | 服务名/状态/版本/时间戳 | 白名单 |
| API-035 | 通用配置管理-查询配置列表 | GET | /api/v1/common/config | 按 serviceName/group/key 过滤查询配置项，支持分页 | 需认证 |
| API-036 | 通用配置管理-按微服务查询配置 | GET | /api/v1/common/config/{serviceName} | 按微服务名称查询该服务全部配置项（不分页） | 需认证 |

> 既有接口 API-001~API-033（认证管理 11 个、用户管理 6 个、角色管理 7 个、权限管理 6 个、健康检查 3 个）沿用主文档 `docs/cso-api.md`（v0.0.1 基线），本版本无变更，此处不重复列出。

## 2. 接口版本策略

沿用主文档（v0.0.1）策略，本版本扩展 common 模块路由：

- **URL 版本路径**：所有接口统一前缀 `/api/v1/{module}/{resource}`，`{module}` 为业务模块标识（auth/biz/system/common），`v1` 为 API 主版本号。
- **网关路由**：Spring Cloud Gateway 通过 Nacos 服务发现路由：
  - `/api/v1/auth/**` → `cloudoffice-auth-service`（:9100）
  - `/api/v1/biz/**` → `cloudoffice-biz-service`（:9200）
  - `/api/v1/system/**` → `cloudoffice-system-service`（:9400）
  - `/api/v1/common/**` → `cloudoffice-common`（:9300，**v0.2.8 新增**）
- **兼容策略**：v1 内保持向后兼容，新功能只允许新增端点与可选字段，禁止修改既有端点语义；本版本仅新增 common 模块端点，既有端点语义不变，契约 API-001~API-033 完整保留。
- **在线文档**：各服务通过 SpringDoc OpenAPI 3 生成 Swagger UI（`/swagger-ui.html`、`/v3/api-docs/**`，网关白名单放行），按模块分组在线调试；common 服务新增文档分组 `common`（v0.2.8 新增）。

## 3. 认证鉴权机制

沿用主文档（v0.0.1）第 3 章机制，本版本扩展 common 模块端点：

- **认证方式**：JWT RS256（RSA 2048 位非对称签名）双 Token 机制（Access 2h + Refresh 7d，刷新轮换防重放）。
- **Token 传递**：`Authorization: Bearer {accessToken}` 请求头传递。
- **网关全局认证（9 步校验）**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → tokenType 校验（必须为 access）→ Redis 黑名单校验 → 登录态校验 → 账号状态校验 → 租户状态校验 → 用户信息 Header 透传（X-User-Id/X-Tenant-Id/X-User-Name/X-Client-Type/X-Roles/X-Permissions）。
- **白名单端点（无需认证，网关直接放行）**：在既有白名单基础上，**v0.2.8 新增** `/api/v1/common/health`：
  `/api/v1/auth/login`、`/api/v1/auth/register`、`/api/v1/auth/refresh`、`/api/v1/auth/health`、`/api/v1/auth/verification-code/send`、`/api/v1/auth/password/forgot/send-code`、`/api/v1/auth/password/forgot/reset`、`/api/v1/common/health`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`、`/webjars/**`。
- **通用配置查询认证要求（v0.2.8 新增）**：`/api/v1/common/config` 与 `/api/v1/common/config/{serviceName}` **不在白名单中**，需经网关 AuthFilter 认证，调用方需携带合法 Bearer Token；未携带或 Token 无效由网关返回 401/403 错误响应。
- **Header 透传**：认证通过后网关向下游服务透传 `X-User-Id`、`X-Tenant-Id`、`X-User-Name`、`X-Client-Type`、`X-Roles`、`X-Permissions`（字段说明同主文档第 3 章）。
- **角色权限**：本版本 RBAC 接口级权限点校验（鉴权注解）随业务版本演进；通用配置查询接口本版本不设接口级权限点校验，后续增删改接口与后端管理界面迭代时补充。

## 4. 通用错误码定义

沿用主文档（v0.0.1）统一错误码体系，本版本**不新增业务错误码**，通用配置查询接口复用基础错误码与既有认证授权错误码。

### 4.1 基础错误码（HTTP 状态码映射）
| 错误码 | 说明 |
| --- | --- |
| 200 | 操作成功 |
| 400 | 请求参数错误 |
| 401 | 未授权，请先登录 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 405 | 请求方法不支持 |
| 409 | 资源冲突 |
| 429 | 请求频率过高 |
| 500 | 系统繁忙，请稍后重试 |
| 503 | 服务暂不可用 |

### 4.2 认证授权错误码（业务编码 AUTH-XXXX，沿用 v0.0.1 共 23 个）
| 业务编码 | 状态码 | 说明 |
| --- | --- | --- |
| AUTH-0001 | 401 | 令牌已过期，请刷新令牌 |
| AUTH-0002 | 401 | 令牌无效 |
| AUTH-0003 | 401 | 令牌已被吊销 |
| AUTH-0004 | 401 | 刷新令牌已过期，请重新登录 |
| AUTH-0005 | 401 | 刷新令牌无效 |
| AUTH-0006 | 403 | 账号已被禁用 |
| AUTH-0007 | 403 | 账号已被锁定 |
| AUTH-0008 | 403 | 账号已被封禁 |
| AUTH-0009 | 403 | 账号已过期 |
| AUTH-0010 | 401 | 用户名或密码错误 |
| AUTH-0011 | 400 | 验证码错误 |
| AUTH-0012 | 400 | 无效的客户端类型 |
| AUTH-0013 | 401 | 账号已在其他设备登录，您已被踢下线 |
| AUTH-0014 | 403 | 租户已被禁用 |
| AUTH-0015 | 403 | 租户已过期 |
| AUTH-0016 | 403 | 权限不足 |
| AUTH-0017 | 404 | 角色不存在 |
| AUTH-0018 | 404 | 用户不存在 |
| AUTH-0019 | 400 | 验证码已过期 |
| AUTH-0020 | 400 | 密码重置令牌无效 |
| AUTH-0021 | 400 | 密码重置令牌已过期 |
| AUTH-0022 | 400 | 原密码错误 |
| AUTH-0023 | 400 | 短信验证码无效 |
| AUTH-0024 | 400 | 短信验证码已过期 |
| AUTH-0025 | 429 | 验证码发送过于频繁 |
| AUTH-0026 | 401 | 第三方登录失败 |
| AUTH-0027 | 404 | 第三方账号未绑定 |
| AUTH-0028 | 409 | 手机号已被其他账号绑定 |
| AUTH-0029 | 409 | 第三方账号已被其他用户绑定 |
| AUTH-0030 | 403 | 需要邮箱验证 |
| AUTH-0031 | 403 | 账号信息未完善，请先补充资料 |
| AUTH-0032 | 400 | 无效的注册模式 |
| AUTH-0033 | 400 | 无效的登录模式 |

### 4.3 统一分页结构 PageResult<T>
```json
{ "records": [], "total": 0, "page": 1, "pageSize": 10 }
```

> 说明：通用配置查询接口不引入独立错误码段；当 `serviceName` 不在合法取值（gateway/auth-service/biz-service/system-service/common）范围内时返回 400（请求参数错误）；配置数据存储异常时返回 500（系统繁忙）；查询结果为空时返回 `code=200` 且 `data.records` 为空列表（非 500 错误）。

## 5. 接口详细定义

### 5.1 common 服务健康检查（API-034）
**接口**：`GET /api/v1/common/health`（白名单，无需认证）
**功能描述**：返回 common 服务运行状态、服务名、版本与时间戳，供部署脚本与监控探活。deploy-start-all 脚本启动 common 服务后经该端点做健康确认（HTTP 探测返回 200 视为就绪）。
**请求头**：无。
**请求参数**：无。
**请求示例**：`GET /api/v1/common/health`
**响应参数**（data 为 Map）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| service | string | 服务名（cloudoffice-common） |
| status | string | 状态（UP） |
| version | string | 版本号 |
| timestamp | string | 时间戳（ISO 格式） |
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "service": "cloudoffice-common",
    "status": "UP",
    "version": "0.2.8-SNAPSHOT",
    "timestamp": "2026-08-13T08:00:00.000Z"
  },
  "timestamp": 1723000000000
}
```
**错误码**：500（服务异常）、503（服务不可用）

### 5.2 通用配置管理-查询配置列表（API-035）
**接口**：`GET /api/v1/common/config`（需认证，非白名单）
**功能描述**：查询各微服务（gateway/auth-service/biz-service/system-service/common）的运行时配置项，支持按微服务名称（serviceName）、配置分组（group）、配置键（key）过滤与分页查询。配置查询优先命中 Redis 本地缓存（命中时响应 ≤ 50ms），缓存未命中时回源数据库（`t_common_config`）查询并回填缓存；敏感配置项（sensitive=1）在返回时脱敏处理，不暴露明文。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**（query）：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| serviceName | string | 否 | query | 微服务名称（gateway/auth-service/biz-service/system-service/common），不传返回全部微服务配置 |
| group | string | 否 | query | 配置分组（业务场景分组，如 security/verification/password/token 等） |
| key | string | 否 | query | 配置键（精确匹配） |
| page | int | 否 | query | 页码（从 1 开始，默认 1） |
| pageSize | int | 否 | query | 每页条数（默认 10） |
**请求示例**：
```
GET /api/v1/common/config?serviceName=gateway&group=security&page=1&pageSize=10
```
**响应参数**（data 为 PageResult\<ConfigItemVO\>）：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| records | array | 配置项列表（字段见下方 ConfigItemVO 说明） |
| total | long | 总记录数 |
| page | int | 当前页码 |
| pageSize | int | 每页大小 |
**ConfigItemVO 关键字段**：id（配置项 ID，long）、serviceName（微服务名称，string）、group（配置分组，string）、key（配置键，string）、value（配置值，string；敏感配置脱敏为掩码）、dataType（数据类型，string/number/boolean/json）、description（配置描述，string）、sensitive（是否敏感，boolean）、status（状态，0-启用/1-禁用）、createTime（创建时间，string）、updateTime（更新时间，string）
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    "records": [
      {
        "id": 1001,
        "serviceName": "auth-service",
        "group": "verification",
        "key": "code-length",
        "value": "6",
        "dataType": "number",
        "description": "验证码长度（位数）",
        "sensitive": false,
        "status": 0,
        "createTime": "2026-08-13T10:00:00",
        "updateTime": "2026-08-13T10:00:00"
      },
      {
        "id": 1002,
        "serviceName": "auth-service",
        "group": "token",
        "key": "sign-secret",
        "value": "****",
        "dataType": "string",
        "description": "令牌签名密钥（敏感）",
        "sensitive": true,
        "status": 0,
        "createTime": "2026-08-13T10:00:00",
        "updateTime": "2026-08-13T10:00:00"
      }
    ],
    "total": 2,
    "page": 1,
    "pageSize": 10
  },
  "timestamp": 1723000000000
}
```
**错误码**：400（参数错误，serviceName 取值非法）、401（未授权/Token 无效）、500（配置存储异常）

### 5.3 通用配置管理-按微服务查询配置（API-036）
**接口**：`GET /api/v1/common/config/{serviceName}`（需认证，非白名单）
**功能描述**：按微服务名称查询该微服务的全部运行时配置项（不分页）。缓存与脱敏策略同 API-035；指定微服务无配置项时返回空列表（`code=200`，非 500 错误）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | string | 是 | Bearer {accessToken} |
**请求参数**（path）：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| serviceName | string | 是 | path | 微服务名称（gateway/auth-service/biz-service/system-service/common） |
**请求示例**：`GET /api/v1/common/config/auth-service`
**响应参数**：data 为 ConfigItemVO 数组（字段同 API-035）。
**响应示例**：
```json
{
  "code": 200,
  "message": "操作成功",
  "data": [
    {
      "id": 1001,
      "serviceName": "auth-service",
      "group": "verification",
      "key": "code-length",
      "value": "6",
      "dataType": "number",
      "description": "验证码长度（位数）",
      "sensitive": false,
      "status": 0,
      "createTime": "2026-08-13T10:00:00",
      "updateTime": "2026-08-13T10:00:00"
    }
  ],
  "timestamp": 1723000000000
}
```
**错误码**：400（参数错误，serviceName 取值非法）、401（未授权/Token 无效）、500（配置存储异常）

## 6. 状态码映射

沿用主文档（v0.0.1）第 6 章，本版本补充 common 模块接口的状态码映射：

| HTTP 状态码 | 业务码 | 场景 |
| --- | --- | --- |
| 200 | 200 | 成功（含通用配置查询返回空列表） |
| 201 | 200 | 创建权限成功（@ResponseStatus CREATED，body 内 code 仍为 200） |
| 400 | 400 / AUTH-0011 / AUTH-0012 / AUTH-0019 / AUTH-0020 / AUTH-0021 / AUTH-0022 / AUTH-0023 / AUTH-0024 / AUTH-0032 / AUTH-0033 | 参数校验失败（含 serviceName 取值非法）、验证码错误/过期、模式无效、原密码错误等 |
| 401 | 401 / AUTH-0001~0005 / AUTH-0010 / AUTH-0013 / AUTH-0026 | 未认证、Token 过期/无效/黑名单、凭据错误、被踢下线 |
| 403 | 403 / AUTH-0006~0009 / AUTH-0014 / AUTH-0015 / AUTH-0016 / AUTH-0030 / AUTH-0031 | 账号/租户状态异常、权限不足、需邮箱验证、账号未完善 |
| 404 | 404 / AUTH-0017 / AUTH-0018 / AUTH-0027 | 用户/角色/资源不存在、第三方账号未绑定 |
| 409 | 409 / AUTH-0028 / AUTH-0029 | 手机号/第三方账号已绑定、资源冲突（编码重复、关联阻止删除） |
| 429 | 429 / AUTH-0025 | 验证码发送过于频繁 |
| 500 | 500 | 系统内部错误（含配置存储异常，全局兜底，不泄露堆栈） |
| 503 | 503 | 服务暂不可用 |

## 7. 限流策略

- **验证码发送限频（沿用）**：同一目标（手机号/邮箱）60 秒内禁止重复发送，超限返回 AUTH-0025（429）；验证码有效期 5 分钟，一次性失效。
- **通用配置查询接口（v0.2.8 新增）**：配置查询以 Redis 本地缓存命中为主（命中响应 ≤ 50ms），为低频读操作，本版本不设接口级独立限流；查询接口经网关 AuthFilter 认证后放行，无特殊频率约束。
- **网关级限流（沿用）**：本版本网关未配置 RequestRateLimiter 限流器；后续版本引入 Spring Cloud Gateway RequestRateLimiter 对登录/验证码等敏感端点按 IP/用户限流。
- **登录失败策略（沿用）**：登录失败统一返回 AUTH-0010（用户名或密码错误），不泄露具体原因，防账号枚举；失败事件记录登录日志供审计。

## 8. 示例代码

### 8.1 通用配置查询 curl 调用示例（v0.2.8 新增）
```bash
# 1. 登录获取 Token
curl -X POST http://localhost:9000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"loginMode":"USERNAME_PASSWORD","loginName":"admin","password":"password123","tenantCode":"default","clientType":"WINDOWS"}'

# 2. 携带 Token 查询全部微服务运行时配置（分页）
curl -X GET "http://localhost:9000/api/v1/common/config?page=1&pageSize=10" \
  -H "Authorization: Bearer {accessToken}"

# 3. 携带 Token 按微服务名称+分组过滤查询配置
curl -X GET "http://localhost:9000/api/v1/common/config?serviceName=gateway&group=security" \
  -H "Authorization: Bearer {accessToken}"

# 4. 携带 Token 按微服务名称查询该服务全部配置
curl -X GET "http://localhost:9000/api/v1/common/config/auth-service" \
  -H "Authorization: Bearer {accessToken}"

# 5. 健康检查（白名单，无需 Token）
curl -X GET "http://localhost:9000/api/v1/common/health"
```

### 8.2 通用配置查询 Java 调用示例（v0.2.8 新增）
```java
// 通过网关访问 common 配置查询接口，携带 Bearer Token
RestTemplate restTemplate = new RestTemplate();
HttpHeaders headers = new HttpHeaders();
headers.set("Authorization", "Bearer " + accessToken);
HttpEntity<Void> entity = new HttpEntity<>(headers);

// 按条件查询配置列表（分页）
ResponseEntity<String> resp = restTemplate.exchange(
    "http://localhost:9000/api/v1/common/config?serviceName=auth-service&page=1&pageSize=10",
    HttpMethod.GET, entity, String.class);
System.out.println(resp.getBody());
```

### 8.3 错误响应示例（网关拦截 401）
```json
{ "code": 401, "message": "令牌已过期，请刷新令牌", "data": null, "timestamp": 1723000000000 }
```

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->