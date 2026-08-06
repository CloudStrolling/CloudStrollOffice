# 接口设计文档（API）
**项目名称**：云漫智企（CloudStrollOffice）
**版本号**：v0.0.1（初始化基线，对应已实现能力 v0.1.6）
**日期**：2026-08-06
**编写人**：TL

## 1. 接口清单
接口路径规范：`/api/v1/{module}/{resource}`；网关 9000 为对外唯一入口；以下接口除标注"白名单"外，均需携带 Access Token 认证。

| 接口编号 | 接口名称 | 方法 | 路径 | 说明 |
| --- | --- | --- | --- | --- |
| API-001 | 用户注册 | POST | /api/v1/auth/register | 多模式注册（5 种注册模式），白名单 |
| API-002 | 用户登录 | POST | /api/v1/auth/login | 多模式登录（4 种登录模式），签发双 Token，白名单 |
| API-003 | 刷新 Token | POST | /api/v1/auth/refresh | Refresh Token 轮换刷新，白名单 |
| API-004 | 用户登出 | POST | /api/v1/auth/logout | 登出并注销当前 Token |
| API-005 | 强制踢人 | POST | /api/v1/auth/kickout | 管理员强制下线指定用户全部会话 |
| API-006 | 发送验证码 | POST | /api/v1/auth/verification-code/send | 通用验证码发送（SMS/EMAIL，用途绑定），白名单 |
| API-007 | 密码找回-发送验证码 | POST | /api/v1/auth/password/forgot/send-code | 密码找回第一步发送验证码，白名单 |
| API-008 | 密码找回-重置 | POST | /api/v1/auth/password/forgot/reset | 密码找回第二步校验验证码并重置密码，白名单 |
| API-009 | 修改密码 | PUT | /api/v1/auth/password/change | 登录后修改密码（校验旧密码） |
| API-010 | 修改手机号 | PUT | /api/v1/auth/phone/change | 手机号变更（原手机短信/邮箱双场景） |
| API-011 | 完善账号信息 | PUT | /api/v1/auth/account/settlement | 两步注册第二步，补全用户名/密码/手机号 |
| API-012 | 用户分页查询 | GET | /api/v1/auth/users | 用户列表分页查询（支持关键字/状态筛选） |
| API-013 | 用户详情查询 | GET | /api/v1/auth/users/{userId} | 查询用户详细信息 |
| API-014 | 更新用户信息 | PUT | /api/v1/auth/users/{userId} | 更新用户基本信息 |
| API-015 | 更新用户状态 | PUT | /api/v1/auth/users/{userId}/status | 启用/禁用用户（禁用后登录态实时失效） |
| API-016 | 分配用户角色 | PUT | /api/v1/auth/users/{userId}/roles | 为用户分配角色 |
| API-017 | 删除用户 | DELETE | /api/v1/auth/users/{userId} | 删除用户 |
| API-018 | 角色列表查询 | GET | /api/v1/auth/roles | 查询本租户角色列表 |
| API-019 | 创建角色 | POST | /api/v1/auth/roles | 创建角色（编码租户内唯一） |
| API-020 | 更新角色 | PUT | /api/v1/auth/roles/{roleId} | 更新角色信息 |
| API-021 | 删除角色 | DELETE | /api/v1/auth/roles/{roleId} | 删除角色（被用户引用不可删除） |
| API-022 | 角色分配权限 | PUT | /api/v1/auth/roles/{roleId}/permissions | 为角色分配权限集合 |
| API-023 | 权限树查询 | GET | /api/v1/auth/permissions | 查询权限树（树形组织） |
| API-024 | 创建权限 | POST | /api/v1/auth/permissions | 创建权限（编码全局唯一） |
| API-025 | 更新权限 | PUT | /api/v1/auth/permissions/{permId} | 更新权限信息 |
| API-026 | 删除权限 | DELETE | /api/v1/auth/permissions/{permId} | 删除权限（存在子权限不可删除） |
| API-027 | 认证服务健康检查 | GET | /api/v1/auth/health | 认证服务探活，白名单 |
| API-028 | 企业服务健康检查 | GET | /api/v1/biz/health | 企业服务探活，白名单 |
| API-029 | 系统服务健康检查 | GET | /api/v1/system/health | 系统服务探活，白名单 |

