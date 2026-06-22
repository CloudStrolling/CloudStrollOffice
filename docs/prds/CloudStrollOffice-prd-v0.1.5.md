# PRD 文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.1.5
**日期：** 2026-06-22

---

## 1. 产品概述

### 1.1 项目背景

云漫智企（CloudStrollOffice）v0.1.0 阶段已完成微服务基础骨架搭建，当前认证服务包含 Spring Security 基础安全配置、OAuth2 授权服务器骨架和 JWT 工具类（HS256 对称加密、24 小时单令牌过期机制）。然而，上述实现仅为基础骨架，缺乏完整的登录认证、权限控制、会话管理和安全审计能力，无法支撑多租户 SaaS 平台的用户认证与权限管理需求。v0.1.5 阶段的目标是构建完整的登录认证与权限管理系统，实现 RBAC 多租户权限模型、多端混合登录、JWT + Redis 双重会话管理、双 Token 续签机制和登录日志审计等核心能力，为平台后续业务功能提供安全、可靠、可扩展的认证授权基础。

### 1.2 产品目标

- **目标 1（RBAC 权限模型）**：实现用户-角色-权限（RBAC）模型，支持多租户隔离，提供统一的认证授权管理能力
- **目标 2（多端混合登录）**：支持 6 种客户端类型（Windows/Ubuntu/H5/Android/iOS/微信小程序）的混合登录，同类型端互斥登录，不同类型端可共存
- **目标 3（三重会话管理）**：构建 JWT 无状态令牌 + Redis 登录态会话 + Redis Token 黑名单的三重管理机制，支持主动登出、强制踢人、账号封禁实时生效
- **目标 4（双 Token 续签）**：实现 Access Token（2 小时有效）+ Refresh Token（7 天有效）的双 Token 机制，升级 JWT 签名算法为 RS256 非对称加密，提升安全性和用户体验
- **目标 5（统一认证拦截）**：在 API 网关层实现全局 Token 校验过滤器，统一拦截所有请求并校验 Access Token，白名单路径放行，将用户信息透传给下游服务
- **目标 6（安全审计）**：实现登录日志审计，记录登录 IP、客户端类型、时间等关键信息，为安全事件追溯和风控策略提供数据基础

### 1.3 核心设计理念

- **认证集中化**：Token 签发仅由 `cloudoffice-auth-service` 负责，请求鉴权在 `cloudoffice-gateway` 完成，业务服务不再重复校验 Token 有效性，通过 Request Header 透传用户信息
- **无状态 + 有状态混合校验**：网关层通过 RS256 公钥本地验签（无状态）快速校验 Token 有效性，同时通过 Redis 查询登录态和黑名单状态（有状态），兼顾性能与安全
- **多租户隔离**：所有认证数据（用户、角色、权限）均按租户 ID 隔离，用户名在租户内唯一，租户间数据互不可见
- **多端会话管理**：以「用户 ID + 客户端类型」为维度管理登录会话，同类型端互斥（新登录踢旧会话），不同类型端可共存

### 1.4 术语表（Glossary）

| 术语 | 英文 | 定义 |
|------|------|------|
| RBAC | Role-Based Access Control | 基于角色的访问控制模型，通过用户-角色-权限三层关联实现权限管理 |
| 多租户 | Multi-Tenancy | 单个 SaaS 实例服务多个企业租户，租户间数据隔离 |
| Access Token | Access Token | 短时效（2 小时）访问令牌，携带用户身份和权限信息，用于 API 请求鉴权 |
| Refresh Token | Refresh Token | 长时效（7 天）刷新令牌，用于无感续签 Access Token，过期后需重新登录 |
| RS256 | RSA Signature with SHA-256 | 基于 RSA 非对称密钥对的 JWT 签名算法，私钥签发、公钥验签 |
| 多端混合登录 | Multi-Client Concurrent Login | 同一账号在不同类型的客户端（如 PC + H5）上同时登录，同类型端互斥 |
| Token 黑名单 | Token Blacklist | Redis 中维护的已吊销 Token 列表，用于实现主动登出和强制踢人 |
| 登录态会话 | Login Session | Redis 中维护的用户登录状态，键为 `auth:session:{userId}:{clientType}` |
| 网关认证过滤器 | AuthFilter | 在 API 网关层实现的全局过滤器，统一拦截和校验所有请求的 Token |

---

## 2. 目标用户

| 用户角色 | 使用场景 | 核心诉求 |
|---------|---------|---------|
| 普通用户 | 使用用户名密码登录平台，在多个设备上访问业务功能 | 安全便捷的登录体验，多端同时在线不冲突，Token 过期无感续签 |
| 租户管理员 | 管理本租户内的用户账号、角色定义和权限分配 | 灵活的 RBAC 授权管理，创建/禁用/封禁用户，分配角色和权限 |
| 平台管理员 | 管理租户级别的认证配置，监控租户内的安全事件 | 查看登录日志审计，执行强制踢人操作，管控租户内账号安全 |
| 平台开发者 | 在网关层和认证服务中实现认证授权基础设施 | 统一的认证错误码、JWT 工具类、网关过滤器、数据库和缓存集成 |
| 安全审计员 | 审查登录日志，定位安全事件和异常行为 | 完整的登录日志记录（时间、IP、设备、状态），支持异常行为分析 |

---

## 3. 用户故事（User Stories）

### US-001: 认证错误码扩展

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-001 (认证错误码扩展)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在公共模块的 `ErrorCode` 枚举中增加认证授权相关的错误码
- **以便** 认证场景下的异常响应能够统一、规范地返回给客户端

#### 前置条件
- `cloudoffice-common` 模块已存在 `ErrorCode` 枚举（位于 `org.cloudstrolling.cloudoffice.common.exception` 包）和 `ErrorCode` 接口（位于 `org.cloudstrolling.cloudoffice.common.model` 包）
- 枚举已实现 `org.cloudstrolling.cloudoffice.common.model.ErrorCode` 接口

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given `ErrorCode` 枚举中已有通用错误码（SUCCESS/BAD_REQUEST 等），When 新增认证授权相关错误码，Then 新增以下 19 个枚举常量并映射正确的 HTTP 状态码：
  - `TOKEN_EXPIRED`(401, "令牌已过期，请刷新令牌")
  - `TOKEN_INVALID`(401, "令牌无效")
  - `TOKEN_BLACKLISTED`(401, "令牌已被吊销")
  - `REFRESH_TOKEN_EXPIRED`(401, "刷新令牌已过期，请重新登录")
  - `REFRESH_TOKEN_INVALID`(401, "刷新令牌无效")
  - `ACCOUNT_DISABLED`(403, "账号已被禁用")
  - `ACCOUNT_LOCKED`(403, "账号已被锁定")
  - `ACCOUNT_BANNED`(403, "账号已被封禁")
  - `ACCOUNT_EXPIRED`(403, "账号已过期")
  - `LOGIN_FAILED`(401, "用户名或密码错误")
  - `CAPTCHA_ERROR`(400, "验证码错误")
  - `CLIENT_TYPE_INVALID`(400, "无效的客户端类型")
  - `SESSION_KICKED_OUT`(401, "账号已在其他设备登录，您已被踢下线")
  - `TENANT_DISABLED`(403, "租户已被禁用")
  - `TENANT_EXPIRED`(403, "租户已过期")
  - `PERMISSION_DENIED`(403, "权限不足")
  - `ROLE_NOT_FOUND`(404, "角色不存在")
  - `USER_NOT_FOUND`(404, "用户不存在")
- [ ] **AC2：** Given 新增的错误码枚举，When 调用 `getCode()` 和 `getMessage()` 方法，Then 返回 `Integer` 类型错误码和 `String` 类型错误描述
- [ ] **AC3：** Given 新增的错误码，When 编译 `cloudoffice-common` 模块，Then 编译通过，无错误警告

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 错误码命名与现有枚举冲突 | 编译失败，需调整命名避免冲突 |
| HTTP 状态码定义错误 | 根据实际认证场景选择正确状态码（401/403/400/404） |

