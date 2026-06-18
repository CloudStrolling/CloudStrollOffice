/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.model;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ApiResult 统一响应体测试。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("ApiResult 统一响应体测试")
class ApiResultTest {

    @Test
    @DisplayName("success(data) 应返回 code=200, message=操作成功, data=传入值, timestamp 非 null")
    void success_withData_shouldReturnSuccessResponse() {
        String data = "testData";
        ApiResult<String> result = ApiResult.success(data);

        assertEquals(200, result.getCode());
        assertEquals("操作成功", result.getMessage());
        assertSame(data, result.getData());
        assertNotNull(result.getTimestamp());
    }

    @Test
    @DisplayName("success() 应返回 code=200, message=操作成功, data=null, timestamp 非 null")
    void success_withoutData_shouldReturnSuccessResponse() {
        ApiResult<String> result = ApiResult.success();

        assertEquals(200, result.getCode());
        assertEquals("操作成功", result.getMessage());
        assertNull(result.getData());
        assertNotNull(result.getTimestamp());
    }

    @Test
    @DisplayName("error(code, message) 应返回指定错误码和消息，data 为 null")
    void error_withCodeAndMessage_shouldReturnErrorResponse() {
        ApiResult<String> result = ApiResult.error(400, "请求参数错误");

        assertEquals(400, result.getCode());
        assertEquals("请求参数错误", result.getMessage());
        assertNull(result.getData());
        assertNotNull(result.getTimestamp());
    }

    @Test
    @DisplayName("error(ErrorCode) 应从枚举获取 code 和 message")
    void error_withErrorCode_shouldReturnErrorResponse() {
        // 使用 exception 包的 ErrorCode 枚举（实现 model.ErrorCode 接口）
        ApiResult<String> result = ApiResult.error(
                org.cloudstrolling.cloudoffice.common.exception.ErrorCode.BAD_REQUEST);

        assertEquals(400, result.getCode());
        assertEquals("请求参数错误", result.getMessage());
        assertNull(result.getData());
        assertNotNull(result.getTimestamp());
    }

    @Test
    @DisplayName("error(code, message, data) 应返回含附加数据的错误响应")
    void error_withCodeMessageData_shouldReturnErrorResponse() {
        String data = "附加信息";
        ApiResult<String> result = ApiResult.error(500, "系统错误", data);

        assertEquals(500, result.getCode());
        assertEquals("系统错误", result.getMessage());
        assertSame(data, result.getData());
        assertNotNull(result.getTimestamp());
    }

    @Test
    @DisplayName("链式 setter 应返回 this（@Accessors(chain=true) 验证）")
    void chainSetters_shouldReturnThis() {
        ApiResult<String> result = new ApiResult<>();

        assertSame(result, result.setCode(200));
        assertSame(result, result.setMessage("msg"));
        assertSame(result, result.setData("data"));
        assertSame(result, result.setTimestamp(123L));
    }

    @Test
    @DisplayName("无参构造应自动填充非 null 的时间戳")
    void constructor_shouldSetTimestamp() {
        ApiResult<String> result = new ApiResult<>();

        assertNotNull(result.getTimestamp());
        assertTrue(result.getTimestamp() > 0, "时间戳应为正数");
    }
}
