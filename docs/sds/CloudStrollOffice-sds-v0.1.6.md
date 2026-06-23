# 软件设计规格说明书（SDS）

**项目名称：** 云漫智企
**项目英文名：** CloudStrollOffice
**版本号：** v0.1.6
**日期：** 2026-06-23

---

## 1. 技术方案概述

### 1.1 系统定位

云漫智企（CloudStrollOffice）v0.1.6 在 v0.1.5 完整登录认证与权限管理系统（RBAC 模型、多端混合登录、JWT+Redis 双重会话管理、双 Token 续签机制）的基础上，对用户认证能力进行全面增强。核心目标是实现多模式注册与登录、统一认证服务层、密码管理、手机号变更、验证码管理等能力，使平台的认证体系覆盖主流互联网应用的用户接入场景。

### 1.2 架构风格

- **选用风格：** 微服务架构（Microservices Architecture）
- **认证模式扩展方案：** 策略模式 + 工厂模式（ADR-017）
- **关键设计模式：** 策略模式（Strategy Pattern）、工厂模式（Factory Pattern）、编排服务（Orchestration Service）

### 1.3 核心工作流

#### 1.3.1 多模式登录流程（策略模式编排）

```
客户端 → POST /api/v1/auth/login { loginMode, ... }
  → AuthController.login()
  → AuthenticationService.authenticate()
    → LoginStrategyFactory.getStrategy(loginMode)
      → UsernamePasswordStrategy  → 校验 loginName + password（BCrypt）
      → PhoneCodeLoginStrategy    → 校验 phone + smsCode（验证码校验）
      → PhonePasswordLoginStrategy → 校验 phone + password（BCrypt）
      → OAuthLoginStrategy        → 校验 oauthProvider + oauthCode
    → 校验通过 → 返回 AuthResult
  → 统一认证后处理（所有模式共享）：
    校验租户状态 → 校验用户状态(含account_settled) → 构建LoginUserDTO
    → 签发JWT双Token → 同端互斥 → 写入Redis登录态 → 缓存状态
    → 记录登录日志 → 更新最后登录时间和IP
  → 返回 TokenPairDTO
```

#### 1.3.2 多模式注册流程（策略模式编排）

```
客户端 → POST /api/v1/auth/register { registerMode, ... }
  → AuthController.register()
  → RegisterStrategyFactory.getStrategy(registerMode)
    → UsernamePwdStrategy     → 创建完整账号（loginName+password+phone）
    → PhoneCodeStrategy       → 手机+验证码创建临时账号
    → OAuthRegisterStrategy   → OAuth创建临时账号并绑定
    → PhoneSetUsernameStrategy → 手机+验证码创建临时账号（两步注册第一步）
    → OAuthSetInfoStrategy    → OAuth创建临时账号并绑定（两步注册第一步）
  → 返回用户基本信息/TokenPairDTO
```

#### 1.3.3 验证码生命周期管理

```
发送验证码 → generateCode(target, mode, purpose)
  → 验证码频率检查（60秒间隔） → 生成6位数字验证码
  → 存储至Redis（TTL 5分钟）+ 数据库持久化
  → 通过VerificationCodeService发送

校验验证码 → verifyCode(target, code, purpose)
  → 检查验证码存在且未过期 → 检查未使用 → 校验通过
  → 标记为已使用（used=1）→ 防止重放攻击
```

### 1.4 关键设计原则

| 原则 | 说明 |
|------|------|
| **策略模式解耦** | 登录和注册的多种方式通过策略模式实现，新增认证方式只需新增策略实现类并注册到工厂，不修改现有核心逻辑（开闭原则） |
| **统一认证编排** | `AuthenticationService` 统一编排凭证校验与 Token 签发/会话管理，所有登录方式共享同一套后处理流程 |
| **验证码一次性使用** | 验证码校验后立即标记为已使用（used=1），Redis + 数据库双重保障，防止重放攻击 |
| **两步注册机制** | `PHONE_SET_USERNAME` 和 `OAUTH_SET_INFO` 模式支持先创建基础账号，后续通过 `account/settlement` API 补充完整信息，`account_settled` 字段标识账号状态 |
| **安全优先** | 密码 BCrypt 加密（强度系数≥10），新旧密码不在日志明文输出，密码修改/重置后清理登录态 |
| **向后兼容** | `loginMode` 不传时默认 `USERNAME_PASSWORD` 模式，`registerMode` 不传时默认 `USERNAME` 模式，现有请求格式完全兼容 |
| **分层抽象** | 验证码发送服务（`VerificationCodeService`）定义为接口，模拟实现与真实网关实现可无缝替换 |

### 1.5 对应 PRD UserStory 一览

