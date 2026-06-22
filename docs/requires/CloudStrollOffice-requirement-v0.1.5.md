# 需求文档

**项目名称：** 云漫智企 (CloudStrollOffice)
**版本号：** v0.1.5
**日期：** 2026-06-22

---

## 修订记录

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| v0.1.5 | 2026-06-22 | 初始版本，定义登录认证与权限管理系统需求 | BA |

---

## 1. 项目背景

### 1.1 业务背景

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务互联网应用程序。v0.1.0 阶段完成了微服务基础骨架搭建（Maven 多模块、公共组件、API 网关、认证服务骨架、企业服务骨架），v0.1.4 阶段完成了系统服务模块搭建。

当前 v0.1.0 阶段搭建的认证服务骨架包含：
- Spring Security 基础安全配置（CSRF 关闭、无状态会话、BCrypt 密码编码器）
- OAuth2 授权服务器骨架配置
- JWT 工具类（仅支持 HS256 对称加密算法，24 小时单令牌过期机制）
- 健康检查端点

上述实现仅为基础骨架，**缺乏完整的多端登录认证、权限控制、会话管理、登录态校验、安全审计等核心能力**，无法支撑多租户 SaaS 平台的用户认证与权限管理需求。

v0.1.5 阶段的目标是**完成完整的登录认证与权限管理系统**，实现用户-角色-权限（RBAC）模型、多端混合登录、JWT + Redis 双重会话管理、双 Token 续签机制、登录日志审计与风控等核心功能，为平台后续业务功能提供安全、可靠、可扩展的认证授权基础。

### 1.2 业务痛点

1. **认证能力缺失：** 当前认证服务仅有骨架，缺少完整的登录/登出、注册、Token 签发与校验流程，业务服务无法接入认证体系
2. **权限控制空白：** 缺少用户-角色-权限（RBAC）模型，无法精细控制用户在平台中各功能模块的访问权限
3. **多租户隔离缺失：** SaaS 平台需要支持多租户数据隔离，当前用户体系缺少租户 ID（tenant_id）设计
4. **多端登录冲突：** 企业用户可能同时在 PC 端（Windows/Ubuntu）、移动端（H5/Android/iOS）和小程序端使用平台，需要支持多端混合登录，同类型端互斥登录
5. **会话管理简单：** 当前仅依赖单一 JWT 令牌（24 小时过期），无法实现主动登出、强制踢人、账号封禁等实时操作
6. **安全风险较高：** 使用 HS256 对称加密算法，密钥泄漏风险较大；缺少 Token 续签机制，用户体验差；缺少登录审计日志，安全事件无法追溯
7. **状态校验缺失：** 无网关层统一的 Token 校验过滤器，每个业务服务需要自行实现认证逻辑，存在安全漏洞和代码冗余

### 1.3 项目目标

1. 实现用户-角色-权限（RBAC）模型，支持多租户隔离
2. 实现多端混合登录（Windows/Ubuntu/H5/Android/iOS/小程序），同类型端互斥登录，不同类型端可共存
3. 实现 JWT + Redis 登录态 + Redis 黑名单的三重管理机制
4. 实现主动登出、强制踢人、账号封禁实时生效
5. 实现双 Token 机制（Access Token 2h + Refresh Token 7d），支持无感续签
6. 升级 JWT 签名算法为 RS256 非对称加密
7. 实现网关层统一 Token 校验过滤器
8. 实现登录日志审计，记录 IP、设备、时间，异常登录触发风控
9. 在 common 模块增加认证相关的错误码

### 1.4 适用范围

本文档适用于 CloudStrollOffice v0.1.5 版本的开发，覆盖登录认证与权限管理系统的全部需求范围，涉及 `cloudoffice-common`、`cloudoffice-gateway`、`cloudoffice-auth-service` 三个模块的修改与扩展。

---

## 2. 总体需求描述

### 2.1 角色定义

| 角色 | 描述 |
|------|------|
| 平台管理员 | 租户级别的超级管理员，拥有租户内所有权限，可管理租户内的用户、角色和权限分配 |
| 租户管理员 | 每个企业租户的管理员，可管理本租户内的用户、角色和权限分配 |
| 普通用户 | 平台业务功能的使用者，被分配特定角色和权限 |
| 系统超级管理员 | 平台级别的超级管理员，可管理所有租户（超管角色，本期仅预留数据模型） |

### 2.2 前端类型定义

| 前端类型标识 | 前端类型 | 说明 |
|-------------|----------|------|
| `WINDOWS` | Windows 桌面端 | Win 原生应用 / Electron 应用 |
| `UBUNTU` | Ubuntu 桌面端 | Linux 原生应用 |
| `H5` | H5 网页端 | 浏览器 Web 端 |
| `ANDROID` | Android 移动端 | Android 原生应用 |
| `IOS` | iOS 移动端 | iOS 原生应用 |
| `WECHAT_MINI` | 微信小程序端 | 微信小程序 |

**互斥规则：** 同类型前端互斥登录（如 Windows 端 A 登录后，Windows 端 B 登录会将 A 踢下线）；不同类型前端可共存（如 Windows 端 + H5 端可同时在线）。

### 2.3 系统上下文

