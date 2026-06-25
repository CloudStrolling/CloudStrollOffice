# 任务清单

**项目：** CloudStrollOffice
**版本：** v0.1.7
**对应PRD：** `docs/prds/CloudStrollOffice-prd-v0.1.7.md`
**对应架构：** `docs/architecture.md`
**对应SDS：** `docs/sds/CloudStrollOffice-sds-v0.1.7.md`
**对应项目文件：** `docs/project.md`
**生成日期：** 2026-06-24

# 1. 模块任务清单

| 模块 | 功能 | 任务编码 | 任务名称 |
|------|------|----------|----------|
| **cloudoffice-parent** | 模块注册 | TASK-001 | 父POM注册cloudoffice-admin-service子模块 |
| **cloudoffice-admin-service** | 模块脚手架 | TASK-002 | admin-service模块脚手架（pom.xml、启动类、配置文件） |
| **cloudoffice-gateway** | 网关路由 | TASK-003 | 网关路由配置新增admin路由 + 白名单扩展 |
| **cloudoffice-auth-service** | 内部API | TASK-004 | auth-service扩展AdminUserController（内部管理API服务端） |
| **cloudoffice-auth-service** | DTO | TASK-005 | auth-service内部管理API的DTO/VO定义 |
| **cloudoffice-admin-service** | Feign | TASK-006 | admin-service AuthServiceClient OpenFeign客户端接口 |
| **cloudoffice-admin-service** | Feign | TASK-007 | FeignConfig配置类（超时配置+请求拦截器） |
| **cloudoffice-admin-service** | 安全 | TASK-008 | AdminAuthFilter管理员认证过滤器 |
| **cloudoffice-admin-service** | 安全 | TASK-009 | AdminWebConfig过滤器注册与白名单配置 |
| **cloudoffice-admin-service** | 安全 | TASK-010 | AdminContext ThreadLocal请求上下文工具类 |
| **cloudoffice-admin-service** | 异常 | TASK-011 | AdminErrorCode错误码枚举 + AdminException异常定义 |
| **cloudoffice-admin-service** | DTO | TASK-012 | 用户管理请求DTO定义（6个请求DTO） |
| **cloudoffice-admin-service** | VO | TASK-013 | 用户管理VO定义（UserVO + UserDetailVO） |
| **cloudoffice-admin-service** | 服务 | TASK-014 | AdminUserService接口与实现（Feign编排+数据脱敏） |
| **cloudoffice-admin-service** | 控制器 | TASK-015 | AdminUserController用户管理控制器 |
| **cloudoffice-admin-service** | 审计 | TASK-016 | 审计日志实体+枚举+Mapper |
| **cloudoffice-admin-service** | 审计 | TASK-017 | AdminAuditLogService接口与实现 |
| **cloudoffice-admin-service** | 审计 | TASK-018 | @AdminAuditLog注解定义 |
| **cloudoffice-admin-service** | 审计 | TASK-019 | AdminAuditLogAspect AOP切面实现 |
| **cloudoffice-admin-service** | 审计 | TASK-020 | AdminAuditLogController审计日志查询控制器 |
| **scripts/sql** | DDL | TASK-021 | DDL SQL脚本（schema_admin.sql） |
| **scripts/sql** | 初始化 | TASK-022 | 管理员角色预置与初始化数据SQL脚本 |
| **cloudoffice-admin-service** | 测试 | TASK-023 | admin-service各层单元测试+集成测试 |

---

# 2. 各任务详情

## 2.1 模块注册与脚手架

### 2.1.1 TASK-001：父POM注册cloudoffice-admin-service子模块

**任务ID：** `TASK-001`
**任务名称：** 父POM注册cloudoffice-admin-service子模块
**任务类型：** `common`
**关联UserStory：** `US-001`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** 无
- **下游依赖：** `TASK-002`

#### 上下文读取
- PRD v0.1.7 US-001「创建 admin-service 微服务模块」AC1 验收标准：父POM注册模块
- SDS v0.1.7 附录B 新增依赖清单（admin-service所需依赖已在父POM的BOM中管理，无需新增版本）
- 架构文档 ADR-021「管理中台服务独立」决策记录

#### 详细业务描述
在父项目 `pom.xml` 的 `<modules>` 节点中新增 `<module>cloudoffice-admin-service</module>`，使 admin-service 成为 Maven 多模块项目的一个子模块。父 POM 已通过 `spring-cloud-dependencies` 和 `spring-cloud-alibaba-dependencies` BOM 管理了所有 Spring Cloud 和 Alibaba 相关依赖版本，admin-service 子模块的 POM 中引用这些依赖时无需指定版本号。无需新增额外的 `dependencyManagement` 配置。

#### 测试验收方法
执行 `mvn clean compile -pl cloudoffice-admin-service -am` 编译通过无错误，验证父POM正确识别admin-service子模块。

---

### 2.1.2 TASK-002：admin-service模块脚手架（pom.xml、启动类、配置文件）

**任务ID：** `TASK-002`
**任务名称：** admin-service模块脚手架（pom.xml、启动类、配置文件）
**任务类型：** `backend`
**关联UserStory：** `US-001`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-001`
- **下游依赖：** `TASK-003`, `TASK-004`, `TASK-006`, `TASK-008`, `TASK-010`, `TASK-011`, `TASK-012`, `TASK-021`, `TASK-023`

#### 上下文读取
- PRD v0.1.7 US-001 AC1~AC3（模块创建/编译/启动验收标准）
- PRD v0.1.7 US-001 备注节「模块端口规划：9500」和「标准包结构：config/controller/service/impl/entity/dto/vo/enums/exception/filter/interceptor/mapper/util」
- SDS v0.1.7 2.2节 admin-service模块内部完整包结构
- SDS v0.1.7 7.1节 关键配置项表（端口/Nacos/数据源/Feign超时/SpringDoc）
- SDS v0.1.7 附录B 新增依赖清单（12个依赖）
- project.md 编码规范「文件组织规范」和「命名规范」

#### 详细业务描述
创建 `cloudoffice-admin-service` 模块的完整目录结构。

**pom.xml：** 依赖列表（均不指定版本，由父POM的BOM统一管理）：
- `spring-boot-starter-web` — Web 服务
- `spring-cloud-starter-alibaba-nacos-discovery` — 服务注册发现
- `spring-cloud-starter-alibaba-nacos-config` — 配置中心
- `spring-cloud-starter-openfeign` — 声明式 HTTP 客户端
- `spring-cloud-starter-loadbalancer` — 负载均衡
- `mybatis-plus-spring-boot3-starter` — ORM 框架
- `mariadb-java-client` — 数据库驱动
- `spring-boot-starter-aop` — AOP 切面
- `lombok`（provided）— 代码简化
- `springdoc-openapi-starter-webmvc-ui` — API 文档
- `spring-boot-starter-validation` — 参数校验
- `cloudoffice-common` — 公共组件

**启动类：** `AdminApplication.java` — @SpringBootApplication + @EnableDiscoveryClient + @EnableFeignClients + @EnableAspectJAutoProxy

**bootstrap.yml：** Nacos注册中心地址配置（server-addr 通过环境变量注入）

**application.yml：** 端口9500、数据源（cloudstroll_office_admin）、MyBatis-Plus配置、SpringDoc配置、Feign超时5s/10s、日志级别

**目录结构：** 创建标准包 `org.cloudstrolling.cloudoffice.admin` 下的全部子包。

#### 测试验收方法
1) `mvn clean compile -pl cloudoffice-admin-service -am` 编译通过
2) `AdminApplicationTest` 验证 Spring 上下文加载成功、验证 @EnableDiscoveryClient/@EnableFeignClients/@EnableAspectJAutoProxy 注解存在
3) 验证 application.yml 配置项正确加载（端口9500、数据源URL、Feign超时）

---

## 2.2 网关路由

### 2.2.1 TASK-003：网关路由配置新增admin路由 + 白名单扩展

**任务ID：** `TASK-003`
**任务名称：** 网关路由配置新增admin路由 + 白名单扩展
**任务类型：** `backend`
**关联UserStory：** `US-002`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`
- **下游依赖：** 无

