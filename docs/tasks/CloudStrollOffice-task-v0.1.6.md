# 任务清单

**项目：** CloudStrollOffice
**版本：** v0.1.6
**对应PRD：** `docs/prds/CloudStrollOffice-prd-v0.1.6.md`
**对应架构：** `docs/architecture.md`
**对应SDS：** `docs/sds/CloudStrollOffice-sds-v0.1.6.md`
**对应项目文件：** `docs/project.md`
**生成日期：** 2026-06-23

# 1. 模块任务清单

| 模块 | 功能 | 任务编码 | 任务名称 |
|------|------|----------|----------|
| **cloudoffice-common** | 枚举 | TASK-001 | 新增 RegisterModeEnum 注册模式枚举 |
| **cloudoffice-common** | 枚举 | TASK-002 | 新增 LoginModeEnum 登录模式枚举 |
| **cloudoffice-common** | 枚举 | TASK-003 | 新增 OAuthProviderEnum OAuth提供商枚举 |
| **cloudoffice-common** | ErrorCode | TASK-004 | ErrorCode枚举扩展（AUTH-0020~AUTH-0033） |
| **cloudoffice-common** | RedisKey | TASK-005 | RedisKeyConstants 验证码相关Key扩展 |
| **cloudoffice-auth-service** | DTO | TASK-006 | LoginRequest DTO修改（增加loginMode等字段） |
| **cloudoffice-auth-service** | DTO | TASK-007 | RegisterRequest DTO修改（增加registerMode等字段） |
| **cloudoffice-auth-service** | DTO | TASK-008 | 新增 PasswordChangeRequest DTO |
| **cloudoffice-auth-service** | DTO | TASK-009 | 新增 PasswordForgotRequest DTO |
| **cloudoffice-auth-service** | DTO | TASK-010 | 新增 SendVerificationCodeRequest DTO |
| **cloudoffice-auth-service** | DTO | TASK-011 | 新增 PhoneChangeRequest DTO |
| **cloudoffice-auth-service** | DTO | TASK-012 | 新增 AccountSettlementRequest DTO |
| **cloudoffice-auth-service** | DTO | TASK-013 | 新增 AuthResult + RegisterResult 策略结果DTO |
| **cloudoffice-auth-service** | 实体/Mapper | TASK-014 | 新增 OAuthAccountEntity + OAuthAccountMapper |
| **cloudoffice-auth-service** | 实体/Mapper | TASK-015 | 新增 VerificationCodeEntity + VerificationCodeMapper |
| **cloudoffice-auth-service** | 实体/Mapper | TASK-016 | UserEntity扩展（新增字段） |
| **cloudoffice-auth-service** | 策略模式 | TASK-017 | LoginStrategy接口 + LoginStrategyFactory |
| **cloudoffice-auth-service** | 策略模式 | TASK-018 | UsernamePasswordStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-019 | PhoneCodeLoginStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-020 | PhonePasswordLoginStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-021 | OAuthLoginStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-022 | RegisterStrategy接口 + RegisterStrategyFactory |
| **cloudoffice-auth-service** | 策略模式 | TASK-023 | UsernamePwdRegisterStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-024 | PhoneCodeRegisterStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-025 | OAuthRegisterStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-026 | PhoneSetUsernameStrategy实现 |
| **cloudoffice-auth-service** | 策略模式 | TASK-027 | OAuthSetInfoStrategy实现 |
| **cloudoffice-auth-service** | 服务 | TASK-028 | AuthenticationService 统一认证编排服务 |
| **cloudoffice-auth-service** | 服务 | TASK-029 | VerificationCodeManager 验证码管理服务 |
| **cloudoffice-auth-service** | 服务 | TASK-030 | VerificationCodeService 验证码发送服务（接口+模拟实现） |
| **cloudoffice-auth-service** | 服务 | TASK-031 | PasswordService 密码管理服务 |
| **cloudoffice-auth-service** | Controller | TASK-032 | AuthController扩展（新增密码管理/手机号变更/账号完善等端点） |
| **cloudoffice-auth-service** | Controller | TASK-033 | 验证码发送Controller端点 |
| **cloudoffice-auth-service** | 配置 | TASK-034 | SecurityConfig白名单扩展 |
| **cloudoffice-auth-service** | 配置 | TASK-035 | 验证码相关配置项（application.yml扩展） |
| **scripts/sql** | DDL | TASK-036 | 数据库DDL脚本（新表创建 + 表扩展ALTER） |

# 2. 详细任务定义

---

## 2.1 cloudoffice-common 公共模块

### 2.1.1 TASK-001：新增 RegisterModeEnum 注册模式枚举

**任务ID：** `TASK-001`
**任务名称：** 新增 RegisterModeEnum 注册模式枚举
**任务类型：** `common`
**关联UserStory：** `US-001`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-007`, `TASK-022`

#### 上下文读取
- PRD v0.1.6：US-001「注册登录模式枚举」章节
- SDS v0.1.6：2.2.1 节 cloudoffice-common 公共模块新增内容，4.2 节接口规范
- 需求文档 FR-001：注册登录模式枚举
- 现有代码：`cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/enums/ClientTypeEnum.java`

#### 详细业务描述
在 `cloudoffice-common` 模块的 `org.cloudstrolling.cloudoffice.common.enums` 包下新增 `RegisterModeEnum` 枚举，包含 5 个枚举值：
- `USERNAME(code="USERNAME", label="用户名密码手机注册", requiresPhone=true)`
- `PHONE_CODE(code="PHONE_CODE", label="手机验证码注册", requiresPhone=true)`
- `OAUTH(code="OAUTH", label="第三方OAuth注册", requiresPhone=false)`
- `PHONE_SET_USERNAME(code="PHONE_SET_USERNAME", label="手机注册后设置用户名", requiresPhone=true)`
- `OAUTH_SET_INFO(code="OAUTH_SET_INFO", label="OAuth注册后完善信息", requiresPhone=false)`

每个枚举值包含 `code`（String）、`label`（String）、`requiresPhone`（boolean）属性。提供 `fromCode(String code)` 静态方法，支持根据 code 获取枚举值。`fromCode` 传入无效 code 或 null 时抛出 `IllegalArgumentException`。

#### 测试验收方法
1. 编写单元测试覆盖 5 个枚举值的定义和属性正确性
2. 编写 `fromCode` 方法测试：有效 code 返回对应枚举、无效 code 抛出异常、null 抛出异常
3. 验证 `mvn clean compile -pl cloudoffice-common` 编译通过

---

### 2.1.2 TASK-002：新增 LoginModeEnum 登录模式枚举

**任务ID：** `TASK-002`
**任务名称：** 新增 LoginModeEnum 登录模式枚举
**任务类型：** `common`
**关联UserStory：** `US-001`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-006`, `TASK-017`

#### 上下文读取
- PRD v0.1.6：US-001「注册登录模式枚举」章节
- SDS v0.1.6：2.2.1 节 cloudoffice-common 公共模块新增内容
- 需求文档 FR-001：注册登录模式枚举

#### 详细业务描述
在 `cloudoffice-common` 模块的 `org.cloudstrolling.cloudoffice.common.enums` 包下新增 `LoginModeEnum` 枚举，包含 4 个枚举值：
- `USERNAME_PASSWORD(code="USERNAME_PASSWORD", label="用户名密码登录")`
- `PHONE_CODE(code="PHONE_CODE", label="手机验证码登录")`
- `PHONE_PASSWORD(code="PHONE_PASSWORD", label="手机密码登录")`
- `OAUTH(code="OAUTH", label="第三方OAuth登录")`

每个枚举值包含 `code`（String）、`label`（String）属性。提供 `fromCode(String code)` 静态方法，支持根据 code 获取枚举值。`fromCode` 传入无效 code 或 null 时抛出 `IllegalArgumentException`。

#### 测试验收方法
1. 编写单元测试覆盖 4 个枚举值的定义和属性正确性
2. 编写 `fromCode` 方法测试：有效 code 返回对应枚举、无效 code 抛出异常、null 抛出异常
3. 验证 `mvn clean compile -pl cloudoffice-common` 编译通过

---