| PRD UserStory | 需求编号 | 模块 | 优先级 |
|---------------|----------|------|--------|
| US-001: 注册登录模式枚举 | FR-001 | common | Must |
| US-002: 认证错误码扩展 | FR-002 | common | Must |
| US-003: OAuth 提供商枚举 | FR-003 | common | Should |
| US-004: 认证相关 DTO 扩展 | FR-004 | auth-service | Must |
| US-005: 多模式注册 API | FR-005 | auth-service | Must |
| US-006: 多模式登录 API | FR-006 | auth-service | Must |
| US-007: 统一认证服务层 | FR-007 | auth-service | Must |
| US-008: 用户修改密码 API | FR-008 | auth-service | Must |
| US-009: 用户密码找回 API | FR-009 | auth-service | Should |
| US-010: 用户修改手机号 API | FR-010 | auth-service | Should |
| US-011: OAuth 账号关联表 | FR-011 | auth-service (DB) | Must |
| US-012: 验证码记录表 | FR-012 | auth-service (DB) | Must |
| US-013: 用户表扩展 | FR-013 | auth-service (DB) | Must |
| US-014: 密码重置令牌表 | FR-014 | auth-service (DB) | Should（可选） |
| US-015: 验证码发送服务 | FR-015 | auth-service | Should |
| US-016: 验证码管理服务 | FR-016 | auth-service | Must |

---

## 2. 模块概要设计

### 2.1 模块清单

| 模块 | 变更类型 | 职责 |
|------|----------|------|
| **cloudoffice-common** | 扩展 | 新增枚举（RegisterModeEnum/LoginModeEnum/OAuthProviderEnum），ErrorCode 扩展（AUTH-0020~AUTH-0033） |
| **cloudoffice-auth-service** | 主要变更 | 策略模式认证架构、统一认证服务层、密码管理、手机号变更、验证码管理、数据库扩展 |
| **cloudoffice-gateway** | 配置变更 | 白名单路径扩展，新增验证码发送/密码找回等路径放行 |

### 2.2 模块间相互关系

```
v0.1.5 认证基础（cloudoffice-common + cloudoffice-auth-service + cloudoffice-gateway）
         │
         ▼
v0.1.6 用户认证增强
         │
         ├── cloudoffice-common
         │    ├── RegisterModeEnum              新增（5种注册模式枚举）
         │    ├── LoginModeEnum                 新增（4种登录模式枚举）
         │    ├── OAuthProviderEnum             新增（4种OAuth提供商）
         │    └── ErrorCode                     扩展（AUTH-0020~AUTH-0033）
         │
         └── cloudoffice-auth-service
              ├── service/strategy/              新增策略模式包
              │    ├── LoginStrategy + 4个实现    登录策略
              │    ├── RegisterStrategy + 5个实现  注册策略
              │    ├── LoginStrategyFactory       登录策略工厂
              │    └── RegisterStrategyFactory    注册策略工厂
              ├── service/
              │    ├── AuthenticationService      新增（统一认证编排）
              │    ├── PasswordService            新增（密码修改/找回）
              │    ├── VerificationCodeService    新增（验证码发送接口）
              │    ├── VerificationCodeManager    新增（验证码生成/校验）
              │    └── UserService                扩展（完善账号/手机号变更）
              ├── controller/AuthController       扩展（新增5+端点）
              ├── dto/                            扩展（新增/修改 DTO）
              ├── entity/                         扩展（UserEntity + 2个新实体）
              └── mapper/                         扩展（2个新 Mapper）
```

#### 2.2.1 cloudoffice-common 公共模块

**v0.1.6 新增内容：**

| 类/枚举 | 包路径 | 说明 |
|---------|--------|------|
| `RegisterModeEnum` | `org.cloudstrolling.cloudoffice.common.enums` | 注册模式枚举：USERNAME / PHONE_CODE / OAUTH / PHONE_SET_USERNAME / OAUTH_SET_INFO |
| `LoginModeEnum` | `org.cloudstrolling.cloudoffice.common.enums` | 登录模式枚举：USERNAME_PASSWORD / PHONE_CODE / PHONE_PASSWORD / OAUTH |
| `OAuthProviderEnum` | `org.cloudstrolling.cloudoffice.common.enums` | OAuth 提供商枚举：WECHAT / DINGTALK / WECHAT_WORK / ALIPAY |
| `ErrorCode`（扩展） | `org.cloudstrolling.cloudoffice.common.exception` | 新增 14 个认证错误码（AUTH-0020 ~ AUTH-0033） |

#### 2.2.2 cloudoffice-auth-service 认证服务

**v0.1.6 新增/变更结构：**

