# 软件设计规格说明书（SDS）

**项目中文名称：** 云漫智企
**项目英文名：** CloudStrollOffice
**版本号：** v0.1.5
**日期：** 2026-06-22

---

## 1. 技术方案概述

### 1.1 系统定位

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务企业管理平台。v0.1.5 阶段构建了完整的登录认证与权限管理系统，包括 RBAC 多租户权限模型、多端混合登录、JWT + Redis 双重会话管理、双 Token 续签机制和登录日志审计等核心能力，为平台后续业务功能提供安全、可靠、可扩展的认证授权基础。

### 1.2 架构风格

采用 **微服务架构（Microservices Architecture）**，认证集中化架构：

- **认证集中化**：Token 签发仅由 `cloudoffice-auth-service` 负责，请求鉴权在 `cloudoffice-gateway` 的 `AuthFilter` 完成，业务服务通过 Header 透传获取用户信息，无需重复校验 Token
- **无状态 + 有状态混合校验**：网关先做 RS256 公钥本地验签（无状态，毫秒级），再查 Redis 黑名单/登录态/状态缓存（有状态，实时生效）
- **多租户隔离**：所有认证数据按租户 ID 隔离，用户名在租户内唯一
- **多端会话管理**：以「用户 ID + 客户端类型」为维度管理登录会话，同类型端互斥，不同类型端可共存

**架构层次图：**

```
[客户端层] Flutter Desktop / Mobile / Web / 微信小程序 / 第三方 API
     │
     ▼
[API 网关层] Spring Cloud Gateway（端口 9000）
     │  AuthFilter: 白名单放行 → RS256 公钥验签 → Redis 黑名单校验
     │  → 登录态校验 → 账号/租户状态校验 → 透传 Header
     ├─────────────────────────┐
     ▼                         ▼
[认证服务 auth-service]   [企业服务 biz-service]   [系统服务 system-service]
  (端口 9100)               (端口 9200)             (端口 9400)
  RBAC + 双Token          骨架阶段 v0.1.0        骨架阶段 v0.1.4
  多端混合登录
  登录日志审计
     │                         │
     ▼                         ▼
[Redis 7.2.x]          [MariaDB 10.6]
 会话/黑名单/状态缓存      每服务独立数据库
```

### 1.3 核心工作流

**登录流程：**
```
客户端 POST /api/v1/auth/login (loginName, password, tenantCode, clientType)
  → 网关白名单放行
  → auth-service: 校验租户状态 → 校验用户状态 → BCrypt 密码校验
  → 查询用户角色/权限 → 构建 LoginUserDTO
  → RS256 签发 Access Token (2h) + Refresh Token (7d)
  → Redis: 同端互斥清理旧会话 → 写入新登录态 (TTL 7d)
  → MariaDB: 写入登录日志
  → 返回 TokenPairDTO
```

**API 请求校验流程：**
```
客户端请求 (Authorization: Bearer <accessToken>)
  → 网关 AuthFilter:
     1. 白名单校验（白名单路径直接放行）
     2. Bearer Token 格式校验
     3. RS256 公钥验签 → 解析 Claims
     4. Redis 黑名单查询（被吊销?）
     5. Redis 登录态查询（会话有效?）
     6. Redis 账号状态缓存（禁用/封禁?）
     7. Redis 租户状态缓存（禁用/过期?）
     8. 通过 → 透传 X-User-Id / X-Tenant-Id / X-User-Name / X-Client-Type / X-Roles / X-Permissions Header
  → 目标业务服务
```

### 1.4 关键设计原则

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| 认证集中化 | Token 签发与鉴权分离 | auth-service 签发，gateway AuthFilter 校验，业务服务零侵入 |
| 混合校验 | 无状态快速验签 + 有状态增强校验 | RS256 公钥本地验签（无状态），Redis 查询（有状态），兼顾性能与安全 |
| 多租户隔离 | 租户间数据完全隔离 | 用户/角色/权限均按 tenant_id 隔离，唯一索引跨租户隔离 |
| 多端互斥 | 同设备类互斥，不同设备类共存 | ClientTypeEnum.isSameCategory() 决策互斥逻辑，PC/WEB/MOBILE/MINI_PROGRAM 四类 |
| Token 轮换 | Refresh Token 一次性使用 | 每次刷新签发新双 Token，旧 Refresh Token 加入黑名单防重放 |
| 实时吊销 | 登出/踢人/封禁实时生效 | Redis 黑名单 + 登录态删除，网关每次请求校验 |

### 1.5 对应 PRD UserStory 一览

| 编号 | 名称 | 技术方案覆盖章节 |
|------|------|----------------|
| US-001 | 认证错误码扩展 | 第 4.4 节 |
| US-002 | 客户端类型枚举 | 第 2.1 节 |
| US-003 | Token 数据传输对象 | 第 2.1 节 |
| US-004 | 网关全局认证过滤器 | 第 2.2 节 |
| US-005 | 网关 Redis 集成 | 第 2.2 节 |
| US-006 | 多租户用户表结构 | 第 3.2 节 |
| US-007 | 租户表结构 | 第 3.2 节 |
| US-008 | 账号注册 | 第 4.3 节 |
| US-009 | 角色表结构 | 第 3.2 节 |
| US-010 | 权限表结构 | 第 3.2 节 |
| US-011 | 用户-角色关联表 | 第 3.2 节 |
| US-012 | 角色-权限关联表 | 第 3.2 节 |
| US-013 | 用户-角色-权限管理 API | 第 4.3 节 |
| US-014 | 用户名密码登录 | 第 4.3 节 |
| US-015 | Token 刷新 | 第 4.3 节 |
| US-016 | 用户登出 | 第 4.3 节 |
| US-017 | 强制踢人 | 第 4.3 节 |
| US-018 | 账号封禁/解封 | 第 4.3 节 |
| US-019 | RS256 非对称密钥管理 | 第 5.2 节 |
| US-020 | JWT 工具类重构 | 第 2.3 节 |
| US-021 | Redis 登录态管理 | 第 3.4 节 |
| US-022 | 登录日志审计 | 第 3.2 节 |

---

## 2. 模块概要设计

### 2.1 模块清单

