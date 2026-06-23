# PRD 文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.1.6
**日期：** 2026-06-23

---

## 1. 产品概述

### 1.1 项目背景

云漫智企（CloudStrollOffice）v0.1.5 阶段已完成完整的登录认证与权限管理系统（RBAC 模型、多端混合登录、JWT+Redis 双重会话管理、双 Token 续签机制等），但现有认证体系在注册和登录方式上较为单一，仅支持用户名+密码登录和用户名+密码+手机号注册，缺少手机验证码登录、第三方 OAuth 登录、密码找回、手机号变更等现代互联网应用必备的用户体验支持，无法满足 SaaS 平台多样化的用户接入场景。v0.1.6 阶段的目标是完成用户认证能力的全面增强，实现多模式注册与登录、统一认证服务层、用户密码管理、手机号变更等核心功能，使平台的认证体系覆盖主流互联网应用的用户接入场景。

### 1.2 产品目标

- **目标 1（多模式注册）**：支持 5 种注册模式（USERNAME / PHONE_CODE / OAUTH / PHONE_SET_USERNAME / OAUTH_SET_INFO），满足不同用户场景的注册需求
- **目标 2（多模式登录）**：支持 4 种登录模式（USERNAME_PASSWORD / PHONE_CODE / PHONE_PASSWORD / OAUTH），用户可根据偏好和场景任选一种
- **目标 3（统一认证服务层）**：设计策略模式驱动的认证服务层，实现"按模式校验凭证 → 统一签发 Token → 统一处理会话"的标准化流程，新增登录/注册模式无需修改核心逻辑
- **目标 4（密码管理）**：提供用户自主修改密码（需校验原密码）和密码找回（邮箱/手机短信两种渠道）功能
- **目标 5（手机号变更）**：提供用户手机号变更功能，覆盖原手机号尚在使用和已停用两种场景，确保账号安全
- **目标 6（认证基础设施）**：扩展认证错误码体系（新增 14 个错误码）、新增 OAuth 账号关联表 / 验证码记录表 / 密码重置令牌表、用户表扩展适配多模式注册

### 1.3 核心设计理念

- **策略模式解耦**：登录和注册的多种方式通过策略模式实现，新增认证方式只需新增策略实现类并注册到工厂，不修改现有核心逻辑
- **统一后处理**：所有登录方式校验通过后，统一进入 JWT 双 Token 签发、Redis 登录态管理、多端互斥处理、登录日志审计等标准化流程
- **分步注册（两步式）**：手机注册和 OAuth 注册支持先创建基础账号，后续补充用户名/密码/手机等完整信息，降低注册门槛
- **安全优先**：密码使用 BCrypt 加密（强度系数≥10），验证码一次性使用（防重放），敏感信息脱敏记录日志，密码修改后清理登录态

### 1.4 术语表（Glossary）

| 术语 | 英文 | 定义 |
|------|------|------|
| 注册模式 | RegisterMode | 标识用户采用的注册方式，如 USERNAME、PHONE_CODE、OAUTH 等 |
| 登录模式 | LoginMode | 标识用户采用的登录方式，如 USERNAME_PASSWORD、PHONE_CODE 等 |
| 两步注册 | Two-Step Registration | 先创建基础账号，后续补充完整信息的注册流程 |
| 账号完善 | Account Settlement | 两步注册中补充用户名、密码、手机等信息的操作 |
| OAuth 提供商 | OAuth Provider | 第三方认证源，如微信、钉钉、企业微信等 |
| 验证码 | Verification Code | 发送至手机或邮箱的 6 位数字验证码，有效期 5 分钟，一次性使用 |
| 统一认证服务层 | AuthenticationService | 编排策略校验和统一后处理流程的核心服务 |

---

## 2. 目标用户

| 用户角色 | 使用场景 | 核心诉求 |
|---------|---------|---------|
| 未注册用户 | 首次使用平台，选择便捷方式创建账号 | 支持手机验证码注册、第三方 OAuth 一键注册，降低注册门槛 |
| 已注册用户 | 使用多种方式登录平台，管理密码和手机号 | 支持验证码登录/OAuth 登录等便捷方式，可自主修改密码、变更绑定手机号 |
| 忘记密码用户 | 忘记密码后通过邮箱或手机验证码自助找回 | 通过验证码验证身份后重置密码，无需联系管理员 |
| 第三方用户 | 通过微信、钉钉等第三方平台授权接入 | 使用第三方账号一键注册/登录，自动获取昵称和头像 |
| 平台开发者 | 实现多模式认证功能的开发与扩展 | 清晰的策略接口和工厂，新增认证方式无需修改核心逻辑，统一的错误码和 DTO |

---

## 3. 用户故事（User Stories）

### US-001: 注册登录模式枚举

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-001 (注册登录模式枚举)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在公共模块中新增 `RegisterModeEnum` 和 `LoginModeEnum` 枚举
- **以便** 统一标识不同的注册和登录方式，支持按 code 值匹配枚举，校验请求中的注册/登录模式合法性

#### 前置条件
- `cloudoffice-common` 模块中 `org.cloudstrolling.cloudoffice.common.enums` 包已存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 创建 `RegisterModeEnum`，When 查看枚举定义，Then 包含以下 5 个枚举值：
  - `USERNAME`(code="USERNAME", label="用户名密码手机注册", requiresPhone=true)
  - `PHONE_CODE`(code="PHONE_CODE", label="手机验证码注册", requiresPhone=true)
  - `OAUTH`(code="OAUTH", label="第三方OAuth注册", requiresPhone=false)
  - `PHONE_SET_USERNAME`(code="PHONE_SET_USERNAME", label="手机注册后设置用户名", requiresPhone=true)
  - `OAUTH_SET_INFO`(code="OAUTH_SET_INFO", label="OAuth注册后完善信息", requiresPhone=false)
- [ ] **AC2：** Given `RegisterModeEnum` 枚举值，When 调用 `fromCode(code)` 传入有效 code，Then 返回对应的枚举值
- [ ] **AC3：** Given `RegisterModeEnum`，When 调用 `fromCode("INVALID")` 或 `fromCode(null)`，Then 抛出 IllegalArgumentException 或返回 Optional.empty()
- [ ] **AC4：** Given 创建 `LoginModeEnum`，When 查看枚举定义，Then 包含以下 4 个枚举值：
  - `USERNAME_PASSWORD`(code="USERNAME_PASSWORD", label="用户名密码登录")
  - `PHONE_CODE`(code="PHONE_CODE", label="手机验证码登录")
  - `PHONE_PASSWORD`(code="PHONE_PASSWORD", label="手机密码登录")
  - `OAUTH`(code="OAUTH", label="第三方OAuth登录")
- [ ] **AC5：** Given `LoginModeEnum` 枚举值，When 调用 `fromCode(code)` 传入有效 code，Then 返回对应的枚举值
- [ ] **AC6：** Given 两个枚举类，When 编译 `cloudoffice-common` 模块，Then 编译通过，无错误警告

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `fromCode("")`（空字符串） | 抛出 IllegalArgumentException 或返回 Optional.empty() |
| `fromCode("username")`（小写） | 区分大小写，返回 Optional.empty() 或抛出异常 |
| 新增注册模式枚举值与已有常量命名冲突 | 编译失败，需调整命名 |