```
┌─────────────────────────────────────────────────────────────────┐
│                       客户端 (多端)                               │
│   Windows / Ubuntu / H5 / Android / iOS / 微信小程序             │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP/HTTPS 请求（携带 Access Token）
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│                    API 网关 (cloudoffice-gateway, 9000)          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  AuthFilter：校验 Access Token → 解析用户信息 → 传递到下游  │ │
│  │  白名单路径放行（登录/注册/刷新 Token/健康检查/Swagger）    │ │
│  │  Token 黑名单校验 → Redis 查询                             │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────────────┘
                           │ 路由转发（携带用户信息 Header）
                           ▼
┌──────────────────────────────────────────────────────────────────┐
│              认证服务 (cloudoffice-auth-service, 9100)          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ 登录/登出    │  │ Token 签发   │  │ 用户/角色/权限管理      │ │
│  │ 注册        │  │ Token 校验   │  │ (RBAC + 多租户)         │ │
│  │ 刷新 Token  │  │ Token 黑名单 │  │ 登录日志审计            │ │
│  └──────┬──────┘  └──────┬───────┘  └───────────┬─────────────┘ │
└─────────┼────────────────┼──────────────────────┼────────────────┘
          │                │                      │
          ▼                ▼                      ▼
┌──────────────────────────────────────────────────────────────────┐
│                      基础设施层                                   │
│  ┌──────────────┐  ┌──────────────────────┐  ┌────────────────┐ │
│  │ MariaDB      │  │ Redis 7.2.x          │  │ Nacos 2.3.x   │ │
│  │ (用户/角色/   │  │ (登录态会话缓存 +    │  │ (注册中心+     │ │
│  │  权限/日志表) │  │  Token黑名单缓存)    │  │  配置中心)     │ │
│  └──────────────┘  └──────────────────────┘  └────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### 2.4 模块定位与职责

| 模块 | 职责 |
|------|------|
| `cloudoffice-common` | 新增认证授权相关错误码（AUTH 错误码段）、增加多端类型枚举、Token 相关 DTO |
| `cloudoffice-gateway` | 实现全局认证过滤器 `AuthFilter`，统一拦截所有请求并校验 Access Token，白名单放行无需认证的路径 |
| `cloudoffice-auth-service` | 完整实现用户管理、角色管理、权限管理、登录认证、Token 签发/刷新/校验/黑名单、登录日志审计等功能 |

### 2.5 认证与授权数据流

```
【登录流程】
Client → POST /api/v1/auth/login → AuthService
  → 校验用户名密码 → 校验租户状态 / 用户状态 / 账号封禁
  → 生成 Access Token (2h) + Refresh Token (7d)
  → 写入 Redis 登录态 (key: login_session:{userId}:{clientType})
  → 记录登录日志
  → 返回 Token 对给客户端

【请求鉴权流程】
Client → Request → Gateway AuthFilter
  → 检查白名单 → 放行或拦截
  → 解析 Access Token → 获取 userId/clientType
  → 校验 Redis 黑名单 → Token 是否被拉黑
  → 校验 Redis 登录态 → 会话是否有效
  → 校验账号状态 → 是否被封禁
  → 通过 → 透传 userId/tenantId/roles 到下游服务 → 业务处理

【Token 续签流程】
Client → POST /api/v1/auth/refresh → AuthService
  → 校验 Refresh Token 有效期和签名
  → 校验 Redis 中 Refresh Token 的黑名单状态
  → 签发新的 Access Token + Refresh Token
  → 旧 Token 加入黑名单
  → 返回新的 Token 对

【登出流程】
Client → POST /api/v1/auth/logout → AuthService
  → 获取当前 Access Token
  → 将 Access Token 加入 Redis 黑名单（TTL = 剩余有效期）
  → 清理 Redis 登录态会话
  → 返回登出成功