| 模块编号 | 模块名称 | 模块类型 | 模块描述 |
|---------|---------|---------|----------|
| module-001 | cloudoffice-common | 公共依赖库 | 通用工具类、统一响应体、异常定义、客户端类型枚举、Token DTO、Redis Key 常量 |
| module-002 | cloudoffice-gateway | API 网关 | 请求路由转发、CORS、AuthFilter 全局认证过滤器、Redis 集成、RSA 公钥加载 |
| module-003 | cloudoffice-auth-service | 认证服务 | RBAC 多租户权限模型、双 Token 登录/刷新/登出、多端混合登录、Redis 会话管理、登录日志审计 |

### 2.2 模块间相互关系

```
                    cloudoffice-common
                    (无业务依赖，公共组件)
                     ▲       ▲       ▲
                     │依赖   │依赖   │依赖
            ┌────────┘       │       └────────┐
            ▼                ▼                 ▼
    cloudoffice-gateway  cloudoffice-auth-service
    (端口 9000)          (端口 9100)
    AuthFilter           RBAC + JWT
    Redis 查询           Redis 写入
            │                │
            │     Redis      │
            └───── 7.2.x ────┘
            │                │
            │    MariaDB     │
            │    10.6        │
            └────────────────┘
            │
            ▼
    cloudoffice-biz-service / cloudoffice-system-service
    (通过 Header 透传获取用户信息)
```

**依赖关系：**
- `cloudoffice-gateway` → `cloudoffice-common`
- `cloudoffice-auth-service` → `cloudoffice-common`
- `cloudoffice-biz-service` → `cloudoffice-common`
- `cloudoffice-system-service` → `cloudoffice-common`

**数据流向：**
- `auth-service` → `Redis`：写入登录态会话、黑名单、账号/租户状态缓存
- `gateway` → `Redis`：读取黑名单、登录态、账号/租户状态缓存
- `auth-service` → `MariaDB`：读写用户/角色/权限/租户/登录日志数据
- `gateway` → `auth-service`：路由转发认证相关请求

### 2.3 cloudoffice-common 公共模块（v0.1.5 新增）

| 类名 | 包路径 | 功能描述 |
|------|--------|---------|
| `ErrorCode`（扩展） | `.*.common.exception` | 新增 19 个认证授权错误码（TOKEN_EXPIRED/TOKEN_INVALID/TOKEN_BLACKLISTED/REFRESH_TOKEN_EXPIRED/REFRESH_TOKEN_INVALID/ACCOUNT_DISABLED/ACCOUNT_LOCKED/ACCOUNT_BANNED/ACCOUNT_EXPIRED/LOGIN_FAILED/CAPTCHA_ERROR/CLIENT_TYPE_INVALID/SESSION_KICKED_OUT/TENANT_DISABLED/TENANT_EXPIRED/PERMISSION_DENIED/ROLE_NOT_FOUND/USER_NOT_FOUND） |
| `ClientTypeEnum` | `.*.common.enums` | 6种客户端类型枚举（WINDOWS/UBUNTU/H5/ANDROID/IOS/WECHAT_MINI），含设备分类（PC/WEB/MOBILE/MINI_PROGRAM），`fromCode(String)` 工厂方法，`isSameCategory()` 互斥判断 |
| `TokenPairDTO` | `.*.common.dto` | 双 Token 响应 DTO：accessToken/refreshToken/accessTokenExpiresIn/refreshTokenExpiresIn/tokenType |
| `LoginUserDTO` | `.*.common.dto` | 登录用户信息 DTO：userId/tenantId/userName/clientType/roles/permissions |
| `RedisKeyConstants` | `.*.common.constant` | Redis Key 前缀常量管理类，统一管理 `auth:session:`、`auth:token:blacklist:`、`auth:account:status:`、`auth:tenant:status:` |

### 2.4 cloudoffice-gateway API 网关（v0.1.5 新增）

| 组件 | 功能描述 |
|------|---------|
| `AuthFilter` | 全局认证过滤器，实现 `GlobalFilter` + `Ordered`，优先级 `HIGHEST_PRECEDENCE + 10`。白名单放行 → RS256 公钥验签 → Token 黑名单查询 → 登录态查询 → 账号状态查询 → 租户状态查询 → 透传 Header |
| `ReactiveRedisTemplate` Bean | 响应式 Redis 客户端，用于非阻塞查询 |
| `RsaKeyConfig` | RSA 公钥加载配置，支持环境变量/配置文件 Base64/PEM 文件三种加载方式 |
| `application.yml` | 新增 `auth.white-list` 白名单配置、`spring.data.redis.*` 配置、`jwt.rsa.public-key` 配置 |