#### 交付物
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/enums/RegisterModeEnum.java`
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/enums/LoginModeEnum.java`

#### 备注
- 枚举位于 `org.cloudstrolling.cloudoffice.common.enums` 包下
- 每个枚举值包含 `code`（String）、`label`（String），RegisterModeEnum 额外包含 `requiresPhone`（boolean）
- 提供 `fromCode(String code)` 静态方法

---

### US-002: 认证错误码扩展

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md` | `docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-002 (认证错误码扩展)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在 `ErrorCode` 枚举中新增密码管理、短信验证码、OAuth 认证、手机号变更等相关的 14 个错误码
- **以便** 认证增强场景下的异常响应能够统一、规范地返回给客户端

#### 前置条件
- `cloudoffice-common` 模块中 `ErrorCode` 枚举已存在（位于 `org.cloudstrolling.cloudoffice.common.exception` 包）
- 枚举已实现 `org.cloudstrolling.cloudoffice.common.model.ErrorCode` 接口

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given `ErrorCode` 枚举中已有 v0.1.5 的错误码，When 新增 14 个认证增强错误码，Then 新增以下枚举常量并映射正确的 HTTP 状态码：

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

- [ ] **AC2：** Given 新增的错误码枚举，When 调用 `getCode()` 和 `getMessage()` 方法，Then 返回 Integer 类型错误码和 String 类型错误描述
- [ ] **AC3：** Given 新增的错误码，When 编译 `cloudoffice-common` 模块，Then 编译通过，无错误警告
- [ ] **AC4：** Given 新增的错误码，When 检查注解注释，Then 每个枚举常量带有 `AUTH-XXXX` 格式的注释标识模块归属

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 错误码命名与现有枚举冲突 | 编译失败，需调整命名避免冲突 |
| HTTP 状态码定义错误 | 根据实际认证场景选择正确状态码（400/401/403/404/409/429） |

#### 交付物
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java` — 新增 14 个认证增强错误码枚举常量

#### 备注
- 新增错误码遵循 `AUTH-XXXX` 注释格式，与 v0.1.5 保持一致的代码风格
- 不可删除或修改现有错误码（AUTH-0001 ~ AUTH-0019）

---

### US-003: OAuth 提供商枚举

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-003 (OAuth 提供商枚举)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在公共模块中新增第三方 OAuth 提供商枚举 `OAuthProviderEnum`
- **以便** 统一管理支持的第三方认证源（微信、钉钉、企业微信等），支持按 code 值匹配提供商

#### 前置条件
- `cloudoffice-common` 模块中 `org.cloudstrolling.cloudoffice.common.enums` 包已存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 创建 `OAuthProviderEnum`，When 查看枚举定义，Then 包含以下枚举值：
  - `WECHAT`(code="WECHAT", label="微信开放平台")
  - `DINGTALK`(code="DINGTALK", label="钉钉")
  - `WECHAT_WORK`(code="WECHAT_WORK", label="企业微信")
  - `ALIPAY`(code="ALIPAY", label="支付宝")
- [ ] **AC2：** Given `OAuthProviderEnum` 枚举值，When 调用 `fromCode(code)` 传入有效 code，Then 返回对应的枚举值
- [ ] **AC3：** Given `OAuthProviderEnum`，When 调用 `fromCode("ALIPAY")`，Then 返回支付宝枚举值（预留扩展）
- [ ] **AC4：** Given `OAuthProviderEnum`，When 编译 `cloudoffice-common` 模块，Then 编译通过，无错误警告

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `fromCode(null)` | 抛出 IllegalArgumentException 或返回 Optional.empty() |
| `fromCode("GITHUB")`（不支持的提供商） | 抛出 IllegalArgumentException 或返回 Optional.empty() |

#### 交付物
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/enums/OAuthProviderEnum.java`

#### 备注
- 每个枚举值包含 `code`（String）、`label`（String）
- 提供 `fromCode(String code)` 静态方法
- `ALIPAY` 为预留枚举，本期可能不实现完整的 OAuth 对接逻辑

---

### US-004: 认证相关 DTO 扩展

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-004 (认证相关 DTO 扩展)

#### 故事描述
- **作为** 平台开发者
- **我想要** 修改 `LoginRequest`、`RegisterRequest` 并新增 `PasswordChangeRequest`、`PasswordForgotRequest`、`SendVerificationCodeRequest`、`PhoneChangeRequest`、`AccountSettlementRequest` 等 DTO
- **以便** 多模式登录/注册、密码管理、手机号变更等功能的 API 请求和响应具有标准化的数据结构

#### 前置条件
- `cloudoffice-common` 和 `cloudoffice-auth-service` 模块中对应的 dto 包已存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 修改 `LoginRequest`（auth-service），When 查看类定义，Then 包含以下变更：
  - 新增 `loginMode` 字段（String，标识登录模式，如 `USERNAME_PASSWORD`、`PHONE_CODE` 等）
  - `loginName` 改为可选（仅 `USERNAME_PASSWORD` 模式必填）
  - `password` 改为可选（仅 `USERNAME_PASSWORD`、`PHONE_PASSWORD` 模式必填）
  - 新增 `phone` 字段（String，可选，`PHONE_CODE`、`PHONE_PASSWORD` 模式必填）
  - 新增 `smsCode` 字段（String，可选，`PHONE_CODE` 模式必填）
  - 新增 `oauthProvider` 字段（String，可选，`OAUTH` 模式必填）
  - 新增 `oauthCode` 或 `oauthToken` 字段（String，可选，`OAUTH` 模式必填）
  - 保留 `tenantCode`（所有模式必填）和 `clientType`（所有模式必填）
- [ ] **AC2：** Given 修改 `RegisterRequest`（auth-service），When 查看类定义，Then 包含以下变更：
  - 新增 `registerMode` 字段（String，标识注册模式，如 `USERNAME`、`PHONE_CODE` 等）
  - 字段按需改为可选（不同注册模式下必填字段不同）
  - 新增 `smsCode` 字段（String，可选，`PHONE_CODE` 模式必填）
  - 新增 `oauthProvider` 字段（String，可选，`OAUTH` 模式必填）
  - 新增 `oauthCode` 或 `oauthToken` 字段（String，可选，`OAUTH` 模式必填）
  - 移除 `tenantId` 字段（由注册逻辑自动关联到租户或使用默认租户）
- [ ] **AC3：** Given 新增 `PasswordChangeRequest`（auth-service），When 查看类定义，Then 包含以下字段：
  - `oldPassword`（String，原密码，@NotBlank）
  - `newPassword`（String，新密码，@Size min=8, max=64）
  - `confirmPassword`（String，确认新密码）
- [ ] **AC4：** Given 新增 `PasswordForgotRequest`（auth-service），When 查看类定义，Then 包含以下字段：
  - `mode`（String，找回方式：`EMAIL` / `SMS`）
  - `target`（String，邮箱地址或手机号）
  - `code`（String，验证码）
  - `newPassword`（String，新密码，@Size min=8, max=64）
