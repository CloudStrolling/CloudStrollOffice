# 任务清单

**项目：** CloudStrollOffice
**版本：** v0.1.5
**对应PRD：** `docs/prds/CloudStrollOffice-prd-v0.1.5.md`
**对应架构：** `docs/architecture.md`
**对应SDS：** `docs/sds/CloudStrollOffice-sds-v0.1.5.md`
**对应项目文件：** `docs/project.md`
**生成日期：** 2026-06-22

# 1. 模块任务清单一览

| 模块 | 功能 | 任务编码 | 任务内容 |
|------|------|---------|---------|
| 公共模块 | 错误码扩展 | TASK-001 | 新增认证错误码枚举常量 |
| 公共模块 | 客户端类型枚举 | TASK-002 | 新增 ClientTypeEnum（含设备分类） |
| 公共模块 | Token DTO | TASK-003 | 新增 TokenPairDTO 和 LoginUserDTO |
| 公共模块 | Redis Key 常量 | TASK-004 | 新增 RedisKeyConstants 常量管理类 |
| 父 POM | 依赖管理 | TASK-005 | 父 POM 依赖补充确认 |
| 网关模块 | Redis 集成 | TASK-006 | 网关集成 Redis 配置 |
| 网关模块 | RSA 公钥加载 | TASK-007 | 网关 RSA 公钥加载配置 |
| 网关模块 | 白名单配置 | TASK-008 | 网关白名单路径配置 |
| 网关模块 | AuthFilter | TASK-009 | 网关 AuthFilter 全局认证过滤器实现 |
| 认证服务 | 依赖补充 | TASK-010 | 认证服务 pom.xml 依赖补充 |
| 认证服务 | 应用配置 | TASK-011 | 认证服务 application.yml 数据库与缓存配置 |
| 认证服务 | MyBatis-Plus 配置 | TASK-012 | 认证服务 MyBatis-Plus 配置类 |
| 认证服务 | 数据库 DDL | TASK-013 | 数据库初始化 SQL 脚本（7 张表） |
| 认证服务 | 实体类 | TASK-014 | RBAC 实体类创建（7 个 Entity） |
| 认证服务 | RBAC Mapper | TASK-015 | RBAC 数据访问层（Mapper + XML） |
| 认证服务 | 日志 Mapper | TASK-016 | 登录日志 Entity + Mapper |
| 认证服务 | RSA 密钥配置 | TASK-017 | 认证服务 RSA 密钥配置类 |
| 认证服务 | JwtUtils 重构 | TASK-018 | JwtUtils 重构（RS256 双 Token） |
| 认证服务 | Redis 会话管理 | TASK-019 | Redis 登录态管理服务（LoginSessionService） |
| 认证服务 | 日志审计服务 | TASK-020 | 登录日志审计服务（LoginLogService） |
| 认证服务 | 用户注册 | TASK-021 | 用户注册业务逻辑 |
| 认证服务 | 登录认证 | TASK-022 | 登录认证业务逻辑（含多端互斥） |
| 认证服务 | Token 刷新 | TASK-023 | Token 刷新业务逻辑（含轮换机制） |
| 认证服务 | 用户登出 | TASK-024 | 登出业务逻辑 |
| 认证服务 | 强制踢人 | TASK-025 | 强制踢人业务逻辑 |
| 认证服务 | 账号封禁/解封 | TASK-026 | 账号封禁/解封业务逻辑 |
| 认证服务 | 用户管理 API | TASK-027 | 用户管理 Service + Controller（CRUD/状态/角色分配） |
| 认证服务 | 角色管理 API | TASK-028 | 角色管理 Service + Controller（CRUD/权限分配） |
| 认证服务 | 权限管理 API | TASK-029 | 权限管理 Service + Controller（CRUD/树形查询） |
| 认证服务 | AuthController | TASK-030 | AuthController 认证控制器实现 |

# 2. cloudoffice-common（公共模块）

## 2.1 错误码扩展

### 2.1.1 TASK-001：新增认证错误码枚举常量

**任务ID：** TASK-001
**任务名称：** 新增认证错误码枚举常量
**任务类型：** common
**关联UserStory：** US-001
**优先级：** P0
**当前状态：** code_finish

#### 上下游任务
- 下游任务：TASK-009（AuthFilter 使用错误码）、TASK-030（AuthController 使用错误码）

#### 上下文读取
- **PRD US-001 AC1~AC3**：19 个认证错误码的枚举常量名称、HTTP 状态码、消息文本
- **SDS 2.3 公共模块**：ErrorCode 扩展内容描述（19 个枚举常量清单）
- **SDS 4.4 错误码定义**：完整错误码定义表（code/message/HTTP 状态码）
- **project.md 统一错误处理规范**：错误码分段（AUTH-0001 ~ AUTH-9999）
- **现有 ErrorCode.java 位置**：`cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java`

#### 详细业务描述
在 `cloudoffice-common` 模块的 `ErrorCode` 枚举（实现 `model.ErrorCode` 接口）中新增 19 个认证授权相关错误码枚举常量。枚举位于 `org.cloudstrolling.cloudoffice.common.exception.ErrorCode`。

**新增的枚举常量清单：**

| 枚举名 | HTTP 状态码 | 消息文本 |
|--------|------------|---------|
| `TOKEN_EXPIRED` | 401 | 令牌已过期，请刷新令牌 |
| `TOKEN_INVALID` | 401 | 令牌无效 |
| `TOKEN_BLACKLISTED` | 401 | 令牌已被吊销 |
| `REFRESH_TOKEN_EXPIRED` | 401 | 刷新令牌已过期，请重新登录 |
| `REFRESH_TOKEN_INVALID` | 401 | 刷新令牌无效 |
| `ACCOUNT_DISABLED` | 403 | 账号已被禁用 |
| `ACCOUNT_LOCKED` | 403 | 账号已被锁定 |
| `ACCOUNT_BANNED` | 403 | 账号已被封禁 |
| `ACCOUNT_EXPIRED` | 403 | 账号已过期 |
| `LOGIN_FAILED` | 401 | 用户名或密码错误 |
| `CAPTCHA_ERROR` | 400 | 验证码错误 |
| `CLIENT_TYPE_INVALID` | 400 | 无效的客户端类型 |
| `SESSION_KICKED_OUT` | 401 | 账号已在其他设备登录，您已被踢下线 |
| `TENANT_DISABLED` | 403 | 租户已被禁用 |
| `TENANT_EXPIRED` | 403 | 租户已过期 |
| `PERMISSION_DENIED` | 403 | 权限不足 |
| `ROLE_NOT_FOUND` | 404 | 角色不存在 |
| `USER_NOT_FOUND` | 404 | 用户不存在 |

**核心要求：**
1. 枚举必须实现 `org.cloudstrolling.cloudoffice.common.model.ErrorCode` 接口
2. 保持与现有枚举常量相同的代码风格和注释规范
3. 不可删除或修改现有的通用错误码（SUCCESS/BAD_REQUEST 等）
4. 每个枚举添加行内注释标注 AUTH 模块编号（如 `/* AUTH-0001 */`）

#### 测试验收方法
- 单元测试验证每个新增错误码的 `getCode()` 和 `getMessage()` 返回值与 PRD 一致
- 现有测试不受影响
- `mvn compile -pl cloudoffice-common` 编译通过

---

## 2.2 客户端类型枚举

### 2.2.1 TASK-002：新增 ClientTypeEnum 枚举

**任务ID：** TASK-002
**任务名称：** 新增 ClientTypeEnum 枚举（含设备分类 DeviceCategory）
**任务类型：** common
**关联UserStory：** US-002
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-022（登录认证使用 ClientTypeEnum）

#### 上下文读取
- **PRD US-002 AC1~AC5**：6 种客户端类型定义、fromCode 方法、isSameCategory 方法
- **SDS 附录 B ClientTypeEnum 枚举定义**：完整的枚举定义表和方法签名
- **SDS 1.4 关键设计原则**：多端互斥逻辑 - 四类设备分类（PC/WEB/MOBILE/MINI_PROGRAM）
- **project.md 文件组织规范**：枚举位于 `org.cloudstrolling.cloudoffice.common.enums` 包

#### 详细业务描述
在 `cloudoffice-common` 模块的 `org.cloudstrolling.cloudoffice.common.enums` 包下创建 `ClientTypeEnum` 枚举，定义 6 种客户端类型及其设备分类。

**枚举值定义：**

| 枚举值 | code | label | deviceCategory |
|--------|------|-------|---------------|
| WINDOWS | WINDOWS | Windows 桌面端 | PC |
| UBUNTU | UBUNTU | Ubuntu 桌面端 | PC |
| H5 | H5 | H5 网页端 | WEB |
| ANDROID | ANDROID | Android 移动端 | MOBILE |
| IOS | IOS | iOS 移动端 | MOBILE |
| WECHAT_MINI | WECHAT_MINI | 微信小程序端 | MINI_PROGRAM |

**设备分类 DeviceCategory：**
- 内部枚举（定义在 ClientTypeEnum 内部或独立枚举类）
- 包含 4 个值：PC、WEB、MOBILE、MINI_PROGRAM

**方法定义：**
1. `static Optional<ClientTypeEnum> fromCode(String code)` — 根据 code 查找枚举，返回 Optional（大小写敏感）
2. `boolean isSameCategory(ClientTypeEnum other)` — 判断是否同设备分类（互斥登录依据）

