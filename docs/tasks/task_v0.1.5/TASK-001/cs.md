# TASK-001 现有代码查询结果

> 生成时间：2026-06-22
> 任务：新增认证错误码枚举常量（19 个 AUTH 模块枚举）

---

## 1. ErrorCode 枚举定义

**文件路径：** `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java`（共 40 行）

### 1.1 包名与依赖

```java
package org.cloudstrolling.cloudoffice.common.exception;

import lombok.Getter;
```

### 1.2 类结构

```java
/**
 * 通用错误码枚举
 *
 * <p>定义系统中使用的标准错误码，包含 HTTP 状态码和对应的中文描述。</p>
 *
 * @author CloudStroll Office
 */
@Getter
public enum ErrorCode implements org.cloudstrolling.cloudoffice.common.model.ErrorCode {
```

- 使用 `@Getter`（lombok）自动生成 getter
- 实现 `org.cloudstrolling.cloudoffice.common.model.ErrorCode` 接口

### 1.3 现有 10 个枚举常量（第 15~24 行）

```java
    SUCCESS(200, "操作成功"),
    BAD_REQUEST(400, "请求参数错误"),
    UNAUTHORIZED(401, "未授权，请先登录"),
    FORBIDDEN(403, "权限不足"),
    NOT_FOUND(404, "资源不存在"),
    METHOD_NOT_ALLOWED(405, "请求方法不支持"),
    CONFLICT(409, "资源冲突"),
    TOO_MANY_REQUESTS(429, "请求频率过高"),
    INTERNAL_ERROR(500, "系统繁忙，请稍后重试"),
    SERVICE_UNAVAILABLE(503, "服务暂不可用");
```

**格式要点：**
- 每个枚举常量占 **一行**
- 末尾使用 `,` 分隔（最后一个使用 `;`）
- 构造函数参数：`(Integer code, String message)`
- 当前 **无行内注释**

### 1.4 构造方法与字段（第 26~39 行）

```java
    /**
     * 错误码（通常对应 HTTP 状态码）
     */
    private final Integer code;

    /**
     * 错误描述
     */
    private final String message;

    ErrorCode(Integer code, String message) {
        this.code = code;
        this.message = message;
    }
```

- 两个字段：`Integer code` 和 `String message`，均为 `private final`
- 构造函数为 `package-private`（默认），无访问修饰符
- 字段有 Javadoc 注释

---

## 2. ErrorCode 接口定义

**文件路径：** `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/model/ErrorCode.java`（共 32 行）

```java
/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.model;

/**
 * 错误码接口。
 * <p>
 * 各业务模块的错误码枚举实现此接口，统一错误码规范。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface ErrorCode {

    /**
     * 获取错误码。
     *
     * @return 错误码编号
     */
    Integer getCode();

    /**
     * 获取错误信息。
     *
     * @return 错误描述
     */
    String getMessage();
}
```

**要点：**
- 位于 `org.cloudstrolling.cloudoffice.common.model` 包
- 定义两个契约方法：`getCode()` → `Integer`，`getMessage()` → `String`
- 枚举中引入 `@Getter` 后自动实现这两个方法
- 文件头部带 Apache-2.0 许可证头

---

## 3. 现有 ErrorCodeTest 测试

**文件路径：** `cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCodeTest.java`（共 103 行）

### 3.1 测试结构

```java
/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.exception;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ErrorCode 通用错误码枚举测试。
 * ...
 */
@DisplayName("ErrorCode 枚举测试")
class ErrorCodeTest {
```

**框架：** JUnit 5（Jupiter）
**包可见性：** 测试类和测试方法均为 `package-private`（无 `public`）
**断言：** 使用 `static import` 的 `assertEquals`、`assertNotNull`

### 3.2 测试方法清单

| 方法名 | 测试内容 | 行号 |
|--------|---------|------|
| `allEnumConstants_shouldHaveNonNullCodeAndMessage()` | 遍历所有枚举，校验 code 和 message 非 null | 25~32 |
| `success_shouldHaveCode200()` | `SUCCESS` → 200, "操作成功" | 34~39 |
| `badRequest_shouldHaveCode400()` | `BAD_REQUEST` → 400, "请求参数错误" | 41~46 |
| `unauthorized_shouldHaveCode401()` | `UNAUTHORIZED` → 401, "未授权，请先登录" | 48~53 |
| `forbidden_shouldHaveCode403()` | `FORBIDDEN` → 403, "权限不足" | 55~60 |
| `notFound_shouldHaveCode404()` | `NOT_FOUND` → 404, "资源不存在" | 62~67 |
| `methodNotAllowed_shouldHaveCode405()` | `METHOD_NOT_ALLOWED` → 405, "请求方法不支持" | 69~74 |
| `conflict_shouldHaveCode409()` | `CONFLICT` → 409, "资源冲突" | 76~81 |
| `tooManyRequests_shouldHaveCode429()` | `TOO_MANY_REQUESTS` → 429, "请求频率过高" | 83~88 |
| `internalError_shouldHaveCode500()` | `INTERNAL_ERROR` → 500, "系统繁忙，请稍后重试" | 90~95 |
| `serviceUnavailable_shouldHaveCode503()` | `SERVICE_UNAVAILABLE` → 503, "服务暂不可用" | 97~102 |

