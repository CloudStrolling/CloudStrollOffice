# 测试用例文档 - CloudStrollOffice Common v0.1.0

> **模块**: `cloudoffice-common`  
> **版本**: v0.1.0  
> **创建日期**: 2026-06-18  
> **负责人**: TE（测试工程师）

---

## 1. ApiResult 统一响应体测试

**测试文件**: `model/ApiResultTest.java`

| # | 测试方法 | 输入 | 预期输出 | 边界场景 |
|---|---------|------|---------|---------|
| 1 | `success_withData_shouldReturnSuccessResponse` | `success("testData")` | code=200, message="操作成功", data="testData", timestamp 非 null | 正常带数据 |
| 2 | `success_withoutData_shouldReturnSuccessResponse` | `success()` | code=200, message="操作成功", data=null, timestamp 非 null | 无数据成功 |
| 3 | `error_withCodeAndMessage_shouldReturnErrorResponse` | `error(400, "请求参数错误")` | code=400, message="请求参数错误", data=null, timestamp 非 null | 纯错误码+消息 |
| 4 | `error_withErrorCode_shouldReturnErrorResponse` | `error(ErrorCode.BAD_REQUEST)` | code=400, message="请求参数错误", data=null, timestamp 非 null | 枚举传参 |
| 5 | `error_withCodeMessageData_shouldReturnErrorResponse` | `error(500, "系统错误", "附加信息")` | code=500, message="系统错误", data="附加信息", timestamp 非 null | 带数据的错误 |
| 6 | `chainSetters_shouldReturnThis` | `setCode(200).setMessage("msg")...` | 每个 setter 返回 this 引用 | 链式调用 |
| 7 | `constructor_shouldSetTimestamp` | `new ApiResult<>()` | timestamp 非 null 且 > 0 | 无参构造 |

---

## 2. PageResult 分页结果测试

**测试文件**: `model/PageResultTest.java`

| # | 测试方法 | 输入 | 预期输出 | 边界场景 |
|---|---------|------|---------|---------|
| 1 | `empty_shouldReturnDefaultEmptyPage` | `PageResult.empty()` | total=0, page=1, pageSize=10, records 空列表 | 空分页默认值 |
| 2 | `of_shouldReturnPopulatedPageResult` | `of(["a","b","c"], 100, 2, 20)` | records=["a","b","c"], total=100, page=2, pageSize=20 | 正常分页构造 |

---

## 3. ErrorCode 枚举测试

**测试文件**: `exception/ErrorCodeTest.java`

| # | 测试方法 | 验证常量 | 预期 code | 预期 message | 边界场景 |
|---|---------|---------|-----------|-------------|---------|
| 1 | `allEnumConstants_shouldHaveNonNullCodeAndMessage` | 全部常量 | 非 null | 非 null | 全部枚举 |
| 2 | `success_shouldHaveCode200` | SUCCESS | 200 | "操作成功" | 成功码 |
| 3 | `badRequest_shouldHaveCode400` | BAD_REQUEST | 400 | "请求参数错误" | 客户端错误 |
| 4 | `unauthorized_shouldHaveCode401` | UNAUTHORIZED | 401 | "未授权，请先登录" | 认证错误 |
| 5 | `forbidden_shouldHaveCode403` | FORBIDDEN | 403 | "权限不足" | 鉴权错误 |
| 6 | `notFound_shouldHaveCode404` | NOT_FOUND | 404 | "资源不存在" | 资源缺失 |
| 7 | `methodNotAllowed_shouldHaveCode405` | METHOD_NOT_ALLOWED | 405 | "请求方法不支持" | 方法不支持 |
| 8 | `conflict_shouldHaveCode409` | CONFLICT | 409 | "资源冲突" | 冲突 |
| 9 | `tooManyRequests_shouldHaveCode429` | TOO_MANY_REQUESTS | 429 | "请求频率过高" | 限流 |
| 10 | `internalError_shouldHaveCode500` | INTERNAL_ERROR | 500 | "系统繁忙，请稍后重试" | 服务端错误 |
| 11 | `serviceUnavailable_shouldHaveCode503` | SERVICE_UNAVAILABLE | 503 | "服务暂不可用" | 服务不可用 |

---

## 4. BaseException 异常基类测试

**测试文件**: `exception/BaseExceptionTest.java`