## 2. 接口版本策略
1. **URL 版本路径**：全部接口采用 URL 前缀版本化，当前版本为 `/api/v1`，路径规范 `/api/v1/{module}/{resource}`，模块标识 auth（认证）、biz（企业）、system（系统）。
2. **版本演进**：v2 版本计划引入时通过新增前缀 `/api/v2` 并存发布，旧版本在新版本稳定后再下线，避免破坏既有客户端。
3. **兼容策略**：v0.0.1 内新增字段不破坏兼容（客户端忽略未知字段）；字段删除或语义变更必须升级版本号；错误码、统一响应体结构（ApiResult）作为契约长期稳定，不随版本变更。
4. **网关路由**：API 网关（9000）按路径前缀将请求路由至认证（9100）/企业（9200）/系统（9400）服务，对外仅暴露网关地址。

## 3. 认证鉴权机制
1. **认证方式**：JWT 双 Token（RS256 非对称签名，RSA 2048 位）。Access Token 有效期 2 小时，携带用户/租户/客户端类型声明；Refresh Token 有效期 7 天，仅用于刷新。私钥仅认证服务持有，公钥分发至网关验签。
2. **Token 传递**：客户端在请求头传递 `Authorization: Bearer <accessToken>`；网关 9 步校验通过后，将用户信息写入请求 Header 透传给下游业务服务：
   | Header 名称 | 说明 |
   | --- | --- |
   | X-User-Id | 当前用户 ID |
   | X-User-Name | 当前用户名 |
   | X-Tenant-Id | 当前租户 ID |
   | X-Tenant-Code | 当前租户编码 |
   | X-User-Roles | 当前用户角色编码集合（逗号分隔） |
   | X-Client-Type | 客户端类型 |
3. **网关 9 步校验**：白名单放行 → Bearer 格式校验 → RS256 公钥验签 → Token 类型校验（必须为 Access）→ Redis 黑名单校验 → 登录态校验 → 账号状态校验 → 租户状态校验 → Header 透传。
4. **角色权限**：多租户 RBAC 三层模型（用户-角色-权限），管理类接口需具备对应权限（如用户管理、角色管理、强制踢人）；租户间数据完全隔离。
5. **过期与刷新**：Access Token 过期后客户端携带 Refresh Token 调用 API-003 刷新接口获取新 Token 对；刷新采用轮换机制（旧 Refresh Token 立即失效）；Refresh Token 过期需重新登录。
6. **实时失效**：登出、强制踢人、密码找回重置、用户禁用、租户禁用均通过 Redis 黑名单/登录态/状态缓存实时生效，无需等待 Token 自然过期。

## 4. 通用错误码定义
统一响应体 `ApiResult<T>`：`{ "code": 0, "message": "ok", "data": {}, "timestamp": 1786000000000 }`，code=0 表示成功。共 29 个业务错误码，按系统/参数/认证/业务四类划分：

| 错误码 | 说明 |
| --- | --- |
| SYS-0001 | 系统内部错误 |
| SYS-0002 | 服务不可用 |
| SYS-0003 | 数据库操作失败 |
| SYS-0004 | 缓存（Redis）操作失败 |
| SYS-0005 | 请求超时 |
| PARAM-0001 | 参数校验失败（缺失/格式/取值非法） |
| PARAM-0002 | 请求体格式错误（JSON 解析失败） |
| AUTH-0001 | 未携带访问凭证（缺少 Authorization 头） |
| AUTH-0002 | 访问凭证无效或已过期（验签失败/过期） |
| AUTH-0003 | 访问凭证已被注销（黑名单） |
| AUTH-0004 | 刷新凭证无效或已过期 |
| AUTH-0005 | 用户名或密码错误（防枚举统一提示） |
| AUTH-0006 | 账号已被禁用 |
| AUTH-0007 | 租户已被禁用 |
| AUTH-0008 | 租户不存在或不可用 |
| AUTH-0009 | 验证码错误或已过期 |
| AUTH-0010 | 验证码发送过于频繁（60 秒内不可重复发送） |
| AUTH-0011 | 验证码用途不匹配 |
| AUTH-0012 | 手机号已被其他账号绑定 |
| AUTH-0013 | 用户名已被占用 |
| AUTH-0014 | 旧密码校验失败 |
| AUTH-0015 | 无权限执行该操作 |
| AUTH-0016 | 登录模式不支持 |
| AUTH-0017 | 注册模式不支持 |
| AUTH-0018 | 客户端类型非法 |
| BIZ-0001 | 用户不存在 |
| BIZ-0002 | 角色不存在 |
| BIZ-0003 | 权限不存在 |
| BIZ-0004 | 存在子权限，不可删除父权限 |

## 5. 接口详细定义