#### 交付物
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java` — 新增认证错误码枚举常量
- 单元测试文件：验证新增错误码的 `getCode()` 和 `getMessage()` 返回值

#### 备注
- 错误码使用 HTTP 状态码作为 `code` 值，`AUTH-XXXX` 仅在注释中标明模块归属
- 与现有 `ErrorCode.java` 保持相同的代码风格和注释规范
- 不可删除或修改现有通用错误码（SUCCESS/BAD_REQUEST 等）

---

### US-002: 客户端类型枚举

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-002 (客户端类型枚举)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在公共模块中定义客户端类型枚举 `ClientTypeEnum`
- **以便** 统一标识和管理 6 种客户端类型，并按设备分类实现多端互斥登录逻辑

#### 前置条件
- `cloudoffice-common` 模块中 `org.cloudstrolling.cloudoffice.common.enums` 包已存在（预留）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 开发者创建 `ClientTypeEnum`，When 查看枚举定义，Then 包含以下 6 个枚举值：
  - `WINDOWS`(code="WINDOWS", label="Windows 桌面端", deviceCategory=PC)
  - `UBUNTU`(code="UBUNTU", label="Ubuntu 桌面端", deviceCategory=PC)
  - `H5`(code="H5", label="H5 网页端", deviceCategory=WEB)
  - `ANDROID`(code="ANDROID", label="Android 移动端", deviceCategory=MOBILE)
  - `IOS`(code="IOS", label="iOS 移动端", deviceCategory=MOBILE)
  - `WECHAT_MINI`(code="WECHAT_MINI", label="微信小程序端", deviceCategory=MINI_PROGRAM)
- [ ] **AC2：** Given 客户端类型 code 字符串，When 调用 `ClientTypeEnum.fromCode(code)`，Then 返回对应的 `Optional<ClientTypeEnum>`（匹配成功）或 `Optional.empty()`（无匹配）
- [ ] **AC3：** Given 两个 `ClientTypeEnum` 实例，When 调用 `isSameCategory(ClientTypeEnum other)`，Then 返回 `true` 表示同类型端（互斥登录依据），`false` 表示不同类型端（可共存）
- [ ] **AC4：** Given 枚举值 `WINDOWS` 和 `UBUNTU`，When 调用 `WINDOWS.isSameCategory(UBUNTU)`，Then 返回 `true`（均属 PC 类）
- [ ] **AC5：** Given 枚举值 `WINDOWS` 和 `H5`，When 调用 `WINDOWS.isSameCategory(H5)`，Then 返回 `false`（分别属 PC 和 WEB 类）

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `fromCode(null)` | 返回 `Optional.empty()` |
| `fromCode("unknown")` | 返回 `Optional.empty()` |
| `fromCode("windows")`（小写） | 返回 `Optional.empty()`（区分大小写） |

#### 交付物
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/enums/ClientTypeEnum.java`
- 设备分类枚举 `DeviceCategory`（可选择内部枚举或独立枚举）

#### 备注
- 枚举位于 `org.cloudstrolling.cloudoffice.common.enums` 包下
- `ClientTypeEnum` 不应依赖任何业务模块

---

### US-003: Token 数据传输对象

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-003 (Token DTO)

#### 故事描述
- **作为** 平台开发者
- **我想要** 定义 Token 相关的数据传输对象（DTO）
- **以便** 登录/刷新 Token 接口能够以统一的数据结构返回令牌信息，网关过滤器能够标准化的传递用户信息

#### 前置条件
- `cloudoffice-common` 模块中 `org.cloudstrolling.cloudoffice.common.dto` 包已存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 创建 `TokenPairDTO` 类，When 查看类定义，Then 包含以下字段并使用 Lombok `@Data`、`@Builder`、`@NoArgsConstructor`、`@AllArgsConstructor` 注解：
  - `accessToken`（String）
  - `refreshToken`（String）
  - `accessTokenExpiresIn`（Long，毫秒时间戳）
  - `refreshTokenExpiresIn`（Long，毫秒时间戳）
  - `tokenType`（String，固定值 `"Bearer"`）
- [ ] **AC2：** Given 创建 `LoginUserDTO` 类，When 查看类定义，Then 包含以下字段并使用 Lombok 注解：
  - `userId`（Long）
  - `tenantId`（Long）
  - `userName`（String）
  - `clientType`（String）
  - `roles`（List&lt;String&gt;）
  - `permissions`（List&lt;String&gt;）
- [ ] **AC3：** Given 以上两个 DTO 类，When 检查实现，Then 均实现 `Serializable` 接口并定义 `serialVersionUID`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `roles` 或 `permissions` 为 null | 使用空列表 `Collections.emptyList()` 默认初始化 |

