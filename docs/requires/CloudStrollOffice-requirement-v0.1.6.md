# 需求文档

**项目名称：** 云漫智企 (CloudStrollOffice)
**版本号：** v0.1.6
**日期：** 2026-06-23

---

## 修订记录

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| v0.1.6 | 2026-06-23 | 初始版本，定义用户认证增强需求（多模式注册/登录/密码管理/手机号变更） | BA |

---

## 1. 项目背景

### 1.1 业务背景

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务互联网应用程序。v0.1.0 阶段完成了微服务基础骨架搭建，v0.1.5 阶段完成了完整的登录认证与权限管理系统（用户-角色-权限 RBAC 模型、多端混合登录、JWT+Redis 双重会话管理、双 Token 续签机制、登录日志审计等），为企业级认证授权提供了坚实基础。

v0.1.5 阶段实现的认证能力包括：
- 单一用户名+密码登录模式
- 用户名+密码+手机号的注册模式
- JWT 双 Token 机制（Access Token 2h + Refresh Token 7d）
- Redis 登录态管理与黑名单
- 多端混合登录与同端互斥
- 用户-角色-权限（RBAC）完整管理

当前认证体系虽然提供了核心的登录认证能力，但**在注册和登录方式上较为单一**，缺少对**手机验证码登录、第三方 OAuth 登录、密码找回、手机号变更**等现代互联网应用必备的用户体验支持，无法满足 SaaS 平台多样化的用户接入场景。

v0.1.6 阶段的目标是**完成用户认证能力的全面增强**，实现多模式注册与登录、统一认证服务层、用户密码管理、手机号变更等核心功能，使平台的认证体系覆盖主流互联网应用的用户接入场景。

### 1.2 业务痛点

1. **注册方式单一：** 当前仅支持用户名+密码+手机号注册，缺少手机短信验证码注册、第三方 OAuth 注册等便捷方式，用户接入门槛高
2. **登录方式单一：** 当前仅支持用户名+密码登录，不支持手机验证码登录、手机+密码登录、第三方 OAuth 登录，用户使用场景受限
3. **密码管理缺失：** 缺少用户自主修改密码和密码找回功能，用户在忘记密码时无法自助恢复账号访问，需联系管理员处理，体验差
4. **手机号变更困难：** 用户更换手机号后无法自助更新绑定手机号，可能因为原手机号已停用导致无法验证，缺乏完善的变更方案
5. **OAuth 集成为零：** 尚未对接任何第三方 OAuth 认证源（微信、钉钉、企业微信等），无法满足企业用户"一键登录"的诉求
6. **认证流程同质化：** 后端代码中未对不同的登录方式进行抽象解耦，新增登录方式需要修改现有核心逻辑，扩展性差

### 1.3 项目目标

1. 支持 6 种注册方式，满足不同用户场景的注册需求
2. 支持 4 种登录方式，用户可根据偏好和场景任选一种
3. 设计统一认证服务层，实现"按模式校验凭证 → 统一签发 Token → 统一处理会话"的标准化流程
4. 提供用户自主修改密码和密码找回功能，支持邮箱和手机短信两种找回渠道
5. 提供用户手机号变更功能，覆盖原手机号尚在使用和已停用两种场景
6. 扩展认证错误码体系，新增密码、短信验证码、OAuth、手机号相关错误码
7. 新增 OAuth 账号绑定表、验证码记录表、密码重置令牌表等数据库表

### 1.4 适用范围

本文档适用于 CloudStrollOffice v0.1.6 版本的开发，覆盖用户认证增强的全部需求范围，涉及 `cloudoffice-common`、`cloudoffice-auth-service` 两个模块的修改与扩展。

---

## 2. 总体需求描述

### 2.1 角色定义

| 角色 | 描述 |
|------|------|
| 未注册用户 | 尚未在平台创建账号的新用户，可通过多种注册方式创建账号 |
| 已注册用户 | 已完成账号注册的用户，可通过多种登录方式接入平台 |
| 第三方用户 | 通过第三方 OAuth 平台（微信、钉钉等）进行认证的用户 |
| 系统管理员 | 可查看和管理用户账号、处理账号安全问题 |

### 2.2 注册方式定义

| 注册模式标识 | 注册方式 | 说明 |
|-------------|----------|------|
| `USERNAME` | 用户名+密码+手机号注册 | 传统注册方式，用户名在租户内唯一 |
| `PHONE_CODE` | 手机+手机短信验证码注册 | 输入手机号，接收短信验证码完成注册 |
| `OAUTH` | 第三方 OAuth 注册 | 通过微信、钉钉等第三方平台授权注册 |
| `PHONE_SET_USERNAME` | 手机注册后设置用户名 | 先用手机+验证码创建临时账号，后续补充用户名 |
| `OAUTH_SET_INFO` | OAuth 注册后设置用户名、密码、手机 | 先用 OAuth 创建临时账号，后续补充完整信息 |
| `EMAIL_OPTIONAL` | 注册时邮箱作为可选项 | 所有注册方式中邮箱均为可选项 |

**重要说明：** `PHONE_SET_USERNAME` 和 `OAUTH_SET_INFO` 属于**两步式注册**（分步注册），首次仅创建基础账号，后续补充完整资料。两步注册之间的状态由数据库字段 `account_settled`（账号是否已完善）标识。

### 2.3 登录方式定义

| 登录模式标识 | 登录方式 | 说明 |
|-------------|----------|------|
| `USERNAME_PASSWORD` | 用户名+密码 | 传统登录方式 |
| `PHONE_CODE` | 手机+验证码 | 短信验证码登录 |
| `PHONE_PASSWORD` | 手机+密码 | 支持使用已绑定手机号 + 密码登录 |
| `OAUTH` | 第三方 OAuth 登录 | 通过微信、钉钉等第三方平台授权登录 |

**登录互斥规则：** 四种登录方式**任选一种**进行认证。登录请求中通过 `loginMode` 字段标识本次使用的登录方式，不同登录方式使用不同的请求参数字段。