```
service/
├── AuthenticationService.java          # [新增] 统一认证编排服务
├── PasswordService.java                # [新增] 密码管理服务（修改/找回）
├── VerificationCodeService.java        # [新增] 验证码发送服务接口
├── VerificationCodeManager.java        # [新增] 验证码生成/校验/过期管理
├── UserService.java                    # [扩展] 完善账号/手机号变更
├── strategy/                           # [新增] 策略模式包
│   ├── LoginStrategy.java              # [新增] 登录策略接口
│   ├── LoginStrategyFactory.java       # [新增] 登录策略工厂
│   ├── UsernamePasswordStrategy.java   # [新增] 用户名密码登录
│   ├── PhoneCodeLoginStrategy.java     # [新增] 手机验证码登录
│   ├── PhonePasswordLoginStrategy.java # [新增] 手机密码登录
│   ├── OAuthLoginStrategy.java         # [新增] OAuth登录
│   ├── RegisterStrategy.java           # [新增] 注册策略接口
│   ├── RegisterStrategyFactory.java    # [新增] 注册策略工厂
│   ├── UsernamePwdStrategy.java        # [新增] 用户名密码注册
│   ├── PhoneCodeStrategy.java          # [新增] 手机验证码注册
│   ├── OAuthRegisterStrategy.java      # [新增] OAuth注册
│   ├── PhoneSetUsernameStrategy.java   # [新增] 手机注册后设用户名
│   └── OAuthSetInfoStrategy.java       # [新增] OAuth注册后完善信息
└── impl/
    ├── PasswordServiceImpl.java        # [新增] 密码管理实现
    ├── SimulatedVerificationCodeServiceImpl.java # [新增] 验证码模拟发送实现
    ├── UserServiceImpl.java            # [扩展] 完善账号/手机号变更
    ├── LoginServiceImpl.java           # [重构] 适配策略模式
    └── ...

controller/
├── AuthController.java                 # [扩展] 新增5+端点

dto/
├── LoginRequest.java                   # [修改] 新增 loginMode/phone/smsCode/oauthProvider/oauthCode
├── RegisterRequest.java                # [修改] 新增 registerMode/smsCode/oauthProvider/oauthCode，移除tenantId
├── PasswordChangeRequest.java          # [新增] 修改密码请求
├── PasswordForgotRequest.java          # [新增] 密码找回请求
├── SendVerificationCodeRequest.java    # [新增] 发送验证码请求
├── PhoneChangeRequest.java             # [新增] 修改手机号请求
├── AccountSettlementRequest.java       # [新增] 完善账号信息请求
├── AuthResult.java                     # [新增] 策略认证结果
└── RegisterResult.java                 # [新增] 注册结果

entity/
├── UserEntity.java                     # [扩展] 新增 registerMode/accountSettled/phoneVerified/emailVerified/lastPasswordChangeTime
├── OAuthAccountEntity.java             # [新增] OAuth账号关联实体
└── VerificationCodeEntity.java         # [新增] 验证码记录实体

mapper/
├── OAuthAccountMapper.java             # [新增] OAuth账号关联Mapper
└── VerificationCodeMapper.java         # [新增] 验证码记录Mapper
```

#### 2.2.3 cloudoffice-gateway API 网关

**v0.1.6 配置变更：**

- **白名单路径扩展**（AuthFilter 配置）：
  - `POST /api/v1/auth/verification-code/send`（新增，通用验证码发送）
  - `POST /api/v1/auth/password/forgot/send-code`（新增，密码找回发送验证码）
  - `POST /api/v1/auth/password/forgot/reset`（新增，密码找回重置）
  - 已有白名单路径保留不变

---

## 3. 数据设计

### 3.1 数据库设计概览

**设计原则：**
- 每微服务独立数据库，服务间禁止跨服务直接访问数据库
- 主键统一使用雪花算法（MyBatis-Plus ID_WORKER）
- 每表统一添加 `create_time`、`update_time`、`deleted` 字段（通过 `BaseEntity` 继承）
- v0.1.6 设计决策：密码找回不新增独立的密码重置令牌表（`t_auth_password_reset_token`），完全基于验证码记录表实现（ADR-019）

### 3.2 表结构设计

#### 3.2.1 新增表：t_auth_oauth_account（OAuth 第三方账号关联表）

**数据库：** `cloudstroll_office_auth`
**用途：** 存储用户与第三方 OAuth 账号的绑定关系，支持一个用户绑定多个第三方账号

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| `id` | BIGINT(20) | PK | 主键，雪花算法 |
| `user_id` | BIGINT(20) | NOT NULL | 平台用户 ID |
| `oauth_provider` | VARCHAR(32) | NOT NULL | OAuth 提供商（WECHAT / DINGTALK / WECHAT_WORK / ALIPAY） |
| `oauth_open_id` | VARCHAR(256) | NOT NULL | 第三方平台用户唯一标识（openId） |
| `oauth_union_id` | VARCHAR(256) | NULL | 第三方平台用户统一标识（unionId，可选） |
| `oauth_nickname` | VARCHAR(128) | NULL | 第三方平台昵称 |
| `oauth_avatar` | VARCHAR(512) | NULL | 第三方平台头像 URL |
| `bound_time` | DATETIME | NULL | 绑定时间 |
| `create_time` | DATETIME | NOT NULL | 创建时间（自动填充） |
| `update_time` | DATETIME | NOT NULL | 更新时间（自动填充） |
| `deleted` | TINYINT(4) | DEFAULT 0 | 逻辑删除（0-正常，1-删除） |

**索引：**
- `uk_provider_openid` — 联合唯一索引（`oauth_provider` + `oauth_open_id`）
- `idx_user_id` — 普通索引（`user_id`）

