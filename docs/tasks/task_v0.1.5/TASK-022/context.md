# 任务上下文

**项目：** CloudStrollOffice
**版本：** v0.1.5
**任务编号：** TASK-022
**任务名称：** 登录认证业务逻辑（含多端互斥/双 Token 签发）
**生成日期：** 2026-06-23

---

## 1. TASK-022 完整任务规格

**来源：** `docs/tasks/CloudStrollOffice-task-v0.1.5.md` 章节 5.4.2

### 1.1 基本信息

| 项目 | 内容 |
|------|------|
| 任务ID | TASK-022 |
| 任务名称 | 登录认证业务逻辑（含多端互斥/双 Token 签发） |
| 任务类型 | backend |
| 关联UserStory | US-014 |
| 优先级 | P0 |
| 当前状态 | pending |

### 1.2 上下游任务

- **上游任务：** TASK-015（UserMapper）、TASK-018（JwtUtils）、TASK-019（LoginSessionService）、TASK-020（LoginLogService）
- **下游任务：** TASK-030（AuthController 登录接口）

### 1.3 详细业务描述

在 `org.cloudstrolling.cloudoffice.auth.service` 包下创建 `LoginService` 接口，在 `impl` 包下创建 `LoginServiceImpl` 实现类。

**登录方法：`TokenPairDTO login(LoginRequest request)`**

**业务流程（13 步）：**

1. 参数校验（loginName/password/tenantCode/clientType 均不可为空）
2. 查询租户（通过 TenantMapper），校验租户状态（禁用/过期）
3. 查询用户（通过 UserMapper），校验用户状态（禁用/锁定/封禁/过期）
4. BCrypt 密码校验（`BCryptPasswordEncoder.matches()`），失败记录日志并返回 401
5. 查询用户角色编码列表和权限标识列表（通过 UserMapper 联表查询）
6. 构建 `LoginUserDTO`
7. 签发双 Token：`JwtUtils.generateAccessToken()` + `JwtUtils.generateRefreshToken()`
8. 同端互斥处理：通过 `LoginSessionService` 检查同类型端旧会话并清理
9. 写入 Redis 登录态会话（`LoginSessionService.createSession()`）
10. 写入账号/租户状态缓存
11. 记录登录成功日志（`LoginLogService.recordLoginSuccess()`）
12. 更新用户表的 `last_login_time` 和 `last_login_ip`
13. 返回 `TokenPairDTO`

**请求 DTO：`LoginRequest`**

```java
@Data
public class LoginRequest {
    @NotBlank private String loginName;
    @NotBlank private String password;
    @NotBlank private String tenantCode;
    @NotBlank private String clientType;
}
```

### 1.4 核心要点

- 同端互斥逻辑：通过 `ClientTypeEnum.fromCode()` 获取客户端类型，调用 `isSameCategory()` 判断
- Redis 操作失败时记录错误日志但不应泄漏 Redis 连接详情

### 1.5 测试验收方法

- [ ] 有效用户登录成功返回双 Token
- [ ] 密码错误返回 401 LOGIN_FAILED
- [ ] 用户被封禁/禁用返回 403
- [ ] 租户禁用/过期返回 403
- [ ] 同端互斥：旧会话 Token 加入黑名单
- [ ] 多端共存：不同类型端同时登录互不影响
- [ ] 登录日志正确记录
- [ ] 登录态会话正确写入 Redis

---

## 2. PRD US-014 完整验收标准和边界情况

**来源：** `docs/prds/CloudStrollOffice-prd-v0.1.5.md` US-014 章节

### 2.1 故事描述

- **作为** 普通用户
- **我想要** 使用用户名和密码登录平台，指定客户端类型和租户编码
- **以便** 获得 Access Token 和 Refresh Token，安全地访问平台功能，并在多端同时使用时获得一致体验

### 2.2 前置条件

- 租户、用户数据已在数据库中初始化
- JWT 密钥对（RS256）已配置（依赖 US-019/US-020）
- Redis 登录态管理已就绪（依赖 US-021）