### 2.1.3 TASK-003：新增 OAuthProviderEnum OAuth提供商枚举

**任务ID：** `TASK-003`
**任务名称：** 新增 OAuthProviderEnum OAuth提供商枚举
**任务类型：** `common`
**关联UserStory：** `US-003`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-006`, `TASK-007`, `TASK-021`, `TASK-025`, `TASK-027`

#### 上下文读取
- PRD v0.1.6：US-003「OAuth 提供商枚举」章节
- SDS v0.1.6：2.2.1 节 cloudoffice-common 公共模块新增内容
- 需求文档 FR-003：OAuth 提供商枚举

#### 详细业务描述
在 `cloudoffice-common` 模块的 `org.cloudstrolling.cloudoffice.common.enums` 包下新增 `OAuthProviderEnum` 枚举，包含以下枚举值：
- `WECHAT(code="WECHAT", label="微信开放平台")`
- `DINGTALK(code="DINGTALK", label="钉钉")`
- `WECHAT_WORK(code="WECHAT_WORK", label="企业微信")`
- `ALIPAY(code="ALIPAY", label="支付宝")`（预留）

每个枚举值包含 `code`（String）、`label`（String）属性。提供 `fromCode(String code)` 静态方法。

#### 测试验收方法
1. 编写单元测试覆盖 4 个枚举值的定义和属性正确性
2. 编写 `fromCode` 方法测试：有效 code 返回对应枚举、无效 code 抛出异常、null 抛出异常
3. 验证 `mvn clean compile -pl cloudoffice-common` 编译通过

---

### 2.1.4 TASK-004：ErrorCode枚举扩展（AUTH-0020~AUTH-0033）

**任务ID：** `TASK-004`
**任务名称：** ErrorCode枚举扩展（AUTH-0020~AUTH-0033）
**任务类型：** `common`
**关联UserStory：** `US-002`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-018`~`TASK-027`, `TASK-028`~`TASK-033`

#### 上下文读取
- PRD v0.1.6：US-002「认证错误码扩展」章节，附录 5.3 错误码速查表
- SDS v0.1.6：4.3 节错误码定义表格
- 需求文档 FR-002：认证错误码扩展
- 现有代码：`cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java`

#### 详细业务描述
在现有的 `ErrorCode` 枚举中新增 14 个认证增强错误码（AUTH-0020 ~ AUTH-0033）：
- AUTH-0020 `PASSWORD_RESET_TOKEN_INVALID`(400, "密码重置令牌无效")
- AUTH-0021 `PASSWORD_RESET_TOKEN_EXPIRED`(400, "密码重置令牌已过期")
- AUTH-0022 `OLD_PASSWORD_INCORRECT`(400, "原密码错误")
- AUTH-0023 `SMS_CODE_INVALID`(400, "短信验证码无效")
- AUTH-0024 `SMS_CODE_EXPIRED`(400, "短信验证码已过期")
- AUTH-0025 `SMS_SEND_TOO_FREQUENT`(429, "验证码发送过于频繁")
- AUTH-0026 `OAUTH_LOGIN_FAILED`(401, "第三方登录失败")
- AUTH-0027 `OAUTH_ACCOUNT_NOT_BOUND`(404, "第三方账号未绑定")
- AUTH-0028 `PHONE_ALREADY_BOUND`(409, "手机号已被其他账号绑定")
- AUTH-0029 `OAUTH_ACCOUNT_ALREADY_BOUND`(409, "第三方账号已被其他用户绑定")
- AUTH-0030 `EMAIL_VERIFICATION_REQUIRED`(403, "需要邮箱验证")
- AUTH-0031 `ACCOUNT_NOT_SETTLED`(403, "账号信息未完善，请先补充资料")
- AUTH-0032 `REGISTER_MODE_INVALID`(400, "无效的注册模式")
- AUTH-0033 `LOGIN_MODE_INVALID`(400, "无效的登录模式")

不可删除或修改现有错误码（AUTH-0001 ~ AUTH-0019）。每个新枚举常量需带有 `AUTH-XXXX` 格式的注释标识模块归属。

#### 测试验收方法
1. 编写单元测试验证所有 14 个新增错误码的存在性、code/getCode()/getMessage() 方法返回值正确
2. 验证现有 19 个错误码未被修改或删除
3. 验证 `mvn clean compile -pl cloudoffice-common` 编译通过

---

### 2.1.5 TASK-005：RedisKeyConstants 验证码相关Key扩展

**任务ID：** `TASK-005`
**任务名称：** RedisKeyConstants 验证码相关Key扩展
**任务类型：** `common`
**关联UserStory：** `US-016`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-029`

#### 上下文读取
- SDS v0.1.6：3.3.1 节 Redis Key 设计（v0.1.6 新增），5.5 节 Redis Key 设计表
- 需求文档 FR-016：验证码管理服务
- 现有代码：`cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/constant/RedisKeyConstants.java`

#### 详细业务描述
在 `cloudoffice-common` 模块的 `RedisKeyConstants` 常量类中新增以下验证码相关的 Redis Key 常量：

```java
// 验证码缓存 Key：auth:verification:{purpose}:{target}
String VERIFICATION_CODE = "auth:verification:";
// 验证码发送频率控制 Key：auth:verification:freq:{purpose}:{target}
String VERIFICATION_FREQ = "auth:verification:freq:";
```

提供静态方法用于构建完整的 Key 字符串，例如 `buildVerificationCodeKey(String purpose, String target)` 和 `buildVerificationFreqKey(String purpose, String target)`。

#### 测试验收方法
1. 编写单元测试验证 Key 常量的正确性
2. 验证 Key 构建方法输出格式符合设计规范
3. 验证 `mvn clean compile -pl cloudoffice-common` 编译通过

---

## 2.2 cloudoffice-auth-service 认证服务 - DTO

### 2.2.1 TASK-006：LoginRequest DTO修改

**任务ID：** `TASK-006`
**任务名称：** LoginRequest DTO修改（增加loginMode等字段）
**任务类型：** `backend`
**关联UserStory：** `US-004`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-002`, `TASK-003`
- 下游任务：`TASK-017`, `TASK-018`, `TASK-019`, `TASK-020`, `TASK-021`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-004「认证相关 DTO 扩展」章节 AC1
- SDS v0.1.6：4.2.1 节「多模式登录」接口定义，请求参数表格
- 需求文档 FR-004：认证相关 DTO 扩展
- 现有代码：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/LoginRequest.java`

#### 详细业务描述
修改现有 `LoginRequest` DTO，新增以下字段：
- `loginMode`（String，标识登录模式，如 USERNAME_PASSWORD 等）
- `phone`（String，可选，PHONE_CODE/PHONE_PASSWORD 模式必填）
- `smsCode`（String，可选，PHONE_CODE 模式必填）
- `oauthProvider`（String，可选，OAUTH 模式必填）
- `oauthCode`（String，可选，OAUTH 模式必填）

同时将现有 `loginName` 和 `password` 字段注解改为非必填（去除 @NotBlank 或改为条件校验），保留 `tenantCode`（所有模式必填）和 `clientType`（所有模式必填）。要求向后兼容：`loginMode` 不传时默认 `USERNAME_PASSWORD` 模式。

使用 Lombok 注解（@Data、@Builder 等），实现 Serializable 接口，使用 `@Valid` 注解进行参数校验。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证序列化/反序列化正确
3. 验证向后兼容性：不传 loginMode 时与 v0.1.5 行为一致

---

### 2.2.2 TASK-007：RegisterRequest DTO修改

**任务ID：** `TASK-007`
**任务名称：** RegisterRequest DTO修改（增加registerMode等字段）
**任务类型：** `backend`
**关联UserStory：** `US-004`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-001`, `TASK-003`
- 下游任务：`TASK-022`, `TASK-023`, `TASK-024`, `TASK-025`, `TASK-026`, `TASK-027`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-004「认证相关 DTO 扩展」章节 AC2
- SDS v0.1.6：4.2.2 节「多模式注册」接口定义，请求参数表格
- 需求文档 FR-004：认证相关 DTO 扩展
- 现有代码：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/RegisterRequest.java`

#### 详细业务描述
修改现有 `RegisterRequest` DTO，新增以下字段：
- `registerMode`（String，标识注册模式，如 USERNAME、PHONE_CODE 等）
- `smsCode`（String，可选，PHONE_CODE 模式必填）
- `oauthProvider`（String，可选，OAUTH 模式必填）
- `oauthCode`（String，可选，OAUTH 模式必填）

移除 `tenantId` 字段。字段按需改为可选（不同注册模式下必填字段不同）。要求向后兼容：`registerMode` 不传时默认 `USERNAME` 模式。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证序列化/反序列化正确
3. 验证向后兼容性：不传 registerMode 时与 v0.1.5 行为一致

---

### 2.2.3 TASK-008：新增 PasswordChangeRequest DTO

**任务ID：** `TASK-008`
**任务名称：** 新增 PasswordChangeRequest DTO
**任务类型：** `backend`
**关联UserStory：** `US-004`, `US-008`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-031`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-004「认证相关 DTO 扩展」章节 AC3，US-008「用户修改密码 API」
- SDS v0.1.6：4.2.3 节「修改密码」接口定义
- 需求文档 FR-004（3）和 FR-008