**核心要求：**
- 枚举不可依赖任何业务模块
- 使用 Lombok `@Getter` 注解简化 getter
- 从 code 到枚举的查找使用 `Map<String, ClientTypeEnum>` 静态缓存

#### 测试验收方法
- `fromCode("WINDOWS")` 返回 `Optional.of(WINDOWS)`
- `fromCode(null)` 返回 `Optional.empty()`
- `fromCode("windows")`（小写）返回 `Optional.empty()`
- `WINDOWS.isSameCategory(UBUNTU)` 返回 `true`
- `WINDOWS.isSameCategory(H5)` 返回 `false`
- `mvn compile -pl cloudoffice-common` 编译通过

---

## 2.3 Token DTO

### 2.3.1 TASK-003：新增认证相关 DTO

**任务ID：** TASK-003
**任务名称：** 新增 TokenPairDTO 和 LoginUserDTO
**任务类型：** common
**关联UserStory：** US-003
**优先级：** P1
**当前状态：** commit_finish

#### 上下游任务
- 下游任务：TASK-018（JwtUtils 使用 LoginUserDTO）、TASK-030（AuthController 使用 TokenPairDTO）

#### 上下文读取
- **PRD US-003 AC1~AC3**：TokenPairDTO 和 LoginUserDTO 的字段定义和 Lombok 注解要求
- **SDS 2.3 公共模块**：DTO 的字段描述
- **SDS 4.5 DTO 定义**：完整的 Java 类定义代码示例
- **project.md 编码规范**：Lombok 使用规范、Serializable 实现要求

#### 详细业务描述
在 `cloudoffice-common` 模块的 `org.cloudstrolling.cloudoffice.common.dto` 包下创建两个 DTO 类。

**TokenPairDTO.java：**
```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TokenPairDTO implements Serializable {
    private static final long serialVersionUID = 1L;
    private String accessToken;              // Access Token (RS256, 2h)
    private String refreshToken;             // Refresh Token (RS256, 7d)
    private Long accessTokenExpiresIn;       // Access Token 过期毫秒时间戳
    private Long refreshTokenExpiresIn;      // Refresh Token 过期毫秒时间戳
    private String tokenType;                // 固定值 "Bearer"
}
```

**LoginUserDTO.java：**
```java
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginUserDTO implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long userId;                     // 用户 ID
    private Long tenantId;                   // 租户 ID
    private String userName;                 // 用户名
    private String clientType;               // 客户端类型编码
    private List<String> roles;              // 角色编码列表（默认空列表）
    private List<String> permissions;        // 权限标识列表（默认空列表）
}
```

**核心要求：**
- 使用 Lombok 注解（`@Data`、`@Builder`、`@NoArgsConstructor`、`@AllArgsConstructor`）
- 实现 `Serializable` 接口并定义 `serialVersionUID`
- roles 和 permissions 字段默认初始化为 `Collections.emptyList()`（通过 @Builder.Default 或在构造器中处理）

#### 测试验收方法
- 单元测试验证字段可正常访问
- 单元测试验证序列化 ID 存在
- 单元测试验证 roles/permissions 为 null 时默认空列表
- 单元测试验证 Builder 模式可用
- `mvn compile -pl cloudoffice-common` 编译通过

---

## 2.4 Redis Key 常量

### 2.4.1 TASK-004：新增 RedisKeyConstants 常量管理类

**任务ID：** TASK-004
**任务名称：** 新增 RedisKeyConstants 常量管理类
**任务类型：** common
**关联UserStory：** US-005, US-021
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-006（网关 Redis 集成引用常量）、TASK-019（LoginSessionService 引用常量）

#### 上下文读取
- **PRD US-005 AC4**：Redis Key 前缀格式定义
- **SDS 2.3 公共模块**：RedisKeyConstants 功能描述
- **SDS 3.4 缓存设计**：4 种缓存 Key 格式、TTL 和用途
- **SDS 5.5 Redis Key 设计**：完整的 Key 格式、TTL、用途、操作方

#### 详细业务描述
在 `cloudoffice-common` 模块的 `org.cloudstrolling.cloudoffice.common.constant` 包下创建 `RedisKeyConstants` 常量管理类。

**常量定义：**

| 常量名 | Key 模板 | 用途 |
|--------|---------|------|
| `SESSION_KEY_PREFIX` | `auth:session:` | 登录态会话 |
| `BLACKLIST_KEY_PREFIX` | `auth:token:blacklist:` | Token 黑名单 |
| `ACCOUNT_STATUS_KEY_PREFIX` | `auth:account:status:` | 账号状态缓存 |
| `TENANT_STATUS_KEY_PREFIX` | `auth:tenant:status:` | 租户状态缓存 |

**方法定义：**
1. `static String buildSessionKey(Long userId, String clientType)` — 构建 `auth:session:{userId}:{clientType}`
2. `static String buildBlacklistKey(String tokenSignature)` — 构建 `auth:token:blacklist:{tokenSignature}`
3. `static String buildAccountStatusKey(Long userId)` — 构建 `auth:account:status:{userId}`
4. `static String buildTenantStatusKey(Long tenantId)` — 构建 `auth:tenant:status:{tenantId}`

**核心要求：**
- 使用 `@UtilityClass` 或私有构造器实现工具类
- Redis Key 统一在此类管理，禁止在其他地方硬编码 Key 字符串

#### 测试验收方法
- 单元测试验证 `buildSessionKey(1L, "WINDOWS")` 返回 `"auth:session:1:WINDOWS"` 
- 单元测试验证 Key 构建方法的参数校验（null 参数抛出 IllegalArgumentException）
- `mvn compile -pl cloudoffice-common` 编译通过

---

# 3. 父 POM 依赖管理

## 3.1 依赖补充确认

### 3.1.1 TASK-005：父 POM 依赖补充确认

**任务ID：** TASK-005
**任务名称：** 父 POM 依赖补充确认
**任务类型：** common
**关联UserStory：** US-024
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-006（网关 Redis 依赖）、TASK-010（认证服务依赖）

#### 上下文读取
- **PRD US-024 AC1/AC2**：确认依赖版本管理状态
- **现有父 POM 内容**：已包含 MyBatis-Plus、MariaDB、JJWT、Hutool、SpringDoc、Lombok 等版本声明
- **现有 auth-service pom.xml**：缺少 Redis、MyBatis-Plus、MariaDB 等依赖
- **现有 gateway pom.xml**：缺少 Redis 依赖

#### 详细业务描述
检查并确认父 POM（根 `pom.xml`）的 `<dependencyManagement>` 已覆盖本次开发所需的全部依赖：

**确认事项：**
1. `spring-boot-starter-data-redis` 和 `commons-pool2` — 版本由 `spring-boot-dependencies` BOM 管理，无需在父 POM 额外声明
2. `mybatis-plus-spring-boot3-starter` — 已在父 POM 声明版本 `3.5.6`
3. `mariadb-java-client` — 已在父 POM 声明版本 `3.3.3`
4. `spring-boot-starter-validation` — 由 Spring Boot BOM 管理，用于 `@Valid` 参数校验
5. 各项依赖版本无冲突

**如检查发现依赖缺失，需补充到父 POM 的 `<dependencyManagement>` 中。**

#### 测试验收方法
- `mvn dependency:tree` 输出无版本冲突
- 各子模块编译通过，无依赖缺失

---

# 4. cloudoffice-gateway（API 网关）

## 4.1 Redis 集成

### 4.1.1 TASK-006：网关集成 Redis 配置

**任务ID：** TASK-006
**任务名称：** 网关集成 Redis 配置
**任务类型：** backend
**关联UserStory：** US-005
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-005（父 POM 依赖）
- 下游任务：TASK-009（AuthFilter 使用 Redis）

#### 上下文读取
- **PRD US-005 AC1~AC4**：依赖声明、Redis 配置项、ReactiveRedisTemplate Bean、Key 格式
- **SDS 2.4 网关模块**：ReactiveRedisTemplate Bean、Redis 集成说明
- **SDS 3.4 缓存设计**：Redis Key 格式、TTL
- **architecture.md 2.2**：网关集成 Redis 查询能力
- **project.md 测试规范**：测试环境需排除 Redis 自动配置

#### 详细业务描述
在 `cloudoffice-gateway` 模块中集成 Spring Data Redis，使用响应式非阻塞客户端。

**① pom.xml 新增依赖：**
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-redis</artifactId>
</dependency>
<dependency>
    <groupId>org.apache.commons</groupId>
    <artifactId>commons-pool2</artifactId>
</dependency>
```

**② application.yml 新增 Redis 配置：**
```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:127.0.0.1}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}
      database: ${REDIS_DATABASE:0}
      timeout: 3000ms
      lettuce:
        pool:
          max-active: 16
          max-idle: 8
          min-idle: 4
          max-wait: -1ms