### 2.4 统一认证服务层设计

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          客户端（多端多模式）                              │
│   注册: USERNAME / PHONE_CODE / OAUTH / 两步注册                        │
│   登录: USERNAME_PASSWORD / PHONE_CODE / PHONE_PASSWORD / OAUTH        │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    统一认证服务层 AuthenticationService                   │
│                                                                         │
│  ┌─────────────────────┐    ┌───────────────────────────────────────┐  │
│  │  认证策略调度层       │    │  凭证校验 → 认证成功 → 统一后处理      │  │
│  │                     │    │                                       │  │
│  │  ┌─────────────────┐│    │  1. 签发 JWT 双 Token                 │  │
│  │  │ 登录策略工厂      ││    │  2. 写入 Redis 登录态会话             │  │
│  │  │ LoginStrategy    ││    │  3. 多端互斥处理                     │  │
│  │  │  ├─ UsernamePwd  ││    │  4. 账号/租户状态缓存                 │  │
│  │  │  ├─ PhoneCode    ││    │  5. 登录日志审计                     │  │
│  │  │  ├─ PhonePwd     ││    │  6. 更新最后登录时间/IP               │  │
│  │  │  └─ OAuth        ││    └───────────────────────────────────────┘  │
│  │  └─────────────────┘│                                                │
│  │                     │                                                │
│  │  ┌─────────────────┐│                                                │
│  │  │ 注册策略工厂      ││                                                │
│  │  │ RegisterStrategy ││                                                │
│  │  │  ├─ UsernamePwd  ││                                                │
│  │  │  ├─ PhoneCode    ││                                                │
│  │  │  ├─ OAuth        ││                                                │
│  │  │  ├─ PhoneSetUsr  ││                                                │
│  │  │  └─ OAuthSetInfo ││                                                │
│  │  └─────────────────┘│                                                │
│  └─────────────────────┘                                                │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         基础设施层                                       │
│  ┌──────────────┐  ┌──────────────────────┐  ┌──────────────────────┐  │
│  │ MariaDB      │  │ Redis 7.2.x          │  │ 短信/邮件服务        │  │
│  │ (用户/认证    │  │ (登录态会话缓存 +    │  │ (短信验证码发送/     │  │
│  │  表扩展/OAuth│  │  Token黑名单缓存)    │  │  邮件发送)           │  │
│  │  绑定/验证码) │  └──────────────────────┘  └──────────────────────┘  │
│  └──────────────┘                                                       │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.5 核心流程说明

#### 2.5.1 多模式登录流程

```
Client → POST /api/v1/auth/login { loginMode, ...根据不同mode携带不同凭证 }
  → AuthController.login()
  → LoginStrategyFactory.getStrategy(loginMode)
    → UsernamePasswordStrategy.login(request)     // 校验用户名+密码
    → PhoneCodeStrategy.login(request)             // 校验手机+短信验证码
    → PhonePasswordStrategy.login(request)         // 校验手机+密码
    → OAuthStrategy.login(request)                 // 校验第三方 OAuth 凭证
  → 校验通过 → 统一认证后处理（和v0.1.5相同的JWT+Redis处理流程）
  → 返回 TokenPairDTO
```

#### 2.5.2 多模式注册流程

```
Client → POST /api/v1/auth/register { registerMode, ...根据不同mode携带不同凭证 }
  → AuthController.register()
  → RegisterStrategyFactory.getStrategy(registerMode)
    → UsernamePwdStrategy.register(request)        // 用户名+密码+手机
    → PhoneCodeStrategy.register(request)          // 手机+短信验证码
    → OAuthStrategy.register(request)              // OAuth 第三方注册
    → PhoneSetUsernameStrategy.register(request)   // 手机注册，后续设置用户名
    → OAuthSetInfoStrategy.register(request)       // OAuth 注册，后续完善信息
  → 校验通过 → 创建用户 → 返回用户基本信息
```

#### 2.5.3 密码找回流程

```
Client → POST /api/v1/auth/password/forgot { mode: EMAIL | SMS, target, code, newPassword }
  → 前端页面展示找回渠道选择（邮箱/手机）
  → 用户选择渠道 → 输入目标（邮箱/手机号）
  → 后端发送验证码（邮箱验证码/短信验证码）
  → 用户输入验证码 + 新密码
  → 后端校验验证码 → 更新密码（BCrypt）
  → 通知用户密码已修改
```

#### 2.5.4 手机号变更流程

```
【场景一：原手机号尚在使用】
  → 用户发起变更 → 系统发送验证码至原手机号
  → 用户输入原手机验证码 → 校验通过
  → 发送验证码至新手机号
  → 用户输入新手机验证码 → 校验通过
  → 更新绑定手机号

【场景二：原手机号已停用】
  → 用户发起变更 → 选择"原手机号已停用" → 转入人工/邮箱验证
  → 邮箱验证：发送验证码至绑定邮箱
  → 邮箱验证码通过后 → 发送验证码至新手机号
  → 用户输入新手机验证码 → 校验通过
  → 更新绑定手机号
  → （如用户邮箱也未绑定，需联系管理员进行身份核验）
```

---

## 3. 功能需求

### 3.1 公共模块增强

#### FR-001: 注册登录模式枚举

- **描述：** 在 `cloudoffice-common` 模块中新增注册模式枚举 `RegisterModeEnum` 和登录模式枚举 `LoginModeEnum`，用于标识不同的注册和登录方式。
- **优先级：** 高 (Must)
- **验收标准：**
  1. `RegisterModeEnum` 位于 `org.cloudstrolling.cloudoffice.common.enums` 包下
  2. 枚举值包含：`USERNAME`（用户名+密码+手机注册）、`PHONE_CODE`（手机+短信验证码注册）、`OAUTH`（第三方 OAuth 注册）、`PHONE_SET_USERNAME`（手机注册后设置用户名）、`OAUTH_SET_INFO`（OAuth 注册后设置用户名/密码/手机）
  3. 每个枚举值包含：`code`（String）、`label`（String）、`requiresPhone`（boolean，是否需要手机号）
  4. 提供 `fromCode(String code)` 静态方法，根据 code 获取枚举值
  5. `LoginModeEnum` 位于同包下
  6. 枚举值包含：`USERNAME_PASSWORD`（用户名+密码）、`PHONE_CODE`（手机+验证码）、`PHONE_PASSWORD`（手机+密码）、`OAUTH`（第三方 OAuth）
  7. 每个枚举值包含：`code`（String）、`label`（String）

#### FR-002: 认证错误码扩展