#### 3.2.2 新增表：t_auth_verification_code（验证码记录表）

**数据库：** `cloudstroll_office_auth`
**用途：** 记录生成的验证码及其状态，支持验证码的生成、校验（一次性使用）、过期处理

| 字段名 | 类型 | 约束 | 说明 |
|--------|------|------|------|
| `id` | BIGINT(20) | PK | 主键，雪花算法 |
| `target` | VARCHAR(128) | NOT NULL | 发送目标（手机号或邮箱） |
| `code` | VARCHAR(16) | NOT NULL | 验证码内容（6位数字） |
| `send_mode` | VARCHAR(16) | NOT NULL | 发送方式（SMS / EMAIL） |
| `purpose` | VARCHAR(32) | NOT NULL | 用途（REGISTER / LOGIN / RESET_PASSWORD / CHANGE_PHONE） |
| `expire_time` | DATETIME | NOT NULL | 过期时间（当前时间 + 5分钟） |
| `used` | TINYINT(4) | DEFAULT 0 | 是否已使用（0-未使用，1-已使用） |
| `used_time` | DATETIME | NULL | 使用时间 |
| `send_count` | INT(11) | NULL | 本日发送次数 |
| `create_time` | DATETIME | NOT NULL | 创建时间（自动填充） |
| `update_time` | DATETIME | NOT NULL | 更新时间（自动填充） |
| `deleted` | TINYINT(4) | DEFAULT 0 | 逻辑删除（0-正常，1-删除） |

**索引：**
- `idx_target_purpose` — 普通索引（`target` + `purpose`）
- `idx_expire_time` — 普通索引（`expire_time`）

#### 3.2.3 扩展表：t_auth_user（用户表扩展）

**数据库：** `cloudstroll_office_auth`
**变更类型：** ALTER TABLE 新增字段

| 字段名 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `register_mode` | VARCHAR(32) | 'USERNAME' | 注册模式标识 |
| `account_settled` | TINYINT(4) | 1 | 账号信息是否完善（0-未完善，1-已完善） |
| `phone_verified` | TINYINT(4) | 0 | 手机号是否已验证（0-未验证，1-已验证） |
| `email_verified` | TINYINT(4) | 0 | 邮箱是否已验证（0-未验证，1-已验证） |
| `last_password_change_time` | DATETIME | NULL | 最后修改密码时间 |

**向后兼容说明：**
- 已有用户记录的 `register_mode` 默认填充为 `'USERNAME'`
- 已有用户记录的 `account_settled` 默认填充为 `1`（已完善）
- 新增字段均设置合理的默认值，保证 v0.1.5 现有数据完全兼容

### 3.3 缓存设计

#### 3.3.1 Redis Key 设计（v0.1.6 新增）

| Key 格式 | 类型 | TTL | 用途 |
|----------|------|-----|------|
| `auth:verification:{purpose}:{target}` | String | 300秒（5分钟） | 验证码缓存（验证码内容，利用 TTL 自动过期） |
| `auth:verification:freq:{purpose}:{target}` | String | 60秒 | 验证码发送频率控制 Key |

#### 3.3.2 缓存优先级策略

- **验证码存储**：优先使用 Redis（利用 TTL 自动过期，减少清理负担），Redis 不可用时回退到数据库存储（ADR-018）
- **验证码频率控制**：仅存储于 Redis（短 TTL 自动清理，无需持久化）
- **一致性保障**：验证码使用后立即标记，Redis 与数据库双重记录防止重放

---

## 4. 接口设计

### 4.1 接口规范

- **统一响应体：** `ApiResult<T>`（包含 code / message / data / timestamp）
- **认证头：** `Authorization: Bearer <accessToken>`
- **请求方法：** 遵循 RESTful 风格
- **参数校验：** 使用 `@Valid` 注解进行参数校验
- **白名单说明：** 登录、注册、Token 刷新、发送验证码、密码找回等接口无需认证，其他接口需携带有效 JWT Token

### 4.2 API 接口定义

#### 4.2.1 多模式登录（修改）

```
POST /api/v1/auth/login
```

**白名单：** 是
**请求参数（LoginRequest）：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `loginMode` | String | 是 | 登录模式：USERNAME_PASSWORD / PHONE_CODE / PHONE_PASSWORD / OAUTH |
| `tenantCode` | String | 是 | 租户编码（所有模式必填） |
| `clientType` | String | 是 | 客户端类型（所有模式必填） |
| `loginName` | String | 条件必填 | 用户名（仅 USERNAME_PASSWORD 模式必填） |
| `password` | String | 条件必填 | 密码（仅 USERNAME_PASSWORD / PHONE_PASSWORD 模式必填） |
| `phone` | String | 条件必填 | 手机号（仅 PHONE_CODE / PHONE_PASSWORD 模式必填） |
| `smsCode` | String | 条件必填 | 短信验证码（仅 PHONE_CODE 模式必填） |
| `oauthProvider` | String | 条件必填 | OAuth 提供商（仅 OAUTH 模式必填） |
| `oauthCode` | String | 条件必填 | OAuth 授权码/令牌（仅 OAUTH 模式必填） |

