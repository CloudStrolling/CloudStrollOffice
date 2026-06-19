# 服务模块单元测试用例文档 v0.1.0

> 文档版本：v0.1.0
> 对应版本：CloudStrollOffice v0.1.0
> 创建日期：2026-06-18

## 目录

1. [测试范围](#1-测试范围)
2. [Gateway 模块测试](#2-gateway-模块测试)
3. [Auth Service 模块测试](#3-auth-service-模块测试)
4. [Biz Service 模块测试](#4-biz-service-模块测试)
5. [Cloud Service 模块测试](#5-cloud-service-模块测试)
6. [System Service 模块测试](#6-system-service-模块测试)

---

## 1. 测试范围

### 1.1 测试目标

对 Gateway、Auth Service、Biz Service、Cloud Service、System Service 五个微服务模块进行单元测试，覆盖：

- 应用启动类上下文加载验证
- 注解正确性验证
- 核心工具类方法验证
- REST 控制器端点验证
- 安全配置验证

### 1.2 测试策略

| 测试类型 | 说明 |
|---------|------|
| `@SpringBootTest` | 验证 Spring 上下文加载，禁用 Nacos 和外部依赖 |
| `@WebMvcTest` | 验证 REST 控制器，Mock 下层依赖 |
| 纯单元测试 | 无需 Spring 上下文，直接构造实例测试 |

### 1.3 环境配置

- **构建工具**：Maven
- **测试框架**：JUnit 5 + Mockito
- **Spring Boot**：3.2.5
- **Java**：21

---

## 2. Gateway 模块测试

### 2.1 GatewayApplicationTest

**文件**：`cloudoffice-gateway/src/test/java/org/cloudstrolling/cloudoffice/gateway/GatewayApplicationTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-GW-001 | `contextLoads_shouldLoadSuccessfully_whenApplicationStarts` | 启动 Spring 上下文 | 上下文加载成功，无异常 |
| TC-GW-002 | `enableDiscoveryClient_shouldBePresent_whenAnnotationCheck` | 检查 `@EnableDiscoveryClient` 注解 | 注解存在 |
| TC-GW-003 | `springBootApplication_shouldBePresent_whenAnnotationCheck` | 检查 `@SpringBootApplication` 注解 | 注解存在 |

---

## 3. Auth Service 模块测试

### 3.1 JwtUtilsTest

**文件**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/util/JwtUtilsTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-AUTH-001 | `generateToken_shouldReturnThreePartToken_whenCalledWithValidParams` | 生成合法 JWT | 三段式字符串（header.payload.signature） |
| TC-AUTH-002 | `generateToken_shouldReturnDifferentTokens_whenCalledWithDifferentUsers` | 不同用户生成令牌 | 令牌不同 |
| TC-AUTH-003 | `parseToken_shouldReturnCorrectClaims_whenTokenIsValid` | 解析有效令牌 | 正确解析 subject 和 userName |
| TC-AUTH-004 | `validateToken_shouldReturnTrue_whenTokenIsValid` | 验证有效令牌 | 返回 true |
| TC-AUTH-005 | `validateToken_shouldReturnFalse_whenTokenHasInvalidSignature` | 验证签名篡改令牌 | 返回 false |
| TC-AUTH-006 | `validateToken_shouldReturnFalse_whenTokenIsNull` | 验证 null 令牌 | 返回 false |
| TC-AUTH-007 | `validateToken_shouldReturnFalse_whenTokenIsMalformed` | 验证格式错误的令牌 | 返回 false |
| TC-AUTH-008 | `getUserIdFromToken_shouldReturnCorrectUserId_whenTokenIsValid` | 从令牌提取 userId | 返回正确 userId |
| TC-AUTH-009 | `getUserNameFromToken_shouldReturnCorrectUserName_whenTokenIsValid` | 从令牌提取 userName | 返回正确 userName |
| TC-AUTH-010 | `init_shouldThrowException_whenSecretIsTooShort` | 密钥长度不足 32 字符 | 抛出 IllegalArgumentException |
| TC-AUTH-011 | `init_shouldThrowException_whenSecretIsNull` | 密钥为 null | 抛出 IllegalArgumentException |
| TC-AUTH-012 | `generateToken_shouldIncludeIssuedAtAndExpiration_whenTokenGenerated` | 生成含 iat/exp 声明的令牌 | 过期令牌抛出 ExpiredJwtException |

### 3.2 AuthApplicationTest

**文件**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/AuthApplicationTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-AUTH-013 | `contextLoads_shouldLoadSuccessfully_whenApplicationStarts` | 启动 Spring 上下文 | 上下文加载成功 |
| TC-AUTH-014 | `jwtUtils_shouldBeLoaded_whenContextIsReady` | 注入 JwtUtils Bean | Bean 非空 |
| TC-AUTH-015 | `enableDiscoveryClient_shouldBePresent_whenAnnotationCheck` | 检查 `@EnableDiscoveryClient` 注解 | 注解存在 |

### 3.3 HealthControllerTest（Auth）

**文件**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/controller/HealthControllerTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-AUTH-016 | `health_shouldReturn200AndApiResult_whenCalled` | GET /api/v1/auth/health | 200 + ApiResult，data 含 service/status/version/timestamp |

### 3.4 SecurityConfigTest

**文件**：`cloudoffice-auth-service/src/test/java/org/cloudstrolling/cloudoffice/auth/config/SecurityConfigTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-AUTH-017 | `passwordEncoder_shouldReturnBCryptPasswordEncoderInstance_whenCalled` | 调用 passwordEncoder() | 返回 BCryptPasswordEncoder 实例 |
| TC-AUTH-018 | `bcryptEncoder_shouldMatchEncodedPassword_whenPasswordIsCorrect` | 正确密码匹配 | matches 返回 true |
| TC-AUTH-019 | `bcryptEncoder_shouldNotMatch_whenPasswordIsWrong` | 错误密码匹配 | matches 返回 false |
| TC-AUTH-020 | `bcryptEncoder_shouldProduceDifferentEncodings_whenCalledMultipleTimes` | 多次编码同一密码 | 结果不同（随机盐值） |

---

## 4. Biz Service 模块测试

### 4.1 BizApplicationTest

**文件**：`cloudoffice-biz-service/src/test/java/org/cloudstrolling/cloudoffice/biz/BizApplicationTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-BIZ-001 | `contextLoads_shouldLoadSuccessfully_whenApplicationStarts` | 启动 Spring 上下文 | 上下文加载成功 |
| TC-BIZ-002 | `enableDiscoveryClient_shouldBePresent_whenAnnotationCheck` | 检查 `@EnableDiscoveryClient` 注解 | 注解存在 |

### 4.2 HealthControllerTest（Biz）

**文件**：`cloudoffice-biz-service/src/test/java/org/cloudstrolling/cloudoffice/biz/controller/HealthControllerTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-BIZ-003 | `health_shouldReturn200AndApiResult_whenCalled` | GET /api/v1/biz/health | 200 + ApiResult，data 含 service/status/version/timestamp |

---

---

> **注意：** Cloud Service（cloudoffice-cloud-service）已于 v0.1.0 版本中移除，相关测试用例（TC-CLOUD-001 ~ TC-CLOUD-003）不再适用。

## 6. System Service 模块测试

### 6.1 SystemApplicationTest

**文件**：`cloudoffice-system-service/src/test/java/org/cloudstrolling/cloudoffice/system/SystemApplicationTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-SYS-001 | `contextLoads_shouldLoadSuccessfully_whenApplicationStarts` | 启动 Spring 上下文 | 上下文加载成功 |
| TC-SYS-002 | `enableDiscoveryClient_shouldBePresent_whenAnnotationCheck` | 检查 `@EnableDiscoveryClient` 注解 | 注解存在 |

### 6.2 HealthControllerTest（System）

**文件**：`cloudoffice-system-service/src/test/java/org/cloudstrolling/cloudoffice/system/controller/HealthControllerTest.java`

| 编号 | 测试方法 | 场景 | 预期结果 |
|------|---------|------|---------|
| TC-SYS-003 | `health_shouldReturn200AndApiResult_whenCalled` | GET /api/v1/system/health | 200 + ApiResult，data 含 service/status/version/timestamp |

---

## 附录

### A. 测试统计

| 模块 | 测试类数 | 测试方法数 |
|------|---------|-----------|
| Gateway | 1 | 3 |
| Auth Service | 4 | 20 |
| Biz Service | 2 | 3 |
| Cloud Service | 2 | 3 |
| System Service | 2 | 3 |
| **总计** | **11** | **32** |

### B. 测试依赖

- `spring-boot-starter-test`（Spring Boot 自动引入）
- `spring-boot-starter-web`（用于 @WebMvcTest）
- `jakarta.annotation`（用于 @PostConstruct 测试）
- `io.jsonwebtoken:jjwt-api`（JWT 解析测试）