### 2.3 验收标准（Acceptance Criteria）

- [ ] **AC1：** Given 一个已注册的有效用户，When 使用正确的 `loginName`、`password`、`tenantCode` 和 `clientType` 调用 `POST /api/v1/auth/login`，Then 返回 HTTP 200，响应体包含 `TokenPairDTO`（accessToken 有效期 2h、refreshToken 有效期 7d，tokenType 为 "Bearer"）
- [ ] **AC2：** Given 登录请求中的 `tenantCode` 对应的租户状态为禁用或已过期，When 请求登录，Then 返回 HTTP 403（`TENANT_DISABLED` 或 `TENANT_EXPIRED`）
- [ ] **AC3：** Given 用户名或密码错误，When 请求登录，Then 返回 HTTP 401（`LOGIN_FAILED`），并记录登录失败日志
- [ ] **AC4：** Given 用户状态为禁用/锁定/封禁，When 请求登录，Then 返回 HTTP 403（`ACCOUNT_DISABLED`/`ACCOUNT_LOCKED`/`ACCOUNT_BANNED`）
- [ ] **AC5：** Given 用户已在 Windows 端登录，When 同一用户在另一台 Windows 设备上使用相同 `clientType`（`WINDOWS`）登录，Then 旧会话的 Token 被加入黑名单、登录态被清除，新会话登录成功（同端互斥）
- [ ] **AC6：** Given 用户已在 Windows 端登录，When 同一用户在 H5 端使用 `clientType=H5` 登录，Then 旧 Windows 端会话不受影响，新 H5 端登录成功（多端共存）
- [ ] **AC7：** Given 登录成功，When 检查 Redis，Then 存在登录态会话 `auth:session:{userId}:{clientType}`，TTL 为 7 天，内容包含 accessToken、refreshToken、loginTime、ip、deviceInfo
- [ ] **AC8：** Given 登录成功，When 检查数据库 `t_auth_login_log`，Then 新增一条登录成功日志记录，包含 user_id、tenant_id、login_ip、client_type、login_time、login_status=1

### 2.4 边界情况与错误处理

| 场景 | 预期行为 |
|------|---------|
| `clientType` 不合法（不在枚举中） | 返回 HTTP 400 `CLIENT_TYPE_INVALID` |
| `tenantCode` 不存在 | 返回 HTTP 404 "租户不存在" |
| 密码为 null 或空字符串 | 返回 HTTP 400 参数校验错误 |
| 用户账号已过期 | 返回 HTTP 403 `ACCOUNT_EXPIRED` |
| Redis 不可用 | 登录失败，返回 HTTP 503 或明确错误提示 |

### 2.5 备注

- 登录成功后自动更新用户表的 `last_login_time` 和 `last_login_ip`
- Token 中携带的 `roles` 和 `permissions` 从数据库实时查询并写入 JWT 声明
- 密码加密使用 BCrypt（强度系数 ≥ 10）

---

## 3. SDS 中的登录流程和接口定义

**来源：** `docs/sds/CloudStrollOffice-sds-v0.1.5.md`

### 3.1 登录流程（SDS 1.3 核心工作流）

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

### 3.2 登录接口定义（SDS 4.3.1）

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

### 3.3 关键设计原则（SDS 1.4）

| 原则 | 说明 | 实现方式 |
|------|------|---------|
| 多端互斥 | 同设备类互斥，不同设备类共存 | ClientTypeEnum.isSameCategory() 决策互斥逻辑，PC/WEB/MOBILE/MINI_PROGRAM 四类 |
| Token 轮换 | Refresh Token 一次性使用 | 每次刷新签发新双 Token，旧 Refresh Token 加入黑名单防重放 |
| 实时吊销 | 登出/踢人/封禁实时生效 | Redis 黑名单 + 登录态删除，网关每次请求校验 |

### 3.4 缓存设计（SDS 3.4）