#### 详细业务描述
在 `cloudoffice-auth-service` 模块的 `org.cloudstrolling.cloudoffice.auth.dto.request` 包下新增 `PasswordChangeRequest` DTO，包含以下字段：
- `oldPassword`（String，原密码，@NotBlank）
- `newPassword`（String，新密码，@Size min=8, max=64）
- `confirmPassword`（String，确认新密码）

使用 Lombok 注解，实现 Serializable。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证参数校验注解正确触发
3. 验证序列化/反序列化正确

---

### 2.2.4 TASK-009：新增 PasswordForgotRequest DTO

**任务ID：** `TASK-009`
**任务名称：** 新增 PasswordForgotRequest DTO
**任务类型：** `backend`
**关联UserStory：** `US-004`, `US-009`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-031`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-004「认证相关 DTO 扩展」章节 AC4，US-009「用户密码找回 API」
- SDS v0.1.6：4.2.5 节「密码找回-重置密码」接口定义
- 需求文档 FR-004（4）和 FR-009

#### 详细业务描述
在 `cloudoffice-auth-service` 模块的 `org.cloudstrolling.cloudoffice.auth.dto.request` 包下新增 `PasswordForgotRequest` DTO，包含以下字段：
- `mode`（String，找回方式：EMAIL / SMS）
- `target`（String，邮箱地址或手机号）
- `code`（String，验证码）
- `newPassword`（String，新密码，@Size min=8, max=64）

使用 Lombok 注解，实现 Serializable。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证参数校验注解正确触发
3. 验证序列化/反序列化正确

---

### 2.2.5 TASK-010：新增 SendVerificationCodeRequest DTO

**任务ID：** `TASK-010`
**任务名称：** 新增 SendVerificationCodeRequest DTO
**任务类型：** `backend`
**关联UserStory：** `US-004`, `US-016`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-029`, `TASK-033`

#### 上下文读取
- PRD v0.1.6：US-004「认证相关 DTO 扩展」章节 AC5
- SDS v0.1.6：4.2.8 节「发送验证码」接口定义
- 需求文档 FR-004（5）

#### 详细业务描述
在 `cloudoffice-auth-service` 模块的 `org.cloudstrolling.cloudoffice.auth.dto.request` 包下新增 `SendVerificationCodeRequest` DTO，包含以下字段：
- `target`（String，手机号或邮箱）
- `purpose`（String，用途：REGISTER / LOGIN / RESET_PASSWORD / CHANGE_PHONE）
- `mode`（String，发送方式：SMS / EMAIL）

使用 Lombok 注解，实现 Serializable。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证序列化/反序列化正确

---

### 2.2.6 TASK-011：新增 PhoneChangeRequest DTO

**任务ID：** `TASK-011`
**任务名称：** 新增 PhoneChangeRequest DTO
**任务类型：** `backend`
**关联UserStory：** `US-004`, `US-010`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-031`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-004「认证相关 DTO 扩展」章节 AC6，US-010「用户修改手机号 API」
- SDS v0.1.6：4.2.6 节「修改手机号」接口定义
- 需求文档 FR-004（6）和 FR-010

#### 详细业务描述
在 `cloudoffice-auth-service` 模块的 `org.cloudstrolling.cloudoffice.auth.dto.request` 包下新增 `PhoneChangeRequest` DTO，包含以下字段：
- `newPhone`（String，新手机号）
- `oldPhoneCode`（String，原手机号验证码，原手机号可用时必填）
- `newPhoneCode`（String，新手机号验证码）
- `emailCode`（String，邮箱验证码，原手机号不可用时选填）

使用 Lombok 注解，实现 Serializable。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证序列化/反序列化正确

---

### 2.2.7 TASK-012：新增 AccountSettlementRequest DTO

**任务ID：** `TASK-012`
**任务名称：** 新增 AccountSettlementRequest DTO
**任务类型：** `backend`
**关联UserStory：** `US-004`, `US-005`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-026`, `TASK-027`, `TASK-031`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-004「认证相关 DTO 扩展」章节 AC7
- SDS v0.1.6：4.2.7 节「完善账号信息」接口定义
- 需求文档 FR-004（7）和 FR-005

#### 详细业务描述
在 `cloudoffice-auth-service` 模块的 `org.cloudstrolling.cloudoffice.auth.dto.request` 包下新增 `AccountSettlementRequest` DTO，包含以下字段：
- `userId`（Long，用户 ID）
- `loginName`（String，用户名，PHONE_SET_USERNAME 模式必填）
- `password`（String，密码，OAUTH_SET_INFO 模式必填）
- `phone`（String，手机号，OAUTH_SET_INFO 模式必填）
- `smsCode`（String，手机验证码，OAUTH_SET_INFO 模式必填）

使用 Lombok 注解，实现 Serializable。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证序列化/反序列化正确

---

### 2.2.8 TASK-013：新增 AuthResult + RegisterResult 策略结果DTO

**任务ID：** `TASK-013`
**任务名称：** 新增 AuthResult + RegisterResult 策略结果DTO
**任务类型：** `backend`
**关联UserStory：** `US-007`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-017`, `TASK-022`, `TASK-028`

#### 上下文读取
- PRD v0.1.6：US-007「统一认证服务层」章节 AC2
- SDS v0.1.6：4.2 节接口规范，2.2.2 节 dto 结构
- 需求文档 FR-007：统一认证服务层设计

#### 详细业务描述
在 `cloudoffice-auth-service` 模块的 `org.cloudstrolling.cloudoffice.auth.dto.result` 包下新增：

1. **AuthResult（策略认证结果DTO）：**
   - `userId`（Long）
   - `tenantId`（Long）
   - `loginName`（String）
   - `userName`（String）
   - `phone`（String）
   - `roles`（List<String>，角色编码列表）
   - `permissions`（List<String>，权限标识列表）

2. **RegisterResult（注册结果DTO）：**
   - `userId`（Long）
   - `loginName`（String）
   - `userName`（String）
   - `accountSettled`（Boolean，是否已完善）
   - `tokenPair`（TokenPairDTO，仅 PHONE_CODE/OAUTH 等自动登录模式返回）

使用 Lombok 注解（@Data、@Builder、@NoArgsConstructor、@AllArgsConstructor），实现 Serializable。

#### 测试验收方法
1. 编写单元测试验证所有字段的 getter/setter/Builder 方法
2. 验证 AuthResult 和 RegisterResult 的序列化/反序列化正确

---

## 2.3 cloudoffice-auth-service 认证服务 - 实体/Mapper

### 2.3.1 TASK-014：新增 OAuthAccountEntity + OAuthAccountMapper

**任务ID：** `TASK-014`
**任务名称：** 新增 OAuthAccountEntity + OAuthAccountMapper
**任务类型：** `backend`
**关联UserStory：** `US-011`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-036`
- 下游任务：`TASK-021`, `TASK-025`, `TASK-027`