| # | 测试方法 | 输入 | 预期输出 | 边界场景 |
|---|---------|------|---------|---------|
| 1 | `constructorWithCodeAndMessage_shouldSetFields` | `new BaseException(400, "测试消息"){}` | code=400, message="测试消息" | 匿名子类构造(code+message) |
| 2 | `constructorWithErrorCode_shouldSetFieldsFromEnum` | `new BaseException(ErrorCode.BAD_REQUEST){}` | code=400, message="请求参数错误" | 匿名子类构造(枚举) |
| 3 | `baseException_shouldExtendRuntimeException` | `new BaseException(500, "错误"){}` | instanceof RuntimeException | 继承链验证 |
| 4 | `message_shouldBePassedToRuntimeException` | message="测试消息" | getMessage() == "测试消息" | 消息传递验证 |

---

## 5. BusinessException 业务异常测试

**测试文件**: `exception/BusinessExceptionTest.java`

| # | 测试方法 | 输入 | 预期输出 | 边界场景 |
|---|---------|------|---------|---------|
| 1 | `constructorWithCodeMessageModule_shouldSetAllFields` | `(400, "业务异常", "BIZ-0001")` | code=400, message="业务异常", module="BIZ-0001" | 全参数构造 |
| 2 | `constructorWithErrorCodeModule_shouldSetAllFields` | `(ErrorCode.BAD_REQUEST, "BIZ-0001")` | code=400, message="请求参数错误", module="BIZ-0001" | 枚举+模块 |
| 3 | `constructorWithCodeMessage_shouldSetCodeAndMessage` | `(500, "系统异常")` | code=500, message="系统异常", module=null | 无模块构造 |
| 4 | `constructorWithErrorCode_shouldSetFromEnum` | `(ErrorCode.INTERNAL_ERROR)` | code=500, message="系统繁忙，请稍后重试", module=null | 仅枚举 |
| 5 | `businessException_shouldExtendBaseException` | 任意构造 | instanceof BaseException, instanceof RuntimeException | 继承链验证 |
| 6 | `getters_shouldReturnCorrectValues` | `(403, "权限不足", "AUTH-001")` | getter 返回正确值 | getter 验证 |

---

## 6. GlobalExceptionHandler 全局异常处理器测试

**测试文件**: `exception/GlobalExceptionHandlerTest.java`

| # | 测试方法 | 输入异常 | 预期 HTTP 状态码 | 预期响应体 | 边界场景 |
|---|---------|---------|----------------|------------|---------|
| 1 | `handleMethodArgumentNotValid_shouldReturn400` | `MethodArgumentNotValidException` (1 字段错误) | 400 BAD_REQUEST | code=400, message 包含字段名和错误 | 单字段校验失败 |
| 2 | `handleMethodArgumentNotValid_withMultipleFieldErrors_shouldJoinMessages` | `MethodArgumentNotValidException` (2 字段错误) | 400 BAD_REQUEST | message 包含 ";" 分隔的多字段错误 | 多字段校验失败 |
| 3 | `handleBusinessException_shouldReturn400` | `BusinessException(400, "业务错误", "BIZ")` | 400 BAD_REQUEST | code=400, message="业务错误" | 标准业务异常 |
| 4 | `handleBusinessException_withDifferentErrorCode_shouldReturnCorrectly` | `BusinessException(409, "资源冲突")` | 400 BAD_REQUEST | code=409, message="资源冲突" | 不同错误码 |
| 5 | `handleAuthException_shouldReturn401` | `AuthException(UNAUTHORIZED)` | 401 UNAUTHORIZED | code=401, message="未授权，请先登录" | 认证异常 |
| 6 | `handleMethodNotSupported_shouldReturn405` | `HttpRequestMethodNotSupportedException("GET", ["POST"])` | 405 METHOD_NOT_ALLOWED | code=405, message="请求方法不支持" | 方法不支持 |
| 7 | `handleException_shouldReturn500` | `RuntimeException("未知错误")` | 500 INTERNAL_SERVER_ERROR | code=500, message="系统繁忙，请稍后重试" | 兜底异常 |
| 8 | `handleException_shouldReturnGenericMessageNotDetail` | `RuntimeException("数据库连接失败")` | 500 INTERNAL_SERVER_ERROR | message="系统繁忙，请稍后重试"（不泄露细节） | 信息防泄露 |

---

## 7. BaseEntity 基础实体测试

**测试文件**: `model/BaseEntityTest.java`