#### 交付物
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/dto/TokenPairDTO.java`
- `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/dto/LoginUserDTO.java`

#### 备注
- DTO 使用 Lombok 注解减少样板代码，不要手动编写 getter/setter
- 遵循 `ApiResult` 统一响应格式，DTO 只定义数据结构，不包含业务逻辑

---

### US-004: 网关全局认证过滤器

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-004 (网关全局认证过滤器)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在 API 网关中实现全局认证过滤器 `AuthFilter`
- **以便** 在请求入口统一拦截并校验 Access Token，将用户信息透传给下游服务，实现统一的鉴权拦截

#### 前置条件
- `cloudoffice-gateway` 模块已创建，网关基础配置（路由、CORS）已就绪
- 认证服务已集成 RS256 公钥用于 Token 验签（依赖 US-014/US-015）
- 网关已集成 Spring Data Redis（依赖 US-005）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 未认证请求访问白名单路径（`POST /api/v1/auth/login`、`POST /api/v1/auth/register`、`POST /api/v1/auth/refresh`、`GET /api/v1/auth/health`、`/swagger-ui/**`、`/v3/api-docs/**`、`/favicon.ico`），When `AuthFilter` 校验，Then 直接放行，不进行 Token 校验
- [ ] **AC2：** Given 请求访问非白名单路径，When 请求头未携带 `Authorization` 头或格式非 `Bearer <token>`，Then 返回 HTTP 401 和统一错误响应
- [ ] **AC3：** Given 请求携带有效的 Access Token，When `AuthFilter` 执行校验，Then 依次完成：RS256 公钥验签 → 查询 Redis 黑名单（未拉黑）→ 查询 Redis 登录态（有效）→ 校验账号状态（正常）→ 校验租户状态（正常），校验通过后放行
- [ ] **AC4：** Given AuthFilter 校验通过，When 转发请求到下游服务，Then 请求头中透传以下用户信息 Header：
  - `X-User-Id`：用户 ID
  - `X-Tenant-Id`：租户 ID
  - `X-User-Name`：用户名
  - `X-Client-Type`：客户端类型
  - `X-Roles`：角色编码列表（逗号分隔）
  - `X-Permissions`：权限标识列表（逗号分隔）
- [ ] **AC5：** Given Token 已在黑名单中或登录态已失效，When AuthFilter 校验，Then 返回 HTTP 401 和对应错误码响应
- [ ] **AC6：** Given 用户账号被封禁或租户已禁用，When AuthFilter 校验，Then 返回 HTTP 403 和对应错误码响应
- [ ] **AC7：** Given `AuthFilter` 实现，When 检查过滤器优先级，Then 返回 `Ordered.HIGHEST_PRECEDENCE + 10`
- [ ] **AC8：** Given 配置文件 `application.yml`，When 查看白名单路径配置，Then 白名单路径通过配置项 `auth.white-list` 动态配置，非硬编码

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| Access Token 已过期 | 返回 401 `TOKEN_EXPIRED`，提示"令牌已过期，请刷新令牌" |
| Access Token 签名无效 | 返回 401 `TOKEN_INVALID`，提示"令牌无效" |
| Token 在 Redis 黑名单中 | 返回 401 `TOKEN_BLACKLISTED`，提示"令牌已被吊销" |
| 用户账号状态为禁用/封禁 | 返回 403 `ACCOUNT_DISABLED`/`ACCOUNT_BANNED`，提示相应信息 |
| 租户状态为禁用/过期 | 返回 403 `TENANT_DISABLED`/`TENANT_EXPIRED`，提示相应信息 |
| Redis 连接超时或不可用 | 网关应有熔断降级提示，明确返回"服务暂不可用"而非泄漏详细异常 |
| 请求 Header 值包含特殊字符 | 进行 URL 编码处理，确保透传过程中信息完整 |

#### 交付物
- `cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/filter/AuthFilter.java`
- `cloudoffice-gateway/src/main/resources/application.yml`（更新白名单配置）

#### 备注
- 过滤器需实现 `GlobalFilter` 和 `Ordered` 接口
- 使用 `@Component` 注册为 Spring Bean
- 注意 Spring Cloud Gateway 使用 WebFlux 响应式编程模型，过滤器应使用 `ServerWebExchange` 非阻塞 API

---

### US-005: 网关 Redis 集成

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-005 (网关 Redis 集成)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在 API 网关中集成 Spring Data Redis
- **以便** AuthFilter 能够查询 Redis 中的 Token 黑名单、登录态和账号/租户状态信息

#### 前置条件
- `cloudoffice-gateway` 模块已创建，Maven 依赖管理可用
- 父 POM 已声明 Spring Boot 版本（3.2.x）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 网关模块的 `pom.xml`，When 查看依赖，Then 新增以下依赖：
  - `spring-boot-starter-data-redis`
  - `commons-pool2`
- [ ] **AC2：** Given 网关模块的 `application.yml`，When 查看 Redis 配置，Then 包含以下配置项（均支持环境变量覆盖）：
  - `spring.data.redis.host`：`${REDIS_HOST:127.0.0.1}`
  - `spring.data.redis.port`：`${REDIS_PORT:6379}`
  - `spring.data.redis.password`：`${REDIS_PASSWORD:}`
  - `spring.data.redis.database`：`${REDIS_DATABASE:0}`
- [ ] **AC3：** Given 网关模块启动时，When 检查 Spring 上下文，Then 存在 `RedisTemplate<String, Object>` 的 Bean 配置
- [ ] **AC4：** Given Redis Key 前缀常量定义，When 查看 Redis Key 管理类，Then 统一管理以下 Key 格式：
  - 黑名单 Token：`auth:token:blacklist:{tokenSignature}`
  - 登录态 Session：`auth:session:{userId}:{clientType}`
  - 账号状态：`auth:account:status:{userId}`
  - 租户状态：`auth:tenant:status:{tenantId}`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| Redis 连接失败或不可用 | 网关应记录错误日志并给出明确提示，不应泄漏 Redis 连接详情 |
| Redis 环境变量未设置 | 使用默认值（127.0.0.1:6379）连接 |
| Redis Key 不存在 | 查询返回 null/空，按业务逻辑判定为无效状态 |

#### 交付物
- `cloudoffice-gateway/pom.xml` — 新增 Redis 和连接池依赖
- `cloudoffice-gateway/src/main/resources/application.yml` — 新增 Redis 配置
- `cloudoffice-gateway/src/main/java/org/cloudstrolling/cloudoffice/gateway/config/RedisConfig.java` — RedisTemplate Bean 配置

#### 备注
- Redis Key 前缀常量可定义在 `RedisKeyConstants.java` 或 `AuthRedisKeys.java` 中，供网关和认证服务共享（可提取到 common 模块）
- 注意 Spring Cloud Gateway 基于 WebFlux，应使用 `ReactiveRedisTemplate` 而非阻塞式 `RedisTemplate`

---

### US-006: 多租户用户表结构

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-006 (多租户用户表结构)

#### 故事描述
- **作为** 平台开发者
- **我想要** 创建用户表 `t_auth_user` 并设计多租户隔离的表结构
- **以便** 存储平台用户的账号信息，确保用户名在租户内唯一，租户间数据隔离

#### 前置条件
- `cloudstroll_office_auth` 数据库已创建（开发环境）
- MyBatis-Plus 自动填充配置已就绪

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_user` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `tenant_id` BIGINT(20) NOT NULL — 租户 ID
  - `login_name` VARCHAR(64) NOT NULL — 登录名
  - `password` VARCHAR(256) NOT NULL — BCrypt 加密密码
  - `real_name` VARCHAR(64) — 真实姓名
  - `phone` VARCHAR(20) — 手机号
  - `email` VARCHAR(128) — 邮箱
  - `avatar` VARCHAR(512) — 头像 URL
  - `status` TINYINT(4) NOT NULL DEFAULT 0 — 状态（0-正常，1-禁用，2-锁定，3-封禁）
  - `account_expire_time` DATETIME — 账号过期时间（NULL 永不过期）
  - `lock_reason` VARCHAR(256) — 锁定/封禁原因
  - `last_login_time` DATETIME — 最后登录时间
  - `last_login_ip` VARCHAR(64) — 最后登录 IP
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) DEFAULT 0 — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含：
  - 唯一索引 `uk_tenant_login_name`（`tenant_id` + `login_name`）
  - 普通索引 `idx_tenant_status`（`tenant_id` + `status`）
  - 普通索引 `idx_phone`（`phone`）
- [ ] **AC3：** Given `UserEntity` 实体类，When 查看类定义，Then 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，继承 `BaseEntity`，使用 `@TableName("t_auth_user")` 注解

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 同一租户内插入重复 `login_name` | 唯一索引 `uk_tenant_login_name` 阻止，抛出数据库异常 |
| `tenant_id` 或 `login_name` 为 NULL | 数据库 NOT NULL 约束阻止插入 |

#### 交付物
- `scripts/sql/auth-init-v0.1.5.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/UserEntity.java`

#### 备注
- `password` 字段长度 256 以容纳 BCrypt 加密输出（60 字符）+ 未来算法升级余量
- `avatar` 字段长度 512 以容纳完整 URL
- Entity 继承 `BaseEntity` 自动获取 `create_time`、`update_time`、`deleted` 字段

---

### US-007: 租户表结构

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-007 (租户表结构)

#### 故事描述
- **作为** 平台开发者
- **我想要** 创建租户表 `t_auth_tenant`
- **以便** 管理 SaaS 平台的企业租户信息，支持租户状态控制和容量限制

#### 前置条件
- `cloudstroll_office_auth` 数据库已创建
- 系统启动初始化时需要插入默认租户数据

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_tenant` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `tenant_name` VARCHAR(128) NOT NULL — 租户名称
  - `tenant_code` VARCHAR(64) NOT NULL — 租户编码（唯一标识）
  - `contact_name` VARCHAR(64) — 联系人姓名
  - `contact_phone` VARCHAR(20) — 联系电话
  - `contact_email` VARCHAR(128) — 联系邮箱
  - `status` TINYINT(4) NOT NULL DEFAULT 0 — 状态（0-正常，1-禁用，2-过期）
  - `expire_time` DATETIME — 租户到期时间（NULL 永不过期）
  - `max_user_count` INT(11) DEFAULT 0 — 最大用户数（0 不限制）
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) DEFAULT 0 — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含唯一索引 `uk_tenant_code`（`tenant_code`）
- [ ] **AC3：** Given `TenantEntity` 实体类，When 查看类定义，Then 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，使用 `@TableName("t_auth_tenant")` 注解

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 插入重复 `tenant_code` | 唯一索引 `uk_tenant_code` 阻止，抛出异常 |
| `tenant_code` 超过 64 字符 | 数据库 VARCHAR(64) 约束拒绝插入 |

#### 交付物
- `scripts/sql/auth-init-v0.1.5.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/TenantEntity.java`

#### 备注
- `tenant_code` 建议使用简短英文编码（如 `acmecorp`），作为 API 参数使用
- 开发环境可通过 `data.sql` 或 Liquibase/Flyway 初始化默认租户

---

### US-008: 账号注册

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-008 (账号注册)

#### 故事描述
- **作为** 租户管理员
- **我想要** 通过注册接口为本租户创建新的用户账号
- **以便** 新员工能够获得平台访问权限，使用平台业务功能

#### 前置条件
- 租户已存在于 `t_auth_tenant` 表中
- 用户表 `t_auth_user` 已创建

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 一个有效的租户编码，When 租户管理员提交注册请求 `POST /api/v1/auth/register` 包含 `loginName`、`password`、`realName`（可选）、`phone`（可选）、`email`（可选），Then 系统校验通过后创建用户（BCrypt 加密密码），返回用户基本信息（不含密码）和 HTTP 201
- [ ] **AC2：** Given 注册请求中 `loginName` 与租户内已有用户重复，When 提交注册，Then 返回 HTTP 400 和"登录名已存在"错误
- [ ] **AC3：** Given 注册请求中密码不符合规则（少于 8 字符/不含字母或数字），When 提交注册，Then 返回 HTTP 400 和参数校验错误
- [ ] **AC4：** Given 注册请求中 `phone` 格式不正确，When 提交注册，Then 返回 HTTP 400 和手机号格式校验错误
- [ ] **AC5：** Given 注册请求中 `email` 格式不正确，When 提交注册，Then 返回 HTTP 400 和邮箱格式校验错误
- [ ] **AC6：** Given 用户注册成功，When 检查数据库，Then 用户自动分配默认角色

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `loginName` 长度小于 4 或大于 64 字符 | 返回 400 参数校验错误 |
| `loginName` 包含特殊字符（非字母、数字、下划线） | 返回 400 参数校验错误 |
| 密码长度超 64 字符 | 返回 400 参数校验错误 |
| 手机号格式不合法 | 返回 400 "手机号格式错误" |
| 租户编码不存在 | 返回 404 "租户不存在" |
| 租户状态为禁用 | 返回 403 "租户已被禁用" |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 注册接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/UserService.java` — 用户注册业务逻辑

#### 备注
- 请求参数使用 `@Valid` 注解进行参数校验
- 注册时自动分配的默认角色可通过配置指定
- 本期注册接口供后端调试和管理使用，前端注册页面在后续版本实现

---

### US-009: 角色表结构

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-009 (角色表结构)

#### 故事描述
- **作为** 平台开发者
- **我想要** 创建角色表 `t_auth_role`
- **以便** 在租户内定义不同的角色（如管理员、普通用户），支持多租户隔离的角色管理

#### 前置条件
- `cloudstroll_office_auth` 数据库已创建

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_role` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `tenant_id` BIGINT(20) NOT NULL — 租户 ID
  - `role_name` VARCHAR(64) NOT NULL — 角色名称
  - `role_code` VARCHAR(64) NOT NULL — 角色编码（如 `admin`）
  - `description` VARCHAR(256) — 角色描述
  - `status` TINYINT(4) NOT NULL DEFAULT 0 — 状态（0-正常，1-禁用）
  - `sort_order` INT(11) — 排序号
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) DEFAULT 0 — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含唯一索引 `uk_tenant_role_code`（`tenant_id` + `role_code`）
- [ ] **AC3：** Given `RoleEntity` 实体类，When 查看类定义，Then 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，使用 `@TableName("t_auth_role")` 注解

#### 交付物
- `scripts/sql/auth-init-v0.1.5.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/RoleEntity.java`

---

### US-010: 权限表结构

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-010 (权限表结构)

#### 故事描述
- **作为** 平台开发者
- **我想要** 创建权限表 `t_auth_permission`
- **以便** 定义系统中所有可操作的权限点，支持树形结构组织菜单、按钮和 API 权限

#### 前置条件
- `cloudstroll_office_auth` 数据库已创建

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_permission` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `parent_id` BIGINT(20) DEFAULT 0 — 父权限 ID
  - `perm_name` VARCHAR(64) NOT NULL — 权限名称（如「用户管理」）
  - `perm_code` VARCHAR(128) NOT NULL — 权限标识（如 `system:user:list`）
  - `perm_type` TINYINT(4) — 类型（1-菜单，2-按钮，3-API）
  - `path` VARCHAR(256) — 菜单/API 路径
  - `method` VARCHAR(16) — HTTP 方法（API 类型时有效）
  - `sort_order` INT(11) — 排序号
  - `status` TINYINT(4) NOT NULL DEFAULT 0 — 状态（0-正常，1-禁用）
  - `remark` VARCHAR(256) — 备注
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) DEFAULT 0 — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含唯一索引 `uk_perm_code`（`perm_code`）
- [ ] **AC3：** Given `PermissionEntity` 实体类，When 查看类定义，Then 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包，使用 `@TableName("t_auth_permission")` 注解

#### 交付物
- `scripts/sql/auth-init-v0.1.5.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/PermissionEntity.java`

#### 备注
- `parent_id = 0` 表示顶级权限，通过 `parent_id` 自关联实现树形结构
- `perm_code` 采用冒号分隔的层级标识规范（如 `system:user:create`）

---

### US-011: 用户-角色关联表

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-011 (用户-角色关联表)

#### 故事描述
- **作为** 平台开发者
- **我想要** 创建用户-角色关联表 `t_auth_user_role`
- **以便** 建立用户与角色的多对多关系，一个用户可以拥有多个角色

#### 前置条件
- 用户表 `t_auth_user` 和角色表 `t_auth_role` 已创建

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_user_role` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `user_id` BIGINT(20) NOT NULL — 用户 ID
  - `role_id` BIGINT(20) NOT NULL — 角色 ID
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) DEFAULT 0 — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含：
  - 联合唯一索引 `uk_user_role`（`user_id` + `role_id`）
  - 普通索引 `idx_user_id`（`user_id`）
  - 普通索引 `idx_role_id`（`role_id`）

#### 交付物
- `scripts/sql/auth-init-v0.1.5.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/UserRoleEntity.java`

---

### US-012: 角色-权限关联表

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-012 (角色-权限关联表)

#### 故事描述
- **作为** 平台开发者
- **我想要** 创建角色-权限关联表 `t_auth_role_permission`
- **以便** 建立角色与权限的多对多关系，一个角色可以拥有多个权限点

#### 前置条件
- 角色表 `t_auth_role` 和权限表 `t_auth_permission` 已创建

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_role_permission` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `role_id` BIGINT(20) NOT NULL — 角色 ID
  - `permission_id` BIGINT(20) NOT NULL — 权限 ID
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) DEFAULT 0 — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含：
  - 联合唯一索引 `uk_role_permission`（`role_id` + `permission_id`）
  - 普通索引 `idx_role_id`（`role_id`）
  - 普通索引 `idx_permission_id`（`permission_id`）

#### 交付物
- `scripts/sql/auth-init-v0.1.5.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/RolePermissionEntity.java`

---

### US-013: 用户-角色-权限管理 API

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-013 (用户-角色-权限管理 API)

#### 故事描述
- **作为** 租户管理员
- **我想要** 通过管理 API 对本租户内的用户、角色和权限进行 CRUD 操作
- **以便** 灵活管理租户内的授权体系，为用户分配适当的角色和权限

#### 前置条件
- 用户表、角色表、权限表、关联表均已创建
- 管理员已通过身份认证（Access Token 携带角色信息）
- RBAC 实体类和 Mapper 已就绪

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 租户管理员已登录，When 调用 `GET /api/v1/auth/users?page=1&size=20`，Then 返回本租户内的用户分页列表
- [ ] **AC2：** Given 租户管理员已登录，When 调用 `GET /api/v1/auth/users/{userId}`，Then 返回用户详情（含基本信息、角色列表和权限列表）
- [ ] **AC3：** Given 租户管理员已登录，When 调用 `PUT /api/v1/auth/users/{userId}` 修改用户信息，Then 更新成功并返回更新后的用户信息
- [ ] **AC4：** Given 租户管理员已登录，When 调用 `PUT /api/v1/auth/users/{userId}/status` 设置用户状态为禁用/封禁，Then 用户状态更新，Redis 缓存同步更新
- [ ] **AC5：** Given 租户管理员已登录，When 调用 `PUT /api/v1/auth/users/{userId}/roles` 为用户分配角色（传入角色 ID 列表），Then 更新用户的角色关联
- [ ] **AC6：** Given 租户管理员已登录，When 调用 `DELETE /api/v1/auth/users/{userId}`，Then 逻辑删除用户
- [ ] **AC7：** Given 租户管理员已登录，When 调用 `GET /api/v1/auth/roles`、`POST /api/v1/auth/roles`、`PUT /api/v1/auth/roles/{roleId}`，Then 完成角色的列表/创建/修改
- [ ] **AC8：** Given 租户管理员已登录，When 调用 `PUT /api/v1/auth/roles/{roleId}/permissions` 分配角色权限，Then 更新角色的权限关联
- [ ] **AC9：** Given 租户管理员已登录，When 调用 `DELETE /api/v1/auth/roles/{roleId}`，Then 逻辑删除角色
- [ ] **AC10：** Given 租户管理员已登录，When 调用 `GET /api/v1/auth/permissions`，Then 返回树形结构的权限列表
- [ ] **AC11：** Given 租户管理员已登录，When 调用 `POST /api/v1/auth/permissions`、`PUT /api/v1/auth/permissions/{permId}`、`DELETE /api/v1/auth/permissions/{permId}`，Then 完成权限的创建/修改/删除
- [ ] **AC12：** Given 普通用户非管理员登录，When 调用上述任何管理 API，Then 返回 HTTP 403 `PERMISSION_DENIED`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 删除角色时角色已被分配给用户 | 检查引用关系，阻止删除并提示"角色已被分配给用户" |
| 删除权限时权限已被分配给角色 | 检查引用关系，阻止删除并提示"权限已被关联到角色" |
| 查询的用户/角色/权限不存在 | 返回 HTTP 404 和对应错误码（`USER_NOT_FOUND`/`ROLE_NOT_FOUND`） |
| 跨租户查询 | 根据当前用户 `tenant_id` 自动过滤，不可查询其他租户数据 |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/UserController.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/RoleController.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/PermissionController.java`
- 对应的 Service 和 Mapper 层代码

#### 备注
- 所有管理接口需校验当前用户的操作权限（租户管理员或平台管理员）
- 管理接口返回统一格式的 `ApiResult`
- 分配角色和权限使用全量更新方式（传入完整列表，删除不在列表中的旧关联）

---

### US-014: 用户名密码登录

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-014 (用户名密码登录)

#### 故事描述
- **作为** 普通用户
- **我想要** 使用用户名和密码登录平台，指定客户端类型和租户编码
- **以便** 获得 Access Token 和 Refresh Token，安全地访问平台功能，并在多端同时使用时获得一致体验

#### 前置条件
- 租户、用户数据已在数据库中初始化
- JWT 密钥对（RS256）已配置（依赖 US-019/US-020）
- Redis 登录态管理已就绪（依赖 US-021）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 一个已注册的有效用户，When 使用正确的 `loginName`、`password`、`tenantCode` 和 `clientType` 调用 `POST /api/v1/auth/login`，Then 返回 HTTP 200，响应体包含 `TokenPairDTO`（accessToken 有效期 2h、refreshToken 有效期 7d，tokenType 为 "Bearer"）
- [ ] **AC2：** Given 登录请求中的 `tenantCode` 对应的租户状态为禁用或已过期，When 请求登录，Then 返回 HTTP 403（`TENANT_DISABLED` 或 `TENANT_EXPIRED`）
- [ ] **AC3：** Given 用户名或密码错误，When 请求登录，Then 返回 HTTP 401（`LOGIN_FAILED`），并记录登录失败日志
- [ ] **AC4：** Given 用户状态为禁用/锁定/封禁，When 请求登录，Then 返回 HTTP 403（`ACCOUNT_DISABLED`/`ACCOUNT_LOCKED`/`ACCOUNT_BANNED`）
- [ ] **AC5：** Given 用户已在 Windows 端登录，When 同一用户在另一台 Windows 设备上使用相同 `clientType`（`WINDOWS`）登录，Then 旧会话的 Token 被加入黑名单、登录态被清除，新会话登录成功（同端互斥）
- [ ] **AC6：** Given 用户已在 Windows 端登录，When 同一用户在 H5 端使用 `clientType=H5` 登录，Then 旧 Windows 端会话不受影响，新 H5 端登录成功（多端共存）
- [ ] **AC7：** Given 登录成功，When 检查 Redis，Then 存在登录态会话 `auth:session:{userId}:{clientType}`，TTL 为 7 天，内容包含 accessToken、refreshToken、loginTime、ip、deviceInfo
- [ ] **AC8：** Given 登录成功，When 检查数据库 `t_auth_login_log`，Then 新增一条登录成功日志记录，包含 user_id、tenant_id、login_ip、client_type、login_time、login_status=1

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `clientType` 不合法（不在枚举中） | 返回 HTTP 400 `CLIENT_TYPE_INVALID` |
| `tenantCode` 不存在 | 返回 HTTP 404 "租户不存在" |
| 密码为 null 或空字符串 | 返回 HTTP 400 参数校验错误 |
| 用户账号已过期 | 返回 HTTP 403 `ACCOUNT_EXPIRED` |
| Redis 不可用 | 登录失败，返回 HTTP 503 或明确错误提示 |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 登录接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/LoginService.java` — 登录业务逻辑

#### 备注
- 登录成功后自动更新用户表的 `last_login_time` 和 `last_login_ip`
- Token 中携带的 `roles` 和 `permissions` 从数据库实时查询并写入 JWT 声明
- 密码加密使用 BCrypt（强度系数 ≥ 10）

---

### US-015: Token 刷新

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-015 (Token 刷新)

#### 故事描述
- **作为** 普通用户
- **我想要** 在 Access Token 过期后使用 Refresh Token 获取新的令牌对
- **以便** 无需重复登录即可继续使用平台功能，获得无感续签体验

#### 前置条件
- 用户已登录并获得 Refresh Token
- RS256 密钥对已配置

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户持有有效的 Refresh Token（7 天内），When 调用 `POST /api/v1/auth/refresh` 传入 `refreshToken`，Then 返回新的 `TokenPairDTO`（新 Access Token 2h + 新 Refresh Token 7d）
- [ ] **AC2：** Given Token 刷新成功，When 检查 Redis，Then 旧 Refresh Token 被加入黑名单（TTL = 旧 Token 剩余有效期），旧登录态被清除，新登录态已写入
- [ ] **AC3：** Given Refresh Token 已过期（超过 7 天），When 调用刷新接口，Then 返回 HTTP 401 `REFRESH_TOKEN_EXPIRED`，提示"刷新令牌已过期，请重新登录"
- [ ] **AC4：** Given Refresh Token 已被加入黑名单（已被使用吊销），When 调用刷新接口，Then 返回 HTTP 401 `TOKEN_BLACKLISTED`
- [ ] **AC5：** Given Refresh Token 签名无效或 tokenType 不为 "refresh"，When 调用刷新接口，Then 返回 HTTP 401 `REFRESH_TOKEN_INVALID`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 用户账号在 Refresh Token 有效期内被封禁 | 刷新失败，返回 403 `ACCOUNT_BANNED` |
| 租户在 Refresh Token 有效期内被禁用 | 刷新失败，返回 403 `TENANT_DISABLED` |
| `refreshToken` 参数为空 | 返回 HTTP 400 参数校验错误 |
| Redis 登录态会话已不存在 | 要求用户重新登录（返回 401 `SESSION_KICKED_OUT`） |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 刷新 Token 接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/TokenService.java` — Token 刷新业务逻辑

#### 备注
- 每次刷新同时更换 Access Token 和 Refresh Token，实现 Refresh Token 轮换（Rotation）
- 旧 Refresh Token 加入黑名单防止重放攻击
- 网关白名单中需放行 `/api/v1/auth/refresh` 路径

---

### US-016: 用户登出

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-016 (用户登出)

#### 故事描述
- **作为** 普通用户
- **我想要** 主动登出平台
- **以便** 清除当前设备上的登录会话，防止他人使用我的账号

#### 前置条件
- 用户已登录，持有有效的 Access Token

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户已登录，When 在请求头中携带有效的 `Authorization: Bearer <accessToken>` 调用 `POST /api/v1/auth/logout`，Then 返回 HTTP 200 登出成功
- [ ] **AC2：** Given 登出成功，When 检查 Redis，Then 当前 Access Token 被加入黑名单（TTL = Token 剩余有效期），登录态会话 `auth:session:{userId}:{clientType}` 被删除
- [ ] **AC3：** Given 用户登出后，When 使用已登出的 Access Token 访问业务 API，Then 网关返回 HTTP 401 `TOKEN_BLACKLISTED`
- [ ] **AC4：** Given Token 已过期或已失效，When 调用登出接口，Then 返回 HTTP 401（由网关拦截或服务层校验返回）

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 重复登出（Token 已在黑名单中） | 返回 HTTP 200 登出成功（幂等处理） |
| 未携带 Authorization 头 | 网关拦截返回 401 |
| 登出时 Redis 连接异常 | 记录错误日志，尽量完成登出清理 |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 登出接口
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/LoginService.java` — 登出业务逻辑

#### 备注
- 登出仅清除当前客户端类型的登录会话（一个用户登录了 Windows 和 H5，登出 Windows 不影响 H5 会话）
- 登出后更新登录日志的 `logout_time`

---

### US-017: 强制踢人

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-017 (强制踢人)

#### 故事描述
- **作为** 租户管理员
- **我想要** 强制将指定用户的某个端（或所有端）踢下线
- **以便** 在账号异常或安全事件发生时及时终止用户会话

#### 前置条件
- 目标用户已登录（存在 Redis 登录态会话）
- 操作者具有租户管理员或平台管理员权限

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 租户管理员已登录，When 调用 `POST /api/v1/auth/kickout` 传入 `userId` 和 `clientType`，Then 强制踢下该用户的指定客户端类型会话
- [ ] **AC2：** Given 踢人操作成功，When 检查 Redis，Then 目标用户的该端口 Token 被加入黑名单，登录态会话被删除
- [ ] **AC3：** Given 被踢用户的该端口 Token，When 被踢后发起 API 请求，Then 网关返回 HTTP 401 `SESSION_KICKED_OUT`
- [ ] **AC4：** Given 租户管理员调用踢人接口时 `clientType` 为空，When 执行踢人，Then 踢下目标用户所有端（全部客户端类型）
- [ ] **AC5：** Given 普通用户或非管理员调用踢人接口，When 执行踢人，Then 返回 HTTP 403 `PERMISSION_DENIED`

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 目标用户不存在（`userId` 无效） | 返回 HTTP 404 `USER_NOT_FOUND` |
| 目标用户指定端口当前不在线 | 幂等处理，返回操作成功 |
| `clientType` 值不合法 | 返回 HTTP 400 `CLIENT_TYPE_INVALID` |
| 踢自己 | 允许操作（管理员可以主动结束自己的某个端会话） |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/AuthController.java` — 强制踢人接口
- 权限校验逻辑（仅租户管理员/平台管理员可执行）

#### 备注
- 踢人操作记录审计日志（记录操作人、目标用户、时间、客户端类型）
- 被踢用户的该端口下次请求时网关返回 401 及明确提示"账号已在其他设备登录，您已被踢下线"

---

### US-018: 账号封禁/解封

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-018 (账号封禁/解封)

#### 故事描述
- **作为** 租户管理员
- **我想要** 封禁或解封用户账号
- **以便** 在用户违规操作或离职时及时终止其所有端访问权限

#### 前置条件
- 目标用户存在于数据库中
- 操作者具有租户管理员或平台管理员权限

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 租户管理员已登录，When 调用 `PUT /api/v1/auth/users/{userId}/status` 将用户状态设为 `3`（封禁），Then 数据库用户状态更新为封禁，Redis 账号状态缓存 `auth:account:status:{userId}` 更新为 `3`
- [ ] **AC2：** Given 用户被封禁后，When 检查 Redis，Then 该用户所有端（全部 `clientType`）的登录态会话被删除，关联 Token 被加入黑名单
- [ ] **AC3：** Given 被封禁用户的所有 Token 已失效，When 用户发起任何 API 请求，Then 网关返回 HTTP 403 `ACCOUNT_BANNED`
- [ ] **AC4：** Given 租户管理员，When 调用 `PUT /api/v1/auth/users/{userId}/status` 将用户状态设为 `0`（正常），Then 数据库用户状态更新为正常，Redis 账号状态缓存被删除（解封后不再缓存）
- [ ] **AC5：** Given 用户被解封后，When 用户使用正确密码重新登录，Then 登录成功，正常使用平台功能

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 目标用户不存在 | 返回 HTTP 404 `USER_NOT_FOUND` |
| 用户状态已经是封禁，再次封禁 | 幂等处理，返回操作成功 |
| 非管理员操作 | 返回 HTTP 403 `PERMISSION_DENIED` |
| 封禁自己 | 应允许操作（管理员可以封禁自己的账号） |

#### 交付物
- 通过 US-013 中的 `PUT /api/v1/auth/users/{userId}/status` 接口实现
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/UserService.java` — 封禁/解封业务逻辑

#### 备注
- 封禁操作是实时生效的，因为网关每次请求都会校验账号状态缓存
- 封禁后所有端同时下线，无需逐个端踢人
- 解封仅恢复账号登录能力，之前的 Token 仍然在黑名单中，用户需要重新登录

---

### US-019: RS256 非对称密钥管理

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-019 (RS256 非对称密钥管理)

#### 故事描述
- **作为** 平台开发者
- **我想要** 将 JWT 签名算法从 HS256 对称加密升级为 RS256 非对称加密
- **以便** 解决 HS256 对称密钥泄漏风险，认证服务使用私钥签发 Token，网关和业务服务使用公钥验签

#### 前置条件
- 已生成 RSA 2048 位密钥对
- `cloudoffice-auth-service` 和 `cloudoffice-gateway` 模块均需要集成密钥加载

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 认证服务配置文件，When 检查 `application.yml`，Then 包含 `jwt.rsa.private-key`（Base64 编码私钥）和 `jwt.rsa.public-key`（Base64 编码公钥）配置项
- [ ] **AC2：** Given 网关配置文件，When 检查 `application.yml`，Then 包含 `jwt.rsa.public-key` 配置项（仅需公钥）
- [ ] **AC3：** Given 密钥配置加载时，When 密钥格式无效或缺失，Then 服务启动时抛出异常并拒绝启动，日志打印明确错误信息
- [ ] **AC4：** Given 密钥加载成功，When 认证服务签发 Token，Then 使用 RSA 私钥（RS256 算法）签名
- [ ] **AC5：** Given 密钥加载成功，When 网关/AuthService 校验 Token，Then 使用 RSA 公钥（RS256 算法）验签
- [ ] **AC6：** Given 密钥配置，When 系统启动，Then 支持以下三种加载方式（优先级从高到低）：环境变量 → 配置文件 Base64 → PEM 文件路径

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 私钥或公钥配置为空 | 启动失败，抛出 `IllegalArgumentException`，日志打印错误信息 |
| Base64 解码失败 | 启动失败，日志打印解码异常 |
| 密钥位数不足 2048 位 | 启动失败，提示密钥强度不足 |
| PEM 文件不存在 | 启动失败，提示文件路径无效 |

#### 交付物
- `cloudoffice-auth-service/src/main/resources/application.yml` — 新增 RSA 密钥配置
- `cloudoffice-gateway/src/main/resources/application.yml` — 新增 RSA 公钥配置
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/RsaKeyConfig.java` — RSA 密钥加载与校验配置类

#### 备注
- 使用 `java.security.KeyFactory` 和 `java.security.spec.PKCS8EncodedKeySpec`/`X509EncodedKeySpec` 加载 RSA 密钥
- 保留对 HS256 的兼容处理（v0.1.5 过渡期后可移除）
- 生产环境密钥建议通过环境变量或 Nacos 配置中心注入，禁止硬编码在配置文件中
- 开发环境可使用脚本生成密钥对：`openssl genrsa -out private-key.pem 2048` 并转换为 Base64

---

### US-020: JwtUtils 重构

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-020 (JwtUtils 重构)

#### 故事描述
- **作为** 平台开发者
- **我想要** 重构现有的 `JwtUtils` 工具类，支持双 Token 机制和 RS256 非对称算法
- **以便** 签发和解析 Access Token 和 Refresh Token，为登录认证和 Token 续签提供底层支持

#### 前置条件
- RS256 密钥管理配置已就绪（依赖 US-019）
- 现有 `JwtUtils` 位于 `org.cloudstrolling.cloudoffice.auth.util`，使用 @Component 注解

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 重构后的 `JwtUtils`，When 调用 `generateAccessToken(LoginUserDTO user)`，Then 生成 RS256 签名的 Access Token，包含以下声明：`sub`=用户ID、`tenantId`、`clientType`、`tokenType`="access"、`roles`、`permissions`、`iat`、`exp`（当前时间 + 2h）
- [ ] **AC2：** Given 重构后的 `JwtUtils`，When 调用 `generateRefreshToken(LoginUserDTO user)`，Then 生成 RS256 签名的 Refresh Token，包含以下声明：`sub`=用户ID、`tenantId`、`clientType`、`tokenType`="refresh"、`iat`、`exp`（当前时间 + 7d）、`tokenVersion`
- [ ] **AC3：** Given 一个有效的 Access Token，When 调用 `parseAccessToken(String token)`，Then 校验 RS256 签名并检查 `tokenType`="access"，返回 Claims
- [ ] **AC4：** Given 一个有效的 Refresh Token，When 调用 `parseRefreshToken(String token)`，Then 校验 RS256 签名并检查 `tokenType`="refresh"，返回 Claims
- [ ] **AC5：** Given 一个 Access Token 尝试使用 `parseRefreshToken` 解析，When 校验 `tokenType`，Then 抛出异常
- [ ] **AC6：** Given 重构后的 `JwtUtils`，When 调用 `validateToken(String token)`，Then 验证签名和有效期，返回 boolean
- [ ] **AC7：** Given 重构后的 `JwtUtils`，When 调用 `getTokenSignature(String token)`，Then 返回 Token 的签名指纹（用于黑名单 Key）
- [ ] **AC8：** Given 重构后的 `JwtUtils`，When 检查注入方式，Then 使用 `@Service` 注解并通过构造器注入（非 `@Component` + `@Value` 字段注入）

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| Token 签名验证失败 | 抛出 `SignatureException`，上层捕获后返回 `TOKEN_INVALID` |
| Token 已过期 | 抛出 `ExpiredJwtException`，上层捕获后返回 `TOKEN_EXPIRED` |
| Token 格式错误 | 抛出 `MalformedJwtException`，上层捕获后返回 `TOKEN_INVALID` |
| 使用 Access Token 调用 Refresh 接口 | `parseRefreshToken` 检查 tokenType 不匹配，返回 `REFRESH_TOKEN_INVALID` |
| Token 载荷中缺少必要声明 | 解析时校验声明完整性，缺失则视为无效 Token |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/util/JwtUtils.java`（重构现有类）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/JwtConfig.java`（可选，JWT 配置属性类）

#### 备注
- 从 `@Component` + `@Value` 字段注入改造为 `@Service` + 构造器注入，符合 Spring 最佳实践
- Access Token 有效期和 Refresh Token 有效期支持通过 `application.yml` 配置（`jwt.access-token-expiration`、`jwt.refresh-token-expiration`）
- `getTokenSignature()` 使用 Token 字符串的签名部分（第三段）或 SHA256 摘要作为黑名单 Key 标识

---

### US-021: Redis 登录态管理

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-021 (Redis 登录态管理)

#### 故事描述
- **作为** 平台开发者
- **我想要** 实现 `LoginSessionService` 统一管理 Redis 中的登录态会话、Token 黑名单、账号状态和租户状态缓存
- **以便** 登录、登出、Token 刷新、踢人、封禁等操作能够实时同步会话状态

#### 前置条件
- 认证服务已集成 Spring Data Redis（依赖 US-023）
- Redis 服务可用

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户登录成功，When 调用 `LoginSessionService.createSession(userId, clientType, sessionData)`，Then 写入 Redis：`auth:session:{userId}:{clientType}`（String 类型，JSON 格式），TTL 设置为 7 天
- [ ] **AC2：** Given 用户登出，When 调用 `LoginSessionService.addToBlacklist(tokenSignature, ttl)`，Then 写入 Redis：`auth:token:blacklist:{tokenSignature}`，TTL 为 Token 剩余有效期
- [ ] **AC3：** Given 需要校验 Token 是否被拉黑，When 调用 `LoginSessionService.isBlacklisted(tokenSignature)`，Then 返回 `true`（在黑名单中）或 `false`（不在黑名单中）
- [ ] **AC4：** Given 需要查询登录态，When 调用 `LoginSessionService.getSession(userId, clientType)`，Then 返回登录态数据或 null（不存在）
- [ ] **AC5：** Given 用户被封禁，When 调用 `LoginSessionService.setAccountStatus(userId, status)`，Then 写入 Redis：`auth:account:status:{userId}`，值为状态数字
- [ ] **AC6：** Given 需要校验账号状态，When 调用 `LoginSessionService.getAccountStatus(userId)`，Then 返回状态数字或 null（无缓存）
- [ ] **AC7：** Given 踢人操作，When 调用 `LoginSessionService.removeSession(userId, clientType)`，Then 删除 Redis 登录态会话，并将关联 Token 加入黑名单
- [ ] **AC8：** Given 封禁操作，When 调用 `LoginSessionService.removeAllSessions(userId)`，Then 查询该用户所有端口登录态并全部清理

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| Redis Key 已存在（重复创建 Session） | 覆盖旧值，自动清理旧会话 |
| 查询不存在的 Session/黑名单 | 返回 null/false |
| Redis 连接超时 | 抛出运行时异常，由调用方处理降级 |
| `tokenSignature` 为 null 或空字符串 | 抛出 `IllegalArgumentException` |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/LoginSessionService.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/impl/LoginSessionServiceImpl.java`

#### 备注
- Redis Key 统一在常量类或枚举中管理，禁止硬编码
- Session 数据存储为 JSON 字符串，包含 accessToken、refreshToken、loginTime、ip、deviceInfo
- 所有 Redis 操作需记录适当级别的日志以便排查问题

---

### US-022: 登录日志审计

**优先级：** 中 (Should)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-022 (登录日志审计)

#### 故事描述
- **作为** 安全审计员
- **我想要** 系统记录每次登录认证的详细信息（时间、IP、设备、状态）
- **以便** 追溯安全事件、分析异常登录行为，为风控策略提供数据基础

#### 前置条件
- `t_auth_login_log` 表已创建（位于 `cloudstroll_office_auth` 数据库）
- MyBatis-Plus Mapper 基础架构已就绪

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given SQL 建表脚本，When 执行建表，Then 成功创建 `t_auth_login_log` 表，包含以下字段：
  - `id` BIGINT(20) — 主键，雪花算法
  - `tenant_id` BIGINT(20) — 租户 ID
  - `user_id` BIGINT(20) — 用户 ID
  - `login_name` VARCHAR(64) — 登录名
  - `login_ip` VARCHAR(64) — 登录 IP
  - `login_location` VARCHAR(128) — 登录地点（IP 解析，可选）
  - `client_type` VARCHAR(32) — 客户端类型
  - `device_info` VARCHAR(256) — 设备信息
  - `login_time` DATETIME — 登录时间
  - `logout_time` DATETIME — 登出时间
  - `login_status` TINYINT(4) — 登录状态（0-失败，1-成功，2-登出）
  - `fail_reason` VARCHAR(256) — 失败原因
  - `create_time` DATETIME — 创建时间
  - `update_time` DATETIME — 更新时间
  - `deleted` TINYINT(4) DEFAULT 0 — 逻辑删除
- [ ] **AC2：** Given 表结构，When 检查索引，Then 包含：`idx_user_id`、`idx_tenant_id`、`idx_login_time`
- [ ] **AC3：** Given 用户登录成功，When 登录完成后，Then 同步写入一条 `login_status=1`（成功）的登录日志
- [ ] **AC4：** Given 用户登录失败（用户名错误或密码错误），When 登录失败时，Then 写入一条 `login_status=0`（失败）、`fail_reason` 记录失败原因的登录日志
- [ ] **AC5：** Given 用户主动登出，When 登出完成，Then 更新对应登录日志的 `logout_time` 字段

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 登录日志写入数据库失败 | 不应影响主登录流程，记录错误日志（异步写入或降级） |
| 登录时未获取到 IP 信息 | `login_ip` 记录 `"unknown"` 或空字符串 |
| 设备信息超过字段长度 | 截断至 VARCHAR(256) |
| 单用户短时间内大量登录失败 | 每笔失败均记录日志（风控分析数据来源） |

#### 交付物
- `scripts/sql/auth-init-v0.1.5.sql` — 建表 DDL 脚本
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/entity/LoginLogEntity.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/LoginLogService.java`
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/mapper/LoginLogMapper.java`

#### 备注
- 本期登录日志为同步写入，后续可优化为异步消息队列写入
- `login_location` 预留 IP 解析功能，本期可选实现（可实现纯 IP 记录，后续通过离线库或第三方 API 解析）
- 风控策略扩展点（同 IP 短时间多次失败、异地登录检测）本期仅预留注释标记，不实现自动阻断

---

### US-023: 认证服务数据库与缓存集成

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-023 (认证服务数据库与缓存集成)

#### 故事描述
- **作为** 平台开发者
- **我想要** 在认证服务中集成 MariaDB 数据库和 Redis 缓存
- **以便** 认证服务能够持久化存储用户/角色/权限数据，并在 Redis 中缓存登录态和黑名单

#### 前置条件
- `cloudoffice-auth-service` 模块已创建（v0.1.0 骨架）
- MariaDB 10.6 服务和 Redis 7.2.x 服务可用（开发环境）
- 父 POM 中已包含 MyBatis-Plus 和 Spring Data Redis 的版本管理

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given `pom.xml`，When 查看认证服务的依赖，Then 新增以下依赖：
  - `mybatis-plus-spring-boot3-starter`（MyBatis-Plus）
  - `mariadb-java-client`（MariaDB 驱动）
  - `spring-boot-starter-data-redis`（Redis）
  - `commons-pool2`（Redis 连接池）
- [ ] **AC2：** Given `application.yml`，When 查看 MariaDB 数据源配置，Then 包含：
  - `spring.datasource.url`：`jdbc:mariadb://${DB_HOST:127.0.0.1}:${DB_PORT:3306}/cloudstroll_office_auth?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai`
  - `spring.datasource.username`：`${DB_USER:root}`
  - `spring.datasource.password`：`${DB_PASSWORD:root}`
  - `spring.datasource.driver-class-name`：`org.mariadb.jdbc.Driver`
- [ ] **AC3：** Given `application.yml`，When 查看 Redis 配置，Then 包含：
  - `spring.data.redis.host`：`${REDIS_HOST:127.0.0.1}`
  - `spring.data.redis.port`：`${REDIS_PORT:6379}`
  - `spring.data.redis.password`：`${REDIS_PASSWORD:}`
  - `spring.data.redis.database`：`${REDIS_DATABASE:0}`
  - Lettuce 连接池配置（max-active=16, min-idle=4）
- [ ] **AC4：** Given MyBatis-Plus 配置，When 检查配置类，Then 与 `cloudoffice-biz-service` 的 MyBatis-Plus 配置保持一致（自动填充、分页插件等）

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 数据库连接参数错误 | 应用启动失败，打印明确错误日志（不含密码明文） |
| Redis 连接失败 | 应用启动成功但 Redis 相关功能不可用，日志打印警告信息 |
| 数据库驱动类不存在 | 编译失败，检查 `mariadb-java-client` 依赖是否引入 |
| 数据源 URL 中数据库名 `cloudstroll_office_auth` 不存在 | 应用启动时连接失败，需手动创建数据库 |

#### 交付物
- `cloudoffice-auth-service/pom.xml` — 新增依赖声明
- `cloudoffice-auth-service/src/main/resources/application.yml` — 新增 MariaDB 和 Redis 配置
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/config/MyBatisPlusConfig.java` — MyBatis-Plus 配置（如有差异）

#### 备注
- 认证服务应拥有独立的数据库 `cloudstroll_office_auth`，其他服务禁止直接访问
- MyBatis-Plus 配置参考 `cloudoffice-biz-service` 中已有的配置风格
- Redis 配置与网关保持一致，共用同一 Redis 实例（不同 database 可通过配置区分）

---

### US-024: 父 POM 依赖补充

**优先级：** 高 (Must)
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.5.md`
需求编号：FR-024 (父 POM 依赖补充)

#### 故事描述
- **作为** 平台开发者
- **我想要** 确认父 POM 的依赖管理已覆盖本次开发所需的全部依赖
- **以便** 各子模块无需硬编码版本号，统一依赖版本管理

#### 前置条件
- 项目根目录 `pom.xml`（父 POM）已存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 父 POM 的 `<dependencyManagement>`，When 检查依赖管理，Then 确认以下依赖的版本通过 Spring Boot Parent BOM 继承，无需额外声明版本号：
  - `spring-boot-starter-data-redis`
  - `commons-pool2`
- [ ] **AC2：** Given 父 POM，When 检查已有的依赖管理，Then 确保已声明本次开发所需的所有依赖版本（`mybatis-plus-spring-boot3-starter`、`mariadb-java-client` 等）

#### 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| 依赖版本冲突 | Maven 依赖解析时报告冲突，需通过 `<exclusions>` 排除或调整版本 |
| 新依赖未在父 POM 声明 | 子模块直接声明版本号（临时方案），需后续补充到父 POM |

#### 交付物
- 根 `pom.xml`（`cloudoffice/pom.xml`）— 如有必要补充依赖管理

#### 备注
- `spring-boot-starter-data-redis` 和 `commons-pool2` 的版本由 `spring-boot-dependencies` BOM 管理，无需在父 POM 中额外声明
- 如果 `mybatis-plus-spring-boot3-starter` 和 `mariadb-java-client` 已在 v0.1.0/v0.1.4 的父 POM 中声明，则无需重复添加
- 本次开发不引入新的外部依赖，所有依赖均基于已有版本管理体系

---

## 4. 非功能性需求（Non-Functional Requirements）

### 4.1 性能

- Token 校验响应时间 ≤ 10ms（在网关层，含 RS256 公钥验签 + Redis 查询）
- 登录接口响应时间 ≤ 500ms（含 BCrypt 密码校验和 Token 签发）
- 单次登录操作 Redis 读写次数 ≤ 5 次
- 网关认证过滤器使用响应式非阻塞方式，不阻塞业务请求处理线程

### 4.2 可用性

- 所有 API 响应使用简体中文描述
- API 返回统一格式的 `ApiResult<T>` 响应体，包含 code、message、data、timestamp
- 异常提示信息清晰明确，帮助客户端定位问题
- 健康检查端点 `GET /api/v1/auth/health` 始终可用（无需认证）

### 4.3 可靠性

- Redis 不可用时认证服务应给出明确的降级/熔断提示，不泄漏敏感信息
- 数据库连接失败时不泄漏敏感信息（不打印密码、连接串详情）
- Token 解析失败时返回明确的错误码和提示信息
- 登录失败次数不做硬性限制（风控策略后期实现）

### 4.4 安全性

- 密码存储使用 BCrypt 加密算法（强度系数 ≥ 10）
- JWT 签名使用 RS256 非对称加密，私钥安全存储（环境变量或配置中心），禁止硬编码
- Access Token 有效期 2 小时，Refresh Token 有效期 7 天
- 敏感信息（密码、Token、密钥）不在日志中明文输出
- Token 黑名单实时生效，无需等待 Token 自然过期
- 密码传输建议使用 HTTPS（非本期强制，但接口设计预留 HTTPS 支持）

### 4.5 可维护性

- 遵循 project.md 定义的包结构规范（`entity`/`mapper`/`service`/`controller` 等）
- 使用构造器注入，禁止 `@Autowired` 字段注入
- 关键业务逻辑添加详细的行内注释
- Redis Key 统一在常量类或枚举中管理，禁止硬编码字符串
- 错误码统一管理，业务异常使用对应错误码
- 登录日志在关键节点使用 `@Slf4j` 记录

### 4.6 可扩展性

- 新增客户端类型时无需修改业务逻辑代码，仅需在 `ClientTypeEnum` 中添加枚举值
- 支持灵活的权限控制策略（方法级注解 `@PreAuthorize` 集成和验证）
- 白名单路径支持通过 `application.yml` 配置动态调整
- Token 有效期（Access Token 和 Refresh Token）支持通过 `application.yml` 配置

### 4.7 测试覆盖率

- Service 层单元测试覆盖率 ≥ 85%
- Controller 层单元测试覆盖率 ≥ 80%
- JwtUtils 工具类单元测试覆盖率 ≥ 90%
- 关键测试场景覆盖：登录成功/失败、Token 签发/解析/校验（含过期/签名错误）、Token 刷新成功/失败、登出清理、强制踢人、账号封禁/解封、多端互斥登录、网关过滤器放行/拦截、Redis 黑名单校验

---

## 5. 附录

### 5.1 用户故事与功能需求映射

| 用户故事 | 关联需求 | 优先级 | 所属模块 |
|---------|---------|--------|---------|
| US-001 | FR-001 认证错误码扩展 | Must | common |
| US-002 | FR-002 客户端类型枚举 | Must | common |
| US-003 | FR-003 Token DTO | Should | common |
| US-004 | FR-004 网关全局认证过滤器 | Must | gateway |
| US-005 | FR-005 网关 Redis 集成 | Must | gateway |
| US-006 | FR-006 多租户用户表结构 | Must | auth-service |
| US-007 | FR-007 租户表结构 | Must | auth-service |
| US-008 | FR-008 账号注册 | Should | auth-service |
| US-009 | FR-009 角色表结构 | Must | auth-service |
| US-010 | FR-010 权限表结构 | Must | auth-service |
| US-011 | FR-011 用户-角色关联表 | Must | auth-service |
| US-012 | FR-012 角色-权限关联表 | Must | auth-service |
| US-013 | FR-013 用户-角色-权限管理 API | Should | auth-service |
| US-014 | FR-014 用户名密码登录 | Must | auth-service |
| US-015 | FR-015 Token 刷新 | Must | auth-service |
| US-016 | FR-016 用户登出 | Must | auth-service |
| US-017 | FR-017 强制踢人 | Should | auth-service |
| US-018 | FR-018 账号封禁/解封 | Should | auth-service |
| US-019 | FR-019 RS256 非对称密钥管理 | Must | auth-service |
| US-020 | FR-020 JwtUtils 重构 | Must | auth-service |
| US-021 | FR-021 Redis 登录态管理 | Must | auth-service |
| US-022 | FR-022 登录日志审计 | Should | auth-service |
| US-023 | FR-023 认证服务数据库与缓存集成 | Must | auth-service |
| US-024 | FR-024 父 POM 依赖补充 | Must | 根 POM |

### 5.2 新增数据库表汇总

| 表名 | 所属数据库 | 用途 | 关联用户故事 |
|------|-----------|------|-------------|
| `t_auth_tenant` | `cloudstroll_office_auth` | 多租户企业信息 | US-007 |
| `t_auth_user` | `cloudstroll_office_auth` | 用户账号（多租户隔离） | US-006 |
| `t_auth_role` | `cloudstroll_office_auth` | 角色定义 | US-009 |
| `t_auth_permission` | `cloudstroll_office_auth` | 权限点定义 | US-010 |
| `t_auth_user_role` | `cloudstroll_office_auth` | 用户-角色多对多关联 | US-011 |
| `t_auth_role_permission` | `cloudstroll_office_auth` | 角色-权限多对多关联 | US-012 |
| `t_auth_login_log` | `cloudstroll_office_auth` | 登录日志审计 | US-022 |

### 5.3 Redis Key 设计汇总

| Key 格式 | 类型 | TTL | 用途 |
|---------|------|-----|------|
| `auth:session:{userId}:{clientType}` | String | 7 天 | 登录态会话缓存 |
| `auth:token:blacklist:{tokenSignature}` | String | Token 剩余有效期 | Token 黑名单 |
| `auth:account:status:{userId}` | String | 无（手动管理） | 账号状态缓存 |
| `auth:tenant:status:{tenantId}` | String | 无（手动管理） | 租户状态缓存 |

### 5.4 API 接口一览

| 方法 | 路径 | 说明 | 认证 | 关联用户故事 |
|------|------|------|------|-------------|
| POST | `/api/v1/auth/login` | 用户名密码登录 | 否 | US-014 |
| POST | `/api/v1/auth/register` | 用户注册 | 否 | US-008 |
| POST | `/api/v1/auth/refresh` | 刷新 Token | 否（需 Refresh Token） | US-015 |
| POST | `/api/v1/auth/logout` | 用户登出 | 是 | US-016 |
| POST | `/api/v1/auth/kickout` | 强制踢人 | 是（管理员） | US-017 |
| GET | `/api/v1/auth/health` | 健康检查 | 否 | — |
| GET | `/api/v1/auth/users` | 用户列表（分页） | 是（管理员） | US-013 |
| GET | `/api/v1/auth/users/{userId}` | 用户详情 | 是（管理员） | US-013 |
| PUT | `/api/v1/auth/users/{userId}` | 修改用户信息 | 是（管理员） | US-013 |
| PUT | `/api/v1/auth/users/{userId}/status` | 修改用户状态 | 是（管理员） | US-013, US-018 |
| PUT | `/api/v1/auth/users/{userId}/roles` | 分配用户角色 | 是（管理员） | US-013 |
| DELETE | `/api/v1/auth/users/{userId}` | 删除用户 | 是（管理员） | US-013 |
| GET | `/api/v1/auth/roles` | 角色列表 | 是（管理员） | US-013 |
| POST | `/api/v1/auth/roles` | 创建角色 | 是（管理员） | US-013 |
| PUT | `/api/v1/auth/roles/{roleId}` | 修改角色 | 是（管理员） | US-013 |
| PUT | `/api/v1/auth/roles/{roleId}/permissions` | 分配角色权限 | 是（管理员） | US-013 |
| DELETE | `/api/v1/auth/roles/{roleId}` | 删除角色 | 是（管理员） | US-013 |
| GET | `/api/v1/auth/permissions` | 权限列表（树形） | 是（管理员） | US-013 |
| POST | `/api/v1/auth/permissions` | 创建权限 | 是（管理员） | US-013 |
| PUT | `/api/v1/auth/permissions/{permId}` | 修改权限 | 是（管理员） | US-013 |
| DELETE | `/api/v1/auth/permissions/{permId}` | 删除权限 | 是（管理员） | US-013 |
| GET | `/swagger-ui/**` | Swagger 文档 UI | 否 | — |
| GET | `/v3/api-docs/**` | OpenAPI 文档 | 否 | — |

### 5.5 版本记录

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| v0.1.5 | 2026-06-22 | 初始版本，定义登录认证与权限管理系统 24 个用户故事 | BA |

---
