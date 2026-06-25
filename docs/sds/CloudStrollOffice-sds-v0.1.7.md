# 软件设计规格说明书（SDS）

**项目中文名称：** 云漫智企
**项目英文名：** CloudStrollOffice
**版本号：** v0.1.7
**日期：** 2026-06-24

---

## 1. 技术方案概述

### 1.1 系统定位

云漫智企（CloudStrollOffice）v0.1.7 阶段新增**管理中台服务（`cloudoffice-admin-service`）**，旨在为系统管理员提供统一的管理后台后端服务。该模块定位为管理和运营中心，解决以下核心问题：

- **管理能力缺失**：现有系统虽有完整的用户管理和角色权限模型，但缺乏面向管理员的可视化操作接口
- **安全隔离不足**：管理操作与普通用户操作混合，存在越权和管理风险
- **可追溯性缺失**：管理员的关键操作（创建用户、禁用账号、重置密码等）缺乏审计记录

本阶段目标是搭建安全的、可审计的管理中台，通过 OpenFeign 与 auth-service 解耦通信，实现管理操作的安全管控和全流程可追溯。

### 1.2 架构风格

- **微服务架构（Microservices Architecture）**：管理中台作为独立微服务部署，与认证服务（auth-service）通过 OpenFeign 声明式 HTTP 客户端通信
- **分层架构**：Controller → Service → Feign Client（调用 auth-service）/ Mapper（操作 admin 本地数据库）
- **过滤器链模式**：通过 `AdminAuthFilter` 对管理 API 请求进行统一的 JWT 解析和角色权限校验
- **AOP 面向切面编程**：使用 `@AdminAuditLog` 注解 + AOP 切面实现审计日志的无侵入记录

**架构层次关系：**

```
[管理员客户端]
      │
      ▼
[API 网关 :9000] ── 路由转发 /api/v1/admin/** → admin-service
      │
      ▼
[cloudoffice-admin-service :9500]
      │
      ├── AdminAuthFilter（JWT 解析 + 角色校验）
      ├── AdminContext（ThreadLocal 请求上下文）
      ├── Controller → AdminUserService → AuthServiceClient（OpenFeign）→ auth-service
      │                                           └── AdminAuditLogService → MariaDB (admin 库)
      └── @AdminAuditLog AOP 切面（自动记录审计日志）
```

### 1.3 核心工作流

**管理员请求处理流程（核心工作流）：**

```
① 管理员携带 JWT Token 发起请求 → GET /api/v1/admin/users
② 网关路由转发（/api/v1/admin/** → admin-service:9500）
③ AdminAuthFilter 拦截：
   ├─ 白名单放行（health 端点）
   ├─ 解析 JWT Claims（RS256 公钥验签）
   ├─ 校验 roles 是否包含 SUPER_ADMIN 或 SYSTEM_ADMIN
   └─ 校验通过 → 设置 AdminContext（ThreadLocal）
④ Controller 接收请求 → Service 层
   ├─ 只读操作（列表/详情查询）→ AuthServiceClient Feign 调用 auth-service
   └─ 写操作（创建/编辑/禁用/重置密码/角色分配）→ AuthServiceClient + @AdminAuditLog 审计日志记录
⑤ 请求结束 → AdminContext.clear()
⑥ 返回统一响应 ApiResult<T>
```

### 1.4 关键设计原则

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| **权限南向** | admin-service 负责权限校验和操作审计，auth-service 负责用户数据持久化 | admin-service 通过 OpenFeign 调用 auth-service，禁止跨服务直接访问数据库 |
| **安全隔离** | 管理后台 API 与普通用户 API 严格分离，所有管理操作必须经过管理员身份认证和角色校验 | 统一 API 前缀 `/api/v1/admin/`，通过网关路由隔离，`AdminAuthFilter` 认证+角色校验 |
| **零侵入审计** | 审计日志不侵入业务逻辑代码 | `@AdminAuditLog` 注解 + AOP 面向切面编程实现 |
| **微服务数据库独立** | 每个微服务拥有独立数据库 | admin-service 独立数据库 `cloudstroll_office_admin`，仅存储审计日志等管理数据 |
| **可扩展架构** | 新增管理资源不影响现有结构 | 统一 API 前缀，新增资源仅需新增 Controller 和 Service |

### 1.5 对应 PRD UserStory 一览

| 编号 | 技术方案覆盖 |
|------|-------------|
| **US-001** | 创建 admin-service 微服务模块 → 2.1 节 |
| **US-002** | 配置管理中台 API 路径与网关路由 → 2.2 节、4.1 节 |
| **US-003** | 管理员身份认证与权限校验 → 5.1 节 |
| **US-004** | 管理员请求上下文与操作权限 → 5.2 节 |
| **US-005** | 用户列表查询 → 4.2.1 节 |
| **US-006** | 用户详情查看 → 4.2.2 节 |
| **US-007** | 新增用户 → 4.2.3 节 |
| **US-008** | 编辑用户信息 → 4.2.4 节 |
| **US-009** | 启用/禁用用户 → 4.2.5 节 |
| **US-010** | 重置用户密码 → 4.2.6 节 |
| **US-011** | 用户角色分配 → 4.2.7 节 |
| **US-012** | 用户管理对外 API（auth-service 扩展）→ 4.3 节 |
| **US-013** | OpenFeign 客户端（admin-service 端）→ 4.4 节 |
| **US-014** | 管理员操作审计日志 → 5.3 节 |
| **US-015** | 管理员角色预置与数据初始化 → 6.1 节 |
| **US-016** | admin-service 独立数据库 → 3.1 节 |

---

## 2. 模块概要设计

### 2.1 模块清单

| 模块编号 | 模块名称 | 模块类型 | 模块描述 |
| -------- | -------- | ------------ | ------ |
| MOD-001 | `cloudoffice-admin-service` | 业务服务（新增） | 管理中台后端服务，提供管理员身份认证与角色权限校验、用户管理 CRUD、操作审计日志等功能 |
| MOD-002 | `cloudoffice-gateway` | 基础设施（变更） | API 网关，新增 `/api/v1/admin/**` 路由规则，扩展网关白名单路径 |
| MOD-003 | `cloudoffice-auth-service` | 业务服务（变更） | 认证服务，新增 `AdminUserController` 供 admin-service 内部调用，预置管理员角色数据 |

### 2.2 cloudoffice-admin-service 模块内部结构