| 缓存名 | 键格式 | TTL | 用途 |
|--------|--------|-----|------|
| 登录态会话 | `auth:session:{userId}:{clientType}` | 7 天 | 存储用户登录会话信息（JSON） |
| Token 黑名单 | `auth:token:blacklist:{tokenSignature}` | Token 剩余有效期 | 吊销的 Token 签名 |
| 账号状态缓存 | `auth:account:status:{userId}` | 手动管理 | 用户账号状态 |
| 租户状态缓存 | `auth:tenant:status:{tenantId}` | 手动管理 | 租户状态 |

### 3.5 错误码定义（SDS 4.4，登录相关）

| 枚举常量 | HTTP 状态码 | 消息 |
|---------|------------|------|
| LOGIN_FAILED | 401 | 用户名或密码错误 |
| CLIENT_TYPE_INVALID | 400 | 无效的客户端类型 |
| ACCOUNT_DISABLED | 403 | 账号已被禁用 |
| ACCOUNT_LOCKED | 403 | 账号已被锁定 |
| ACCOUNT_BANNED | 403 | 账号已被封禁 |
| ACCOUNT_EXPIRED | 403 | 账号已过期 |
| TENANT_DISABLED | 403 | 租户已被禁用 |
| TENANT_EXPIRED | 403 | 租户已过期 |

### 3.6 DTO 定义（SDS 4.5）

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
```

### 3.7 安全设计（SDS 5.2 认证机制）

| 认证方式 | 适用场景 | 实现方案 |
|---------|---------|---------|
| 用户名+密码 | 用户登录 | BCrypt 密码校验（强度系数 ≥ 10） |
| JWT Access Token | API 请求鉴权 | RS256 签名，2 小时有效期 |
| JWT Refresh Token | Token 续签 | RS256 签名，7 天有效期 |

---

## 4. 架构文档相关设计

**来源：** `docs/architecture.md`

### 4.1 认证服务核心能力（Architecture 2.3）

**登录认证与双 Token 机制：**
- `POST /api/v1/auth/login`：用户名密码登录（BCrypt 校验），RS256 签发 Access Token（2h 有效）和 Refresh Token（7d 有效）

**多端混合登录管理：**
- 6 种客户端类型：WINDOWS（PC类）、UBUNTU（PC类）、H5（WEB类）、ANDROID（MOBILE类）、IOS（MOBILE类）、WECHAT_MINI（MINI_PROGRAM类）
- 同类型端互斥（同一用户 + 同端类型新登录踢旧会话），不同类型端可共存
- 登录态会话存储：Redis Key `auth:session:{userId}:{clientType}`

**Redis 登录态管理（LoginSessionService）：**
- 登录态会话 CRUD：创建/查询/删除，TTL 7 天
- Token 黑名单管理：添加/校验，TTL = Token 剩余有效期
- 账号状态缓存：`auth:account:status:{userId}`
- 租户状态缓存：`auth:tenant:status:{tenantId}`

### 4.2 核心业务数据流（Architecture 4.1 - 登录流程）

```
[客户端]
    │ ① POST /api/v1/auth/login
    │ { loginName, password, tenantCode, clientType }
    ▼
[API 网关 (端口 9000)]
    │ 白名单路径，直接放行
    ▼
[认证服务 (端口 9100)]
    │ ② 校验参数 & 校验验证码（预留）
    │ ③ 查询租户（t_auth_tenant）→ 校验租户状态
    │ ④ 查询用户（t_auth_user）→ 校验用户状态 & 账号有效期
    │ ⑤ BCrypt.matches(password, encryptedPassword) → 验证密码
    │    ├─ 失败 → 记录登录失败日志 → 返回 401 LOGIN_FAILED
    │    └─ 成功 →
    │         ⑥ 查询用户角色和权限（联表查询）
    │         ⑦ 构建 LoginUserDTO
    │         ⑧ JwtUtils.generateAccessToken() → RS256 签名 → Access Token (2h)
    │         ⑨ JwtUtils.generateRefreshToken() → RS256 签名 → Refresh Token (7d)
    │         ⑩ LoginSessionService.createSession():
    │            ├─ 同端互斥：删除旧会话 + 旧 Token 加入黑名单
    │            ├─ 写入 Redis: auth:session:{userId}:{clientType} (TTL 7d)
    │            ├─ 写入 Redis: auth:account:status:{userId} (缓存账号状态)
    │            └─ 写入 Redis: auth:tenant:status:{tenantId} (缓存租户状态)
    │         ⑪ 记录登录成功日志（t_auth_login_log）
    │         ⑫ 更新用户表 last_login_time / last_login_ip
    │         ⑬ 返回 TokenPairDTO（accessToken + refreshToken）
    ▼