#### 上下文读取
- PRD v0.1.6：US-011「OAuth 账号关联表」章节
- SDS v0.1.6：3.2.1 节「t_auth_oauth_account」表结构设计
- 需求文档 FR-011：OAuth 账号关联表
- 现有代码：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/` 下的现有 Entity

#### 详细业务描述
1. 新增 `OAuthAccountEntity` 实体类，位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，映射表 `t_auth_oauth_account`：
   - 使用 `@TableName("t_auth_oauth_account")` 注解
   - 继承 `BaseEntity`（自动获取 id/create_time/update_time/deleted）
   - 字段：userId、oauthProvider、oauthOpenId、oauthUnionId、oauthNickname、oauthAvatar、boundTime
   - 使用 MyBatis-Plus 注解（`@TableField`、`@TableId` 等）

2. 新增 `OAuthAccountMapper` 接口，位于 `org.cloudstrolling.cloudoffice.auth.mapper` 包：
   - 继承 `BaseMapper<OAuthAccountEntity>`
   - 提供自定义方法：
     - `selectByUserId(Long userId)` — 按用户ID查询
     - `selectByProviderAndOpenId(String provider, String openId)` — 按提供商+openId查询
     - `insert(OAuthAccountEntity entity)` — 新增绑定（使用 MP 内置）

#### 测试验收方法
1. 编写单元测试验证 Entity 字段映射正确
2. 验证 Mapper 基础 CRUD 和自定义查询方法

---

### 2.3.2 TASK-015：新增 VerificationCodeEntity + VerificationCodeMapper

**任务ID：** `TASK-015`
**任务名称：** 新增 VerificationCodeEntity + VerificationCodeMapper
**任务类型：** `backend`
**关联UserStory：** `US-012`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-036`
- 下游任务：`TASK-029`

#### 上下文读取
- PRD v0.1.6：US-012「验证码记录表」章节
- SDS v0.1.6：3.2.2 节「t_auth_verification_code」表结构设计
- 需求文档 FR-012：验证码记录表

#### 详细业务描述
1. 新增 `VerificationCodeEntity` 实体类，位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，映射表 `t_auth_verification_code`：
   - 使用 `@TableName("t_auth_verification_code")` 注解
   - 继承 `BaseEntity`
   - 字段：target、code、sendMode、purpose、expireTime、used、usedTime、sendCount

2. 新增 `VerificationCodeMapper` 接口，位于 `org.cloudstrolling.cloudoffice.auth.mapper` 包：
   - 继承 `BaseMapper<VerificationCodeEntity>`
   - 提供自定义方法：
     - `selectLatestByTargetAndPurpose(String target, String purpose)` — 按target+purpose查询最新记录
     - `updateUsedStatus(Long id, LocalDateTime usedTime)` — 标记为已使用
     - `deleteExpired(LocalDateTime expireTime)` — 清理过期记录

#### 测试验收方法
1. 编写单元测试验证 Entity 字段映射正确
2. 验证 Mapper 自定义查询方法

---

### 2.3.3 TASK-016：UserEntity扩展（新增字段）

**任务ID：** `TASK-016`
**任务名称：** UserEntity扩展（新增字段）
**任务类型：** `backend`
**关联UserStory：** `US-013`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-036`
- 下游任务：`TASK-018`~`TASK-027`, `TASK-031`

#### 上下文读取
- PRD v0.1.6：US-013「用户表扩展」章节
- SDS v0.1.6：3.2.3 节「t_auth_user」表扩展设计
- 需求文档 FR-013：用户表扩展
- 现有代码：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/UserEntity.java`

#### 详细业务描述
在现有 `UserEntity` 中新增以下字段（使用 MyBatis-Plus `@TableField` 注解映射）：
- `registerMode`（String，注册模式，默认 `USERNAME`）
- `accountSettled`（Boolean，账号是否完善，默认 `true`）
- `phoneVerified`（Boolean，手机是否验证，默认 `false`）
- `emailVerified`（Boolean，邮箱是否验证，默认 `false`）
- `lastPasswordChangeTime`（LocalDateTime，最后修改密码时间）

所有新增字段设置合理的默认值，保证与 v0.1.5 的现有用户数据兼容。

#### 测试验收方法
1. 编写单元测试验证新增字段的正确性和默认值
2. 验证 Entity 序列化/反序列化正确

---

## 2.4 cloudoffice-auth-service 认证服务 - 策略模式

### 2.4.1 TASK-017：LoginStrategy接口 + LoginStrategyFactory

**任务ID：** `TASK-017`
**任务名称：** LoginStrategy接口 + LoginStrategyFactory
**任务类型：** `backend`
**关联UserStory：** `US-006`, `US-007`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-002`, `TASK-006`
- 下游任务：`TASK-018`, `TASK-019`, `TASK-020`, `TASK-021`, `TASK-028`

#### 上下文读取
- PRD v0.1.6：US-006「多模式登录 API」章节 AC6，US-007「统一认证服务层」章节
- SDS v0.1.6：1.3.1 节多模式登录流程，2.2.2 节 strategy 包结构
- 需求文档 FR-006 和 FR-007
- SDS 8.4 节 ADR-017：策略模式 + 工厂模式

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增：

1. **LoginStrategy 接口：**
   - 定义 `AuthResult authenticate(LoginRequest request)` 方法
   - 策略实现类使用构造器注入，必须无状态（不可包含可变字段）
   - 方法抛出异常：参数校验异常、BusinessException（包装 ErrorCode）

2. **LoginStrategyFactory 工厂类：**
   - 使用 `@Component` 或 `@Service` 注解注册为 Spring Bean
   - 使用构造器注入所有 LoginStrategy 实现类
   - 提供 `LoginStrategy getStrategy(String loginMode)` 方法
   - 根据 `LoginModeEnum` 的 code 值匹配策略实现
   - 未找到匹配策略时抛出 `IllegalArgumentException`（包装 `LOGIN_MODE_INVALID`）
   - 策略实例预先初始化，运行时 O(1) 获取

#### 测试验收方法
1. 编写 LoginStrategy 接口单元测试（验证接口定义正确）
2. 编写 LoginStrategyFactory 单元测试：有效 loginMode 返回对应策略、无效 mode 抛出异常
3. 覆盖率 ≥ 90%

---

### 2.4.2 TASK-018：UsernamePasswordStrategy实现

**任务ID：** `TASK-018`
**任务名称：** UsernamePasswordStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-006`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-017`
- 下游任务：`TASK-028`

#### 上下文读取
- PRD v0.1.6：US-006「多模式登录 API」章节 AC1
- SDS v0.1.6：1.3.1 节多模式登录流程
- 现有代码：`LoginServiceImpl.java` 中 login 方法的核心逻辑

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `UsernamePasswordStrategy` 类，实现 `LoginStrategy` 接口。

职责：处理 `USERNAME_PASSWORD` 模式的登录认证。
- 校验 `loginName` 和 `password` 不为空
- 通过 `tenantCode` 查询租户获取 tenantId
- 按 `tenantId + loginName` 查询用户
- 使用 BCryptPasswordEncoder.matches() 校验密码
- 校验通过后返回 `AuthResult`（包含 userId/tenantId/loginName/userName/phone/roles/permissions）

保持与 v0.1.5 `LoginServiceImpl.login()` 的现有逻辑向后兼容。使用构造器注入 `UserMapper` 和 `BCryptPasswordEncoder`。

#### 测试验收方法
1. 编写单元测试覆盖：登录成功、密码错误、用户不存在、密码为 null 等场景
2. 覆盖率 ≥ 90%

---

### 2.4.3 TASK-019：PhoneCodeLoginStrategy实现

**任务ID：** `TASK-019`
**任务名称：** PhoneCodeLoginStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-006`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-017`
- 下游任务：`TASK-028`

#### 上下文读取
- PRD v0.1.6：US-006「多模式登录 API」章节 AC2
- SDS v0.1.6：1.3.1 节多模式登录流程
- 需求文档 FR-006

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `PhoneCodeLoginStrategy` 类，实现 `LoginStrategy` 接口。

职责：处理 `PHONE_CODE` 模式的登录认证。
- 校验 `phone` 和 `smsCode` 不为空
- 通过 `phone` + `tenantCode` 查询用户
- 调用 `VerificationCodeManager.verifyCode(phone, smsCode, "LOGIN")` 校验验证码
- 校验通过后返回 `AuthResult`

使用构造器注入 `UserMapper` 和 `VerificationCodeManager`。

#### 测试验收方法
1. 编写单元测试覆盖：验证码正确登录成功、验证码无效、验证码过期、手机号不存在等场景
2. 覆盖率 ≥ 90%

---

### 2.4.4 TASK-020：PhonePasswordLoginStrategy实现

**任务ID：** `TASK-020`
**任务名称：** PhonePasswordLoginStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-006`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-017`
- 下游任务：`TASK-028`

#### 上下文读取
- PRD v0.1.6：US-006「多模式登录 API」章节 AC3
- SDS v0.1.6：1.3.1 节多模式登录流程
- 需求文档 FR-006

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `PhonePasswordLoginStrategy` 类，实现 `LoginStrategy` 接口。

职责：处理 `PHONE_PASSWORD` 模式的登录认证。
- 校验 `phone` 和 `password` 不为空
- 通过 `phone` + `tenantCode` 查询用户
- 使用 BCryptPasswordEncoder.matches() 校验密码
- 校验通过后返回 `AuthResult`

使用构造器注入 `UserMapper` 和 `BCryptPasswordEncoder`。

#### 测试验收方法
1. 编写单元测试覆盖：密码正确登录成功、密码错误、手机号不存在等场景
2. 覆盖率 ≥ 90%

---

### 2.4.5 TASK-021：OAuthLoginStrategy实现

**任务ID：** `TASK-021`
**任务名称：** OAuthLoginStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-006`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-003`, `TASK-014`, `TASK-017`
- 下游任务：`TASK-028`

#### 上下文读取
- PRD v0.1.6：US-006「多模式登录 API」章节 AC4
- SDS v0.1.6：1.3.1 节多模式登录流程
- 需求文档 FR-006

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `OAuthLoginStrategy` 类，实现 `LoginStrategy` 接口。

职责：处理 `OAUTH` 模式的登录认证。
- 校验 `oauthProvider` 和 `oauthCode` 不为空
- 通过 OAuth 提供商验证授权码，获取 access_token 和用户信息（openId）
- 通过 `OAuthAccountMapper.selectByProviderAndOpenId(provider, openId)` 查询平台用户
- 未找到绑定时返回 `OAUTH_ACCOUNT_NOT_BOUND` 错误
- 找到绑定时返回 `AuthResult`

本期 OAuth 验证逻辑使用简化实现（模拟 OAuth 提供商回调），仅做参数校验和 openId 映射。使用构造器注入 `OAuthAccountMapper`。

#### 测试验收方法
1. 编写单元测试覆盖：OAuth账号已绑定登录成功、OAuth账号未绑定、OAuth提供商无效等场景
2. 覆盖率 ≥ 90%

---

### 2.4.6 TASK-022：RegisterStrategy接口 + RegisterStrategyFactory

**任务ID：** `TASK-022`
**任务名称：** RegisterStrategy接口 + RegisterStrategyFactory
**任务类型：** `backend`
**关联UserStory：** `US-005`, `US-007`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-001`, `TASK-007`
- 下游任务：`TASK-023`, `TASK-024`, `TASK-025`, `TASK-026`, `TASK-027`