```

---

## 3. 功能需求

### 3.1 公共模块增强

#### FR-001: 认证错误码扩展

- **描述：** 在 `cloudoffice-common` 模块的 `ErrorCode` 枚举中增加认证授权相关的错误码，统一认证场景下的异常响应。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 新增以下 AUTH 错误码段（使用 HTTP 状态码，AUTH 前缀仅在注释中标识模块归属）：

     | 错误码 | 枚举名称 | HTTP 状态码 | 描述 |
     |--------|----------|-------------|------|
     | AUTH-1001 | `TOKEN_EXPIRED` | 401 | 令牌已过期，请刷新令牌 |
     | AUTH-1002 | `TOKEN_INVALID` | 401 | 令牌无效 |
     | AUTH-1003 | `TOKEN_BLACKLISTED` | 401 | 令牌已被吊销 |
     | AUTH-1004 | `REFRESH_TOKEN_EXPIRED` | 401 | 刷新令牌已过期，请重新登录 |
     | AUTH-1005 | `REFRESH_TOKEN_INVALID` | 401 | 刷新令牌无效 |
     | AUTH-2001 | `ACCOUNT_DISABLED` | 403 | 账号已被禁用 |
     | AUTH-2002 | `ACCOUNT_LOCKED` | 403 | 账号已被锁定 |
     | AUTH-2003 | `ACCOUNT_BANNED` | 403 | 账号已被封禁 |
     | AUTH-2004 | `ACCOUNT_EXPIRED` | 403 | 账号已过期 |
     | AUTH-3001 | `LOGIN_FAILED` | 401 | 用户名或密码错误 |
     | AUTH-3002 | `CAPTCHA_ERROR` | 400 | 验证码错误 |
     | AUTH-3003 | `CLIENT_TYPE_INVALID` | 400 | 无效的客户端类型 |
     | AUTH-3004 | `SESSION_KICKED_OUT` | 401 | 账号已在其他设备登录，您已被踢下线 |
     | AUTH-4001 | `TENANT_DISABLED` | 403 | 租户已被禁用 |
     | AUTH-4002 | `TENANT_EXPIRED` | 403 | 租户已过期 |
     | AUTH-5001 | `PERMISSION_DENIED` | 403 | 权限不足 |
     | AUTH-5002 | `ROLE_NOT_FOUND` | 404 | 角色不存在 |
     | AUTH-5003 | `USER_NOT_FOUND` | 404 | 用户不存在 |
  2. 错误码枚举实现 `org.cloudstrolling.cloudoffice.common.model.ErrorCode` 接口
  3. 保持与现有 `ErrorCode.java` 枚举相同的代码风格和注释规范。

#### FR-002: 客户端类型枚举

- **描述：** 在 `cloudoffice-common` 模块中定义前端类型枚举 `ClientTypeEnum`，用于标识登录会话的客户端类型。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 枚举位于 `org.cloudstrolling.cloudoffice.common.enums` 包下
  2. 枚举值包含：`WINDOWS`、`UBUNTU`、`H5`、`ANDROID`、`IOS`、`WECHAT_MINI`
  3. 每个枚举值包含字段：`code`（String，如 `"WINDOWS"`）、`label`（String，如 `"Windows 桌面端"`）、`deviceCategory`（设备分类枚举：`PC`、`MOBILE`、`WEB`、`MINI_PROGRAM`）
  4. 提供静态方法 `fromCode(String code)` 根据 code 获取枚举值，找不到时返回 Optional.empty()
  5. 提供 `isSameCategory(ClientTypeEnum other)` 方法判断是否同类型端（互斥登录依据）

#### FR-003: Token DTO

- **描述：** 在 `cloudoffice-common` 模块中定义 Token 相关的数据传输对象。
- **优先级：** 中 (Should)
- **验收标准：**
  1. `TokenPairDTO`：包含 `accessToken`（String）、`refreshToken`（String）、`accessTokenExpiresIn`（Long，毫秒时间戳）、`refreshTokenExpiresIn`（Long，毫秒时间戳）、`tokenType`（String，固定 `"Bearer"`）
  2. `LoginUserDTO`：包含 `userId`（Long）、`tenantId`（Long）、`userName`（String）、`clientType`（String）、`roles`（List&lt;String&gt;）、`permissions`（List&lt;String&gt;）
  3. DTO 位于 `org.cloudstrolling.cloudoffice.common.dto` 包下
  4. 使用 Lombok 注解（`@Data`、`@Builder`、`@NoArgsConstructor`、`@AllArgsConstructor`）
  5. 实现 Serializable 接口

---

### 3.2 网关认证过滤器

#### FR-004: 网关全局认证过滤器

- **描述：** 在 `cloudoffice-gateway` 模块中实现全局认证过滤器 `AuthFilter`，作为请求入口的统一拦截点，校验 Access Token 的有效性，将用户信息透传给下游服务。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 实现 `GlobalFilter` 和 `Ordered` 接口，位于 `org.cloudstrolling.cloudoffice.gateway.filter` 包下
  2. 配置白名单路径，以下路径放行不做 Token 校验：
     - `POST /api/v1/auth/login` — 登录
     - `POST /api/v1/auth/register` — 注册
     - `POST /api/v1/auth/refresh` — 刷新 Token
     - `GET /api/v1/auth/health` — 健康检查
     - `/swagger-ui/**`、`/v3/api-docs/**` — Swagger 文档
     - `/favicon.ico` — 浏览器图标
  3. 非白名单路径的请求，提取 `Authorization: Bearer <accessToken>` 头
  4. 校验逻辑：
     - 解析 Access Token（RS256 验签）
     - 校验 Token 是否在 Redis 黑名单中
     - 校验 Redis 登录态会话是否有效
     - 校验账号状态（是否封禁/禁用）
     - 校验租户状态（是否禁用/过期）
  5. 校验通过后，将解析出的 `LoginUserDTO` 信息写入请求 Header 透传给下游服务：
     - `X-User-Id`：用户 ID
     - `X-Tenant-Id`：租户 ID
     - `X-User-Name`：用户名
     - `X-Client-Type`：客户端类型
     - `X-Roles`：角色列表（逗号分隔）
     - `X-Permissions`：权限标识列表（逗号分隔）
  6. 校验失败时，返回统一的 JSON 错误响应（`ApiResult` 格式），HTTP 状态码对应错误类型
  7. 过滤器优先级设置为 `Ordered.HIGHEST_PRECEDENCE + 10`
  8. 白名单路径配置支持通过配置文件（application.yml）动态配置，不硬编码
  9. 过滤器通过 `@Component` 注册为 Spring Bean

#### FR-005: 网关 Redis 集成

- **描述：** 在 `cloudoffice-gateway` 模块中集成 Spring Data Redis，用于 Token 黑名单校验和登录态校验。
- **优先级：** 高 (Must)
- **验收标准：**
  1. pom.xml 新增依赖：`spring-boot-starter-data-redis`、`commons-pool2`
  2. `application.yml` 中配置 Redis 连接信息（支持环境变量覆盖：`REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD`、`REDIS_DATABASE`）
  3. 提供 `RedisTemplate<String, Object>` 的 Bean 配置
  4. Redis Key 前缀统一管理：
     - 黑名单 Token Key：`auth:token:blacklist:{tokenSignature}`
     - 登录态 Session Key：`auth:session:{userId}:{clientType}`
     - 账号状态 Key：`auth:account:status:{userId}`
     - 租户状态 Key：`auth:tenant:status:{tenantId}`

---

### 3.3 认证服务 - 用户与租户管理

#### FR-006: 多租户用户表结构

- **描述：** 在认证服务数据库中创建用户表（`t_auth_user`），支持多租户隔离。用户属于某个租户，用户名在租户内唯一。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_user`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构包含以下字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `tenant_id` | BIGINT(20) | 租户 ID，NOT NULL |
     | `login_name` | VARCHAR(64) | 登录名，NOT NULL，在租户内唯一 |
     | `password` | VARCHAR(256) | BCrypt 加密密码，NOT NULL |
     | `real_name` | VARCHAR(64) | 真实姓名 |
     | `phone` | VARCHAR(20) | 手机号 |
     | `email` | VARCHAR(128) | 邮箱 |
     | `avatar` | VARCHAR(512) | 头像 URL |
     | `status` | TINYINT(4) | 状态：0-正常，1-禁用，2-锁定，3-封禁，NOT NULL，默认 0 |
     | `account_expire_time` | DATETIME | 账号过期时间，NULL 表示永不过期 |
     | `lock_reason` | VARCHAR(256) | 锁定/封禁原因 |
     | `last_login_time` | DATETIME | 最后登录时间 |
     | `last_login_ip` | VARCHAR(64) | 最后登录 IP |
     | `create_time` | DATETIME | 创建时间（继承 BaseEntity） |
     | `update_time` | DATETIME | 更新时间（继承 BaseEntity） |
     | `deleted` | TINYINT(4) | 逻辑删除，0-正常，1-删除（继承 BaseEntity） |
  3. 唯一索引：`uk_tenant_login_name`（`tenant_id` + `login_name`）
  4. 普通索引：`idx_tenant_status`（`tenant_id` + `status`）、`idx_phone`（`phone`）
  5. Entity 类 `UserEntity` 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包

#### FR-007: 租户表结构

- **描述：** 创建租户表（`t_auth_tenant`），管理 SaaS 平台的企业租户信息。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_tenant`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构包含以下字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `tenant_name` | VARCHAR(128) | 租户名称，NOT NULL |
     | `tenant_code` | VARCHAR(64) | 租户编码，唯一，NOT NULL |
     | `contact_name` | VARCHAR(64) | 联系人姓名 |
     | `contact_phone` | VARCHAR(20) | 联系电话 |
     | `contact_email` | VARCHAR(128) | 联系邮箱 |
     | `status` | TINYINT(4) | 状态：0-正常，1-禁用，2-过期，NOT NULL，默认 0 |
     | `expire_time` | DATETIME | 租户到期时间，NULL 表示永不过期 |
     | `max_user_count` | INT(11) | 最大用户数，0 表示不限制 |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 唯一索引：`uk_tenant_code`（`tenant_code`）
  4. Entity 类 `TenantEntity` 位于 `org.cloudstrolling.cloudoffice.auth.entity` 包

#### FR-008: 账号注册

- **描述：** 用户注册接口，支持租户管理员创建本租户下的用户账号。
- **优先级：** 中 (Should)
- **验收标准：**
  1. API：`POST /api/v1/auth/register`
  2. 请求参数：`loginName`（登录名）、`password`（密码）、`realName`（真实姓名，可选）、`phone`（手机号，可选）、`email`（邮箱，可选）
  3. 密码使用 BCrypt 加密存储
  4. 登录名在校验时检查租户内唯一性
  5. 创建成功后返回用户基本信息（不含密码）
  6. 注册时自动分配默认角色
  7. 校验规则：
     - 登录名长度 4~64 字符，支持字母、数字、下划线
     - 密码长度 8~64 字符，必须包含字母和数字
     - 手机号格式校验
     - 邮箱格式校验

---

### 3.4 认证服务 - 角色与权限管理

#### FR-009: 角色表结构

- **描述：** 创建角色表（`t_auth_role`），支持多租户隔离的角色定义。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_role`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构包含以下字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `tenant_id` | BIGINT(20) | 租户 ID，NOT NULL |
     | `role_name` | VARCHAR(64) | 角色名称，NOT NULL |
     | `role_code` | VARCHAR(64) | 角色编码（如 `admin`、`user`），在租户内唯一，NOT NULL |
     | `description` | VARCHAR(256) | 角色描述 |
     | `status` | TINYINT(4) | 状态：0-正常，1-禁用，NOT NULL，默认 0 |
     | `sort_order` | INT(11) | 排序号 |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 唯一索引：`uk_tenant_role_code`（`tenant_id` + `role_code`）

#### FR-010: 权限表结构

- **描述：** 创建权限表（`t_auth_permission`），定义系统中所有可操作的权限点。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_permission`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构包含以下字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `parent_id` | BIGINT(20) | 父权限 ID，0 表示顶级权限 |
     | `perm_name` | VARCHAR(64) | 权限名称（如「用户管理」），NOT NULL |
     | `perm_code` | VARCHAR(128) | 权限标识（如 `system:user:list`），唯一，NOT NULL |
     | `perm_type` | TINYINT(4) | 类型：1-菜单，2-按钮，3-API |
     | `path` | VARCHAR(256) | 菜单/API 路径 |
     | `method` | VARCHAR(16) | HTTP 方法（API 类型时有效） |
     | `sort_order` | INT(11) | 排序号 |
     | `status` | TINYINT(4) | 状态：0-正常，1-禁用，NOT NULL，默认 0 |
     | `remark` | VARCHAR(256) | 备注 |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 唯一索引：`uk_perm_code`（`perm_code`）

#### FR-011: 用户-角色关联表

- **描述：** 创建用户-角色关联表（`t_auth_user_role`），建立用户与角色的多对多关系。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_user_role`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构包含以下字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `user_id` | BIGINT(20) | 用户 ID，NOT NULL |
     | `role_id` | BIGINT(20) | 角色 ID，NOT NULL |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 联合唯一索引：`uk_user_role`（`user_id` + `role_id`）
  4. 普通索引：`idx_user_id`（`user_id`）、`idx_role_id`（`role_id`）

#### FR-012: 角色-权限关联表

- **描述：** 创建角色-权限关联表（`t_auth_role_permission`），建立角色与权限的多对多关系。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 表名：`t_auth_role_permission`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构包含以下字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `role_id` | BIGINT(20) | 角色 ID，NOT NULL |
     | `permission_id` | BIGINT(20) | 权限 ID，NOT NULL |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 联合唯一索引：`uk_role_permission`（`role_id` + `permission_id`）
  4. 普通索引：`idx_role_id`（`role_id`）、`idx_permission_id`（`permission_id`）

#### FR-013: 用户-角色-权限管理 API

- **描述：** 提供用户、角色、权限的 CRUD 管理接口，支持租户管理员进行授权管理。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **用户管理 API：**
     - `GET /api/v1/auth/users` — 用户列表（分页，支持租户内查询）
     - `GET /api/v1/auth/users/{userId}` — 用户详情（含角色信息）
     - `PUT /api/v1/auth/users/{userId}` — 修改用户信息
     - `PUT /api/v1/auth/users/{userId}/status` — 修改用户状态（启用/禁用/封禁）
     - `PUT /api/v1/auth/users/{userId}/roles` — 分配用户角色
     - `DELETE /api/v1/auth/users/{userId}` — 删除用户（逻辑删除）
  2. **角色管理 API：**
     - `GET /api/v1/auth/roles` — 角色列表（支持租户内查询）
     - `POST /api/v1/auth/roles` — 创建角色
     - `PUT /api/v1/auth/roles/{roleId}` — 修改角色
     - `PUT /api/v1/auth/roles/{roleId}/permissions` — 分配角色权限
     - `DELETE /api/v1/auth/roles/{roleId}` — 删除角色
  3. **权限管理 API：**
     - `GET /api/v1/auth/permissions` — 权限列表（树形结构）
     - `POST /api/v1/auth/permissions` — 创建权限
     - `PUT /api/v1/auth/permissions/{permId}` — 修改权限
     - `DELETE /api/v1/auth/permissions/{permId}` — 删除权限
  4. 所有管理接口需校验当前用户的操作权限
  5. 管理接口返回统一格式的 `ApiResult`

---

### 3.5 认证服务 - 登录认证

#### FR-014: 用户名密码登录

- **描述：** 实现用户名密码登录接口，支持多端混合登录，采用双 Token 机制返回令牌。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`POST /api/v1/auth/login`
  2. 请求参数：`loginName`（登录名）、`password`（密码）、`clientType`（客户端类型）、`tenantCode`（租户编码）
  3. 登录校验流程：
     - 根据 `tenantCode` 查找租户 → 校验租户状态（是否禁用/过期）
     - 根据 `loginName` + `tenantId` 查找用户 → 校验用户状态（是否禁用/锁定/封禁）
     - 校验密码（BCrypt 匹配）
     - 更新最后登录时间和 IP
  4. **多端互斥逻辑：**
     - 查询 Redis 中 `auth:session:{userId}:{clientType}` 是否存在
     - 如果存在（同类型端已登录），将旧会话标记为踢下线（旧 Token 加入黑名单，发送踢下线通知）
     - 创建新的 Redis 登录态会话
  5. **Token 签发：**
     - 生成 Access Token（有效期 2 小时，携带 userId、tenantId、clientType、roles、permissions 等声明）
     - 生成 Refresh Token（有效期 7 天）
     - 写入 Redis 登录态：`auth:session:{userId}:{clientType}` → `{"accessToken": "...", "refreshToken": "...", "loginTime": "...", "ip": "...", "deviceInfo": "..."}`
     - 设置 Redis 过期时间 = 7 天（与 Refresh Token 一致）
  6. 返回 `TokenPairDTO` 给客户端
  7. **登录日志：** 记录本次登录的 user_id、tenant_id、login_ip、client_type、login_time、login_status（成功/失败）

#### FR-015: Token 刷新

- **描述：** 通过 Refresh Token 获取新的 Access Token 和 Refresh Token，实现无感续签。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`POST /api/v1/auth/refresh`
  2. 请求参数：`refreshToken`（刷新令牌）
  3. 校验流程：
     - 解析 Refresh Token（RS256 验签）
     - 校验 Refresh Token 是否在 Redis 黑名单中
     - 校验 Redis 登录态会话是否存在
     - 校验用户状态
     - 校验租户状态
  4. 签发新的 Access Token（2h） + Refresh Token（7d）
  5. 旧 Refresh Token 加入 Redis 黑名单（TTL = 剩余有效期）
  6. 清理旧 Redis 登录态，写入新的登录态
  7. 返回新的 `TokenPairDTO`
  8. Refresh Token 过期后必须重新登录

#### FR-016: 用户登出

- **描述：** 用户主动登出，清理当前会话。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`POST /api/v1/auth/logout`
  2. 请求头携带 `Authorization: Bearer <accessToken>`
  3. 获取当前用户的 Access Token，将其加入 Redis 黑名单（TTL = Token 剩余有效期）
  4. 删除 Redis 中对应的登录态会话：`auth:session:{userId}:{clientType}`
  5. 返回登出成功

#### FR-017: 强制踢人

- **描述：** 管理员强制将指定用户的某个端踢下线。
- **优先级：** 中 (Should)
- **验收标准：**
  1. API：`POST /api/v1/auth/kickout`
  2. 请求参数：`userId`（目标用户 ID）、`clientType`（目标客户端类型，为空则踢下线所有端）
  3. 权限校验：仅租户管理员或平台管理员可执行
  4. 将目标用户的指定端会话 Token 加入 Redis 黑名单
  5. 删除 Redis 登录态会话
  6. 返回操作成功
  7. 被踢用户的该端口的下一次请求将被网关拦截（403 且提示已被踢下线）

#### FR-018: 账号封禁/解封

- **描述：** 管理员封禁或解封用户账号，封禁后所有端实时下线。
- **优先级：** 中 (Should)
- **验收标准：**
  1. 通过 `PUT /api/v1/auth/users/{userId}/status` 接口实现
  2. 将用户状态设置为 `3-封禁` 时：
     - 更新数据库用户状态
     - 更新 Redis 账号状态缓存：`auth:account:status:{userId}`
     - 查询该用户所有 Redis 登录态会话，将关联 Token 加入黑名单
     - 删除所有 Redis 登录态会话
  3. 解封时（status 设为 0-正常）：
     - 更新数据库用户状态
     - 删除 Redis 账号状态缓存
  4. 封禁/解封实时生效（网关过滤器每次请求都校验账号状态缓存）

---

### 3.6 认证服务 - JWT 密钥与 Token 管理

#### FR-019: RS256 非对称密钥管理

- **描述：** 将 JWT 签名算法从 HS256 对称加密升级为 RS256 非对称加密，认证服务持有私钥签发 Token，网关和业务服务持有公钥验签。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 使用 RSA 2048 位密钥对（RS256 算法）
  2. **私钥用途：** 认证服务签发 Access Token 和 Refresh Token
  3. **公钥用途：** 网关过滤器校验 Token 签名
  4. 密钥加载方式：
     - 支持从配置（`application.yml`）中读取 Base64 编码的私钥/公钥
     - 支持从文件系统加载 PEM 格式密钥文件
     - 支持通过环境变量注入
  5. 配置项：
     - `jwt.rsa.private-key`：Base64 编码的私钥（auth-service 使用）
     - `jwt.rsa.public-key`：Base64 编码的公钥（gateway 使用，auth-service 也需要用于解析 Refresh Token）
  6. 启动时校验密钥有效性，密钥无效则拒绝启动
  7. **兼容性：** 保留对 HS256 的兼容处理（v0.1.5 过渡期后可移除）

#### FR-020: JwtUtils 重构

- **描述：** 重构现有 `JwtUtils` 工具类，支持双 Token 机制和 RS256 非对称算法。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 支持两种 Token 类型：`AccessToken` 和 `RefreshToken`
  2. **Access Token 声明：**
     - `sub`：用户 ID
     - `tenantId`：租户 ID
     - `clientType`：客户端类型
     - `tokenType`：固定 `"access"`
     - `roles`：角色编码列表
     - `permissions`：权限标识列表
     - `iat`：签发时间
     - `exp`：过期时间（当前时间 + 2 小时）
  3. **Refresh Token 声明：**
     - `sub`：用户 ID
     - `tenantId`：租户 ID
     - `clientType`：客户端类型
     - `tokenType`：固定 `"refresh"`
     - `iat`：签发时间
     - `exp`：过期时间（当前时间 + 7 天）
     - `tokenVersion`：令牌版本号（用于黑名单校验）
  4. 方法定义：
     - `generateAccessToken(LoginUserDTO user)` → String
     - `generateRefreshToken(LoginUserDTO user)` → String
     - `parseAccessToken(String token)` → Claims（校验签名和 tokenType）
     - `parseRefreshToken(String token)` → Claims（校验签名和 tokenType）
     - `validateToken(String token)` → boolean
     - `getTokenSignature(String token)` → String（Token 签名指纹，用于黑名单 Key）
  5. 升级为 `@Service` 注解，支持构造器注入

#### FR-021: Redis 登录态管理

- **描述：** 在认证服务中实现 Redis 登录态会话的写入、查询和清理管理。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **Key 设计：**
     - 登录态 Session：`auth:session:{userId}:{clientType}`（String 类型）
     - Token 黑名单：`auth:token:blacklist:{tokenSignature}`（String 类型，值为 token_type，TTL = Token 剩余有效期）
     - 账号状态缓存：`auth:account:status:{userId}`（String 类型，值为 status 数字）
     - 租户状态缓存：`auth:tenant:status:{tenantId}`（String 类型，值为 status 数字）
  2. 登录时写入 Session，设置 TTL = 7 天（与 Refresh Token 一致）
  3. 登出时将 Token 加入黑名单，TTL = Token 剩余有效期
  4. 封禁时同时更新账号状态缓存和清理所有 Session
  5. 刷新 Token 时旧 Refresh Token 加入黑名单
  6. 提供 `LoginSessionService` 封装所有 Redis 操作

#### FR-022: 登录日志审计

- **描述：** 记录每次登录认证的详细信息，用于安全审计和异常行为分析。
- **优先级：** 中 (Should)
- **验收标准：**
  1. 表名：`t_auth_login_log`，位于 `cloudstroll_office_auth` 数据库
  2. 表结构包含以下字段：

     | 字段名 | 类型 | 说明 |
     |--------|------|------|
     | `id` | BIGINT(20) | 主键，雪花算法 |
     | `tenant_id` | BIGINT(20) | 租户 ID |
     | `user_id` | BIGINT(20) | 用户 ID |
     | `login_name` | VARCHAR(64) | 登录名 |
     | `login_ip` | VARCHAR(64) | 登录 IP |
     | `login_location` | VARCHAR(128) | 登录地点（IP 解析，可选） |
     | `client_type` | VARCHAR(32) | 客户端类型 |
     | `device_info` | VARCHAR(256) | 设备信息（User-Agent 等） |
     | `login_time` | DATETIME | 登录时间 |
     | `logout_time` | DATETIME | 登出时间（登出时更新） |
     | `login_status` | TINYINT(4) | 登录状态：0-失败，1-成功，2-登出 |
     | `fail_reason` | VARCHAR(256) | 失败原因 |
     | `create_time` | DATETIME | 创建时间 |
     | `update_time` | DATETIME | 更新时间 |
     | `deleted` | TINYINT(4) | 逻辑删除 |
  3. 普通索引：`idx_user_id`（`user_id`）、`idx_tenant_id`（`tenant_id`）、`idx_login_time`（`login_time`）
  4. 登录成功后同步写入登录日志
  5. 登录失败时记录失败原因
  6. 登出时更新 `logout_time`
  7. **异常风控规则（预留扩展点）：**
     - 同 IP 短时间内多次登录失败 → 记录可疑日志
     - 非常用地点登录 → 记录可疑日志
     - 非常用设备登录 → 记录可疑日志
     - （具体风控策略本期仅预留扩展点，不实现自动阻断）

---

### 3.7 认证服务 - 认证服务配置

#### FR-023: 认证服务数据库与缓存集成

- **描述：** 在 `cloudoffice-auth-service` 模块中集成 MariaDB 数据库和 Redis 缓存。
- **优先级：** 高 (Must)
- **验收标准：**
  1. pom.xml 新增依赖：
     - `mybatis-plus-spring-boot3-starter`（MyBatis-Plus）
     - `mariadb-java-client`（MariaDB 驱动）
     - `spring-boot-starter-data-redis`（Redis）
     - `commons-pool2`（连接池）
  2. `application.yml` 配置 MariaDB 数据源：
     - `spring.datasource.url`：`jdbc:mariadb://${DB_HOST:127.0.0.1}:${DB_PORT:3306}/cloudstroll_office_auth?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai`
     - `spring.datasource.username`：`${DB_USER:root}`
     - `spring.datasource.password`：`${DB_PASSWORD:root}`
     - `spring.datasource.driver-class-name`：`org.mariadb.jdbc.Driver`
  3. `application.yml` 配置 Redis：
     - `spring.data.redis.host`：`${REDIS_HOST:127.0.0.1}`
     - `spring.data.redis.port`：`${REDIS_PORT:6379}`
     - `spring.data.redis.password`：`${REDIS_PASSWORD:}`
     - `spring.data.redis.database`：`${REDIS_DATABASE:0}`
     - `spring.data.redis.lettuce.pool.max-active`：`16`
     - `spring.data.redis.lettuce.pool.min-idle`：`4`
  4. MyBatis-Plus 配置（同 biz-service/system-service 保持一致）

---

### 3.8 依赖版本管理

#### FR-024: 父 POM 依赖补充

- **描述：** 在父 POM 中补充 `spring-boot-starter-data-redis` 的依赖版本声明。
- **优先级：** 高 (Must)
- **验收标准：**
  1. `spring-boot-starter-data-redis` 和 `commons-pool2` 通过 Spring Boot Parent BOM 继承，无需额外声明版本号
  2. 确认父 POM 已有的依赖管理可满足本次开发所需的所有依赖

---

## 4. 非功能需求

### NFR-001: 安全性

- **描述：** 登录认证系统必须满足企业级安全要求，防止常见 Web 安全攻击。
- **指标：**
  1. 密码存储使用 BCrypt 加密算法（强度系数 ≥ 10）
  2. JWT 签名使用 RS256 非对称加密，私钥安全存储
  3. Access Token 有效期 2 小时，Refresh Token 有效期 7 天
  4. 敏感信息（密码、Token）不在日志中明文输出
  5. Token 黑名单实时生效，无需等待 Token 自然过期
  6. 密码传输建议使用 HTTPS（非本期强制，但需预留支持）

### NFR-002: 性能

- **描述：** 认证和鉴权操作应具备高性能，不能成为系统瓶颈。
- **指标：**
  1. Token 校验响应时间 ≤ 10ms（在网关层，含 Redis 查询）
  2. 登录接口响应时间 ≤ 500ms（含密码校验和 Token 签发）
  3. 单次登录操作 Redis 读写次数 ≤ 5 次
  4. 网关过滤器不阻塞业务请求处理线程（使用响应式非阻塞方式）

### NFR-003: 可扩展性

- **描述：** 认证授权体系应支持水平扩展和灵活配置。
- **指标：**
  1. 新增客户端类型时无需修改代码，仅需在 `ClientTypeEnum` 中添加枚举值
  2. 支持灵活的权限控制策略（方法级注解 `@PreAuthorize`）
  3. 白名单路径支持配置化（通过 application.yml 配置）
  4. Token 有效期支持配置化（通过 application.yml 配置）

### NFR-004: 可维护性

- **描述：** 认证服务的代码应遵循统一规范，具备良好的可读性和可维护性。
- **指标：**
  1. 遵循 project.md 中定义的标准包结构规范
  2. 使用构造器注入，禁止 `@Autowired` 字段注入
  3. 关键业务逻辑添加详细的行内注释
  4. Redis Key 统一管理（枚举或常量类定义）
  5. 错误码统一管理，业务异常使用对应错误码
  6. 登录日志在关键节点使用 `@Slf4j` 记录

### NFR-005: 可靠性

- **描述：** 认证服务应具备高可用性和容错能力。
- **指标：**
  1. Redis 不可用时认证服务应给出明确的降级/熔断提示
  2. 数据库连接失败时不应泄漏敏感信息
  3. Token 解析失败时返回明确的错误码和提示信息
  4. 登录失败次数不做硬性限制（风控策略后期实现）

### NFR-006: 测试覆盖率

- **描述：** 核心认证功能代码应具备充分的单元测试覆盖。
- **指标：**
  1. 单元测试覆盖率要求：Service 层 ≥ 85%，Controller 层 ≥ 80%，Utils 层 ≥ 90%
  2. 关键测试场景：
     - 登录成功/失败场景
     - Token 签发/解析/校验场景（含过期、签名错误）
     - Token 刷新成功/失败场景
     - 登出清理场景
     - 强制踢人场景
     - 账号封禁/解封场景
     - 多端互斥登录场景
     - 网关过滤器放行/拦截场景
     - Redis 黑名单校验场景

---

## 5. 技术栈选型（补充）

### 5.1 新增/变更依赖

| 组件/依赖 | 版本 | 用途 | 使用模块 |
|-----------|------|------|----------|
| spring-boot-starter-data-redis | 3.2.5 (继承 Boot Parent) | Redis 缓存集成 | auth-service, gateway |
| commons-pool2 | 继承 Boot Parent | Redis 连接池 | auth-service, gateway |

### 5.2 密钥管理

| 配置项 | 说明 | 使用模块 |
|--------|------|----------|
| `jwt.rsa.private-key` | Base64 编码的 RSA 私钥（2048 位） | auth-service |
| `jwt.rsa.public-key` | Base64 编码的 RSA 公钥（2048 位） | auth-service, gateway |
| `jwt.access-token-expiration` | Access Token 过期时间（ms，默认 2h=7200000） | auth-service |
| `jwt.refresh-token-expiration` | Refresh Token 过期时间（ms，默认 7d=604800000） | auth-service |

### 5.3 新增表汇总

| 表名 | 所属数据库 | 说明 |
|------|-----------|------|
| `t_auth_tenant` | `cloudstroll_office_auth` | 租户表 |
| `t_auth_user` | `cloudstroll_office_auth` | 用户表 |
| `t_auth_role` | `cloudstroll_office_auth` | 角色表 |
| `t_auth_permission` | `cloudstroll_office_auth` | 权限表 |
| `t_auth_user_role` | `cloudstroll_office_auth` | 用户-角色关联表 |
| `t_auth_role_permission` | `cloudstroll_office_auth` | 角色-权限关联表 |
| `t_auth_login_log` | `cloudstroll_office_auth` | 登录日志审计表 |

---

## 6. 约束条件

### 6.1 技术约束

1. **JDK 版本：** 必须使用 Java 21 (OpenJDK 21 LTS)，不得使用更低版本
2. **构建工具：** 必须使用 Maven 3.9.x 进行项目构建
3. **注册中心：** 必须集成 Nacos 2.3.x 作为服务注册中心和配置中心
4. **数据库：** 使用 MariaDB 10.6 (LTS)，认证服务数据库名 `cloudstroll_office_auth`
5. **缓存：** 使用 Redis 7.2.x，必须启用持久化（RDB/AOF）
6. **JWT 算法：** 必须使用 RS256 非对称加密，不允许使用 HS256 对称加密（生产环境）
7. **密码加密：** 必须使用 BCrypt，不允许使用 MD5/SHA1 等

### 6.2 架构约束

1. **认证集中：** Token 签发仅由 `cloudoffice-auth-service` 负责，其他服务不得签发 Token
2. **拦截统一：** 请求鉴权在 `cloudoffice-gateway` 完成，业务服务不再重复校验 Token 有效性（业务权限校验除外）
3. **无状态校验：** 网关 Token 校验不依赖认证服务在线，通过公钥本地验签 + Redis 状态校验
4. **用户信息透传：** 网关校验通过后，通过 Request Header 将用户信息传递给下游服务
5. **数据库独立：** 认证服务拥有独立的数据库（`cloudstroll_office_auth`），其他服务禁止直接访问

### 6.3 规范约束

1. **Redis Key 规范：** 统一使用 `auth:{category}:{key}` 命名空间格式
2. **错误码规范：** 新增错误码遵循 `ACTUAL_HTTP_CODE` 命名方式，注释标 `AUTH-XXXX` 模块标识
3. **API 路径规范：** 认证相关 API 路径统一前缀 `/api/v1/auth/`
4. **DTO 规范：** 请求参数使用 `@Valid` + 分组校验，响应统一使用 `ApiResult<T>`

---

## 7. 假设与依赖

### 7.1 外部依赖

1. **Redis 服务：** 开发环境中需要部署并运行 Redis 7.2.x 服务，网关和认证服务均依赖 Redis
2. **Nacos 服务：** 需要部署并运行 Nacos 2.3.x 服务（单机模式可满足开发需求）
3. **MariaDB 服务：** 需要部署并运行 MariaDB 10.6，初始化 `cloudstroll_office_auth` 数据库
4. **cloudoffice-common 公共模块：** 依赖 common 模块提供的 `ApiResult`、`BaseEntity`、`ErrorCode` 等公共组件

### 7.2 环境假设

1. 开发人员本地已安装 JDK 21（OpenJDK 21 LTS）
2. 开发人员本地已安装 Maven 3.9.x，并正确配置 `settings.xml`
3. Redis 默认连接地址 `127.0.0.1:6379`，可通过环境变量 `REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD` 覆盖
4. 数据库连接参数可通过 `DB_HOST`、`DB_PORT`、`DB_USER`、`DB_PASSWORD` 环境变量覆盖
5. 当前已有的 auth-service、gateway、common 模块的代码基础可直接使用

### 7.3 项目假设

1. 本期 v0.1.5 聚焦于后端认证授权功能，前端 UI 界面不在本期范围内
2. 验证码功能（图形验证码/短信验证码）本期做接口预留，具体实现在后续版本完成
3. 风控策略（异地登录检测、暴力破解防护等）本期仅预留数据采集扩展点，不实现自动阻断
4. OAuth2 第三方登录（微信扫码、企业微信等）不在本期范围内
5. Spring Security 方法级权限注解（`@PreAuthorize`）本期进行集成和验证，业务服务的使用在后续版本

---

## 8. 优先级汇总 (MoSCoW)

### 8.1 Must（必须有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-001 | 认证错误码扩展 | common |
| FR-002 | 客户端类型枚举 | common |
| FR-004 | 网关全局认证过滤器 | gateway |
| FR-005 | 网关 Redis 集成 | gateway |
| FR-006 | 多租户用户表结构 | auth-service |
| FR-007 | 租户表结构 | auth-service |
| FR-009 | 角色表结构 | auth-service |
| FR-010 | 权限表结构 | auth-service |
| FR-011 | 用户-角色关联表 | auth-service |
| FR-012 | 角色-权限关联表 | auth-service |
| FR-014 | 用户名密码登录 | auth-service |
| FR-015 | Token 刷新 | auth-service |
| FR-016 | 用户登出 | auth-service |
| FR-019 | RS256 非对称密钥管理 | auth-service |
| FR-020 | JwtUtils 重构 | auth-service |
| FR-021 | Redis 登录态管理 | auth-service |
| FR-023 | 认证服务数据库与缓存集成 | auth-service |
| FR-024 | 父 POM 依赖补充 | 根 POM |

### 8.2 Should（应该有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-003 | Token DTO | common |
| FR-008 | 账号注册 | auth-service |
| FR-013 | 用户-角色-权限管理 API | auth-service |
| FR-017 | 强制踢人 | auth-service |
| FR-018 | 账号封禁/解封 | auth-service |
| FR-022 | 登录日志审计 | auth-service |

### 8.3 Could（可以有）

（本期无 Could 优先级需求）

### 8.4 Won't（本期不做）

| 需求名称 | 说明 |
|----------|------|
| 验证码功能 | 图形验证码/短信验证码接口预留，本期不实现 |
| OAuth2 第三方登录 | 微信扫码、企业微信等，后续版本实现 |
| 风控自动阻断 | 异地登录检测、暴力破解防护等，本期仅预留日志采集 |
| 前端 UI 页面 | 本期纯后端需求，不开发前端界面 |
| 单点登录 (SSO) | 跨系统单点登录，后续版本实现 |

---

## 9. 模块间依赖关系

```
cloudoffice-common (无业务依赖)
       ▲
       │ 依赖
       │
┌──────┴──────────────────────────────────────┐
│                                             │
▼                                             ▼
cloudoffice-gateway           cloudoffice-auth-service
(端口 9000)                    (端口 9100)
├── AuthFilter (全局认证过滤)   ├── 用户/角色/权限 CRUD
├── Redis: Token黑名单校验      ├── 登录/登出/刷新 Token
├── Redis: 登录态校验           ├── RS256 密钥管理
└── Redis: 账号/租户状态校验    ├── Redis: 登录态/黑名单管理
                               ├── MariaDB: 7张认证表
                               └── 登录日志审计
       │                              │
       │                              │
       ▼                              ▼
   Redis 7.2.x               MariaDB 10.6
   (Token黑名单/登录态/       (cloudstroll_office_auth
    账号状态/租户状态)          数据库: 7张认证表)
```

- **common 模块：** 基础依赖，提供错误码、枚举、DTO
- **gateway 模块：** 依赖 common，通过 Redis 进行 Token 校验和状态校验；通过 Nacos 服务发现路由到认证服务
- **auth-service 模块：** 依赖 common，集成 MariaDB（持久化认证数据）和 Redis（缓存登录态和黑名单）
- **biz-service/system-service：** 本期不直接修改，但需要通过 gateway 过滤器的用户信息透传获取当前登录用户

---

## 10. 验收总体标准

1. 所有 Must 优先级需求必须全部完成并通过验收
2. 所有 Should 优先级需求应在资源允许的情况下尽量完成
3. 项目通过 `mvn clean compile -pl cloudoffice-auth-service,cloudoffice-gateway,cloudoffice-common -am` 编译无错误
4. 认证服务可正常启动，监听端口 9100，集成 MariaDB 和 Redis
5. 网关可正常启动，监听端口 9000，集成 Redis Token 校验过滤器
6. 完整的登录-请求-续签-登出流程可正常运行
7. 多端混合登录和同端互斥场景可正常验证
8. 强制踢人和账号封禁实时生效（下次请求即拦截）
9. 所有单元测试通过（`mvn test -pl cloudoffice-auth-service,cloudoffice-gateway,cloudoffice-common`）
10. Redis 和 MariaDB 连接断开时服务有明确提示，不泄漏敏感信息