[客户端] ←─── JSON 响应 { code: 200, data: { accessToken, refreshToken, ... } }
```

### 4.3 Redis Key 设计（Architecture 5.5）

| Key 格式 | 类型 | TTL | 用途 | 操作方 |
|---------|------|-----|------|--------|
| `auth:session:{userId}:{clientType}` | String | 7 天 | 登录态会话缓存（JSON） | auth-service写入，gateway读取 |
| `auth:token:blacklist:{tokenSignature}` | String | Token 剩余有效期 | Token 黑名单 | auth-service写入，gateway读取 |
| `auth:account:status:{userId}` | String | 手动管理 | 账号状态缓存 | auth-service写入/更新，gateway读取 |
| `auth:tenant:status:{tenantId}` | String | 手动管理 | 租户状态缓存 | auth-service写入/更新，gateway读取 |

### 4.4 数据流 - 模块间数据流转

| 数据流 | 发起方 | 接收方 | 说明 |
|--------|--------|--------|------|
| 登录态写入 | auth-service | Redis | 登录成功写入会话 |
| 黑名单写入 | auth-service | Redis | 登出/踢人时加入黑名单 |
| 登录日志写入 | auth-service | MariaDB | 记录登录日志审计 |

### 4.5 ADR 关键决策记录

| ADR | 决策 | 理由 |
|-----|------|------|
| ADR-011 | JWT 签名算法选型 RS256 | 非对称加密，私钥签发公钥验签 |
| ADR-012 | JWT + Redis 混合状态管理 | 支持主动登出/踢人/Token 吊销实时生效 |
| ADR-014 | 同类型端互斥（按设备分类） | 符合实际使用场景，通过 isSameCategory() 灵活扩展 |
| ADR-009 | BCrypt 密码加密 | 自动加盐，抗彩虹表攻击，强度系数 ≥ 10 |

### 4.6 数据库设计规范（Architecture 5.6）

| 类别 | 规则 |
|------|------|
| 表命名 | `t_{module}_{table_name}`（如 `t_auth_user`） |
| 字段命名 | 下划线命名法（如 `user_name`、`create_time`） |
| 主键 | 雪花算法（BIGINT），字段名统一 `id` |
| 公共字段 | 每表必须包含 `id`、`create_time`、`update_time`、`deleted` |
| 索引命名 | 普通索引 `idx_{table}_{column}`，唯一索引 `uk_{table}_{column}` |

---

## 5. 编码规范要求

**来源：** `docs/project.md`

### 5.1 文件组织规范

认证服务遵循以下标准包结构：

```
org.cloudstrolling.cloudoffice.auth
├── config/          # 配置类
├── controller/      # 控制器层（RESTful API 入口）
├── service/         # 业务逻辑层接口
│   └── impl/        # 业务逻辑实现类
├── mapper/          # 数据访问层（MyBatis-Plus Mapper）
├── entity/          # 实体类（数据库表映射）
├── dto/             # 数据传输对象（请求/响应 DTO）
├── util/            # 工具类
└── exception/       # 异常处理类
```

**LoginService 位置：**
- 接口：`org.cloudstrolling.cloudoffice.auth.service.LoginService`
- 实现：`org.cloudstrolling.cloudoffice.auth.service.impl.LoginServiceImpl`

### 5.2 命名规范

| 类别 | 规则 | 示例 |
|------|------|------|
| 类名 | PascalCase（大驼峰） | `LoginService`、`LoginServiceImpl` |
| 方法名 | camelCase（小驼峰） | `login`、`getUserById` |
| 变量名 | camelCase（小驼峰） | `loginRequest`、`loginUserDTO` |
| 常量 | UPPER_SNAKE_CASE | `TOKEN_EXPIRE_SECONDS` |

### 5.3 代码风格

- 遵循《阿里巴巴 Java 开发手册》
- 使用 Lombok 减少样板代码（`@Data`、`@Slf4j`、`@Builder`、`@NoArgsConstructor`、`@AllArgsConstructor`）
- 统一使用构造器注入替代 `@Autowired` 字段注入（Spring 推荐方式）
- 缩进使用 4 个空格，禁止使用 Tab
- 文件编码统一 UTF-8
- 行宽不超过 120 字符
- 大括号风格采用 K&R 风格（左大括号不换行）

### 5.4 日志规范

- 统一使用 Lombok `@Slf4j` 注解生成日志对象
- 日志级别使用：`info`（重要业务节点如登录成功/失败）、`warn`（潜在问题）、`error`（异常错误）
- 敏感信息（密码等）需脱敏处理后再打印
- 异常日志必须打印完整堆栈信息

### 5.5 测试规范

- 单元测试覆盖率不低于 80%
- 测试框架：Spring Boot Test + JUnit 5 + Mockito
- 遵循 Given-When-Then 模式组织测试用例
- 命名规范：`{methodName}_{scenario}_{expectedResult}`
- 每个 Service 层方法必须有对应的单元测试

### 5.6 统一错误处理规范

- **通用响应体：** `ApiResult<T>`，包含 `code`（状态码）、`message`（提示信息）、`data`（数据）、`timestamp`（时间戳）
- **业务异常：** 继承 `BaseException` 或 `BusinessException`，包含错误码和错误信息
- **全局异常处理：** 使用 `@RestControllerAdvice` + `@ExceptionHandler` 统一拦截处理异常
- **错误码分段：** 认证服务使用 `AUTH-0001 ~ AUTH-9999` 段

### 5.7 其他规范

- API 路径规范：`/api/v1/{module}/{resource}`，使用 RESTful 风格
- 主键生成：统一使用雪花算法（MyBatis-Plus ID_WORKER）
- 密码加密：使用 BCrypt 加密算法存储（强度系数 ≥ 10）
- 依赖管理：版本在父 POM 中统一管理
- SQL 注入防护：使用 MyBatis-Plus 预编译机制，禁止拼接 SQL

---

## 6. 上游任务上下文（关键接口/工具说明）

### 6.1 UserMapper（TASK-015）关键方法

```java
// 按租户+登录名查询用户
@Select("SELECT * FROM t_auth_user WHERE tenant_id = #{tenantId} AND login_name = #{loginName} AND deleted = 0")
UserEntity selectByTenantIdAndLoginName(@Param("tenantId") Long tenantId, @Param("loginName") String loginName);