#### 上下文读取
- PRD v0.1.6：US-005「多模式注册 API」章节 AC7，US-007「统一认证服务层」章节
- SDS v0.1.6：1.3.2 节多模式注册流程，2.2.2 节 strategy 包结构
- 需求文档 FR-005 和 FR-007
- SDS 8.4 节 ADR-017：策略模式 + 工厂模式

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增：

1. **RegisterStrategy 接口：**
   - 定义 `Object register(RegisterRequest request)` 方法（返回 Object 兼容不同注册模式的返回类型差异）
   - 策略实现类使用构造器注入，必须无状态
   - 方法抛出异常：参数校验异常、BusinessException（包装 ErrorCode）

2. **RegisterStrategyFactory 工厂类：**
   - 使用 `@Component` 或 `@Service` 注解注册为 Spring Bean
   - 使用构造器注入所有 RegisterStrategy 实现类
   - 提供 `RegisterStrategy getStrategy(String registerMode)` 方法
   - 根据 `RegisterModeEnum` 的 code 值匹配策略实现
   - 未找到匹配策略时抛出 `IllegalArgumentException`（包装 `REGISTER_MODE_INVALID`）
   - 策略实例预先初始化，运行时 O(1) 获取

#### 测试验收方法
1. 编写 RegisterStrategy 接口单元测试（验证接口定义正确）
2. 编写 RegisterStrategyFactory 单元测试：有效 registerMode 返回对应策略、无效 mode 抛出异常
3. 覆盖率 ≥ 90%

---

### 2.4.7 TASK-023：UsernamePwdRegisterStrategy实现

**任务ID：** `TASK-023`
**任务名称：** UsernamePwdRegisterStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-005`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-016`, `TASK-022`
- 下游任务：`TASK-028`

#### 上下文读取
- PRD v0.1.6：US-005「多模式注册 API」章节 AC1
- SDS v0.1.6：1.3.2 节多模式注册流程
- 需求文档 FR-005

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `UsernamePwdStrategy` 类，实现 `RegisterStrategy` 接口。

职责：处理 `USERNAME` 模式注册。
- 校验 `loginName`、`password`、`phone` 不为空
- 校验用户名在租户内唯一
- 校验手机号在租户内唯一
- 使用 BCrypt 加密密码
- 创建完整用户记录（`register_mode = USERNAME`, `account_settled = true`）
- 返回 `UserDTO`（用户基本信息，不含密码）
- 与 v0.1.5 现有注册逻辑向后兼容

使用构造器注入 `UserMapper` 和 `BCryptPasswordEncoder`。

#### 测试验收方法
1. 编写单元测试覆盖：注册成功、用户名已存在、手机号已存在等场景
2. 覆盖率 ≥ 90%

---

### 2.4.8 TASK-024：PhoneCodeRegisterStrategy实现

**任务ID：** `TASK-024`
**任务名称：** PhoneCodeRegisterStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-005`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-015`, `TASK-022`
- 下游任务：`TASK-028`

#### 上下文读取
- PRD v0.1.6：US-005「多模式注册 API」章节 AC2
- SDS v0.1.6：1.3.2 节多模式注册流程
- 需求文档 FR-005

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `PhoneCodeStrategy` 类，实现 `RegisterStrategy` 接口。

职责：处理 `PHONE_CODE` 模式注册。
- 校验 `phone` 和 `smsCode` 不为空
- 校验手机号在租户内唯一
- 调用 `VerificationCodeManager.verifyCode(phone, smsCode, "REGISTER")` 校验验证码
- 自动生成 `loginName`（如 `user_{phone_hash}`）
- 自动生成随机密码（或暂为空）
- 创建用户记录（`register_mode = PHONE_CODE`, `account_settled = false`）
- 返回 `RegisterResult`（含 TokenPairDTO，完成自动登录）

使用构造器注入 `UserMapper`、`VerificationCodeManager`、`BCryptPasswordEncoder`。

#### 测试验收方法
1. 编写单元测试覆盖：注册成功（含自动登录返回Token）、验证码错误、手机号已存在等场景
2. 覆盖率 ≥ 90%

---

### 2.4.9 TASK-025：OAuthRegisterStrategy实现

**任务ID：** `TASK-025`
**任务名称：** OAuthRegisterStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-005`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-003`, `TASK-014`, `TASK-022`
- 下游任务：`TASK-028`

#### 上下文读取
- PRD v0.1.6：US-005「多模式注册 API」章节 AC3
- SDS v0.1.6：1.3.2 节多模式注册流程
- 需求文档 FR-005

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `OAuthRegisterStrategy` 类，实现 `RegisterStrategy` 接口。

职责：处理 `OAUTH` 模式注册。
- 校验 `oauthProvider` 和 `oauthCode` 不为空
- 通过 OAuth 提供商获取用户信息（openId、昵称、头像等）
- 校验 OAuth openId 在平台内唯一（未被其他用户绑定）
- 自动生成 `loginName`
- 创建用户记录（`register_mode = OAUTH`, `account_settled = false`）
- 创建 OAuth 账号绑定记录（`OAuthAccountEntity`）
- 返回 `RegisterResult`（含 TokenPairDTO，完成自动登录）