- [ ] **AC5：** Given 新增 `SendVerificationCodeRequest`（auth-service），When 查看类定义，Then 包含以下字段：
  - `target`（String，手机号或邮箱）
  - `purpose`（String，用途：`REGISTER` / `LOGIN` / `RESET_PASSWORD` / `CHANGE_PHONE`）
  - `mode`（String，发送方式：`SMS` / `EMAIL`）
- [ ] **AC6：** Given 新增 `PhoneChangeRequest`（auth-service），When 查看类定义，Then 包含以下字段：
  - `newPhone`（String，新手机号）
  - `oldPhoneCode`（String，原手机号验证码，原手机号可用时必填）
  - `newPhoneCode`（String，新手机号验证码）
  - `emailCode`（String，邮箱验证码，原手机号不可用时选填）
- [ ] **AC7：** Given 新增 `AccountSettlementRequest`（auth-service），When 查看类定义，Then 包含以下字段：
  - `userId`（Long，用户 ID）
  - `loginName`（String，用户名，`PHONE_SET_USERNAME` 模式必填）
  - `password`（String，密码，`OAUTH_SET_INFO` 模式必填）
  - `phone`（String，手机号，`OAUTH_SET_INFO` 模式必填）
  - `smsCode`（String，手机验证码，`OAUTH_SET_INFO` 模式必填）
- [ ] **AC8：** Given 所有 DTO，When 检查实现，Then 使用 Lombok 注解（@Data、@Builder 等），使用 `@Valid` 注解进行参数校验，响应统一使用 `ApiResult<T>`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `LoginRequest` 中 `loginMode` 为 null | 参数校验失败，返回 400 参数校验错误 |
| 必填字段在不同模式下缺失 | 根据 `loginMode` / `registerMode` 动态校验，返回对应错误 |
| DTO 字段序列化/反序列化 | 所有 DTO 实现 Serializable 接口 |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/request/LoginRequest.java`（修改）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/request/RegisterRequest.java`（修改）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/request/PasswordChangeRequest.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/request/PasswordForgotRequest.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/request/SendVerificationCodeRequest.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/request/PhoneChangeRequest.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/request/AccountSettlementRequest.java`（新增）

#### 备注
- 请求参数使用 `@Valid` 注解进行参数校验，响应统一使用 `ApiResult<T>`
- DTO 使用 Lombok 注解减少样板代码
- `LoginRequest` 改造后需保持向后兼容（`loginMode` 不传时默认 `USERNAME_PASSWORD`）

---

### US-005: 多模式注册 API

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-005 (多模式注册 API)

#### 故事描述
- **作为** 未注册用户
- **我想要** 通过多种注册方式（用户名密码、手机验证码、第三方 OAuth、两步注册）在本平台创建账号
- **以便** 选择最适合自己的注册方式，降低注册门槛，快速开始使用平台服务

#### 前置条件
- `RegisterModeEnum` 枚举已定义（依赖 US-001）
- `RegisterRequest` DTO 已扩展（依赖 US-004）
- 验证码管理服务已就绪（依赖 US-011）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户名+密码+手机注册（`registerMode=USERNAME`），When 调用 `POST /api/v1/auth/register` 提交 `loginName`、`password`、`phone`（email 可选），Then 创建用户成功，返回用户基本信息（不含密码），`account_settled=true`
- [ ] **AC2：** Given 手机+短信验证码注册（`registerMode=PHONE_CODE`），When 提交 `phone` 和 `smsCode`，Then 校验验证码通过后自动创建用户，`loginName` 自动生成（如 `user_{phone_hash}`），`account_settled=false`，返回 TokenPairDTO（完成自动登录）
- [ ] **AC3：** Given 第三方 OAuth 注册（`registerMode=OAUTH`），When 提交 `oauthProvider` 和 `oauthCode`/`oauthToken`，Then 通过 OAuth 提供商获取用户信息，创建用户并绑定 OAuth 账号，`account_settled=false`，返回 TokenPairDTO（完成自动登录）
- [ ] **AC4：** Given 手机注册后设置用户名模式（`registerMode=PHONE_SET_USERNAME`），When 提交 `phone` 和 `smsCode`，Then 创建临时账号（`account_settled=false`），后续可通过 `PUT /api/v1/auth/account/settlement` 补充 `loginName`
- [ ] **AC5：** Given OAuth 注册后完善信息模式（`registerMode=OAUTH_SET_INFO`），When 提交 `oauthProvider` 和 `oauthCode`/`oauthToken`，Then 创建临时账号（`account_settled=false`），后续可通过 `PUT /api/v1/auth/account/settlement` 补充 `loginName`、`password`、`phone`、`smsCode`
- [ ] **AC6：** Given 完善账号信息（`PUT /api/v1/auth/account/settlement`），When 提交 `userId` 和对应模式的必填字段，Then 校验当前用户属于"未完善"状态，更新账号信息，设置 `account_settled=true`
- [ ] **AC7：** Given 注册请求中使用策略模式，When 检查代码实现，Then 存在 `RegisterStrategy` 接口和 `RegisterStrategyFactory`，不同注册模式由不同的策略实现类处理
- [ ] **AC8：** Given 所有注册模式，When `email` 字段已传，Then 邮箱作为可选项存储；When `phone` 已传，Then 校验手机号在租户内唯一

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 注册时 `registerMode` 无效 | 返回 HTTP 400 `REGISTER_MODE_INVALID` |
| `PHONE_CODE` 模式验证码错误/过期 | 返回 HTTP 400 `SMS_CODE_INVALID` / `SMS_CODE_EXPIRED` |
| 手机号已被其他用户绑定 | 返回 HTTP 409 `PHONE_ALREADY_BOUND` |
| OAuth 账号已被其他用户绑定 | 返回 HTTP 409 `OAUTH_ACCOUNT_ALREADY_BOUND` |
| `account/settlement` 时用户已是"已完善"状态 | 返回 HTTP 400，提示"账号信息已完善，不可重复操作" |
| OAuth openId 在平台内重复 | 返回 HTTP 409，提示"该第三方账号已被绑定" |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 扩展注册接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/RegisterStrategy.java` — 注册策略接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/RegisterStrategyFactory.java` — 注册策略工厂
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/UsernamePwdStrategy.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/PhoneCodeStrategy.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/OAuthRegisterStrategy.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/PhoneSetUsernameStrategy.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/OAuthSetInfoStrategy.java`

#### 备注
- `USERNAME` 模式与 v0.1.5 的注册逻辑向后兼容（`registerMode` 不传时默认走 `USERNAME`）
- 手机注册和 OAuth 注册成功后直接返回 TokenPairDTO（完成自动登录）
- 两步注册的"补充信息"可通过独立 API 调用，不影响其他注册模式的正常流程

---

### US-006: 多模式登录 API

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-006 (多模式登录 API)

#### 故事描述
- **作为** 已注册用户
- **我想要** 通过多种方式登录平台（用户名+密码、手机+验证码、手机+密码、第三方 OAuth）
- **以便** 根据当前场景选择最便捷的登录方式，获得灵活、安全的访问体验