**白名单路径**（通过 `auth.white-list` 配置）：
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/auth/health`
- `/swagger-ui/**`
- `/v3/api-docs/**`
- `/favicon.ico`

### 2.5 cloudoffice-auth-service 认证服务（v0.1.5 完整实现）

| 组件 | 功能描述 |
|------|---------|
| `AuthController` | 登录/注册/刷新/登出/踢人接口 |
| `UserController` | 用户管理 CRUD、状态变更、角色分配 |
| `RoleController` | 角色管理 CRUD、权限分配 |
| `PermissionController` | 权限管理 CRUD、树形查询 |
| `LoginService` | 登录/登出业务（BCrypt 校验、双 Token 签发、同端互斥、日志记录） |
| `TokenService` | Token 刷新业务（RS256 校验、轮换、黑名单处理） |
| `UserService` | 用户管理业务（CRUD、封禁/解封、角色分配） |
| `RoleService` | 角色管理业务 |
| `PermissionService` | 权限管理业务 |
| `LoginSessionService` | Redis 登录态管理（会话 CRUD、黑名单管理、批量清理） |
| `LoginLogService` | 登录日志审计业务 |
| `JwtUtils` | **重构**：HS256 → RS256，支持 Access/Refresh 双 Token 签发、解析、签名指纹提取 |
| `RsaKeyConfig` | RSA 密钥对加载与校验（含私钥+公钥） |

---

## 3. 数据设计

### 3.1 数据库概述

- **数据库名**：`cloudstroll_office_auth`
- **类型**：MariaDB 10.6 LTS
- **ORM**：MyBatis-Plus 3.5.x
- **总表数**：v0.1.5 新增 7 张表

### 3.2 表结构设计

#### 3.2.1 t_auth_tenant（租户表）

**说明**：存储 SaaS 平台企业租户信息，支持租户状态控制和用户数限制。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | 雪花算法 | 主键 |
| tenant_name | VARCHAR(128) | NOT NULL | | 租户名称 |
| tenant_code | VARCHAR(64) | NOT NULL | | 租户编码（唯一标识） |
| contact_name | VARCHAR(64) | | | 联系人姓名 |
| contact_phone | VARCHAR(20) | | | 联系电话 |
| contact_email | VARCHAR(128) | | | 联系邮箱 |
| status | TINYINT(4) | NOT NULL | 0 | 0-正常，1-禁用，2-过期 |
| expire_time | DATETIME | | NULL | 到期时间（NULL 永不过期） |
| max_user_count | INT(11) | | 0 | 最大用户数（0 不限制） |
| create_time | DATETIME | NOT NULL | | 创建时间 |
| update_time | DATETIME | NOT NULL | | 更新时间 |
| deleted | TINYINT(4) | | 0 | 逻辑删除 |

**索引：**
| 索引名 | 类型 | 字段 | 唯一 |
|--------|------|------|------|
| uk_tenant_code | BTREE | tenant_code | 是 |

#### 3.2.2 t_auth_user（用户表）

**说明**：存储平台用户账号信息，多租户隔离，用户名在租户内唯一。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | 雪花算法 | 主键 |
| tenant_id | BIGINT(20) | NOT NULL | | 租户 ID |
| login_name | VARCHAR(64) | NOT NULL | | 登录名 |
| password | VARCHAR(256) | NOT NULL | | BCrypt 加密密码 |
| real_name | VARCHAR(64) | | | 真实姓名 |
| phone | VARCHAR(20) | | | 手机号 |
| email | VARCHAR(128) | | | 邮箱 |
| avatar | VARCHAR(512) | | | 头像 URL |
| status | TINYINT(4) | NOT NULL | 0 | 0-正常，1-禁用，2-锁定，3-封禁 |
| account_expire_time | DATETIME | | NULL | 账号过期时间（NULL 永不过期） |
| lock_reason | VARCHAR(256) | | | 锁定/封禁原因 |
| last_login_time | DATETIME | | | 最后登录时间 |
| last_login_ip | VARCHAR(64) | | | 最后登录 IP |
| create_time | DATETIME | NOT NULL | | 创建时间 |
| update_time | DATETIME | NOT NULL | | 更新时间 |
| deleted | TINYINT(4) | | 0 | 逻辑删除 |

**索引：**
| 索引名 | 类型 | 字段 | 唯一 |
|--------|------|------|------|
| uk_tenant_login_name | BTREE | tenant_id, login_name | 是 |
| idx_tenant_status | BTREE | tenant_id, status | 否 |
| idx_phone | BTREE | phone | 否 |

#### 3.2.3 t_auth_role（角色表）

**说明**：角色定义，租户内隔离。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | 雪花算法 | 主键 |
| tenant_id | BIGINT(20) | NOT NULL | | 租户 ID |
| role_name | VARCHAR(64) | NOT NULL | | 角色名称 |
| role_code | VARCHAR(64) | NOT NULL | | 角色编码（如 admin） |
| description | VARCHAR(256) | | | 角色描述 |
| status | TINYINT(4) | NOT NULL | 0 | 0-正常，1-禁用 |
| sort_order | INT(11) | | | 排序号 |
| create_time | DATETIME | NOT NULL | | 创建时间 |
| update_time | DATETIME | NOT NULL | | 更新时间 |
| deleted | TINYINT(4) | | 0 | 逻辑删除 |

**索引：**
| 索引名 | 类型 | 字段 | 唯一 |
|--------|------|------|------|
| uk_tenant_role_code | BTREE | tenant_id, role_code | 是 |

#### 3.2.4 t_auth_permission（权限表）

**说明**：权限点定义，支持树形结构组织菜单、按钮和 API 权限。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | 雪花算法 | 主键 |
| parent_id | BIGINT(20) | | 0 | 父权限 ID（0 表示顶级） |
| perm_name | VARCHAR(64) | NOT NULL | | 权限名称 |
| perm_code | VARCHAR(128) | NOT NULL | | 权限标识（如 system:user:list） |
| perm_type | TINYINT(4) | | | 1-菜单，2-按钮，3-API |
| path | VARCHAR(256) | | | 菜单/API 路径 |
| method | VARCHAR(16) | | | HTTP 方法（API 类型时有效） |
| sort_order | INT(11) | | | 排序号 |
| status | TINYINT(4) | NOT NULL | 0 | 0-正常，1-禁用 |
| remark | VARCHAR(256) | | | 备注 |
| create_time | DATETIME | NOT NULL | | 创建时间 |
| update_time | DATETIME | NOT NULL | | 更新时间 |
| deleted | TINYINT(4) | | 0 | 逻辑删除 |

**索引：**
| 索引名 | 类型 | 字段 | 唯一 |
|--------|------|------|------|
| uk_perm_code | BTREE | perm_code | 是 |

#### 3.2.5 t_auth_user_role（用户-角色关联表）

**说明**：用户与角色的多对多关联。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | 雪花算法 | 主键 |
| user_id | BIGINT(20) | NOT NULL | | 用户 ID |
| role_id | BIGINT(20) | NOT NULL | | 角色 ID |
| create_time | DATETIME | NOT NULL | | 创建时间 |
| update_time | DATETIME | NOT NULL | | 更新时间 |
| deleted | TINYINT(4) | | 0 | 逻辑删除 |

**索引：**
| 索引名 | 类型 | 字段 | 唯一 |
|--------|------|------|------|
| uk_user_role | BTREE | user_id, role_id | 是 |
| idx_user_id | BTREE | user_id | 否 |
| idx_role_id | BTREE | role_id | 否 |

#### 3.2.6 t_auth_role_permission（角色-权限关联表）

**说明**：角色与权限的多对多关联。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | 雪花算法 | 主键 |
| role_id | BIGINT(20) | NOT NULL | | 角色 ID |
| permission_id | BIGINT(20) | NOT NULL | | 权限 ID |
| create_time | DATETIME | NOT NULL | | 创建时间 |
| update_time | DATETIME | NOT NULL | | 更新时间 |
| deleted | TINYINT(4) | | 0 | 逻辑删除 |

**索引：**
| 索引名 | 类型 | 字段 | 唯一 |
|--------|------|------|------|
| uk_role_permission | BTREE | role_id, permission_id | 是 |
| idx_role_id | BTREE | role_id | 否 |
| idx_permission_id | BTREE | permission_id | 否 |

#### 3.2.7 t_auth_login_log（登录日志表）

**说明**：记录用户登录认证的详细信息，用于安全审计。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK | 雪花算法 | 主键 |
| tenant_id | BIGINT(20) | NOT NULL | | 租户 ID |
| user_id | BIGINT(20) | | | 用户 ID |
| login_name | VARCHAR(64) | | | 登录名 |
| login_ip | VARCHAR(64) | | | 登录 IP 地址 |
| client_type | VARCHAR(32) | | | 客户端类型（WINDOWS/H5/ANDROID 等） |
| device_info | VARCHAR(256) | | | 设备信息 |
| login_time | DATETIME | NOT NULL | | 登录时间 |
| logout_time | DATETIME | | | 登出时间 |
| login_status | TINYINT(4) | NOT NULL | 0 | 0-失败，1-成功，2-登出 |
| fail_reason | VARCHAR(256) | | | 失败原因 |
| create_time | DATETIME | NOT NULL | | 创建时间 |
| update_time | DATETIME | NOT NULL | | 更新时间 |
| deleted | TINYINT(4) | | 0 | 逻辑删除 |

**索引：**
| 索引名 | 类型 | 字段 | 唯一 |
|--------|------|------|------|
| idx_user_id | BTREE | user_id | 否 |
| idx_tenant_id | BTREE | tenant_id | 否 |
| idx_login_time | BTREE | login_time | 否 |

### 3.3 ER 图

```
┌─────────────────┐       ┌───────────────────┐
│   t_auth_tenant  │       │   t_auth_user      │
│─────────────────│       │───────────────────│
│ id (PK)         │◄──────│ tenant_id          │
│ tenant_code(UK) │       │ id (PK)            │
│ status          │       │ login_name         │
│ expire_time     │       │ password(BCrypt)   │
│ max_user_count  │       │ status             │
└─────────────────┘       │ account_expire_time│
                          └────────┬──────────┘
                                   │
                                   │ 多对多
                                   ▼
                          ┌───────────────────┐       ┌───────────────────┐
                          │ t_auth_user_role   │       │ t_auth_role       │
                          │───────────────────│       │───────────────────│
                          │ id (PK)           │       │ id (PK)           │
                          │ user_id (FK)      │──────►│ tenant_id         │
                          │ role_id (FK)      │       │ role_code (UK)    │
                          │ UK(user_id,role_id)│       │ status            │
                          └───────────────────┘       └────────┬──────────┘
                                                               │
                                                               │ 多对多
                                                               ▼
                          ┌───────────────────┐       ┌───────────────────┐
                          │ t_auth_role_perm   │       │ t_auth_permission │
                          │───────────────────│       │───────────────────│
                          │ id (PK)           │       │ id (PK)           │
                          │ role_id (FK)      │──────►│ parent_id         │
                          │ permission_id (FK) │       │ perm_code (UK)    │
                          │ UK(role_id,perm_id)│       │ perm_type         │
                          └───────────────────┘       └───────────────────┘

┌─────────────────────┐
│  t_auth_login_log    │
│─────────────────────│
│ id (PK)             │
│ tenant_id           │
│ user_id             │
│ login_status        │
│ login_time          │
│ client_type         │
└─────────────────────┘
```

### 3.4 缓存设计

| 缓存编号 | 缓存名 | 类型 | 用途 | 键格式 | 序列化 | TTL |
|---------|-------|------|------|--------|--------|-----|
| CACHE-001 | 登录态会话 | String | 存储用户登录会话信息 | `auth:session:{userId}:{clientType}` | JSON | 7 天 |
| CACHE-002 | Token 黑名单 | String | 吊销的 Token 签名 | `auth:token:blacklist:{tokenSignature}` | String | Token 剩余有效期 |
| CACHE-003 | 账号状态缓存 | String | 用户账号状态（减少 DB 查询） | `auth:account:status:{userId}` | String | 手动管理（状态变更时更新/删除） |
| CACHE-004 | 租户状态缓存 | String | 租户状态 | `auth:tenant:status:{tenantId}` | String | 手动管理（状态变更时更新/删除） |

**Redis 操作方：**
- `auth-service` 写入/更新：登录时写入会话和状态缓存，登出/踢人/封禁时加入黑名单
- `gateway` 读取：每次请求读取黑名单、登录态、状态缓存进行校验

### 3.5 数据流设计

| 流程编号 | 流程名称 | 一致性要求 | 说明 |
|---------|---------|-----------|------|
| FLOW-001 | 用户登录 | 强一致 | 参数校验 → 租户状态校验 → 用户状态校验 → BCrypt 密码校验 → 角色/权限查询 → Token 签发 → Redis 会话写入 → 登录日志写入 |
| FLOW-002 | 请求鉴权 | 最终一致 | RS256 公钥本地验签（无状态）→ Redis 黑名单/登录态/状态查询（最终一致） |
| FLOW-003 | Token 刷新 | 强一致 | Refresh Token 验签 → 黑名单校验 → 新双 Token 签发 → 旧 Token 加入黑名单 → Redis 登录态更新 |
| FLOW-004 | 用户登出 | 最终一致 | Token 加入黑名单 → Redis 登录态删除 → 更新登出日志 |
| FLOW-005 | 强制踢人 | 最终一致 | 校验操作者权限 → Token 加入黑名单 → Redis 登录态删除 → 审计日志 |

---

## 4. 接口设计

### 4.1 接口规范

| 项目 | 规范 |
|------|------|
| 对外接口协议 | RESTful (OpenAPI 3) |
| 内部接口协议 | RESTful HTTP |
| 版本策略 | URL 路径版本 (`/api/v1/`) |
| 认证方式 | JWT Bearer Token（Access Token），白名单路径无需认证 |
| 数据格式 | JSON (UTF-8) |
| 统一响应体 | `ApiResult<T>` (code/message/data/timestamp) |
| 统一分页响应 | `PageResult<T>` (records/total/page/pageSize) |

### 4.2 认证与授权

| 项目 | 说明 |
|------|------|
| Token 颁发方 | `cloudoffice-auth-service`（RS256 私钥签发） |
| Token 校验方 | `cloudoffice-gateway` AuthFilter（RS256 公钥验签） |
| Access Token 有效期 | 2 小时 |
| Refresh Token 有效期 | 7 天 |
| 刷新策略 | Refresh Token 轮换（Rotation），每次刷新同时更换双 Token，旧 Token 入黑名单 |
| 权限模型 | RBAC（用户-角色-权限三层关联），多租户隔离 |
| 网关透传 Header | X-User-Id / X-Tenant-Id / X-User-Name / X-Client-Type / X-Roles / X-Permissions |

### 4.3 API 接口定义

#### 4.3.1 登录接口

```
POST /api/v1/auth/login
Content-Type: application/json
Authorization: 无（白名单）

请求体：
{
  "loginName": "string (4-64字符，字母/数字/下划线)",
  "password": "string (8-64字符)",
  "tenantCode": "string",
  "clientType": "string (WINDOWS|UBUNTU|H5|ANDROID|IOS|WECHAT_MINI)"
}

成功响应 (200)：
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "accessToken": "string (RS256 signed JWT, 2h)",
    "refreshToken": "string (RS256 signed JWT, 7d)",
    "accessTokenExpiresIn": "long (毫秒时间戳)",
    "refreshTokenExpiresIn": "long (毫秒时间戳)",
    "tokenType": "Bearer"
  },
  "timestamp": 1234567890
}

错误场景：
| HTTP 状态码 | 错误码 | 条件 |
|------------|--------|------|
| 400 | CLIENT_TYPE_INVALID | clientType 不合法 |
| 400 | - | 参数校验失败（loginName/password 格式错误） |
| 401 | LOGIN_FAILED | 用户名或密码错误 |
| 403 | TENANT_DISABLED | 租户已被禁用 |
| 403 | TENANT_EXPIRED | 租户已过期 |
| 403 | ACCOUNT_DISABLED | 账号已被禁用 |
| 403 | ACCOUNT_LOCKED | 账号已被锁定 |
| 403 | ACCOUNT_BANNED | 账号已被封禁 |
| 403 | ACCOUNT_EXPIRED | 账号已过期 |
| 404 | - | 租户不存在 |
```

#### 4.3.2 注册接口

```
POST /api/v1/auth/register
Content-Type: application/json
Authorization: 无（白名单）

请求体：
{
  "loginName": "string (4-64字符)",
  "password": "string (8-64字符, 需含字母和数字)",
  "realName": "string (可选)",
  "phone": "string (可选, 需合法手机号格式)",
  "email": "string (可选, 需合法邮箱格式)",
  "tenantCode": "string"
}

成功响应 (201)：
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": 123456,
    "loginName": "zhangsan",
    "realName": "张三",
    "phone": "13800138000",
    "email": "zhangsan@example.com"
  },
  "timestamp": 1234567890
}

错误场景：
| HTTP 状态码 | 错误码 | 条件 |
|------------|--------|------|
| 400 | - | 参数校验失败（loginName 重复/密码不符合规则/手机号格式错误/邮箱格式错误） |
| 403 | TENANT_DISABLED | 租户已被禁用 |
| 404 | - | 租户不存在 |
```

#### 4.3.3 Token 刷新接口

```
POST /api/v1/auth/refresh
Content-Type: application/json
Authorization: 无（白名单）

请求体：
{
  "refreshToken": "string"
}

成功响应 (200)：
{
  "code": 200,
  "message": "刷新成功",
  "data": {
    "accessToken": "string (新 Access Token, 2h)",
    "refreshToken": "string (新 Refresh Token, 7d)",
    "accessTokenExpiresIn": "long",
    "refreshTokenExpiresIn": "long",
    "tokenType": "Bearer"
  },
  "timestamp": 1234567890
}

错误场景：
| HTTP 状态码 | 错误码 | 条件 |
|------------|--------|------|
| 400 | - | refreshToken 参数为空 |
| 401 | REFRESH_TOKEN_EXPIRED | Refresh Token 已过期 |
| 401 | REFRESH_TOKEN_INVALID | Refresh Token 无效 |
| 401 | TOKEN_BLACKLISTED | Refresh Token 已被吊销 |
| 401 | SESSION_KICKED_OUT | Redis 登录态不存在 |
| 403 | ACCOUNT_BANNED | 账号已被封禁 |
| 403 | TENANT_DISABLED | 租户已被禁用 |
```

#### 4.3.4 登出接口

```
POST /api/v1/auth/logout
Authorization: Bearer <accessToken>
Content-Type: application/json

请求体：（无）

成功响应 (200)：
{
  "code": 200,
  "message": "登出成功",
  "data": null,
  "timestamp": 1234567890
}

错误场景：
| HTTP 状态码 | 错误码 | 条件 |
|------------|--------|------|
| 401 | TOKEN_INVALID | Token 无效 |
| 401 | TOKEN_EXPIRED | Token 已过期 |
```

#### 4.3.5 强制踢人接口

```
POST /api/v1/auth/kickout
Authorization: Bearer <accessToken>
Content-Type: application/json

请求体：
{
  "userId": 123456,
  "clientType": "string (可选，为空时踢所有端)"
}

成功响应 (200)：
{
  "code": 200,
  "message": "踢人成功",
  "data": null,
  "timestamp": 1234567890
}

错误场景：
| HTTP 状态码 | 错误码 | 条件 |
|------------|--------|------|
| 400 | CLIENT_TYPE_INVALID | clientType 值不合法 |
| 403 | PERMISSION_DENIED | 非管理员操作 |
| 404 | USER_NOT_FOUND | 目标用户不存在 |
```

#### 4.3.6 用户管理接口

```
GET /api/v1/auth/users?page=1&size=20
Authorization: Bearer <accessToken>
描述：租户内用户分页查询
成功响应 (200)：{ "code": 200, "data": { "records": [...], "total": 100, "page": 1, "pageSize": 20 } }

GET /api/v1/auth/users/{userId}
Authorization: Bearer <accessToken>
描述：用户详情（含角色和权限列表）
成功响应 (200)：{ "code": 200, "data": { "id": 1, "loginName": "...", "roles": [...], "permissions": [...] } }
错误场景：404 USER_NOT_FOUND

PUT /api/v1/auth/users/{userId}
Authorization: Bearer <accessToken>
描述：修改用户信息

PUT /api/v1/auth/users/{userId}/status
Authorization: Bearer <accessToken>
Content-Type: application/json
请求体：{ "status": 0 | 1 | 2 | 3, "lockReason": "string (可选)" }
描述：变更用户状态（0-正常，1-禁用，2-锁定，3-封禁）
封禁时自动清除所有 Redis 登录态和黑名单

PUT /api/v1/auth/users/{userId}/roles
Authorization: Bearer <accessToken>
Content-Type: application/json
请求体：{ "roleIds": [1, 2, 3] }
描述：全量更新用户角色分配

DELETE /api/v1/auth/users/{userId}
Authorization: Bearer <accessToken>
描述：逻辑删除用户
```

#### 4.3.7 角色管理接口

```
GET /api/v1/auth/roles
Authorization: Bearer <accessToken>
描述：租户内角色列表

POST /api/v1/auth/roles
Authorization: Bearer <accessToken>
描述：创建角色

PUT /api/v1/auth/roles/{roleId}
Authorization: Bearer <accessToken>
描述：修改角色

PUT /api/v1/auth/roles/{roleId}/permissions
Authorization: Bearer <accessToken>
Content-Type: application/json
请求体：{ "permissionIds": [1, 2, 3] }
描述：全量更新角色权限分配

DELETE /api/v1/auth/roles/{roleId}
Authorization: Bearer <accessToken>
描述：逻辑删除角色（如已被分配用户则阻止删除）
错误场景：400 角色已被分配给用户
```

#### 4.3.8 权限管理接口

```
GET /api/v1/auth/permissions
Authorization: Bearer <accessToken>
描述：树形结构权限列表

POST /api/v1/auth/permissions
Authorization: Bearer <accessToken>
描述：创建权限点

PUT /api/v1/auth/permissions/{permId}
Authorization: Bearer <accessToken>
描述：修改权限

DELETE /api/v1/auth/permissions/{permId}
Authorization: Bearer <accessToken>
描述：逻辑删除权限（如已被关联角色则阻止删除）
错误场景：400 权限已被关联到角色
```

### 4.4 错误码定义

| 错误码 (HTTP) | 枚举常量 | HTTP 状态码 | 消息 |
|--------------|---------|------------|------|
| 200 | SUCCESS | 200 | 操作成功 |
| 400 | BAD_REQUEST | 400 | 请求参数错误 |
| 400 | CAPTCHA_ERROR | 400 | 验证码错误 |
| 400 | CLIENT_TYPE_INVALID | 400 | 无效的客户端类型 |
| 401 | UNAUTHORIZED | 401 | 未认证 |
| 401 | TOKEN_EXPIRED | 401 | 令牌已过期，请刷新令牌 |
| 401 | TOKEN_INVALID | 401 | 令牌无效 |
| 401 | TOKEN_BLACKLISTED | 401 | 令牌已被吊销 |
| 401 | REFRESH_TOKEN_EXPIRED | 401 | 刷新令牌已过期，请重新登录 |
| 401 | REFRESH_TOKEN_INVALID | 401 | 刷新令牌无效 |
| 401 | LOGIN_FAILED | 401 | 用户名或密码错误 |
| 401 | SESSION_KICKED_OUT | 401 | 账号已在其他设备登录，您已被踢下线 |
| 403 | FORBIDDEN | 403 | 权限不足 |
| 403 | ACCOUNT_DISABLED | 403 | 账号已被禁用 |
| 403 | ACCOUNT_LOCKED | 403 | 账号已被锁定 |
| 403 | ACCOUNT_BANNED | 403 | 账号已被封禁 |
| 403 | ACCOUNT_EXPIRED | 403 | 账号已过期 |
| 403 | TENANT_DISABLED | 403 | 租户已被禁用 |
| 403 | TENANT_EXPIRED | 403 | 租户已过期 |
| 403 | PERMISSION_DENIED | 403 | 权限不足 |
| 404 | NOT_FOUND | 404 | 资源不存在 |
| 404 | USER_NOT_FOUND | 404 | 用户不存在 |
| 404 | ROLE_NOT_FOUND | 404 | 角色不存在 |
| 500 | INTERNAL_ERROR | 500 | 服务器内部错误 |

### 4.5 DTO 定义

```java
// TokenPairDTO - 双 Token 响应
public class TokenPairDTO implements Serializable {
    private String accessToken;              // Access Token (RS256, 2h)
    private String refreshToken;             // Refresh Token (RS256, 7d)
    private Long accessTokenExpiresIn;       // Access Token 过期毫秒时间戳
    private Long refreshTokenExpiresIn;      // Refresh Token 过期毫秒时间戳
    private String tokenType;                // 固定值 "Bearer"
}

// LoginUserDTO - 登录用户信息
public class LoginUserDTO implements Serializable {
    private Long userId;                     // 用户 ID
    private Long tenantId;                   // 租户 ID
    private String userName;                 // 用户名
    private String clientType;               // 客户端类型
    private List<String> roles;              // 角色编码列表
    private List<String> permissions;        // 权限标识列表
}

// 网关透传 Header（字符串格式）
// X-User-Id: Long
// X-Tenant-Id: Long
// X-User-Name: String
// X-Client-Type: String
// X-Roles: String (逗号分隔)
// X-Permissions: String (逗号分隔)
```

### 4.6 网关透传 Header 规范

| Header 名称 | 类型 | 示例值 | 说明 |
|------------|------|--------|------|
| X-User-Id | Long | `123456` | 用户 ID |
| X-Tenant-Id | Long | `1` | 租户 ID |
| X-User-Name | String | `admin` | 用户名 |
| X-Client-Type | String | `WINDOWS` | 客户端类型编码 |
| X-Roles | String | `admin,operator` | 角色编码列表（逗号分隔） |
| X-Permissions | String | `system:user:list,system:user:create` | 权限标识列表（逗号分隔） |

---

## 5. 安全设计

### 5.1 威胁模型

| 威胁类型 | 威胁描述 | 受影响组件 | 缓解措施 |
|---------|---------|-----------|---------|
| Token 伪造 | 攻击者构造假 Token 绕过认证 | Gateway | RS256 非对称签名，公钥验签；私钥仅认证服务持有 |
| Token 重放 | 拦截 Token 后重放使用 | Gateway | Refresh Token 轮换，旧 Token 黑名单 |
| 密码暴力破解 | 大量尝试登录猜测密码 | Auth Service | BCrypt 慢哈希（强度系数 ≥ 10），后续可引入登录频率限制 |
| 会话劫持 | 窃取 Token 冒充用户 | Gateway | Token 黑名单实时吊销，Redis 登录态校验，TLS 传输加密（后续） |
| 跨租户访问 | 用户越权访问其他租户数据 | Auth Service | 多租户隔离，按租户 ID 过滤数据 |
| 密钥泄漏 | RSA 私钥被窃取 | Auth Service | 环境变量/配置文件管理密钥，不支持硬编码；三选一加载策略 |

### 5.2 认证机制

| 认证方式 | 适用场景 | 实现方案 |
|---------|---------|---------|
| 用户名+密码 | 用户登录 | BCrypt 密码校验（强度系数 ≥ 10） |
| JWT Access Token | API 请求鉴权 | RS256 签名，2 小时有效期，携带用户身份和权限信息 |
| JWT Refresh Token | Token 续签 | RS256 签名，7 天有效期，含 tokenVersion，轮换策略防重放 |
| RS256 非对称加密 | 令牌签名与验签 | RSA 2048 位密钥对，私钥 auth-service 签发，公钥 gateway 验签 |

**密钥加载优先级：** 环境变量 → 配置文件 Base64 → PEM 文件路径

### 5.3 授权机制

| 项目 | 说明 |
|------|------|
| 权限模型 | RBAC（用户-角色-权限三层关联） |
| 多租户隔离 | 所有数据按 tenant_id 隔离，用户名/角色编码在租户内唯一 |
| 角色定义 | 支持自定义角色名称和编码（如 admin、operator、user） |
| 权限标识 | 冒号分隔层级式（如 system:user:create） |
| 管理员权限 | 租户管理员可管理本租户用户/角色/权限，平台管理员可管理所有租户 |
| 网关层权限 | AuthFilter 仅校验 Token 有效性，不校验具体权限点 |

### 5.4 数据安全

| 项目 | 方案 |
|------|------|
| 传输加密 | HTTPS（后续配置证书）/ 内网 HTTP |
| 密码存储 | BCrypt 哈希加密（强度系数 ≥ 10） |
| 密钥管理 | 环境变量 + 配置文件 Base64 + PEM 文件，三选一加载 |
| PII 处理 | 日志中密码/密钥脱敏，不输出明文 |
| SQL 注入防护 | MyBatis-Plus 预编译机制，禁止拼接 SQL |
| 敏感配置 | JWT 密钥、数据库密码通过环境变量注入，不留存于代码仓库 |

### 5.5 审计日志

| 项目 | 说明 |
|------|------|
| 记录事件 | 登录成功、登录失败、主动登出、强制踢人（后续）、封禁/解封（后续） |
| 日志格式 | 结构化数据库记录（t_auth_login_log） |
| 记录字段 | tenant_id, user_id, login_name, login_ip, client_type, device_info, login_time, logout_time, login_status, fail_reason |
| 保留期限 | 持久化存储至 MariaDB |
| 存储位置 | `cloudstroll_office_auth` 数据库 `t_auth_login_log` 表 |

---

## 6. 非功能需求设计

### 6.1 性能指标

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| Token 校验 P99 延迟 | ≤ 10ms | 压测工具 |
| 登录接口 P99 延迟 | ≤ 500ms | 压测工具 |
| 健康检查响应时间 | < 100ms | MockMvc / 压测 |
| 单次登录 Redis 读写 | ≤ 5 次 | 代码审查 |
| 单模块首次启动时间 | ≤ 30 秒 | Maven + Spring Boot |
| Maven 增量编译时间 | ≤ 30 秒 | `mvn clean compile -pl {module} -am` |

### 6.2 可扩展性

| 项目 | 策略 | 上限 |
|------|------|------|
| 服务水平扩展 | 无状态 + Nacos 负载均衡 | 多实例部署 |
| 客户端类型扩展 | `ClientTypeEnum` 新增枚举值 | 灵活扩展 |
| 白名单扩展 | 配置项 `auth.white-list` 动态添加 | 灵活扩展 |
| 权限标识扩展 | 新增 `perm_code` 记录 | 灵活扩展 |

### 6.3 可用性

| 项目 | 目标 |
|------|------|
| 服务启动失败容错 | Nacos 连接失败时给出明确提示，拒绝启动 |
| Redis 熔断降级 | Redis 不可用时返回"服务暂不可用"，不泄漏 Redis 连接详情 |
| 全局异常兜底 | `@RestControllerAdvice` 兜底未捕获异常，统一返回 ApiResult |
| Docker 自动重启 | `restart: always` 策略 |

### 6.4 可靠性设计

| 机制 | 方案 | 配置 |
|------|------|------|
| 全局异常处理 | `@RestControllerAdvice` + 兜底 Exception | 100% 异常走统一处理器 |
| Redis 降级 | 连接失败返回明确错误，不泄漏堆栈 | 日志 WARN 级别记录 |
| 数据库容错 | HikariCP 连接池 + 自动重连 | 默认 Spring Boot 配置 |
| 幂等处理 | 重复登出/重复踢人/重复封禁 | 返回操作成功 |

### 6.5 可观测性

| 类别 | 方案 | 说明 |
|------|------|------|
| 日志 | Logback（slf4j）+ @Slf4j | 重要业务节点（登录成功/失败/登出）记录 info 级别日志 |
| 指标 | Prometheus + Grafana | 后续版本集成 |
| 链路追踪 | SkyWalking | 后续版本集成 |
| API 文档 | SpringDoc (OpenAPI 3) | 各服务 `/swagger-ui.html` 可在线调试 |

---

## 7. 部署与运维设计

### 7.1 新增基础设施依赖

| 组件 | 用途 | 版本 | 启用状态 |
|------|------|------|---------|
| Redis 7.2.x | Token 黑名单、登录态会话、状态缓存 | 7.2.x | **v0.1.5 新增启用** |

### 7.2 Nacos 配置

| 配置项 | 说明 | 管理方式 |
|--------|------|---------|
| `spring.data.redis.*` | Redis 连接配置 | 本地配置 + 环境变量覆盖 |
| `jwt.rsa.private-key` | RSA 私钥（Base64）| 环境变量（首选）/配置文件 |
| `jwt.rsa.public-key` | RSA 公钥（Base64）| 环境变量（首选）/配置文件 |
| `auth.white-list` | 网关白名单路径 | 本地配置文件 |
| 数据库密码 | MariaDB 连接密码 | 环境变量注入 |

### 7.3 部署架构（Docker Compose）

```
[Developer Local / CI]
    │
    ▼
┌────────────────────────────────────────────┐
│         Docker Host                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Nacos    │  │ MariaDB  │  │ Redis    │  │
│  │ 2.3.x    │  │ 10.6     │  │ 7.2.x    │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ Gateway  │  │ Auth     │  │ Biz      │  │
│  │ :9000    │  │ :9100    │  │ :9200    │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│  ┌──────────┐                               │
│  │ System   │                               │
│  │ :9400    │                               │
│  └──────────┘                               │
└────────────────────────────────────────────┘
```

### 7.4 测试环境配置

| 要求 | 方案 |
|------|------|
| 无外部中间件运行 | 测试 bootstrap.yml 禁用 Nacos |
| 无需 MariaDB | 排除 DataSourceAutoConfiguration |
| 无需 Redis | Mock Redis 操作 |
| RSA 密钥测试配置 | 提供测试专用 Base64 公私钥 |

---

## 8. 风险与缓解措施

| 风险编号 | 风险描述 | 可能性 | 影响 | 缓解措施 | 负责人 | 状态 |
|---------|---------|-------|------|---------|-------|------|
| RISK-001 | Redis 不可用导致认证服务全部失效 | 低 | 高 | 网关层降级为仅 RS256 公钥验签，不强制查询 Redis（需配置降级策略）；Redis 容器配置 `restart: always` 自动恢复 | 开发团队 | 计划中 |
| RISK-002 | RSA 私钥泄漏导致 Token 可被伪造 | 低 | 高 | 私钥仅认证服务持有，通过环境变量注入，不存储于代码仓库；密钥支持定期轮换；网关无私钥 | 运维/开发 | 已缓解 |
| RISK-003 | 多端混合登录导致 Redis 会话膨胀 | 中 | 中 | 登录态 TTL 7 天自动过期；Token 黑名单 TTL = Token 剩余有效期自动清理；单用户最多 6 个会话（6 种客户端类型） | 开发团队 | 已缓解 |
| RISK-004 | BCrypt 密码校验性能瓶颈（高并发登录） | 低 | 中 | BCrypt 强度系数 ≥ 10，单次校验约 10ms；后续可引入登录频率限制；Redis 缓存账号状态减少 DB 查询 | 开发团队 | 已接受 |
| RISK-005 | 网关 AuthFilter 成为性能瓶颈 | 中 | 中 | RS256 公钥验签（本地无网络开销）+ Redis 响应式非阻塞查询；单次校验目标 ≤ 10ms；网关支持水平扩展 | 开发团队 | 已缓解 |
| RISK-006 | 多租户数据隔离实现遗漏 | 中 | 高 | 所有 SQL 查询强制拼接 tenant_id 条件；唯一索引（uk_tenant_login_name、uk_tenant_role_code）防止跨租户数据冲突 | 开发团队 | 计划中 |
| RISK-007 | 测试环境依赖过多中间件 | 中 | 中 | 测试配置禁用 Nacos/MariaDB/Redis；RSA 密钥使用测试专用配置；确保单元测试可独立运行 | 开发团队 | 已缓解 |

---

## 9. 附录

### 附录 A：术语表

| 术语 | 释义 |
|------|------|
| RBAC | Role-Based Access Control，基于角色的访问控制模型 |
| 多租户 | Multi-Tenancy，单个 SaaS 实例服务多个企业租户，数据隔离 |
| Access Token | 短时效（2 小时）访问令牌，用于 API 请求鉴权 |
| Refresh Token | 长时效（7 天）刷新令牌，用于无感续签 Access Token |
| RS256 | RSA Signature with SHA-256，非对称 JWT 签名算法 |
| 多端混合登录 | 同一账号在不同客户端类型同时登录，同类型端互斥 |
| Token 黑名单 | Redis 中维护的已吊销 Token 列表 |
| 登录态会话 | Redis 中维护的用户登录状态 |
| AuthFilter | 网关层全局认证过滤器 |
| Token 轮换 | Refresh Token 刷新时更换新旧 Token，旧 Token 入黑名单 |
| 同端互斥 | 同一用户 + 同客户端类型只能有一个有效登录会话 |
| 设备分类 | ClientTypeEnum 按 PC/WEB/MOBILE/MINI_PROGRAM 分类，决定互斥策略 |

### 附录 B：ClientTypeEnum 枚举定义

| 枚举值 | code | label | deviceCategory |
|--------|------|-------|---------------|
| WINDOWS | WINDOWS | Windows 桌面端 | PC |
| UBUNTU | UBUNTU | Ubuntu 桌面端 | PC |
| H5 | H5 | H5 网页端 | WEB |
| ANDROID | ANDROID | Android 移动端 | MOBILE |
| IOS | IOS | iOS 移动端 | MOBILE |
| WECHAT_MINI | WECHAT_MINI | 微信小程序端 | MINI_PROGRAM |

**方法签名：**
- `static Optional<ClientTypeEnum> fromCode(String code)` — 根据 code 查找枚举，返回 Optional
- `boolean isSameCategory(ClientTypeEnum other)` — 判断是否同设备分类（互斥依据）

### 附录 C：JwtUtils 方法签名

```java
public class JwtUtils {
    // 签发 Access Token（2h 过期，含 roles/permissions 声明）
    String generateAccessToken(LoginUserDTO loginUser);

    // 签发 Refresh Token（7d 过期，含 tokenVersion 声明）
    String generateRefreshToken(LoginUserDTO loginUser);

    // 解析并验证 Access Token，返回 Claims（校验 tokenType="access"）
    Claims parseAccessToken(String token);

    // 解析并验证 Refresh Token，返回 Claims（校验 tokenType="refresh"）
    Claims parseRefreshToken(String token);

    // 获取 Token 签名指纹（SHA-256 摘要），用于黑名单 Key
    String getTokenSignature(String token);
}
```