```
org.cloudstrolling.cloudoffice.admin/
│
├── AdminApplication.java                  # 启动类（@SpringBootApplication + @EnableDiscoveryClient + @EnableFeignClients + @EnableAspectJAutoProxy）
│
├── config/
│   ├── AdminWebConfig.java                # Web 配置：注册过滤器、白名单路径、CORS 配置
│   └── FeignConfig.java                   # Feign 配置：连接超时 5s、读取超时 10s、请求拦截器
│
├── controller/
│   ├── HealthController.java              # 健康检查（GET /api/v1/admin/health）
│   ├── AdminUserController.java           # 用户管理控制器（7 个 RESTful 端点）
│   └── AdminAuditLogController.java       # 审计日志查询控制器（GET /api/v1/admin/audit-logs）
│
├── service/
│   ├── AdminUserService.java              # 用户管理服务接口
│   ├── AdminAuditLogService.java          # 审计日志服务接口
│   └── impl/
│       ├── AdminUserServiceImpl.java      # 用户管理实现（Feign 调用编排 + 数据脱敏）
│       └── AdminAuditLogServiceImpl.java  # 审计日志实现（插入 + 分页查询）
│
├── feign/
│   └── AuthServiceClient.java             # OpenFeign 客户端接口（调用 auth-service 管理 API）
│
├── filter/
│   └── AdminAuthFilter.java               # 管理员认证过滤器（OncePerRequestFilter）
│
├── interceptor/
│   └── FeignAuthInterceptor.java          # Feign 请求拦截器（传递管理员 JWT Token）
│
├── annotation/
│   └── AdminAuditLog.java                 # 审计日志注解（@Target(ElementType.METHOD)）
│
├── aspect/
│   └── AdminAuditLogAspect.java           # 审计日志 AOP 切面（@Around）
│
├── entity/
│   └── AdminAuditLogEntity.java           # 审计日志实体（t_admin_audit_log）
│
├── dto/
│   ├── UserQueryRequest.java              # 用户查询参数 DTO
│   ├── CreateUserRequest.java             # 创建用户请求 DTO
│   ├── UpdateUserRequest.java             # 编辑用户请求 DTO
│   ├── UpdateUserStatusRequest.java       # 状态更新请求 DTO
│   ├── ResetPasswordRequest.java          # 重置密码请求 DTO
│   └── AssignRolesRequest.java            # 角色分配请求 DTO
│
├── vo/
│   ├── UserVO.java                        # 用户列表 VO（含脱敏处理）
│   └── UserDetailVO.java                  # 用户详情 VO
│
├── enums/
│   └── AdminActionTypeEnum.java           # 管理操作类型枚举
│
├── exception/
│   ├── AdminException.java                # 管理中台业务异常
│   └── AdminErrorCode.java                # 错误码枚举（ADMIN-0001 ~ ADMIN-0007）
│
├── mapper/
│   └── AdminAuditLogMapper.java           # 审计日志 MyBatis-Plus Mapper
│
└── util/
    └── AdminContext.java                  # 管理员请求上下文（ThreadLocal）
```

### 2.3 模块间相互关系

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            cloudoffice-common                            │
│                 (ApiResult, PageResult, BaseEntity, ErrorCode,           │
│                   TokenPairDTO, LoginUserDTO, 异常体系等)                 │
└─────────────────────────────────────────────────────────────────────────┘
                            ▲            ▲
                            │依赖        │依赖
                            │            │
┌───────────────┐  ┌──────────────┐  ┌──────────────────────┐
│   gateway:9000│  │auth-service  │  │  admin-service:9500   │
│               │  │   :9100      │  │                       │
│ 新增路由:     │  │              │  │ AdminAuthFilter       │
│ /api/v1/admin/│  │ AdminUser    │◄─┤ AuthServiceClient     │
│   → admin-svc │  │ Controller   │  │   (OpenFeign)         │
│               │  │ (内部管理API) │  │                       │
│ 白名单扩展:   │  │              │  │ AdminAuditLogService  │
│ /admin/health │  │ 角色预置数据  │  │   → admin 数据库      │
└───────────────┘  └──────┬───────┘  └───────────────────────┘
                          │
                          ▼
              ┌─────────────────────┐
              │  Redis 7.2.x        │
              │  (登录态/黑名单管理) │
              └─────────────────────┘