#### 前置条件
- `LoginModeEnum` 枚举已定义（依赖 US-001）
- `LoginRequest` DTO 已扩展（依赖 US-004）
- 统一认证服务层已就绪（依赖 US-006）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户名+密码登录（`loginMode=USERNAME_PASSWORD`），When 提交 `loginName` + `password` + `tenantCode` + `clientType`，Then 校验通过后返回 `TokenPairDTO`（与 v0.1.5 行为一致）
- [ ] **AC2：** Given 手机+验证码登录（`loginMode=PHONE_CODE`），When 提交 `phone` + `smsCode` + `tenantCode` + `clientType`，Then 校验验证码有效性和过期时间，通过手机号查找用户，校验通过后返回 `TokenPairDTO`
- [ ] **AC3：** Given 手机+密码登录（`loginMode=PHONE_PASSWORD`），When 提交 `phone` + `password` + `tenantCode` + `clientType`，Then 使用 BCrypt 验证密码，通过手机号查找用户，校验通过后返回 `TokenPairDTO`
- [ ] **AC4：** Given 第三方 OAuth 登录（`loginMode=OAUTH`），When 提交 `oauthProvider` + `oauthCode`/`oauthToken` + `tenantCode` + `clientType`，Then 通过 OAuth 提供商获取 access_token 和用户信息，通过 openId 关联平台用户，校验通过后返回 `TokenPairDTO`
- [ ] **AC5：** Given 四种登录模式，When 校验通过后检查统一后处理流程，Then 所有模式共享同一套认证后处理：校验租户状态 → 校验用户状态 → 构建 LoginUserDTO → 签发 JWT 双 Token → 同端互斥处理 → 写入 Redis 登录态 → 缓存账号/租户状态 → 记录登录日志 → 更新最后登录时间和 IP
- [ ] **AC6：** Given 登录请求中的 `loginMode`，When 代码编译检查，Then 使用策略模式设计，`LoginStrategy` 接口定义 `authenticate(LoginRequest)` 方法，`LoginStrategyFactory` 根据 loginMode 获取对应策略实现

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `loginMode` 不传或为空 | 返回 HTTP 400 `LOGIN_MODE_INVALID` |
| `PHONE_CODE` 模式验证码错误 | 返回 HTTP 400 `SMS_CODE_INVALID` |
| `PHONE_CODE` 模式验证码已过期 | 返回 HTTP 400 `SMS_CODE_EXPIRED` |
| `OAUTH` 模式用户未绑定 | 返回 HTTP 404 `OAUTH_ACCOUNT_NOT_BOUND` |
| `OAUTH` 模式 OAuth 登录失败 | 返回 HTTP 401 `OAUTH_LOGIN_FAILED` |
| 账号状态为"未完善"(`account_settled=false`) | 返回 HTTP 403 `ACCOUNT_NOT_SETTLED` |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 扩展登录接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/LoginStrategy.java` — 登录策略接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/LoginStrategyFactory.java` — 登录策略工厂
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/UsernamePasswordStrategy.java`（基于现有逻辑重构）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/PhoneCodeLoginStrategy.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/PhonePasswordLoginStrategy.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/OAuthLoginStrategy.java`（新增）

#### 备注
- `USERNAME_PASSWORD` 模式保持与 v0.1.5 的请求格式向后兼容
- 新增策略实现类不得修改现有核心登录后处理逻辑
- 所有登录模式使用同一套后处理流程，确保 Token 签发和会话管理一致

---

### US-007: 统一认证服务层

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-007 (统一认证服务层)

#### 故事描述
- **作为** 平台开发者
- **我想要** 设计统一的认证服务层 `AuthenticationService`，将凭证校验与 Token 签发/会话管理解耦
- **以便** 新增登录/注册模式时只需要新增策略实现类并注册到工厂，无需修改核心后处理流程，实现开闭原则

#### 前置条件
- `LoginStrategy` 接口和 `RegisterStrategy` 接口已定义（依赖 US-005、US-006）
- v0.1.5 的登录后处理流程（JWT 签发、Redis 会话管理、日志审计等）已可用

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given `LoginStrategy` 接口设计，When 查看接口定义，Then 包含 `authenticate(LoginRequest)` 方法，返回 `AuthResult` 对象
- [ ] **AC2：** Given `AuthResult` 对象，When 查看类定义，Then 包含 `userId`、`tenantId`、`loginName`、`userName`、`phone`、`roles`、`permissions` 字段
- [ ] **AC3：** Given `AuthenticationService.authenticate()` 方法，When 查看编排流程，Then 完整包含以下步骤：
  1. 调用 `LoginStrategyFactory.getStrategy(loginMode).authenticate(request)` 获取 AuthResult
  2. 校验租户状态（`checkTenantStatus`）
  3. 校验用户状态（`checkUserStatus`）
  4. 构建 `LoginUserDTO`
  5. 签发 JWT 双 Token（Access Token 2h + Refresh Token 7d）
  6. 同端互斥处理
  7. 写入 Redis 登录态
  8. 缓存账号/租户状态
  9. 记录登录日志
  10. 更新最后登录时间和 IP
  11. 返回 TokenPairDTO
- [ ] **AC4：** Given `RegisterStrategy` 接口设计，When 查看接口定义，Then 包含 `register(RegisterRequest)` 方法，返回 `RegisterResult` 对象
- [ ] **AC5：** Given 策略类和工厂类，When 检查包路径，Then 位于 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下
- [ ] **AC6：** Given 需要新增登录模式，When 开发者操作，Then 仅需新增 `LoginStrategy` 实现并注册到工厂，无需修改 `AuthenticationService` 核心流程

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 策略工厂中未找到匹配的策略 | 抛出 `IllegalArgumentException` 或返回 `REGISTER_MODE_INVALID` / `LOGIN_MODE_INVALID` |
| 策略实例未正确注入 Spring 容器 | 启动时抛出 `NoSuchBeanDefinitionException` |
| 策略实例为单例，并发安全性 | 策略实现类不应包含可变状态（无状态 Bean） |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/AuthenticationService.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/LoginStrategy.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/LoginStrategyFactory.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/RegisterStrategy.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/strategy/RegisterStrategyFactory.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/result/AuthResult.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/result/RegisterResult.java`

#### 备注
- 策略实现类使用构造器注入，禁止 `@Autowired` 字段注入
- 每个策略实现类职责单一，不超过 200 行
- 策略实例预先初始化，运行时调度零额外开销

---

### US-008: 用户修改密码 API

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-008 (用户修改密码 API)

#### 故事描述
- **作为** 已登录用户
- **我想要** 通过当前密码验证后修改我的账号密码
- **以便** 定期更换密码或在新密码泄露时立即更新，保障账号安全

#### 前置条件
- 用户已登录，持有有效的 Access Token
- `PasswordChangeRequest` DTO 已定义（依赖 US-004）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户已登录，When 调用 `PUT /api/v1/auth/password/change` 提交 `oldPassword`、`newPassword`、`confirmPassword`（请求头携带 `Authorization: Bearer <accessToken>`），Then 校验通过后使用 BCrypt 加密新密码并更新数据库，返回操作成功
- [ ] **AC2：** Given `oldPassword` 与数据库中当前密码不匹配，When 提交修改，Then 返回 HTTP 400 `OLD_PASSWORD_INCORRECT`
- [ ] **AC3：** Given `newPassword` 与 `confirmPassword` 不一致，When 提交修改，Then 返回 HTTP 400 参数校验错误
- [ ] **AC4：** Given `newPassword` 与当前密码相同，When 提交修改，Then 返回 HTTP 400，提示"新密码不能与原密码相同"
- [ ] **AC5：** Given 新密码不满足长度要求（8~64 位）或不包含字母和数字，When 提交修改，Then 返回 HTTP 400 参数校验错误
- [ ] **AC6：** Given 密码修改成功，When 检查安全措施，Then 新密码使用 BCrypt 加密存储（强度系数≥10），新旧密码均不在日志中明文输出
- [ ] **AC7：** Given 密码修改成功，When 检查后处理，Then 当前用户的所有登录态会话可选择被清理（强制重新登录）或仅刷新当前 Token

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 修改密码时未登录（无 Token） | 网关拦截返回 401 |
| 新密码为空或 null | 返回 HTTP 400 参数校验错误 |
| 新密码长度 > 64 字符 | 返回 HTTP 400 参数校验错误 |
| 当前密码已用 BCrypt 加密，但原密码格式校验 | `oldPassword` 使用 BCryptPasswordEncoder.matches() 校验 |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 新增修改密码端点
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/PasswordService.java`（新增）