// 查询用户角色编码列表
@Select("SELECT r.role_code FROM t_auth_user_role ur INNER JOIN t_auth_role r ON ur.role_id = r.id WHERE ur.user_id = #{userId} AND r.status = 0 AND r.deleted = 0")
List<String> selectRoleCodesByUserId(@Param("userId") Long userId);

// 查询用户权限标识列表
@Select("SELECT DISTINCT p.perm_code FROM t_auth_user_role ur INNER JOIN t_auth_role_permission rp ON ur.role_id = rp.role_id INNER JOIN t_auth_permission p ON rp.permission_id = p.id WHERE ur.user_id = #{userId} AND p.status = 0 AND p.deleted = 0")
List<String> selectPermissionCodesByUserId(@Param("userId") Long userId);
```

### 6.2 TenantMapper 关键方法

```java
// 按租户编码查询租户
@Select("SELECT * FROM t_auth_tenant WHERE tenant_code = #{tenantCode} AND deleted = 0")
TenantEntity selectByTenantCode(@Param("tenantCode") String tenantCode);
```

### 6.3 JwtUtils（TASK-018）关键方法

```java
// 签发 Access Token（2h 过期，含 roles/permissions 声明）
String generateAccessToken(LoginUserDTO loginUser);

// 签发 Refresh Token（7d 过期，含 tokenVersion 声明）
String generateRefreshToken(LoginUserDTO loginUser);

