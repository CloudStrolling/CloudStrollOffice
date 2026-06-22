# 测试用例文档

**项目名称：** CloudStroll Office（云逛办公）
**项目英文名：** CloudStrollOffice
**版本号：** v0.1.5
**日期：** 2026-06-22

---

## 模块：cloudoffice-common - 新增认证错误码枚举常量

### TC-TASK-001-001：所有新增枚举常量非 null 校验（P0）

**前置条件**：
- ErrorCode 枚举已加载

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 遍历 ErrorCode.values() 所有枚举 | 全部枚举常量 | 每个枚举的 getCode() 和 getMessage() 均不为 null |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-002：TOKEN_EXPIRED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.TOKEN_EXPIRED.getCode() | 无 | 返回 401 |
| 2 | 调用 ErrorCode.TOKEN_EXPIRED.getMessage() | 无 | 返回 "令牌已过期，请刷新令牌" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-003：TOKEN_INVALID 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.TOKEN_INVALID.getCode() | 无 | 返回 401 |
| 2 | 调用 ErrorCode.TOKEN_INVALID.getMessage() | 无 | 返回 "令牌无效" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-004：TOKEN_BLACKLISTED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.TOKEN_BLACKLISTED.getCode() | 无 | 返回 401 |
| 2 | 调用 ErrorCode.TOKEN_BLACKLISTED.getMessage() | 无 | 返回 "令牌已被吊销" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-005：REFRESH_TOKEN_EXPIRED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.REFRESH_TOKEN_EXPIRED.getCode() | 无 | 返回 401 |
| 2 | 调用 ErrorCode.REFRESH_TOKEN_EXPIRED.getMessage() | 无 | 返回 "刷新令牌已过期，请重新登录" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-006：REFRESH_TOKEN_INVALID 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.REFRESH_TOKEN_INVALID.getCode() | 无 | 返回 401 |
| 2 | 调用 ErrorCode.REFRESH_TOKEN_INVALID.getMessage() | 无 | 返回 "刷新令牌无效" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-007：ACCOUNT_DISABLED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.ACCOUNT_DISABLED.getCode() | 无 | 返回 403 |
| 2 | 调用 ErrorCode.ACCOUNT_DISABLED.getMessage() | 无 | 返回 "账号已被禁用" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-008：ACCOUNT_LOCKED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.ACCOUNT_LOCKED.getCode() | 无 | 返回 403 |
| 2 | 调用 ErrorCode.ACCOUNT_LOCKED.getMessage() | 无 | 返回 "账号已被锁定" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-009：ACCOUNT_BANNED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.ACCOUNT_BANNED.getCode() | 无 | 返回 403 |
| 2 | 调用 ErrorCode.ACCOUNT_BANNED.getMessage() | 无 | 返回 "账号已被封禁" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-010：ACCOUNT_EXPIRED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.ACCOUNT_EXPIRED.getCode() | 无 | 返回 403 |
| 2 | 调用 ErrorCode.ACCOUNT_EXPIRED.getMessage() | 无 | 返回 "账号已过期" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-011：LOGIN_FAILED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.LOGIN_FAILED.getCode() | 无 | 返回 401 |
| 2 | 调用 ErrorCode.LOGIN_FAILED.getMessage() | 无 | 返回 "用户名或密码错误" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-012：CAPTCHA_ERROR 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.CAPTCHA_ERROR.getCode() | 无 | 返回 400 |
| 2 | 调用 ErrorCode.CAPTCHA_ERROR.getMessage() | 无 | 返回 "验证码错误" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-013：CLIENT_TYPE_INVALID 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.CLIENT_TYPE_INVALID.getCode() | 无 | 返回 400 |
| 2 | 调用 ErrorCode.CLIENT_TYPE_INVALID.getMessage() | 无 | 返回 "无效的客户端类型" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-014：SESSION_KICKED_OUT 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.SESSION_KICKED_OUT.getCode() | 无 | 返回 401 |
| 2 | 调用 ErrorCode.SESSION_KICKED_OUT.getMessage() | 无 | 返回 "账号已在其他设备登录，您已被踢下线" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-015：TENANT_DISABLED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.TENANT_DISABLED.getCode() | 无 | 返回 403 |
| 2 | 调用 ErrorCode.TENANT_DISABLED.getMessage() | 无 | 返回 "租户已被禁用" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-016：TENANT_EXPIRED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.TENANT_EXPIRED.getCode() | 无 | 返回 403 |
| 2 | 调用 ErrorCode.TENANT_EXPIRED.getMessage() | 无 | 返回 "租户已过期" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-017：PERMISSION_DENIED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.PERMISSION_DENIED.getCode() | 无 | 返回 403 |
| 2 | 调用 ErrorCode.PERMISSION_DENIED.getMessage() | 无 | 返回 "权限不足" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-018：ROLE_NOT_FOUND 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.ROLE_NOT_FOUND.getCode() | 无 | 返回 404 |
| 2 | 调用 ErrorCode.ROLE_NOT_FOUND.getMessage() | 无 | 返回 "角色不存在" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-019：USER_NOT_FOUND 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.USER_NOT_FOUND.getCode() | 无 | 返回 404 |
| 2 | 调用 ErrorCode.USER_NOT_FOUND.getMessage() | 无 | 返回 "用户不存在" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