- **描述：** 在 `ErrorCode` 枚举中新增密码管理、短信验证码、OAuth 认证、手机号变更等相关错误码。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 新增以下错误码：

     | 错误码 | 枚举名称 | HTTP 状态码 | 描述 |
     |--------|----------|-------------|------|
     | AUTH-0020 | `PASSWORD_RESET_TOKEN_INVALID` | 400 | 密码重置令牌无效 |
     | AUTH-0021 | `PASSWORD_RESET_TOKEN_EXPIRED` | 400 | 密码重置令牌已过期 |
     | AUTH-0022 | `OLD_PASSWORD_INCORRECT` | 400 | 原密码错误 |
     | AUTH-0023 | `SMS_CODE_INVALID` | 400 | 短信验证码无效 |
     | AUTH-0024 | `SMS_CODE_EXPIRED` | 400 | 短信验证码已过期 |
     | AUTH-0025 | `SMS_SEND_TOO_FREQUENT` | 429 | 验证码发送过于频繁 |
     | AUTH-0026 | `OAUTH_LOGIN_FAILED` | 401 | 第三方登录失败 |
     | AUTH-0027 | `OAUTH_ACCOUNT_NOT_BOUND` | 404 | 第三方账号未绑定 |
     | AUTH-0028 | `PHONE_ALREADY_BOUND` | 409 | 手机号已被其他账号绑定 |
     | AUTH-0029 | `OAUTH_ACCOUNT_ALREADY_BOUND` | 409 | 第三方账号已被其他用户绑定 |
     | AUTH-0030 | `EMAIL_VERIFICATION_REQUIRED` | 403 | 需要邮箱验证 |
     | AUTH-0031 | `ACCOUNT_NOT_SETTLED` | 403 | 账号信息未完善，请先补充资料 |
     | AUTH-0032 | `REGISTER_MODE_INVALID` | 400 | 无效的注册模式 |
     | AUTH-0033 | `LOGIN_MODE_INVALID` | 400 | 无效的登录模式 |

  2. 新增的枚举保持与现有 ErrorCode 一致的代码风格

#### FR-003: OAuth 提供商枚举

- **描述：** 在 `cloudoffice-common` 模块中新增第三方 OAuth 提供商枚举 `OAuthProviderEnum`，定义支持的第三方认证源。
- **优先级：** 中 (Should)
- **验收标准：**
  1. 枚举位于 `org.cloudstrolling.cloudoffice.common.enums` 包下
  2. 枚举值包含（预留扩展，本期至少包含）：
     - `WECHAT`（微信开放平台）
     - `DINGTALK`（钉钉）
     - `WECHAT_WORK`（企业微信）
     - `ALIPAY`（支付宝，预留）
  3. 每个枚举值包含：`code`（String）、`label`（String）
  4. 提供 `fromCode(String code)` 静态方法

#### FR-004: 认证相关 DTO 扩展

- **描述：** 在 `cloudoffice-common` 和 `cloudoffice-auth-service` 中新增和修改认证相关的 DTO。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **修改 `LoginRequest`（auth-service）：**
     - 新增 `loginMode` 字段（String，标识登录模式，如 `USERNAME_PASSWORD`、`PHONE_CODE`、`PHONE_PASSWORD`、`OAUTH`）
     - `loginName` 改为可选（仅 `USERNAME_PASSWORD` 模式必填）
     - `password` 改为可选（仅 `USERNAME_PASSWORD`、`PHONE_PASSWORD` 模式必填）
     - 新增 `phone` 字段（String，可选，`PHONE_CODE`、`PHONE_PASSWORD` 模式必填）
     - 新增 `smsCode` 字段（String，可选，`PHONE_CODE` 模式必填）
     - 新增 `oauthProvider` 字段（String，可选，`OAUTH` 模式必填）
     - 新增 `oauthCode` 或 `oauthToken` 字段（String，可选，`OAUTH` 模式必填）
     - 保留 `tenantCode`（所有模式必填）和 `clientType`（所有模式必填）

  2. **修改 `RegisterRequest`（auth-service）：**
     - 新增 `registerMode` 字段（String，标识注册模式，如 `USERNAME`、`PHONE_CODE`、`OAUTH` 等）
     - 字段按需改为可选（不同注册模式下必填字段不同）
     - 新增 `smsCode` 字段（String，可选，`PHONE_CODE` 模式必填）
     - 新增 `oauthProvider` 字段（String，可选，`OAUTH` 模式必填）
     - 新增 `oauthCode` 或 `oauthToken` 字段（String，可选，`OAUTH` 模式必填）
     - 移除 `tenantId` 字段（由注册逻辑自动关联到租户或使用默认租户）

  3. **新增 `PasswordChangeRequest`（auth-service）：**
     - `oldPassword`（String，原密码，@NotBlank）
     - `newPassword`（String，新密码，@Size 8-64）
     - `confirmPassword`（String，确认新密码）

  4. **新增 `PasswordForgotRequest`（auth-service）：**
     - `mode`（String，找回方式：`EMAIL` / `SMS`）
     - `target`（String，邮箱地址或手机号）
     - `code`（String，验证码）
     - `newPassword`（String，新密码，@Size 8-64）

  5. **新增 `SendVerificationCodeRequest`（auth-service）：**
     - `target`（String，手机号或邮箱）
     - `purpose`（String，用途：`REGISTER` / `LOGIN` / `RESET_PASSWORD` / `CHANGE_PHONE`）
     - `mode`（String，发送方式：`SMS` / `EMAIL`）

  6. **新增 `PhoneChangeRequest`（auth-service）：**
     - `newPhone`（String，新手机号）
     - `oldPhoneCode`（String，原手机号验证码，原手机号可用时必填）
     - `newPhoneCode`（String，新手机号验证码）
     - `emailCode`（String，邮箱验证码，原手机号不可用时选填）

  7. **新增 `AccountSettlementRequest`（auth-service）：**
     - 用于两步注册中补充信息
     - `userId`（Long，用户 ID）
     - `loginName`（String，用户名，`PHONE_SET_USERNAME` 模式必填）
     - `password`（String，密码，`OAUTH_SET_INFO` 模式必填）
     - `phone`（String，手机号，`OAUTH_SET_INFO` 模式必填）
     - `smsCode`（String，手机验证码，`OAUTH_SET_INFO` 模式必填）

---

### 3.2 多模式注册

#### FR-005: 多模式注册 API