使用构造器注入 `UserMapper`、`OAuthAccountMapper`。

#### 测试验收方法
1. 编写单元测试覆盖：注册成功（含OAuth绑定）、OAuth账号已被绑定等场景
2. 覆盖率 ≥ 90%

---

### 2.4.10 TASK-026：PhoneSetUsernameStrategy实现

**任务ID：** `TASK-026`
**任务名称：** PhoneSetUsernameStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-005`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-015`, `TASK-022`
- 下游任务：`TASK-031`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-005「多模式注册 API」章节 AC4
- SDS v0.1.6：1.3.2 节多模式注册流程
- 需求文档 FR-005

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `PhoneSetUsernameStrategy` 类，实现 `RegisterStrategy` 接口。

职责：处理 `PHONE_SET_USERNAME` 模式注册（两步注册第一步）。
- 校验 `phone` 和 `smsCode` 不为空
- 校验手机号在租户内唯一
- 调用 `VerificationCodeManager.verifyCode(phone, smsCode, "REGISTER")` 校验验证码
- 创建临时用户记录（`register_mode = PHONE_SET_USERNAME`, `account_settled = false`）
- 返回 `RegisterResult`（含 TokenPairDTO，完成自动登录）
- 后续用户通过 `PUT /api/v1/auth/account/settlement` 补充 `loginName`

使用构造器注入 `UserMapper`、`VerificationCodeManager`。

#### 测试验收方法
1. 编写单元测试覆盖：两步注册第一步成功（含自动登录）、验证码错误等场景
2. 覆盖率 ≥ 90%

---

### 2.4.11 TASK-027：OAuthSetInfoStrategy实现

**任务ID：** `TASK-027`
**任务名称：** OAuthSetInfoStrategy实现
**任务类型：** `backend`
**关联UserStory：** `US-005`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-003`, `TASK-014`, `TASK-022`
- 下游任务：`TASK-031`, `TASK-032`

#### 上下文读取
- PRD v0.1.6：US-005「多模式注册 API」章节 AC5
- SDS v0.1.6：1.3.2 节多模式注册流程
- 需求文档 FR-005

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service.strategy` 包下新增 `OAuthSetInfoStrategy` 类，实现 `RegisterStrategy` 接口。

职责：处理 `OAUTH_SET_INFO` 模式注册（两步注册第一步）。
- 校验 `oauthProvider` 和 `oauthCode` 不为空
- 通过 OAuth 提供商获取用户信息（openId、昵称、头像等）
- 校验 OAuth openId 在平台内唯一
- 创建临时用户记录（`register_mode = OAUTH_SET_INFO`, `account_settled = false`）
- 创建 OAuth 账号绑定记录
- 返回 `RegisterResult`（含 TokenPairDTO，完成自动登录）
- 后续用户通过 `PUT /api/v1/auth/account/settlement` 补充 `loginName`、`password`、`phone`、`smsCode`

使用构造器注入 `UserMapper`、`OAuthAccountMapper`。

#### 测试验收方法
1. 编写单元测试覆盖：两步注册第一步成功（含OAuth绑定+自动登录）、OAuth账号已被绑定等场景
2. 覆盖率 ≥ 90%

---

## 2.5 cloudoffice-auth-service 认证服务 - 新增服务

### 2.5.1 TASK-028：AuthenticationService 统一认证编排服务

**任务ID：** `TASK-028`
**任务名称：** AuthenticationService 统一认证编排服务
**任务类型：** `backend`
**关联UserStory：** `US-007`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-017`, `TASK-018`, `TASK-019`, `TASK-020`, `TASK-021`
- 下游任务：`TASK-032`

#### 上下文读取
- PRD v0.1.6：US-007「统一认证服务层」章节
- SDS v0.1.6：1.3.1 节多模式登录流程，2.2.2 节 service 结构
- 需求文档 FR-007

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service` 包下新增 `AuthenticationService` 服务类。

职责：编排登录认证的"策略校验 → 统一后处理"完整流程。

**`authenticate(LoginRequest request)` 方法完整流程：**
1. 调用 `LoginStrategyFactory.getStrategy(request.getLoginMode()).authenticate(request)` 获取 `AuthResult`
2. 校验租户状态（调用 `TenantMapper` 查询租户状态，缓存至 Redis）
3. 校验用户状态（`account_settled=false` 时返回 `ACCOUNT_NOT_SETTLED`）
4. 构建 `LoginUserDTO`（从 AuthResult 获取数据 + 补充 clientType）
5. 签发 JWT 双 Token（调用 `JwtUtils.generateAccessToken`/`generateRefreshToken`）
6. 同端互斥处理（调用 `LoginSessionService` 删除旧会话）
7. 写入 Redis 登录态（调用 `LoginSessionService.createSession`）
8. 缓存账号/租户状态（调用 `LoginSessionService` 缓存方法）
9. 记录登录日志（调用 `LoginLogService.recordLoginSuccess`）
10. 更新最后登录时间和 IP
11. 返回 `TokenPairDTO`

**`register(RegisterRequest request)` 方法：**
- 调用 `RegisterStrategyFactory.getStrategy(request.getRegisterMode()).register(request)`
- 返回注册结果

使用构造器注入所有依赖服务。策略实现类和工厂注入后，新增策略无需修改 AuthenticationService。

#### 测试验收方法
1. 编写单元测试覆盖：4种登录模式的完整认证编排流程
2. 验证流程编排顺序正确（Mock 每个步骤）
3. 验证 account_settled=false 时返回 ACCOUNT_NOT_SETTLED
4. 覆盖率 ≥ 85%

---

### 2.5.2 TASK-029：VerificationCodeManager 验证码管理服务

**任务ID：** `TASK-029`
**任务名称：** VerificationCodeManager 验证码管理服务
**任务类型：** `backend`
**关联UserStory：** `US-016`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-005`, `TASK-015`
- 下游任务：`TASK-019`, `TASK-024`, `TASK-026`, `TASK-031`

#### 上下文读取
- PRD v0.1.6：US-016「验证码管理服务」章节
- SDS v0.1.6：1.3.3 节验证码生命周期管理，3.3 节缓存设计
- 需求文档 FR-016

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service` 包下新增 `VerificationCodeManager` 服务类。

核心方法：
1. **`generateCode(String target, String mode, String purpose)`：**
   - 生成 6 位数字随机验证码（可配置 `app.verification-code.length`）
   - 写入 Redis（Key: `auth:verification:{purpose}:{target}`, TTL: 5 分钟）
   - 持久化至 `t_auth_verification_code` 表
   - 返回验证码内容

2. **`verifyCode(String target, String code, String purpose)`：**
   - 从 Redis 或数据库查询验证码
   - 校验：存在、未过期（expire_time）、未使用（used=0）、target 和 purpose 匹配
   - 校验通过：标记 used=1、记录 used_time
   - 校验失败：抛出 `SMS_CODE_INVALID` 或 `SMS_CODE_EXPIRED`

3. **`isSendTooFrequent(String target, String purpose)`：**
   - 检查 Redis Key `auth:verification:freq:{purpose}:{target}` 是否存在
   - 存在 => 60 秒内已发送 => 返回 true（抛出 `SMS_SEND_TOO_FREQUENT`）
   - 不存在 => 允许发送 => 写入 Redis（TTL: 60 秒）

4. **`cleanExpiredCodes()`：**
   - 清理数据库中过期的验证码记录

使用构造器注入 `VerificationCodeMapper` 和 `RedisTemplate`。

#### 测试验收方法
1. 编写单元测试覆盖：验证码生成成功、校验通过、验证码过期、验证码已使用、频率控制、target 为 null 等场景
2. 覆盖率 ≥ 90%

---

### 2.5.3 TASK-030：VerificationCodeService 验证码发送服务（接口+模拟实现）