#### 备注
- 密码修改后建议清除该用户的 Redis 登录态会话，强制重新登录
- 使用构造器注入 `BCryptPasswordEncoder`
- 与 v0.1.5 的密码加密策略保持一致（BCrypt 强度系数≥10）

---

### US-009: 用户密码找回 API

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-009 (用户密码找回 API)

#### 故事描述
- **作为** 忘记密码的用户
- **我想要** 通过邮箱或手机短信验证码验证身份后重置密码
- **以便** 在不联系管理员的情况下自助恢复账号访问权限

#### 前置条件
- `PasswordForgotRequest` DTO 已定义（依赖 US-004）
- 验证码管理服务和验证码发送服务已就绪（依赖 US-011、US-016）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户选择邮箱找回模式，When 调用 `POST /api/v1/auth/password/forgot/send-code` 提交 `target`（邮箱地址）和 `mode=EMAIL`，Then 校验 target 对应的账号存在，生成 6 位数字验证码并发送至邮箱
- [ ] **AC2：** Given 用户选择短信找回模式，When 调用 `POST /api/v1/auth/password/forgot/send-code` 提交 `target`（手机号）和 `mode=SMS`，Then 校验 target 对应的账号存在，生成 6 位数字验证码并发送至手机
- [ ] **AC3：** Given 验证码已发送，When 调用 `POST /api/v1/auth/password/forgot/reset` 提交 `target`、`mode`、`code`（验证码）、`newPassword`、`confirmPassword`，Then 校验验证码有效性和过期时间，使用 BCrypt 加密新密码并更新数据库，返回操作成功
- [ ] **AC4：** Given 验证码错误，When 提交密码重置，Then 返回 HTTP 400 `SMS_CODE_INVALID`（短信模式）或对应错误
- [ ] **AC5：** Given 验证码已过期（超过 5 分钟），When 提交密码重置，Then 返回 HTTP 400 `SMS_CODE_EXPIRED`
- [ ] **AC6：** Given 验证码校验通过后，When 检查数据库，Then 该验证码被标记为已使用（防止重复使用）
- [ ] **AC7：** Given 密码重置成功，When 检查后处理，Then 清除该用户的所有 Redis 登录态会话（强制重新登录），敏感信息脱敏记录日志
- [ ] **AC8：** Given 同一 target 同一用途，When 60 秒内重复调用发送验证码接口，Then 返回 HTTP 429 `SMS_SEND_TOO_FREQUENT`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| target（邮箱/手机号）未绑定任何账号 | 返回 HTTP 404 "账号不存在" |
| target 绑定了多个账号（多租户场景） | 提示用户输入租户编码以确定具体账号 |
| 新密码与旧密码相同 | 返回 HTTP 400，提示"新密码不能与原密码相同" |
| 新密码不满足复杂度要求 | 返回 HTTP 400 参数校验错误 |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 新增密码找回端点
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/PasswordService.java` — 扩展密码找回逻辑

#### 备注
- 密码找回整体流程建议在前端分步完成：选择渠道 → 发送验证码 → 输入新密码 → 提交重置
- 验证码使用后立即标记为已使用，防止重放攻击
- 重置成功后清理该用户的所有 Redis 登录态会话

---

### US-010: 用户修改手机号 API

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-010 (用户修改手机号 API)

#### 故事描述
- **作为** 已登录用户
- **我想要** 在更换手机号后自助更新绑定手机号（原手机号可用或已停用两种场景均支持）
- **以便** 及时更新联系方式，确保账号安全和后续认证流程正常使用

#### 前置条件
- 用户已登录，持有有效的 Access Token
- `PhoneChangeRequest` DTO 已定义（依赖 US-004）
- 验证码管理服务已就绪（依赖 US-011）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 原手机号尚在使用，When 用户调用 `PUT /api/v1/auth/phone/change` 提交 `newPhone`、`oldPhoneCode`、`newPhoneCode`，Then 系统依次校验：原手机号验证码 → 新手机号验证码 → 校验通过后更新绑定手机号
- [ ] **AC2：** Given 原手机号已停用但用户已绑定邮箱，When 用户提交 `newPhone`、`newPhoneCode`、`emailCode`（并标记 `oldPhoneUnavailable=true`），Then 系统校验：邮箱验证码 → 新手机号验证码 → 校验通过后更新绑定手机号
- [ ] **AC3：** Given 原手机号已停用且用户未绑定邮箱，When 用户发起变更，Then 提示"请联系管理员进行身份核验"，无法通过自助方式变更
- [ ] **AC4：** Given 新手机号已在租户内被其他账号绑定，When 提交变更，Then 返回 HTTP 409 `PHONE_ALREADY_BOUND`
- [ ] **AC5：** Given 新手机号与原手机号相同，When 提交变更，Then 返回 HTTP 400，提示"新手机号不能与原手机号相同"
- [ ] **AC6：** Given 手机号变更成功，When 检查数据库，Then 绑定手机号已更新，记录审计日志

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 原手机号验证码错误 | 返回 HTTP 400 `SMS_CODE_INVALID` |
| 新手机号格式不合法 | 返回 HTTP 400 参数校验错误 |
| 邮箱验证码错误 | 返回 HTTP 400 对应错误 |
| 验证码已过期 | 返回 HTTP 400 `SMS_CODE_EXPIRED` |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 新增修改手机号端点
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/UserService.java` — 扩展手机号变更逻辑

#### 备注
- 原手机号可用/不可用两种场景的验证流程不同，需在前端区分展示
- 修改成功后记录审计日志（原手机号、新手机号、变更时间、变更方式）
- 新手机号需校验租户内唯一性