**成功响应（200）：** `ApiResult<TokenPairDTO>`

```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "accessToken": "eyJhbGciOiJSUzI1NiJ9...",
    "refreshToken": "eyJhbGciOiJSUzI1NiJ9...",
    "accessTokenExpiresIn": 1728000000,
    "refreshTokenExpiresIn": 604800000,
    "tokenType": "Bearer"
  },
  "timestamp": 1719123456789
}
```

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0033 | 400 | loginMode 无效或为空 |
| AUTH-0001 | 401 | 用户名或密码错误 |
| AUTH-0023 | 400 | 短信验证码无效 |
| AUTH-0024 | 400 | 短信验证码已过期 |
| AUTH-0026 | 401 | 第三方登录失败 |
| AUTH-0027 | 404 | 第三方账号未绑定 |
| AUTH-0031 | 403 | 账号信息未完善（account_settled=false） |

**向后兼容：** `loginMode` 不传时默认 `USERNAME_PASSWORD` 模式，行为与 v0.1.5 完全一致。

---

#### 4.2.2 多模式注册（修改）

```
POST /api/v1/auth/register
```

**白名单：** 是
**请求参数（RegisterRequest）：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `registerMode` | String | 是 | 注册模式：USERNAME / PHONE_CODE / OAUTH / PHONE_SET_USERNAME / OAUTH_SET_INFO |
| `loginName` | String | 条件必填 | 用户名（仅 USERNAME 模式必填，其他模式自动生成） |
| `password` | String | 条件必填 | 密码（仅 USERNAME 模式必填） |
| `phone` | String | 条件必填 | 手机号（USERNAME / PHONE_CODE / PHONE_SET_USERNAME 模式必填） |
| `email` | String | 可选 | 邮箱（所有模式可选项） |
| `smsCode` | String | 条件必填 | 短信验证码（PHONE_CODE / PHONE_SET_USERNAME 模式必填） |
| `oauthProvider` | String | 条件必填 | OAuth 提供商（OAUTH / OAUTH_SET_INFO 模式必填） |
| `oauthCode` | String | 条件必填 | OAuth 授权码/令牌（OAUTH / OAUTH_SET_INFO 模式必填） |
| `userName` | String | 可选 | 用户姓名（默认取 loginName） |

**注意：** `tenantId` 已移除，由注册逻辑自动关联到租户或使用默认租户。

**成功响应（200）：**

- **USERNAME 模式：** `ApiResult<UserDTO>`（用户基本信息，不含密码，`account_settled=true`）
- **PHONE_CODE / OAUTH 模式：** `ApiResult<RegisterResultDTO>`（含 TokenPairDTO，自动登录，`account_settled=false`）
- **PHONE_SET_USERNAME / OAUTH_SET_INFO 模式：** `ApiResult<RegisterResultDTO>`（含 TokenPairDTO，自动登录，`account_settled=false`）

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0032 | 400 | registerMode 无效或为空 |
| AUTH-0028 | 409 | 手机号已被其他账号绑定 |
| AUTH-0029 | 409 | 第三方账号已被其他用户绑定 |
| AUTH-0023 | 400 | 短信验证码无效 |
| AUTH-0024 | 400 | 短信验证码已过期 |

**向后兼容：** `registerMode` 不传时默认 `USERNAME` 模式，行为与 v0.1.5 完全一致。

---

#### 4.2.3 修改密码（新增）

```
PUT /api/v1/auth/password/change
```

**白名单：** 否（需登录认证）
**请求参数（PasswordChangeRequest）：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `oldPassword` | String | 是 | 原密码（@NotBlank） |
| `newPassword` | String | 是 | 新密码（@Size min=8, max=64） |
| `confirmPassword` | String | 是 | 确认新密码 |

**成功响应（200）：** `ApiResult<Void>`（无 data，message 为"密码修改成功"）

**处理逻辑：**
1. 从 JWT Token 中获取当前用户 ID
2. 校验 `oldPassword`（BCrypt.matches）
3. 校验 `newPassword` 与 `confirmPassword` 一致
4. 校验 `newPassword` 与当前密码不同
5. 新密码 BCrypt 加密更新数据库
6. 更新 `last_password_change_time`
7. 清理该用户所有 Redis 登录态会话（强制重新登录）
8. 敏感信息脱敏记录日志

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0022 | 400 | 原密码错误 |
| AUTH-0002 | 401 | 未登录或 Token 无效 |
| — | 400 | 新密码与确认密码不一致 |
| — | 400 | 新密码不能与原密码相同 |
| — | 400 | 新密码不满足复杂度要求 |

---

#### 4.2.4 密码找回-发送验证码（新增）

```
POST /api/v1/auth/password/forgot/send-code
```