```

**③ RedisConfig.java：**
在 `org.cloudstrolling.cloudoffice.gateway.config` 包下创建 `RedisConfig` 配置类：
- 使用 `@Configuration` 注解
- 创建 `ReactiveRedisTemplate<String, Object>` Bean
- 设置 Key 序列化为 `StringRedisSerializer`
- 设置 Value 序列化为 `Jackson2JsonRedisSerializer<Object>`

**关键点：**
- 必须使用 `ReactiveRedisTemplate`（响应式非阻塞），而非传统阻塞式 `RedisTemplate`
- 环境变量支持默认值，确保本地开发可无 Redis 配置启动

#### 测试验收方法
- 网关启动后 `ReactiveRedisTemplate` Bean 正常注入
- Redis 连接配置正确（连接真实或 Mock Redis 均可）
- 测试环境需通过 `@SpringBootTest` 排除 Redis 自动配置

---

## 4.2 RSA 公钥加载

### 4.2.1 TASK-007：网关 RSA 公钥加载配置

**任务ID：** TASK-007
**任务名称：** 网关 RSA 公钥加载配置
**任务类型：** backend
**关联UserStory：** US-019
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-009（AuthFilter 使用 RSA 公钥验签）

#### 上下文读取
- **PRD US-019 AC1/AC2**：网关配置 RSA 公钥
- **PRD US-019 AC6**：三种加载方式（环境变量 → 配置文件 Base64 → PEM 文件路径）
- **SDS 5.2 认证机制**：密钥加载优先级
- **architecture.md ADR-011**：RS256 非对称加密选型决策

#### 详细业务描述
在 `cloudoffice-gateway` 模块的 `org.cloudstrolling.cloudoffice.gateway.config` 包下创建 `RsaKeyConfig` 配置类。

**功能：**
1. 从配置/环境变量加载 RSA 公钥（Base64 编码）
2. 支持三种加载方式（优先级从高到低）：环境变量 → 配置文件 Base64 → PEM 文件路径
3. 将 Base64 解码为 `java.security.PublicKey` 对象
4. 提供 `getPublicKey()` 方法供 AuthFilter 调用

**application.yml 新增配置：**
```yaml
jwt:
  rsa:
    public-key: ${JWT_RSA_PUBLIC_KEY:}