// 获取 Token 签名指纹（SHA-256 摘要），用于黑名单 Key
String getTokenSignature(String token);
```

### 6.4 LoginSessionService（TASK-019）关键方法

```java
// 创建登录态会话
void createSession(Long userId, String clientType, Map<String, Object> sessionData);

// 获取登录态
Map<String, Object> getSession(Long userId, String clientType);

// 删除登录态
void removeSession(Long userId, String clientType);

// 加入 Token 黑名单
void addToBlacklist(String tokenSignature, long ttl);

// 校验是否在黑名单
boolean isBlacklisted(String tokenSignature);

// 设置账号状态缓存
void setAccountStatus(Long userId, Integer status);

// 获取账号状态
Integer getAccountStatus(Long userId);

// 设置租户状态缓存
void setTenantStatus(Long tenantId, Integer status);

// 获取租户状态
Integer getTenantStatus(Long tenantId);
```

### 6.5 LoginLogService（TASK-020）关键方法

```java
// 记录登录成功日志
void recordLoginSuccess(Long tenantId, Long userId, String loginName, String loginIp, String clientType, String deviceInfo);

// 记录登录失败日志
void recordLoginFailure(String loginName, String loginIp, String clientType, String failReason);
```

### 6.6 ClientTypeEnum（TASK-002）关键方法

```java
// 根据 code 查找枚举
static Optional<ClientTypeEnum> fromCode(String code);

// 判断是否同设备分类（互斥登录依据）
boolean isSameCategory(ClientTypeEnum other);
```

**枚举值：** WINDOWS(PC)、UBUNTU(PC)、H5(WEB)、ANDROID(MOBILE)、IOS(MOBILE)、WECHAT_MINI(MINI_PROGRAM)

---

## 7. 依赖关系汇总

### 7.1 文件依赖

| 依赖项 | 说明 |
|--------|------|
| `UserEntity` | 用户实体（TASK-014） |
| `TenantEntity` | 租户实体（TASK-014） |
| `UserMapper` | 用户数据访问（TASK-015） |
| `TenantMapper` | 租户数据访问（TASK-015） |
| `JwtUtils` | 双 Token 签发工具（TASK-018） |
| `LoginSessionService` | Redis 会话管理服务（TASK-019） |
| `LoginLogService` | 登录日志服务（TASK-020） |
| `ClientTypeEnum` | 客户端类型枚举（TASK-002） |
| `TokenPairDTO` | 双 Token 响应 DTO（TASK-003） |
| `LoginUserDTO` | 登录用户信息 DTO（TASK-003） |
| `ErrorCode` | 错误码枚举（TASK-001） |
| `RedisKeyConstants` | Redis Key 常量（TASK-004） |

### 7.2 外部依赖

| 依赖 | 用途 |
|------|------|
| `spring-boot-starter-web` | Web 框架 |
| `spring-boot-starter-data-redis` | Redis 操作 |
| `mybatis-plus-spring-boot3-starter` | ORM 框架 |
| `mariadb-java-client` | 数据库驱动 |
| `spring-boot-starter-validation` | 参数校验（@Valid） |
| `spring-security-crypto` | BCrypt 密码加密（已通过 SecurityConfig 引入） |
| `jjwt` | JWT 令牌操作 |
| `lombok` | 代码简化 |
| `hutool` | 工具类库 |
| `jackson` | JSON 序列化 |