---

### US-011: OAuth 账号关联表

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-011 (OAuth 账号关联表)

#### 故事描述
- **作为** 平台开发者
- **我想要** 新增 `t_auth_oauth_account` 表存储用户与第三方 OAuth 账号的绑定关系
- **以便** 支持一个用户绑定多个第三方账号，通过 openId 关联平台用户，实现 OAuth 登录/注册

#### 前置条件
- `cloudstroll_office_auth` 数据库已创建
- MyBatis-Plus 自动填充配置已就绪

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_oauth_account` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `user_id` BIGINT(20) NOT NULL — 平台用户 ID
  - `oauth_provider` VARCHAR(32) NOT NULL — OAuth 提供商（如 WECHAT、DINGTALK）
  - `oauth_open_id` VARCHAR(256) NOT NULL — 第三方平台用户唯一标识（openId）
  - `oauth_union_id` VARCHAR(256) — 第三方平台用户统一标识（unionId，可选）
  - `oauth_nickname` VARCHAR(128) — 第三方平台昵称
  - `oauth_avatar` VARCHAR(512) — 第三方平台头像 URL
  - `bound_time` DATETIME — 绑定时间
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含：
  - 联合唯一索引 `uk_provider_openid`（`oauth_provider` + `oauth_open_id`）
  - 普通索引 `idx_user_id`（`user_id`）
- [ ] **AC3：** Given `OAuthAccountEntity` 实体类，When 查看类定义，Then 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，使用 `@TableName("t_auth_oauth_account")` 注解
- [ ] **AC4：** Given `OAuthAccountMapper` 接口，When 查看，Then 提供按 `userId` 查询、按 `oauthProvider` + `openId` 查询、新增绑定等方法

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 同一提供商插入重复 openId | 唯一索引 `uk_provider_openid` 阻止，抛出数据库异常 |
| 同一用户绑定多个提供商 | 允许（一个用户可绑定微信和钉钉等多个第三方账号） |
| 同一提供商同一用户绑定多个 openId | 根据业务需求决定是否允许（一般不允许） |

#### 交付物
- `scripts/sql/auth-init-v0.1.6.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/OAuthAccountEntity.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/mapper/OAuthAccountMapper.java`（新增）

#### 备注
- `oauth_open_id` 字段长度 256 以容纳不同平台的 openId 长度差异
- OAuth 的 openId 在平台内全局唯一（不按租户隔离）
- Entity 继承 `BaseEntity` 自动获取 `create_time`、`update_time`、`deleted` 字段

---

### US-012: 验证码记录表

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-012 (验证码记录表)

#### 故事描述
- **作为** 平台开发者
- **我想要** 新增 `t_auth_verification_code` 表记录生成的验证码及其状态
- **以便** 支持验证码的生成、校验（一次性使用）、过期处理，防止验证码重放攻击

#### 前置条件
- `cloudstroll_office_auth` 数据库已创建

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_verification_code` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `target` VARCHAR(128) NOT NULL — 发送目标（手机号或邮箱）
  - `code` VARCHAR(16) NOT NULL — 验证码内容
  - `send_mode` VARCHAR(16) NOT NULL — 发送方式（SMS / EMAIL）
  - `purpose` VARCHAR(32) NOT NULL — 用途（REGISTER / LOGIN / RESET_PASSWORD / CHANGE_PHONE）
  - `expire_time` DATETIME NOT NULL — 过期时间
  - `used` TINYINT(4) DEFAULT 0 — 是否已使用：0-未使用，1-已使用
  - `used_time` DATETIME — 使用时间
  - `send_count` INT(11) — 当日发送次数
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含：
  - 普通索引 `idx_target_purpose`（`target` + `purpose`）
  - 普通索引 `idx_expire_time`（`expire_time`）
- [ ] **AC3：** Given `VerificationCodeEntity` 实体类，When 查看类定义，Then 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，使用 `@TableName("t_auth_verification_code")` 注解
- [ ] **AC4：** Given `VerificationCodeMapper` 接口，When 查看，Then 提供按 target 和 purpose 查询、新增记录、标记已使用等方法

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 同一 target 同一用途 60 秒内重复发送 | 业务层拦截，不插入重复记录（返回 `SMS_SEND_TOO_FREQUENT`） |
| 验证码已过期（expire_time < now） | 校验时返回过期错误 |
| 验证码已被使用（used=1） | 校验时返回无效错误 |

#### 交付物
- `scripts/sql/auth-init-v0.1.6.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/VerificationCodeEntity.java`（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/mapper/VerificationCodeMapper.java`（新增）

#### 备注
- 验证码优先考虑存储于 Redis（利用 TTL 自动过期），Redis 不可用时回退到数据库存储
- `purpose` 字段明确标识验证码用途，防止验证码被跨用途滥用
- `send_count` 用于统计每日发送次数，可扩展为每日上限控制

---

### US-013: 用户表扩展

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-013 (用户表扩展)

#### 故事描述
- **作为** 平台开发者
- **我想要** 对现有 `t_auth_user` 表扩展注册模式、账号完善状态、验证状态等字段
- **以便** 适配多模式注册和两步注册场景，标识用户是通过哪种方式注册的、账号信息是否已完善

#### 前置条件
- `t_auth_user` 表已存在（v0.1.5 已创建）
- `UserEntity` 实体类已存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 扩展 `t_auth_user` 表，When 执行 DDL 变更，Then 增加以下字段：
  - `register_mode` VARCHAR(32) DEFAULT 'USERNAME' — 注册模式
  - `account_settled` TINYINT(4) DEFAULT 1 — 账号信息是否完善：0-未完善，1-已完善
  - `phone_verified` TINYINT(4) DEFAULT 0 — 手机号是否已验证：0-未验证，1-已验证
  - `email_verified` TINYINT(4) DEFAULT 0 — 邮箱是否已验证：0-未验证，1-已验证
  - `last_password_change_time` DATETIME — 最后修改密码时间
- [ ] **AC2：** Given 新增字段，When 检查索引优化，Then `idx_phone` 索引保持原样或考虑提升为唯一索引（由业务层决定租户内手机号唯一性保障方式）
- [ ] **AC3：** Given `UserEntity` 实体类，When 查看类定义，Then 新增字段已同步添加，使用正确的 MyBatis-Plus 注解映射

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 已有用户记录的 `register_mode` | 默认填充为 `USERNAME`（向后兼容） |
| 已有用户记录的 `account_settled` | 默认填充为 `1`（已完善） |
| `register_mode` 设为 NULL | 默认值 `USERNAME` 兜底 |

#### 交付物
- `scripts/sql/auth-init-v0.1.6.sql` — DDL 变更脚本（ALTER TABLE）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/UserEntity.java` — 新增字段

#### 备注
- 新增字段需设置合理的默认值，保证与 v0.1.5 的现有用户数据兼容
- 后端逻辑中 `account_settled=0` 的用户在登录时应返回 `ACCOUNT_NOT_SETTLED` 错误
- Entity 使用 `@TableField` 注解映射新增列

---

### US-014: 密码重置令牌表

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-014 (密码重置令牌表)