```

**模块间依赖关系说明：**

| 调用方 | 被调用方 | 通信方式 | 用途 |
|--------|---------|---------|------|
| 管理员客户端 | gateway | HTTP | 请求管理后台 API |
| gateway | admin-service | HTTP（网关路由）| 转发 `/api/v1/admin/**` 请求 |
| admin-service | auth-service | OpenFeign HTTP | 用户数据 CRUD 操作（用户列表/详情/创建/编辑/状态变更/密码重置/角色分配）|
| admin-service | MariaDB(admin) | JDBC | 审计日志写入和查询 |
| auth-service | Redis | RESP | 清除用户登录态会话（禁用/重置密码/角色变更时）|

---

## 3. 数据设计

### 3.1 数据库设计

| 数据库编号 | 数据库名 | 类型 | 版本 | 用途 | 负责人 |
|-----------|---------|------|------|------|--------|
| DB-003 | `cloudstroll_office_admin` | MariaDB | 10.6 LTS | 存储 admin-service 审计日志等管理后台数据（v0.1.7 新增） |

### 3.2 表结构设计

**表名**：`t_admin_audit_log`

**说明**：管理员关键操作审计日志表，记录管理员在管理后台的所有关键操作（创建用户、禁用用户、重置密码、角色分配等）。日志不可修改和删除，仅支持插入和查询。

| 字段名 | 数据类型 | 约束 | 默认值 | 说明 |
|--------|---------|------|--------|------|
| id | BIGINT(20) | PK, NOT NULL | 雪花算法 | 主键 ID |
| admin_id | BIGINT(20) | NOT NULL | - | 操作管理员 ID |
| admin_name | VARCHAR(64) | NOT NULL | - | 操作管理员登录名 |
| action_type | VARCHAR(32) | NOT NULL | - | 操作类型枚举值（CREATE_USER / UPDATE_USER / DISABLE_USER / ENABLE_USER / RESET_PASSWORD / ASSIGN_ROLES / DELETE_USER） |
| target_id | BIGINT(20) | NULL | - | 操作目标用户 ID |
| target_name | VARCHAR(64) | NULL | - | 操作目标用户登录名 |
| detail | VARCHAR(1024) | NULL | - | 操作详情 JSON 字符串（如修改前后的字段值对比） |
| result | TINYINT(4) | NOT NULL | 0 | 操作结果（0-失败, 1-成功） |
| error_message | VARCHAR(512) | NULL | - | 操作失败时的错误信息 |
| request_ip | VARCHAR(64) | NULL | - | 请求来源 IP 地址 |
| user_agent | VARCHAR(256) | NULL | - | 客户端 User-Agent |
| create_time | DATETIME | NOT NULL | CURRENT_TIMESTAMP | 创建时间（非可空，自动填充） |
| update_time | DATETIME | NOT NULL | CURRENT_TIMESTAMP ON UPDATE | 更新时间（自动填充） |
| deleted | TINYINT(4) | NOT NULL | 0 | 逻辑删除（0-正常, 1-删除，但实际上审计日志不应被删除） |

**索引设计**：

| 索引名 | 类型 | 字段 | 唯一 | 说明 |
|--------|------|------|------|------|
| `idx_audit_admin_id` | BTREE | `admin_id` | 否 | 按管理员 ID 查询加速 |
| `idx_audit_action_type` | BTREE | `action_type` | 否 | 按操作类型筛选加速 |
| `idx_audit_target_id` | BTREE | `target_id` | 否 | 按目标用户 ID 查询加速 |
| `idx_audit_create_time` | BTREE | `create_time` | 否 | 按时间范围查询加速 |

### 3.3 数据流设计

| 流程编号 | 流程名称 | 一致性要求 | 说明 |
|---------|---------|-----------|------|
| FLOW-01 | 管理员查询用户列表 | 最终一致 | admin-service 通过 Feign 调用 auth-service 获取用户数据，返回给客户端 |
| FLOW-02 | 管理员创建用户 | 强一致（auth-service 本地事务）| admin-service 通过 Feign 调用 auth-service 创建用户，auth-service 本地事务保证用户表和角色关联表的原子性 |
| FLOW-03 | 管理员禁用用户 | 最终一致 | auth-service 更新用户状态（DB 事务）+ 清除 Redis 登录态（缓存最终一致） |
| FLOW-04 | 审计日志记录 | 弱一致 | AOP 切面异步写入审计日志到 admin 数据库，写入失败不影响主业务 |

**详细步骤（FLOW-03 管理员禁用用户数据流）：**

| 步骤 | 动作 | 数据转换 | 一致性 |
|------|------|---------|--------|
| 1 | admin-service 接收 `PUT /api/v1/admin/users/{userId}/status` | `UpdateUserStatusRequest` → Feign 请求 | - |
| 2 | admin-service `AuthServiceClient` 调用 auth-service | JSON 序列化 HTTP 请求 | - |
| 3 | auth-service `AdminUserController` 接收请求 | Feign 反序列化 → `@RequestBody` | - |
| 4 | auth-service 更新 `t_auth_user.status` | JDBC UPDATE → 数据库行锁 | 强一致（本地事务）|
| 5 | auth-service `LoginSessionService.clearSessions(userId)` | Redis DEL `auth:session:{userId}:*` | 最终一致 |
| 6 | admin-service `@AdminAuditLog` AOP 记录审计日志 | Entity → JDBC INSERT → admin 数据库 | 弱一致（try-catch 隔离）|
| 7 | admin-service 返回 `ApiResult.success()` | 统一响应体 | - |

---

## 4. 接口设计

### 4.1 接口规范

| 项目 | 规范 |
| ---- | -------------------------------------- |
| 对外接口协议 | RESTful (OpenAPI 3.1)，JSON 数据格式 |
| 内部接口协议 | OpenFeign HTTP + JSON（admin-service → auth-service）|
| 版本策略 | URL 路径版本 (`/api/v1/`) |
| 认证方式 | JWT Bearer Token（RS256，管理员角色校验）|
| 数据格式 | JSON（UTF-8 编码）|
| 统一响应体 | `ApiResult<T>`（code / message / data / timestamp）|
| 分页响应体 | `PageResult<T>`（records / total / page / pageSize）|

**统一响应体定义：**

```java
// ApiResult<T> — 统一响应体
public class ApiResult<T> {
    private Integer code;       // 状态码（200=成功, 其余=失败）
    private String message;     // 提示信息（简体中文）
    private T data;             // 泛型数据
    private Long timestamp;     // 响应时间戳
}

// PageResult<T> — 分页响应体
public class PageResult<T> {
    private List<T> records;    // 数据列表
    private Long total;         // 总记录数
    private Integer page;       // 当前页码
    private Integer pageSize;   // 每页大小
}
```

### 4.2 管理中台 API（admin-service 对外接口）

#### 4.2.1 分页查询用户列表

| 项目 | 值 |
|------|------|
| **说明** | 按条件分页查询用户列表，支持关键词搜索、状态筛选、角色筛选、注册时间范围筛选 |
| **路径** | `GET /api/v1/admin/users` |
| **认证** | JWT Token（需 `SUPER_ADMIN` 或 `SYSTEM_ADMIN` 角色） |
| **请求参数** | `Query Parameters` |

**请求参数（UserQueryRequest）：**

```java
public class UserQueryRequest {
    private Integer page;          // 当前页码（默认 1，最小 1）
    private Integer size;          // 每页大小（默认 10，最大 100）
    private String keyword;        // 关键词（匹配 loginName / phone / email）
    private Integer status;        // 用户状态（0-正常, 1-禁用）
    private String roleCode;       // 角色编码筛选
    private LocalDateTime startTime; // 注册开始时间
    private LocalDateTime endTime;   // 注册结束时间
}
```

**响应体：**

```java
public ApiResult<PageResult<UserVO>> listUsers(UserQueryRequest request);
```

**UserVO 定义：**

```java
public class UserVO {
    private Long id;                    // 用户 ID
    private String loginName;           // 登录名
    private String userName;            // 真实姓名
    private String phone;               // 手机号（脱敏：138****1234）
    private String email;               // 邮箱（脱敏：u***@example.com）
    private Integer status;             // 用户状态（0-正常, 1-禁用）
    private List<String> roleNames;     // 角色名称列表
    private LocalDateTime createTime;   // 注册时间
    private LocalDateTime lastLoginTime; // 最后登录时间
}
```

**异常场景：**

| 场景 | HTTP 状态码 | 错误码 | 说明 |
|------|-------------|--------|------|
| 参数校验失败（page/size 为负数） | 400 | `ADMIN-0006` | 请求参数校验失败 |
| Feign 调用 auth-service 超时 | 500 | `ADMIN-0006` | 服务内部调用失败 |
| 未携带 Token 或 Token 无效 | 401 | `ADMIN-0007` | JWT Token 无效或已过期 |
| 无管理员角色 | 403 | `ADMIN-0001` | 非管理员用户无权访问 |

#### 4.2.2 查询用户详情

| 项目 | 值 |
|------|------|
| **说明** | 查询特定用户的详细信息 |
| **路径** | `GET /api/v1/admin/users/{userId}` |
| **认证** | JWT Token（需管理员角色） |

**请求参数：**

```java
@PathVariable Long userId;  // 目标用户 ID
```

**响应体：**

```java
public ApiResult<UserDetailVO> getUserDetail(@PathVariable Long userId);
```

**UserDetailVO 定义：**

```java
public class UserDetailVO {
    private Long id;                    // 用户 ID
    private String loginName;           // 登录名
    private String userName;            // 真实姓名
    private String phone;               // 手机号（脱敏）
    private String email;               // 邮箱（脱敏）
    private Integer status;             // 用户状态
    private String registerMode;        // 注册模式
    private List<RoleInfo> roles;       // 角色列表（含 roleId, roleCode, roleName）
    private LocalDateTime createTime;   // 注册时间
    private LocalDateTime updateTime;   // 最后修改时间
    private LocalDateTime lastLoginTime; // 最后登录时间
    private String lastLoginIp;         // 最后登录 IP
    private Boolean phoneVerified;      // 手机是否已验证
    private Boolean emailVerified;      // 邮箱是否已验证
}
```

**异常场景：**

| 场景 | HTTP 状态码 | 错误码 | 说明 |
|------|-------------|--------|------|
| 用户 ID 不存在 | 404 | `ADMIN-0002` | 用户不存在 |
| userId 参数为非数字 | 400 | `ADMIN-0006` | 参数校验失败 |

#### 4.2.3 创建用户

| 项目 | 值 |
|------|------|
| **说明** | 管理员创建新用户，可指定角色分配 |
| **路径** | `POST /api/v1/admin/users` |
| **认证** | JWT Token（需管理员角色） |

**请求体（CreateUserRequest）：**

```java
public class CreateUserRequest {
    @NotBlank(message = "登录名不能为空")
    @Pattern(regexp = "^[a-zA-Z0-9_]{4,32}$", message = "登录名格式不正确")
    private String loginName;           // 登录名（4-32位字母数字下划线）
    
    @NotBlank(message = "用户姓名不能为空")
    private String userName;            // 真实姓名
    
    @NotBlank(message = "密码不能为空")
    @Size(min = 8, max = 64, message = "密码长度需在8-64位之间")
    private String password;            // 密码（明文，服务端 BCrypt 加密）
    
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phone;               // 手机号（可选）
    
    @Email(message = "邮箱格式不正确")
    private String email;               // 邮箱（可选）
    
    private List<Long> roleIds;         // 角色 ID 列表（可选）
}
```

**响应体：**

```java
public ApiResult<UserVO> createUser(@Valid @RequestBody CreateUserRequest request);
```

**异常场景：**

| 场景 | HTTP 状态码 | 错误码 | 说明 |
|------|-------------|--------|------|
| 必填字段缺失 | 400 | `ADMIN-0006` | 请求参数校验失败 |
| 登录名已存在 | 400 | `ADMIN-0006` | 登录名已存在 |
| 密码复杂度不足 | 400 | `ADMIN-0006` | 密码长度不足 8 位 |
| 手机号格式错误 | 400 | `ADMIN-0006` | 手机号格式不正确 |
| 邮箱格式错误 | 400 | `ADMIN-0006` | 邮箱格式不正确 |
| roleIds 包含不存在的角色 | 400 | `ADMIN-0006` | 角色 ID 不合法 |

#### 4.2.4 编辑用户信息

| 项目 | 值 |
|------|------|
| **说明** | 编辑用户基本信息（真实姓名、手机号、邮箱），不支持修改登录名和密码 |
| **路径** | `PUT /api/v1/admin/users/{userId}` |
| **认证** | JWT Token（需管理员角色） |

**请求体（UpdateUserRequest）：**

```java
public class UpdateUserRequest {
    private String userName;            // 真实姓名（可选，不传则不修改）
    
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phone;               // 手机号（可选，不传则不修改）
    
    @Email(message = "邮箱格式不正确")
    private String email;               // 邮箱（可选，不传则不修改）
}
```

**响应体：**

```java
public ApiResult<UserDetailVO> updateUser(@PathVariable Long userId, @Valid @RequestBody UpdateUserRequest request);
```

**异常场景：**

| 场景 | HTTP 状态码 | 错误码 | 说明 |
|------|-------------|--------|------|
| 用户不存在 | 404 | `ADMIN-0002` | 用户不存在 |
| 手机号已被使用 | 400 | `ADMIN-0006` | 手机号已被占用 |
| 邮箱格式错误 | 400 | `ADMIN-0006` | 邮箱格式不正确 |

#### 4.2.5 启用/禁用用户

| 项目 | 值 |
|------|------|
| **说明** | 启用（status=0）或禁用（status=1）用户账号，禁用时清除用户 Redis 登录态会话 |
| **路径** | `PUT /api/v1/admin/users/{userId}/status` |
| **认证** | JWT Token（需管理员角色） |

**请求体（UpdateUserStatusRequest）：**

```java
public class UpdateUserStatusRequest {
    @NotNull(message = "状态不能为空")
    @Min(value = 0)
    @Max(value = 1)
    private Integer status;             // 0-启用, 1-禁用
}
```

**响应体：**

```java
public ApiResult<Void> updateUserStatus(@PathVariable Long userId, @Valid @RequestBody UpdateUserStatusRequest request);
```

**异常场景：**

| 场景 | HTTP 状态码 | 错误码 | 说明 |
|------|-------------|--------|------|
| 用户不存在 | 404 | `ADMIN-0002` | 用户不存在 |
| 不能禁用自身 | 400 | `ADMIN-0003` | 不能禁用自身 |
| 不能禁用唯一的超级管理员 | 400 | `ADMIN-0004` | 不能禁用唯一的超级管理员 |
| status 参数值不是 0 或 1 | 400 | `ADMIN-0006` | 参数校验失败 |

#### 4.2.6 重置用户密码

| 项目 | 值 |
|------|------|
| **说明** | 重置指定用户的密码，重置后清除该用户所有 Redis 登录态会话（强制重新登录） |
| **路径** | `PUT /api/v1/admin/users/{userId}/password/reset` |
| **认证** | JWT Token（需管理员角色） |

**请求体（ResetPasswordRequest）：**

```java
public class ResetPasswordRequest {
    @NotBlank(message = "新密码不能为空")
    @Size(min = 8, max = 64, message = "密码长度需在8-64位之间")
    private String newPassword;         // 新密码
    
    @NotBlank(message = "确认密码不能为空")
    private String confirmPassword;     // 确认密码（需与 newPassword 一致）
}
```

**响应体：**

```java
public ApiResult<Void> resetPassword(@PathVariable Long userId, @Valid @RequestBody ResetPasswordRequest request);
```

**异常场景：**

| 场景 | HTTP 状态码 | 错误码 | 说明 |
|------|-------------|--------|------|
| 用户不存在 | 404 | `ADMIN-0002` | 用户不存在 |
| 新密码与确认密码不一致 | 400 | `ADMIN-0006` | 两次密码输入不一致 |
| 密码长度不足 8 位 | 400 | `ADMIN-0006` | 密码长度需在8-64位之间 |

#### 4.2.7 分配用户角色

| 项目 | 值 |
|------|------|
| **说明** | 全量替换用户的角色分配（先删后增），变更后清除用户 Redis 登录态会话 |
| **路径** | `PUT /api/v1/admin/users/{userId}/roles` |
| **认证** | JWT Token（需管理员角色） |

**请求体（AssignRolesRequest）：**

```java
public class AssignRolesRequest {
    @NotNull(message = "角色 ID 列表不能为空")
    private List<Long> roleIds;         // 角色 ID 列表（空列表表示移除所有角色）
}
```

**响应体：**

```java
public ApiResult<Void> assignRoles(@PathVariable Long userId, @Valid @RequestBody AssignRolesRequest request);
```

**异常场景：**

| 场景 | HTTP 状态码 | 错误码 | 说明 |
|------|-------------|--------|------|
| 用户不存在 | 404 | `ADMIN-0002` | 用户不存在 |
| 不能移除超级管理员的最后一个管理员角色 | 400 | `ADMIN-0005` | 不能移除超级管理员的最后一个管理员角色 |
| roleIds 中包含不存在的角色 ID | 400 | `ADMIN-0006` | 角色 ID 不合法 |

#### 4.2.8 查询审计日志

| 项目 | 值 |
|------|------|
| **说明** | 分页查询管理员操作审计日志，支持时间范围、操作类型、管理员 ID 筛选 |
| **路径** | `GET /api/v1/admin/audit-logs` |
| **认证** | JWT Token（需管理员角色） |

**请求参数：**

```java
public class AuditLogQueryRequest {
    private Integer page;               // 当前页码（默认 1）
    private Integer size;               // 每页大小（默认 10，最大 100）
    private Long adminId;               // 管理员 ID（可选）
    private String actionType;          // 操作类型（可选，如 CREATE_USER）
    private Long targetId;              // 目标用户 ID（可选）
    private LocalDateTime startTime;    // 开始时间（可选）
    private LocalDateTime endTime;      // 结束时间（可选）
}
```

**响应体：**

```java
public ApiResult<PageResult<AdminAuditLogVO>> listAuditLogs(AuditLogQueryRequest request);
```

**AdminAuditLogVO 定义：**

```java
public class AdminAuditLogVO {
    private Long id;                    // 日志 ID
    private Long adminId;               // 管理员 ID
    private String adminName;           // 管理员登录名
    private String actionType;          // 操作类型
    private Long targetId;              // 目标用户 ID
    private String targetName;          // 目标用户登录名
    private String detail;              // 操作详情 JSON
    private Integer result;             // 操作结果（0-失败, 1-成功）
    private String errorMessage;        // 错误信息
    private String requestIp;           // 请求 IP
    private LocalDateTime createTime;   // 操作时间
}
```

#### 4.2.9 健康检查

| 项目 | 值 |
|------|------|
| **说明** | 服务健康检查端点，白名单放行，无需认证 |
| **路径** | `GET /api/v1/admin/health` |
| **认证** | 无（白名单） |

**响应体：**

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "service": "cloudoffice-admin-service",
    "status": "UP",
    "version": "v0.1.7",
    "timestamp": 1719200000000
  }
}
```

### 4.3 auth-service 内部管理 API（admin-service Feign 调用）

以下 API 仅在 auth-service 内部暴露，供 admin-service 通过 OpenFeign 调用，不对外开放。

#### 4.3.1 内部用户列表查询

```java
// Feign 接口定义
@GetMapping("/api/v1/auth/admin/users")
ApiResult<PageResult<AdminUserVO>> listUsers(
    @RequestParam(value = "page", defaultValue = "1") Integer page,
    @RequestParam(value = "size", defaultValue = "10") Integer size,
    @RequestParam(value = "keyword", required = false) String keyword,
    @RequestParam(value = "status", required = false) Integer status,
    @RequestParam(value = "roleCode", required = false) String roleCode,
    @RequestParam(value = "startTime", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime startTime,
    @RequestParam(value = "endTime", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime endTime
);
```

#### 4.3.2 内部用户详情查询

```java
@GetMapping("/api/v1/auth/admin/users/{userId}")
ApiResult<AdminUserDetailVO> getUserDetail(@PathVariable("userId") Long userId);
```

#### 4.3.3 内部创建用户

```java
@PostMapping("/api/v1/auth/admin/users")
ApiResult<AdminUserVO> createUser(@RequestBody AdminCreateUserRequest request);
// 注册模式固定为 ADMIN_CREATE，BCrypt 加密密码
```

#### 4.3.4 内部编辑用户

```java
@PutMapping("/api/v1/auth/admin/users/{userId}")
ApiResult<AdminUserDetailVO> updateUser(
    @PathVariable("userId") Long userId,
    @RequestBody AdminUpdateUserRequest request
);
```

#### 4.3.5 内部启用/禁用用户

```java
@PutMapping("/api/v1/auth/admin/users/{userId}/status")
ApiResult<Void> updateUserStatus(
    @PathVariable("userId") Long userId,
    @RequestBody AdminUserStatusRequest request  // { status: 0/1 }
);
// 禁用时同步清除 Redis 登录态会话
```

#### 4.3.6 内部重置密码

```java
@PutMapping("/api/v1/auth/admin/users/{userId}/password/reset")
ApiResult<Void> resetPassword(
    @PathVariable("userId") Long userId,
    @RequestBody AdminResetPasswordRequest request  // { newPassword, confirmPassword }
);
// BCrypt 加密新密码 + 清除 Redis 登录态
```

#### 4.3.7 内部角色分配

```java
@PutMapping("/api/v1/auth/admin/users/{userId}/roles")
ApiResult<Void> assignRoles(
    @PathVariable("userId") Long userId,
    @RequestBody AdminAssignRolesRequest request  // { roleIds: [...] }
);
// 全量替换（先删后增）+ 清除 Redis 登录态
```

### 4.4 OpenFeign 客户端接口定义

**AuthServiceClient**（admin-service 端）：

```java
@FeignClient(
    name = "cloudoffice-auth-service",  // Nacos 服务名称
    path = "/api/v1/auth/admin",         // 统一前缀
    fallbackFactory = AuthServiceClientFallbackFactory.class  // 降级处理
)
public interface AuthServiceClient {

    @GetMapping("/users")
    ApiResult<PageResult<AdminUserVO>> listUsers(
        @RequestParam("page") Integer page,
        @RequestParam("size") Integer size,
        @RequestParam(value = "keyword", required = false) String keyword,
        @RequestParam(value = "status", required = false) Integer status,
        @RequestParam(value = "roleCode", required = false) String roleCode,
        @RequestParam(value = "startTime", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime startTime,
        @RequestParam(value = "endTime", required = false) @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime endTime
    );

    @GetMapping("/users/{userId}")
    ApiResult<AdminUserDetailVO> getUserDetail(@PathVariable("userId") Long userId);

    @PostMapping("/users")
    ApiResult<AdminUserVO> createUser(@RequestBody AdminCreateUserRequest request);

    @PutMapping("/users/{userId}")
    ApiResult<AdminUserDetailVO> updateUser(
        @PathVariable("userId") Long userId,
        @RequestBody AdminUpdateUserRequest request
    );

    @PutMapping("/users/{userId}/status")
    ApiResult<Void> updateUserStatus(
        @PathVariable("userId") Long userId,
        @RequestBody AdminUserStatusRequest request
    );

    @PutMapping("/users/{userId}/password/reset")
    ApiResult<Void> resetPassword(
        @PathVariable("userId") Long userId,
        @RequestBody AdminResetPasswordRequest request
    );

    @PutMapping("/users/{userId}/roles")
    ApiResult<Void> assignRoles(
        @PathVariable("userId") Long userId,
        @RequestBody AdminAssignRolesRequest request
    );
}
```

**Feign 配置（FeignConfig）：**

```java
@Configuration
public class FeignConfig {
    
    @Bean
    public RequestInterceptor feignAuthInterceptor() {
        return requestTemplate -> {
            // 从 AdminContext 获取当前管理员的 JWT Token
            String token = AdminContext.getCurrentAdminToken();
            if (StringUtils.hasText(token)) {
                requestTemplate.header(HttpHeaders.AUTHORIZATION, "Bearer " + token);
            }
        };
    }
    
    @Bean
    public FeignClientProperties feignClientProperties() {
        FeignClientProperties properties = new FeignClientProperties();
        // 连接超时 5s
        // 读取超时 10s
        return properties;
    }
}
```

**Feign 超时配置（application.yml）：**

```yaml
spring.cloud.openfeign.client.config:
  default:
    connect-timeout: 5000      # 连接超时 5s
    read-timeout: 10000        # 读取超时 10s
    logger-level: BASIC
```

### 4.5 错误码定义

| 错误码 | HTTP 状态码 | 说明 | 触发条件 |
|--------|-------------|------|---------|
| `ADMIN-0001` | 403 | 非管理员用户无权访问 | JWT Token 解析后 roles 不包含 `SUPER_ADMIN` 或 `SYSTEM_ADMIN` |
| `ADMIN-0002` | 404 | 用户不存在 | 查询的用户 ID 在数据库中不存在 |
| `ADMIN-0003` | 400 | 不能禁用自身 | 管理员尝试禁用自身账号 |
| `ADMIN-0004` | 400 | 不能禁用唯一的超级管理员 | 系统中只有唯一一个超级管理员时尝试禁用 |
| `ADMIN-0005` | 400 | 不能移除超级管理员的最后一个管理员角色 | 尝试移除超级管理员的最后一个管理员角色 |
| `ADMIN-0006` | 400 | 请求参数校验失败 | 参数格式错误、必填字段缺失、业务校验失败等 |
| `ADMIN-0007` | 401 | JWT Token 无效或已过期 | Token 未携带、格式错误、签名无效、已过期 |

### 4.6 API 路由表（网关配置）

| 路由路径 | 目标服务 | 负载均衡策略 | 说明 |
|---------|---------|------------|------|
| `/api/v1/admin/**` | `cloudoffice-admin-service` | 轮询 | 管理中台请求（v0.1.7 新增）|

**网关路由配置（application.yml 变更）：**

```yaml
spring.cloud.gateway.routes:
  # ... 已有路由规则 ...
  - id: admin-service
    uri: lb://cloudoffice-admin-service
    predicates:
      - Path=/api/v1/admin/**
```

**网关白名单扩展：**

```yaml
# 白名单路径（不校验 Token）
auth.white-list:
  - POST /api/v1/auth/login
  - POST /api/v1/auth/register
  - POST /api/v1/auth/refresh
  - GET  /api/v1/auth/health
  # ... 其他白名单路径
  - GET  /api/v1/admin/health           # v0.1.7 新增：admin-service 健康检查
```

---

## 5. 安全设计

### 5.1 管理员认证流程（AdminAuthFilter）

```
[请求] → Gateway 基础 Token 校验（RS256 公钥验签 + Redis 黑名单/登录态）
       → admin-service AdminAuthFilter（OncePerRequestFilter）
       
AdminAuthFilter 校验流程：
1. 获取请求路径，判断是否在白名单列表（如 /api/v1/admin/health）
   ├─ 白名单 → 直接放行
   └─ 非白名单 → 继续执行
   
2. 从请求头获取 Authorization: Bearer <token>
   ├─ 无 Token → 返回 401 ADMIN-0007
   └─ 有 Token → 继续执行
   
3. 解析 JWT Token
   ├─ 签名无效/过期 → 返回 401 ADMIN-0007
   └─ 解析成功 → 获取 Claims（含 roles 字段）
   
4. 校验用户角色是否包含管理员角色
   ├─ roles 不包含 SUPER_ADMIN 或 SYSTEM_ADMIN → 返回 403 ADMIN-0001
   └─ 包含管理员角色 → 继续执行
   
5. 设置 AdminContext（ThreadLocal）
   ├─ adminId / adminName / realName / roles
   └─ 放行请求到 Controller
   
6. 请求处理完成（正常/异常）→ finally 块执行 AdminContext.clear()
```

**过滤器配置：**

```java
@Configuration
public class AdminWebConfig implements WebMvcConfigurer {
    
    @Bean
    public FilterRegistrationBean<AdminAuthFilter> adminAuthFilter(AdminAuthFilter filter) {
        FilterRegistrationBean<AdminAuthFilter> registration = new FilterRegistrationBean<>();
        registration.setFilter(filter);
        registration.addUrlPatterns("/api/v1/admin/*");
        registration.setOrder(Ordered.HIGHEST_PRECEDENCE + 10);
        return registration;
    }
}
```

### 5.2 管理员请求上下文（AdminContext）

```java
public class AdminContext {
    
    private static final ThreadLocal<AdminContextHolder> CONTEXT_HOLDER = new ThreadLocal<>();
    
    public static void setContext(AdminContextHolder context) {
        CONTEXT_HOLDER.set(context);
    }
    
    public static AdminContextHolder getCurrentAdmin() {
        return CONTEXT_HOLDER.get();
    }
    
    public static void clear() {
        CONTEXT_HOLDER.remove();
    }
    
    @Data
    @Builder
    public static class AdminContextHolder {
        private Long adminId;           // 管理员用户 ID
        private String adminName;       // 管理员登录名
        private String realName;        // 管理员真实姓名
        private List<String> roles;     // 管理员角色编码列表
        private String token;           // 当前请求的 JWT Token（用于 Feign 传递）
    }
}
```

### 5.3 审计日志体系（AOP 实现）

**注解定义：**

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface AdminAuditLog {
    AdminActionTypeEnum actionType();   // 操作类型
    String targetId() default "";       // 目标 ID 的 SpEL 表达式（如 #userId）
    String targetName() default "";     // 目标名称的 SpEL 表达式
    String detail() default "";         // 操作详情 SpEL 表达式
}
```

**AOP 切面实现：**

```java
@Aspect
@Component
@Slf4j
public class AdminAuditLogAspect {
    
    @Around("@annotation(auditLog)")
    public Object around(ProceedingJoinPoint joinPoint, AdminAuditLog auditLog) throws Throwable {
        // 1. 获取当前操作人
        AdminContext.AdminContextHolder admin = AdminContext.getCurrentAdmin();
        
        // 2. 记录开始时间
        long startTime = System.currentTimeMillis();
        
        // 3. 执行目标方法
        Object result;
        boolean success = true;
        String errorMessage = null;
        try {
            result = joinPoint.proceed();
        } catch (Throwable e) {
            success = false;
            errorMessage = e.getMessage();
            throw e;
        } finally {
            // 4. 构建审计日志实体（异步写入，try-catch 隔离）
            try {
                AdminAuditLogEntity logEntity = buildAuditLogEntity(
                    admin, auditLog, joinPoint, success, errorMessage, startTime
                );
                adminAuditLogService.save(logEntity);
            } catch (Exception e) {
                log.warn("审计日志记录失败，不影响主业务", e);
            }
        }
        return result;
    }
}
```

**操作类型枚举（AdminActionTypeEnum）：**

```java
public enum AdminActionTypeEnum {
    CREATE_USER("创建用户"),
    UPDATE_USER("编辑用户"),
    DISABLE_USER("禁用用户"),
    ENABLE_USER("启用用户"),
    RESET_PASSWORD("重置密码"),
    ASSIGN_ROLES("分配角色"),
    DELETE_USER("删除用户"),
    QUERY_AUDIT_LOG("查询审计日志");
    
    private final String description;
}
```

### 5.4 关键安全规则

| 规则 | 实现方式 | 违反后果 |
|------|---------|---------|
| 所有管理 API 必须验证管理员身份 | `AdminAuthFilter` 统一拦截校验 | 返回 401 ADMIN-0007 |
| 非管理员角色访问返回 403 | JWT roles 字段白名单校验 | 返回 403 ADMIN-0001 |
| 密码 BCrypt 加密存储 | auth-service `UserServiceImpl` 加密逻辑 | 无法反解密码明文 |
| 手机号/邮箱脱敏显示 | admin-service VO 层脱敏处理 | 响应中返回原始值视为缺陷 |
| 关键操作记录审计日志 | `@AdminAuditLog` 注解 + AOP 切面 | 缺少日志视为缺陷 |
| 禁用用户/重置密码/角色变更后清除 Redis 会话 | auth-service 调用 `LoginSessionService.clearSessions()` | 用户仍可使用旧 Token 访问系统 |
| 不能禁用自身 | `AdminAuthFilter` + 业务层双重校验 | 管理员可被自身禁用视为缺陷 |
| 不能禁用唯一的超级管理员 | 业务层查询当前超级管理员数量后校验 | 系统可失去管理员入口视为缺陷 |

### 5.5 Token 复用机制

管理员使用与普通用户相同的登录接口获取 JWT Token（通过 `POST /api/v1/auth/login`），JWT Claims 中已包含 `roles` 字段。admin-service 通过 `AdminAuthFilter` 解析 Token 中的 `roles` 字段来判断是否具有管理员权限，无需额外签发管理员专用 Token。

**Token 中 roles 字段示例：**

```json
{
  "sub": "1001",
  "roles": ["SUPER_ADMIN", "SYSTEM_ADMIN"],
  "tenantId": 1,
  "clientType": "WEB"
}
```

---

## 6. 非功能需求设计

### 6.1 性能指标

| 指标 | 目标值 | 测量方式 |
| -------------- | ---------- | ------------------ |
| 用户列表查询（10000 用户规模，分页） | ≤ 1000ms | JMeter 压测 |
| 用户详情查询 | ≤ 200ms | JMeter 压测 |
| 新增/编辑用户 | ≤ 500ms | 接口调用计时 |
| 启用/禁用用户（含清除 Redis 会话） | ≤ 1000ms | 接口调用计时 |
| 重置密码（含 BCrypt 加密和清除会话） | ≤ 500ms | 接口调用计时 |
| Feign 调用超时 | 连接 5s，读取 10s | Feign 配置 |
| 管理员 Token 角色校验耗时 | ≤ 50ms | 过滤器计时 |

### 6.2 可扩展性

| 项目 | 策略 | 说明 |
| ------------ | ---------------- | --------- |
| 新增管理资源 | 新增 Controller + Service | 遵循 `/api/v1/admin/{resource}` 路径规范，不影响现有结构 |
| 服务水平扩展 | 无状态设计 + Nacos 多实例 | admin-service 无状态，可多实例部署水平扩展 |
| 细粒度权限扩展（后续版本）| 扩展 `AdminAuthFilter` 或集成 Spring Security | 当前为角色级别粗粒度控制，后续可扩展为 API 级别细粒度权限 |

### 6.3 可用性

| 项目 | 目标 |
| ------------ | --------- |
| 错误提示语言 | 简体中文 |
| 错误响应体格式 | 统一使用 `ApiResult<T>`，包含错误码和中文错误描述 |
| API 响应状态码 | 统一标准 HTTP 状态码（200/400/401/403/404/500）|

### 6.4 可靠性设计

| 机制 | 方案 | 配置 |
| -------- | -------------------- | ------------------------ |
| 熔断降级 | Feign FallbackFactory | auth-service 不可用时返回降级提示 |
| 超时控制 | Feign 客户端超时配置 | 连接 5s，读取 10s |
| 异常隔离 | 审计日志插入 try-catch 隔离 | 不影响主业务操作 |
| 幂等处理 | 启用/禁用用户幂等 | 禁用已禁用的用户，状态保持不变 |

### 6.5 可观测性

| 类型 | 方案 | 采集内容 | 当前阶段 |
| ---- | ----------------------- | ------------- | -------- |
| 日志 | Logback（`@Slf4j`） | 业务日志、错误日志、审计日志 | ✔ 本期启用 |
| 指标 | Prometheus + Grafana（预留） | JVM 指标/QPS/延迟/错误率 | ⏳ 后续版本 |
| 链路追踪 | SkyWalking（预留） | 请求全链路追踪 | ⏳ 后续版本 |

---

## 7. 部署与运维设计

### 7.1 新增服务配置

**admin-service 端口**：9500

**Nacos 注册名称**：`cloudoffice-admin-service`

**关键配置项：**

| 配置项 | 说明 | 默认值/示例 |
|--------|------|------------|
| `server.port` | 服务端口 | 9500 |
| `spring.application.name` | Nacos 服务名 | `cloudoffice-admin-service` |
| `spring.datasource.url` | admin 数据库 JDBC URL | `jdbc:mariadb://localhost:3306/cloudstroll_office_admin` |
| `spring.datasource.username` | 数据库用户名 | `root`（通过环境变量注入） |
| `spring.datasource.password` | 数据库密码 | 通过环境变量注入 |
| `spring.cloud.nacos.discovery.server-addr` | Nacos 地址 | 通过环境变量注入 |
| `spring.cloud.openfeign.client.config.default.connect-timeout` | Feign 连接超时 | 5000ms |
| `spring.cloud.openfeign.client.config.default.read-timeout` | Feign 读取超时 | 10000ms |
| `springdoc.api-docs.path` | API 文档路径 | `/api/v1/admin/v3/api-docs` |

### 7.2 SQL 初始化脚本

**schema_admin.sql**（`cloudstroll_office_admin` 数据库 DDL）：

```sql
-- 创建数据库
CREATE DATABASE IF NOT EXISTS `cloudstroll_office_admin`
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE `cloudstroll_office_admin`;

-- 审计日志表
CREATE TABLE IF NOT EXISTS `t_admin_audit_log` (
    `id`              BIGINT(20)    NOT NULL  COMMENT '主键（雪花算法）',
    `admin_id`        BIGINT(20)    NOT NULL  COMMENT '操作管理员ID',
    `admin_name`      VARCHAR(64)   NOT NULL  COMMENT '操作管理员登录名',
    `action_type`     VARCHAR(32)   NOT NULL  COMMENT '操作类型(CREATE_USER/UPDATE_USER/DISABLE_USER/ENABLE_USER/RESET_PASSWORD/ASSIGN_ROLES/DELETE_USER)',
    `target_id`       BIGINT(20)    NULL      COMMENT '操作目标用户ID',
    `target_name`     VARCHAR(64)   NULL      COMMENT '操作目标用户登录名',
    `detail`          VARCHAR(1024) NULL      COMMENT '操作详情JSON',
    `result`          TINYINT(4)    NOT NULL  DEFAULT 0  COMMENT '操作结果(0-失败,1-成功)',
    `error_message`   VARCHAR(512)  NULL      COMMENT '错误信息',
    `request_ip`      VARCHAR(64)   NULL      COMMENT '请求IP',
    `user_agent`      VARCHAR(256)  NULL      COMMENT '用户代理',
    `create_time`     DATETIME      NOT NULL  DEFAULT CURRENT_TIMESTAMP  COMMENT '创建时间',
    `update_time`     DATETIME      NOT NULL  DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP  COMMENT '更新时间',
    `deleted`         TINYINT(4)    NOT NULL  DEFAULT 0  COMMENT '逻辑删除(0-正常,1-删除)',
    PRIMARY KEY (`id`) USING BTREE,
    INDEX `idx_audit_admin_id` (`admin_id`) USING BTREE,
    INDEX `idx_audit_action_type` (`action_type`) USING BTREE,
    INDEX `idx_audit_target_id` (`target_id`) USING BTREE,
    INDEX `idx_audit_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='管理员操作审计日志表';
```

**init_admin_data.sql**（管理员角色和初始账号预置）：

```sql
USE `cloudstroll_office_auth`;

-- 预置管理员角色（使用 INSERT IGNORE 防止重复）
INSERT IGNORE INTO `t_auth_role` (`id`, `tenant_id`, `role_name`, `role_code`, `status`)
VALUES (1, 0, '超级管理员', 'SUPER_ADMIN', 0);

INSERT IGNORE INTO `t_auth_role` (`id`, `tenant_id`, `role_name`, `role_code`, `status`)
VALUES (2, 0, '系统管理员', 'SYSTEM_ADMIN', 0);

-- 创建初始超级管理员账号（密码: Admin@123456, BCrypt 加密）
INSERT IGNORE INTO `t_auth_user` (`id`, `tenant_id`, `login_name`, `user_name`, `password`, `status`, `register_mode`, `account_settled`)
VALUES (1, 0, 'admin', '系统管理员', '$2a$10$...BCrypt哈希...', 0, 'ADMIN_CREATE', 1);

-- 关联初始超级管理员角色
INSERT IGNORE INTO `t_auth_user_role` (`id`, `user_id`, `role_id`)
VALUES (1, 1, 1);
```

### 7.3 部署架构说明

```
[管理员客户端]
      │
      ▼
[API 网关 :9000]
      │ 路由 /api/v1/admin/** → lb://cloudoffice-admin-service
      ▼
[cloudoffice-admin-service :9500] ←── OpenFeign ──→ [cloudoffice-auth-service :9100]
      │                                                    │
      ▼                                                    ▼
[MariaDB: cloudstroll_office_admin]            [MariaDB: cloudstroll_office_auth]
[t_admin_audit_log]                            [t_auth_user / t_auth_role / ...]
                                                     │
                                                     ▼
                                              [Redis 7.2.x: 登录态/黑名单]
```

---

## 8. 风险与缓解措施

| 风险编号 | 风险描述 | 可能性 | 影响 | 缓解措施 | 负责人 | 状态 |
| -------- | -------- | -------- | -------- | -------- | ------ | -------------------- |
| RISK-001 | auth-service 不可用时 admin-service 无法操作用户数据 | 低 | 高 | Feign Fallback 降级返回友好提示；网关层面健康检查熔断 | 后端开发 | 计划中 |
| RISK-002 | 审计日志表数据量膨胀影响查询性能 | 中 | 中 | 分页查询限制单次返回数量；后续增加定时归档机制；create_time 索引优化查询 | 后端开发 | 已接受 |
| RISK-003 | 管理员 JWT Token 泄漏导致越权操作 | 中 | 高 | Token 有 2h 有效期自动过期；Redis 黑名单机制支持手动吊销；审计日志记录所有操作可追溯 | 后端开发 | 已缓解 |
| RISK-004 | 禁用用户时 Redis 连接失败导致登录态未被清除 | 低 | 中 | 数据库状态更新成功后即使 Redis 清除失败也返回操作成功；记录 warn 日志提示人工处理 | 后端开发 | 已缓解 |
| RISK-005 | Feign 调用 auth-service 长时间阻塞 admin-service 线程 | 中 | 中 | 配置连接超时 5s 和读取超时 10s；后续引入线程池隔离或异步调用 | 后端开发 | 计划中 |

---

## 9. 附录

### 附录 A：术语表

| 术语 | 英文 | 释义 |
| ---- | ---- | ---- |
| 管理中台 | Admin Console | 统一的管理后台后端服务，提供用户管理、审计日志等管理功能 |
| 管理员认证过滤器 | AdminAuthFilter | admin-service 中的 OncePerRequestFilter，对所有管理 API 请求进行 JWT 解析和角色校验 |
| 管理员请求上下文 | AdminContext | 基于 ThreadLocal 的请求上下文，贯穿整个请求生命周期，存储当前操作管理员信息 |
| 审计日志 | Audit Log | 记录管理员关键操作（创建/禁用/重置密码/角色分配等）的日志，不可修改和删除 |
| OpenFeign | OpenFeign | Spring Cloud 声明式 HTTP 客户端，admin-service 通过它调用 auth-service 的用户管理 API |
| 超级管理员 | SUPER_ADMIN | 拥有系统最高权限，可管理所有管理员和普通用户的管理角色 |
| 系统管理员 | SYSTEM_ADMIN | 拥有用户管理操作权限（查看/编辑/启用/禁用等）的管理角色 |
| 操作类型枚举 | AdminActionTypeEnum | 定义管理操作类型的枚举，包括 CREATE_USER / DISABLE_USER / RESET_PASSWORD / ASSIGN_ROLES 等 |

### 附录 B：新增依赖清单（admin-service pom.xml）

| 依赖名 | GroupId | ArtifactId | 用途 |
|-------|---------|-----------|------|
| Spring Boot Starter Web | org.springframework.boot | spring-boot-starter-web | Web 服务 |
| Nacos Discovery | com.alibaba.cloud | spring-cloud-starter-alibaba-nacos-discovery | 服务注册发现 |
| Nacos Config | com.alibaba.cloud | spring-cloud-starter-alibaba-nacos-config | 配置中心 |
| OpenFeign | org.springframework.cloud | spring-cloud-starter-openfeign | 声明式 HTTP 客户端 |
| LoadBalancer | org.springframework.cloud | spring-cloud-starter-loadbalancer | 负载均衡 |
| MyBatis-Plus | com.baomidou | mybatis-plus-spring-boot3-starter | ORM 框架 |
| MariaDB Driver | org.mariadb.jdbc | mariadb-java-client | 数据库驱动 |
| Spring Boot Starter AOP | org.springframework.boot | spring-boot-starter-aop | AOP 切面编程 |
| Lombok | org.projectlombok | lombok | 代码简化 |
| SpringDoc | org.springdoc | springdoc-openapi-starter-webmvc-ui | API 文档 |
| Spring Boot Starter Validation | org.springframework.boot | spring-boot-starter-validation | 参数校验 |
| Common 模块 | org.cloudstrolling | cloudoffice-common | 公共组件（ApiResult / PageResult / 异常体系）|

### 附录 C：Key 文件清单（新增/变更）

| 文件路径 | 类型 | 说明 |
|---------|------|------|
| `cloudoffice-admin-service/pom.xml` | 新增 | admin-service 模块 POM 文件 |
| `cloudoffice-admin-service/src/main/java/.../AdminApplication.java` | 新增 | 启动入口 |
| `cloudoffice-admin-service/src/main/resources/bootstrap.yml` | 新增 | Nacos 配置 |
| `cloudoffice-admin-service/src/main/resources/application.yml` | 新增 | 应用配置（端口 9500、数据源、Feign、日志）|
| `cloudoffice-admin-service/src/main/java/.../filter/AdminAuthFilter.java` | 新增 | 管理员认证过滤器 |
| `cloudoffice-admin-service/src/main/java/.../config/AdminWebConfig.java` | 新增 | Web 配置 |
| `cloudoffice-admin-service/src/main/java/.../config/FeignConfig.java` | 新增 | Feign 配置 |
| `cloudoffice-admin-service/src/main/java/.../controller/AdminUserController.java` | 新增 | 用户管理控制器 |
| `cloudoffice-admin-service/src/main/java/.../controller/AdminAuditLogController.java` | 新增 | 审计日志查询控制器 |
| `cloudoffice-admin-service/src/main/java/.../controller/HealthController.java` | 新增 | 健康检查控制器 |
| `cloudoffice-admin-service/src/main/java/.../service/AdminUserService.java` | 新增 | 用户管理服务接口 |
| `cloudoffice-admin-service/src/main/java/.../service/impl/AdminUserServiceImpl.java` | 新增 | 用户管理服务实现 |
| `cloudoffice-admin-service/src/main/java/.../service/AdminAuditLogService.java` | 新增 | 审计日志服务接口 |
| `cloudoffice-admin-service/src/main/java/.../service/impl/AdminAuditLogServiceImpl.java` | 新增 | 审计日志服务实现 |
| `cloudoffice-admin-service/src/main/java/.../feign/AuthServiceClient.java` | 新增 | Feign 客户端接口 |
| `cloudoffice-admin-service/src/main/java/.../interceptor/FeignAuthInterceptor.java` | 新增 | Feign 请求拦截器 |
| `cloudoffice-admin-service/src/main/java/.../annotation/AdminAuditLog.java` | 新增 | 审计日志注解 |
| `cloudoffice-admin-service/src/main/java/.../aspect/AdminAuditLogAspect.java` | 新增 | 审计日志 AOP 切面 |
| `cloudoffice-admin-service/src/main/java/.../entity/AdminAuditLogEntity.java` | 新增 | 审计日志实体 |
| `cloudoffice-admin-service/src/main/java/.../dto/*.java` | 新增 | 6 个请求 DTO |
| `cloudoffice-admin-service/src/main/java/.../vo/UserVO.java` | 新增 | 用户列表 VO |
| `cloudoffice-admin-service/src/main/java/.../vo/UserDetailVO.java` | 新增 | 用户详情 VO |
| `cloudoffice-admin-service/src/main/java/.../enums/AdminActionTypeEnum.java` | 新增 | 操作类型枚举 |
| `cloudoffice-admin-service/src/main/java/.../exception/AdminException.java` | 新增 | 管理中台业务异常 |
| `cloudoffice-admin-service/src/main/java/.../exception/AdminErrorCode.java` | 新增 | 错误码枚举 |
| `cloudoffice-admin-service/src/main/java/.../mapper/AdminAuditLogMapper.java` | 新增 | 审计日志 Mapper |
| `cloudoffice-admin-service/src/main/java/.../util/AdminContext.java` | 新增 | 管理员请求上下文 |
| `cloudoffice-admin-service/src/test/java/.../AdminApplicationTest.java` | 新增 | 启动测试 |
| `cloudoffice-gateway/src/main/resources/application.yml` | 变更 | 新增 admin-service 路由规则 |
| `cloudoffice-auth-service/src/main/java/.../controller/admin/AdminUserController.java` | 新增 | auth-service 内部管理 API 控制器 |
| `scripts/sql/schema_admin.sql` | 新增 | admin-service DDL 脚本 |
| `scripts/sql/init_admin_data.sql` | 新增 | 管理员角色和初始账号初始化脚本 |
| `scripts/docker/admin-service/Dockerfile` | 新增 | admin-service Dockerfile |

---

## 变更记录

| 变更日期 | 版本号 | 变更说明 |
|---------|-------|---------|
| 2026-06-24 | v0.1.7 | 初版创建 — 根据 v0.1.7 PRD 和架构文档生成管理中台技术规格说明书，涵盖 admin-service 模块设计、管理员认证与权限校验、OpenFeign 服务间通信、独立数据库设计（t_admin_audit_log 表）、9 个管理 API 端点完整定义（含输入/输出/异常场景）、AOP 审计日志体系、错误码定义、安全规则和部署配置 |