| # | 测试方法 | 输入 | 预期输出 | 边界场景 |
|---|---------|------|---------|---------|
| 1 | `anonymousSubclass_shouldHaveAllFields` | 匿名子类实例, set fields | getter 返回正确值 | 字段读写 |
| 2 | `idField_shouldHaveTableIdAnnotation` | 反射获取 id 字段 | @TableId(type=ASSIGN_ID) | 主键注解 |
| 3 | `createTimeField_shouldHaveInsertFillAnnotation` | 反射获取 createTime 字段 | @TableField(fill=INSERT) | 创建时间填充注解 |
| 4 | `updateTimeField_shouldHaveInsertUpdateFillAnnotation` | 反射获取 updateTime 字段 | @TableField(fill=INSERT_UPDATE) | 更新时间填充注解 |
| 5 | `deletedField_shouldHaveTableLogicAndInsertFillAnnotation` | 反射获取 deleted 字段 | @TableLogic + @TableField(fill=INSERT) | 逻辑删除注解 |

---

## 8. JsonUtils JSON 工具类测试

**测试文件**: `util/JsonUtilsTest.java`

| # | 测试方法 | 输入 | 预期输出 | 边界场景 |
|---|---------|------|---------|---------|
| 1 | `toJsonString_withMap_shouldReturnJsonString` | `{name=CloudStroll, version=1, active=true}` | 包含 key 和 value 的 JSON 字符串 | Map 序列化 |
| 2 | `toJsonString_withNull_shouldReturnNull` | `null` | null | null 输入 |
| 3 | `toJsonString_withString_shouldReturnQuotedString` | `"hello"` | `"\"hello\""` | 字符串序列化 |
| 4 | `toJsonString_withInteger_shouldReturnNumberString` | `42` | `"42"` | 数字序列化 |
| 5 | `toJsonString_withBoolean_shouldReturnBooleanString` | `true` | `"true"` | 布尔序列化 |
| 6 | `toJsonString_withList_shouldReturnJsonArrayString` | `["a","b","c"]` | `"[\"a\",\"b\",\"c\"]"` | List 序列化 |
| 7 | `toJsonString_withEmptyString_shouldReturnQuotedEmptyString` | `""` | `"\"\""` | 空字符串序列化 |

---

## 9. MyBatisPlusConfig 自动填充处理器测试

**测试文件**: `config/MyBatisPlusConfigTest.java`

| # | 测试方法 | 输入 | 预期行为 | 边界场景 |
|---|---------|------|---------|---------|
| 1 | `insertFill_shouldCallStrictInsertFillForCreateTime` | mock MetaObject | 调用 strictInsertFill(metaObject, "createTime", LocalDateTime.class, now()) | createTime 插入填充 |
| 2 | `insertFill_shouldCallStrictInsertFillForUpdateTime` | mock MetaObject | 调用 strictInsertFill(metaObject, "updateTime", LocalDateTime.class, now()) | updateTime 插入填充 |
| 3 | `insertFill_shouldCallStrictInsertFillForDeleted` | mock MetaObject | 调用 strictInsertFill(metaObject, "deleted", Integer.class, 0) | deleted 插入填充 |
| 4 | `updateFill_shouldCallStrictUpdateFill` | mock MetaObject | 调用 strictUpdateFill(metaObject, "updateTime", LocalDateTime.class, now()) | updateTime 更新填充 |
| 5 | `insertFill_shouldCallStrictInsertFillExactlyThreeTimes` | mock MetaObject | strictInsertFill 恰好被调用 3 次 | 调用次数验证 |
| 6 | `updateFill_shouldNotCallStrictInsertFill` | mock MetaObject | strictInsertFill 从未被调用 | 操作隔离性验证 |

---

## 测试统计

| 测试文件 | 测试方法数 | 测试类 |
|---------|-----------|-------|
| ApiResultTest | 7 | ApiResult |
| PageResultTest | 2 | PageResult |
| ErrorCodeTest | 11 | ErrorCode (enum) |
| BaseExceptionTest | 4 | BaseException |
| BusinessExceptionTest | 6 | BusinessException |
| GlobalExceptionHandlerTest | 8 | GlobalExceptionHandler |
| BaseEntityTest | 5 | BaseEntity |
| JsonUtilsTest | 7 | JsonUtils |
| MyBatisPlusConfigTest | 6 | MyBatisPlusConfig |
| **合计** | **56** | **9 个测试类** |
