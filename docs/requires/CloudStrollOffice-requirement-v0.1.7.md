# 需求文档

**项目名称：** 云漫智企 (CloudStrollOffice)
**版本号：** v0.1.7
**日期：** 2026-06-24

---

## 修订记录

| 版本 | 日期 | 修订内容 | 作者 |
|------|------|----------|------|
| v0.1.7 | 2026-06-24 | 初始版本，定义管理中台建设需求（admin-service 模块搭建、管理后台用户管理） | BA |

---

## 1. 项目背景

### 1.1 业务背景

云漫智企（CloudStrollOffice）是一个基于 Java 21 + Spring Boot 3.2.x + Spring Cloud 2023.x 技术栈构建的微服务互联网应用程序。当前已完成 v0.1.6 版本的全部开发，具备了完善的认证体系（多模式注册/登录、密码管理、手机号变更、OAuth 绑定、验证码管理等），以及微服务基础骨架（common、gateway、auth-service、biz-service、system-service）。

当前各业务模块的能力分布如下：

| 模块 | 能力 |
|------|------|
| `cloudoffice-auth-service` | 认证授权、用户管理、角色权限管理（RBAC）、多模式登录注册 |
| `cloudoffice-biz-service` | 企业信息管理骨架 |
| `cloudoffice-system-service` | 系统配置、监控、健康检查骨架 |
| `cloudoffice-gateway` | API 网关、路由转发 |

虽然 `auth-service` 拥有完整的用户管理（UserService/UserMapper/UserEntity）和角色权限管理能力，但**当前所有用户管理操作仅限于后端内部调用或注册流程触发**，缺乏一个统一的**管理后台（Admin Console）**供系统管理员通过 Web 界面或专用 API 来进行可视化的用户管理。

### 1.2 业务痛点

1. **缺乏管理后台**：系统目前没有一个统一的管理后台模块，所有管理操作无法通过标准化的 Web 管理界面完成，只能直接操作数据库或通过硬编码接口调用
2. **用户管理不可视化**：管理员无法查看用户列表、搜索用户、了解用户状态（启用/禁用、注册时间、角色分配等），用户运营管理效率低下
3. **非管理员用户直接管理风险**：目前用户管理相关 API 与普通用户认证 API 混在 `auth-service` 中，缺少面向管理员的专用接口层和安全隔离
4. **管理能力零散**：用户管理、角色管理、系统配置等管理功能分散在各个微服务中，没有统一的门户和聚合层，第三方接入和后台集成困难
5. **缺少管理审计**：缺乏管理员操作日志，无法追溯"谁在什么时间对哪个用户做了什么操作"

### 1.3 项目目标

1. 搭建**管理中台微服务模块**（`cloudoffice-admin-service`），作为统一的管理后台后端服务
2. 通过管理中台提供**用户管理**功能，包括用户列表查询、新增用户、编辑用户、启用/禁用用户、重置密码、角色分配等 CRUD 操作
3. 实现**管理员身份认证**，确保只有具备管理员角色的用户才能访问管理后台 API
4. 基于 OpenFeign 实现 `admin-service` 与 `auth-service` 之间的服务间通信，避免直接跨服务访问数据库
5. 建立管理操作审计日志机制，记录关键管理操作

### 1.4 适用范围

本文档适用于 CloudStrollOffice v0.1.7 版本的开发，覆盖管理中台建设与用户管理的全部需求范围，涉及 `cloudoffice-admin-service`（新增模块）、`cloudoffice-auth-service`（扩展）两个模块。

---

## 2. 总体需求描述

### 2.1 角色定义

| 角色 | 描述 |
|------|------|
| 超级管理员 | 拥有系统最高权限，可管理所有管理员和普通用户，可进行用户创建/删除/角色分配等操作 |
| 系统管理员 | 拥有用户管理的操作权限，可查看用户列表、编辑用户、启用/禁用、重置密码等 |
| 普通用户 | 通过前台应用注册和使用系统，不具备管理后台访问权限 |
| 未认证请求者 | 未登录的匿名请求，无法访问任何管理后台 API |

### 2.2 管理员角色权限矩阵（v0.1.7）

| 功能模块 | 操作 | 超级管理员 | 系统管理员 | 普通用户 |
|---------|------|-----------|-----------|---------|
| 用户管理 | 查看用户列表 | ✓ | ✓ | ✗ |
| 用户管理 | 查看用户详情 | ✓ | ✓ | ✗ |
| 用户管理 | 新增用户 | ✓ | ✓ | ✗ |
| 用户管理 | 编辑用户信息 | ✓ | ✓ | ✗ |
| 用户管理 | 启用/禁用用户 | ✓ | ✓ | ✗ |
| 用户管理 | 重置用户密码 | ✓ | ✓ | ✗ |
| 用户管理 | 用户角色分配 | ✓ | ✓ | ✗ |
| 管理员管理 | 管理其他管理员 | ✓ | ✗ | ✗ |