### 5.1 用户注册（API-001）
**接口**：`POST /api/v1/auth/register`
**功能描述**：访客多模式注册创建账号。支持 5 种注册模式：USERNAME_PASSWORD（用户名密码）、PHONE_CODE（手机验证码）、OAUTH（第三方自动创建）、PHONE_SET_USERNAME（手机号设用户名）、OAUTH_SET_INFO（OAuth 补全信息）。注册成功后账号默认启用，OAuth 信息不完整时进入两步注册。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| registerMode | String | 是 | Body | 注册模式：USERNAME_PASSWORD/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO |
| tenantCode | String | 是 | Body | 租户编码（租户需有效且启用） |
| clientType | String | 是 | Body | 客户端类型：Windows/Ubuntu/H5/Android/iOS/WeChatMini |
| loginName | String | 条件 | Body | 用户名（USERNAME_PASSWORD、PHONE_SET_USERNAME 模式必填；租户内唯一） |
| password | String | 条件 | Body | 密码（USERNAME_PASSWORD、OAUTH_SET_INFO 模式必填；8~64 位，BCrypt 加密存储） |
| phone | String | 条件 | Body | 手机号（PHONE_CODE、PHONE_SET_USERNAME、OAUTH_SET_INFO 模式必填；租户内唯一） |
| code | String | 条件 | Body | 验证码（PHONE_CODE 模式必填，用途=REGISTER） |
| userName | String | 否 | Body | 姓名/昵称 |
| oauthProvider | String | 条件 | Body | 第三方平台标识（OAUTH 模式必填：WECHAT/DINGTALK/GITHUB） |
| oauthCode | String | 条件 | Body | 第三方授权码（OAUTH 模式必填） |
**请求示例**：
```json
{
  "registerMode": "USERNAME_PASSWORD",
  "tenantCode": "DEFAULT",
  "clientType": "H5",
  "loginName": "zhangsan",
  "password": "Admin@123456",
  "userName": "张三"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.userId | Long | 新用户 ID |
| data.registerMode | String | 注册模式 |
| data.accountComplete | Boolean | 账号信息是否完整（false 时需进入两步注册补全） |
| data.tenantCode | String | 租户编码 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "userId": 1001,
    "registerMode": "USERNAME_PASSWORD",
    "accountComplete": true,
    "tenantCode": "DEFAULT"
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| PARAM-0001 | 参数校验失败 |
| AUTH-0007 | 租户已被禁用 |
| AUTH-0008 | 租户不存在或不可用 |
| AUTH-0012 | 手机号已被其他账号绑定 |
| AUTH-0013 | 用户名已被占用 |
| AUTH-0017 | 注册模式不支持 |
| AUTH-0018 | 客户端类型非法 |
| SYS-0003 | 数据库操作失败 |

### 5.2 用户登录（API-002）
**接口**：`POST /api/v1/auth/login`
**功能描述**：多模式登录签发 JWT 双 Token。支持 4 种登录模式：USERNAME_PASSWORD（用户名密码）、PHONE_CODE（手机验证码）、PHONE_PASSWORD（手机+密码）、OAUTH（第三方授权）。登录成功建立 Redis 登录态会话（同端互斥、多端共存），并写入登录日志。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| loginMode | String | 是 | Body | 登录模式：USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH |
| tenantCode | String | 是 | Body | 租户编码（OAuth 登录可空） |
| clientType | String | 是 | Body | 客户端类型：Windows/Ubuntu/H5/Android/iOS/WeChatMini |
| loginName | String | 条件 | Body | 用户名（USERNAME_PASSWORD 模式必填） |
| password | String | 条件 | Body | 密码（USERNAME_PASSWORD、PHONE_PASSWORD 模式必填） |
| phone | String | 条件 | Body | 手机号（PHONE_CODE、PHONE_PASSWORD 模式必填） |
| code | String | 条件 | Body | 验证码（PHONE_CODE 模式必填，用途=LOGIN，5 分钟有效） |
| oauthProvider | String | 条件 | Body | 第三方平台标识（OAUTH 模式必填：WECHAT/DINGTALK/GITHUB） |
| oauthCode | String | 条件 | Body | 第三方授权码（OAUTH 模式必填） |
**请求示例**：
```json
{
  "loginMode": "USERNAME_PASSWORD",
  "tenantCode": "DEFAULT",
  "clientType": "H5",
  "loginName": "zhangsan",
  "password": "Admin@123456"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.accessToken | String | 访问令牌（有效期 2 小时） |
| data.refreshToken | String | 刷新令牌（有效期 7 天） |
| data.tokenType | String | 令牌类型，固定 Bearer |
| data.expiresIn | Long | Access Token 有效期（秒），7200 |
| data.refreshExpiresIn | Long | Refresh Token 有效期（秒），604800 |
| data.accountComplete | Boolean | 账号信息是否完整（false 时需完善账号信息） |
| data.userInfo.userId | Long | 用户 ID |
| data.userInfo.userName | String | 用户姓名 |
| data.userInfo.loginName | String | 用户名 |
| data.userInfo.tenantCode | String | 租户编码 |
| data.userInfo.roles | Array | 角色编码集合 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9.xxxxx",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9.yyyyy",
    "tokenType": "Bearer",
    "expiresIn": 7200,
    "refreshExpiresIn": 604800,
    "accountComplete": true,
    "userInfo": {
      "userId": 1001,
      "userName": "张三",
      "loginName": "zhangsan",
      "tenantCode": "DEFAULT",
      "roles": ["EMPLOYEE"]
    }
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| PARAM-0001 | 参数校验失败 |
| AUTH-0005 | 用户名或密码错误（防枚举统一提示） |
| AUTH-0006 | 账号已被禁用 |
| AUTH-0007 | 租户已被禁用 |
| AUTH-0008 | 租户不存在或不可用 |
| AUTH-0009 | 验证码错误或已过期 |
| AUTH-0011 | 验证码用途不匹配 |
| AUTH-0016 | 登录模式不支持 |
| AUTH-0018 | 客户端类型非法 |

### 5.3 刷新 Token（API-003）
**接口**：`POST /api/v1/auth/refresh`
**功能描述**：Access Token 过期后，使用 Refresh Token 轮换签发新 Token 对。每次刷新签发新 Refresh Token 并将旧 Refresh Token 立即加入黑名单（防重放）。刷新接口为白名单，但会校验 Refresh Token 是否有效、是否在黑名单。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| refreshToken | String | 是 | Body | 刷新令牌（7 天有效期内、未注销） |
| clientType | String | 是 | Body | 客户端类型：Windows/Ubuntu/H5/Android/iOS/WeChatMini |
**请求示例**：
```json
{
  "refreshToken": "eyJhbGciOiJSUzI1NiJ9.yyyyy",
  "clientType": "H5"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.accessToken | String | 新访问令牌（2 小时） |
| data.refreshToken | String | 新刷新令牌（7 天，旧令牌已作废） |
| data.tokenType | String | 令牌类型，固定 Bearer |
| data.expiresIn | Long | Access Token 有效期（秒），7200 |
| data.refreshExpiresIn | Long | Refresh Token 有效期（秒），604800 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9.zzzzz",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9.wwwww",
    "tokenType": "Bearer",
    "expiresIn": 7200,
    "refreshExpiresIn": 604800
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| PARAM-0001 | 参数校验失败 |
| AUTH-0003 | 刷新凭证已被注销（黑名单） |
| AUTH-0004 | 刷新凭证无效或已过期 |
| AUTH-0018 | 客户端类型非法 |

### 5.4 用户登出（API-004）
**接口**：`POST /api/v1/auth/logout`
**功能描述**：用户主动登出，将当前 Access/Refresh Token 加入黑名单并清除 Redis 登录态会话，Token 立即失效。重复登出幂等处理，不报错。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| refreshToken | String | 是 | Body | 刷新令牌（一并加入黑名单） |
**请求示例**：
```json
{
  "refreshToken": "eyJhbGciOiJSUzI1NiJ9.yyyyy"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0003 | 访问凭证已被注销 |

### 5.5 强制踢人（API-005）
**接口**：`POST /api/v1/auth/kickout`
**功能描述**：管理员强制下线指定用户的全部登录会话（清除 Redis 登录态并将相关 Token 加入黑名单），被踢用户下次请求即返回 401。需要管理员权限（角色含踢人权限）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | Long | 是 | Body | 被踢用户 ID |
**请求示例**：
```json
{
  "userId": 1002
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0015 | 无权限执行该操作 |
| BIZ-0001 | 用户不存在 |

### 5.6 发送验证码（API-006）
**接口**：`POST /api/v1/auth/verification-code/send`
**功能描述**：统一验证码发送接口。生成 6 位数字验证码（有效期 5 分钟、用途与目标绑定、单次使用），通过短信（SMS）或邮件（EMAIL）通道发送；同一目标 60 秒内不可重复发送。模拟模式（VERIFICATION_CODE_MOCK=true）下不实际发送，响应直接返回固定验证码 123456。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| target | String | 是 | Body | 接收目标：手机号或邮箱 |
| channel | String | 是 | Body | 发送通道：SMS（短信）/EMAIL（邮件） |
| purpose | String | 是 | Body | 用途：LOGIN/REGISTER/PASSWORD_RESET/PHONE_CHANGE |
| tenantCode | String | 否 | Body | 租户编码（PASSWORD_RESET 等场景可空） |
**请求示例**：
```json
{
  "target": "13800138000",
  "channel": "SMS",
  "purpose": "LOGIN",
  "tenantCode": "DEFAULT"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.mockCode | String | 模拟模式返回固定验证码 123456；真实模式为 null |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "mockCode": "123456"
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| PARAM-0001 | 参数校验失败（目标格式非法/通道非法/用途非法） |
| AUTH-0010 | 验证码发送过于频繁（60 秒内） |

### 5.7 密码找回-发送验证码（API-007）
**接口**：`POST /api/v1/auth/password/forgot/send-code`
**功能描述**：密码找回第一步：向目标（手机号/邮箱）发送用途为 PASSWORD_RESET 的验证码，受 60 秒频率控制。目标必须已绑定账号（按目标定位账号）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| target | String | 是 | Body | 接收目标：手机号或邮箱 |
| channel | String | 是 | Body | 发送通道：SMS（短信）/EMAIL（邮件） |
**请求示例**：
```json
{
  "target": "13800138000",
  "channel": "SMS"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.mockCode | String | 模拟模式返回固定验证码 123456；真实模式为 null |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "mockCode": "123456"
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| PARAM-0001 | 参数校验失败 |
| AUTH-0010 | 验证码发送过于频繁（60 秒内） |
| BIZ-0001 | 用户不存在（目标未绑定账号） |

### 5.8 密码找回-重置（API-008）
**接口**：`POST /api/v1/auth/password/forgot/reset`
**功能描述**：密码找回第二步：校验验证码（用途=PASSWORD_RESET、5 分钟有效、单次使用）后重置密码（BCrypt 加密），并自动清除该账号全部登录态（Token 黑名单 + 会话清除），需重新登录。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| target | String | 是 | Body | 接收目标：手机号或邮箱 |
| channel | String | 是 | Body | 发送通道：SMS（短信）/EMAIL（邮件） |
| code | String | 是 | Body | 验证码（6 位数字） |
| newPassword | String | 是 | Body | 新密码（8~64 位，与旧密码不同） |
**请求示例**：
```json
{
  "target": "13800138000",
  "channel": "SMS",
  "code": "123456",
  "newPassword": "NewPass@123"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| PARAM-0001 | 参数校验失败 |
| AUTH-0009 | 验证码错误或已过期 |
| AUTH-0011 | 验证码用途不匹配 |
| BIZ-0001 | 用户不存在 |

### 5.9 修改密码（API-009）
**接口**：`PUT /api/v1/auth/password/change`
**功能描述**：登录用户修改密码：校验旧密码（BCrypt）通过后更新新密码，记录最后修改密码时间。修改密码不强制下线（与找回不同）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| oldPassword | String | 是 | Body | 旧密码 |
| newPassword | String | 是 | Body | 新密码（8~64 位，与旧密码不同） |
**请求示例**：
```json
{
  "oldPassword": "Admin@123456",
  "newPassword": "NewPass@123"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0014 | 旧密码校验失败 |
| PARAM-0001 | 参数校验失败（新密码不满足策略/与旧密码相同） |

### 5.10 修改手机号（API-010）
**接口**：`PUT /api/v1/auth/phone/change`
**功能描述**：变更账号绑定手机号，按场景区分验证方式：场景 OLD_PHONE_SMS（原手机可用）发送短信验证码至原手机号校验；场景 EMAIL（原手机停用）发送邮箱验证码至绑定邮箱校验。新手机号租户内不可重复绑定。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| scene | String | 是 | Body | 变更场景：OLD_PHONE_SMS（原手机短信）/EMAIL（邮箱验证） |
| oldPhone | String | 条件 | Body | 原手机号（OLD_PHONE_SMS 场景必填，需与绑定一致） |
| newPhone | String | 是 | Body | 新手机号（租户内唯一） |
| code | String | 是 | Body | 验证码（OLD_PHONE_SMS 场景发至原手机，EMAIL 场景发至绑定邮箱） |
**请求示例**：
```json
{
  "scene": "OLD_PHONE_SMS",
  "oldPhone": "13800138000",
  "newPhone": "13900139000",
  "code": "123456"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0009 | 验证码错误或已过期 |
| AUTH-0012 | 手机号已被其他账号绑定 |
| PARAM-0001 | 参数校验失败（原手机号与绑定不一致/新手机号与旧手机号相同） |

### 5.11 完善账号信息（API-011）
**接口**：`PUT /api/v1/auth/account/settlement`
**功能描述**：两步注册第二步。对信息不完整的账号（如 OAuth 注册仅获得第三方唯一标识）补全用户名/密码/手机号，补全完成后账号具备完整登录能力。任一校验失败本次补全回滚，已补全项保留。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| loginName | String | 否 | Body | 用户名（缺省项补全；租户内唯一） |
| password | String | 否 | Body | 密码（缺省项补全；8~64 位） |
| phone | String | 否 | Body | 手机号（缺省项补全；租户内唯一） |
| code | String | 条件 | Body | 验证码（补全手机号时必填，用途=REGISTER） |
| userName | String | 否 | Body | 姓名/昵称 |
**请求示例**：
```json
{
  "loginName": "zhangsan",
  "password": "Admin@123456",
  "phone": "13800138000",
  "code": "123456",
  "userName": "张三"
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.accountComplete | Boolean | 账号补全是否完成（true 表示具备完整登录能力） |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "accountComplete": true
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0009 | 验证码错误或已过期 |
| AUTH-0012 | 手机号已被其他账号绑定 |
| AUTH-0013 | 用户名已被占用 |
| PARAM-0001 | 参数校验失败 |

### 5.12 用户分页查询（API-012）
**接口**：`GET /api/v1/auth/users?pageNum=1&pageSize=10&keyword=zhang&status=1`
**功能描述**：按租户隔离分页查询用户列表，支持关键字（用户名/姓名/手机号）与状态筛选，需要用户管理权限。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| pageNum | Integer | 否 | Query | 页码，默认 1 |
| pageSize | Integer | 否 | Query | 每页条数，默认 10，最大 100 |
| keyword | String | 否 | Query | 关键字（用户名/姓名/手机号模糊匹配） |
| status | Integer | 否 | Query | 状态筛选：1 启用 / 0 禁用（空=全部） |
**请求示例**：
```json
{}
```
（无请求体；URL 示例：`GET /api/v1/auth/users?pageNum=1&pageSize=10&keyword=zhang&status=1`）
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.records[].userId | Long | 用户 ID |
| data.records[].loginName | String | 用户名 |
| data.records[].userName | String | 姓名 |
| data.records[].phone | String | 手机号（脱敏展示） |
| data.records[].email | String | 邮箱（脱敏展示） |
| data.records[].status | Integer | 状态：1 启用 / 0 禁用 |
| data.records[].roles | Array | 角色编码集合 |
| data.records[].createdAt | String | 创建时间 |
| data.total | Long | 总记录数 |
| data.pageNum | Integer | 当前页码 |
| data.pageSize | Integer | 每页条数 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "records": [
      {
        "userId": 1001,
        "loginName": "zhangsan",
        "userName": "张三",
        "phone": "138****8000",
        "email": "zhang***@example.com",
        "status": 1,
        "roles": ["EMPLOYEE"],
        "createdAt": "2026-07-01 10:00:00"
      }
    ],
    "total": 1,
    "pageNum": 1,
    "pageSize": 10
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0015 | 无权限执行该操作 |
| PARAM-0001 | 参数校验失败（分页参数非法） |

### 5.13 用户详情查询（API-013）
**接口**：`GET /api/v1/auth/users/{userId}`
**功能描述**：查询指定用户详细信息（含角色集合），需要用户管理权限，仅限本租户数据。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | Long | 是 | Path | 用户 ID |
**请求示例**：
```json
{}
```
（无请求体；URL 示例：`GET /api/v1/auth/users/1001`）
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.userId | Long | 用户 ID |
| data.loginName | String | 用户名 |
| data.userName | String | 姓名 |
| data.phone | String | 手机号 |
| data.email | String | 邮箱 |
| data.status | Integer | 状态：1 启用 / 0 禁用 |
| data.roles | Array | 角色编码集合 |
| data.tenantCode | String | 租户编码 |
| data.createdAt | String | 创建时间 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "userId": 1001,
    "loginName": "zhangsan",
    "userName": "张三",
    "phone": "13800138000",
    "email": "zhangsan@example.com",
    "status": 1,
    "roles": ["EMPLOYEE"],
    "tenantCode": "DEFAULT",
    "createdAt": "2026-07-01 10:00:00"
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0015 | 无权限执行该操作 |
| BIZ-0001 | 用户不存在 |

### 5.14 更新用户状态（API-015）
**接口**：`PUT /api/v1/auth/users/{userId}/status`
**功能描述**：启用/禁用用户。禁用后该用户全部登录态实时失效（Redis 状态缓存 + 网关状态校验联动，后续请求返回 403）。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | Long | 是 | Path | 用户 ID |
| status | Integer | 是 | Body | 目标状态：1 启用 / 0 禁用 |
**请求示例**：
```json
{
  "status": 0
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0015 | 无权限执行该操作 |
| BIZ-0001 | 用户不存在 |
| PARAM-0001 | 参数校验失败（状态取值非法） |

### 5.15 分配用户角色（API-016）
**接口**：`PUT /api/v1/auth/users/{userId}/roles`
**功能描述**：为用户分配角色集合（全量覆盖式更新用户-角色关联），需要用户管理权限。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| userId | Long | 是 | Path | 用户 ID |
| roleIds | Array | 是 | Body | 角色 ID 集合 |
**请求示例**：
```json
{
  "roleIds": [201, 202]
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0015 | 无权限执行该操作 |
| BIZ-0001 | 用户不存在 |
| BIZ-0002 | 角色不存在 |

### 5.16 角色分配权限（API-022）
**接口**：`PUT /api/v1/auth/roles/{roleId}/permissions`
**功能描述**：为角色分配权限集合（全量覆盖式更新角色-权限关联），需要角色管理权限。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
| Content-Type | String | 是 | application/json |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| roleId | Long | 是 | Path | 角色 ID |
| permissionIds | Array | 是 | Body | 权限 ID 集合 |
**请求示例**：
```json
{
  "permissionIds": [301, 302, 303]
}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data | Object | 空对象 |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": null,
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0015 | 无权限执行该操作 |
| BIZ-0002 | 角色不存在 |
| BIZ-0003 | 权限不存在 |

### 5.17 权限树查询（API-023）
**接口**：`GET /api/v1/auth/permissions`
**功能描述**：查询当前租户可见的权限树（树形组织，含父子层级），用于角色分配权限时的树形勾选，需要角色管理权限。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| Authorization | String | 是 | Bearer <accessToken> |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| （无） |  |  |  | 无请求参数 |
**请求示例**：
```json
{}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data[].permId | Long | 权限 ID |
| data[].permCode | String | 权限编码（全局唯一） |
| data[].permName | String | 权限名称 |
| data[].permType | String | 权限类型（MENU/BUTTON/API） |
| data[].parentId | Long | 父权限 ID（0=根节点） |
| data[].path | String | 资源路径 |
| data[].children | Array | 子权限集合（递归结构） |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": [
    {
      "permId": 301,
      "permCode": "auth:user:manage",
      "permName": "用户管理",
      "permType": "MENU",
      "parentId": 0,
      "path": "/auth/users",
      "children": [
        {
          "permId": 302,
          "permCode": "auth:user:create",
          "permName": "创建用户",
          "permType": "BUTTON",
          "parentId": 301,
          "path": "/auth/users",
          "children": []
        }
      ]
    }
  ],
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| AUTH-0001 | 未携带访问凭证 |
| AUTH-0002 | 访问凭证无效或已过期 |
| AUTH-0015 | 无权限执行该操作 |

### 5.18 健康检查（API-027）
**接口**：`GET /api/v1/auth/health`
**功能描述**：认证服务探活接口（白名单，无需 Token），返回服务名称与运行状态；企业服务、系统服务健康检查路径分别为 /api/v1/biz/health、/api/v1/system/health，结构一致。
**请求头**：
| 名称 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| （无） |  |  | 无需认证 |
**请求参数**：
| 参数名 | 类型 | 必填 | 位置 | 说明 |
| --- | --- | --- | --- | --- |
| （无） |  |  |  | 无请求参数 |
**请求示例**：
```json
{}
```
**响应参数**：
| 参数名 | 类型 | 说明 |
| --- | --- | --- |
| code | Integer | 业务码，0=成功 |
| message | String | 提示信息 |
| data.service | String | 服务名称（如 cloudoffice-auth-service） |
| data.status | String | 服务状态：UP / DOWN |
| data.timestamp | Long | 服务当前时间戳（毫秒） |
| timestamp | Long | 服务器时间戳（毫秒） |
**响应示例**：
```json
{
  "code": 0,
  "message": "ok",
  "data": {
    "service": "cloudoffice-auth-service",
    "status": "UP",
    "timestamp": 1786000000000
  },
  "timestamp": 1786000000000
}
```
**错误码**：
| 错误码 | 说明 |
| --- | --- |
| SYS-0002 | 服务不可用（状态为 DOWN 时） |

## 6. 状态码映射
HTTP 状态码与业务错误码映射关系（网关/服务端统一）：

| HTTP 状态码 | 场景 | 业务错误码 |
| --- | --- | --- |
| 200 | 请求成功 | code=0 |
| 400 | 参数校验失败、请求体格式错误 | PARAM-0001、PARAM-0002 |
| 401 | 未认证：未携带 Token、Token 无效/过期、黑名单、登录态不存在、Refresh 无效 | AUTH-0001、AUTH-0002、AUTH-0003、AUTH-0004 |
| 403 | 无权限：账号禁用、租户禁用、越权操作 | AUTH-0006、AUTH-0007、AUTH-0015 |
| 409 | 业务冲突：用户名/手机号已占用 | AUTH-0012、AUTH-0013 |
| 422 | 业务校验失败：验证码错误/过期/用途不符、旧密码错误、目标不存在 | AUTH-0009、AUTH-0011、AUTH-0014、BIZ-0001、BIZ-0002、BIZ-0003 |
| 429 | 频率限制：验证码 60 秒内重复发送 | AUTH-0010 |
| 500 | 系统内部错误、服务不可用、数据库/缓存异常 | SYS-0001 ~ SYS-0005 |

说明：业务失败统一返回 ApiResult 结构携带业务错误码；网关认证失败返回 401/403 且不泄露内部细节；错误响应不包含堆栈与敏感信息。

## 7. 限流策略
1. **网关层限流**：API 网关预留 Spring Cloud Gateway RequestRateLimiter 限流能力（按 IP/用户维度），后续版本按接口配置阈值，超限返回 429 规范化错误。
2. **验证码频率控制**：同一目标（手机号/邮箱）60 秒内不可重复发送验证码，超限返回 AUTH-0010；验证码 5 分钟有效、单次使用、用途与目标绑定，防短信轰炸与暴力破解。
3. **登录防护**：登录失败统一提示"用户名或密码错误"防账号枚举；失败日志全量记录供风控分析；验证码登录受验证码频率与有效期双重约束。
4. **白名单接口**：登录、注册、刷新、验证码发送、密码找回、健康检查等白名单接口仍受网关限流规则约束，防止被恶意刷量。

## 8. 示例代码
以下为 curl 调用示例（网关地址 http://localhost:9000，模拟模式验证码固定 123456）。

### 8.1 发送验证码（获取登录验证码）
```bash
curl -X POST 'http://localhost:9000/api/v1/auth/verification-code/send' \
  -H 'Content-Type: application/json' \
  -d '{
    "target": "13800138000",
    "channel": "SMS",
    "purpose": "LOGIN",
    "tenantCode": "DEFAULT"
  }'
```

### 8.2 登录获取 Token
```bash
curl -X POST 'http://localhost:9000/api/v1/auth/login' \
  -H 'Content-Type: application/json' \
  -d '{
    "loginMode": "USERNAME_PASSWORD",
    "tenantCode": "DEFAULT",
    "clientType": "H5",
    "loginName": "admin",
    "password": "Admin@123456"
  }'
```
响应中的 data.accessToken / data.refreshToken 分别用于后续访问与刷新。

### 8.3 带 Token 访问用户列表（分页查询）
```bash
curl -X GET 'http://localhost:9000/api/v1/auth/users?pageNum=1&pageSize=10&status=1' \
  -H 'Authorization: Bearer <accessToken>'
```

### 8.4 刷新 Token（轮换）
```bash
curl -X POST 'http://localhost:9000/api/v1/auth/refresh' \
  -H 'Content-Type: application/json' \
  -d '{
    "refreshToken": "<refreshToken>",
    "clientType": "H5"
  }'
```

### 8.5 用户注册（用户名密码模式）
```bash
curl -X POST 'http://localhost:9000/api/v1/auth/register' \
  -H 'Content-Type: application/json' \
  -d '{
    "registerMode": "USERNAME_PASSWORD",
    "tenantCode": "DEFAULT",
    "clientType": "H5",
    "loginName": "zhangsan",
    "password": "Admin@123456",
    "userName": "张三"
  }'
```

### 8.6 登出
```bash
curl -X POST 'http://localhost:9000/api/v1/auth/logout' \
  -H 'Authorization: Bearer <accessToken>' \
  -H 'Content-Type: application/json' \
  -d '{
    "refreshToken": "<refreshToken>"
  }'
```

<!-- SPDX-License-Identifier: Apache-2.0 / Copyright 2026 jenemy8023 <jenemy8023@163.com> -->