#### 故事描述
- **作为** 平台开发者
- **我想要** 新增 `t_auth_password_reset_token` 表记录密码找回的临时令牌
- **以便** 支持基于邮箱和短信的密码找回流程，记录令牌的生成、使用和过期状态

#### 前置条件
- `cloudstroll_office_auth` 数据库已创建
- 如果密码找回流程完全基于验证码实现，此表可由 FR-012 的验证码记录表覆盖，可不新增

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 设计决策确定新增此表，When 执行建表，Then 成功创建 `t_auth_password_reset_token` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `user_id` BIGINT(20) NOT NULL — 用户 ID
  - `token` VARCHAR(256) NOT NULL — 重置令牌（加密字符串）
  - `reset_mode` VARCHAR(16) NOT NULL — 找回方式（EMAIL / SMS）
  - `target` VARCHAR(128) — 发送目标（邮箱或手机号）
  - `expire_time` DATETIME NOT NULL — 过期时间
  - `used` TINYINT(4) DEFAULT 0 — 是否已使用：0-未使用，1-已使用
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含：
  - 唯一索引 `uk_token`（`token`）
  - 普通索引 `idx_user_id`（`user_id`）

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 设计决策不新增此表 | 密码找回流程完全基于 FR-012 验证码记录表实现 |
| 令牌已使用（used=1） | 校验时返回 `PASSWORD_RESET_TOKEN_INVALID` |
| 令牌已过期 | 校验时返回 `PASSWORD_RESET_TOKEN_EXPIRED` |

#### 交付物
- `scripts/sql/auth-init-v0.1.6.sql` — 建表 DDL 脚本（可选）
- 或依赖 US-012 验证码记录表实现密码找回

#### 备注
- 此表的决策取决于：密码找回是否额外需要一个独立的安全令牌（Reset Token）还是完全通过验证码校验完成
- 如果验证码本身已满足安全需求（一次性、5 分钟过期、目标匹配），可不额外新增此表
- 最终由架构评审确定是否建表

---

### US-015: 验证码发送服务

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-015 (验证码发送服务 - 接口与模拟实现)

#### 故事描述
- **作为** 平台开发者
- **我想要** 定义验证码发送服务接口并提供模拟实现
- **以便** 在开发阶段不依赖真实短信/邮件网关即可完成功能验证，后续接入真实网关时仅需替换实现类

#### 前置条件
- `VerificationCodeManager` 已就绪（依赖 US-011）
- `spring-boot-starter-mail` 依赖已声明（正式对接时使用）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 接口 `VerificationCodeService`，When 查看接口定义，Then 包含以下方法：
  - `void sendSmsCode(String phone, String code, String purpose)` — 发送短信验证码
  - `void sendEmailCode(String email, String code, String purpose)` — 发送邮件验证码
- [ ] **AC2：** Given `SimulatedVerificationCodeService` 实现类，When 调用发送方法，Then 在日志中输出验证码内容（用于开发和测试），返回发送成功
- [ ] **AC3：** Given 配置项 `app.verification-code.mock=true`，When 系统启动，Then 自动装配模拟实现；When 设为 `false`，Then 加载真实网关实现（后续版本）
- [ ] **AC4：** Given 验证码生成，When 检查生成逻辑，Then 验证码为 6 位数字

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 模拟模式下手机号或邮箱为空 | 记录警告日志，不发送，返回成功（便于测试） |
| 模拟模式下日志输出验证码 | 日志级别为 INFO，生产环境可通过日志配置关闭 |
| 接口尚未对接真实网关 | 调用模拟方法时日志输出格式清晰，便于开发调试 |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/VerificationCodeService.java`（新增接口）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/impl/SimulatedVerificationCodeService.java`（新增模拟实现）

#### 备注
- 接口定义在 `org.cloudstrolling.cloudoffice.auth.service` 包下
- 验证码为 6 位数字，生成逻辑由 `VerificationCodeManager` 负责
- 未来对接真实网关时，新增实现类并替换注入即可

---

### US-016: 验证码管理服务

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.6.md`
需求编号：FR-016 (验证码管理服务)

#### 故事描述
- **作为** 平台开发者
- **我想要** 实现验证码的生成、存储、校验和过期管理服务
- **以便** 在多种认证场景（注册、登录、密码找回、手机号变更）中统一管理验证码的生命周期，确保验证码安全可用

#### 前置条件
- `t_auth_verification_code` 表已创建（依赖 US-012）
- `VerificationCodeMapper` 已就绪

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given `VerificationCodeManager` 服务类，When 调用 `generateCode(target, mode, purpose)`，Then 生成 6 位数字验证码，写入数据库（或 Redis），返回验证码内容
- [ ] **AC2：** Given 调用 `verifyCode(target, code, purpose)`，When 验证码有效且未过期、未被使用、target 和 purpose 匹配，Then 校验通过，标记验证码为已使用（used=1），返回 true
- [ ] **AC3：** Given 调用 `verifyCode(target, code, purpose)`，When 验证码已过期（expire_time < now），Then 返回 false，抛出 `SMS_CODE_EXPIRED`
- [ ] **AC4：** Given 调用 `verifyCode(target, code, purpose)`，When 验证码已被使用（used=1），Then 返回 false，抛出 `SMS_CODE_INVALID`
- [ ] **AC5：** Given 调用 `isSendTooFrequent(target, purpose)`，When 同一 target 同一用途在 60 秒内已发送过验证码，Then 返回 true，抛出 `SMS_SEND_TOO_FREQUENT`
- [ ] **AC6：** Given 调用 `cleanExpiredCodes()`，When 执行清理，Then 删除（或逻辑标记）所有已过期的验证码记录
- [ ] **AC7：** Given 验证码校验通过后，When 检查数据库，Then 对应记录 `used` 字段已更新为 1，`used_time` 已记录当前时间（防止重放攻击）

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| target 为 null 或空字符串 | 抛出 IllegalArgumentException |
| 验证码为 null 或空字符串 | 校验不通过，返回 false |
| purpose 不匹配（如注册验证码用于登录） | 校验不通过，返回 `SMS_CODE_INVALID` |
| Redis 用于验证码存储时 Key 设计 | 建议格式：`auth:verification:{purpose}:{target}` |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/VerificationCodeManager.java`（新增）

#### 备注
- 验证码有效期 5 分钟（可通过配置 `app.verification-code.expire-seconds` 调整）
- 同一 target 同一用途发送间隔不低于 60 秒（可通过配置 `app.verification-code.send-interval-seconds` 调整）
- 验证码优先考虑存储于 Redis（利用 TTL 自动过期），Redis 不可用时回退到数据库存储
- 校验后立即标记为已使用，防止重放攻击

---

## 4. 非功能性需求（Non-Functional Requirements）

### 4.1 性能

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 登录接口响应时间 | ≤ 500ms | 含密码/验证码校验和 Token 签发，四种模式统一标准 |
| 注册接口响应时间 | ≤ 500ms | 五种注册模式统一标准 |
| 验证码生成接口响应时间 | ≤ 200ms | 不含实际短信/邮件发送耗时（模拟发送） |
| 策略调度层开销 | 零额外开销 | 策略实例预先初始化，运行时无反射/动态加载开销 |