### 3.3 典型测试方法模板

```java
@Test
@DisplayName("枚举名 应具有 code=xxx, message=描述")
void enumName_shouldHaveCodeXxx() {
    assertEquals(xxx, ErrorCode.ENUM_NAME.getCode());
    assertEquals("描述", ErrorCode.ENUM_NAME.getMessage());
}
```

**命名规范：** `{下划线风格枚举名}_shouldHaveCode{状态码}()`
**`@DisplayName` 规范：** `"枚举名 应具有 code=xxx, message=描述"`

---

## 4. 编码规范与风格要求总结

### 4.1 新增枚举格式要求

每个新增枚举占一行，格式如下（参照 context.md）：

```java
    TOKEN_EXPIRED(401, "令牌已过期，请刷新令牌"),          /* AUTH-0001 */
    TOKEN_INVALID(401, "令牌无效"),                          /* AUTH-0002 */
    // ...
    USER_NOT_FOUND(404, "用户不存在");                       /* AUTH-0018 */
```

**格式规则：**
- 每行以 `,` 结尾（最后一个以 `;` 结尾）
- 枚举名使用全大写 + 下划线命名法
- 在行尾添加 `/* AUTH-XXXX */` 行内注释
- 所有枚举常量在 `SERVICE_UNAVAILABLE(503, "服务暂不可用");` **之后**、构造函数**之前**插入

### 4.2 19 个待新增枚举列表

| 序号 | 枚举名 | HTTP 状态码 | 消息文本 | AUTH 编号 |
|------|--------|------------|---------|-----------|
| 1 | `TOKEN_EXPIRED` | 401 | 令牌已过期，请刷新令牌 | AUTH-0001 |
| 2 | `TOKEN_INVALID` | 401 | 令牌无效 | AUTH-0002 |
| 3 | `TOKEN_BLACKLISTED` | 401 | 令牌已被吊销 | AUTH-0003 |
| 4 | `REFRESH_TOKEN_EXPIRED` | 401 | 刷新令牌已过期，请重新登录 | AUTH-0004 |
| 5 | `REFRESH_TOKEN_INVALID` | 401 | 刷新令牌无效 | AUTH-0005 |
| 6 | `ACCOUNT_DISABLED` | 403 | 账号已被禁用 | AUTH-0006 |
| 7 | `ACCOUNT_LOCKED` | 403 | 账号已被锁定 | AUTH-0007 |
| 8 | `ACCOUNT_BANNED` | 403 | 账号已被封禁 | AUTH-0008 |
| 9 | `ACCOUNT_EXPIRED` | 403 | 账号已过期 | AUTH-0009 |
| 10 | `LOGIN_FAILED` | 401 | 用户名或密码错误 | AUTH-0010 |
| 11 | `CAPTCHA_ERROR` | 400 | 验证码错误 | AUTH-0011 |
| 12 | `CLIENT_TYPE_INVALID` | 400 | 无效的客户端类型 | AUTH-0012 |
| 13 | `SESSION_KICKED_OUT` | 401 | 账号已在其他设备登录，您已被踢下线 | AUTH-0013 |
| 14 | `TENANT_DISABLED` | 403 | 租户已被禁用 | AUTH-0014 |
| 15 | `TENANT_EXPIRED` | 403 | 租户已过期 | AUTH-0015 |
| 16 | `PERMISSION_DENIED` | 403 | 权限不足 | AUTH-0016 |
| 17 | `ROLE_NOT_FOUND` | 404 | 角色不存在 | AUTH-0017 |
| 18 | `USER_NOT_FOUND` | 404 | 用户不存在 | AUTH-0018 |
| 19 | `CAPTCHA_EXPIRED` | 400 | 验证码已过期 | AUTH-0019 |

### 4.3 禁删禁改清单

以下 10 个现有枚举**不得删除或修改**：

```
SUCCESS, BAD_REQUEST, UNAUTHORIZED, FORBIDDEN, NOT_FOUND,
METHOD_NOT_ALLOWED, CONFLICT, TOO_MANY_REQUESTS,
INTERNAL_ERROR, SERVICE_UNAVAILABLE
```

---

## 5. 禁止修改的文件

仅以下文件需要修改：

| 操作 | 文件路径 |
|------|---------|
| **修改** | `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java` |
| **不改** | `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/model/ErrorCode.java`（接口定义无需变更） |
| **不改** | `cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCodeTest.java` |
| **不改** | 其他所有文件 |

---

## 6. 编译验证命令

```bash
mvn compile -pl cloudoffice-common
mvn test -pl cloudoffice-common -Dtest=ErrorCodeTest
```