**任务ID：** `TASK-030`
**任务名称：** VerificationCodeService 验证码发送服务（接口+模拟实现）
**任务类型：** `backend`
**关联UserStory：** `US-015`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-029`

#### 上下文读取
- PRD v0.1.6：US-015「验证码发送服务」章节
- SDS v0.1.6：2.2.2 节 VerificationCodeService 描述
- 需求文档 FR-015

#### 详细业务描述
1. **`VerificationCodeService` 接口**（`org.cloudstrolling.cloudoffice.auth.service` 包下）：
   - `void sendSmsCode(String phone, String code, String purpose)` — 发送短信验证码
   - `void sendEmailCode(String email, String code, String purpose)` — 发送邮件验证码

2. **`SimulatedVerificationCodeService` 实现类**（`org.cloudstrolling.cloudoffice.auth.service.impl` 包下）：
   - 使用 `@Profile("!prod")` 或 `@ConditionalOnProperty(name="app.verification-code.mock", havingValue="true")` 注解
   - 在日志中以 INFO 级别输出验证码内容（格式：`[模拟发送] 短信验证码 {code} 已发送至手机 {phone}，用途：{purpose}`）
   - 返回成功（void 正常返回）
   - 生产环境替换为真实实现时，只需新增实现类并替换 `@ConditionalOnProperty` 配置

#### 测试验收方法
1. 编写接口定义的单元测试
2. 验证模拟实现日志输出格式正确
3. 验证配置 `app.verification-code.mock=true` 时自动装配模拟实现

---

### 2.5.4 TASK-031：PasswordService 密码管理服务

**任务ID：** `TASK-031`
**任务名称：** PasswordService 密码管理服务
**任务类型：** `backend`
**关联UserStory：** `US-008`, `US-009`
**优先级：** `P0`（修改密码）/ `P1`（密码找回）
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-008`, `TASK-009`, `TASK-016`, `TASK-029`
- 下游任务：`TASK-032`

#### 上下文读取
- PRD v0.1.6：US-008「用户修改密码 API」章节，US-009「用户密码找回 API」章节
- SDS v0.1.6：4.2.3 节修改密码，4.2.4 节密码找回-发送验证码，4.2.5 节密码找回-重置密码
- 需求文档 FR-008 和 FR-009

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service` 包下新增 `PasswordService` 服务类。

**`changePassword(Long userId, String oldPassword, String newPassword, String confirmPassword)` 方法：**
1. 校验 `newPassword` 与 `confirmPassword` 一致
2. 校验 `newPassword` 长度 8~64，包含字母和数字
3. 查询用户当前密码（BCrypt）
4. 校验 `oldPassword`（BCryptPasswordEncoder.matches）
5. 校验 `newPassword` 与当前密码不同
6. 新密码 BCrypt 加密更新数据库
7. 更新 `last_password_change_time`
8. 清理该用户所有 Redis 登录态会话
9. 敏感信息脱敏记录日志

**`forgotPasswordSendCode(String target, String mode)` 方法：**
1. 校验 target 对应账号存在
2. 调用 `VerificationCodeManager.generateCode(target, mode, "RESET_PASSWORD")`
3. 调用 `VerificationCodeService.sendSmsCode/sendEmailCode` 发送验证码

**`forgotPasswordReset(String target, String mode, String code, String newPassword, String confirmPassword)` 方法：**
1. 校验 `newPassword` 与 `confirmPassword` 一致
2. 调用 `VerificationCodeManager.verifyCode(target, code, "RESET_PASSWORD")` 校验验证码
3. 验证码校验通过后标记为已使用
4. 新密码 BCrypt 加密更新数据库
5. 更新 `last_password_change_time`
6. 清理该用户所有 Redis 登录态会话
7. 敏感信息脱敏记录日志

使用构造器注入 `UserMapper`、`BCryptPasswordEncoder`、`VerificationCodeManager`、`VerificationCodeService`、`LoginSessionService`。

#### 测试验收方法
1. 编写修改密码单元测试：成功修改、原密码错误、新密码与旧密码相同、新密码与确认密码不一致
2. 编写密码找回单元测试：发送验证码成功、重置密码成功、验证码错误/过期
3. 验证密码修改后清理登录态
4. 覆盖率 ≥ 85%

---

## 2.6 cloudoffice-auth-service 认证服务 - Controller

### 2.6.1 TASK-032：AuthController扩展（新增密码管理/手机号变更/账号完善等端点）

**任务ID：** `TASK-032`
**任务名称：** AuthController扩展（新增密码管理/手机号变更/账号完善等端点）
**任务类型：** `backend`
**关联UserStory：** `US-005`, `US-006`, `US-008`, `US-009`, `US-010`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-006`, `TASK-007`, `TASK-008`, `TASK-009`, `TASK-011`, `TASK-012`, `TASK-028`, `TASK-031`
- 下游任务：无

#### 上下文读取
- PRD v0.1.6：US-005~US-010 各 API 定义
- SDS v0.1.6：4.2 节全部 API 接口定义
- 需求文档 附录 A：API 接口总览
- 现有代码：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java`

#### 详细业务描述
扩展现有 `AuthController`，新增和修改以下端点：

**1. 修改 `POST /api/v1/auth/login`（扩展）：**
- 接收 `LoginRequest`（含 loginMode 等新字段）
- 调用 `AuthenticationService.authenticate(request)`
- `loginMode` 不传时默认 `USERNAME_PASSWORD`
- 返回 `ApiResult<TokenPairDTO>`

**2. 修改 `POST /api/v1/auth/register`（扩展）：**
- 接收 `RegisterRequest`（含 registerMode 等新字段）
- 调用 `AuthenticationService.register(request)`
- `registerMode` 不传时默认 `USERNAME`
- 返回 `ApiResult<UserDTO>` 或 `ApiResult<RegisterResult>`

**3. 新增 `PUT /api/v1/auth/password/change`：**
- 接收 `PasswordChangeRequest`
- 从 JWT Token 获取当前用户 ID
- 调用 `PasswordService.changePassword(...)`
- 返回 `ApiResult<Void>`

**4. 新增 `POST /api/v1/auth/password/forgot/send-code`：**
- 接收 `target` 和 `mode` 参数（可封装为轻量DTO）
- 调用 `PasswordService.forgotPasswordSendCode(target, mode)`
- 白名单路径，无需登录
- 返回 `ApiResult<Void>`

**5. 新增 `POST /api/v1/auth/password/forgot/reset`：**
- 接收 `PasswordForgotRequest`
- 调用 `PasswordService.forgotPasswordReset(...)`
- 白名单路径，无需登录
- 返回 `ApiResult<Void>`

**6. 新增 `PUT /api/v1/auth/phone/change`：**
- 接收 `PhoneChangeRequest`
- 从 JWT Token 获取当前用户 ID
- 调用 `UserService.changePhone(userId, request)`（或在 PasswordService 中实现）
- 返回 `ApiResult<Void>`

**7. 新增 `PUT /api/v1/auth/account/settlement`：**
- 接收 `AccountSettlementRequest`
- 调用 `UserService.settleAccount(request)`
- 返回 `ApiResult<UserDTO>`

所有端点统一使用 `@Valid` 注解校验请求参数，返回 `ApiResult<T>`。

#### 测试验收方法
1. 使用 MockMvc 为每个新增/修改端点编写单元测试
2. 覆盖成功场景和错误场景（参数校验失败、业务异常等）
3. 覆盖率 ≥ 80%

---

### 2.6.2 TASK-033：验证码发送Controller端点

**任务ID：** `TASK-033`
**任务名称：** 验证码发送Controller端点
**任务类型：** `backend`
**关联UserStory：** `US-016`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：`TASK-010`, `TASK-029`
- 下游任务：无

#### 上下文读取
- PRD v0.1.6：US-016「验证码管理服务」章节
- SDS v0.1.6：4.2.8 节「发送验证码」接口定义
- 需求文档 FR-016

#### 详细业务描述
在 `AuthController` 中新增 `POST /api/v1/auth/verification-code/send` 端点：

- 接收 `SendVerificationCodeRequest`（含 target、purpose、mode）
- 校验参数合法性
- 调用 `VerificationCodeManager.isSendTooFrequent(target, purpose)` 检查频率
- 调用 `VerificationCodeManager.generateCode(target, mode, purpose)` 生成验证码
- 调用 `VerificationCodeService` 发送验证码（模拟实现输出到日志）
- 返回 `ApiResult<Void>`（message："验证码已发送"）
- 白名单路径，无需登录

#### 测试验收方法
1. 使用 MockMvc 编写单元测试覆盖：发送成功、发送频率过高、参数校验失败等场景
2. 覆盖率 ≥ 80%

---

## 2.7 cloudoffice-auth-service 认证服务 - 配置

### 2.7.1 TASK-034：SecurityConfig白名单扩展

**任务ID：** `TASK-034`
**任务名称：** SecurityConfig白名单扩展
**任务类型：** `backend`
**关联UserStory：** `US-005`, `US-009`, `US-016`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-032`, `TASK-033`