### 4.2 可用性

- 认证服务支持健康检查端点（`GET /api/v1/auth/health`），用于服务发现和负载均衡
- 验证码存储优先使用 Redis（自动过期），Redis 不可用时回退到数据库存储
- 验证码模拟模式支持通过配置开关启用/禁用，不影响服务正常运行

### 4.3 可靠性

- 密码修改/重置成功后必须清理登录态，防止旧密码继续使用
- 验证码使用后立即标记为已使用，防止重放攻击
- 验证码生成频率控制（同一目标同一用途 60 秒间隔），防止恶意刷验证码
- 密码找回流程的验证码校验和新密码更新在同一个事务中执行

### 4.4 安全性

- 密码存储使用 BCrypt 加密算法（强度系数 ≥ 10）
- 新密码不能与原密码相同，修改密码后建议重新登录
- 验证码为 6 位数字，有效期 5 分钟，使用后立即作废（一次性）
- 同一手机号/邮箱发送验证码间隔不低于 60 秒
- 密码在日志、响应体、异常信息中不得明文输出
- 密码重置成功后，清除该用户的所有 Redis 登录态会话
- 验证码不在日志中明文记录（模拟模式下除外，需脱敏处理）
- OAuth 绑定时需校验当前 OAuth 账号未被其他用户绑定

### 4.5 可维护性

- 策略接口定义在 `strategy` 包下，命名遵循 `XxxStrategy` 模式
- 工厂类命名遵循 `XxxStrategyFactory` 模式
- 每个策略实现类职责单一，不超过 200 行
- 遵循 project.md 中定义的标准包结构规范
- 使用构造器注入，禁止 `@Autowired` 字段注入
- 新增登录/注册模式仅需创建策略实现类并注册到工厂，无需修改核心流程

### 4.6 测试覆盖率

- 策略层（Strategy）单元测试覆盖率 ≥ 90%
- 工厂类（Factory）单元测试覆盖率 ≥ 90%
- Service 层新增方法单元测试覆盖率 ≥ 85%
- Controller 层新增接口单元测试覆盖率 ≥ 80%

**关键测试场景：**
| 测试场景 | 说明 |
|----------|------|
| 四种登录模式的成功/失败场景 | 每种模式至少一个成功用例和一个失败用例 |
| 五种注册模式的成功/失败场景 | 每种模式至少一个成功用例和一个失败用例 |
| 验证码生成、校验、过期场景 | 验证码正确/错误/过期/已使用/频率限制 |
| 修改密码成功/原密码错误/新密码与旧密码相同 | 三种场景全覆盖 |
| 密码找回成功/验证码错误场景 | 邮箱找回和短信找回两种渠道 |
| 手机号变更两种场景 | 原手机号可用和已停用两种验证流程 |
| 两步注册信息补充场景 | `PHONE_SET_USERNAME` 和 `OAUTH_SET_INFO` 模式 |
| OAuth 绑定与解绑场景 | 绑定成功/重复绑定/未绑定登录 |

---

## 5. 附录

### 5.1 API 接口总览（新增/变更）

| 方法 | API 路径 | 说明 | 优先级 |
|------|----------|------|--------|
| POST | `/api/v1/auth/register` | 多模式注册（扩展原有接口） | Must |
| PUT | `/api/v1/auth/account/settlement` | 两步注册信息完善 | Must |
| POST | `/api/v1/auth/login` | 多模式登录（扩展原有接口） | Must |
| PUT | `/api/v1/auth/password/change` | 修改密码 | Must |
| POST | `/api/v1/auth/password/forgot/send-code` | 密码找回 - 发送验证码 | Should |
| POST | `/api/v1/auth/password/forgot/reset` | 密码找回 - 重置密码 | Should |
| PUT | `/api/v1/auth/phone/change` | 修改手机号 | Should |
| POST | `/api/v1/auth/verification-code/send` | 通用发送验证码 | Must |

### 5.2 新增数据库表/变更汇总

| 表名 | 所属数据库 | 变更类型 | 说明 |
|------|-----------|----------|------|
| `t_auth_oauth_account` | `cloudstroll_office_auth` | 新增 | OAuth 第三方账号关联表 |
| `t_auth_verification_code` | `cloudstroll_office_auth` | 新增 | 验证码记录表 |
| `t_auth_password_reset_token` | `cloudstroll_office_auth` | 新增（可选） | 密码重置令牌表 |
| `t_auth_user` | `cloudstroll_office_auth` | 变更 | 新增 register_mode / account_settled / phone_verified / email_verified / last_password_change_time 字段 |

### 5.3 错误码速查（新增）

| 错误码 | HTTP 状态码 | 说明 |
|--------|-------------|------|
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

### 5.4 配置项

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `app.verification-code.mock` | 是否启用验证码模拟模式 | `true` |
| `app.verification-code.expire-seconds` | 验证码过期时间（秒） | `300`（5 分钟） |
| `app.verification-code.send-interval-seconds` | 验证码发送间隔（秒） | `60` |
| `app.verification-code.length` | 验证码长度 | `6` |
| `app.password.min-length` | 密码最小长度 | `8` |
| `app.password.max-length` | 密码最大长度 | `64` |

### 5.5 模块依赖关系

```
v0.1.5 认证基础（cloudoffice-common、cloudoffice-auth-service）
         │
         ▼
v0.1.6 用户认证增强（变更范围）
         │
         ├── cloudoffice-common
         │    ├── RegisterModeEnum              新增
         │    ├── LoginModeEnum                 新增
         │    ├── OAuthProviderEnum             新增（Should）
         │    └── ErrorCode                     扩展（AUTH-0020 ~ AUTH-0033）
         │
         └── cloudoffice-auth-service
              ├── controller/AuthController      扩展（新增 changePassword/forgotPassword/changePhone/settlement 端点）
              ├── service/
              │    ├── AuthenticationService      新增（统一认证编排）
              │    ├── PasswordService            新增（密码管理服务）
              │    ├── VerificationCodeService    新增（验证码发送接口）
              │    ├── VerificationCodeManager    新增（验证码生成/校验管理）
              │    ├── UserService                 扩展（修改密码/完善账号）
              │    └── strategy/                  新增（策略模式包）
              │         ├── LoginStrategy          新增（登录策略接口）
              │         ├── LoginStrategyFactory   新增
              │         ├── UsernamePasswordStrategy 新增
              │         ├── PhoneCodeLoginStrategy   新增
              │         ├── PhonePasswordLoginStrategy 新增
              │         ├── OAuthLoginStrategy       新增
              │         ├── RegisterStrategy         新增（注册策略接口）
              │         ├── RegisterStrategyFactory  新增
              │         └── ...多种注册策略实现
              ├── dto/                           扩展（新增/修改 DTO）
              ├── entity/
              │    ├── UserEntity                 扩展（新增字段）
              │    ├── OAuthAccountEntity          新增
              │    └── VerificationCodeEntity      新增
              └── mapper/
                   ├── OAuthAccountMapper          新增
                   └── VerificationCodeMapper      新增
```
