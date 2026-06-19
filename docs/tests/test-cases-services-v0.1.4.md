# 服务模块单元测试用例文档 v0.1.4

> 文档版本：v0.1.4
> 对应版本：CloudStrollOffice v0.1.4（系统服务搭建）
> 创建日期：2026-06-19
> 基于 v0.1.0 测试用例文档扩展

## 目录

1. [测试范围](#1-测试范围)
2. [System Service 模块测试（新增/更新）](#2-system-service-模块测试新增更新)
3. [全量回归测试清单](#3-全量回归测试清单)
4. [测试执行结果](#4-测试执行结果)

---

## 1. 测试范围

### 1.1 v0.1.4 变更范围

| 模块 | 变更类型 | 变更说明 |
|------|---------|---------|
| `cloudoffice-system-service` | 新增（完整实现） | 系统服务完整搭建：启动入口、健康检查、应用配置、骨架目录、单元测试 |
| `cloudoffice-common` | 回归（无变更） | 公共模块，v0.1.0 已完成，本次回归验证未受系统服务影响 |
| `cloudoffice-gateway` | 回归（无变更） | API 网关，验证未受新模块影响 |
| `cloudoffice-auth-service` | 回归（无变更） | 认证服务，验证未受新模块影响 |
| `cloudoffice-biz-service` | 回归（无变更） | 企业服务，验证未受新模块影响 |

### 1.2 测试策略

| 测试类型 | 说明 |
|---------|------|
| `@SpringBootTest` | 验证 Spring 上下文加载，禁用 Nacos 和外部依赖 |
| 纯单元测试（Mockito） | 无需 Spring 上下文，直接构造实例测试 |

### 1.3 环境配置

- **构建工具**：Maven
- **测试框架**：JUnit 5 + Mockito
- **Spring Boot**：3.2.5
- **Java**：21

---

## 2. System Service 模块测试（新增/更新）

> 对应 PRD：US-005（系统服务单元测试）
> 对应 TASK：TASK-007（编写系统服务单元测试）

### 2.1 SystemApplicationTest

**文件**：`cloudoffice-system-service/src/test/java/org/cloudstrolling/cloudoffice/system/SystemApplicationTest.java`

**测试类注解**：
```java
@SpringBootTest(classes = SystemApplication.class, properties = {
    "spring.cloud.nacos.discovery.enabled=false",
    "spring.cloud.nacos.config.enabled=false",
    "spring.cloud.nacos.config.import-check.enabled=false",
    "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration"
})
```

| 编号 | 优先级 | 测试方法 | 场景 | 前置条件 | 测试步骤 | 输入数据 | 预期结果 | 关联 AC | 测试结论 |
|------|--------|---------|------|---------|---------|---------|---------|---------|---------|
| TC-SYS-001 | P0 | `contextLoads_shouldLoadSuccessfully_whenApplicationStarts` | 验证 Spring 上下文正常加载 | 测试环境无 Nacos、无 MariaDB | 1. 自动加载 @SpringBootTest 上下文<br>2. 断言运行成功 | 无 | Spring 应用上下文加载成功，`assertNotNull(SystemApplication.class)` 通过 | US-005 AC1 | ✅ 通过 |
| TC-SYS-002 | P0 | `enableDiscoveryClient_shouldBePresent_whenAnnotationCheck` | 验证启动类标注 `@EnableDiscoveryClient` 注解 | SystemApplication 类已定义 | 1. 反射获取注解<br>2. 断言非空 | 无 | 注解存在，`assertNotNull(annotation)` 通过 | US-005 AC2 | ✅ 通过 |

### 2.2 HealthControllerTest（System）

**文件**：`cloudoffice-system-service/src/test/java/org/cloudstrolling/cloudoffice/system/controller/HealthControllerTest.java`

**测试方式**：纯单元测试（Mockito 模拟 Environment，不启动 Spring 上下文）

| 编号 | 优先级 | 测试方法 | 场景 | 前置条件 | 测试步骤 | 输入数据 | 预期结果 | 关联 AC | 测试结论 |
|------|--------|---------|------|---------|---------|---------|---------|---------|---------|
| TC-SYS-003 | P0 | `health_shouldReturn200AndApiResult_whenCalled` | GET /api/v1/system/health 返回完整健康信息 | Mock Environment 返回 service 名称为 `cloudoffice-system-service` | 1. 构造 Mock Environment<br>2. 构造 HealthController<br>3. 调用 health()<br>4. 断言所有响应字段 | `spring.application.name` = `cloudoffice-system-service` | 1. `result` 不为 null<br>2. `result.code` = 200<br>3. `result.message` = "操作成功"<br>4. `data.service` = "cloudoffice-system-service"<br>5. `data.status` = "UP"<br>6. `data.version` = "0.0.1-SNAPSHOT"<br>7. `data.timestamp` 非 null 且为 Long 类型<br>8. 顶层 `result.timestamp` > 0 | US-005 AC3, AC4 | ✅ 通过 |

### 2.3 测试依赖隔离验证

| 编号 | 优先级 | 验证项 | 预期的隔离行为 | 关联 AC | 测试结论 |
|------|--------|-------|---------------|---------|---------|
| TC-SYS-004 | P1 | 无 Nacos 环境可独立运行 | 测试通过（bootstrap.yml 已禁用 Nacos 发现和配置中心） | US-005 AC5 | ✅ 通过 |
| TC-SYS-005 | P1 | 无 MariaDB 环境可独立运行 | 测试通过（排除 DataSourceAutoConfiguration） | US-005 AC5 | ✅ 通过 |
| TC-SYS-006 | P1 | 全部测试通过 | 运行 `mvn test -pl cloudoffice-system-service` 无失败 | US-005 AC6 | ✅ 通过 |

---

## 3. 全量回归测试清单

> 以下为从 v0.1.0 继承的回归测试用例，验证本次变更未引入回归缺陷。
> 完整用例详情请参考 `docs/tests/test-cases-common-v0.1.0.md` 和 `docs/tests/test-cases-services-v0.1.0.md`。

### 3.1 Common 模块回归（cloudoffice-common）

**测试文件**：共 9 个测试类，56 个测试方法

| 编号 | 测试文件 | 方法数 | 说明 | 测试结论 |
|------|---------|-------|------|---------|
| TC-COMMON-001~007 | ApiResultTest | 7 | 统一响应体：success/error/链式调用/构造器 | ✅ 通过 |
| TC-COMMON-008~009 | PageResultTest | 2 | 分页结果：empty/of 静态工厂 | ✅ 通过 |
| TC-COMMON-010~020 | ErrorCodeTest | 11 | 错误码枚举：全部 11 个常量 | ✅ 通过 |
| TC-COMMON-021~024 | BaseExceptionTest | 4 | 异常基类：构造/继承链/消息传递 | ✅ 通过 |
| TC-COMMON-025~030 | BusinessExceptionTest | 6 | 业务异常：各种构造方式/继承链/getter | ✅ 通过 |
| TC-COMMON-031~038 | GlobalExceptionHandlerTest | 8 | 全局异常处理：参数校验/业务异常/认证异常/方法不支持/兜底 500 | ✅ 通过 |
| TC-COMMON-039~043 | BaseEntityTest | 5 | 基础实体：字段读写/主键/自动填充/逻辑删除注解 | ✅ 通过 |
| TC-COMMON-044~050 | JsonUtilsTest | 7 | JSON 工具：Map/null/String/数字/布尔/List/空字符串 | ✅ 通过 |
| TC-COMMON-051~056 | MyBatisPlusConfigTest | 6 | MyBatis-Plus 配置：插入/更新填充策略 | ✅ 通过 |

### 3.2 Gateway 模块回归（cloudoffice-gateway）

| 编号 | 测试文件 | 方法数 | 测试方法 | 测试结论 |
|------|---------|-------|---------|---------|
| TC-GW-001~003 | GatewayApplicationTest | 3 | `contextLoads_shouldLoadSuccessfully_whenApplicationStarts`<br>`enableDiscoveryClient_shouldBePresent_whenAnnotationCheck`<br>`springBootApplication_shouldBePresent_whenAnnotationCheck` | ✅ 通过 |

### 3.3 Auth Service 模块回归（cloudoffice-auth-service）

| 编号 | 测试文件 | 方法数 | 说明 | 测试结论 |
|------|---------|-------|------|---------|
| TC-AUTH-001~012 | JwtUtilsTest | 12 | JWT 令牌：生成/解析/验证/提取/异常场景 | ✅ 通过 |
| TC-AUTH-013~015 | AuthApplicationTest | 3 | 应用启动：上下文加载/JwtUtils Bean/注解 | ✅ 通过 |
| TC-AUTH-016 | HealthControllerTest（Auth） | 1 | 健康检查：GET /api/v1/auth/health | ✅ 通过 |
| TC-AUTH-017~020 | SecurityConfigTest | 4 | 安全配置：BCrypt 编码器/密码匹配/随机盐值 | ✅ 通过 |

### 3.4 Biz Service 模块回归（cloudoffice-biz-service）

| 编号 | 测试文件 | 方法数 | 说明 | 测试结论 |
|------|---------|-------|------|---------|
| TC-BIZ-001~002 | BizApplicationTest | 2 | 应用启动：上下文加载/注解 | ✅ 通过 |
| TC-BIZ-003 | HealthControllerTest（Biz） | 1 | 健康检查：GET /api/v1/biz/health | ✅ 通过 |

### 3.5 System Service 模块回归（cloudoffice-system-service）

| 编号 | 测试文件 | 方法数 | 说明 | 测试结论 |
|------|---------|-------|------|---------|
| TC-SYS-001~002 | SystemApplicationTest | 2 | 应用启动：上下文加载/注解 | ✅ 通过 |
| TC-SYS-003 | HealthControllerTest（System） | 1 | 健康检查：GET /api/v1/system/health | ✅ 通过 |

---

## 4. 测试执行结果

### 4.1 执行概要

| 项目 | 内容 |
|------|------|
| 执行日期 | 2026-06-19 |
| 执行环境 | Windows 11, JDK 21.0.9, Maven 3.9.x |
| 执行方式 | `mvn clean test`（全量回归） |
| 分支 | `cso-v0.1.4` |
| 执行人 | TE（测试工程师） |
| 总耗时 | 2 分 22 秒 |

### 4.2 各模块测试结果统计

| 模块 | 测试类数 | 测试方法数 | 通过 | 失败 | 跳过 | 通过率 |
|------|---------|-----------|------|------|------|--------|
| cloudoffice-common | 9 | 56 | 56 | 0 | 0 | **100%** |
| cloudoffice-gateway | 1 | 3 | 3 | 0 | 0 | **100%** |
| cloudoffice-auth-service | 4 | 20 | 20 | 0 | 0 | **100%** |
| cloudoffice-biz-service | 2 | 3 | 3 | 0 | 0 | **100%** |
| cloudoffice-system-service | 2 | 3 | 3 | 0 | 0 | **100%** |
| **总计** | **18** | **85** | **85** | **0** | **0** | **100%** |

### 4.3 失败用例清单

> 无失败用例。

| 编号 | 测试方法 | 失败原因 | 实际结果 | 预期结果 |
|------|---------|---------|---------|---------|
| - | - | - | - | - |

### 4.4 测试结论

- [x] **全部通过** ✅ — 无回归缺陷，系统服务搭建 v0.1.4 验证通过
- [ ] 存在失败 — 需修复后重新回归

**回归测试结论：`BUILD SUCCESS`，85 个测试全部通过，0 失败，0 跳过。**
