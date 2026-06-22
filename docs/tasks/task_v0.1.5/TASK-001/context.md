# TASK-001 上下文文档

## 基本信息

| 项目 | 内容 |
|------|------|
| **任务编号** | TASK-001 |
| **任务标题** | 新增认证错误码枚举常量 |
| **关联 UserStory** | US-001：认证错误码扩展 |
| **优先级** | P0 |
| **当前状态** | context_finish |
| **上游依赖** | 无 |
| **下游依赖** | TASK-009（AuthFilter）、TASK-030（AuthController） |
| **模块** | cloudoffice-common |

---

## 1. 任务目标

在 `cloudoffice-common` 模块的 `ErrorCode` 枚举中新增 19 个认证授权相关错误码枚举常量（`TOKEN_EXPIRED`、`TOKEN_INVALID`、`TOKEN_BLACKLISTED` 等），每个枚举映射正确的 HTTP 状态码和中文消息文本，不得删除或修改现有通用错误码。

---

## 2. 现有 ErrorCode 枚举结构

### 2.1 文件位置

```
cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java
```

### 2.2 当前枚举常量（10 个）

| 枚举名 | HTTP 状态码 | 消息文本 |
|--------|------------|---------|
| `SUCCESS` | 200 | 操作成功 |
| `BAD_REQUEST` | 400 | 请求参数错误 |
| `UNAUTHORIZED` | 401 | 未授权，请先登录 |
| `FORBIDDEN` | 403 | 权限不足 |
| `NOT_FOUND` | 404 | 资源不存在 |
| `METHOD_NOT_ALLOWED` | 405 | 请求方法不支持 |
| `CONFLICT` | 409 | 资源冲突 |
| `TOO_MANY_REQUESTS` | 429 | 请求频率过高 |
| `INTERNAL_ERROR` | 500 | 系统繁忙，请稍后重试 |
| `SERVICE_UNAVAILABLE` | 503 | 服务暂不可用 |

### 2.3 当前代码结构

```java
package org.cloudstrolling.cloudoffice.common.exception;

import lombok.Getter;

/**
 * 通用错误码枚举
 *
 * <p>定义系统中使用的标准错误码，包含 HTTP 状态码和对应的中文描述。</p>
 *
 * @author CloudStroll Office
 */
@Getter
public enum ErrorCode implements org.cloudstrolling.cloudoffice.common.model.ErrorCode {

    SUCCESS(200, "操作成功"),
    BAD_REQUEST(400, "请求参数错误"),
    // ... 其他枚举常量

    INTERNAL_ERROR(500, "系统繁忙，请稍后重试"),
    SERVICE_UNAVAILABLE(503, "服务暂不可用");

    private final Integer code;
    private final String message;

    ErrorCode(Integer code, String message) {
        this.code = code;
        this.message = message;
    }
}
```

### 2.4 关键接口

枚举实现了 `org.cloudstrolling.cloudoffice.common.model.ErrorCode` 接口，该接口定义了 `getCode()` 和 `getMessage()` 契约方法。

---

## 3. 需要新增的 19 个认证错误码

新增错误码按顺序排列，并标注 AUTH 模块编号注释：

| 序号 | 枚举名 | HTTP 状态码 | 消息文本 | AUTH 编号 |
|------|--------|------------|---------|-----------|
| 1 | `TOKEN_EXPIRED` | 401 | 令牌已过期，请刷新令牌 | `/* AUTH-0001 */` |
| 2 | `TOKEN_INVALID` | 401 | 令牌无效 | `/* AUTH-0002 */` |
| 3 | `TOKEN_BLACKLISTED` | 401 | 令牌已被吊销 | `/* AUTH-0003 */` |
| 4 | `REFRESH_TOKEN_EXPIRED` | 401 | 刷新令牌已过期，请重新登录 | `/* AUTH-0004 */` |
| 5 | `REFRESH_TOKEN_INVALID` | 401 | 刷新令牌无效 | `/* AUTH-0005 */` |
| 6 | `ACCOUNT_DISABLED` | 403 | 账号已被禁用 | `/* AUTH-0006 */` |
| 7 | `ACCOUNT_LOCKED` | 403 | 账号已被锁定 | `/* AUTH-0007 */` |
| 8 | `ACCOUNT_BANNED` | 403 | 账号已被封禁 | `/* AUTH-0008 */` |
| 9 | `ACCOUNT_EXPIRED` | 403 | 账号已过期 | `/* AUTH-0009 */` |
| 10 | `LOGIN_FAILED` | 401 | 用户名或密码错误 | `/* AUTH-0010 */` |
| 11 | `CAPTCHA_ERROR` | 400 | 验证码错误 | `/* AUTH-0011 */` |
| 12 | `CLIENT_TYPE_INVALID` | 400 | 无效的客户端类型 | `/* AUTH-0012 */` |
| 13 | `SESSION_KICKED_OUT` | 401 | 账号已在其他设备登录，您已被踢下线 | `/* AUTH-0013 */` |
| 14 | `TENANT_DISABLED` | 403 | 租户已被禁用 | `/* AUTH-0014 */` |
| 15 | `TENANT_EXPIRED` | 403 | 租户已过期 | `/* AUTH-0015 */` |
| 16 | `PERMISSION_DENIED` | 403 | 权限不足 | `/* AUTH-0016 */` |
| 17 | `ROLE_NOT_FOUND` | 404 | 角色不存在 | `/* AUTH-0017 */` |
| 18 | `USER_NOT_FOUND` | 404 | 用户不存在 | `/* AUTH-0018 */` |