**白名单：** 是
**请求参数：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `target` | String | 是 | 手机号或邮箱地址 |
| `mode` | String | 是 | 发送方式：SMS / EMAIL |

**成功响应（200）：** `ApiResult<Void>`（message 为"验证码已发送"）

**处理逻辑：**
1. 校验 `target` 对应的账号存在（通过手机号或邮箱查询用户）
2. 调用 `VerificationCodeManager.generateCode(target, mode, "RESET_PASSWORD")` 生成验证码
3. 调用 `VerificationCodeService.sendSmsCode/sendEmailCode` 发送验证码
4. 返回发送成功

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0008 | 404 | 账号不存在（target 未绑定任何账号） |
| AUTH-0025 | 429 | 60 秒内重复发送 |

**关联需求说明：** 如果 target 绑定了多个账号（多租户场景），需提示用户输入租户编码以确定具体账号。

---

#### 4.2.5 密码找回-重置密码（新增）

```
POST /api/v1/auth/password/forgot/reset
```

**白名单：** 是
**请求参数（PasswordForgotRequest）：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `target` | String | 是 | 手机号或邮箱地址 |
| `mode` | String | 是 | 找回方式：SMS / EMAIL |
| `code` | String | 是 | 验证码 |
| `newPassword` | String | 是 | 新密码（@Size min=8, max=64） |
| `confirmPassword` | String | 是 | 确认新密码 |

**成功响应（200）：** `ApiResult<Void>`（message 为"密码重置成功"）

**处理逻辑：**
1. 校验 `newPassword` 与 `confirmPassword` 一致
2. 调用 `VerificationCodeManager.verifyCode(target, code, "RESET_PASSWORD")` 校验验证码
3. 验证码校验通过后标记为已使用（防止重放）
4. 使用 BCrypt 加密新密码并更新数据库
5. 更新 `last_password_change_time`
6. 清理该用户所有 Redis 登录态会话（强制重新登录）
7. 敏感信息脱敏记录日志

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0023 | 400 | 验证码无效 |
| AUTH-0024 | 400 | 验证码已过期 |
| — | 400 | 新密码与确认密码不一致 |
| — | 400 | 新密码不能与原密码相同 |

---

#### 4.2.6 修改手机号（新增）

```
PUT /api/v1/auth/phone/change
```

**白名单：** 否（需登录认证）
**请求参数（PhoneChangeRequest）：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `newPhone` | String | 是 | 新手机号 |
| `oldPhoneCode` | String | 条件必填 | 原手机号验证码（原手机号可用时必填） |
| `newPhoneCode` | String | 是 | 新手机号验证码 |
| `emailCode` | String | 条件必填 | 邮箱验证码（原手机号不可用时选填） |

**场景一：原手机号尚在使用**

**处理逻辑：**
1. 校验原手机号验证码（`oldPhoneCode`）
2. 校验新手机号验证码（`newPhoneCode`）
3. 校验新手机号在租户内唯一
4. 校验新手机号与原手机号不同
5. 更新绑定手机号
6. 记录审计日志

**场景二：原手机号已停用（用户绑定邮箱时）**

**处理逻辑：**
1. 校验邮箱验证码（`emailCode`）
2. 校验新手机号验证码（`newPhoneCode`）
3. 校验新手机号在租户内唯一
4. 校验新手机号与原手机号不同
5. 更新绑定手机号
6. 记录审计日志

**场景三：原手机号已停用且用户未绑定邮箱**

**响应：** 返回提示"请联系管理员进行身份核验"，无法通过自助方式变更。

**成功响应（200）：** `ApiResult<Void>`（message 为"手机号修改成功"）

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0023 | 400 | 验证码无效 |
| AUTH-0024 | 400 | 验证码已过期 |
| AUTH-0028 | 409 | 新手机号已被其他账号绑定 |
| — | 400 | 新手机号与原手机号相同 |
| — | 400 | 手机号格式不合法 |

---

#### 4.2.7 完善账号信息（新增）

```
PUT /api/v1/auth/account/settlement
```

**白名单：** 否（需登录认证）
**请求参数（AccountSettlementRequest）：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `userId` | Long | 是 | 用户 ID |
| `loginName` | String | 条件必填 | 用户名（PHONE_SET_USERNAME 模式必填） |
| `password` | String | 条件必填 | 密码（OAUTH_SET_INFO 模式必填） |
| `phone` | String | 条件必填 | 手机号（OAUTH_SET_INFO 模式必填） |
| `smsCode` | String | 条件必填 | 手机验证码（OAUTH_SET_INFO 模式必填） |

**处理逻辑：**
1. 校验当前用户属于"未完善"状态（`account_settled=false`）
2. 根据用户的 `register_mode` 字段校验必填参数
3. 更新账号信息（loginName/password/phone 等）
4. 设置 `account_settled=true`
5. 如涉及 OAuth 模式，绑定手机号并验证（`OAUTH_SET_INFO` 模式）