#### 上下文读取
- SDS v0.1.6：8.3 节网关白名单完整列表，4.2 节 API 接口定义
- 需求文档 附录 A：API 接口总览
- 现有代码：`cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/SecurityConfig.java`
- 现有代码：`cloudoffice-gateway` 的 `application.yml` 中白名单配置

#### 详细业务描述
1. **认证服务 SecurityConfig 白名单扩展：**
   - 在 Spring Security 配置中，将以下新增路径加入匿名访问白名单（`.permitAll()`）：
     - `POST /api/v1/auth/verification-code/send`
     - `POST /api/v1/auth/password/forgot/send-code`
     - `POST /api/v1/auth/password/forgot/reset`
   - 已有白名单路径：`POST /api/v1/auth/login`、`POST /api/v1/auth/register`、`POST /api/v1/auth/refresh`、`GET /api/v1/auth/health` 等保持不变

2. **网关白名单配置扩展（如果网关 `application.yml` 中存在白名单配置）：**
   - 同步添加上述 3 个新路径到白名单列表

#### 测试验收方法
1. 验证 SecurityConfig 中白名单路径正确
2. 验证匿名访问新增路径返回正确的响应（而非 401/403）

---

### 2.7.2 TASK-035：验证码相关配置项（application.yml扩展）

**任务ID：** `TASK-035`
**任务名称：** 验证码相关配置项（application.yml扩展）
**任务类型：** `backend`
**关联UserStory：** `US-015`, `US-016`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-029`, `TASK-030`

#### 上下文读取
- SDS v0.1.6：8.1 节配置项表
- 需求文档 5.2 节新增/变更配置
- 现有代码：`cloudoffice-auth-service/src/main/resources/application.yml`

#### 详细业务描述
在 `cloudoffice-auth-service` 的 `application.yml` 中新增以下配置项：

```yaml
app:
  verification-code:
    mock: true                           # 是否启用验证码模拟模式
    expire-seconds: 300                  # 验证码过期时间（秒），默认5分钟
    send-interval-seconds: 60            # 验证码发送间隔（秒）
    length: 6                            # 验证码长度
  password:
    min-length: 8                        # 密码最小长度
    max-length: 64                       # 密码最大长度
```

并创建对应的配置属性类 `VerificationCodeProperties` 和 `PasswordProperties`（或合并为一个 `AuthProperties` 配置类），使用 `@ConfigurationProperties` 注解绑定配置，启用 Spring 的配置属性自动绑定。

#### 测试验收方法
1. 编写单元测试验证配置属性类正确加载配置值
2. 验证默认值在未配置时的使用正确

---

## 2.8 数据库DDL/脚本

### 2.8.1 TASK-036：数据库DDL脚本（新表创建 + 表扩展ALTER）

**任务ID：** `TASK-036`
**任务名称：** 数据库DDL脚本（新表创建 + 表扩展ALTER）
**任务类型：** `docs`
**关联UserStory：** `US-011`, `US-012`, `US-013`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- 上游依赖：无
- 下游任务：`TASK-014`, `TASK-015`, `TASK-016`

#### 上下文读取
- PRD v0.1.6：US-011「OAuth 账号关联表」章节，US-012「验证码记录表」章节，US-013「用户表扩展」章节
- SDS v0.1.6：3.2 节「数据设计」全部内容
- 需求文档 FR-011、FR-012、FR-013
- 现有脚本：`scripts/sql/auth-init-v0.1.5.sql`

#### 详细业务描述
在 `scripts/sql/` 目录下创建 `auth-init-v0.1.6.sql` 脚本文件，包含以下 DDL：

**1. 新建表 `t_auth_oauth_account`：**
```sql
CREATE TABLE `t_auth_oauth_account` (
  `id` BIGINT(20) NOT NULL COMMENT '主键，雪花算法',
  `user_id` BIGINT(20) NOT NULL COMMENT '平台用户 ID',
  `oauth_provider` VARCHAR(32) NOT NULL COMMENT 'OAuth 提供商（WECHAT/DINGTALK/WECHAT_WORK/ALIPAY）',
  `oauth_open_id` VARCHAR(256) NOT NULL COMMENT '第三方平台用户唯一标识（openId）',
  `oauth_union_id` VARCHAR(256) DEFAULT NULL COMMENT '第三方平台用户统一标识（unionId）',
  `oauth_nickname` VARCHAR(128) DEFAULT NULL COMMENT '第三方平台昵称',
  `oauth_avatar` VARCHAR(512) DEFAULT NULL COMMENT '第三方平台头像 URL',
  `bound_time` DATETIME DEFAULT NULL COMMENT '绑定时间',
  `create_time` DATETIME NOT NULL COMMENT '创建时间',
  `update_time` DATETIME NOT NULL COMMENT '更新时间',
  `deleted` TINYINT(4) DEFAULT '0' COMMENT '逻辑删除（0-正常，1-删除）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_provider_openid` (`oauth_provider`, `oauth_open_id`) USING BTREE,
  KEY `idx_user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='OAuth 第三方账号关联表';
```

**2. 新建表 `t_auth_verification_code`：**
```sql
CREATE TABLE `t_auth_verification_code` (
  `id` BIGINT(20) NOT NULL COMMENT '主键，雪花算法',
  `target` VARCHAR(128) NOT NULL COMMENT '发送目标（手机号或邮箱）',
  `code` VARCHAR(16) NOT NULL COMMENT '验证码内容',
  `send_mode` VARCHAR(16) NOT NULL COMMENT '发送方式（SMS/EMAIL）',
  `purpose` VARCHAR(32) NOT NULL COMMENT '用途（REGISTER/LOGIN/RESET_PASSWORD/CHANGE_PHONE）',
  `expire_time` DATETIME NOT NULL COMMENT '过期时间',
  `used` TINYINT(4) DEFAULT '0' COMMENT '是否已使用（0-未使用，1-已使用）',
  `used_time` DATETIME DEFAULT NULL COMMENT '使用时间',
  `send_count` INT(11) DEFAULT NULL COMMENT '当日发送次数',
  `create_time` DATETIME NOT NULL COMMENT '创建时间',
  `update_time` DATETIME NOT NULL COMMENT '更新时间',
  `deleted` TINYINT(4) DEFAULT '0' COMMENT '逻辑删除（0-正常，1-删除）',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_target_purpose` (`target`, `purpose`) USING BTREE,
  KEY `idx_expire_time` (`expire_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='验证码记录表';
```

**3. 扩展表 `t_auth_user`：**
```sql
ALTER TABLE `t_auth_user`
  ADD COLUMN `register_mode` VARCHAR(32) DEFAULT 'USERNAME' COMMENT '注册模式',
  ADD COLUMN `account_settled` TINYINT(4) DEFAULT '1' COMMENT '账号信息是否完善（0-未完善，1-已完善）',
  ADD COLUMN `phone_verified` TINYINT(4) DEFAULT '0' COMMENT '手机号是否已验证（0-未验证，1-已验证）',
  ADD COLUMN `email_verified` TINYINT(4) DEFAULT '0' COMMENT '邮箱是否已验证（0-未验证，1-已验证）',
  ADD COLUMN `last_password_change_time` DATETIME DEFAULT NULL COMMENT '最后修改密码时间';
```

注意：三个 DDL 语句需支持幂等执行（使用 IF NOT EXISTS / IF EXISTS 或前置检查）。

#### 测试验收方法
1. 验证 SQL 语法正确（可在本地 MariaDB 数据库执行测试）
2. 验证 `t_auth_user` 扩展字段设置正确的默认值，与 v0.1.5 数据兼容
3. 验证索引命名和表结构符合项目规范