> **注意：** PRD US-001 AC1 中列出了 18 个枚举常量，加上现有代码中的 `PERMISSION_DENIED`（403，"权限不足"）实际上已存在（现有 `FORBIDDEN` 也是"权限不足"但消息文本不同），但 SDS 4.4 明确要求单独列出 `PERMISSION_DENIED` 常量。因此实际新增为 **19 个**（含 SDS 4.4 表中的全部新条目）。AC1 的清单未包含 `PERMISSION_DENIED`，但 SDS 和任务描述要求新增它。

---

## 4. 编码规范与注意事项

### 4.1 文件操作要求

- **仅修改文件：** `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java`
- **禁删禁改：** 不可删除或修改现有的 10 个通用错误码（SUCCESS/BAD_REQUEST/UNAUTHORIZED/FORBIDDEN/NOT_FOUND/METHOD_NOT_ALLOWED/CONFLICT/TOO_MANY_REQUESTS/INTERNAL_ERROR/SERVICE_UNAVAILABLE）
- **新增位置：** 在最后现有枚举之后、构造函数之前新增
- **枚举分隔：** 每个枚举占用一行，末尾添加 `,`（最后一个枚举常量后跟 `;`）

### 4.2 代码风格

- 每个枚举常量添加行内注释 `/* AUTH-XXXX */` 标注模块归属
- 与现有枚举保持相同的代码风格和注释规范
- 保持 K&R 大括号风格（左大括号不换行）
- 缩进使用 4 个空格
- 行宽不超过 120 字符
- 文件编码统一 UTF-8

### 4.3 错误码设计说明

- 错误码使用 **HTTP 状态码**作为 `code` 值（`Integer` 类型）
- `AUTH-XXXX` 仅在注释中标明模块归属，不体现在 `code` 中
- 各错误码 HTTP 状态码选用规则：
  - **400**（Bad Request）：参数类错误（验证码、客户端类型）
  - **401**（Unauthorized）：认证类错误（Token 过期/无效/黑名单、刷新令牌过期、登录失败、被踢下线）
  - **403**（Forbidden）：权限类错误（账号禁用/锁定/封禁/过期、租户禁用/过期、权限不足）
  - **404**（Not Found）：资源不存在（用户、角色）

### 4.4 编译要求

- `mvn compile -pl cloudoffice-common` 编译通过，无错误警告

### 4.5 测试要求

- 每个新增错误码需验证 `getCode()` 和 `getMessage()` 返回值与 PRD/SDS 一致
- 现有测试（`ErrorCodeTest.java`）不受影响
- 参见现有测试文件：`cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCodeTest.java`

---

## 5. 关键参考链接/文档路径

| 文档 | 路径 | 相关章节 |
|------|------|---------|
| PRD 文档 | `docs/prds/CloudStrollOffice-prd-v0.1.5.md` | US-001（第 62~117 行） |
| SDS 文档 | `docs/sds/CloudStrollOffice-sds-v0.1.5.md` | 2.3 公共模块（第 164~173 行）、4.4 错误码定义（第 751~779 行） |
| 架构文档 | `docs/architecture.md` | 2.1 公共模块（第 91~103 行） |
| 项目文档 | `docs/project.md` | 统一错误处理规范（第 127~140 行） |
| 任务清单 | `docs/tasks/CloudStrollOffice-task-v0.1.5.md` | TASK-001（第 50~105 行） |
| 任务 JSON | `docs/tasks/CloudStrollOffice-task-v0.1.5.json` | TASK-001（第 9~22 行） |
| 现有 ErrorCode | `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCode.java` | 全部（40 行） |
| 现有 ErrorCodeTest | `cloudoffice-common/src/test/java/org/cloudstrolling/cloudoffice/common/exception/ErrorCodeTest.java` | 测试参考 |
| ErrorCode 接口 | `cloudoffice-common/src/main/java/org/cloudstrolling/cloudoffice/common/model/ErrorCode.java` | 接口定义（getCode/getMessage） |

---

## 6. 验收标准汇总

| 编号 | 验收标准 |
|------|---------|
| AC1 | 19 个认证授权错误码枚举常量已新增，HTTP 状态码映射正确，消息文本与 PRD/SDS 一致 |
| AC2 | 调用 `getCode()` 返回 `Integer` 类型正确错误码，调用 `getMessage()` 返回 `String` 类型正确中文描述 |
| AC3 | `mvn compile -pl cloudoffice-common` 编译通过，无错误警告，现有错误码未被破坏 |
| AC4 | 现有错误码（SUCCESS/BAD_REQUEST 等 10 个）未被删除或修改 |