**成功响应（200）：** `ApiResult<UserDTO>`（完善后的用户基本信息）

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0031 | 403 | 账号信息已完善，不可重复操作 |
| AUTH-0028 | 409 | 手机号已被其他账号绑定 |
| — | 400 | 参数校验错误 |

---

#### 4.2.8 发送验证码（新增）

```
POST /api/v1/auth/verification-code/send
```

**白名单：** 是
**请求参数（SendVerificationCodeRequest）：**

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `target` | String | 是 | 手机号或邮箱地址 |
| `purpose` | String | 是 | 用途：REGISTER / LOGIN / RESET_PASSWORD / CHANGE_PHONE |
| `mode` | String | 是 | 发送方式：SMS / EMAIL |

**成功响应（200）：** `ApiResult<Void>`（message 为"验证码已发送"）

**处理逻辑：**
1. 校验参数合法性
2. 调用 `VerificationCodeManager.isSendTooFrequent(target, purpose)` 检查发送频率
3. 调用 `VerificationCodeManager.generateCode(target, mode, purpose)` 生成 6 位数字验证码
4. 写入 Redis（TTL 5分钟）+ 数据库持久化
5. 调用 `VerificationCodeService` 发送验证码（模拟实现输出到日志）
6. 返回发送成功

**错误场景：**

| 错误码 | HTTP 状态码 | 场景 |
|--------|-------------|------|
| AUTH-0025 | 429 | 60 秒内重复发送 |
| — | 400 | target 格式不合法 |

---

### 4.3 错误码定义

#### v0.1.6 新增错误码（AUTH-0020 ~ AUTH-0033）

| 错误码 | 枚举名称 | HTTP 状态码 | 描述 | 所属场景 |
|--------|----------|-------------|------|----------|
| AUTH-0020 | `PASSWORD_RESET_TOKEN_INVALID` | 400 | 密码重置令牌无效 | 密码找回（预留，当前基于验证码实现） |
| AUTH-0021 | `PASSWORD_RESET_TOKEN_EXPIRED` | 400 | 密码重置令牌已过期 | 密码找回（预留，当前基于验证码实现） |
| AUTH-0022 | `OLD_PASSWORD_INCORRECT` | 400 | 原密码错误 | 修改密码 |
| AUTH-0023 | `SMS_CODE_INVALID` | 400 | 短信验证码无效 | 注册/登录/密码找回/手机号变更 |
| AUTH-0024 | `SMS_CODE_EXPIRED` | 400 | 短信验证码已过期 | 注册/登录/密码找回/手机号变更 |
| AUTH-0025 | `SMS_SEND_TOO_FREQUENT` | 429 | 验证码发送过于频繁 | 发送验证码 |
| AUTH-0026 | `OAUTH_LOGIN_FAILED` | 401 | 第三方登录失败 | OAuth 登录/注册 |
| AUTH-0027 | `OAUTH_ACCOUNT_NOT_BOUND` | 404 | 第三方账号未绑定 | OAuth 登录 |
| AUTH-0028 | `PHONE_ALREADY_BOUND` | 409 | 手机号已被其他账号绑定 | 注册/手机号变更 |
| AUTH-0029 | `OAUTH_ACCOUNT_ALREADY_BOUND` | 409 | 第三方账号已被其他用户绑定 | OAuth 注册 |
| AUTH-0030 | `EMAIL_VERIFICATION_REQUIRED` | 403 | 需要邮箱验证 | 手机号变更（原手机号不可用） |
| AUTH-0031 | `ACCOUNT_NOT_SETTLED` | 403 | 账号信息未完善，请先补充资料 | 登录（两步注册未完成） |
| AUTH-0032 | `REGISTER_MODE_INVALID` | 400 | 无效的注册模式 | 注册 |
| AUTH-0033 | `LOGIN_MODE_INVALID` | 400 | 无效的登录模式 | 登录 |

---

## 5. 安全设计

### 5.1 认证机制

| 机制 | 说明 |
|------|------|
| **JWT 双 Token 认证** | 继承 v0.1.5 的 RS256 非对称签名机制，Access Token（2h）+ Refresh Token（7d） |
| **策略模式认证编排** | `AuthenticationService` 统一编排凭证校验和 Token 签发，确保所有登录模式后处理流程一致 |
| **密码重置清理会话** | 密码修改/重置成功后，清理该用户所有 Redis 登录态会话，强制重新登录 |
| **OAuth 账号防重复绑定** | 同一 OAuth 提供商 + openId 在平台内全局唯一（唯一索引 `uk_provider_openid`） |

### 5.2 数据安全

| 安全措施 | 说明 |
|----------|------|
| **BCrypt 密码加密** | 密码存储强度系数≥10，新旧密码不在日志、响应体、异常信息中明文输出 |
| **验证码一次性使用** | 校验后立即标记 used=1，Redis + 数据库双重保障，防止重放攻击 |
| **验证码频率控制** | 同一 target 同一用途 60 秒内不可重复发送，Redis 频控 Key 自动过期 |
| **验证码生命周期** | 6 位数字，有效期 5 分钟，过期自动失效 |
| **密码规范** | 最小长度 8 位，最大长度 64 位，必须包含字母和数字 |
| **敏感日志脱敏** | 手机号、邮箱、密码等敏感信息在日志中需脱敏处理 |
| **手机号唯一性** | 新手机号在租户内唯一，防止账号混淆 |