- **描述：** 重构现有注册接口，支持 5 种注册模式，通过策略模式实现注册逻辑的灵活扩展。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`POST /api/v1/auth/register`
  2. 请求参数支持 `registerMode` 字段标识注册模式
  3. **模式一 - 用户名+密码+手机号注册（USERNAME）：**
     - 与现有注册逻辑一致
     - 必填：`loginName`、`password`、`phone`（手机号）
     - `userName` 改为可选（默认取 `loginName`）
     - `email` 改为可选
  4. **模式二 - 手机+短信验证码注册（PHONE_CODE）：**
     - 必填：`phone`、`smsCode`
     - 不需要 `loginName` 和 `password`
     - 验证码校验通过后自动创建用户
     - `loginName` 自动生成（如 `user_{phone_hash}` 或用户后续设置）
     - `password` 自动生成随机密码或暂为空（后续补充）
     - 用户状态为"未完善"（`account_settled = false`）
  5. **模式三 - 第三方 OAuth 注册（OAUTH）：**
     - 必填：`oauthProvider`、`oauthCode`/`oauthToken`
     - 通过 OAuth 提供商获取用户基本信息（openId、昵称、头像等）
     - 创建用户并绑定 OAuth 账号
     - `loginName` 自动生成
     - 用户状态为"未完善"（`account_settled = false`）
  6. **模式四 - 手机注册后设置用户名（PHONE_SET_USERNAME）：**
     - 调用注册接口时与模式二相同，但标记后续需要补充用户名
     - 用户首次登录后引导至"完善资料"页面
     - 提供独立 API 用于补充用户名：`PUT /api/v1/auth/account/settlement`
  7. **模式五 - OAuth 注册后设置用户名、密码、手机（OAUTH_SET_INFO）：**
     - 调用注册接口时与模式三相同，但标记后续需要补充信息
     - 提供独立 API 用于补充完整信息：`PUT /api/v1/auth/account/settlement`
  8. **通用规则：**
     - 所有模式中 `email` 均为可选项
     - 手机号在注册时校验租户内唯一性
     - OAuth 的 openId 在平台内全局唯一
     - 注册成功后返回用户基本信息（不含密码）
     - 手机注册和 OAuth 注册成功后直接返回 TokenPairDTO（完成自动登录）
  9. **新增接口 - 完善账号信息：**
     - API：`PUT /api/v1/auth/account/settlement`
     - 用于两步注册中第二步完善资料
     - 校验当前用户属于"未完善"状态
     - 成功后更新 `account_settled = true`

---

### 3.3 多模式登录

#### FR-006: 多模式登录 API

- **描述：** 重构现有登录接口，支持 4 种登录模式。通过策略模式（`LoginStrategy` 接口）解耦不同登录方式的校验逻辑，校验通过后由统一的认证后处理流程签发 Token。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`POST /api/v1/auth/login`（同一接口，通过 `loginMode` 字段区分）
  2. **模式一 - 用户名+密码登录（USERNAME_PASSWORD）：**
     - 保留现有逻辑，通过 `loginName` + `password` 校验
     - 原有 `LoginRequest` 中 `loginName`、`password` 仅在此模式必填
  3. **模式二 - 手机+验证码登录（PHONE_CODE）：**
     - 通过 `phone` + `smsCode`（短信验证码）校验
     - 校验验证码有效性、过期时间
     - 通过手机号查找用户，支持多租户场景（需同时提供 `tenantCode`）
  4. **模式三 - 手机+密码登录（PHONE_PASSWORD）：**
     - 通过 `phone` + `password` 校验
     - 使用 BCrypt 验证密码
     - 通过手机号查找用户
  5. **模式四 - 第三方 OAuth 登录（OAUTH）：**
     - 通过 `oauthProvider` + `oauthCode`/`oauthToken` 校验
     - 调用 OAuth 提供商 API 获取 access_token 和用户信息
     - 通过 openId 关联平台用户
  6. **统一认证后处理（所有模式共享）：**
     - 校验租户状态
     - 校验用户状态
     - 构建 LoginUserDTO
     - 签发 JWT 双 Token（Access Token 2h + Refresh Token 7d）
     - 同端互斥处理
     - 写入 Redis 登录态
     - 缓存账号/租户状态
     - 记录登录日志
     - 更新最后登录时间和 IP
  7. 使用策略模式设计，`LoginStrategy` 接口定义 `authenticate(LoginRequest)` 方法
  8. `LoginStrategyFactory` 根据 loginMode 获取对应的策略实现
  9. 新增策略实现类不得修改现有核心登录后处理逻辑

---

### 3.4 统一认证服务层

#### FR-007: 统一认证服务层设计

- **描述：** 在认证服务中设计统一的认证服务层（`AuthenticationService`），将凭证校验与 Token 签发/会话管理解耦，确保不同登录模式共享同一套认证后处理流程。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **架构设计：**
     - `LoginStrategy` 接口：定义 `authenticate(LoginRequest)` 方法，返回 `AuthResult` 对象
       - `AuthResult` 包含：`userId`、`tenantId`、`loginName`、`userName`、`phone`、`roles`、`permissions`
     - `LoginStrategyFactory`：根据 `loginMode` 返回对应的策略实现
     - `AuthenticationService`：编排"策略校验 → 统一后处理"流程
  2. **统一后处理流程（`AuthenticationService.authenticate()`）：**
     - 调用 `LoginStrategyFactory.getStrategy(loginMode).authenticate(request)` 获取 AuthResult
     - 校验租户状态（调用 `checkTenantStatus`）
     - 校验用户状态（调用 `checkUserStatus`）
     - 构建 `LoginUserDTO`
     - 签发 JWT 双 Token
     - 同端互斥处理
     - 写入 Redis 登录态
     - 缓存账号/租户状态
     - 记录登录日志
     - 更新最后登录时间和 IP
     - 返回 TokenPairDTO
  3. **注册策略模式（`RegisterStrategy` 接口）：**
     - 定义 `register(RegisterRequest)` 方法，返回 `RegisterResult`
     - `RegisterStrategyFactory`：根据 `registerMode` 返回对应的策略实现
  4. 策略模式的基类和工厂位于 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下
  5. 新增登录模式时，仅需新增 `LoginStrategy` 实现并注册到工厂，无需修改核心流程

---

### 3.5 密码管理

#### FR-008: 用户修改密码 API

