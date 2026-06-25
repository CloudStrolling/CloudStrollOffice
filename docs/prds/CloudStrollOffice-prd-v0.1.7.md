# PRD 文档

**项目中文名称：** 云漫智企
**项目名称：** CloudStrollOffice
**版本号：** v0.1.7
**日期：** 2026-06-24

---

## 1. 产品概述

### 1.1 项目背景

云漫智企（CloudStrollOffice）当前虽拥有完整的用户管理（UserService/UserMapper/UserEntity）和角色权限管理能力，但所有用户管理操作仅限于后端内部调用或注册流程触发，缺乏一个统一的管理后台（Admin Console）供系统管理员通过 Web 界面或专用 API 进行可视化的用户管理。管理员无法查看用户列表、搜索用户、了解用户状态，用户运营管理效率低下，管理操作存在安全隐患。

### 1.2 产品目标

- **业务目标**：搭建统一的管理中台微服务模块（`cloudoffice-admin-service`），提供可视化的用户管理能力，使系统管理员可通过 REST API 完成用户列表查询、新增用户、编辑用户、启用/禁用用户、重置密码、角色分配等核心 CRUD 操作
- **技术目标**：实现 admin-service 与 auth-service 之间的 OpenFeign 服务间通信，建立管理员身份认证与角色权限校验机制，并建立管理操作审计日志体系，确保管理操作可追溯

### 1.3 核心设计理念

- **权限南向**：admin-service 负责权限校验和操作审计，auth-service 负责用户数据持久化，服务间通过 OpenFeign 解耦，禁止跨服务直接访问数据库
- **安全隔离**：管理后台 API 与普通用户 API 严格分离，所有管理操作必须经过管理员身份认证和角色校验，关键操作需记录审计日志
- **可扩展架构**：管理后台采用统一 API 前缀 `/api/v1/admin/`，新增管理资源仅需新增 Controller 和 Service，不影响现有结构

### 1.4 术语表（Glossary）

| 术语 | 英文 | 定义 |
|------|------|------|
| 管理中台 | Admin Console | 统一的管理后台后端服务，提供用户管理、审计等管理功能 |
| 超级管理员 | SUPER_ADMIN | 拥有系统最高权限，可管理所有管理员和普通用户 |
| 系统管理员 | SYSTEM_ADMIN | 拥有用户管理的操作权限，可查看/编辑/启用/禁用用户等 |
| 审计日志 | Audit Log | 记录管理员关键操作的日志，用于操作追溯和安全审计 |
| OpenFeign | OpenFeign | Spring Cloud 声明式 HTTP 客户端，用于 admin-service 调用 auth-service |

---

## 2. 目标用户

| 用户角色 | 使用场景 | 核心诉求 |
|---------|---------|---------|
| 超级管理员 | 管理所有管理员和普通用户，进行用户创建/删除/角色分配等操作 | 拥有系统最高权限，可执行所有管理操作 |
| 系统管理员 | 日常用户管理，如查看用户列表、编辑用户信息、启用/禁用用户、重置密码 | 高效管理用户，可视化操作，减少人工干预 |
| 普通用户 | 通过前台应用注册和使用系统 | 不具备管理后台访问权限，不受管理操作影响 |
| 未认证请求者 | 未登录的匿名请求 | 无法访问任何管理后台 API，返回 401 Unauthorized |

---

## 3. 用户故事（User Stories）

### US-001: 创建 admin-service 微服务模块

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-001（创建 admin-service 微服务模块）

#### 故事描述
- **作为** 系统开发者
- **我想要** 创建 `cloudoffice-admin-service` 微服务模块，遵循项目标准包结构，注册到 Nacos 服务发现
- **以便** 为管理后台提供独立的后端服务，通过 API 网关路由访问

#### 前置条件
- 父项目 `pom.xml` 已存在，Maven 多模块架构已就绪
- Nacos 2.3.x 服务已部署并运行
- `cloudoffice-common` 公共模块已编译安装到本地 Maven 仓库

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 父项目 `pom.xml` 已存在，When 在父项目中注册 `<module>cloudoffice-admin-service</module>` 并创建模块目录结构，Then 模块 `artifactId` 为 `cloudoffice-admin-service`，包名为 `org.cloudstrolling.cloudoffice.admin`
- [ ] **AC2：** Given 模块结构已创建，When 执行 `mvn clean compile -pl cloudoffice-admin-service -am`，Then 编译通过无错误
- [ ] **AC3：** Given 模块配置了 `bootstrap.yml` 和 `application.yml`，When 启动 `AdminApplication`，Then 服务监听端口 9500，成功注册到 Nacos，健康检查端点 `GET /api/v1/admin/health` 返回服务状态

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| Nacos 服务不可用时启动 admin-service | 服务启动失败，打印连接 Nacos 失败的错误日志 |
| 端口 9500 已被占用 | 服务启动失败，抛端口冲突异常 |
| 依赖的 common 模块未编译 | Maven 编译失败，提示找不到依赖 |
| 网关路由未配置 | 服务可独立启动，但通过网关无法访问 |