---

## 6. 非功能需求设计

### 6.1 性能指标

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 登录接口响应时间 | ≤ 500ms | 含密码/验证码校验和 Token 签发，四种模式统一标准 |
| 注册接口响应时间 | ≤ 500ms | 五种注册模式统一标准 |
| 验证码生成接口响应时间 | ≤ 200ms | 不含实际短信/邮件发送耗时（模拟发送） |
| 策略调度层开销 | 零额外开销 | 策略实例预先初始化（Spring 容器管理），运行时 O(1) 获取 |

### 6.2 可扩展性

| 扩展场景 | 实现方式 |
|----------|----------|
| 新增登录模式 | 创建 `LoginStrategy` 实现类 + 注册到 `LoginStrategyFactory` |
| 新增注册模式 | 创建 `RegisterStrategy` 实现类 + 注册到 `RegisterStrategyFactory` |
| 新增验证码发送渠道 | 实现 `VerificationCodeService` 接口 + 替换注入 |
| 新增两步注册类型 | 创建新 RegisterStrategy + AccountSettlementRequest 扩展字段 |

### 6.3 安全性

| 约束 | 说明 |
|------|------|
| 密码加密 | 必须使用 BCrypt（强度系数≥10），禁止 MD5/SHA |
| 验证码安全 | 6 位数字，5 分钟有效期，一次性使用，60 秒发送间隔 |
| 日志安全 | 密码、验证码等敏感信息不得明文输出 |
| 会话安全 | 密码修改/重置后必须清理登录态会话 |
| OAuth 安全 | 绑定 OAuth 账号时校验未被其他用户绑定 |

---

## 7. 风险与缓解措施

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 策略实现类过多导致维护成本上升 | 可维护性下降 | 每个策略类不超过 200 行，命名规范统一，职责单一 |
| OAuth 回调流程复杂 | 开发周期延长 | 本期简化为授权码模式（code），前端获取 code 后传给后端 |
| 验证码模拟实现与真实网关差异 | 验证码流程未充分验证 | 模拟实现覆盖完整生命周期（生成/校验/过期/频率控制） |
| Redis 不可用时验证码管理降级 | 可用性下降 | Redis 不可用时回退到数据库存储，保证验证码基本功能可用 |
| 两步注册用户忘记补充信息 | 用户体验下降 | 登录时返回 `ACCOUNT_NOT_SETTLED` 错误，引导完善资料 |

---

## 8. 附录

### 8.1 配置项

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `app.verification-code.mock` | `true` | 是否启用验证码模拟模式 |
| `app.verification-code.expire-seconds` | `300`（5分钟） | 验证码过期时间（秒） |
| `app.verification-code.send-interval-seconds` | `60` | 验证码发送间隔（秒） |
| `app.verification-code.length` | `6` | 验证码长度 |
| `app.password.min-length` | `8` | 密码最小长度 |
| `app.password.max-length` | `64` | 密码最大长度 |

### 8.2 新增依赖

| 依赖 | 版本 | 用途 | 使用模块 |
|------|------|------|----------|
| `spring-boot-starter-mail` | 3.2.5（继承 Boot Parent） | 邮件发送支持 | auth-service |

### 8.3 网关白名单完整列表

```
POST /api/v1/auth/login                     # 登录（所有模式）
POST /api/v1/auth/register                  # 注册（所有模式）
POST /api/v1/auth/refresh                   # Token 刷新
POST /api/v1/auth/verification-code/send    # [v0.1.6 新增] 发送验证码
POST /api/v1/auth/password/forgot/send-code # [v0.1.6 新增] 密码找回-发送验证码
POST /api/v1/auth/password/forgot/reset     # [v0.1.6 新增] 密码找回-重置密码
GET  /api/v1/auth/health                    # 健康检查
/swagger-ui/**                              # API 文档
/v3/api-docs/**                             # API 文档
/favicon.ico                                # 图标
```

### 8.4 设计决策汇总（ADR 对应）

| ADR 编号 | 决策内容 | 选择理由 |
|----------|----------|----------|
| ADR-017 | 策略模式 + 工厂模式扩展认证模式 | 开闭原则，新增认证方式无需修改核心逻辑 |
| ADR-018 | 验证码存储：Redis 优先 + 数据库回退 | Redis TTL 自动过期，减少清理负担；DB 兜底保证可用性 |
| ADR-019 | 密码找回不新增独立令牌表，基于验证码记录表实现 | 验证码一次性使用已满足安全需求，减少维护成本 |
| ADR-020 | 验证码发送渠道：接口抽象 + 模拟实现 | 与具体发送渠道解耦，模拟实现不依赖真实短信/邮件网关 |