- **描述：** 提供已登录用户修改自己密码的功能，需要验证原密码。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`PUT /api/v1/auth/password/change`
  2. 请求头携带 `Authorization: Bearer <accessToken>`（用户需登录）
  3. 请求参数：`oldPassword`、`newPassword`、`confirmPassword`
  4. 校验规则：
     - 校验原密码是否正确（BCrypt 匹配）
     - 校验新密码与确认密码一致
     - 校验新密码与旧密码不同（不可重复使用）
     - 新密码长度 8~64 字符，必须包含字母和数字
  5. 校验通过后使用 BCrypt 加密新密码并更新数据库
  6. 更新成功后，当前用户的所有登录态会话需重新登录（可选：仅刷新当前会话的 Token，或踢下线所有端）
  7. 返回操作成功，不返回密码
  8. **安全要求：**
     - 新密码不能与原密码相同
     - 新旧密码均不在日志中明文输出
     - 修改密码后建议重新登录（刷新 Token）

#### FR-009: 用户密码找回 API

- **描述：** 提供用户通过邮箱或手机短信验证码找回密码的功能，整个找回流程在前端页面完成。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **发送验证码接口：**
     - API：`POST /api/v1/auth/password/forgot/send-code`
     - 请求参数：`target`（手机号或邮箱）、`mode`（`SMS` / `EMAIL`）
     - 校验 target 对应的账号是否存在
     - 生成验证码并发送（短信/邮件）
     - 验证码有效期 5 分钟
     - 同一 target 发送间隔不低于 60 秒
  2. **密码重置接口：**
     - API：`POST /api/v1/auth/password/forgot/reset`
     - 请求参数：`target`、`mode`、`code`（验证码）、`newPassword`、`confirmPassword`
     - 校验验证码有效性和过期时间
     - 验证码使用后立即标记为已使用（防止重复使用）
     - 使用 BCrypt 加密新密码并更新数据库
     - 返回操作成功
  3. **前端交互流程：**
     - 步骤一：用户选择找回方式（邮箱/手机）→ 输入目标
     - 步骤二：点击"发送验证码"→ 输入验证码 + 新密码
     - 步骤三：提交重置 → 成功后跳转登录页
  4. **安全要求：**
     - 验证码为 6 位数字
     - 重置成功后清理该用户的所有 Redis 登录态会话
     - 敏感信息脱敏记录日志

---

### 3.6 手机号管理

#### FR-010: 用户修改手机号 API

- **描述：** 提供已登录用户变更绑定手机号的功能，需根据原手机号状态（尚在使用/已停用）采用不同的验证流程。
- **优先级：** 中 (Should)
- **验收标准：**
  1. API：`PUT /api/v1/auth/phone/change`
  2. 请求头携带 `Authorization: Bearer <accessToken>`（用户需登录）
  3. **场景一：原手机号尚在使用**
     - 流程：
       a. 发送验证码至原手机号 → 用户输入验证码
       b. 校验原手机号验证码通过
       c. 发送验证码至新手机号 → 用户输入验证码
       d. 校验新手机号验证码通过
       e. 更新数据库中的手机号
     - 请求参数：`newPhone`、`oldPhoneCode`、`newPhoneCode`
  4. **场景二：原手机号已停用**
     - 用户通过前端选择"原手机号已停用"
     - 替代验证方式：
       a. 如用户绑定邮箱：发送验证码至邮箱 → 用户输入邮箱验证码
       b. 校验邮箱验证码通过
       c. 发送验证码至新手机号 → 校验通过
       d. 更新数据库中的手机号
     - 如用户未绑定邮箱，无法通过自助方式变更，提示联系管理员
     - 请求参数：`newPhone`、`newPhoneCode`、`emailCode`（可选，邮箱验证码）
     - 并可传入 `oldPhoneUnavailable: true` 标记原手机号已停用
  5. **通用校验：**
     - 新手机号在租户内唯一（不可与其他用户重复）
     - 新手机号不能与原手机号相同
     - 验证码有效期 5 分钟
     - 手机号格式校验
  6. 修改成功后，记录审计日志

---

### 3.7 数据库扩展

#### FR-011: OAuth 账号关联表

- **描述：** 新增 `t_auth_oauth_account` 表，用于存储用户与第三方 OAuth 账号的绑定关系，支持一个用户绑定多个第三方账号。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_oauth_account`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `user_id` | BIGINT(20) | 平台用户 ID，NOT NULL |
     | `oauth_provider` | VARCHAR(32) | OAuth 提供商（如 WECHAT、DINGTALK），NOT NULL |
     | `oauth_open_id` | VARCHAR(256) | 第三方平台用户唯一标识（openId），NOT NULL |
     | `oauth_union_id` | VARCHAR(256) | 第三方平台用户统一标识（unionId，可选） |
     | `oauth_nickname` | VARCHAR(128) | 第三方平台昵称 |
     | `oauth_avatar` | VARCHAR(512) | 第三方平台头像 URL |
     | `bound_time` | DATETIME | 绑定时间 |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 联合唯一索引：`uk_provider_openid`（`oauth_provider` + `oauth_open_id`）
  4. 普通索引：`idx_user_id`（`user_id`）

#### FR-012: 验证码记录表

- **描述：** 新增 `t_auth_verification_code` 表，用于记录发送的短信/邮箱验证码，支持验证码的生成、校验、过期处理。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_verification_code`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `target` | VARCHAR(128) | 发送目标（手机号或邮箱），NOT NULL |
     | `code` | VARCHAR(16) | 验证码内容，NOT NULL |
     | `send_mode` | VARCHAR(16) | 发送方式（SMS / EMAIL），NOT NULL |
     | `purpose` | VARCHAR(32) | 用途（REGISTER / LOGIN / RESET_PASSWORD / CHANGE_PHONE），NOT NULL |
     | `expire_time` | DATETIME | 过期时间，NOT NULL |
     | `used` | TINYINT(4) | 是否已使用：0-未使用，1-已使用，默认 0 |
     | `used_time` | DATETIME | 使用时间 |
     | `send_count` | INT(11) | 当日发送次数 |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 普通索引：`idx_target_purpose`（`target` + `purpose`）、`idx_expire_time`（`expire_time`）

#### FR-013: 用户表扩展