#### 上下文读取
- PRD v0.1.7 US-002「配置管理中台 API 路径与网关路由」AC1~AC3
- SDS v0.1.7 4.6节 API路由表（/api/v1/admin/** → lb://cloudoffice-admin-service）
- SDS v0.1.7 4.6节 网关白名单扩展（GET /api/v1/admin/health 加入白名单）
- 架构文档 2.2节 v0.1.7 更新网关白名单路径

#### 详细业务描述
在 `cloudoffice-gateway` 的 `application.yml` 中，在 `spring.cloud.gateway.routes` 列表末尾新增 admin-service 路由规则：
- id: admin-service
- uri: lb://cloudoffice-admin-service
- predicates: Path=/api/v1/admin/**

同时在网关的白名单路径配置列表（`auth.white-list`）中新增 `GET /api/v1/admin/health`，确保健康检查端点无需认证即可访问。

#### 测试验收方法
1) 网关启动成功后，路由规则正确加载
2) 通过网关访问 `GET /api/v1/admin/health` 返回200（白名单放行）
3) 验证非白名单路径（如 `GET /api/v1/admin/users`）无Token时返回401

---

## 2.3 auth-service 内部管理 API 扩展

### 2.3.1 TASK-004：auth-service扩展AdminUserController（内部管理API服务端）

**任务ID：** `TASK-004`
**任务名称：** auth-service扩展AdminUserController（内部管理API服务端）
**任务类型：** `backend`
**关联UserStory：** `US-012`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`
- **下游依赖：** `TASK-005`, `TASK-006`

#### 上下文读取
- PRD v0.1.7 US-012「用户管理对外 API（auth-service 扩展）」AC1~AC5
- SDS v0.1.7 4.3.1~4.3.7节 7个内部管理API的完整定义（请求参数/响应体/异常场景）
- 架构文档 2.3节 auth-service 扩展（AdminUserController 控制器）

#### 详细业务描述
在 auth-service 的 `controller.admin` 包下新增 `AdminUserController`，提供供 admin-service 通过 Feign 内部调用的 REST API。包含7个端点，所有端点返回统一响应 `ApiResult<T>`：

1. **GET /api/v1/auth/admin/users** — 分页查询用户列表
   - 参数：page, size, keyword, status, roleCode, startTime, endTime（@RequestParam）
   - 返回：`ApiResult<PageResult<AdminUserVO>>`
   - 说明：委托 UserService/UserMapper 查询，分页使用 MyBatis-Plus 分页插件

2. **GET /api/v1/auth/admin/users/{userId}** — 用户详情
   - 参数：@PathVariable Long userId
   - 返回：`ApiResult<AdminUserDetailVO>`（含角色信息列表）
   - 说明：委托 RoleService 查询用户关联角色

3. **POST /api/v1/auth/admin/users** — 创建用户
   - 参数：@RequestBody AdminCreateUserRequest
   - 返回：`ApiResult<AdminUserVO>`
   - 说明：registerMode=ADMIN_CREATE，accountSettled=已完善，BCrypt加密密码，可选roleIds

4. **PUT /api/v1/auth/admin/users/{userId}** — 编辑用户
   - 参数：@PathVariable + @RequestBody AdminUpdateUserRequest
   - 返回：`ApiResult<AdminUserDetailVO>`
   - 说明：只更新非null字段，loginName/password 字段不修改

5. **PUT /api/v1/auth/admin/users/{userId}/status** — 启用/禁用用户
   - 参数：@PathVariable + @RequestBody AdminUserStatusRequest（status=0/1）
   - 返回：`ApiResult<Void>`
   - 说明：禁用时调用 LoginSessionService.clearSessions(userId) 清除Redis登录态

6. **PUT /api/v1/auth/admin/users/{userId}/password/reset** — 重置密码
   - 参数：@PathVariable + @RequestBody AdminResetPasswordRequest
   - 返回：`ApiResult<Void>`
   - 说明：BCrypt加密新密码，更新 lastPasswordChangeTime，清除Redis登录态

7. **PUT /api/v1/auth/admin/users/{userId}/roles** — 分配角色
   - 参数：@PathVariable + @RequestBody AdminAssignRolesRequest（roleIds列表）
   - 返回：`ApiResult<Void>`
   - 说明：全量替换（先删t_auth_user_role后批量插入），清除Redis登录态

Controller 逻辑应简洁，所有业务操作委托给 UserService/RoleService/LoginSessionService 等现有服务。

#### 测试验收方法
MockMvc 单元测试覆盖：
- 每个端点成功场景返回200+正确响应体
- 参数校验失败返回400
- 用户不存在返回404
- 验证 registerMode=ADMIN_CREATE, accountSettled=1
- 验证禁用/重置密码/角色变更时调用 LoginSessionService.clearSessions
- 验证密码在日志和响应体中不明文输出

---

### 2.3.2 TASK-005：auth-service内部管理API的DTO/VO定义

**任务ID：** `TASK-005`
**任务名称：** auth-service内部管理API的DTO/VO定义
**任务类型：** `backend`
**关联UserStory：** `US-012`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-004`
- **下游依赖：** `TASK-006`

#### 上下文读取
- PRD v0.1.7 US-012「用户管理对外 API」交付物列表
- SDS v0.1.7 4.3.1~4.3.7节 每个内部API的请求/响应参数定义

#### 详细业务描述
在 auth-service 的 `dto.admin` 包下新增以下DTO/VO类，使用 Lombok @Data/@Builder/@NoArgsConstructor/@AllArgsConstructor 注解：

**响应VO：**
- `AdminUserVO`（用户列表VO）：id/loginName/userName/phone/email/status/roleNames/createTime/lastLoginTime
- `AdminUserDetailVO`（用户详情VO）：继承AdminUserVO的字段 + registerMode/roles（List<RoleInfo>含roleId/roleCode/roleName）/createTime/updateTime/lastLoginTime/lastLoginIp/phoneVerified/emailVerified

**请求DTO：**
- `AdminCreateUserRequest`：loginName（@NotBlank + @Pattern 4-32位字母数字下划线）/userName（@NotBlank）/password（@NotBlank + @Size min=8 max=64）/phone（@Pattern手机号）/email（@Email）/roleIds（List<Long>）
- `AdminUpdateUserRequest`：userName/phone/email（均为可选，不传不修改）
- `AdminUserStatusRequest`：status（@NotNull + @Min0 + @Max1）
- `AdminResetPasswordRequest`：newPassword（@NotBlank + @Size min=8 max=64）/confirmPassword（@NotBlank）
- `AdminAssignRolesRequest`：roleIds（@NotNull List<Long>）

#### 测试验收方法
单元测试验证每个DTO/VO的字段getter/setter/Builder/序列化/反序列化；验证校验注解配置正确。

---

## 2.4 admin-service OpenFeign 客户端

### 2.4.1 TASK-006：admin-service AuthServiceClient OpenFeign客户端接口

**任务ID：** `TASK-006`
**任务名称：** admin-service AuthServiceClient OpenFeign客户端接口
**任务类型：** `backend`
**关联UserStory：** `US-013`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`, `TASK-004`, `TASK-005`
- **下游依赖：** `TASK-007`, `TASK-014`

#### 上下文读取
- PRD v0.1.7 US-013「OpenFeign 客户端（admin-service 端）」AC1~AC5
- SDS v0.1.7 4.4节 AuthServiceClient 接口定义完整代码（含7个方法全部签名和参数注解）

#### 详细业务描述
在 admin-service 的 `feign` 包下创建 `AuthServiceClient` OpenFeign 客户端接口，使用 `@FeignClient(name="cloudoffice-auth-service", path="/api/v1/auth/admin")` 注解。定义7个Feign方法：

```java
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
ApiResult<AdminUserDetailVO> updateUser(@PathVariable("userId") Long userId, @RequestBody AdminUpdateUserRequest request);

@PutMapping("/users/{userId}/status")
ApiResult<Void> updateUserStatus(@PathVariable("userId") Long userId, @RequestBody AdminUserStatusRequest request);

@PutMapping("/users/{userId}/password/reset")
ApiResult<Void> resetPassword(@PathVariable("userId") Long userId, @RequestBody AdminResetPasswordRequest request);

@PutMapping("/users/{userId}/roles")
ApiResult<Void> assignRoles(@PathVariable("userId") Long userId, @RequestBody AdminAssignRolesRequest request);
```

注意：`AdminUserVO`、`AdminUserDetailVO` 等类型需与 auth-service 的 DTO 类包名和字段结构一致（可共用 auth-service 的 dto.admin 包下的类，或将Feign响应类型定义在 admin-service 自身包中字段名与之匹配）。建议在 admin-service 的 feign.dto 包中定义 Feign 专用的 DTO 类型，保持字段结构与 auth-service 侧一致。

#### 测试验收方法
1) 验证接口定义方法和 @FeignClient/@GetMapping/@PostMapping/@PutMapping 注解配置正确
2) Spring 启动后验证 Feign 客户端代理 Bean 成功注册
3) 验证 Nacos 服务名 `cloudoffice-auth-service` 和路径前缀 `/api/v1/auth/admin` 正确

---

### 2.4.2 TASK-007：FeignConfig配置类（超时配置+请求拦截器）

**任务ID：** `TASK-007`
**任务名称：** FeignConfig配置类（超时配置+请求拦截器）
**任务类型：** `backend`
**关联UserStory：** `US-013`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-006`
- **下游依赖：** `TASK-014`

#### 上下文读取
- SDS v0.1.7 4.4节 FeignConfig 配置类完整代码（含请求拦截器和超时配置）
- PRD v0.1.7 US-013 AC3（请求拦截器传递Token）、AC5（降级处理）

#### 详细业务描述
在 admin-service 的 `config` 包下创建 `FeignConfig` 配置类。包含：

1. **Feign请求拦截器**：`@Bean RequestInterceptor feignAuthInterceptor()` — 从 `AdminContext.getCurrentAdminToken()` 获取当前管理员 JWT Token，如果存在则设置请求头 `Authorization: Bearer <token>`。每次Feign调用auth-service时自动携带Token。

2. **超时配置**：在 `application.yml` 中配置：
   ```yaml
   spring.cloud.openfeign.client.config:
     default:
       connect-timeout: 5000
       read-timeout: 10000
       logger-level: BASIC
   ```

#### 测试验收方法
单元测试验证 Feign 请求拦截器能正确从 AdminContext 获取 Token 并设置到请求头中；验证 application.yml 中 Feign 超时配置加载正确。

---

## 2.5 管理员安全认证

### 2.5.1 TASK-008：AdminAuthFilter管理员认证过滤器

**任务ID：** `TASK-008`
**任务名称：** AdminAuthFilter管理员认证过滤器
**任务类型：** `backend`
**关联UserStory：** `US-003`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`
- **下游依赖：** `TASK-009`, `TASK-010`

#### 上下文读取
- PRD v0.1.7 US-003「实现管理员身份认证与权限校验」AC1~AC5 及边界情况表
- SDS v0.1.7 5.1节 AdminAuthFilter 校验流程（6步完整流程描述）和过滤器配置代码
- 架构文档 5.5节 Token 复用机制（管理员使用与普通用户相同的 JWT Token，通过roles字段区分）

#### 详细业务描述
在 admin-service 的 `filter` 包下创建 `AdminAuthFilter`，继承 `OncePerRequestFilter`。

核心校验逻辑（6步）：

1. **白名单判断**：获取请求路径，判断是否在白名单列表（如 `/api/v1/admin/health`）。白名单路径直接放行（`filterChain.doFilter`）。

2. **Token 提取**：从请求头获取 `Authorization` 头，校验格式为 `Bearer <token>`。无Token或格式错误 → 返回 401（错误码 `ADMIN-0007`）。

3. **JWT 解析**：解析 JWT Token（RS256公钥验签）。需要加载 RSA 公钥，可通过 Nacos 配置中心共享或从配置文件中读取（与 auth-service 共享同一套密钥对）。签名无效/过期 → 返回 401（`ADMIN-0007`）。

4. **角色校验**：从 JWT Claims 中提取 `roles` 字段（List<String>），校验是否包含 `SUPER_ADMIN` 或 `SYSTEM_ADMIN`。不包含管理员角色 → 返回 403（`ADMIN-0001`）。

5. **设置上下文**：解析 Claims 获取 `adminId`(sub)、`adminName`、`realName`、`roles`，构建 `AdminContext.AdminContextHolder` 并设置到 `AdminContext`。从请求头获取 Token 原始字符串存入 context 供 Feign 拦截器使用。

6. **清理上下文**：在 `finally` 块中调用 `AdminContext.clear()` 确保请求结束后 ThreadLocal 被清理。

过滤器在 `doFilterInternal` 方法中实现上述逻辑，校验不通过时使用 `HttpServletResponse` 直接返回 JSON 格式的错误响应（`ApiResult` 格式）。

#### 测试验收方法
单元测试（Mock HttpServletRequest/Response）覆盖：
- 白名单路径直接放行（返回200）
- 无Authorization头 → 返回401 + ADMIN-0007
- 无效Token（签名错误/过期）→ 返回401 + ADMIN-0007
- 普通用户角色（非管理员）→ 返回403 + ADMIN-0001
- 管理员角色 → 放行，验证 AdminContext 被正确设置
- 请求完成后验证 AdminContext 被正确清除

---

### 2.5.2 TASK-009：AdminWebConfig过滤器注册与白名单配置

**任务ID：** `TASK-009`
**任务名称：** AdminWebConfig过滤器注册与白名单配置
**任务类型：** `backend`
**关联UserStory：** `US-003`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-008`
- **下游依赖：** 无

#### 上下文读取
- SDS v0.1.7 5.1节 AdminWebConfig 配置类完整代码（FilterRegistrationBean注册）

#### 详细业务描述
在 admin-service 的 `config` 包下创建 `AdminWebConfig` 配置类，实现 `WebMvcConfigurer`。

1. **过滤器注册**：`@Bean FilterRegistrationBean<AdminAuthFilter> adminAuthFilter(AdminAuthFilter filter)` — 设置过滤器为 AdminAuthFilter 实例；URL 模式为 `/api/v1/admin/*`；优先级 `Ordered.HIGHEST_PRECEDENCE + 10`。

2. **白名单配置**：从 application.yml 的 `auth.admin.whitelist` 配置项读取白名单路径列表（如 `/api/v1/admin/health`），通过构造函数或 `@Value` 注入传递给 AdminAuthFilter。

#### 测试验收方法
验证过滤器正确注册到 `/api/v1/admin/*` URL模式；验证白名单配置可动态读取。

---

### 2.5.3 TASK-010：AdminContext ThreadLocal请求上下文工具类

**任务ID：** `TASK-010`
**任务名称：** AdminContext ThreadLocal请求上下文工具类
**任务类型：** `backend`
**关联UserStory：** `US-004`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-008`
- **下游依赖：** `TASK-007`, `TASK-014`, `TASK-019`

#### 上下文读取
- PRD v0.1.7 US-004「建立管理员请求上下文与操作权限」AC1~AC4
- SDS v0.1.7 5.2节 AdminContext 完整代码（含 AdminContextHolder 静态内部类定义和 ThreadLocal 操作）

#### 详细业务描述
在 admin-service 的 `util` 包下创建 `AdminContext` 工具类，基于 `ThreadLocal` 实现。

```java
public class AdminContext {
    private static final ThreadLocal<AdminContextHolder> CONTEXT_HOLDER = new ThreadLocal<>();

    public static void setContext(AdminContextHolder context) { CONTEXT_HOLDER.set(context); }
    public static AdminContextHolder getCurrentAdmin() { return CONTEXT_HOLDER.get(); }
    public static String getCurrentAdminToken() {
        AdminContextHolder holder = CONTEXT_HOLDER.get();
        return holder != null ? holder.getToken() : null;
    }
    public static void clear() { CONTEXT_HOLDER.remove(); }

    @Data
    @Builder
    public static class AdminContextHolder {
        private Long adminId;
        private String adminName;
        private String realName;
        private List<String> roles;
        private String token;  // 当前请求的JWT Token，供Feign拦截器使用
    }
}
```

要求：
- `setContext` 在 AdminAuthFilter 认证通过后调用
- `getCurrentAdmin` 供业务逻辑获取当前操作人信息
- `getCurrentAdminToken` 供 Feign 请求拦截器获取Token
- `clear` 必须在过滤器 `finally` 块和全局异常处理器中调用，防止 ThreadLocal 内存泄漏

#### 测试验收方法
单元测试覆盖：setContext后getCurrentAdmin返回正确信息；不同线程上下文隔离互不干扰；clear后getCurrentAdmin返回null；多线程并发下数据不串扰。

---

## 2.6 异常体系

### 2.6.1 TASK-011：AdminErrorCode错误码枚举 + AdminException异常定义

**任务ID：** `TASK-011`
**任务名称：** AdminErrorCode错误码枚举 + AdminException异常定义
**任务类型：** `backend`
**关联UserStory：** `US-003`, `US-004`, `US-009`, `US-010`, `US-011`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`
- **下游依赖：** `TASK-014`, `TASK-015`, `TASK-008`

#### 上下文读取
- PRD v0.1.7 5.2节「新增错误码」表（7个错误码定义：ADMIN-0001~ADMIN-0007）
- SDS v0.1.7 4.5节 错误码定义表（含触发条件列）

#### 详细业务描述
在 admin-service 的 `exception` 包下创建：

1. **`AdminErrorCode` 枚举** — 实现 `model.ErrorCode` 接口，包含7个错误码常量：
   - `ADMIN_0001("ADMIN-0001", 403, "非管理员用户无权访问")`
   - `ADMIN_0002("ADMIN-0002", 404, "用户不存在")`
   - `ADMIN_0003("ADMIN-0003", 400, "不能禁用自身")`
   - `ADMIN_0004("ADMIN-0004", 400, "不能禁用唯一的超级管理员")`
   - `ADMIN_0005("ADMIN-0005", 400, "不能移除超级管理员的最后一个管理员角色")`
   - `ADMIN_0006("ADMIN-0006", 400, "请求参数校验失败")`
   - `ADMIN_0007("ADMIN-0007", 401, "JWT Token无效或已过期")`

2. **`AdminException` 异常类** — 继承 `BusinessException`，构造时传入 `AdminErrorCode` 枚举，自动设置错误码、HTTP状态码和中文错误描述。也可直接传入 message 字符串用于参数校验失败等场景。

#### 测试验收方法
单元测试验证每个错误码的 getCode()/getMessage()/getHttpStatus() 返回正确值；验证 AdminException 构造时正确设置错误码和message。

---

## 2.7 用户管理 DTO/VO

### 2.7.1 TASK-012：用户管理请求DTO定义（6个请求DTO）

**任务ID：** `TASK-012`
**任务名称：** 用户管理请求DTO定义（6个请求DTO）
**任务类型：** `backend`
**关联UserStory：** `US-005`, `US-006`, `US-007`, `US-008`, `US-009`, `US-010`, `US-011`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`
- **下游依赖：** `TASK-013`, `TASK-014`

#### 上下文读取
- PRD v0.1.7 US-005~US-011 各UserStory的请求参数表和验收标准
- SDS v0.1.7 4.2.1~4.2.7节 每个API的请求体完整定义（含 @NotBlank/@Pattern/@Size/@Email/@Min/@Max 校验注解规格）

#### 详细业务描述
在 admin-service 的 `dto` 包下创建6个请求DTO，使用 Lombok @Data/@Builder/@NoArgsConstructor/@AllArgsConstructor 注解：

1. **`UserQueryRequest`**: page(Integer, 默认1, min=1)/size(Integer, 默认10, max=100)/keyword(String, 可选)/status(Integer, 可选)/roleCode(String, 可选)/startTime(LocalDateTime, 可选)/endTime(LocalDateTime, 可选)

2. **`CreateUserRequest`**: loginName(@NotBlank + @Pattern regexp="^[a-zA-Z0-9_]{4,32}$")/userName(@NotBlank)/password(@NotBlank + @Size min=8 max=64)/phone(@Pattern regexp="^1[3-9]\\d{9}$" 可选)/email(@Email 可选)/roleIds(List<Long> 可选)

3. **`UpdateUserRequest`**: userName(String 可选)/phone(@Pattern手机号 可选)/email(@Email 可选)，不传则不修改

4. **`UpdateUserStatusRequest`**: status(@NotNull + @Min(0) + @Max(1))

5. **`ResetPasswordRequest`**: newPassword(@NotBlank + @Size min=8 max=64)/confirmPassword(@NotBlank)

6. **`AssignRolesRequest`**: roleIds(@NotNull List<Long>)，空数组表示移除所有角色

#### 测试验收方法
单元测试验证每个DTO的字段getter/setter/Builder/序列化/反序列化；验证校验注解在边界条件下生效（page=0应被前端校验捕获或后端使用默认值、size=200限制为100、密码不足8位触发校验异常）。

---

### 2.7.2 TASK-013：用户管理VO定义（UserVO + UserDetailVO）

**任务ID：** `TASK-013`
**任务名称：** 用户管理VO定义（UserVO + UserDetailVO）
**任务类型：** `backend`
**关联UserStory：** `US-005`, `US-006`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-012`
- **下游依赖：** `TASK-014`

#### 上下文读取
- PRD v0.1.7 US-005 AC5（手机号和邮箱脱敏要求：138****1234、u***@example.com）
- SDS v0.1.7 4.2.1节 UserVO 定义（完整字段列表）
- SDS v0.1.7 4.2.2节 UserDetailVO 定义（完整字段列表）

#### 详细业务描述
在 admin-service 的 `vo` 包下创建2个视图对象，使用 Lombok @Data 注解：

**`UserVO`**（用户列表VO）：
- id(Long), loginName(String), userName(String), phone(String, getter中脱敏), email(String, getter中脱敏), status(Integer), roleNames(List<String>), createTime(LocalDateTime), lastLoginTime(LocalDateTime)
- 脱敏规则：phone 中间4位掩码（`138****5678`），email @前字符除第1个外掩码（`u***@example.com`），在 getPhone() 和 getEmail() 方法中实现

**`UserDetailVO`**（用户详情VO）：
- 包含 UserVO 全部字段 + registerMode(String), roles(List<RoleInfo> 含 roleId/roleCode/roleName), updateTime(LocalDateTime), lastLoginIp(String), phoneVerified(Boolean), emailVerified(Boolean)

#### 测试验收方法
单元测试验证VO字段getter/setter/Builder/序列化；验证脱敏规则正确执行：phone 13812345678 → 138****5678，email user@example.com → u***@example.com，短邮箱 a@b.com → a***@b.com。

---

## 2.8 用户管理业务逻辑

### 2.8.1 TASK-014：AdminUserService接口与实现（Feign编排+数据脱敏）

**任务ID：** `TASK-014`
**任务名称：** AdminUserService接口与实现（Feign编排+数据脱敏）
**任务类型：** `backend`
**关联UserStory：** `US-005`, `US-006`, `US-007`, `US-008`, `US-009`, `US-010`, `US-011`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-006`, `TASK-007`, `TASK-010`, `TASK-012`, `TASK-013`, `TASK-011`
- **下游依赖：** `TASK-015`

#### 上下文读取
- PRD v0.1.7 US-005~US-011 各UserStory的业务逻辑描述和全部验收标准
- PRD v0.1.7 4.4节安全性（脱敏、密码加密、审计日志、不能禁用自身）
- SDS v0.1.7 4.2.1~4.2.7节 每个API的业务逻辑和异常场景

#### 详细业务描述
创建 `AdminUserService` 接口和 `AdminUserServiceImpl` 实现类（构造器注入 AuthServiceClient）。核心方法：

1. **`listUsers(UserQueryRequest)`** → 调用 `AuthServiceClient.listUsers` → 将 Feign 响应中的 `AdminUserVO` 转换为 admin-service 的 `UserVO`（应用脱敏规则）→ 返回 `PageResult<UserVO>`

2. **`getUserDetail(Long userId)`** → 调用 `AuthServiceClient.getUserDetail(userId)` → 转换为 `UserDetailVO`（应用脱敏）→ 返回

3. **`createUser(CreateUserRequest)`** → 调用 `AuthServiceClient.createUser(...)` → 转换返回为 `UserVO` → 返回
   - `@AdminAuditLog(actionType = CREATE_USER, targetId = "#request.loginName")`

4. **`updateUser(Long userId, UpdateUserRequest)`** → 调用 `AuthServiceClient.updateUser(...)` → 返回 `UserDetailVO`
   - `@AdminAuditLog(actionType = UPDATE_USER, targetId = "#userId")`

5. **`updateUserStatus(Long userId, UpdateUserStatusRequest)`** → 业务校验：不能禁用自身（从 AdminContext.getCurrentAdmin().getAdminId() 与 userId 比较）→ 调用 `AuthServiceClient.updateUserStatus(...)` → 返回
   - `@AdminAuditLog(actionType = ENABLE_USER/DISABLE_USER, targetId = "#userId")`
   - 业务校验：禁用自身 → 抛 `AdminException(ADMIN-0003)`
   - 业务校验：禁用唯一超级管理员（需Feign调用查询当前超级管理员数量）→ 抛 `AdminException(ADMIN-0004)`

6. **`resetPassword(Long userId, ResetPasswordRequest)`** → 校验 newPassword 与 confirmPassword 一致 → 调用 `AuthServiceClient.resetPassword(...)` → 返回
   - `@AdminAuditLog(actionType = RESET_PASSWORD, targetId = "#userId")`

7. **`assignRoles(Long userId, AssignRolesRequest)`** → 调用 `AuthServiceClient.assignRoles(...)` → 返回
   - `@AdminAuditLog(actionType = ASSIGN_ROLES, targetId = "#userId")`
   - 业务校验：不能移除超级管理员的最后一个管理员角色（需Feign调用查询当前角色分配情况）→ 抛 `AdminException(ADMIN-0005)`

#### 测试验收方法
单元测试（Mock AuthServiceClient）覆盖：
- 列表查询成功（验证脱敏处理）
- 详情查询成功
- 创建/编辑/状态变更/密码重置/角色分配成功场景
- 不能禁用自身/唯一超级管理员保护/参数校验异常/用户不存在等错误场景
- 验证 Feign 调用参数正确传递
- 验证 @AdminAuditLog 注解在写操作上正确标注

---

### 2.8.2 TASK-015：AdminUserController用户管理控制器

**任务ID：** `TASK-015`
**任务名称：** AdminUserController用户管理控制器
**任务类型：** `backend`
**关联UserStory：** `US-005`, `US-006`, `US-007`, `US-008`, `US-009`, `US-010`, `US-011`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-014`, `TASK-008`, `TASK-009`, `TASK-011`
- **下游依赖：** 无

#### 上下文读取
- PRD v0.1.7 5.1节「API接口总览」表（admin-service对外9个API）
- SDS v0.1.7 4.2.1~4.2.7节 每个API的完整定义（路径/请求参数/响应体/异常场景）

#### 详细业务描述
在 admin-service 的 `controller` 包下创建 `AdminUserController`，`@RestController` + `@RequestMapping("/api/v1/admin/users")`。使用构造器注入 `AdminUserService`，使用 SpringDoc `@Operation/@Schema` 注解生成API文档。包含7个端点：

1. **`GET /`** — `listUsers(UserQueryRequest)` → 返回 `ApiResult<PageResult<UserVO>>`
   - `@Operation(summary = "分页查询用户列表")`

2. **`GET /{userId}`** — `getUserDetail(@PathVariable Long userId)` → 返回 `ApiResult<UserDetailVO>`
   - `@Operation(summary = "查询用户详情")`

3. **`POST /`** — `createUser(@Valid @RequestBody CreateUserRequest)` → 返回 `ApiResult<UserVO>`
   - `@Operation(summary = "创建用户")`

4. **`PUT /{userId}`** — `updateUser(@PathVariable Long userId, @Valid @RequestBody UpdateUserRequest)` → 返回 `ApiResult<UserDetailVO>`
   - `@Operation(summary = "编辑用户信息")`

5. **`PUT /{userId}/status`** — `updateUserStatus(@PathVariable Long userId, @Valid @RequestBody UpdateUserStatusRequest)` → 返回 `ApiResult<Void>`
   - `@Operation(summary = "启用/禁用用户")`

6. **`PUT /{userId}/password/reset`** — `resetPassword(@PathVariable Long userId, @Valid @RequestBody ResetPasswordRequest)` → 返回 `ApiResult<Void>`
   - `@Operation(summary = "重置用户密码")`

7. **`PUT /{userId}/roles`** — `assignRoles(@PathVariable Long userId, @Valid @RequestBody AssignRolesRequest)` → 返回 `ApiResult<Void>`
   - `@Operation(summary = "分配用户角色")`

#### 测试验收方法
MockMvc 单元测试覆盖每个端点的成功场景（返回200+正确响应体）和错误场景（参数校验失败400/无权限403/用户不存在404等）；验证路径映射和HTTP方法正确。

---

## 2.9 审计日志体系

### 2.9.1 TASK-016：审计日志实体+枚举+Mapper

**任务ID：** `TASK-016`
**任务名称：** 审计日志实体+枚举+Mapper
**任务类型：** `backend`
**关联UserStory：** `US-014`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`
- **下游依赖：** `TASK-017`, `TASK-018`

#### 上下文读取
- SDS v0.1.7 3.2节 t_admin_audit_log 表结构（字段名/类型/约束/索引）
- SDS v0.1.7 5.3节 AdminActionTypeEnum 枚举定义（CREATE_USER/UPDATE_USER/DISABLE_USER/ENABLE_USER/RESET_PASSWORD/ASSIGN_ROLES/QUERY_AUDIT_LOG 等）

#### 详细业务描述
创建审计日志相关的数据层组件：

1. **`AdminAuditLogEntity`**（`entity`包）：继承 `BaseEntity`，映射 `t_admin_audit_log` 表。字段：adminId/adminName/actionType/targetId/targetName/detail(VARCHAR 1024，超长截断)/result(0失败1成功，默认0)/errorMessage/requestIp/userAgent。使用 `@TableName("t_admin_audit_log")` 和 `@TableField` 注解。

2. **`AdminActionTypeEnum`**（`enums`包）：`CREATE_USER("创建用户")/UPDATE_USER("编辑用户")/DISABLE_USER("禁用用户")/ENABLE_USER("启用用户")/RESET_PASSWORD("重置密码")/ASSIGN_ROLES("分配角色")/QUERY_AUDIT_LOG("查询审计日志")/DELETE_USER("删除用户")`，含 `code` 和 `description` 属性。

3. **`AdminAuditLogMapper`**（`mapper`包）：继承 `BaseMapper<AdminAuditLogEntity>`，MyBatis-Plus 提供基础 CRUD 和分页查询能力。

#### 测试验收方法
单元测试验证 Entity 字段映射正确；验证枚举常量和 description 正确；验证 Mapper 基础 CRUD 操作。

---

### 2.9.2 TASK-017：AdminAuditLogService接口与实现

**任务ID：** `TASK-017`
**任务名称：** AdminAuditLogService接口与实现
**任务类型：** `backend`
**关联UserStory：** `US-014`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-016`
- **下游依赖：** `TASK-019`, `TASK-020`

#### 上下文读取
- PRD v0.1.7 US-014「管理员操作审计日志」AC1~AC4
- SDS v0.1.7 5.3节 审计日志体系描述（写入和查询逻辑）

#### 详细业务描述
创建 `AdminAuditLogService` 接口和 `AdminAuditLogServiceImpl` 实现类（构造器注入 AdminAuditLogMapper）：

1. **`save(AdminAuditLogEntity entity)`**：写入审计日志。使用 try-catch 异常隔离，插入数据库失败时仅记录 `log.warn("审计日志记录失败，不影响主业务", e)`，不抛异常影响主业务流程。

2. **`pageList(AuditLogQueryRequest request)`**：分页查询审计日志。使用 MyBatis-Plus 分页插件 + LambdaQueryWrapper 动态构造查询条件，支持按 adminId/actionType/targetId/startTime/endTime 筛选。转换实体为 `AdminAuditLogVO` 返回。

#### 测试验收方法
单元测试（Mock AdminAuditLogMapper）覆盖：
- 保存成功验证 mapper.insert 调用
- 保存失败验证 try-catch 隔离（不抛异常）
- 分页查询各种筛选条件组合（单条件/多条件/无筛选）
- 分页参数边界（page=0 默认第1页、size=200 限制100条）

---

### 2.9.3 TASK-018：@AdminAuditLog注解定义

**任务ID：** `TASK-018`
**任务名称：** @AdminAuditLog注解定义
**任务类型：** `backend`
**关联UserStory：** `US-014`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-016`, `TASK-017`
- **下游依赖：** `TASK-019`

#### 上下文读取
- SDS v0.1.7 5.3节 @AdminAuditLog 注解定义完整代码

#### 详细业务描述
在 admin-service 的 `annotation` 包下创建 `@AdminAuditLog` 注解：

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface AdminAuditLog {
    AdminActionTypeEnum actionType();           // 操作类型（必填）
    String targetId() default "";               // 目标ID的SpEL表达式，如 #userId
    String targetName() default "";             // 目标名称的SpEL表达式，如 #request.loginName
    String detail() default "";                 // 操作详情SpEL表达式
}
```

#### 测试验收方法
单元测试验证注解定义的目标类型、保留策略、属性默认值正确。

---

### 2.9.4 TASK-019：AdminAuditLogAspect AOP切面实现

**任务ID：** `TASK-019`
**任务名称：** AdminAuditLogAspect AOP切面实现
**任务类型：** `backend`
**关联UserStory：** `US-014`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-017`, `TASK-018`, `TASK-010`
- **下游依赖：** `TASK-020`

#### 上下文读取
- SDS v0.1.7 5.3节 AdminAuditLogAspect 完整代码（@Around 环绕通知）
- SDS v0.1.7 4.1.6节 审计日志记录数据流图

#### 详细业务描述
在 admin-service 的 `aspect` 包下创建 `AdminAuditLogAspect` AOP切面类，`@Aspect` + `@Component`。

`@Around("@annotation(auditLog)")` 环绕通知逻辑：

1. **获取当前操作人**：`AdminContext.getCurrentAdmin()` 获取管理员信息（adminId/adminName）
2. **记录开始时间**：`System.currentTimeMillis()` 
3. **执行目标方法**：`joinPoint.proceed()`
4. **构建审计日志实体**（finally块）：
   - adminId/adminName：来自 AdminContext
   - actionType：来自注解 `@AdminAuditLog.actionType()`
   - targetId/targetName：通过 Spring SpEL 表达式解析方法参数（如 #userId 获取方法第1个参数）
   - result：成功=1，失败=0
   - errorMessage：catch到的异常信息（成功时为null）
   - requestIp：通过 `RequestContextHolder.getRequestAttributes()` 获取 HttpServletRequest 提取 IP
   - detail：通过 SpEL 解析注解的 detail 属性
5. **写入数据库**：调用 `AdminAuditLogService.save(entity)`，try-catch 隔离异常

SpEL 解析可使用 `org.springframework.expression.spel.standard.SpelExpressionParser` 或在切面中通过 `joinPoint.getArgs()` 获取参数数组，按参数名匹配。

#### 测试验收方法
单元测试（Mock AdminAuditLogService）覆盖：
- 方法执行成功后验证审计日志记录正确（result=1）
- 方法抛出异常后验证记录失败日志（result=0 + errorMessage）
- SpEL 表达式正确解析方法参数值
- 审计日志插入异常时不影响主业务流程（不抛异常）
- 验证 requestIp 正确获取

---

### 2.9.5 TASK-020：AdminAuditLogController审计日志查询控制器

**任务ID：** `TASK-020`
**任务名称：** AdminAuditLogController审计日志查询控制器
**任务类型：** `backend`
**关联UserStory：** `US-014`
**优先级：** `P1`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-017`, `TASK-019`, `TASK-011`
- **下游依赖：** 无

#### 上下文读取
- PRD v0.1.7 US-014 AC3（审计日志查询）和 AC4（不可修改/删除）
- SDS v0.1.7 4.2.8节「查询审计日志」API定义（含 AuditLogQueryRequest 和 AdminAuditLogVO 定义）

#### 详细业务描述
在 admin-service 的 `controller` 包下创建 `AdminAuditLogController`，`@RestController` + `@RequestMapping("/api/v1/admin/audit-logs")`。

1个端点：

- **`GET /`** — `listAuditLogs(AuditLogQueryRequest request)` → 返回 `ApiResult<PageResult<AdminAuditLogVO>>`
  - 使用 `@AdminAuditLog(actionType = QUERY_AUDIT_LOG)` 注解记录审计日志查询操作
  - 委托 `AdminAuditLogService.pageList(request)`

**`AuditLogQueryRequest`**（`dto`包）：page/size/adminId/actionType/targetId/startTime/endTime

**`AdminAuditLogVO`**（`vo`包）：id/adminId/adminName/actionType/targetId/targetName/detail/result/errorMessage/requestIp/createTime

#### 测试验收方法
MockMvc 单元测试覆盖：分页查询成功返回、各种筛选条件组合、分页参数边界；验证 @AdminAuditLog 注解正确标注。

---

## 2.10 数据库与初始化脚本

### 2.10.1 TASK-021：DDL SQL脚本（schema_admin.sql）

**任务ID：** `TASK-021`
**任务名称：** DDL SQL脚本（schema_admin.sql）
**任务类型：** `docs`
**关联UserStory：** `US-016`, `US-014`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`
- **下游依赖：** `TASK-022`

#### 上下文读取
- PRD v0.1.7 US-016「admin-service 独立数据库」AC1~AC4
- SDS v0.1.7 7.2节 schema_admin.sql 完整DDL脚本

#### 详细业务描述
创建 `scripts/sql/schema_admin.sql` DDL脚本：

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

#### 测试验收方法
验证 SQL 语法正确（可在 MariaDB 客户端执行）；验证表结构和字段类型与 SDS 定义一致；验证4个索引定义正确；验证数据库字符集 utf8mb4 设置。

---

### 2.10.2 TASK-022：管理员角色预置与初始化数据SQL脚本

**任务ID：** `TASK-022`
**任务名称：** 管理员角色预置与初始化数据SQL脚本
**任务类型：** `docs`
**关联UserStory：** `US-015`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-021`
- **下游依赖：** 无

#### 上下文读取
- PRD v0.1.7 US-015「管理员角色预置与数据初始化」AC1~AC5
- SDS v0.1.7 7.2节 init_admin_data.sql 完整脚本

#### 详细业务描述
创建 `scripts/sql/init_admin_data.sql` 初始化脚本（作用于 `cloudstroll_office_auth` 数据库）：

```sql
USE `cloudstroll_office_auth`;

-- 预置管理员角色（使用 INSERT IGNORE 防止重复）
INSERT IGNORE INTO `t_auth_role` (`id`, `tenant_id`, `role_name`, `role_code`, `status`)
VALUES (1, 0, '超级管理员', 'SUPER_ADMIN', 0);
INSERT IGNORE INTO `t_auth_role` (`id`, `tenant_id`, `role_name`, `role_code`, `status`)
VALUES (2, 0, '系统管理员', 'SYSTEM_ADMIN', 0);

-- 创建初始超级管理员账号（loginName=admin, password=Admin@123456, BCrypt加密）
-- 注意：BCrypt哈希值需要使用Java代码或在线工具实际生成后替换
INSERT IGNORE INTO `t_auth_user` (`id`, `tenant_id`, `login_name`, `user_name`, `password`, `status`, `register_mode`, `account_settled`)
VALUES (1, 0, 'admin', '系统管理员', '$2a$10$...BCrypt哈希...', 0, 'ADMIN_CREATE', 1);

-- 关联初始超级管理员角色
INSERT IGNORE INTO `t_auth_user_role` (`id`, `user_id`, `role_id`)
VALUES (1, 1, 1);
```

备注：生成 BCrypt 哈希值可使用 Java `BCrypt.hashpw("Admin@123456", BCrypt.gensalt())` 或在线 BCrypt 生成器。脚本中必须在注释中标注密码明文 `Admin@123456`。

#### 测试验收方法
验证 SQL 语法正确；验证 INSERT IGNORE 可重复执行不报错；验证初始化后 t_auth_role 表存在 SUPER_ADMIN/SYSTEM_ADMIN 记录；验证 admin 用户存在并关联 SUPER_ADMIN 角色；验证 BCrypt 加密的密码在 auth-service 登录时可被正确验证。

---

## 2.11 测试

### 2.11.1 TASK-023：admin-service各层单元测试+集成测试

**任务ID：** `TASK-023`
**任务名称：** admin-service各层单元测试+集成测试
**任务类型：** `test`
**关联UserStory：** `US-001`, `US-003`, `US-004`, `US-005`, `US-006`, `US-007`, `US-008`, `US-009`, `US-010`, `US-011`, `US-014`
**优先级：** `P0`
**当前状态：** `pending`

#### 上下游任务
- **上游依赖：** `TASK-002`, `TASK-008`, `TASK-010`, `TASK-014`, `TASK-015`, `TASK-017`, `TASK-019`, `TASK-020`
- **下游依赖：** 无

#### 上下文读取
- PRD v0.1.7 全部 UserStory 的验收标准和边界情况表
- SDS v0.1.7 全部 API 定义的请求/响应/错误场景
- project.md 测试规范（Given-When-Then 模式、MockMvc 测试、覆盖率要求）

#### 详细业务描述
为 admin-service 编写完整的单元测试和集成测试。测试骨架和目录结构在 `src/test/java/org/cloudstrolling/cloudoffice/admin/` 下创建。

测试环境使用 `bootstrap.yml`（禁用 Nacos）和 `application-test.yml`（H2 内存数据库或排除数据源自动配置），确保测试可在无外部中间件环境下独立运行。

**测试清单：**

1. **`AdminApplicationTest`**：应用启动测试
   - 验证 Spring 上下文正常加载
   - 验证 @EnableDiscoveryClient/@EnableFeignClients/@EnableAspectJAutoProxy 注解存在

2. **`HealthControllerTest`**：健康检查控制器测试（MockMvc）
   - GET /api/v1/admin/health 返回200，验证响应体 service/status/version/timestamp 字段

3. **`filter/AdminAuthFilterTest`**：管理员认证过滤器测试
   - 白名单路径放行
   - 无Token → 401
   - 无效Token → 401
   - 非管理员角色 → 403
   - 管理员角色放行并验证 AdminContext 设置
   - 请求完成后 AdminContext 被清除

4. **`util/AdminContextTest`**：管理员上下文测试
   - setContext/getCurrentAdmin/getCurrentAdminToken/clear
   - 线程隔离验证
   - 多线程并发安全

5. **`service/impl/AdminUserServiceImplTest`**：用户管理服务测试（Mock AuthServiceClient）
   - listUsers：成功返回脱敏数据、无数据返回空列表
   - getUserDetail：成功返回、用户不存在
   - createUser：成功创建、登录名已存在、参数校验失败
   - updateUser：成功更新、用户不存在
   - updateUserStatus：启用/禁用成功、不能禁用自身、不能禁用唯一超级管理员
   - resetPassword：成功重置、密码不一致、用户不存在
   - assignRoles：成功分配、不能移除最后一个管理员角色

6. **`controller/AdminUserControllerTest`**：用户管理控制器测试（MockMvc）
   - 7个端点各覆盖成功场景和错误场景
   - 参数校验（DTO 校验注解触发）
   - 用户不存在 404
   - 403 权限拒绝

7. **`service/impl/AdminAuditLogServiceImplTest`**：审计日志服务测试（Mock Mapper）
   - save 成功
   - save 失败时异常隔离
   - pageList 各种筛选条件组合

8. **`controller/AdminAuditLogControllerTest`**：审计日志控制器测试（MockMvc）
   - 分页查询成功
   - 各种筛选条件
   - 验证 @AdminAuditLog 注解

**测试规范：**
- 使用 @SpringBootTest + @AutoConfigureMockMvc
- Service 层使用 Mockito @Mock 模拟依赖
- 遵循 Given-When-Then 模式
- 测试方法命名：`{methodName}_{scenario}_{expectedResult}`
- Service 层覆盖率 ≥ 85%，Controller 层覆盖率 ≥ 80%

#### 测试验收方法
执行 `mvn clean test -pl cloudoffice-admin-service` 全部测试通过无失败；验证测试覆盖率满足要求（Service≥85%、Controller≥80%）。

---

## 3. 任务依赖关系图

```
TASK-001 (父POM)
   │
   ▼
TASK-002 (admin-service 脚手架) ──────────────────────┐
   │                          │                        │
   ▼                          ▼                        ▼
TASK-003 (网关路由)    TASK-004 (auth AdminUserController)   TASK-008 (AdminAuthFilter)
   │                          │                        │
   ▼                          ▼                        ├───TASK-009 (AdminWebConfig)
TASK-021 (DDL SQL)    TASK-005 (auth DTO/VO)           │
   │                          │                        ▼
   ▼                          ▼                   TASK-010 (AdminContext)
TASK-022 (Init SQL)    TASK-006 (AuthServiceClient)     │
                              │                        ├───TASK-007 (FeignConfig)
                              ▼                        │
                         TASK-011 (ErrorCode)◄─────────┤
                              │                        │
                              ▼                        ▼
                         TASK-012 (DTO定义)────►TASK-014 (AdminUserService)
                              │                        │
                              ▼                        ▼
                         TASK-013 (VO定义)────►TASK-015 (AdminUserController)
                                                      │
                                         TASK-016 (审计实体+枚举+Mapper)
                                                      │
                                         TASK-017 (AdminAuditLogService)◄─┐
                                                      │                    │
                                         TASK-018 (@AdminAuditLog注解)──────┤
                                                      │                    │
                                         TASK-019 (AdminAuditLogAspect)────┤
                                                      │                    │
                                         TASK-020 (AdminAuditLogController)┘
                                                      │
                                                      ▼
                                         TASK-023 (全量单元测试+集成测试)
```

---

## 4. 任务类型统计

| 类型 | 数量 | 任务编号 |
|------|------|----------|
| `common` | 1 | TASK-001 |
| `backend` | 19 | TASK-002~TASK-020 |
| `docs` | 2 | TASK-021, TASK-022 |
| `test` | 1 | TASK-023 |
| **合计** | **23** | |

---

## 5. 优先级分布

| 优先级 | 数量 | 任务编号 |
|--------|------|----------|
| `P0` | 21 | TASK-001~TASK-019, TASK-021~TASK-023 |
| `P1` | 2 | TASK-020, TASK-022(?) |
| `P2` | 0 | |