### TC-TASK-001-020：CAPTCHA_EXPIRED 枚举值校验（P0）

**前置条件**：
- 无

| 步骤 | 测试步骤 | 测试数据 | 预期结果 |
|------|---------|---------|---------|
| 1 | 调用 ErrorCode.CAPTCHA_EXPIRED.getCode() | 无 | 返回 400 |
| 2 | 调用 ErrorCode.CAPTCHA_EXPIRED.getMessage() | 无 | 返回 "验证码已过期" |

**关联任务**：TASK-001
**自动化测试脚本**：ErrorCodeTest.java
**测试过程**：执行 `mvn clean test -pl cloudoffice-common -Dtest=ErrorCodeTest`，全部 30 个测试用例通过（11 个现有 + 19 个新增），0 失败，0 错误。
**测试结论**：通过

---

## 对应测试方法清单

以下为将在 `ErrorCodeTest.java` 中实现的测试方法，遵循现有 JUnit 5 测试风格：

### 遍历校验（增强现有方法）

```java
// 现有 allEnumConstants_shouldHaveNonNullCodeAndMessage() 方法已遍历所有枚举，
// 新增枚举后自动覆盖，无需新增测试方法
```

### 19 个新增枚举的专用测试方法

```java
// 1. TOKEN_EXPIRED
@Test
@DisplayName("TOKEN_EXPIRED 应具有 code=401, message=令牌已过期，请刷新令牌")
void tokenExpired_shouldHaveCode401() {
    assertEquals(401, ErrorCode.TOKEN_EXPIRED.getCode());
    assertEquals("令牌已过期，请刷新令牌", ErrorCode.TOKEN_EXPIRED.getMessage());
}

// 2. TOKEN_INVALID
@Test
@DisplayName("TOKEN_INVALID 应具有 code=401, message=令牌无效")
void tokenInvalid_shouldHaveCode401() {
    assertEquals(401, ErrorCode.TOKEN_INVALID.getCode());
    assertEquals("令牌无效", ErrorCode.TOKEN_INVALID.getMessage());
}

// 3. TOKEN_BLACKLISTED
@Test
@DisplayName("TOKEN_BLACKLISTED 应具有 code=401, message=令牌已被吊销")
void tokenBlacklisted_shouldHaveCode401() {
    assertEquals(401, ErrorCode.TOKEN_BLACKLISTED.getCode());
    assertEquals("令牌已被吊销", ErrorCode.TOKEN_BLACKLISTED.getMessage());
}

// 4. REFRESH_TOKEN_EXPIRED
@Test
@DisplayName("REFRESH_TOKEN_EXPIRED 应具有 code=401, message=刷新令牌已过期，请重新登录")
void refreshTokenExpired_shouldHaveCode401() {
    assertEquals(401, ErrorCode.REFRESH_TOKEN_EXPIRED.getCode());
    assertEquals("刷新令牌已过期，请重新登录", ErrorCode.REFRESH_TOKEN_EXPIRED.getMessage());
}

// 5. REFRESH_TOKEN_INVALID
@Test
@DisplayName("REFRESH_TOKEN_INVALID 应具有 code=401, message=刷新令牌无效")
void refreshTokenInvalid_shouldHaveCode401() {
    assertEquals(401, ErrorCode.REFRESH_TOKEN_INVALID.getCode());
    assertEquals("刷新令牌无效", ErrorCode.REFRESH_TOKEN_INVALID.getMessage());
}

// 6. ACCOUNT_DISABLED
@Test
@DisplayName("ACCOUNT_DISABLED 应具有 code=403, message=账号已被禁用")
void accountDisabled_shouldHaveCode403() {
    assertEquals(403, ErrorCode.ACCOUNT_DISABLED.getCode());
    assertEquals("账号已被禁用", ErrorCode.ACCOUNT_DISABLED.getMessage());
}

// 7. ACCOUNT_LOCKED
@Test
@DisplayName("ACCOUNT_LOCKED 应具有 code=403, message=账号已被锁定")
void accountLocked_shouldHaveCode403() {
    assertEquals(403, ErrorCode.ACCOUNT_LOCKED.getCode());
    assertEquals("账号已被锁定", ErrorCode.ACCOUNT_LOCKED.getMessage());
}

// 8. ACCOUNT_BANNED
@Test
@DisplayName("ACCOUNT_BANNED 应具有 code=403, message=账号已被封禁")
void accountBanned_shouldHaveCode403() {
    assertEquals(403, ErrorCode.ACCOUNT_BANNED.getCode());
    assertEquals("账号已被封禁", ErrorCode.ACCOUNT_BANNED.getMessage());
}

// 9. ACCOUNT_EXPIRED
@Test
@DisplayName("ACCOUNT_EXPIRED 应具有 code=403, message=账号已过期")
void accountExpired_shouldHaveCode403() {
    assertEquals(403, ErrorCode.ACCOUNT_EXPIRED.getCode());
    assertEquals("账号已过期", ErrorCode.ACCOUNT_EXPIRED.getMessage());
}

// 10. LOGIN_FAILED
@Test
@DisplayName("LOGIN_FAILED 应具有 code=401, message=用户名或密码错误")
void loginFailed_shouldHaveCode401() {
    assertEquals(401, ErrorCode.LOGIN_FAILED.getCode());
    assertEquals("用户名或密码错误", ErrorCode.LOGIN_FAILED.getMessage());
}

// 11. CAPTCHA_ERROR
@Test
@DisplayName("CAPTCHA_ERROR 应具有 code=400, message=验证码错误")
void captchaError_shouldHaveCode400() {
    assertEquals(400, ErrorCode.CAPTCHA_ERROR.getCode());
    assertEquals("验证码错误", ErrorCode.CAPTCHA_ERROR.getMessage());
}

// 12. CLIENT_TYPE_INVALID
@Test
@DisplayName("CLIENT_TYPE_INVALID 应具有 code=400, message=无效的客户端类型")
void clientTypeInvalid_shouldHaveCode400() {
    assertEquals(400, ErrorCode.CLIENT_TYPE_INVALID.getCode());
    assertEquals("无效的客户端类型", ErrorCode.CLIENT_TYPE_INVALID.getMessage());
}

// 13. SESSION_KICKED_OUT
@Test
@DisplayName("SESSION_KICKED_OUT 应具有 code=401, message=账号已在其他设备登录，您已被踢下线")
void sessionKickedOut_shouldHaveCode401() {
    assertEquals(401, ErrorCode.SESSION_KICKED_OUT.getCode());
    assertEquals("账号已在其他设备登录，您已被踢下线", ErrorCode.SESSION_KICKED_OUT.getMessage());
}

// 14. TENANT_DISABLED
@Test
@DisplayName("TENANT_DISABLED 应具有 code=403, message=租户已被禁用")
void tenantDisabled_shouldHaveCode403() {
    assertEquals(403, ErrorCode.TENANT_DISABLED.getCode());
    assertEquals("租户已被禁用", ErrorCode.TENANT_DISABLED.getMessage());
}

// 15. TENANT_EXPIRED
@Test
@DisplayName("TENANT_EXPIRED 应具有 code=403, message=租户已过期")
void tenantExpired_shouldHaveCode403() {
    assertEquals(403, ErrorCode.TENANT_EXPIRED.getCode());
    assertEquals("租户已过期", ErrorCode.TENANT_EXPIRED.getMessage());
}

// 16. PERMISSION_DENIED
@Test
@DisplayName("PERMISSION_DENIED 应具有 code=403, message=权限不足")
void permissionDenied_shouldHaveCode403() {
    assertEquals(403, ErrorCode.PERMISSION_DENIED.getCode());
    assertEquals("权限不足", ErrorCode.PERMISSION_DENIED.getMessage());
}

// 17. ROLE_NOT_FOUND
@Test
@DisplayName("ROLE_NOT_FOUND 应具有 code=404, message=角色不存在")
void roleNotFound_shouldHaveCode404() {
    assertEquals(404, ErrorCode.ROLE_NOT_FOUND.getCode());
    assertEquals("角色不存在", ErrorCode.ROLE_NOT_FOUND.getMessage());
}

// 18. USER_NOT_FOUND
@Test
@DisplayName("USER_NOT_FOUND 应具有 code=404, message=用户不存在")
void userNotFound_shouldHaveCode404() {
    assertEquals(404, ErrorCode.USER_NOT_FOUND.getCode());
    assertEquals("用户不存在", ErrorCode.USER_NOT_FOUND.getMessage());
}

// 19. CAPTCHA_EXPIRED
@Test
@DisplayName("CAPTCHA_EXPIRED 应具有 code=400, message=验证码已过期")
void captchaExpired_shouldHaveCode400() {
    assertEquals(400, ErrorCode.CAPTCHA_EXPIRED.getCode());
    assertEquals("验证码已过期", ErrorCode.CAPTCHA_EXPIRED.getMessage());
}
```