- **描述：** 对现有 `t_auth_user` 表进行扩展，增加注册模式标识、账号完善状态、OAuth 相关信息等字段，以适应多模式注册和两步注册场景。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_user`（现有表，新增字段）
  2. 新增字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `register_mode` | VARCHAR(32) | 注册模式（USERNAME / PHONE_CODE / OAUTH / PHONE_SET_USERNAME / OAUTH_SET_INFO），默认 USERNAME |
     | `account_settled` | TINYINT(4) | 账号信息是否完善：0-未完善，1-已完善，默认 1 |
     | `phone_verified` | TINYINT(4) | 手机号是否已验证：0-未验证，1-已验证，默认 0 |
     | `email_verified` | TINYINT(4) | 邮箱是否已验证：0-未验证，1-已验证，默认 0 |
     | `last_password_change_time` | DATETIME | 最后修改密码时间 |

  3. 新增索引：`idx_phone` 提升为唯一索引（租户内手机号唯一）或保持普通索引（由业务层保证租户内唯一性）
  4. Entity 类 `UserEntity` 同步新增对应字段

#### FR-014: 密码重置令牌表（可选，可被验证码记录表替代）

- **描述：** 新增 `t_auth_password_reset_token` 表，用于记录密码找回的临时令牌，支持基于邮箱和短信的密码找回流程。
- **优先级：** 中 (Should)
  （注：如果密码找回流程完全基于验证码实现，此表可被 FR-012 的验证码记录表覆盖，不新增此表）
- **验收标准：**
  1. 表名：`t_auth_password_reset_token`，位于 `cloudstroll_office_auth` 数据库（可选，按设计决策确定是否建表）
  2. 表结构：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `user_id` | BIGINT(20) | 用户 ID，NOT NULL |
     | `token` | VARCHAR(256) | 重置令牌（加密字符串），NOT NULL |
     | `reset_mode` | VARCHAR(16) | 找回方式（EMAIL / SMS），NOT NULL |
     | `target` | VARCHAR(128) | 发送目标（邮箱或手机号） |
     | `expire_time` | DATETIME | 过期时间，NOT NULL |
     | `used` | TINYINT(4) | 是否已使用：0-未使用，1-已使用，默认 0 |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 唯一索引：`uk_token`（`token`）
  4. 普通索引：`idx_user_id`（`user_id`）

---

### 3.8 认证服务 - 验证码发送服务

#### FR-015: 验证码发送服务（接口与模拟实现）

- **描述：** 在认证服务中提供验证码发送服务接口 `VerificationCodeService`，支持短信和邮件两种发送方式。本期提供模拟实现（Simulated 实现），后续对接真实短信/邮件网关。
- **优先级：** 中 (Should)
- **验收标准：**
  1. 接口 `VerificationCodeService` 位于 `org.cloudstrolling.cloudoffice.auth.service` 包下
  2. 方法定义：
     - `void sendSmsCode(String phone, String code, String purpose)` — 发送短信验证码
     - `void sendEmailCode(String email, String code, String purpose)` — 发送邮件验证码
  3. 实现类 `SimulatedVerificationCodeService`：
     - 在日志中输出验证码内容（用于开发和测试）
     - 返回发送成功
  4. 配置 `app.verification-code.mock=true` 启用模拟模式
  5. 未来对接真实网关时，替换实现类即可
  6. 验证码生成规则：6 位数字

#### FR-016: 验证码管理服务

- **描述：** 实现验证码的生成、存储、校验和过期管理，与 FR-012 的验证码记录表配合使用。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 服务类 `VerificationCodeManager` 位于 `org.cloudstrolling.cloudoffice.auth.service` 包下
  2. 核心方法：
     - `String generateCode(String target, String mode, String purpose)` — 生成验证码（6 位数字），写入数据库，返回验证码内容
     - `boolean verifyCode(String target, String code, String purpose)` — 校验验证码，校验后标记为已使用（一次性使用）
     - `boolean isSendTooFrequent(String target, String purpose)` — 检查发送频率（同一 target 同一用途 60 秒内不可重复发送）
     - `void cleanExpiredCodes()` — 清理过期验证码（可定时任务执行）
  3. 验证码有效期 5 分钟
  4. 校验规则：
     - 验证码必须存在且未过期
     - 验证码必须未被使用过
     - target 和 purpose 必须匹配
  5. 校验通过后立即标记为已使用，防止重放攻击

---

## 4. 非功能需求

### NFR-001: 安全性

- **描述：** 用户认证增强功能必须满足企业级安全要求，特别是密码管理和验证码处理的安全性。
- **指标：**
  1. 密码存储使用 BCrypt 加密算法（强度系数 ≥ 10）
  2. 新密码不能与原密码相同，修改密码后建议重新登录
  3. 验证码为 6 位数字，有效期 5 分钟，使用后立即作废（一次性）
  4. 同一手机号/邮箱发送验证码间隔不低于 60 秒
  5. 密码在日志、响应体、异常信息中不得明文输出
  6. 密码重置成功后，清除该用户的所有 Redis 登录态会话
  7. 短信验证码和密码重置凭证不在日志中明文记录（脱敏处理）

### NFR-002: 性能

- **描述：** 多模式登录和注册的性能不能比当前实现有明显下降。
- **指标：**
  1. 登录接口响应时间 ≤ 500ms（含密码/验证码校验和 Token 签发）
  2. 注册接口响应时间 ≤ 500ms
  3. 验证码生成接口响应时间 ≤ 200ms（不含实际短信/邮件发送耗时）
  4. 策略调度层零额外开销（策略实例预先初始化）

### NFR-003: 可扩展性

- **描述：** 认证方式支持灵活扩展，新增登录/注册模式不应修改现有核心逻辑。
- **指标：**
  1. 新增登录模式仅需创建新的 `LoginStrategy` 实现类并注册到工厂
  2. 新增注册模式仅需创建新的 `RegisterStrategy` 实现类并注册到工厂
  3. 新增验证码发送渠道仅需实现 `VerificationCodeService` 接口
  4. 两步注册的"补充信息"步骤不影响其他注册模式的正常流程

### NFR-004: 可维护性

- **描述：** 代码应遵循统一规范，策略模式的实现类职责单一、命名规范。
- **指标：**
  1. 策略接口定义在 `strategy` 包下，命名遵循 `XxxStrategy` 模式
  2. 工厂类命名遵循 `XxxStrategyFactory` 模式
  3. 每个策略实现类职责单一，不超过 200 行
  4. 遵循 project.md 中定义的标准包结构规范
  5. 使用构造器注入，禁止 `@Autowired` 字段注入

### NFR-005: 测试覆盖率

- **描述：** 新增的核心认证功能应具备充分的单元测试覆盖。
- **指标：**
  1. 单元测试覆盖率要求：
     - 策略层（Strategy）≥ 90%
     - 工厂类（Factory）≥ 90%
     - Service 层新增方法 ≥ 85%
     - Controller 层新增接口 ≥ 80%
  2. 关键测试场景：
     - 四种登录模式的成功/失败场景
     - 五种注册模式的成功/失败场景
     - 验证码生成、校验、过期场景
     - 修改密码成功/原密码错误/新密码与旧密码相同场景
     - 密码找回成功/验证码错误场景
     - 手机号变更两种场景
     - 两步注册信息补充场景
     - OAuth 绑定与解绑场景

---

## 5. 技术栈选型（补充）

### 5.1 新增/变更依赖

| 组件/依赖 | 版本 | 用途 | 使用模块 |
|-----------|------|------|----------|
| spring-boot-starter-mail | 3.2.5 (继承 Boot Parent) | 邮件发送支持（用于邮箱验证码） | auth-service |
| spring-boot-starter-webflux | 3.2.5 (继承 Boot Parent) | WebClient OAuth 回调请求（可选） | auth-service |

### 5.2 新增/变更配置

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `app.verification-code.mock` | 是否启用验证码模拟模式 | `true` |
| `app.verification-code.expire-seconds` | 验证码过期时间（秒） | `300` |
| `app.verification-code.send-interval-seconds` | 验证码发送间隔（秒） | `60` |
| `app.verification-code.length` | 验证码长度 | `6` |
| `app.password.min-length` | 密码最小长度 | `8` |
| `app.password.max-length` | 密码最大长度 | `64` |

### 5.3 新增表汇总

| 表名 | 所属数据库 | 说明 |
|------|-----------|------|
| `t_auth_oauth_account` | `cloudstroll_office_auth` | OAuth 第三方账号关联表（新增） |
| `t_auth_verification_code` | `cloudstroll_office_auth` | 验证码记录表（新增） |
| `t_auth_password_reset_token` | `cloudstroll_office_auth` | 密码重置令牌表（可选，按设计决策） |

### 5.4 变更表汇总

| 表名 | 变更类型 | 说明 |
|------|----------|------|
| `t_auth_user` | 新增字段 | 增加 `register_mode`、`account_settled`、`phone_verified`、`email_verified`、`last_password_change_time` |

---

## 6. 约束条件

### 6.1 技术约束

1. **JDK 版本：** 必须使用 Java 21 (OpenJDK 21 LTS)，不得使用更低版本
2. **构建工具：** 必须使用 Maven 3.9.x 进行项目构建
3. **数据库：** 使用 MariaDB 10.6 (LTS)，认证服务数据库名 `cloudstroll_office_auth`
4. **缓存：** 使用 Redis 7.2.x，验证码短期内也可选择存储于 Redis（更优方案）
5. **密码加密：** 必须使用 BCrypt，不允许使用 MD5/SHA1 等
6. **验证码：** 本期提供模拟实现（日志输出），不依赖真实短信/邮件网关

### 6.2 架构约束

1. **策略模式：** 登录和注册的多种方式必须使用策略模式实现，禁止在 Service 中使用大段 if-else 逻辑
2. **统一后处理：** 所有登录方式校验通过后，必须进入统一的 Token 签发和会话管理流程
3. **认证集中：** 修改密码、密码找回、手机号变更等敏感操作必须验证当前用户身份
4. **接口兼容：** 现有 `POST /api/v1/auth/login` 和 `POST /api/v1/auth/register` 接口的请求格式必须保持向后兼容

### 6.3 规范约束

1. **API 路径规范：** 新增 API 路径遵循 RESTful 风格：
   - 密码管理：`/api/v1/auth/password/**`
   - 手机号管理：`/api/v1/auth/phone/**`
   - 账号完善：`/api/v1/auth/account/**`
2. **错误码规范：** 新增错误码遵循现有注释格式（`AUTH-XXXX`），统一管理
3. **DTO 规范：** 请求参数使用 `@Valid` 校验注解，响应统一使用 `ApiResult<T>`
4. **策略命名规范：** 策略实现类命名格式为 `{登录/注册方式}Strategy`

### 6.4 安全约束

1. 短信验证码必须有有效期限制（5 分钟），过期后自动失效
2. 验证码使用后立即标记为已使用，防止重放攻击
3. 同一手机号同一用途的验证码发送频率限制为至少间隔 60 秒
4. 密码重置成功后必须清除该用户所有登录态（强制重新登录）
5. OAuth 绑定时需校验当前 OAuth 账号未被其他用户绑定

---

## 7. 假设与依赖

### 7.1 外部依赖

1. **Redis 服务：** 开发环境中需要部署并运行 Redis 7.2.x 服务，验证码可选存储于 Redis
2. **MariaDB 服务：** 需要部署并运行 MariaDB 10.6，执行新表的 DDL 脚本
3. **短信/邮件网关（模拟）：** 本期依赖模拟实现，验证码在日志中输出，不依赖真实短信/邮件网关
4. **cloudoffice-common 公共模块：** 依赖 common 模块提供的枚举、DTO、ApiResult 等公共组件

### 7.2 环境假设

1. 开发人员本地已安装 JDK 21（OpenJDK 21 LTS）
2. 开发人员本地已安装 Maven 3.9.x，并正确配置 `settings.xml`
3. v0.1.5 阶段的认证服务代码已完成并可直接使用

### 7.3 项目假设

1. **验证码模拟实现：** 本期验证码在日志中输出，开发调试时直接查看日志获取验证码
2. **OAuth 回调兼容：** 本期 OAuth 登录采用 code 模式（授权码模式），前端先获取授权码后传给后端
3. **租户上下文：** 注册和登录时通过 `tenantCode` 确定所属租户，系统预置默认租户
4. **验证码存储：** 验证码优先考虑存储于 Redis（利用 TTL 自动过期），Redis 不可用时回退到数据库存储
5. **邮箱配置：** 邮件发送依赖 SMTP 服务器配置，本期通过模拟实现跳过
6. **前端开发：** 如果涉及前端密码找回流程页面和两步注册引导页面，属于单独的 UI 开发任务，不在本期后端需求范围内，但需确认与前端约定的 API 交互协议

---

## 8. 优先级汇总 (MoSCoW)

### 8.1 Must（必须有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-001 | 注册登录模式枚举 | common |
| FR-002 | 认证错误码扩展 | common |
| FR-004 | 认证相关 DTO 扩展 | common / auth-service |
| FR-005 | 多模式注册 API | auth-service |
| FR-006 | 多模式登录 API | auth-service |
| FR-007 | 统一认证服务层 | auth-service |
| FR-008 | 用户修改密码 API | auth-service |
| FR-011 | OAuth 账号关联表 | auth-service (DB) |
| FR-012 | 验证码记录表 | auth-service (DB) |
| FR-013 | 用户表扩展 | auth-service (DB) |
| FR-016 | 验证码管理服务 | auth-service |

### 8.2 Should（应该有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-003 | OAuth 提供商枚举 | common |
| FR-009 | 用户密码找回 API | auth-service |
| FR-010 | 用户修改手机号 API | auth-service |
| FR-014 | 密码重置令牌表 | auth-service (DB) |
| FR-015 | 验证码发送服务 | auth-service |

### 8.3 Could（可以有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-003 | OAuth 提供商枚举（已提升至 Should） | common |
| FR-014 | 密码重置令牌表（已提升至 Should） | auth-service (DB) |

### 8.4 Won't（本期不做）

| 需求名称 | 说明 |
|----------|------|
| 真实短信网关对接 | 对接阿里云/腾讯云等短信服务商，后续版本实现 |
| 真实邮件服务对接 | 对接 SMTP 邮件服务，本期使用模拟发送 |
| 多租户注册 | 租户自主注册、租户套餐管理、租户开通流程等，不在本期范围 |
| 账号风控增强 | 异地登录检测、暴力破解防护、风控自动阻断等 |
| 前端 UI 页面 | 密码找回前端页面、两步注册引导页面等，后续版本实现 |
| OAuth 全套回调流程 | OAuth 授权码的前端重定向、回调处理等，本期仅后端 API |
| SSO 单点登录 | 跨系统单点登录，后续版本实现 |
| 图形验证码 (CAPTCHA) | 注册/登录的图形验证码防刷，建议后续版本增加 |

---

## 9. 模块间依赖关系

```
v0.1.5 认证基础（cloudoffice-common、cloudoffice-gateway、cloudoffice-auth-service）
         │
         ▼
v0.1.6 用户认证增强（变更范围）
         │
         ├── cloudoffice-common                 ← 新增枚举、DTO、ErrorCode
         │    ├── RegisterModeEnum              新增
         │    ├── LoginModeEnum                 新增
         │    ├── OAuthProviderEnum             新增（Should）
         │    └── ErrorCode                     扩展（AUTH-0020 ~ AUTH-0033）
         │
         └── cloudoffice-auth-service           ← 主要变更模块
              ├── controller/AuthController      扩展（新增 changePassword/forgotPassword/changePhone/settlement 端点）
              ├── service/
              │    ├── AuthenticationService      新增（统一认证编排）
              │    ├── strategy/                  新增（策略模式包）
              │    │    ├── LoginStrategy          新增（登录策略接口）
              │    │    ├── LoginStrategyFactory   新增
              │    │    ├── UsernamePasswordStrategy 新增
              │    │    ├── PhoneCodeLoginStrategy   新增
              │    │    ├── PhonePasswordLoginStrategy 新增
              │    │    ├── OAuthLoginStrategy       新增
              │    │    ├── RegisterStrategy         新增（注册策略接口）
              │    │    ├── RegisterStrategyFactory  新增
              │    │    └── ...多种注册策略实现
              │    ├── VerificationCodeService    新增（验证码发送接口）
              │    ├── VerificationCodeManager    新增（验证码生成/校验管理）
              │    ├── UserService                 扩展（修改密码/完善账号）
              │    └── PasswordService             新增（密码管理服务）
              ├── dto/                           扩展（新增/修改 DTO）
              ├── entity/
              │    ├── UserEntity                 扩展（新增字段）
              │    ├── OAuthAccountEntity          新增
              │    └── VerificationCodeEntity      新增
              └── mapper/
                   ├── OAuthAccountMapper          新增
                   └── VerificationCodeMapper      新增

依赖关系：
  common ← auth-service（Maven 依赖）
  auth-service → MariaDB（数据库持久化）
  auth-service → Redis（验证码临时存储，可选）
```

---

## 10. 验收总体标准

1. 所有 Must 优先级需求必须全部完成并通过验收
2. 所有 Should 优先级需求应在资源允许的情况下尽量完成
3. 项目通过 `mvn clean compile -pl cloudoffice-auth-service,cloudoffice-common -am` 编译无错误
4. 认证服务可正常启动，监听端口 9100，集成 MariaDB 和 Redis
5. **多模式注册：** 5 种注册模式均可正常完成注册流程，数据正确写入数据库
6. **多模式登录：** 4 种登录模式均可正常完成登录流程，返回正确的 TokenPairDTO
7. **统一认证服务层：** 4 种登录模式共享同一套认证后处理流程，Token 签发/Redis 会话/日志审计一致
8. **修改密码：** 已验证用户可以成功修改密码，原密码错误时明确提示
9. **密码找回：** 通过邮箱和手机验证码均能正常找回密码，验证码使用后失效
10. **手机号变更：** 原手机号可用和不可用两种场景均能正常变更手机号
11. **两步注册：** 手机注册后补充用户名、OAuth 注册后补充完整信息均可正常完成
12. 所有单元测试通过（`mvn test -pl cloudoffice-auth-service,cloudoffice-common`）
13. 与 v0.1.5 的现有 API 保持向后兼容（`POST /api/v1/auth/login` 使用 `USERNAME_PASSWORD` 模式时与原有请求格式兼容）

---

## 附录 A：API 接口总览（新增/变更）

| 方法 | API 路径 | 说明 | 优先级 |
|------|----------|------|--------|
| POST | `/api/v1/auth/register` | 多模式注册（扩展原有接口） | Must |
| PUT | `/api/v1/auth/account/settlement` | 两步注册信息完善 | Must |
| POST | `/api/v1/auth/login` | 多模式登录（扩展原有接口） | Must |
| PUT | `/api/v1/auth/password/change` | 修改密码 | Must |
| POST | `/api/v1/auth/password/forgot/send-code` | 密码找回-发送验证码 | Should |
| POST | `/api/v1/auth/password/forgot/reset` | 密码找回-重置密码 | Should |
| PUT | `/api/v1/auth/phone/change` | 修改手机号 | Should |
| POST | `/api/v1/auth/verification-code/send` | 通用发送验证码 | Must |

## 附录 B：错误码速查

| 错误码 | HTTP 状态码 | 说明 |
|--------|-------------|------|
| AUTH-0001 ~ AUTH-0019 | - | 沿用 v0.1.5 已有错误码 |
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