### 2.3 整体架构

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         管理中台前端（独立前端应用）                        │
│                     Admin Console (Vue.js/React SPA)                     │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │ HTTP API
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    API 网关 (cloudoffice-gateway :9000)                    │
│              路由: /api/v1/admin/** → admin-service :9500                 │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                  cloudoffice-admin-service（新增 :9500）                   │
│                                                                          │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────────┐  │
│  │ Admin 认证过滤器   │  │ 用户管理控制器     │  │ 操作日志 AOP          │  │
│  │ (JWT解析+角色校验) │  │ AdminUserCtrl    │  │ (管理操作审计记录)     │  │
│  └────────┬────────┘  └────────┬─────────┘  └────────────────────────┘  │
│           │                    │                                          │
│           └────────────────────┤                                          │
│                                │                                          │
│  ┌─────────────────────────────▼──────────────────────────────────────┐  │
│  │              OpenFeign 服务间调用                                     │  │
│  │  ┌─────────────────────────────────────────────────────────────┐   │  │
│  │  │ AuthServiceClient（Feign）                                      │   │  │
│  │  │  ├─ 用户列表查询 / 用户详情                                    │   │  │
│  │  │  ├─ 新增用户 / 编辑用户                                       │   │  │
│  │  │  ├─ 启用/禁用用户                                             │   │  │
│  │  │  ├─ 重置用户密码                                              │   │  │
│  │  │  └─ 角色分配 / 查询用户角色                                    │   │  │
│  │  └─────────────────────────────────────────────────────────────┘   │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────┬─────────────────────────────────────────┘
                                 │
                                 ▼
┌──────────────────────────────────────────────────────────────────────────┐
│               cloudoffice-auth-service（扩展 :9100）                      │
│                                                                          │
│  ┌─────────────────────────────┐   ┌─────────────────────────────────┐  │
│  │ 新增：AdminUserController    │   │ 已有：UserService/UserMapper    │  │
│  │ (管理后台专用的用户管理API)    │◄──│ (用户 CRUD、角色查询等)        │  │
│  └─────────────────────────────┘   └─────────────────────────────────┘  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │ 数据库: cloudstroll_office_auth                                    │  │
│  │ t_auth_user  │ t_auth_role  │ t_auth_user_role  │ t_auth_permission│  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
```

### 2.4 核心交互流程

#### 2.4.1 管理员登录流程

```
Admin → POST /api/v1/auth/login { loginMode: USERNAME_PASSWORD, loginName, password, tenantCode }
  → auth-service 校验用户名+密码
  → 查询用户角色（如 "SUPER_ADMIN" / "SYSTEM_ADMIN"）
  → 签发 JWT 双 Token（Token 中注入 roles 信息）
  → 返回 TokenPairDTO
  → Admin frontend 保存 Token，跳转管理后台首页
```

#### 2.4.2 管理员访问管理后台 API 流程

```
Admin → GET /api/v1/admin/users (Authorization: Bearer <accessToken>)
  → gateway 路由到 admin-service :9500
  → admin-service AdminAuthFilter:
      1. 从 Authorization 头解析 JWT Token
      2. 校验 Token 有效性（RS256 验签，共享 auth-service 的公钥）
      3. 提取用户角色列表
      4. 校验是否包含 ADMIN 角色（SUPER_ADMIN / SYSTEM_ADMIN）
      5. 校验通过 → 传递用户上下文到请求
      6. 校验失败 → 返回 403 Forbidden
  → 通过后 → AdminUserController.listUsers()
  → AdminUserService.listUsers(params)
  → AuthServiceClient.listUsers(params) [Feign → auth-service]
  → auth-service AdminUserController.listUsers()
  → UserService.listUsers(params)
  → UserMapper.selectPage(page, wrapper)
  → 返回分页数据 → 逐层返回
```

#### 2.4.3 用户管理操作流程（以新增用户为例）

```
Admin → POST /api/v1/admin/users (Authorization: Bearer <accessToken>)
  → admin-service 校验管理员身份
  → 校验请求参数（用户名、手机号、邮箱等）
  → AuthServiceClient.createUser(adminCreateUserRequest) [Feign → auth-service]
  → auth-service 校验管理员操作权限
  → UserService.createUser() → UserMapper.insert(user)
  → 返回创建成功的用户信息
  → admin-service 记录操作日志（管理员ID、操作类型、目标用户、时间）
```

---

## 3. 功能需求

### 3.1 管理中台模块搭建

#### FR-001: 创建 admin-service 微服务模块

- **描述：** 新建 `cloudoffice-admin-service` 微服务模块，作为统一的管理后台后端服务。该模块遵循项目标准包结构，注册到 Nacos 服务发现，通过 API 网关路由访问。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 在 `pom.xml` 父项目中注册 `<module>cloudoffice-admin-service</module>`
  2. 模块 `artifactId` 为 `cloudoffice-admin-service`
  3. 端口号：9500
  4. 包名：`org.cloudstrolling.cloudoffice.admin`
  5. 遵循项目标准包结构：`config/`、`controller/`、`service/`、`service/impl/`、`entity/`、`dto/`、`vo/`、`enums/`、`exception/`、`filter/`、`interceptor/`、`mapper/`、`util/`
  6. 包含启动类 `AdminApplication.java`（`@SpringBootApplication` + `@EnableDiscoveryClient`）
  7. 包含健康检查端点 `GET /api/v1/admin/health`
  8. Maven 依赖：`cloudoffice-common`、`spring-boot-starter-web`、`spring-cloud-starter-openfeign`、`spring-cloud-starter-loadbalancer` 等
  9. 配置文件 `bootstrap.yml`（Nacos 注册/配置中心）和 `application.yml`（端口 9500、SpringDoc 配置）
  10. 模块注册至 Nacos，网关配置路由规则 `/api/v1/admin/**` → `cloudoffice-admin-service`
  11. 可通过 `mvn clean compile -pl cloudoffice-admin-service -am` 编译通过
  12. 创建 `AdminApplicationTest.java` 应用启动测试，验证 Spring 上下文正常加载

#### FR-002: 管理中台 API 路径与网关路由

- **描述：** 定义管理中台的统一 API 路径规范，并在 API 网关中配置路由规则，将所有 `/api/v1/admin/**` 路径的请求转发到 admin-service。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 管理中台 API 统一前缀：`/api/v1/admin/{resource}`
  2. 网关路由配置：匹配路径 `/api/v1/admin/**`，转发至 `cloudoffice-admin-service`
  3. 资源命名遵循 RESTful 风格：
     - 用户管理：`/api/v1/admin/users`
     - 健康检查：`/api/v1/admin/health`
  4. 网关路由规则支持负载均衡（通过 Nacos 服务发现）

---

### 3.2 管理中台认证与授权

#### FR-003: 管理员身份认证与权限校验

- **描述：** 实现管理员身份认证机制。管理员通过 `auth-service` 的标准登录接口登录，admin-service 通过 JWT 校验和角色检查来确保只有管理员角色可以访问管理后台 API。
- **优先级：** 高 (Must)
- **验收标准：**
  1. **认证机制：**
     - 管理员使用已有的 `POST /api/v1/auth/login` 进行登录（不需要额外的管理员登录接口）
     - auth-service 在 JWT Token 的 `roles` 字段中携带角色编码
     - admin-service 从 JWT Token 中提取并校验用户角色
  2. **角色检查：**
     - admin-service 中实现 `AdminAuthFilter` 或 `AdminAuthInterceptor`，对所有 `/api/v1/admin/**` 请求进行拦截
     - 校验逻辑：
       a. 从请求头 `Authorization: Bearer <token>` 中提取 JWT Token
       b. 解析 Token 获取用户基本信息（userId、userName、roles）
       c. 检查 `roles` 列表中是否包含管理员角色（如 `SUPER_ADMIN` 或 `SYSTEM_ADMIN`）
       d. 校验通过 → 将用户信息放入请求上下文（`AdminContext` / `RequestAttributes`）
       e. 校验失败 → 返回 403 Forbidden（错误码：`ADMIN-0001` 非管理员用户无权访问）
     - 健康检查端点 `GET /api/v1/admin/health` 应排除在认证拦截之外
  3. **JWT 验签：**
     - admin-service 需持有 RSA 公钥，用于验证 JWT Token 的签名
     - RSA 公钥可通过 Nacos 配置中心共享，或从公共配置中读取
  4. **管理员角色预置：**
     - 在 auth-service 的 `t_auth_role` 表中预置管理员角色：
       - `SUPER_ADMIN`（超级管理员）
       - `SYSTEM_ADMIN`（系统管理员）
     - 现有注册接口注册的用户默认不赋予管理员角色（普通用户角色 `USER`）
     - 通过数据初始化脚本（或手动 SQL）赋予初始超级管理员账号

#### FR-004: 管理员上下文与操作权限

- **描述：** 在 admin-service 中建立管理员请求上下文（AdminContext），贯穿整个请求生命周期，为业务逻辑提供当前操作者的身份信息和操作基准。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **AdminContext 上下文：**
     - 类：`AdminContext.java`（ThreadLocal 持有）
     - 内容：`adminId`（Long，管理员用户ID）、`adminName`（String，管理员登录名）、`realName`（String，真实姓名）、`roles`（List&lt;String&gt;，角色列表）
     - 提供静态方法：`getCurrentAdmin()`、`setCurrentAdmin(AdminContext)`、`clear()`
     - 在 `AdminAuthFilter` 解析 Token 后设置上下文
     - 请求结束后清除上下文（通过 `finally` 或过滤器销毁方法）
  2. **操作权限校验：**
     - 后续 CRUD 操作中通过 AdminContext 获取当前操作者身份
     - 敏感操作（如禁用超级管理员、删除用户等）需额外校验权限层级
     - 超级管理员可执行所有操作，系统管理员不能管理其他管理员

---

### 3.3 用户管理（管理员侧）

#### FR-005: 用户列表查询

- **描述：** 管理员可通过管理后台按条件分页查询用户列表，支持多种筛选条件和关键词搜索。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`GET /api/v1/admin/users`
  2. 请求参数（Query String）：
     - `page`（int，页码，默认 1）
     - `size`（int，每页条数，默认 10，最大 100）
     - `keyword`（String，可选，关键词搜索，匹配用户名、手机号、邮箱）
     - `status`（Integer，可选，用户状态：0-正常，1-禁用，-1-全部）
     - `roleCode`（String，可选，按角色编码筛选）
     - `registerMode`（String，可选，按注册模式筛选）
     - `startTime` / `endTime`（String，可选，按注册时间范围筛选）
  3. 返回 Pagination（`PageResult<UserVO>`）：
     - 包含用户列表数据、总记录数、总页数、当前页码、每页条数
  4. 每个用户数据（`UserVO`）至少包含：
     - `id`（用户 ID）
     - `loginName`（登录名）
     - `userName`（真实姓名）
     - `phone`（手机号，脱敏显示：138****1234）
     - `email`（邮箱，脱敏显示：u***@example.com）
     - `status`（用户状态：0-正常，1-禁用）
     - `registerMode`（注册模式）
     - `accountSettled`（账号是否已完善）
     - `roles`（角色列表，角色编码+角色名称）
     - `createTime`（注册时间）
     - `lastLoginTime`（最后登录时间）
  5. 查询实现：admin-service 通过 Feign 调用 auth-service 提供的数据接口
  6. 要求：所有筛选条件均为可选，不传任何条件时返回全量用户（分页）

#### FR-006: 用户详情查看

- **描述：** 管理员可通过 ID 查看某个用户的详细信息。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`GET /api/v1/admin/users/{userId}`
  2. 请求参数：`userId`（Long，路径变量，用户 ID）
  3. 返回 `UserDetailVO`，包含：
     - `id`、`loginName`、`userName`、`phone`、`email`
     - `status`（用户状态）
     - `registerMode`、`accountSettled`
     - `phoneVerified`、`emailVerified`
     - `roles`（角色列表）
     - `createTime`、`updateTime`
     - `lastLoginTime`、`lastLoginIp`
  4. 用户不存在时返回 404（错误码：`ADMIN-0002` 用户不存在）
  5. 手机号和邮箱需脱敏处理

#### FR-007: 新增用户

- **描述：** 管理员可通过管理后台创建新用户，创建后用户可直接使用（状态为正常）。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`POST /api/v1/admin/users`
  2. 请求参数 JSON Body：
     - `loginName`（String，必填，登录名，租户内唯一）
     - `userName`（String，必填，真实姓名）
     - `password`（String，必填，初始密码，长度 8~64 位）
     - `phone`（String，可选，手机号）
     - `email`（String，可选，邮箱）
     - `roleIds`（List&lt;Long&gt;，可选，初始角色 ID 列表）
  3. 校验规则：
     - `loginName` 在租户内唯一
     - 密码复杂度校验（长度 8~64，必须包含字母和数字）
     - 手机号格式校验
     - 邮箱格式校验
  4. 处理逻辑：
     - 使用 BCrypt 加密密码
     - 创建用户状态为正常（0）
     - 如传入了 `roleIds`，同步分配角色
     - `registerMode` 标记为 `ADMIN_CREATE`（管理员创建）
     - `accountSettled` 标记为已完善（1）
  5. 返回：创建成功的用户基本信息（不含密码）
  6. 审计日志：记录"管理员 {adminName} 创建了用户 {loginName}"

#### FR-008: 编辑用户信息

- **描述：** 管理员可编辑用户的基本信息，包括用户名、手机号、邮箱等。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`PUT /api/v1/admin/users/{userId}`
  2. 请求参数（路径变量 + JSON Body）：
     - `userId`（Long，路径变量）
     - `userName`（String，可选，修改真实姓名）
     - `phone`（String，可选，修改手机号）
     - `email`（String，可选，修改邮箱）
  3. 校验规则：
     - 用户不存在时返回 404
     - 手机号修改时需校验新手机号在租户内唯一
     - 邮箱格式校验
  4. 不允许修改：`loginName`、`password`（通过专用接口修改）
  5. 返回：更新后的用户基本信息
  6. 审计日志：记录"管理员 {adminName} 修改了用户 {userId} 的信息"

#### FR-009: 启用/禁用用户

- **描述：** 管理员可通过管理后台启用或禁用用户账号，禁用后该用户无法登录系统。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`PUT /api/v1/admin/users/{userId}/status`
  2. 请求参数：
     - `userId`（Long，路径变量）
     - `status`（Integer，必填，0-启用，1-禁用）
     - `reason`（String，可选，禁用原因）
  3. 校验规则：
     - 用户不存在时返回 404
     - 禁止禁用自身（管理员不能禁用自己）
     - 禁止禁用超级管理员（有且只有一个超级管理员时，不允许禁用）
  4. 禁用处理逻辑：
     - 更新用户状态为禁用
     - 清除该用户的所有 Redis 登录态会话（强制登出）
  5. 启用处理逻辑：
     - 更新用户状态为正常
  6. 审计日志：记录"管理员 {adminName} 禁用了用户 {userId}（原因：{reason}）"或"管理员 {adminName} 启用了用户 {userId}"
  7. 错误码：
     - `ADMIN-0003` 不能禁用自身
     - `ADMIN-0004` 不能禁用唯一的超级管理员

#### FR-010: 重置用户密码

- **描述：** 管理员可重置指定用户的密码，重置后用户需使用新密码登录。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`PUT /api/v1/admin/users/{userId}/password/reset`
  2. 请求参数：
     - `userId`（Long，路径变量）
     - `newPassword`（String，必填，新密码，长度 8~64 位）
     - `confirmPassword`（String，必填，确认新密码）
  3. 校验规则：
     - 用户不存在时返回 404
     - 新密码与确认密码必须一致
     - 密码复杂度校验（长度 8~64，必须包含字母和数字）
  4. 处理逻辑：
     - 使用 BCrypt 加密新密码并更新
     - 清除该用户的所有 Redis 登录态会话（强制重新登录）
     - 更新 `lastPasswordChangeTime` 字段
  5. 返回：操作成功，不返回密码
  6. 安全要求：
     - 密码不在日志、响应体、异常信息中明文输出
  7. 审计日志：记录"管理员 {adminName} 重置了用户 {userId} 的密码"

#### FR-011: 用户角色分配

- **描述：** 管理员可为用户分配角色，支持多角色分配（全量替换），修改后立即生效。
- **优先级：** 高 (Must)
- **验收标准：**
  1. API：`PUT /api/v1/admin/users/{userId}/roles`
  2. 请求参数：
     - `userId`（Long，路径变量）
     - `roleIds`（List&lt;Long&gt;，必填，角色 ID 列表，传空数组表示移除所有角色）
  3. 校验规则：
     - 用户不存在时返回 404
     - 角色 ID 不合法时返回错误
     - 禁止移除超级管理员的最后一个管理员角色（至少保留一个管理员资格）
  4. 处理逻辑：
     - 全量替换（先删后增）用户角色关联
     - 更新成功后，清除该用户的 Redis 登录态会话（强制重新登录使角色变更生效）
  5. 审计日志：记录"管理员 {adminName} 修改了用户 {userId} 的角色"

---

### 3.4 auth-service 扩展

#### FR-012: 用户管理对外 API（auth-service 扩展）

- **描述：** 在 auth-service 中新增 `AdminUserController`，提供管理员专用的用户管理 REST API 端点，供 admin-service 通过 OpenFeign 调用。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 新增 `AdminUserController`，位于 `org.cloudstrolling.cloudoffice.auth.controller.admin` 包下
  2. 所有端点路径前缀：`/api/v1/auth/admin/users`
  3. 这些端点**仅用于 admin-service 内部调用**，需校验来源（可通过内部网络限制或管理员 Token），防止外部直接访问
  4. 需要暴露的端点：
     - `GET /api/v1/auth/admin/users` — 分页查询用户列表（支持 FR-005 的所有筛选条件）
     - `GET /api/v1/auth/admin/users/{userId}` — 查询用户详情（含角色信息）
     - `POST /api/v1/auth/admin/users` — 创建用户（BCrypt 加密密码，设置注册模式）
     - `PUT /api/v1/auth/admin/users/{userId}` — 更新用户信息
     - `PUT /api/v1/auth/admin/users/{userId}/status` — 启用/禁用用户（附带清除 Redis 会话）
     - `PUT /api/v1/auth/admin/users/{userId}/password/reset` — 重置密码（BCrypt 加密 + 清除会话）
     - `PUT /api/v1/auth/admin/users/{userId}/roles` — 全量替换用户角色
  5. 新增 `AdminUserRequest` DTO 和 `AdminUserVO` / `AdminUserDetailVO` 用于管理员视角的用户数据展示
  6. `AdminUserVO` 中需包含角色列表信息（角色编码 + 角色名称）
  7. 响应格式统一使用 `ApiResult<T>` 和 `PageResult<AdminUserVO>`
  8. 错误码复用已有的 `AUTH-XXXX` 错误码体系

#### FR-013: OpenFeign 客户端（admin-service 端）

- **描述：** 在 admin-service 中创建 OpenFeign 客户端接口，用于调用 auth-service 的用户管理 API。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 接口：`AuthServiceClient`，位于 `org.cloudstrolling.cloudoffice.admin.feign` 包下
  2. 使用 `@FeignClient(name = "cloudoffice-auth-service")` 注解
  3. 定义以下远程调用方法（对应 FR-012 的端点）：
     - `listUsers(page, size, keyword, status, roleCode, startTime, endTime)` → `ApiResult<PageResult<AdminUserVO>>`
     - `getUserDetail(userId)` → `ApiResult<AdminUserDetailVO>`
     - `createUser(request)` → `ApiResult<AdminUserVO>`
     - `updateUser(userId, request)` → `ApiResult<AdminUserVO>`
     - `updateUserStatus(userId, status, reason)` → `ApiResult<Void>`
     - `resetUserPassword(userId, newPassword, confirmPassword)` → `ApiResult<Void>`
     - `assignUserRoles(userId, roleIds)` → `ApiResult<Void>`
  4. 配置 OpenFeign 的请求拦截器，在调用 auth-service 时传递管理员身份 Token
  5. Feign 配置类 `FeignConfig.java` 启用 OpenFeign

---

### 3.5 管理操作审计日志

#### FR-014: 管理员操作审计日志

- **描述：** 记录管理员在管理后台的关键操作行为，支持操作追溯和审计。
- **优先级：** 中 (Should)
- **验收标准：**
  1. **新增审计日志实体：** `AdminAuditLogEntity`，对应数据库表 `t_admin_audit_log`
     - 位于 admin-service 模块
  2. 表 `t_admin_audit_log` 结构：
     - `id` BIGINT(20) — 主键，雪花算法
     - `admin_id` BIGINT(20) — 操作管理员用户 ID，NOT NULL
     - `admin_name` VARCHAR(64) — 操作管理员登录名
     - `action_type` VARCHAR(32) — 操作类型（如 `CREATE_USER`、`UPDATE_USER`、`DISABLE_USER`、`RESET_PASSWORD`、`ASSIGN_ROLES` 等）
     - `target_id` BIGINT(20) — 操作目标 ID（如被操作用户 ID）
     - `target_desc` VARCHAR(256) — 操作目标描述
     - `detail` VARCHAR(1024) — 操作详情（JSON 格式，记录变更前后内容）
     - `result` TINYINT(4) — 操作结果：0-成功，1-失败
     - `error_message` VARCHAR(512) — 错误信息（失败时记录）
     - `ip_address` VARCHAR(64) — 操作者 IP 地址
     - `create_time` DATETIME — 创建时间
     - `update_time` DATETIME — 更新时间
     - `deleted` TINYINT(4) — 逻辑删除
  3. **操作类型枚举：** `AdminActionTypeEnum`
     - `CREATE_USER`、`UPDATE_USER`、`DISABLE_USER`、`ENABLE_USER`
     - `RESET_PASSWORD`、`ASSIGN_ROLES`
     - 预留扩展：`DELETE_USER`、`SYSTEM_CONFIG` 等
  4. **实现方式：**
     - 通过 Spring AOP（`@AdminAuditLog` 注解）实现操作日志切面
     - 注解参数：`actionType`（操作类型）、`targetIdExpr`（目标 ID 的 SpEL 表达式）
     - 在 Controller 方法上加注解，自动记录日志
     - 异常时记录失败结果和异常信息
  5. 审计日志查询接口（供管理后台查看审计记录）：`GET /api/v1/admin/audit-logs`
     - 支持按操作时间范围、操作类型、操作管理员 ID 筛选分页查询
  6. 审计日志不可被修改或删除（仅插入和查询）

---

### 3.6 数据库扩展

#### FR-015: 管理员角色预置与数据初始化

- **描述：** 在 `t_auth_role` 表中预置管理员角色，并创建初始超级管理员账号。
- **优先级：** 高 (Must)
- **验收标准：**
  1. 在 `t_auth_role` 表中插入以下角色数据（可通过 SQL 脚本或数据初始化器）：
     - `SUPER_ADMIN`（编码：`SUPER_ADMIN`，名称：超级管理员，描述：拥有系统最高权限）
     - `SYSTEM_ADMIN`（编码：`SYSTEM_ADMIN`，名称：系统管理员，描述：可管理用户和系统配置）
  2. 为 `SUPER_ADMIN` 角色分配所有用户管理的操作权限（后续版本可细化到具体权限点）
  3. 为 `SYSTEM_ADMIN` 角色分配用户管理相关操作权限
  4. 创建初始超级管理员账号（通过数据初始化脚本）：
     - `loginName`：`admin`
     - `userName`：系统管理员
     - `password`：BCrypt 加密，初始值 `Admin@123456`
     - 关联 `SUPER_ADMIN` 角色
     - 状态：正常
     - `registerMode`：`ADMIN_CREATE`
  5. 初始超级管理员账号建议在首次登录后强制修改密码（提示 `-D` 参数或通过系统配置控制）
  6. 数据库初始化脚本位于 `scripts/sql/` 目录下，命名为 `init_admin_data.sql`

#### FR-016: admin-service 独立数据库

- **描述：** admin-service 拥有独立的数据库 `cloudstroll_office_admin`，用于存储管理后台相关的数据（如审计日志）。
- **优先级：** 中 (Should)
- **验收标准：**
  1. 数据库名：`cloudstroll_office_admin`
  2. 数据源配置在 admin-service 的 `application.yml` 中
  3. v0.1.7 需创建的数据库表：
     - `t_admin_audit_log` — 管理员操作审计日志表（FR-014）
  4. 用户相关数据不在 admin-service 数据库维护，通过 Feign 调用 auth-service 操作
  5. DDL 脚本位于 `scripts/sql/` 目录

---

## 4. 非功能需求

### NFR-001: 安全性

- **描述：** 管理中台涉及敏感操作和用户数据，必须满足企业级安全要求。
- **指标：**
  1. 所有管理后台 API 必须验证管理员身份，未授权请求返回 401/403
  2. JWT Token 解析失败时返回 401，角色校验不通过时返回 403
  3. 管理员密码复杂度满足密码策略要求
  4. 用户手机号、邮箱在日志和 API 响应中脱敏显示（如 138****1234）
  5. 用户密码不在日志、响应体、异常信息中明文输出
  6. 关键操作（创建用户、禁用用户、重置密码、角色分配）必须记录审计日志
  7. 禁用用户操作必须同步清除该用户的所有登录态会话
  8. 防止水平越权：管理员只能操作其权限范围内的用户

### NFR-002: 性能

- **描述：** 管理后台 API 响应性能满足日常管理操作的需求。
- **指标：**
  1. 用户列表查询（带分页）响应时间 ≤ 1000ms（10000 用户规模）
  2. 用户详情查询响应时间 ≤ 200ms
  3. 新增/编辑用户响应时间 ≤ 500ms
  4. 启用/禁用用户响应时间 ≤ 1000ms（含清除 Redis 会话）
  5. 重置密码响应时间 ≤ 500ms（含 BCrypt 加密和清除会话）
  6. Feign 调用超时配置：连接超时 5s，读取超时 10s

### NFR-003: 可维护性

- **描述：** 代码应遵循项目统一规范，便于后续扩展和维护。
- **指标：**
  1. admin-service 遵循 project.md 定义的标准包结构
  2. 使用构造器注入，禁止 `@Autowired` 字段注入
  3. API 路径遵循规范：`/api/v1/admin/{resource}`
  4. 响应统一使用 `ApiResult<T>` 和 `PageResult<T>`
  5. 审计日志使用 AOP 切面实现，不侵入业务逻辑代码
  6. Feign 客户端接口单独封装，业务层不直接感知远程调用细节

### NFR-004: 可扩展性

- **描述：** 管理中台应支持后续扩展更多管理功能。
- **指标：**
  1. 新增管理资源（如角色管理、权限管理、系统配置等）仅需新增 Controller 和 Service，不影响现有结构
  2. 审计日志操作类型枚举可扩展，新增操作类型无需修改切面逻辑
  3. 管理后台 API 统一前缀 `/api/v1/admin/`，保持一致的路径风格
  4. Feign 客户端接口按资源分类（多接口），避免单一接口过于庞大

### NFR-005: 测试覆盖率

- **描述：** 新增的 admin-service 模块和 auth-service 扩展应具备充分的单元测试覆盖。
- **指标：**
  1. admin-service 模块测试覆盖率：
     - Controller 层 → ≥ 80%
     - Service 层 → ≥ 85%
     - Filter/Interceptor → ≥ 80%
  2. auth-service 新增的 `AdminUserController` → ≥ 80%
  3. 关键测试场景：
     - 用户列表分页查询（含各种筛选条件组合）
     - 创建用户（成功/用户名重复/参数校验失败）
     - 启用/禁用用户（成功/禁用自身/禁用超级管理员）
     - 重置密码（成功/密码复杂度校验）
     - 角色分配（成功/无效角色 ID）
     - 管理员认证拦截（无 Token/无效 Token/非管理员角色）
     - 审计日志记录（成功/异常场景）

---

## 5. 技术栈选型（补充）

### 5.1 新增/变更依赖

| 组件/依赖 | 版本 | 用途 | 使用模块 |
|-----------|------|------|----------|
| spring-cloud-starter-openfeign | 2023.0.1 (继承 Cloud BOM) | 服务间远程调用（admin-service → auth-service） | admin-service |
| spring-cloud-starter-loadbalancer | 2023.0.1 (继承 Cloud BOM) | Feign 客户端负载均衡 | admin-service |
| cloudoffice-common | 0.0.1-SNAPSHOT | 公共模块依赖（统一响应体、BaseEntity、错误码等） | admin-service |

### 5.2 新增/变更配置

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `server.port` | 管理后台服务端口 | `9500` |
| `spring.application.name` | Nacos 服务注册名称 | `cloudoffice-admin-service` |
| `springdoc.api-docs.path` | API 文档路径 | `/api/v1/admin/v3/api-docs` |
| `app.admin.default-password` | 初始超级管理员密码（仅初始化使用） | `Admin@123456` |
| `app.admin.force-change-password` | 首次登录是否强制修改密码 | `true` |

### 5.3 新增数据库

| 数据库名 | 说明 |
|----------|------|
| `cloudstroll_office_admin` | 管理后台数据库（admin-service 独有） |

### 5.4 新增表汇总

| 表名 | 所属数据库 | 说明 |
|------|-----------|------|
| `t_admin_audit_log` | `cloudstroll_office_admin` | 管理员操作审计日志表（新增） |

### 5.5 变更表汇总

| 表名 | 所属数据库 | 变更类型 | 说明 |
|------|-----------|----------|------|
| `t_auth_role` | `cloudstroll_office_auth` | 数据初始化 | 预置 SUPER_ADMIN、SYSTEM_ADMIN 角色 |

---

## 6. 约束条件

### 6.1 技术约束

1. **JDK 版本：** 必须使用 Java 21 (OpenJDK 21 LTS)，不得使用更低版本
2. **构建工具：** 必须使用 Maven 3.9.x 进行项目构建
3. **数据库：** admin-service 使用独立数据库 `cloudstroll_office_admin` (MariaDB 10.6)
4. **缓存：** 使用 Redis 7.2.x，用户禁用/密码重置/角色变更时需清除 Redis 会话
5. **服务间通信：** admin-service 必须通过 OpenFeign 调用 auth-service，禁止直接访问 auth-service 的数据库
6. **密码加密：** 必须使用 BCrypt，不允许使用 MD5/SHA1 等

### 6.2 架构约束

1. **服务隔离：** admin-service 不直接操作 auth-service 的用户表、角色表等，所有用户数据操作通过 Feign 调用 auth-service 完成
2. **认证集中：** 管理员认证复用 auth-service 的 JWT 双 Token 机制，不单独创建管理员认证体系
3. **权限南向：** admin-service 负责权限校验和操作审计，auth-service 负责用户数据持久化
4. **网关路由：** 所有管理后台 API 通过 API 网关（gateway:9000）路由到 admin-service，不直接暴露 admin-service 端口到外部网络

### 6.3 规范约束

1. **API 路径规范：** 新增管理后台 API 统一前缀为 `/api/v1/admin/`
2. **错误码规范：** 新增管理后台错误码使用 `ADMIN-XXXX` 格式，统一管理
3. **DTO 规范：** 请求参数使用 `@Valid` 校验注解，响应统一使用 `ApiResult<T>`
4. **模块命名规范：** 新模块 `cloudoffice-admin-service`，包名 `org.cloudstrolling.cloudoffice.admin`
5. **敏感数据脱敏：** API 返回的手机号、邮箱等敏感信息需脱敏处理

### 6.4 安全约束

1. 所有管理后台 API 必须经过管理员身份认证，未认证请求返回 401
2. 非管理员角色访问管理后台 API 返回 403
3. 禁止禁用自身账号（Failsafe 机制）
4. 禁止禁用系统中唯一的超级管理员
5. 禁用用户、重置密码、角色变更等操作后必须清除该用户的 Redis 登录态会话
6. 关键操作必须记录审计日志，审计日志不可删除或修改

---

## 7. 假设与依赖

### 7.1 外部依赖

1. **Redis 服务：** 开发环境中需要部署并运行 Redis 7.2.x 服务，用于清除用户登录态
2. **MariaDB 服务：** 需要部署并运行 MariaDB 10.6，创建 `cloudstroll_office_admin` 数据库并执行 DDL 脚本
3. **Nacos 服务：** 需要部署并运行 Nacos 2.3.x，作为注册中心和配置中心
4. **auth-service API：** 需要 auth-service 正常运行并暴露用户管理的 REST API
5. **cloudoffice-common 公共模块：** 依赖 common 模块提供的 ApiResult、PageResult、BaseEntity 等公共组件
6. **RSA 公钥：** admin-service 需要获取 RSA 公钥用于验证 JWT Token 签名

### 7.2 环境假设

1. 开发人员本地已安装 JDK 21（OpenJDK 21 LTS）
2. 开发人员本地已安装 Maven 3.9.x，并正确配置 `settings.xml`
3. v0.1.6 阶段的认证服务代码已完成并可直接使用
4. Nacos、Redis、MariaDB 等基础设施在开发环境中已部署并运行
5. auth-service 的 JWT Token 使用 RS256 算法，RSA 公钥可配置共享

### 7.3 项目假设

1. **角色预置：** `SUPER_ADMIN` 和 `SYSTEM_ADMIN` 角色仅通过数据初始化脚本创建，不提供管理界面创建/编辑管理员角色（后续版本实现）
2. **前端分离：** 管理后台前端应用（Admin Console）是独立的 SPA 项目，不在本后端项目中开发；v0.1.7 仅完成后端 API，前端对接为独立任务
3. **端口规划：** admin-service 分配端口 9500，网关路由规则 `/api/v1/admin/**` → `cloudoffice-admin-service`
4. **初始管理员：** 初始化脚本创建默认超级管理员 `admin/Admin@123456`，部署后需立即修改密码
5. **用户数据一致性：** 用户相关数据一致性由 auth-service 保证，admin-service 不缓存用户数据
6. **Feign 调用鉴权：** admin-service 在 Feign 调用 auth-service 时，可使用 JWT Token 传播或内部服务专用 Token 进行鉴权
7. **权限控制粒度：** v0.1.7 仅做角色级别的粗粒度权限控制（具有 ADMIN 角色即可访问），细粒度操作权限控制在后续版本实现

---

## 8. 优先级汇总 (MoSCoW)

### 8.1 Must（必须有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-001 | 创建 admin-service 微服务模块 | admin-service |
| FR-002 | 管理中台 API 路径与网关路由 | gateway / admin-service |
| FR-003 | 管理员身份认证与权限校验 | admin-service |
| FR-005 | 用户列表查询 | admin-service / auth-service |
| FR-006 | 用户详情查看 | admin-service / auth-service |
| FR-007 | 新增用户 | admin-service / auth-service |
| FR-008 | 编辑用户信息 | admin-service / auth-service |
| FR-009 | 启用/禁用用户 | admin-service / auth-service |
| FR-010 | 重置用户密码 | admin-service / auth-service |
| FR-011 | 用户角色分配 | admin-service / auth-service |
| FR-012 | 用户管理对外 API（auth-service 扩展） | auth-service |
| FR-013 | OpenFeign 客户端（admin-service 端） | admin-service |
| FR-015 | 管理员角色预置与数据初始化 | auth-service (DB) |

### 8.2 Should（应该有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-004 | 管理员上下文与操作权限 | admin-service |
| FR-014 | 管理员操作审计日志 | admin-service |
| FR-016 | admin-service 独立数据库 | admin-service |

### 8.3 Could（可以有）

| 需求编号 | 需求名称 | 所属模块 |
|----------|----------|----------|
| FR-014 | 管理员操作审计日志（已提升至 Should） | admin-service |
| FR-016 | admin-service 独立数据库（已提升至 Should） | admin-service |

### 8.4 Won't（本期不做）

| 需求名称 | 说明 |
|----------|------|
| 管理后台前端 UI | 管理后台前端是独立的 SPA 项目，本期仅完成后端 API，前端开发为单独任务 |
| 角色管理界面 | 角色 CRUD 的管理界面（创建/编辑/删除角色及权限配置），后续版本实现 |
| 权限管理界面 | 权限点的管理和配置界面，后续版本实现 |
| 系统配置管理 | 系统级配置参数的管理界面（如登录策略配置、密码策略配置等），后续版本实现 |
| 操作日志查看界面 | 审计日志的查询和展示界面，本期后端实现 API，前端展示后续版本 |
| 管理员多租户隔离 | 不同租户的管理员只能管理本租户的用户，本期简化处理 |
| 批量用户操作 | 批量导入/导出用户、批量禁用等，后续版本实现 |
| 双因素认证（2FA） | 管理员登录的二次验证，后续版本实现 |
| 管理后台通知 | 系统公告、操作审批通知等，后续版本实现 |

---

## 9. 模块间依赖关系

```
v0.1.6 用户认证增强（cloudoffice-common、cloudoffice-auth-service）
         │
         ▼
v0.1.7 管理中台建设（变更范围）
         │
         ├── cloudoffice-admin-service             ← 新增模块
         │    ├── controller/
         │    │    ├── HealthController.java         新增（健康检查）
         │    │    ├── AdminUserController.java      新增（用户管理 API）
         │    │    └── AdminAuditLogController.java  新增（审计日志查询，Should）
         │    ├── service/
         │    │    ├── AdminUserService.java         新增（用户管理编排）
         │    │    ├── AdminAuditLogService.java     新增（审计日志，Should）
         │    │    └── impl/                         新增（实现类）
         │    ├── feign/
         │    │    └── AuthServiceClient.java        新增（Feign 客户端）
         │    ├── filter/
         │    │    └── AdminAuthFilter.java          新增（管理员认证过滤器）
         │    ├── entity/
         │    │    └── AdminAuditLogEntity.java      新增（审计日志实体，Should）
         │    ├── dto/                               新增（请求/响应 DTO）
         │    ├── vo/                                新增（管理后台 VO）
         │    ├── enums/
         │    │    └── AdminActionTypeEnum.java      新增（审计日志操作类型枚举，Should）
         │    ├── config/
         │    │    ├── FeignConfig.java              新增（Feign 配置）
         │    │    └── AdminWebConfig.java           新增（Web 配置/过滤器注册）
         │    └── util/
         │         └── AdminContext.java            新增（管理员上下文，Should）
         │
         ├── cloudoffice-auth-service               ← 扩展
         │    ├── controller/admin/
         │    │    └── AdminUserController.java      新增（管理员用户管理 API）
         │    ├── dto/admin/
         │    │    ├── AdminUserRequest.java         新增
         │    │    └── AdminUserVO.java              新增
         │    │    └── AdminUserDetailVO.java        新增
         │    ├── service/
         │    │    └── UserService.java              扩展（新增管理员相关查询方法）
         │    └── mapper/
         │         └── UserMapper.java               扩展（新增管理查询方法）
         │
         ├── cloudoffice-gateway                    ← 扩展
         │    └── application.yml                   扩展（添加 admin-service 路由规则）
         │
         └── scripts/sql/
              ├── init_admin_data.sql               新增（管理员角色和初始账号初始化脚本）
              └── schema_admin.sql                  新增（admin-service DDL 脚本，Should）

依赖关系：
  gateway → admin-service（路由转发）
  admin-service → auth-service（Feign 服务间调用）
  admin-service → common（Maven 依赖）
  admin-service → MariaDB（admin 数据库，审计日志）
  auth-service → MariaDB（auth 数据库，用户/角色数据）
  auth-service → Redis（会话管理，禁用/重置密码时清除会话）
```

---

## 10. 验收总体标准

1. 所有 Must 优先级需求必须全部完成并通过验收
2. 所有 Should 优先级需求应在资源允许的情况下尽量完成
3. 项目通过 `mvn clean compile -pl cloudoffice-admin-service,cloudoffice-auth-service -am` 编译无错误
4. admin-service 可正常启动，监听端口 9500，注册到 Nacos
5. 网关路由规则生效：`GET /api/v1/admin/health` 通过网关访问正常返回服务状态
6. **管理员登录：** 初始超级管理员账号（admin/Admin@123456）可通过 auth-service 正常登录，返回 JWT Token
7. **认证拦截：** 未携带 Token 或无效 Token 访问管理后台 API 返回 401；非管理员角色访问返回 403
8. **用户列表查询：** 按关键词、状态、角色、时间范围等条件分页查询用户，返回正确的分页结果和脱敏数据
9. **用户详情查看：** 按用户 ID 查询，返回完整的用户信息和角色列表
10. **新增用户：** 管理员创建用户成功，用户可正常登录；登录名重复时提示错误
11. **编辑用户信息：** 修改用户名、手机号、邮箱成功；手机号唯一性校验正常
12. **启用/禁用用户：** 禁用后用户无法登录；启用后恢复正常；禁止自禁用；禁止禁用唯一超级管理员
13. **重置密码：** 重置后用户使用新密码可登录，旧密码不可用
14. **角色分配：** 分配后用户权限立即生效（需重新登录）
15. **审计日志（Should）：** 关键操作正确记录审计日志，可通过 API 查询
16. 所有单元测试通过（`mvn test -pl cloudoffice-admin-service,cloudoffice-auth-service`）
17. 与 v0.1.6 的现有 API 保持向后兼容

---

## 附录 A：API 接口总览（新增/变更）

| 方法 | API 路径 | 说明 | 所属模块 | 优先级 |
|------|----------|------|----------|--------|
| GET | `/api/v1/admin/health` | 健康检查 | admin-service | Must |
| GET | `/api/v1/admin/users` | 分页查询用户列表 | admin-service | Must |
| GET | `/api/v1/admin/users/{userId}` | 查询用户详情 | admin-service | Must |
| POST | `/api/v1/admin/users` | 创建用户 | admin-service | Must |
| PUT | `/api/v1/admin/users/{userId}` | 编辑用户信息 | admin-service | Must |
| PUT | `/api/v1/admin/users/{userId}/status` | 启用/禁用用户 | admin-service | Must |
| PUT | `/api/v1/admin/users/{userId}/password/reset` | 重置用户密码 | admin-service | Must |
| PUT | `/api/v1/admin/users/{userId}/roles` | 分配用户角色 | admin-service | Must |
| GET | `/api/v1/admin/audit-logs` | 查询操作审计日志 | admin-service | Should |
| GET | `/api/v1/auth/admin/users` | [内部]分页查询用户列表 | auth-service | Must |
| GET | `/api/v1/auth/admin/users/{userId}` | [内部]查询用户详情 | auth-service | Must |
| POST | `/api/v1/auth/admin/users` | [内部]创建用户 | auth-service | Must |
| PUT | `/api/v1/auth/admin/users/{userId}` | [内部]编辑用户信息 | auth-service | Must |
| PUT | `/api/v1/auth/admin/users/{userId}/status` | [内部]启用/禁用用户 | auth-service | Must |
| PUT | `/api/v1/auth/admin/users/{userId}/password/reset` | [内部]重置密码 | auth-service | Must |
| PUT | `/api/v1/auth/admin/users/{userId}/roles` | [内部]分配角色 | auth-service | Must |

## 附录 B：错误码速查

| 错误码 | HTTP 状态码 | 说明 |
|--------|-------------|------|
| AUTH-0001 ~ AUTH-0033 | - | 沿用 v0.1.6 已有错误码 |
| ADMIN-0001 | 403 | 非管理员用户无权访问 |
| ADMIN-0002 | 404 | 用户不存在 |
| ADMIN-0003 | 400 | 不能禁用自身 |
| ADMIN-0004 | 400 | 不能禁用唯一的超级管理员 |
| ADMIN-0005 | 400 | 不能移除超级管理员的最后一个管理员角色 |
| ADMIN-0006 | 400 | 请求参数校验失败 |
| ADMIN-0007 | 401 | JWT Token 无效或已过期 |