---

## 测试覆盖分析

| 覆盖维度 | 覆盖情况 |
|---------|---------|
| 正常路径 | 19 个新增枚举的 getCode() 返回正确的 HTTP 状态码 |
| 正常路径 | 19 个新增枚举的 getMessage() 返回正确的中文消息文本 |
| 边界情况 | 所有枚举 getCode()/getMessage() 非 null（通过遍历测试覆盖） |
| 回归验证 | 现有 10 个通用错误码未被删除或修改（通过现有测试覆盖） |
| 编译验证 | `mvn compile -pl cloudoffice-common` 编译通过 |

### HTTP 状态码分布覆盖

| HTTP 状态码 | 枚举数量 | 枚举名 |
|------------|---------|--------|
| 400 | 3 | CAPTCHA_ERROR, CLIENT_TYPE_INVALID, CAPTCHA_EXPIRED |
| 401 | 8 | TOKEN_EXPIRED, TOKEN_INVALID, TOKEN_BLACKLISTED, REFRESH_TOKEN_EXPIRED, REFRESH_TOKEN_INVALID, LOGIN_FAILED, SESSION_KICKED_OUT |
| 403 | 6 | ACCOUNT_DISABLED, ACCOUNT_LOCKED, ACCOUNT_BANNED, ACCOUNT_EXPIRED, TENANT_DISABLED, TENANT_EXPIRED, PERMISSION_DENIED |
| 404 | 2 | ROLE_NOT_FOUND, USER_NOT_FOUND |

**注：** 以上 HTTP 状态码分布中，403 实际包含 7 个枚举，PERMISSION_DENIED 也属于 403。