#### 交付物
- `cloudoffice-admin-service/pom.xml` — 模块 POM 文件
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/AdminApplication.java` — 启动类
- `cloudoffice-admin-service/src/main/resources/bootstrap.yml` — Nacos 配置
- `cloudoffice-admin-service/src/main/resources/application.yml` — 应用配置
- `cloudoffice-admin-service/src/test/java/org/cloudstrolling/cloudoffice/admin/AdminApplicationTest.java` — 启动测试
- `cloudoffice-gateway/src/main/resources/application.yml` — 网关路由配置（变更）

#### 备注
- 模块端口规划：9500，与现有服务不冲突
- 遵循项目中台标准包结构：`config/`、`controller/`、`service/`、`service/impl/`、`entity/`、`dto/`、`vo/`、`enums/`、`exception/`、`filter/`、`interceptor/`、`mapper/`、`util/`

---

### US-002: 配置管理中台 API 路径与网关路由

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-002（管理中台 API 路径与网关路由）

#### 故事描述
- **作为** 系统开发者
- **我想要** 定义管理中台的统一 API 路径规范，并在 API 网关中配置路由规则
- **以便** 所有 `/api/v1/admin/**` 路径的请求统一转发到 admin-service，实现 RESTful 风格的管理后台 API

#### 前置条件
- `cloudoffice-gateway` 模块已存在并正常运行
- Nacos 服务发现已启用

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given API 路径规范已定义，When 访问健康检查端点 `GET /api/v1/admin/health` 通过网关，Then 请求被路由到 `cloudoffice-admin-service` 并返回服务状态信息
- [ ] **AC2：** Given 网关路由规则配置了负载均衡，When admin-service 多实例部署，Then 网关通过 Nacos 负载均衡分发请求到不同实例
- [ ] **AC3：** Given 用户管理 API 路径规范为 `/api/v1/admin/users`，When 管理员发起 HTTP 请求到该路径，Then 网关正确路由到 admin-service 的相应控制器

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| admin-service 未启动 | 网关返回 503 Service Unavailable |
| 请求路径不匹配任何路由规则 | 网关返回 404 Not Found |
| admin-service 实例全部下线 | 网关负载均衡器无可用实例，返回 503 |

#### 交付物
- `cloudoffice-gateway/src/main/resources/application.yml` — 网关路由配置（添加 admin-service 路由规则）

#### 备注
- 资源命名遵循 RESTful 风格：用户管理 → `/api/v1/admin/users`，健康检查 → `/api/v1/admin/health`
- 未来新增管理资源均使用 `/api/v1/admin/{resource}` 路径

---

### US-003: 实现管理员身份认证与权限校验

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-003（管理员身份认证与权限校验）

#### 故事描述
- **作为** 系统开发者
- **我想要** 在 admin-service 中实现管理员身份认证过滤器 `AdminAuthFilter`，对所有 `/api/v1/admin/**` 请求进行 JWT 解析和角色校验
- **以便** 确保只有拥有管理员角色（`SUPER_ADMIN` / `SYSTEM_ADMIN`）的用户才能访问管理后台 API

#### 前置条件
- `cloudoffice-admin-service` 模块已创建（US-001）
- auth-service 已签发包含 `roles` 信息的 JWT Token（RS256 算法）
- RSA 公钥可通过 Nacos 配置中心共享

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 请求未携带 `Authorization` 头，When 访问 `/api/v1/admin/users`，Then 返回 401 Unauthorized（错误码：`ADMIN-0007`）
- [ ] **AC2：** Given 请求携带无效或已过期的 JWT Token，When 访问管理后台 API，Then 返回 401 Unauthorized（错误码：`ADMIN-0007`）
- [ ] **AC3：** Given 请求携带有效 JWT Token 但用户角色为普通用户（不含 `SUPER_ADMIN` 或 `SYSTEM_ADMIN`），When 访问管理后台 API，Then 返回 403 Forbidden（错误码：`ADMIN-0001` 非管理员用户无权访问）
- [ ] **AC4：** Given 请求携带有效 JWT Token 且用户包含管理员角色，When 访问管理后台 API，Then 校验通过，请求继续处理，用户信息注入请求上下文
- [ ] **AC5：** Given 请求访问健康检查端点 `GET /api/v1/admin/health`，When 未携带任何 Token，Then 健康检查端点应排除认证拦截，正常返回服务状态

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| JWT Token 被篡改 | 签名验证失败，返回 401 Unauthorized |
| JWT Token 过期 | 解析 Token 时检测过期，返回 401 Unauthorized |
| Authorization 头格式错误（非 Bearer 开头） | 返回 401 Unauthorized |
| RSA 公钥加载失败 | 过滤器初始化失败，服务启动报错 |
| Token 中 roles 字段为空 | 视为无管理员角色，返回 403 Forbidden |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/filter/AdminAuthFilter.java` — 管理员认证过滤器
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/config/AdminWebConfig.java` — Web 配置/过滤器注册
- `cloudoffice-admin-service/src/main/resources/application.yml` — 白名单路径配置

#### 备注
- 健康检查端点、Swagger 文档路径等应列入认证白名单
- RSA 公钥通过 Nacos 配置中心共享，与 auth-service 共享同一套密钥对

---

### US-004: 建立管理员请求上下文与操作权限

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-004（管理员上下文与操作权限）

#### 故事描述
- **作为** 系统开发者
- **我想要** 在 admin-service 中建立管理员请求上下文（AdminContext），贯穿整个请求生命周期
- **以便** 业务逻辑能够获取当前操作者的身份信息，并在敏感操作中进行权限层级校验

#### 前置条件
- `AdminAuthFilter` 已实现并可解析 JWT Token 获取用户信息（US-003）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 管理员请求通过认证过滤器，When `AdminAuthFilter` 解析 Token 成功后设置 `AdminContext`，Then `AdminContext.getCurrentAdmin()` 返回包含 `adminId`、`adminName`、`realName`、`roles` 的上下文对象
- [ ] **AC2：** Given 请求处理完成（正常或异常返回），When 过滤器销毁或 `finally` 块执行 `AdminContext.clear()`，Then 上下文被清除，ThreadLocal 中不再持有该请求的用户信息
- [ ] **AC3：** Given 超级管理员执行操作，When 调用任意管理 API，Then 操作被允许执行
- [ ] **AC4：** Given 系统管理员执行禁止操作（如管理其他管理员），When 调用相关 API，Then 返回 403 错误码

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 未认证请求访问业务逻辑 | `AdminContext` 中无数据，业务层应识别并抛出认证异常 |
| 高并发请求下 ThreadLocal 污染 | 必须在 `finally` 块中调用 `clear()`，使用过滤器确保清除 |
| 异步请求中上下文丢失 | 当前版本不处理异步场景，确保同步请求上下文正确 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/util/AdminContext.java` — 管理员上下文（ThreadLocal）

#### 备注
- 上下文仅在同步请求中有效，异步任务需手动传递上下文（后续版本优化）
- 当前版本权限校验为角色级别粗粒度控制，后续版本可扩展为细粒度权限校验

---

### US-005: 实现用户列表查询

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-005（用户列表查询）

#### 故事描述
- **作为** 管理员（超级管理员/系统管理员）
- **我想要** 通过 `GET /api/v1/admin/users` 按条件分页查询用户列表，支持关键词搜索、状态筛选、角色筛选、注册时间范围筛选
- **以便** 快速定位和了解用户信息，进行高效的运营管理

#### 前置条件
- 管理员已登录并获取有效的 JWT Token（包含管理员角色）
- auth-service 的 `AdminUserController` 已暴露用户列表查询接口（US-012）
- admin-service 的 `AuthServiceClient` Feign 客户端已配置（US-013）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 管理员携带有效 Token，When 发送 `GET /api/v1/admin/users?page=1&size=10`，Then 返回 `PageResult<UserVO>` 包含第一页 10 条用户数据及总记录数
- [ ] **AC2：** Given 管理员发送 `GET /api/v1/admin/users?keyword=张三`，When 执行查询，Then 返回匹配"张三"的用户列表（匹配登录名、手机号、邮箱）
- [ ] **AC3：** Given 管理员发送 `GET /api/v1/admin/users?status=0`，When 执行查询，Then 返回所有状态为正常的用户
- [ ] **AC4：** Given 管理员发送 `GET /api/v1/admin/users?page=1&size=5`，When 无匹配数据，Then 返回空列表 `records: []`，`total: 0`
- [ ] **AC5：** Given 返回的用户数据中包含手机号和邮箱，When 查看 JSON 响应，Then 手机号脱敏显示（如 `138****1234`），邮箱脱敏显示（如 `u***@example.com`）
- [ ] **AC6：** Given 管理员传参 `size=200`，When 执行查询，Then 服务端限制最大 100 条，实际返回 100 条

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 不传任何筛选条件 | 返回全量用户的分页数据 |
| 页码或大小参数为负数 | 使用默认值（page=1, size=10）或返回参数校验错误 |
| Feign 调用 auth-service 超时 | 返回 500，错误码 `ADMIN-0006`，记录错误日志 |
| auth-service 返回错误响应 | 透传 auth-service 的错误信息和错误码 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminUserController.java` — 新增 `listUsers()` 方法
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/service/AdminUserService.java` — 用户管理服务
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/service/impl/AdminUserServiceImpl.java` — 用户管理服务实现
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/vo/UserVO.java` — 用户列表 VO（含脱敏处理）
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/dto/UserQueryRequest.java` — 用户查询参数 DTO

#### 备注
- 用户列表查询通过 Feign 调用 auth-service 实现，admin-service 不直接访问用户数据库
- 脱敏处理在 VO 层面实现，数据在 admin-service 中脱敏后再返回

---

### US-006: 查看用户详情

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-006（用户详情查看）

#### 故事描述
- **作为** 管理员（超级管理员/系统管理员）
- **我想要** 通过 `GET /api/v1/admin/users/{userId}` 查看特定用户的详细信息
- **以便** 了解用户的完整资料，包括角色分配、注册时间、最后登录时间等

#### 前置条件
- 管理员已登录并获取有效的 JWT Token
- 目标用户 ID 存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 存在用户 ID 为 1001 的活跃用户，When 管理员发送 `GET /api/v1/admin/users/1001`，Then 返回 `UserDetailVO` 包含用户完整信息（ID、登录名、真实姓名、角色列表、注册时间、最后登录时间等）
- [ ] **AC2：** Given 用户 ID 1001 不存在，When 管理员发送 `GET /api/v1/admin/users/1001`，Then 返回 404 Not Found（错误码：`ADMIN-0002` 用户不存在）
- [ ] **AC3：** Given 返回的用户数据中包含手机号和邮箱，When 查看响应，Then 手机号和邮箱已脱敏显示
- [ ] **AC4：** Given 用户有角色分配，When 查看详情，Then 角色列表中包含角色编码和角色名称

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| userId 参数为非数字 | 类型转换异常，返回 400 参数校验失败 |
| userId 为负数或 0 | 返回参数校验错误 |
| Feign 调用 auth-service 失败 | 透传错误，返回 500 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminUserController.java` — 新增 `getUserDetail()` 方法
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/vo/UserDetailVO.java` — 用户详情 VO

#### 备注
- UserDetailVO 包含比 UserVO 更完整的信息（如 `phoneVerified`、`emailVerified`、`lastLoginIp` 等）

---

### US-007: 新增用户

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-007（新增用户）

#### 故事描述
- **作为** 管理员（超级管理员/系统管理员）
- **我想要** 通过 `POST /api/v1/admin/users` 创建新用户，指定登录名、姓名、密码，并可选择分配角色
- **以便** 为新员工或外部人员创建系统账号，创建后用户可立即使用

#### 前置条件
- 管理员已登录并获取有效的 JWT Token
- 租户内登录名唯一性约束已建立

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 管理员提供完整的用户信息（loginName=zhangsan, userName=张三, password=Pass1234, phone=13812345678），When 发送 `POST /api/v1/admin/users`，Then 创建成功，返回新用户基本信息（ID、登录名、姓名、角色），注册模式为 `ADMIN_CREATE`，`accountSettled` 为已完善
- [ ] **AC2：** Given 管理员尝试创建登录名已存在的用户，When 发送创建请求，Then 返回错误提示登录名已存在（错误码：`ADMIN-0006`）
- [ ] **AC3：** Given 管理员提供密码 `123`（不足 8 位），When 发送创建请求，Then 返回密码复杂度校验失败错误
- [ ] **AC4：** Given 管理员创建用户时传入了 `roleIds=[1,2]`，When 创建成功，Then 用户已关联角色 ID 为 1 和 2 的角色
- [ ] **AC5：** Given 管理员创建用户成功，When 查看审计日志，Then 记录"管理员 {adminName} 创建了用户 zhangsan"

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 必填字段（loginName/userName/password）缺失 | 返回 400，提示必填字段不能为空 |
| 手机号格式不合法 | 返回 400，提示手机号格式错误 |
| 邮箱格式不合法 | 返回 400，提示邮箱格式错误 |
| roleIds 中包含不存在的角色 ID | 返回错误，提示角色 ID 不合法 |
| loginName 包含特殊字符 | 返回参数校验错误，提示登录名格式要求 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminUserController.java` — 新增 `createUser()` 方法
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/dto/CreateUserRequest.java` — 创建用户请求 DTO

#### 备注
- 密码使用 BCrypt 加密后存储
- 审计日志通过 `@AdminAuditLog` 注解 AOP 实现（US-014）

---

### US-008: 编辑用户信息

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-008（编辑用户信息）

#### 故事描述
- **作为** 管理员（超级管理员/系统管理员）
- **我想要** 通过 `PUT /api/v1/admin/users/{userId}` 编辑用户的基本信息（真实姓名、手机号、邮箱）
- **以便** 更新用户资料，保持用户信息的准确性

#### 前置条件
- 管理员已登录并获取有效的 JWT Token
- 目标用户 ID 存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户 ID 1001 存在且手机号为 13800000001，When 管理员发送 `PUT /api/v1/admin/users/1001` 修改手机号为 13900000001，Then 更新成功，返回更新后的用户信息，手机号变更为 13900000001
- [ ] **AC2：** Given 用户 ID 9999 不存在，When 管理员发送编辑请求，Then 返回 404 Not Found（错误码：`ADMIN-0002` 用户不存在）
- [ ] **AC3：** Given 新手机号已被其他用户使用，When 管理员发送编辑请求，Then 返回错误提示手机号已被占用
- [ ] **AC4：** Given 管理员尝试修改 `loginName` 或 `password`，When 发送编辑请求，Then 请求中的 loginName 和 password 字段被忽略，不进行修改

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 不传任何可选字段 | 用户信息不变，返回当前用户信息 |
| 邮箱格式不合法 | 返回 400 参数校验失败 |
| 只传 email 字段 | 仅更新邮箱，用户名和手机号保持不变 |
| 编辑自身账号信息 | 允许操作，但需在审计日志中记录 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminUserController.java` — 新增 `updateUser()` 方法
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/dto/UpdateUserRequest.java` — 更新用户请求 DTO

#### 备注
- 不允许修改 `loginName` 和 `password`（密码通过专用接口重置）
- 审计日志记录修改操作

---

### US-009: 启用/禁用用户

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-009（启用/禁用用户）

#### 故事描述
- **作为** 管理员（超级管理员/系统管理员）
- **我想要** 通过 `PUT /api/v1/admin/users/{userId}/status` 启用或禁用用户账号
- **以便** 管理用户访问权限，禁用异常账号或恢复正常账号的使用

#### 前置条件
- 管理员已登录并获取有效的 JWT Token
- 目标用户 ID 存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 正常用户 ID 1001，When 管理员发送 `PUT /api/v1/admin/users/1001/status` 设置 `status=1`（禁用），Then 用户状态变更为禁用，该用户所有 Redis 登录态会话被清除
- [ ] **AC2：** Given 被禁用用户 ID 1001，When 管理员发送 `PUT /api/v1/admin/users/1001/status` 设置 `status=0`（启用），Then 用户状态恢复为正常，用户可正常登录
- [ ] **AC3：** Given 管理员尝试禁用自身，When 发送禁用请求，Then 返回 400（错误码：`ADMIN-0003` 不能禁用自身）
- [ ] **AC4：** Given 系统中只有一个超级管理员，When 尝试禁用该超级管理员，Then 返回 400（错误码：`ADMIN-0004` 不能禁用唯一的超级管理员）
- [ ] **AC5：** Given 用户 ID 9999 不存在，When 发送禁用请求，Then 返回 404（错误码：`ADMIN-0002` 用户不存在）

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| status 参数值不是 0 或 1 | 返回 400 参数校验失败 |
| 禁用已禁用的用户 | 操作成功，状态保持不变（幂等） |
| 启用已启用的用户 | 操作成功，状态保持不变（幂等） |
| 禁用操作时 Redis 连接失败 | 数据库状态更新成功，Redis 清除操作失败需记录警告日志 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminUserController.java` — 新增 `updateUserStatus()` 方法
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/dto/UpdateUserStatusRequest.java` — 状态更新请求 DTO

#### 备注
- 禁用操作必须同步清除该用户的 Redis 登录态会话（强制登出）
- 通过审计日志记录禁用原因（可选字段）

---

### US-010: 重置用户密码

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-010（重置用户密码）

#### 故事描述
- **作为** 管理员（超级管理员/系统管理员）
- **我想要** 通过 `PUT /api/v1/admin/users/{userId}/password/reset` 重置指定用户的密码
- **以便** 用户忘记密码时可由管理员协助重置，或强制更新弱密码账号

#### 前置条件
- 管理员已登录并获取有效的 JWT Token
- 目标用户 ID 存在

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户 ID 1001 存在，When 管理员发送 `PUT /api/v1/admin/users/1001/password/reset` 设置新密码 `NewPwd@123`（确认密码相同），Then 密码更新成功，用户所有 Redis 登录态会话被清除，返回操作成功
- [ ] **AC2：** Given 管理员设置的新密码 `123`（长度不足 8 位），When 发送重置请求，Then 返回密码复杂度校验失败错误
- [ ] **AC3：** Given 管理员设置的 `newPassword` 与 `confirmPassword` 不一致，When 发送重置请求，Then 返回参数校验失败错误
- [ ] **AC4：** Given 用户 ID 9999 不存在，When 发送重置请求，Then 返回 404（错误码：`ADMIN-0002` 用户不存在）
- [ ] **AC5：** Given 密码重置成功后，When 用户使用旧密码登录，Then 登录失败；When 使用新密码登录，Then 登录成功

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 新密码与历史密码相同 | 已有密码策略校验，允许设置相同密码（无历史密码约束） |
| 密码在日志中明文输出 | 禁止，所有日志中密码字段必须替换为 `******` |
| 重置密码时 Redis 连接失败 | 数据库密码更新成功，Redis 清除操作失败需记录警告日志 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminUserController.java` — 新增 `resetPassword()` 方法
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/dto/ResetPasswordRequest.java` — 重置密码请求 DTO

#### 备注
- 密码不在日志、响应体、异常信息中明文输出
- 重置后清除 Redis 会话，强制用户重新登录
- 更新 `lastPasswordChangeTime` 字段

---

### US-011: 用户角色分配

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-011（用户角色分配）

#### 故事描述
- **作为** 管理员（超级管理员/系统管理员）
- **我想要** 通过 `PUT /api/v1/admin/users/{userId}/roles` 为用户分配角色（全量替换）
- **以便** 调整用户的权限范围，确保用户拥有合适的角色

#### 前置条件
- 管理员已登录并获取有效的 JWT Token
- 目标用户 ID 存在
- 角色数据已初始化（US-015）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 用户 ID 1001 当前没有角色，When 管理员发送 `PUT /api/v1/admin/users/1001/roles` 设置 `roleIds=[1,2]`，Then 用户成功关联角色 1 和 2
- [ ] **AC2：** Given 用户 ID 1001 当前有角色 [1,2]，When 管理员发送 `PUT /api/v1/admin/users/1001/roles` 设置 `roleIds=[3]`，Then 用户角色被全量替换为 [3]，不再拥有角色 1 和 2
- [ ] **AC3：** Given 管理员发送 `roleIds=[]`（空数组），When 为用户分配角色，Then 用户的所有角色被移除
- [ ] **AC4：** Given 管理员尝试移除超级管理员的最后一个管理员角色，When 发送分配请求，Then 返回 400（错误码：`ADMIN-0005` 不能移除超级管理员的最后一个管理员角色）
- [ ] **AC5：** Given 角色 ID 9999 不存在，When 发送分配请求，Then 返回错误提示角色 ID 不合法

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| roleIds 参数为 null（必须传） | 返回 400，提示 roleIds 不能为空 |
| 用户不存在 | 返回 404（错误码：`ADMIN-0002`） |
| 角色分配成功后 Redis 会话清除 | 清除该用户的 Redis 登录态，强制重新登录使角色变更生效 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminUserController.java` — 新增 `assignRoles()` 方法
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/dto/AssignRolesRequest.java` — 角色分配请求 DTO

#### 备注
- 全量替换策略（先删后增），非增量添加
- 角色变更后清除 Redis 会话，角色变更立即生效（需用户重新登录）

---

### US-012: 用户管理对外 API（auth-service 扩展）

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-012（用户管理对外 API - auth-service 扩展）

#### 故事描述
- **作为** 系统开发者
- **我想要** 在 auth-service 中新增 `AdminUserController`，提供管理员专用的用户管理 REST API 端点
- **以便** admin-service 通过 OpenFeign 调用这些端点进行用户数据操作，且这些端点仅限服务间内部调用

#### 前置条件
- auth-service 的 `UserService`、`UserMapper` 等已有基础 CRUD 方法
- `RoleService` 可提供角色查询和分配功能
- `LoginSessionService` 可清除用户的 Redis 会话

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given admin-service 通过 Feign 调用 `GET /api/v1/auth/admin/users`，When 传递分页参数和筛选条件，Then 返回分页的用户列表数据（含角色信息）
- [ ] **AC2：** Given admin-service 通过 Feign 调用 `POST /api/v1/auth/admin/users`，When 传递创建用户请求，Then 用户被创建，密码 BCrypt 加密，`registerMode` 为 `ADMIN_CREATE`，返回用户基本信息
- [ ] **AC3：** Given admin-service 通过 Feign 调用 `PUT /api/v1/auth/admin/users/{userId}/status`，When 传递禁用状态，Then 用户状态更新为禁用，Redis 会话被清除
- [ ] **AC4：** Given admin-service 通过 Feign 调用 `PUT /api/v1/auth/admin/users/{userId}/roles`，When 传递角色 ID 列表，Then 用户角色被全量替换
- [ ] **AC5：** Given 非 admin-service 的外部请求，When 直接访问 `/api/v1/auth/admin/users`，Then 请求被拒绝（通过内部网络限制或管理员 Token 校验）

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| Feign 调用传递无效参数 | 返回参数校验错误 |
| 用户数据操作涉及租户隔离 | 当前版本简化处理，不强制租户隔离 |
| 批量操作请求超时 | Feign 配置连接超时 5s，读取超时 10s |

#### 交付物
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/controller/admin/AdminUserController.java` — 管理员用户管理控制器（新增）
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/admin/AdminUserRequest.java` — 管理后台用户请求 DTO
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/admin/AdminUserVO.java` — 管理后台用户列表 VO
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/dto/admin/AdminUserDetailVO.java` — 管理后台用户详情 VO
- `cloudoffice-auth-service/src/main/java/org/cloudstrolling/cloudoffice/auth/service/impl/UserServiceImpl.java` — 扩展（新增管理员专用查询方法）

#### 备注
- 新增 `controller/admin/` 子包单独存放管理员控制器，与普通认证控制器分离
- 所有端点使用统一响应格式 `ApiResult<T>` 和 `PageResult<AdminUserVO>`
- 错误码复用已有的 `AUTH-XXXX` 错误码体系

---

### US-013: OpenFeign 客户端（admin-service 端）

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-013（OpenFeign 客户端 - admin-service 端）

#### 故事描述
- **作为** 系统开发者
- **我想要** 在 admin-service 中创建 OpenFeign 客户端接口 `AuthServiceClient`
- **以便** admin-service 通过声明式 HTTP 客户端调用 auth-service 的用户管理 API，实现服务间解耦

#### 前置条件
- auth-service 已暴露 `AdminUserController` API（US-012）
- Nacos 服务发现已启用
- Maven 依赖 `spring-cloud-starter-openfeign` 和 `spring-cloud-starter-loadbalancer` 已引入

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given admin-service 需要查询用户列表，When 调用 `AuthServiceClient.listUsers(params)`，Then Feign 客户端正确发起 HTTP 请求到 `cloudoffice-auth-service`，返回 `ApiResult<PageResult<AdminUserVO>>`
- [ ] **AC2：** Given admin-service 需要创建用户，When 调用 `AuthServiceClient.createUser(request)`，Then Feign 客户端正确传递请求体到 auth-service 的 `POST /api/v1/auth/admin/users`
- [ ] **AC3：** Given admin-service 调用 auth-service 时，When Feign 请求拦截器生效，Then 请求头中携带管理员身份 Token，auth-service 可识别调用来源
- [ ] **AC4：** Given admin-service 启动时，When Spring 容器初始化，Then Feign 客户端被正确扫描并注册为 Bean
- [ ] **AC5：** Given auth-service 服务不可用，When admin-service 发起 Feign 调用，Then 触发降级处理（返回熔断或错误响应）

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| auth-service 调用超时 | Feign 连接超时 5s，读取超时 10s，超时后抛出异常 |
| auth-service 返回 4xx/5xx | Feign 将 HTTP 错误码转换为 FeignException，admin-service 需捕获处理 |
| auth-service 实例全部下线 | 负载均衡器无可用实例，Feign 调用失败 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/feign/AuthServiceClient.java` — Feign 客户端接口
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/config/FeignConfig.java` — Feign 配置类（含请求拦截器）
- `cloudoffice-admin-service/pom.xml` — 添加 OpenFeign 和 LoadBalancer 依赖

#### 备注
- Feign 客户端接口按资源分类，避免单一接口过于庞大
- 请求拦截器在 Feign 调用 auth-service 时传递管理员身份 Token 或内部服务专用 Token

---

### US-014: 管理员操作审计日志

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-014（管理员操作审计日志）

#### 故事描述
- **作为** 系统管理员
- **我想要** 系统自动记录管理员在管理后台的关键操作行为（创建用户、禁用用户、重置密码、角色分配等）
- **以便** 操作可追溯，满足安全审计需求

#### 前提条件
- admin-service 独立数据库 `cloudstroll_office_admin` 已创建（US-016）
- `t_admin_audit_log` 表已通过 DDL 脚本创建
- `AdminContext` 已正确设置当前管理员信息（US-004）

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 管理员创建了一个新用户，When 操作成功完成，Then `t_admin_audit_log` 表中新增一条记录，包含管理员 ID、操作类型 `CREATE_USER`、目标用户 ID、操作结果成功
- [ ] **AC2：** Given 管理员禁用用户时操作失败（如用户不存在），When 操作抛出异常，Then 审计日志记录操作失败及错误信息
- [ ] **AC3：** Given 管理员通过 `GET /api/v1/admin/audit-logs` 查询审计日志，When 传递时间范围、操作类型、管理员 ID 等筛选条件，Then 返回分页的审计日志列表
- [ ] **AC4：** Given 审计日志已记录，When 尝试修改或删除审计日志，Then 不允许修改或删除操作（仅插入和查询）

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 审计日志插入失败（数据库异常） | 使用 try-catch 异常隔离，记录错误日志，不影响主业务操作 |
| 审计日志表数据量过大 | 通过分页查询限制单次返回数量，后续可考虑定时归档 |
| 操作详情 JSON 字段超长 | 截断至 1024 字符后存储 |

#### 交付物
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/entity/AdminAuditLogEntity.java` — 审计日志实体
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/enums/AdminActionTypeEnum.java` — 操作类型枚举
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/mapper/AdminAuditLogMapper.java` — 审计日志 Mapper
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/service/AdminAuditLogService.java` — 审计日志服务
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/annotation/AdminAuditLog.java` — 审计日志注解
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/aspect/AdminAuditLogAspect.java` — 审计日志切面
- `cloudoffice-admin-service/src/main/java/org/cloudstrolling/cloudoffice/admin/controller/AdminAuditLogController.java` — 审计日志查询接口
- `scripts/sql/schema_admin.sql` — admin-service DDL 脚本（新增 `t_admin_audit_log` 表）

#### 备注
- 使用 Spring AOP（`@AdminAuditLog` 注解）实现，不侵入业务逻辑代码
- 操作类型枚举预留扩展：`DELETE_USER`、`SYSTEM_CONFIG` 等
- 审计日志不可被修改或删除

---

### US-015: 管理员角色预置与数据初始化

**优先级：** 高
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-015（管理员角色预置与数据初始化）

#### 故事描述
- **作为** 系统开发者
- **我想要** 在 `t_auth_role` 表中预置管理员角色（`SUPER_ADMIN`、`SYSTEM_ADMIN`），并创建初始超级管理员账号
- **以便** 部署后系统即可拥有管理员账号，管理员可直接登录管理后台进行用户管理

#### 前置条件
- `t_auth_role`、`t_auth_user`、`t_auth_user_role` 表已通过 DDL 创建
- auth-service 数据库 `cloudstroll_office_auth` 已创建

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 数据库初始化脚本已执行，When 查询 `t_auth_role` 表，Then 存在两条记录：`SUPER_ADMIN`（超级管理员）和 `SYSTEM_ADMIN`（系统管理员）
- [ ] **AC2：** Given 初始化脚本已执行，When 查询 `t_auth_user` 表，Then 存在一条记录：`loginName=admin`，`userName=系统管理员`，密码使用 BCrypt 加密
- [ ] **AC3：** Given 初始管理员账号已创建，When 查询 `t_auth_user_role` 表，Then admin 用户已关联 `SUPER_ADMIN` 角色
- [ ] **AC4：** Given 初始化脚本已执行，When 使用 `admin/Admin@123456` 通过 auth-service 登录，Then 登录成功，返回的 JWT Token 中包含 `SUPER_ADMIN` 角色
- [ ] **AC5：** Given 普通用户通过注册接口注册，When 角色查询，Then 不会自动获得 `SUPER_ADMIN` 或 `SYSTEM_ADMIN` 管理员角色

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 初始化脚本重复执行 | 使用 `INSERT IGNORE` 或 `IF NOT EXISTS` 避免重复插入 |
| 初始密码在生产环境使用 | 强烈建议首次登录后强制修改密码 |
| 数据库字符集不支持中文 | 初始化脚本中设置 UTF-8 字符集 |

#### 交付物
- `scripts/sql/init_admin_data.sql` — 管理员角色和初始账号初始化脚本

#### 备注
- 初始超级管理员账号：`loginName=admin`，`password=Admin@123456`
- 初始密码在首次登录后应强制修改（通过配置项 `app.admin.force-change-password` 控制）

---

### US-016: admin-service 独立数据库

**优先级：** 中
**关联需求：**
需求文档：`docs/requires/CloudStrollOffice-requirement-v0.1.7.md`
需求编号：FR-016（admin-service 独立数据库）

#### 故事描述
- **作为** 系统开发者
- **我想要** admin-service 拥有独立的数据库 `cloudstroll_office_admin`
- **以便** 存储管理后台相关的数据（如审计日志），实现微服务数据库独立原则

#### 前置条件
- MariaDB 10.6 服务已部署并运行

#### 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 数据库 `cloudstroll_office_admin` 已创建，When admin-service 启动，Then 数据源配置正确加载，数据库连接成功
- [ ] **AC2：** Given DDL 脚本已执行，When 查询 `cloudstroll_office_admin` 数据库，Then `t_admin_audit_log` 表已创建，表结构与需求定义一致
- [ ] **AC3：** Given admin-service 已启动，When 执行管理操作触发审计日志，Then 数据写入 `cloudstroll_office_admin.t_admin_audit_log` 表
- [ ] **AC4：** Given admin-service 需要用户数据，When 业务逻辑执行，Then 通过 Feign 调用 auth-service 获取，不直接访问 auth-service 的数据库

#### 边界情况与错误处理
| 场景 | 预期行为 |
|------|---------|
| 数据库连接失败 | admin-service 启动失败，打印连接超时或拒绝访问的错误日志 |
| 表结构不匹配 | MyBatis-Plus 实体映射失败，启动时报错 |
| DDL 脚本执行失败 | 需手动检查 SQL 语句和数据库权限 |

#### 交付物
- `cloudoffice-admin-service/src/main/resources/application.yml` — 数据源配置
- `scripts/sql/schema_admin.sql` — admin-service DDL 脚本（`t_admin_audit_log` 表）

#### 备注
- 用户相关数据不在 admin-service 数据库维护，通过 Feign 调用 auth-service 操作
- 遵循项目数据库设计原则：数据库独立、雪花算法主键、公共字段统一

---

## 4. 非功能性需求（Non-Functional Requirements）

### 4.1 性能

| 指标 | 要求 |
|------|------|
| 用户列表查询（带分页，10000 用户规模） | 响应时间 ≤ 1000ms |
| 用户详情查询 | 响应时间 ≤ 200ms |
| 新增/编辑用户 | 响应时间 ≤ 500ms |
| 启用/禁用用户（含清除 Redis 会话） | 响应时间 ≤ 1000ms |
| 重置密码（含 BCrypt 加密和清除会话） | 响应时间 ≤ 500ms |
| Feign 调用超时 | 连接超时 5s，读取超时 10s |

### 4.2 可用性

- 管理后台 API 使用简体中文作为错误提示语言
- 错误响应体统一使用 `ApiResult<T>` 格式，包含错误码和中文错误描述
- API 响应统一返回标准 HTTP 状态码（200/400/401/403/404/500）

### 4.3 可靠性

- Feign 调用 auth-service 失败时，admin-service 需捕获异常并返回友好的错误信息
- 审计日志插入失败不影响主业务操作（try-catch 异常隔离）
- 禁用用户、重置密码、角色分配等关键操作需保证数据一致性（数据库状态更新 + Redis 会话清除）

### 4.4 安全性

- 所有管理后台 API 必须验证管理员身份，未授权请求返回 401
- 非管理员角色访问管理后台 API 返回 403（错误码：`ADMIN-0001`）
- 用户密码使用 BCrypt 加密存储，不在日志、响应体、异常信息中明文输出
- 用户手机号、邮箱在日志和 API 响应中脱敏显示（如 `138****1234`）
- 关键操作（创建用户、禁用用户、重置密码、角色分配）必须记录审计日志
- 禁用用户、重置密码、角色变更后必须清除该用户的 Redis 登录态会话
- 禁止禁用自身账号
- 禁止禁用系统中唯一的超级管理员
- 禁止移除超级管理员的最后一个管理员角色

### 4.5 可维护性

- admin-service 遵循 project.md 定义的标准包结构
- 使用构造器注入，禁止 `@Autowired` 字段注入
- API 路径遵循规范：`/api/v1/admin/{resource}`
- 响应统一使用 `ApiResult<T>` 和 `PageResult<T>`
- 审计日志使用 AOP 切面实现，不侵入业务逻辑代码
- Feign 客户端接口单独封装，业务层不直接感知远程调用细节
- 新增管理资源（如角色管理、权限管理等）仅需新增 Controller 和 Service，不影响现有结构

---

## 5. 附录

### 5.1 API 接口总览（新增/变更）

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

### 5.2 新增错误码

| 错误码 | HTTP 状态码 | 说明 |
|--------|-------------|------|
| ADMIN-0001 | 403 | 非管理员用户无权访问 |
| ADMIN-0002 | 404 | 用户不存在 |
| ADMIN-0003 | 400 | 不能禁用自身 |
| ADMIN-0004 | 400 | 不能禁用唯一的超级管理员 |
| ADMIN-0005 | 400 | 不能移除超级管理员的最后一个管理员角色 |
| ADMIN-0006 | 400 | 请求参数校验失败 |
| ADMIN-0007 | 401 | JWT Token 无效或已过期 |

### 5.3 新增/变更配置

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| `server.port` | 管理后台服务端口 | `9500` |
| `spring.application.name` | Nacos 服务注册名称 | `cloudoffice-admin-service` |
| `springdoc.api-docs.path` | API 文档路径 | `/api/v1/admin/v3/api-docs` |
| `app.admin.default-password` | 初始超级管理员密码（仅初始化使用） | `Admin@123456` |
| `app.admin.force-change-password` | 首次登录是否强制修改密码 | `true` |

### 5.4 用户故事与需求映射

| 用户故事 | 关联需求 | 优先级 | 涉及模块 |
|----------|----------|--------|----------|
| US-001 | FR-001 | Must | admin-service |
| US-002 | FR-002 | Must | gateway / admin-service |
| US-003 | FR-003 | Must | admin-service |
| US-004 | FR-004 | Should | admin-service |
| US-005 | FR-005 | Must | admin-service / auth-service |
| US-006 | FR-006 | Must | admin-service / auth-service |
| US-007 | FR-007 | Must | admin-service / auth-service |
| US-008 | FR-008 | Must | admin-service / auth-service |
| US-009 | FR-009 | Must | admin-service / auth-service |
| US-010 | FR-010 | Must | admin-service / auth-service |
| US-011 | FR-011 | Must | admin-service / auth-service |
| US-012 | FR-012 | Must | auth-service |
| US-013 | FR-013 | Must | admin-service |
| US-014 | FR-014 | Should | admin-service |
| US-015 | FR-015 | Must | auth-service (DB) |
| US-016 | FR-016 | Should | admin-service |