```

**核心要求：**
- 公钥配置为空时服务启动失败，抛出 `IllegalArgumentException` 并打印明确错误信息
- Base64 解码失败时抛出异常并打印解码异常信息
- 密钥位数不足 2048 位时提示密钥强度不足
- 使用 `java.security.KeyFactory` 和 `X509EncodedKeySpec` 加载 RSA 公钥

#### 测试验收方法
- 提供测试专用公钥配置，验证公钥可正常加载
- 公钥配置为空时验证启动失败
- 公钥格式无效时验证异常抛出
- 单元测试验证 `getPublicKey()` 返回有效的 PublicKey 对象

---

## 4.3 白名单配置

### 4.3.1 TASK-008：网关白名单路径配置

**任务ID：** TASK-008
**任务名称：** 网关白名单路径配置
**任务类型：** backend
**关联UserStory：** US-004
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-009（AuthFilter 使用白名单配置）

#### 上下文读取
- **PRD US-004 AC1**：白名单路径清单
- **PRD US-004 AC8**：白名单通过配置项 `auth.white-list` 动态配置
- **SDS 2.4 网关模块**：白名单路径清单

#### 详细业务描述
在网关的 `application.yml` 中新增白名单路径配置项。

**新增配置：**
```yaml
auth:
  white-list:
    - /api/v1/auth/login
    - /api/v1/auth/register
    - /api/v1/auth/refresh
    - /api/v1/auth/health
    - /swagger-ui/**
    - /v3/api-docs/**
    - /favicon.ico
```

**创建配置属性类 `AuthProperties.java`：**
在 `org.cloudstrolling.cloudoffice.gateway.config` 包下创建，使用 `@ConfigurationProperties(prefix = "auth")` 注解。

```java
@Data
@Component
@ConfigurationProperties(prefix = "auth")
public class AuthProperties {
    private List<String> whiteList = new ArrayList<>();
}
```

**核心要求：**
- 白名单路径通过 `application.yml` 配置，非硬编码
- 路径支持 Ant 风格匹配（如 `/swagger-ui/**`）

#### 测试验收方法
- `AuthProperties` Bean 正常注入
- 白名单配置值正确读取
- 验证 `/api/v1/auth/login` 在配置列表中

---

## 4.4 全局认证过滤器

### 4.4.1 TASK-009：网关 AuthFilter 全局认证过滤器实现

**任务ID：** TASK-009
**任务名称：** 网关 AuthFilter 全局认证过滤器实现
**任务类型：** backend
**关联UserStory：** US-004
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-006（Redis 集成）、TASK-007（RSA 公钥）、TASK-008（白名单配置）
- 下游任务：TASK-030（AuthController 需考虑网关过滤规则）

#### 上下文读取
- **PRD US-004 AC1~AC8**：过滤器完整行为定义
- **PRD US-004 边界情况与错误处理**：7 种边界场景的预期行为
- **SDS 2.4 网关模块**：AuthFilter 校验流程、白名单路径、Header 透传规范
- **SDS 1.3 API 请求校验流程**：完整的 8 步校验流程图
- **SDS 4.6 网关透传 Header 规范**：6 个透传 Header 的名称和格式
- **architecture.md 数据流 4.1**：API 请求校验流程详细步骤

#### 详细业务描述
在 `cloudoffice-gateway` 模块的 `org.cloudstrolling.cloudoffice.gateway.filter` 包下创建 `AuthFilter` 全局认证过滤器。

**实现接口：** `GlobalFilter`、`Ordered`

**优先级：** `Ordered.HIGHEST_PRECEDENCE + 10`

**核心校验流程：**
1. **白名单校验**：请求路径是否在白名单中，是则直接放行
2. **Token 格式校验**：检查 `Authorization` 头是否为 `Bearer <token>` 格式
3. **RS256 公钥验签**：使用 RsaKeyConfig 的公钥验签，解析 Claims
4. **Redis 黑名单查询**：查询 `auth:token:blacklist:{signature}`，判断 Token 是否被吊销
5. **Redis 登录态查询**：查询 `auth:session:{userId}:{clientType}`，判断会话是否有效
6. **账号状态校验**：查询 `auth:account:status:{userId}`，判断账号是否禁用/封禁
7. **租户状态校验**：查询 `auth:tenant:status:{tenantId}`，判断租户是否禁用/过期
8. **Header 透传**：校验通过后，透传 X-User-Id / X-Tenant-Id / X-User-Name / X-Client-Type / X-Roles / X-Permissions

**错误处理（ServerWebExchange 响应式方式）：**
- 使用 `ServerHttpResponse` 设置 HTTP 状态码和 JSON 响应体
- 返回统一格式 `ApiResult` 响应

**注入方式：**
- `@Component` 注册为 Spring Bean
- 构造器注入 `ReactiveRedisTemplate`、`RsaKeyConfig`、`AuthProperties`

#### 测试验收方法
- 白名单路径直接放行
- 无 Authorization 头返回 401
- 有效 Token 通过校验并透传正确 Header
- Token 在黑名单中返回 401 TOKEN_BLACKLISTED
- 登录态不存在返回 401 SESSION_KICKED_OUT
- 账号被封禁返回 403 ACCOUNT_BANNED
- 使用 Spring Cloud Gateway 测试框架（`@SpringBootTest` + WebTestClient）

---

# 5. cloudoffice-auth-service（认证服务）

## 5.1 基础设施

### 5.1.1 TASK-010：认证服务 pom.xml 依赖补充

**任务ID：** TASK-010
**任务名称：** 认证服务 pom.xml 依赖补充
**任务类型：** backend
**关联UserStory：** US-023
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-005（父 POM 依赖）
- 下游任务：TASK-011（认证服务配置）

#### 上下文读取
- **PRD US-023 AC1**：需新增的 4 项依赖清单
- **现有 auth-service pom.xml**：当前已有 Spring Web、Security、OAuth2、JJWT、Nacos、Common、Lombok、Test
- **父 POM 依赖管理**：MyBatis-Plus 3.5.6、MariaDB 3.3.3 已在父 POM 声明

#### 详细业务描述
在 `cloudoffice-auth-service/pom.xml` 中补充以下依赖：

**新增依赖：**
| 依赖 | groupId:artifactId | Scope | 说明 |
|------|-------------------|-------|------|
| MyBatis-Plus | `com.baomidou:mybatis-plus-spring-boot3-starter` | compile | ORM 框架 |
| MariaDB 驱动 | `org.mariadb.jdbc:mariadb-java-client` | compile | 数据库连接 |
| Spring Data Redis | `org.springframework.boot:spring-boot-starter-data-redis` | compile | Redis 缓存 |
| 连接池 | `org.apache.commons:commons-pool2` | compile | Redis 连接池 |
| 参数校验 | `org.springframework.boot:spring-boot-starter-validation` | compile | @Valid 注解支持 |

**核心要求：**
- 所有依赖版本由父 POM 统一管理，子模块不出现硬编码版本号
- MyBatis-Plus 和 MariaDB 驱动已在父 POM 声明版本，直接引用

#### 测试验收方法
- `mvn clean compile -pl cloudoffice-auth-service -am` 编译通过
- `mvn dependency:tree -pl cloudoffice-auth-service` 确认依赖正确引入

---

### 5.1.2 TASK-011：认证服务 application.yml 数据库与缓存配置

**任务ID：** TASK-011
**任务名称：** 认证服务 application.yml 数据源与缓存配置
**任务类型：** backend
**关联UserStory：** US-023
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-010（pom.xml 依赖）
- 下游任务：TASK-012（MyBatis-Plus 配置）

#### 上下文读取
- **PRD US-023 AC2/AC3**：MariaDB 数据源配置和 Redis 配置模板
- **SDS 3.1 数据库概述**：数据库名 `cloudstroll_office_auth`
- **architecture.md 5.6 数据库设计规范**：数据库连接配置规范

#### 详细业务描述
在 `cloudoffice-auth-service/src/main/resources/application.yml` 中新增 MariaDB 数据源配置和 Redis 缓存配置。

**MariaDB 数据源配置：**
```yaml
spring:
  datasource:
    url: jdbc:mariadb://${DB_HOST:127.0.0.1}:${DB_PORT:3306}/cloudstroll_office_auth?useUnicode=true&characterEncoding=utf-8&serverTimezone=Asia/Shanghai
    username: ${DB_USER:root}
    password: ${DB_PASSWORD:root}
    driver-class-name: org.mariadb.jdbc.Driver
    hikari:
      minimum-idle: 5
      maximum-pool-size: 20
      idle-timeout: 300000
      max-lifetime: 1200000
```

**Redis 配置：**
```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:127.0.0.1}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}
      database: ${REDIS_DATABASE:0}
      timeout: 3000ms
      lettuce:
        pool:
          max-active: 16
          max-idle: 8
          min-idle: 4
```

**JWT 配置：**
```yaml
jwt:
  access-token-expiration: 7200000    # 2 小时（毫秒）
  refresh-token-expiration: 604800000 # 7 天（毫秒）
  rsa:
    private-key: ${JWT_RSA_PRIVATE_KEY:}
    public-key: ${JWT_RSA_PUBLIC_KEY:}
```

**核心要求：**
- 所有连接参数支持环境变量覆盖，提供合理的默认值
- 数据库密码和 RSA 密钥通过环境变量注入，禁止明文硬编码
- 排除 `DataSourceAutoConfiguration` 以支持无数据库启动测试

#### 测试验收方法
- 服务启动后数据库和 Redis 连接正常
- 环境变量覆盖生效
- `curl http://localhost:9100/api/v1/auth/health` 返回 200

---

### 5.1.3 TASK-012：认证服务 MyBatis-Plus 配置类

**任务ID：** TASK-012
**任务名称：** 认证服务 MyBatis-Plus 配置类
**任务类型：** backend
**关联UserStory：** US-023
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-011（application.yml 配置）
- 下游任务：TASK-015（Mapper 实现）

#### 上下文读取
- **SDS 3.1 数据库概述**：MyBatis-Plus 3.5.x 配置要求
- **project.md 编码规范**：MyBatis-Plus 自动填充配置（createTime/updateTime/deleted）
- **现有 common 模块 MyBatisPlusConfig**：参考 `cloudoffice-common` 中的配置风格

#### 详细业务描述
在 `cloudoffice-auth-service` 的 `org.cloudstrolling.cloudoffice.auth.config` 包下创建 MyBatis-Plus 配置类。

**配置内容：**
1. `@Configuration` + `@MapperScan("org.cloudstrolling.cloudoffice.auth.mapper")` 注解
2. 分页插件 `PaginationInnerInterceptor` Bean（MyBatis-Plus 3.5.6 新配置方式）
3. 自动填充处理器 `MetaObjectHandler` 实现（或复用 common 模块的配置）
4. 性能分析插件（开发环境）

**核心要求：**
- 包扫描路径指向 `org.cloudstrolling.cloudoffice.auth.mapper`
- 分页插件使用 `MybatisPlusInterceptor` 注册
- 自动填充逻辑与 common 模块保持一致（创建时间/更新时间/逻辑删除）

#### 测试验收方法
- 配置类 Bean 正常加载
- Mapper 扫描路径正确
- 分页查询功能正常

---

## 5.2 数据层

### 5.2.1 TASK-013：数据库初始化 SQL 脚本（7 张表 DDL）

**任务ID：** TASK-013
**任务名称：** 数据库初始化 SQL 脚本（7 张表 DDL）
**任务类型：** backend
**关联UserStory：** US-006, US-007, US-009, US-010, US-011, US-012, US-022
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-014（实体类创建）

#### 上下文读取
- **PRD US-006**：`t_auth_user` 表结构（字段、索引、约束）
- **PRD US-007**：`t_auth_tenant` 表结构
- **PRD US-009**：`t_auth_role` 表结构
- **PRD US-010**：`t_auth_permission` 表结构
- **PRD US-011**：`t_auth_user_role` 表结构
- **PRD US-012**：`t_auth_role_permission` 表结构
- **PRD US-022 AC1/AC2**：`t_auth_login_log` 表结构
- **SDS 3.2 表结构设计**：7 张表的完整字段定义、数据类型、约束、索引
- **SDS 3.3 ER 图**：表间关系
- **architecture.md 5.6 数据库设计规范**：表命名 `t_{module}_{name}`、字段命名下划线、雪花算法主键

#### 详细业务描述
在 `scripts/sql/auth-init-v0.1.5.sql` 中创建 7 张表的 DDL 建表脚本。

**表清单：**
1. `t_auth_tenant` — 租户表（含 `uk_tenant_code` 唯一索引）
2. `t_auth_user` — 用户表（含 `uk_tenant_login_name` 唯一索引、`idx_tenant_status`、`idx_phone`）
3. `t_auth_role` — 角色表（含 `uk_tenant_role_code` 唯一索引）
4. `t_auth_permission` — 权限表（含 `uk_perm_code` 唯一索引）
5. `t_auth_user_role` — 用户-角色关联表（含 `uk_user_role` 联合唯一索引、`idx_user_id`、`idx_role_id`）
6. `t_auth_role_permission` — 角色-权限关联表（含 `uk_role_permission` 联合唯一索引、`idx_role_id`、`idx_permission_id`）
7. `t_auth_login_log` — 登录日志表（含 `idx_user_id`、`idx_tenant_id`、`idx_login_time`）

**DDL 模板（t_auth_user 示例）：**
```sql
CREATE TABLE `t_auth_user` (
  `id` BIGINT(20) NOT NULL COMMENT '主键（雪花算法）',
  `tenant_id` BIGINT(20) NOT NULL COMMENT '租户ID',
  `login_name` VARCHAR(64) NOT NULL COMMENT '登录名',
  `password` VARCHAR(256) NOT NULL COMMENT 'BCrypt加密密码',
  ...
  `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `deleted` TINYINT(4) DEFAULT 0 COMMENT '逻辑删除（0-正常，1-删除）',
  PRIMARY KEY (`id`),
  UNIQUE INDEX `uk_tenant_login_name` (`tenant_id`, `login_name`),
  INDEX `idx_tenant_status` (`tenant_id`, `status`),
  INDEX `idx_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';
```

**核心要求：**
- 每张表包含 `id`（雪花算法 BIGINT PK）、`create_time`、`update_time`、`deleted`
- 严格遵循 SDS 3.2 定义的字段类型、约束、默认值
- 包含初始数据插入（默认租户、默认角色、默认管理员账号）

#### 测试验收方法
- SQL 脚本在 MariaDB 10.6 执行成功
- 7 张表全部创建成功
- 所有索引正确创建
- 初始数据插入成功

---

### 5.2.2 TASK-014：RBAC 实体类创建（7 个 Entity）

**任务ID：** TASK-014
**任务名称：** RBAC 实体类创建（7 个 Entity）
**任务类型：** backend
**关联UserStory：** US-006, US-007, US-009, US-010, US-011, US-012, US-022
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-015（Mapper 实现）、TASK-016（日志 Mapper）

#### 上下文读取
- **SDS 3.2 表结构设计**：7 张表的完整字段定义
- **architecture.md 5.6 数据库设计规范**：表命名、字段命名、主键策略
- **project.md 编码规范**：BaseEntity 继承、Lombok 注解使用

#### 详细业务描述
在 `cloudoffice-auth-service` 的 `org.cloudstrolling.cloudoffice.auth.entity` 包下创建 7 个实体类。

**实体类清单：**

| 实体类 | @TableName | 继承 | 说明 |
|--------|-----------|------|------|
| `TenantEntity` | `t_auth_tenant` | BaseEntity | 租户实体 |
| `UserEntity` | `t_auth_user` | BaseEntity | 用户实体 |
| `RoleEntity` | `t_auth_role` | BaseEntity | 角色实体 |
| `PermissionEntity` | `t_auth_permission` | BaseEntity | 权限实体 |
| `UserRoleEntity` | `t_auth_user_role` | BaseEntity | 用户-角色关联实体 |
| `RolePermissionEntity` | `t_auth_role_permission` | BaseEntity | 角色-权限关联实体 |
| `LoginLogEntity` | `t_auth_login_log` | BaseEntity | 登录日志实体 |

**核心要求：**
- 每个实体类使用 `@Data`、`@TableName` 注解
- 继承 `BaseEntity` 获取 `id`、`createTime`、`updateTime`、`deleted` 字段
- 字段命名使用驼峰命名法，MyBatis-Plus 自动映射下划线
- 使用 `@TableField` 注解标记逻辑删除字段（如适用）

#### 测试验收方法
- 编译通过
- 实体类与数据库表字段一一对应

---

### 5.2.3 TASK-015：RBAC 数据访问层（Mapper + XML）

**任务ID：** TASK-015
**任务名称：** RBAC 数据访问层（Mapper 接口 + XML 映射文件）
**任务类型：** backend
**关联UserStory：** US-006, US-007, US-009, US-010, US-011, US-012
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-014（实体类）
- 下游任务：TASK-021（注册）、TASK-022（登录）、TASK-027（用户管理 API）

#### 上下文读取
- **SDS 3.2 表结构设计**：表关系（ER 图）
- **PRD US-013**：用户详情需包含角色和权限列表
- **architecture.md 5.1 数据模型概览**：表间关联关系

#### 详细业务描述
在 `cloudoffice-auth-service` 的 `org.cloudstrolling.cloudoffice.auth.mapper` 包下创建 6 个 RBAC Mapper 接口。

**Mapper 清单：**

| Mapper 接口 | 对应实体 | 说明 |
|------------|---------|------|
| `TenantMapper` | TenantEntity | 租户基本 CRUD |
| `UserMapper` | UserEntity | 用户基本 CRUD + 按 loginName+tenantId 查询 |
| `RoleMapper` | RoleEntity | 角色基本 CRUD + 按租户查询 |
| `PermissionMapper` | PermissionEntity | 权限基本 CRUD + 树形查询 |
| `UserRoleMapper` | UserRoleEntity | 用户-角色关联（按用户查询角色列表） |
| `RolePermissionMapper` | RolePermissionEntity | 角色-权限关联（按角色查询权限列表） |

**核心要求：**
- 所有 Mapper 继承 `BaseMapper<T>` 接口
- 复杂查询（如用户详情含角色权限）使用 `@Select` 注解或 XML 映射
- 角色和权限的联表查询使用 MyBatis-Plus 的 `@Select` 注解执行 SQL

**关键查询方法示例：**
```java
public interface UserMapper extends BaseMapper<UserEntity> {
    // 按租户+登录名查询用户
    @Select("SELECT * FROM t_auth_user WHERE tenant_id = #{tenantId} AND login_name = #{loginName} AND deleted = 0")
    UserEntity selectByTenantIdAndLoginName(@Param("tenantId") Long tenantId, @Param("loginName") String loginName);
    
    // 查询用户角色编码列表
    @Select("SELECT r.role_code FROM t_auth_user_role ur INNER JOIN t_auth_role r ON ur.role_id = r.id WHERE ur.user_id = #{userId} AND r.status = 0 AND r.deleted = 0")
    List<String> selectRoleCodesByUserId(@Param("userId") Long userId);
    
    // 查询用户权限标识列表
    @Select("SELECT DISTINCT p.perm_code FROM t_auth_user_role ur INNER JOIN t_auth_role_permission rp ON ur.role_id = rp.role_id INNER JOIN t_auth_permission p ON rp.permission_id = p.id WHERE ur.user_id = #{userId} AND p.status = 0 AND p.deleted = 0")
    List<String> selectPermissionCodesByUserId(@Param("userId") Long userId);
}
```

#### 测试验收方法
- 每个 Mapper 的 CRUD 基本操作正常
- 联表查询返回正确数据
- `mvn compile -pl cloudoffice-auth-service -am` 编译通过

---

### 5.2.4 TASK-016：登录日志 Entity + Mapper

**任务ID：** TASK-016
**任务名称：** 登录日志 Entity + Mapper
**任务类型：** backend
**关联UserStory：** US-022
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-014（实体类创建）
- 下游任务：TASK-020（日志审计服务）

#### 上下文读取
- **PRD US-022 AC1/AC2**：登录日志表字段定义
- **SDS 3.2.7**：t_auth_login_log 表结构

#### 详细业务描述
创建 `LoginLogEntity` 实体类和 `LoginLogMapper` 接口。

**LoginLogEntity.java：**
位于 `org.cloudstrolling.cloudoffice.auth.entity` 包：
- `@Data` + `@TableName("t_auth_login_log")`
- 继承 `BaseEntity`
- 字段：tenantId, userId, loginName, loginIp, loginLocation, clientType, deviceInfo, loginTime, logoutTime, loginStatus, failReason

**LoginLogMapper.java：**
位于 `org.cloudstrolling.cloudoffice.auth.mapper` 包：
- 继承 `BaseMapper<LoginLogEntity>`
- 提供基本 CRUD 操作

#### 测试验收方法
- 编译通过
- 插入和查询登录日志记录正常

---

## 5.3 服务层 - 基础设施服务

### 5.3.1 TASK-017：认证服务 RSA 密钥配置类（RsaKeyConfig）

**任务ID：** TASK-017
**任务名称：** 认证服务 RSA 密钥配置类
**任务类型：** backend
**关联UserStory：** US-019
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 下游任务：TASK-018（JwtUtils 重构依赖 RSA 密钥）

#### 上下文读取
- **PRD US-019 AC1~AC6**：RSA 密钥加载完整要求
- **SDS 5.2 认证机制**：密钥加载优先级（环境变量 → 配置文件 Base64 → PEM 文件）
- **architecture.md ADR-011**：RS256 非对称加密选型

#### 详细业务描述
在 `cloudoffice-auth-service` 的 `org.cloudstrolling.cloudoffice.auth.config` 包下创建 `RsaKeyConfig` 配置类。

**功能：**
1. 同时加载 RSA 私钥和公钥（Base64 编码）
2. 支持三种加载方式（优先级从高到低）：环境变量 → 配置文件 Base64 → PEM 文件路径
3. 将 Base64 解码为 `java.security.PrivateKey` 和 `java.security.PublicKey` 对象
4. 提供 `getPrivateKey()` 和 `getPublicKey()` 方法

**application.yml 配置：**
```yaml
jwt:
  rsa:
    private-key: ${JWT_RSA_PRIVATE_KEY:}
    public-key: ${JWT_RSA_PUBLIC_KEY:}
```

**核心要求：**
- 使用 `@Configuration` + `@ConfigurationProperties(prefix = "jwt.rsa")` 注解
- @PostConstruct 初始化时校验密钥有效性
- 私钥使用 `PKCS8EncodedKeySpec` 加载，公钥使用 `X509EncodedKeySpec` 加载
- 密钥为空时服务启动失败，抛出明确异常

#### 测试验收方法
- 提供测试密钥对，验证公私钥加载成功
- 密钥无效时验证启动失败
- `getPrivateKey()` 返回有效的 PrivateKey 对象
- `getPublicKey()` 返回有效的 PublicKey 对象

---

### 5.3.2 TASK-018：JwtUtils 重构（RS256 双 Token）

**任务ID：** TASK-018
**任务名称：** JwtUtils 重构（支持 RS256 双 Token 签发/解析/指纹提取）
**任务类型：** backend
**关联UserStory：** US-020
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-017（RSA 密钥配置）
- 下游任务：TASK-022（登录认证）、TASK-023（Token 刷新）

#### 上下文读取
- **PRD US-020 AC1~AC8**：JwtUtils 完整方法定义和验收标准
- **PRD US-020 边界情况与错误处理**：5 种异常场景
- **SDS 附录 C JwtUtils 方法签名**：完整方法签名
- **SDS 5.2 认证机制**：Access Token 2h、Refresh Token 7d、tokenType 声明
- **现有 JwtUtils**：位于 `org.cloudstrolling.cloudoffice.auth.util`，需重构

#### 详细业务描述
重构 `cloudoffice-auth-service` 模块 `util` 包下的 `JwtUtils` 类。

**重构后方法：**
1. `String generateAccessToken(LoginUserDTO loginUser)` — 签发 Access Token（2h）
   - 声明：`sub`=userId, `tenantId`, `clientType`, `tokenType`="access", `roles`, `permissions`, `iat`, `exp`
2. `String generateRefreshToken(LoginUserDTO loginUser)` — 签发 Refresh Token（7d）
   - 声明：`sub`=userId, `tenantId`, `clientType`, `tokenType`="refresh", `iat`, `exp`, `tokenVersion`(UUID)
3. `Claims parseAccessToken(String token)` — 解析 Access Token，校验 tokenType="access"
4. `Claims parseRefreshToken(String token)` — 解析 Refresh Token，校验 tokenType="refresh"
5. `String getTokenSignature(String token)` — 获取 Token 签名指纹（SHA-256 摘要），用于黑名单 Key

**核心要点：**
- 从 `@Component` + `@Value` 字段注入改造为构造器注入
- 支持通过配置设置 Token 有效期（`jwt.access-token-expiration`、`jwt.refresh-token-expiration`）
- 使用 RS256 算法（`SignatureAlgorithm.RS256`）
- 保留对 HS256 的兼容处理（过渡期后可移除）

**异常处理：**
- 签名验证失败 → 抛出 `SignatureException`
- Token 过期 → 抛出 `ExpiredJwtException`
- Token 格式错误 → 抛出 `MalformedJwtException`

#### 测试验收方法
- 单元测试覆盖率 ≥ 90%
- generateAccessToken → parseAccessToken 成功返回 Claims
- generateRefreshToken → parseRefreshToken 成功返回 Claims
- Access Token 使用 parseRefreshToken 解析失败
- Token 签名指纹校验：相同 Token 返回相同指纹
- Token 过期校验
- Token 格式错误/签名错误异常
- `mvn test -pl cloudoffice-auth-service` 通过

---

### 5.3.3 TASK-019：Redis 登录态管理服务（LoginSessionService）

**任务ID：** TASK-019
**任务名称：** Redis 登录态管理服务实现
**任务类型：** backend
**关联UserStory：** US-021
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-011（Redis 配置）、TASK-004（RedisKeyConstants）
- 下游任务：TASK-022（登录）、TASK-023（刷新）、TASK-024（登出）、TASK-025（踢人）、TASK-026（封禁）

#### 上下文读取
- **PRD US-021 AC1~AC8**：LoginSessionService 完整方法定义
- **SDS 2.5 认证服务组件**：LoginSessionService 功能描述
- **SDS 3.4 缓存设计**：4 种缓存 Key 格式、TTL、操作方

#### 详细业务描述
在 `cloudoffice-auth-service` 的 `org.cloudstrolling.cloudoffice.auth.service` 包下创建 `LoginSessionService` 接口，在 `impl` 包下创建实现类。

**接口方法：**

| 方法 | 功能 | Redis 操作 |
|------|------|-----------|
| `createSession(userId, clientType, sessionData)` | 创建登录态会话 | SET `auth:session:{userId}:{clientType}` (JSON, TTL 7d) |
| `getSession(userId, clientType)` | 获取登录态 | GET `auth:session:{userId}:{clientType}` |
| `removeSession(userId, clientType)` | 删除登录态 | DEL `auth:session:{userId}:{clientType}` |
| `removeAllSessions(userId)` | 删除用户所有端会话 | 扫描 `auth:session:{userId}:*` 并删除 |
| `addToBlacklist(tokenSignature, ttl)` | 加入 Token 黑名单 | SET `auth:token:blacklist:{sig}` (TTL=剩余有效期) |
| `isBlacklisted(tokenSignature)` | 校验是否在黑名单 | EXISTS/GET `auth:token:blacklist:{sig}` |
| `setAccountStatus(userId, status)` | 设置账号状态缓存 | SET `auth:account:status:{userId}` |
| `getAccountStatus(userId)` | 获取账号状态 | GET `auth:account:status:{userId}` |
| `setTenantStatus(tenantId, status)` | 设置租户状态缓存 | SET `auth:tenant:status:{tenantId}` |
| `getTenantStatus(tenantId)` | 获取租户状态 | GET `auth:tenant:status:{tenantId}` |

**注入方式：** 构造器注入 `RedisTemplate<String, Object>`

**核心要求：**
- Redis Key 使用 `RedisKeyConstants` 构建，禁止硬编码
- 所有操作记录适当级别日志
- 会话数据存储为 JSON 字符串（包含 accessToken、refreshToken、loginTime、ip、deviceInfo）
- null/空参数校验

#### 测试验收方法
- 单元测试（Mock Redis）验证各方法行为
- 创建/获取/删除会话流程完整
- 黑名单添加/校验流程完整
- 账号/租户状态缓存设置/获取流程完整
- `removeAllSessions` 使用 scan 模式删除匹配的 Key

---

### 5.3.4 TASK-020：登录日志审计服务（LoginLogService）

**任务ID：** TASK-020
**任务名称：** 登录日志审计服务实现
**任务类型：** backend
**关联UserStory：** US-022
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-016（日志 Mapper）
- 下游任务：TASK-022（登录记录日志）、TASK-024（登出更新日志）

#### 上下文读取
- **PRD US-022 AC3~AC5**：登录成功/失败/登出日志记录要求
- **PRD US-022 边界情况与错误处理**：日志写入失败不影响主流程

#### 详细业务描述
在 `cloudoffice-auth-service` 的 `org.cloudstrolling.cloudoffice.auth.service` 包下创建 `LoginLogService`。

**方法定义：**
1. `void recordLoginSuccess(Long tenantId, Long userId, String loginName, String loginIp, String clientType, String deviceInfo)` — 记录登录成功日志
2. `void recordLoginFailure(String loginName, String loginIp, String clientType, String failReason)` — 记录登录失败日志
3. `void updateLogoutTime(Long userId, String clientType)` — 更新最近登录记录的登出时间

**核心要求：**
- 日志写入使用 `@Async` 或同步写入（本期同步，故障时降级）
- 日志写入失败不应影响主登录流程（try-catch 包裹，记录错误日志）
- `loginIp` 获取不到时记录 `"unknown"`
- 设备信息超长时截断至 VARCHAR(256)

#### 测试验收方法
- 登录成功后正确写入日志
- 登录失败后正确写入失败日志
- 登出后正确更新时间
- 数据库写入失败时主流程不受影响

---

## 5.4 服务层 - 业务逻辑

### 5.4.1 TASK-021：用户注册业务逻辑

**任务ID：** TASK-021
**任务名称：** 用户注册业务逻辑
**任务类型：** backend
**关联UserStory：** US-008
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-015（UserMapper）、TASK-018（JwtUtils）
- 下游任务：TASK-030（AuthController 注册接口）

#### 上下文读取
- **PRD US-008 AC1~AC6**：注册业务完整验收标准
- **PRD US-008 边界情况与错误处理**：7 种边界场景
- **SDS 4.3.2 注册接口**：请求/响应格式、错误场景

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service` 包下创建 `UserService` 接口，在 `impl` 包下创建 `UserServiceImpl` 实现类。

**注册方法：`UserEntity register(RegisterRequest request)`**

**业务流程：**
1. 校验 `tenantCode` → 查询租户，校验租户状态（禁用/过期返回对应错误）
2. 校验 `loginName` 格式（4-64 字符，字母/数字/下划线）
3. 校验 `loginName` 唯一性（同一租户内不可重复）
4. 校验 `password` 规则（8-64 字符，需含字母和数字）
5. 可选字段校验（`phone`、`email` 格式）
6. BCrypt 加密密码（强度系数 ≥ 10）
7. 创建用户记录
8. 分配默认角色（通过配置指定）
9. 返回用户基本信息（不含密码）

**请求 DTO：`RegisterRequest`**
```java
@Data
public class RegisterRequest {
    @NotBlank @Size(min = 4, max = 64) @Pattern(regexp = "^[a-zA-Z0-9_]+$")
    private String loginName;
    @NotBlank @Size(min = 8, max = 64)
    private String password;
    private String realName;
    @Pattern(regexp = "^1[3-9]\\d{9}$")
    private String phone;
    @Email
    private String email;
    @NotBlank
    private String tenantCode;
}
```

#### 测试验收方法
- 注册成功返回用户信息（不含密码）
- 重复 loginName 返回 400 错误
- 密码不符合规则返回 400
- 手机号/邮箱格式错误返回 400
- 租户不存在/禁用/过期返回对应错误
- 注册后用户 BCrypt 密码正确加密
- 注册后自动分配默认角色

---

### 5.4.2 TASK-022：登录认证业务逻辑

**任务ID：** TASK-022
**任务名称：** 登录认证业务逻辑（含多端互斥/双 Token 签发）
**任务类型：** backend
**关联UserStory：** US-014
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-015（UserMapper）、TASK-018（JwtUtils）、TASK-019（LoginSessionService）、TASK-020（LoginLogService）
- 下游任务：TASK-030（AuthController 登录接口）

#### 上下文读取
- **PRD US-014 AC1~AC8**：登录业务完整验收标准
- **PRD US-014 边界情况与错误处理**：6 种边界场景
- **SDS 1.3 登录流程**：完整的 13 步登录流程
- **SDS 4.3.1 登录接口**：请求/响应格式、错误场景对照表

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service` 包下创建 `LoginService` 接口，在 `impl` 包下创建 `LoginServiceImpl` 实现类。

**登录方法：`TokenPairDTO login(LoginRequest request)`**

**业务流程：**
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

**核心要点：**
- 同端互斥逻辑：通过 `ClientTypeEnum.fromCode()` 获取客户端类型，调用 `isSameCategory()` 判断
- Redis 操作失败时记录错误日志但不应泄漏 Redis 连接详情

#### 测试验收方法
- 有效用户登录成功返回双 Token
- 密码错误返回 401 LOGIN_FAILED
- 用户被封禁/禁用返回 403
- 租户禁用/过期返回 403
- 同端互斥：旧会话 Token 加入黑名单
- 多端共存：不同类型端同时登录互不影响
- 登录日志正确记录
- 登录态会话正确写入 Redis

---

### 5.4.3 TASK-023：Token 刷新业务逻辑

**任务ID：** TASK-023
**任务名称：** Token 刷新业务逻辑（含轮换机制）
**任务类型：** backend
**关联UserStory：** US-015
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-018（JwtUtils）、TASK-019（LoginSessionService）
- 下游任务：TASK-030（AuthController 刷新接口）

#### 上下文读取
- **PRD US-015 AC1~AC5**：Token 刷新完整验收标准
- **PRD US-015 边界情况与错误处理**：5 种边界场景
- **SDS 1.4 关键设计原则**：Token 轮换（Rotation）策略
- **SDS 1.3 登录流程**：刷新流程
- **SDS 4.3.3 Token 刷新接口**：请求/响应格式

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.service` 包下创建 `TokenService` 接口，在 `impl` 包下创建 `TokenServiceImpl` 实现类。

**刷新方法：`TokenPairDTO refresh(String refreshToken)`**

**业务流程：**
1. RS256 验签 Refresh Token（`JwtUtils.parseRefreshToken()`）
2. 校验 Refresh Token 是否在黑名单中（`LoginSessionService.isBlacklisted()`）
3. 从 Claims 中提取 userId、tenantId、clientType
4. 查询用户最新状态（禁用/封禁/过期）
5. 查询租户状态（禁用/过期）
6. 查询用户角色和权限列表
7. 生成新的双 Token（`JwtUtils.generateAccessToken()` + `JwtUtils.generateRefreshToken()`）
8. 旧 Refresh Token 加入黑名单（TTL = 旧 Token 剩余有效期）
9. 更新 Redis 登录态会话
10. 返回新的 `TokenPairDTO`

**核心要点：**
- Refresh Token 轮换：每次刷新同时更换 Access Token 和 Refresh Token
- 旧 Refresh Token 加入黑名单防止重放攻击
- 校验账号状态和租户状态（即使在 Token 有效期内封禁，刷新时也应拒绝）

#### 测试验收方法
- 有效 Refresh Token 返回新的双 Token
- 过期 Refresh Token 返回 401 REFRESH_TOKEN_EXPIRED
- 黑名单中的 Refresh Token 返回 401 TOKEN_BLACKLISTED
- 账号被封禁返回 403 ACCOUNT_BANNED
- 租户被禁用返回 403 TENANT_DISABLED

---

### 5.4.4 TASK-024：登出业务逻辑

**任务ID：** TASK-024
**任务名称：** 登出业务逻辑
**任务类型：** backend
**关联UserStory：** US-016
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-019（LoginSessionService）、TASK-020（LoginLogService）
- 下游任务：TASK-030（AuthController 登出接口）

#### 上下文读取
- **PRD US-016 AC1~AC4**：登出业务验收标准
- **PRD US-016 边界情况与错误处理**：3 种边界场景
- **SDS 4.3.4 登出接口**：接口定义

#### 详细业务描述
在 `LoginService` 中新增登出方法。

**登出方法：`void logout(String accessToken, Long userId, String clientType)`**

**业务流程：**
1. 从 Access Token 中获取 Token 签名指纹（`JwtUtils.getTokenSignature()`）
2. 计算 Token 剩余有效期（从当前时间到 exp 声明）
3. 将 Access Token 加入黑名单（`LoginSessionService.addToBlacklist()`）
4. 删除登录态会话（`LoginSessionService.removeSession()`）
5. 更新登录日志的登出时间（`LoginLogService.updateLogoutTime()`）

**核心要点：**
- 幂等处理：已登出的 Token 再次登出返回成功
- 仅清除当前客户端类型的登录会话
- 登出后更新登录日志的 logout_time

#### 测试验收方法
- 有效 Token 登出成功（200）
- 登出后 Token 在黑名单中
- 登出后 Redis 登录态被清除
- 重复登出返回 200（幂等）
- 已过期 Token 登出返回 401

---

### 5.4.5 TASK-025：强制踢人业务逻辑

**任务ID：** TASK-025
**任务名称：** 强制踢人业务逻辑
**任务类型：** backend
**关联UserStory：** US-017
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-019（LoginSessionService）
- 下游任务：TASK-030（AuthController 踢人接口）

#### 上下文读取
- **PRD US-017 AC1~AC5**：踢人业务验收标准
- **PRD US-017 边界情况与错误处理**：4 种边界场景
- **SDS 4.3.5 强制踢人接口**：接口定义

#### 详细业务描述
在 `LoginService` 或独立的 `SessionManageService` 中实现强制踢人方法。

**踢人方法：`void kickout(Long operatorUserId, Long targetUserId, String clientType)`**

**业务流程：**
1. 校验操作者权限（必须是租户管理员或平台管理员）
2. 校验目标用户存在
3. 如果 `clientType` 不为空：
   - 获取该端登录态会话
   - 删除会话（`LoginSessionService.removeSession()`）
   - 将关联 Token 加入黑名单
4. 如果 `clientType` 为空（踢所有端）：
   - 删除该用户所有端会话（`LoginSessionService.removeAllSessions()`）
   - 扫描所有关联 Token 加入黑名单
5. 记录审计日志

**核心要点：**
- 租户管理员只能踢本租户用户
- 平台管理员可踢所有租户用户
- 目标用户不存在返回 404 USER_NOT_FOUND
- `clientType` 不合法返回 400 CLIENT_TYPE_INVALID
- 目标用户指定端不在线时幂等处理

#### 测试验收方法
- 管理员踢人成功
- 被踢用户的 Token 在网关请求时返回 401 SESSION_KICKED_OUT
- 非管理员调用返回 403 PERMISSION_DENIED
- 指定 clientType 踢单端
- 空 clientType 踢所有端

---

### 5.4.6 TASK-026：账号封禁/解封业务逻辑

**任务ID：** TASK-026
**任务名称：** 账号封禁/解封业务逻辑
**任务类型：** backend
**关联UserStory：** US-018
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-015（UserMapper）、TASK-019（LoginSessionService）
- 下游任务：TASK-027（用户管理 API）

#### 上下文读取
- **PRD US-018 AC1~AC5**：封禁/解封验收标准
- **PRD US-018 边界情况与错误处理**：4 种边界场景

#### 详细业务描述
在 `UserService` 中实现账号封禁/解封方法。

**状态变更方法：`void changeUserStatus(Long operatorUserId, Long targetUserId, Integer status, String lockReason)`**

**业务流程：**

封禁（status=3）：
1. 校验操作者权限（租户管理员/平台管理员）
2. 校验目标用户存在且属于同一租户
3. 更新数据库用户状态为封禁
4. 更新 Redis 账号状态缓存（`LoginSessionService.setAccountStatus()`）
5. 清除该用户所有端登录态（`LoginSessionService.removeAllSessions()`）
6. 所有关联 Token 加入黑名单

解封（status=0）：
1. 校验操作者权限
2. 校验目标用户存在
3. 更新数据库用户状态为正常
4. 删除 Redis 账号状态缓存（解封后不再缓存，下次登录时重新写入）

**核心要点：**
- 封禁后所有端同时下线，实时生效
- 幂等处理：已封禁再次封禁返回成功
- 解封仅恢复登录能力，已有 Token 仍然在黑名单中，用户需重新登录

#### 测试验收方法
- 封禁后端状态变更为 3
- 封禁后 Redis 缓存状态更新
- 封禁后所有端登录态清除
- 被封禁用户请求网关返回 403 ACCOUNT_BANNED
- 解封后状态恢复为 0
- 非管理员操作返回 403

---

## 5.5 服务层 - 管理 API

### 5.5.1 TASK-027：用户管理 Service + Controller

**任务ID：** TASK-027
**任务名称：** 用户管理 Service + Controller（CRUD/状态变更/角色分配）
**任务类型：** backend
**关联UserStory：** US-013
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-015（UserMapper、UserRoleMapper）、TASK-026（封禁/解封）
- 下游任务：无

#### 上下文读取
- **PRD US-013 AC1~AC6**：用户管理 API 验收标准
- **PRD US-013 边界情况与错误处理**：跨租户查询、资源不存在
- **SDS 4.3.6 用户管理接口**：6 个接口定义

#### 详细业务描述
完善 `UserService` 并在 `UserController` 中实现用户管理 API。

**UserService 方法：**

| 方法 | 功能 |
|------|------|
| `pageQuery(PageParam, Long tenantId)` | 租户内用户分页查询 |
| `getUserById(Long userId)` | 用户详情（含角色和权限列表） |
| `updateUser(Long userId, UpdateUserRequest)` | 修改用户信息 |
| `changeUserStatus(Long userId, Integer status, String reason)` | 变更用户状态（调用 TASK-026 逻辑） |
| `assignRoles(Long userId, List<Long> roleIds)` | 全量更新用户角色分配 |
| `deleteUser(Long userId)` | 逻辑删除用户 |

**UserController API：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/auth/users?page=1&size=20` | 用户分页查询 |
| GET | `/api/v1/auth/users/{userId}` | 用户详情 |
| PUT | `/api/v1/auth/users/{userId}` | 修改用户信息 |
| PUT | `/api/v1/auth/users/{userId}/status` | 变更用户状态 |
| PUT | `/api/v1/auth/users/{userId}/roles` | 分配角色 |
| DELETE | `/api/v1/auth/users/{userId}` | 删除用户 |

**核心要点：**
- 所有查询自动按当前租户 ID 过滤（从 Token Claims 中提取 tenantId）
- 返回统一格式 `ApiResult` 和 `PageResult`
- 用户详情包含角色编码列表和权限标识列表

#### 测试验收方法
- 分页查询返回正确结果
- 用户详情包含角色和权限信息
- 状态变更（封禁/解封）实时生效
- 角色分配全量更新
- 逻辑删除后用户不可查询
- 跨租户查询不可见

---

### 5.5.2 TASK-028：角色管理 Service + Controller

**任务ID：** TASK-028
**任务名称：** 角色管理 Service + Controller（CRUD/权限分配）
**任务类型：** backend
**关联UserStory：** US-013
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-015（RoleMapper、RolePermissionMapper）
- 下游任务：无

#### 上下文读取
- **PRD US-013 AC7~AC9**：角色管理 API 验收标准
- **PRD US-013 边界情况与错误处理**：角色被引用时阻止删除
- **SDS 4.3.7 角色管理接口**：5 个接口定义

#### 详细业务描述
创建 `RoleService` 和 `RoleController`。

**RoleService 方法：**

| 方法 | 功能 |
|------|------|
| `listRoles(Long tenantId)` | 租户内角色列表 |
| `createRole(CreateRoleRequest)` | 创建角色 |
| `updateRole(Long roleId, UpdateRoleRequest)` | 修改角色 |
| `assignPermissions(Long roleId, List<Long> permissionIds)` | 全量更新角色权限 |
| `deleteRole(Long roleId)` | 逻辑删除角色（检查引用） |

**RoleController API：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/auth/roles` | 角色列表 |
| POST | `/api/v1/auth/roles` | 创建角色 |
| PUT | `/api/v1/auth/roles/{roleId}` | 修改角色 |
| PUT | `/api/v1/auth/roles/{roleId}/permissions` | 分配权限 |
| DELETE | `/api/v1/auth/roles/{roleId}` | 删除角色 |

**核心要点：**
- 角色编码在租户内唯一
- 删除角色时检查是否被用户引用，已引用则阻止删除并提示
- 权限分配使用全量更新方式

#### 测试验收方法
- 角色 CRUD 正常
- 角色编码唯一性校验
- 角色已被分配时阻止删除
- 权限分配全量更新
- 跨租户角色不可见

---

### 5.5.3 TASK-029：权限管理 Service + Controller

**任务ID：** TASK-029
**任务名称：** 权限管理 Service + Controller（CRUD/树形查询）
**任务类型：** backend
**关联UserStory：** US-013
**优先级：** P1
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-015（PermissionMapper）
- 下游任务：无

#### 上下文读取
- **PRD US-013 AC10/AC11**：权限管理 API 验收标准
- **PRD US-013 边界情况与错误处理**：权限被引用时阻止删除
- **SDS 4.3.8 权限管理接口**：4 个接口定义

#### 详细业务描述
创建 `PermissionService` 和 `PermissionController`。

**PermissionService 方法：**

| 方法 | 功能 |
|------|------|
| `getTree()` | 树形权限列表（按 parent_id 组织） |
| `createPermission(CreatePermissionRequest)` | 创建权限点 |
| `updatePermission(Long permId, UpdatePermissionRequest)` | 修改权限 |
| `deletePermission(Long permId)` | 逻辑删除权限（检查引用） |

**PermissionController API：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/auth/permissions` | 树形权限列表 |
| POST | `/api/v1/auth/permissions` | 创建权限 |
| PUT | `/api/v1/auth/permissions/{permId}` | 修改权限 |
| DELETE | `/api/v1/auth/permissions/{permId}` | 删除权限 |

**核心要点：**
- 树形结构通过 `parent_id` 自关联实现
- 权限标识 `perm_code` 全局唯一
- 删除权限时检查是否被角色引用，已引用则阻止删除
- 权限数据是全局性的（不按租户隔离，但可以按需分配）

#### 测试验收方法
- 权限 CRUD 正常
- 树形结构正确（父级包含子级列表）
- 权限标识唯一性校验
- 权限已被关联时阻止删除

---

## 5.6 控制器层

### 5.6.1 TASK-030：AuthController 认证控制器实现

**任务ID：** TASK-030
**任务名称：** AuthController 认证控制器实现（登录/注册/刷新/登出/踢人）
**任务类型：** backend
**关联UserStory：** US-008, US-014, US-015, US-016, US-017
**优先级：** P0
**当前状态：** pending

#### 上下游任务
- 上游任务：TASK-021（注册业务）、TASK-022（登录业务）、TASK-023（刷新业务）、TASK-024（登出业务）、TASK-025（踢人业务）
- 下游任务：无

#### 上下文读取
- **PRD US-008**：注册接口规范
- **PRD US-014**：登录接口规范
- **PRD US-015**：刷新接口规范
- **PRD US-016**：登出接口规范
- **PRD US-017**：踢人接口规范
- **SDS 4.3 API 接口定义**：5 个接口的完整请求/响应格式
- **project.md 编码规范**：SpringDoc 注解、构造器注入

#### 详细业务描述
在 `org.cloudstrolling.cloudoffice.auth.controller` 包下创建 `AuthController`，实现认证相关 5 个端点。

**控制器 API：**

| 方法 | 路径 | 白名单 | 说明 |
|------|------|--------|------|
| POST | `/api/v1/auth/login` | 是 | 用户名密码登录 |
| POST | `/api/v1/auth/register` | 是 | 用户注册 |
| POST | `/api/v1/auth/refresh` | 是 | Token 刷新 |
| POST | `/api/v1/auth/logout` | 否 | 用户登出 |
| POST | `/api/v1/auth/kickout` | 否 | 强制踢人 |

**每个接口的校验逻辑：**

1. **登录接口（login）：**
   - `@RequestBody @Valid LoginRequest`
   - 调用 `LoginService.login()` → 返回 `TokenPairDTO`

2. **注册接口（register）：**
   - `@RequestBody @Valid RegisterRequest`
   - 调用 `UserService.register()` → 返回用户基本信息
   - HTTP 状态码 201

3. **刷新接口（refresh）：**
   - `@RequestBody RefreshTokenRequest(refreshToken)`
   - 调用 `TokenService.refresh()` → 返回新 `TokenPairDTO`

4. **登出接口（logout）：**
   - 从请求头提取 `Authorization: Bearer <token>`
   - 解析 Token 获取 userId 和 clientType
   - 调用 `LoginService.logout()`
   - 返回 200

5. **踢人接口（kickout）：**
   - `@RequestBody KickoutRequest(userId, clientType)`
   - 从 Token 获取操作者身份
   - 调用踢人业务逻辑
   - 返回 200

**核心要点：**
- 所有接口使用 `@Tag`、`@Operation` SpringDoc 注解生成 API 文档
- 参数校验使用 `@Valid` 注解
- 统一返回 `ApiResult` 响应体
- 使用构造器注入所有 Service

#### 测试验收方法
- 每个接口 MockMvc 单元测试：
  - 登录成功返回 TokenPairDTO
  - 登录失败返回对应错误码
  - 注册成功返回用户信息含 userId
  - 刷新成功返回新 TokenPairDTO
  - 登出成功返回 200
  - 踢人成功返回 200
- `mvn test -pl cloudoffice-auth-service` 全部通过

---

# 6. 任务依赖关系总图

```
TASK-001 (ErrorCode) ──────────────────────────────────────────┐
TASK-002 (ClientTypeEnum) ─────────────────────────────────┐   │
TASK-003 (DTO) ───────────────────────────────────────────┐│   │
TASK-004 (RedisKeyConstants) ──────────────────────────┐  ││   │
TASK-005 (父POM确认) ──────────────────────────────┐    │  ││   │
                                                   │    │  ││   │
          ┌────────────────────────────────────────┘    │  ││   │
          ▼                                             │  ││   │
    TASK-006 (网关Redis) ←──────────────────────────────┘  ││   │
    TASK-007 (网关RSA) ←───────────────────────────────────┘│   │
    TASK-008 (网关白名单) ←─────────────────────────────────┘   │
          │                                                     │
          ▼                                                     │
    TASK-009 (AuthFilter) ←── TASK-006 ~ TASK-008 ──────────────┘
          │
          ▼  (AuthFilter 拦截所有请求，但不受 auth-service 影响)
          │
    TASK-010 (auth-service pom) ─── TASK-005
          │
          ▼
    TASK-011 (auth-service yml) ─── TASK-010
    TASK-012 (auth-service MPConfig) ─── TASK-010
          │
          ├── TASK-013 (SQL DDL)
          │       │
          │       ▼
          │   TASK-014 (Entity) ──── TASK-010
          │       │
          │       ├── TASK-015 (RBAC Mapper+XML)
          │       │       │
          │       │       ├── TASK-021 (注册) ← TASK-018
          │       │       ├── TASK-022 (登录) ← TASK-018,019,020
          │       │       ├── TASK-027 (用户管理API)
          │       │       ├── TASK-028 (角色管理API)
          │       │       └── TASK-029 (权限管理API)
          │       │
          │       └── TASK-016 (日志Mapper)
          │               │
          │               ▼
          │           TASK-020 (LoginLogService)
          │
          ├── TASK-017 (RsaKeyConfig)
          │       │
          │       ▼
          │   TASK-018 (JwtUtils) ←── TASK-003(LoginUserDTO)
          │       │
          │       ├── TASK-022 (登录)
          │       └── TASK-023 (Token刷新)
          │
          ├── TASK-019 (LoginSessionService) ← TASK-004,011
          │       │
          │       ├── TASK-022 (登录)
          │       ├── TASK-023 (刷新)
          │       ├── TASK-024 (登出)
          │       ├── TASK-025 (踢人)
          │       └── TASK-026 (封禁)
          │
          └───────────────────────────────────────────┐
                                                      │
    TASK-021 ~ TASK-026 (业务逻辑) ←── 上游依赖     │
          │                                           │
          └───────────────────────┬───────────────────┘
                                  │
    TASK-027 (用户管理 Controller) ← TASK-015
    TASK-028 (角色管理 Controller) ← TASK-015
    TASK-029 (权限管理 Controller) ← TASK-015
    TASK-030 (AuthController) ← TASK-021~025
```

---

# 7. 任务优先级建议执行顺序

| 阶段 | 任务 | 说明 |
|------|------|------|
| 第一阶段（公共模块 + 父POM） | TASK-001 ~ TASK-005 | 基础组件，无外部依赖 |
| 第二阶段（网关基础设施） | TASK-006 ~ TASK-008 | 网关 Redis/RSA/白名单 |
| 第三阶段（认证服务基础设施） | TASK-010 ~ TASK-012, TASK-017 | 认证服务 pom/配置/RSA |
| 第四阶段（数据层） | TASK-013 ~ TASK-016 | DDL + Entity + Mapper |
| 第五阶段（核心服务层） | TASK-018 ~ TASK-020 | JwtUtils + LoginSession + LoginLog |
| 第六阶段（业务逻辑层） | TASK-021 ~ TASK-026 | 注册/登录/刷新/登出/踢人/封禁 |
| 第七阶段（控制器 + 网关过滤器） | TASK-009, TASK-027 ~ TASK-030 | API 暴露与全局拦截 |
