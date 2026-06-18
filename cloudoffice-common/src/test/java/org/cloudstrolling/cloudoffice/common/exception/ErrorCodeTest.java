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
 * <p>
 * 验证所有枚举常量的 code 和 message 非 null，以及每个常量的预期值。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("ErrorCode 枚举测试")
class ErrorCodeTest {

    @Test
    @DisplayName("所有枚举常量应具有非 null 的 code 和 message")
    void allEnumConstants_shouldHaveNonNullCodeAndMessage() {
        for (ErrorCode errorCode : ErrorCode.values()) {
            assertNotNull(errorCode.getCode(), errorCode.name() + " 的 code 不应为 null");
            assertNotNull(errorCode.getMessage(), errorCode.name() + " 的 message 不应为 null");
        }
    }

    @Test
    @DisplayName("SUCCESS 应具有 code=200, message=操作成功")
    void success_shouldHaveCode200() {
        assertEquals(200, ErrorCode.SUCCESS.getCode());
        assertEquals("操作成功", ErrorCode.SUCCESS.getMessage());
    }

    @Test
    @DisplayName("BAD_REQUEST 应具有 code=400, message=请求参数错误")
    void badRequest_shouldHaveCode400() {
        assertEquals(400, ErrorCode.BAD_REQUEST.getCode());
        assertEquals("请求参数错误", ErrorCode.BAD_REQUEST.getMessage());
    }

    @Test
    @DisplayName("UNAUTHORIZED 应具有 code=401, message=未授权，请先登录")
    void unauthorized_shouldHaveCode401() {
        assertEquals(401, ErrorCode.UNAUTHORIZED.getCode());
        assertEquals("未授权，请先登录", ErrorCode.UNAUTHORIZED.getMessage());
    }

    @Test
    @DisplayName("FORBIDDEN 应具有 code=403, message=权限不足")
    void forbidden_shouldHaveCode403() {
        assertEquals(403, ErrorCode.FORBIDDEN.getCode());
        assertEquals("权限不足", ErrorCode.FORBIDDEN.getMessage());
    }

    @Test
    @DisplayName("NOT_FOUND 应具有 code=404, message=资源不存在")
    void notFound_shouldHaveCode404() {
        assertEquals(404, ErrorCode.NOT_FOUND.getCode());
        assertEquals("资源不存在", ErrorCode.NOT_FOUND.getMessage());
    }

    @Test
    @DisplayName("METHOD_NOT_ALLOWED 应具有 code=405, message=请求方法不支持")
    void methodNotAllowed_shouldHaveCode405() {
        assertEquals(405, ErrorCode.METHOD_NOT_ALLOWED.getCode());
        assertEquals("请求方法不支持", ErrorCode.METHOD_NOT_ALLOWED.getMessage());
    }

    @Test
    @DisplayName("CONFLICT 应具有 code=409, message=资源冲突")
    void conflict_shouldHaveCode409() {
        assertEquals(409, ErrorCode.CONFLICT.getCode());
        assertEquals("资源冲突", ErrorCode.CONFLICT.getMessage());
    }

    @Test
    @DisplayName("TOO_MANY_REQUESTS 应具有 code=429, message=请求频率过高")
    void tooManyRequests_shouldHaveCode429() {
        assertEquals(429, ErrorCode.TOO_MANY_REQUESTS.getCode());
        assertEquals("请求频率过高", ErrorCode.TOO_MANY_REQUESTS.getMessage());
    }

    @Test
    @DisplayName("INTERNAL_ERROR 应具有 code=500, message=系统繁忙，请稍后重试")
    void internalError_shouldHaveCode500() {
        assertEquals(500, ErrorCode.INTERNAL_ERROR.getCode());
        assertEquals("系统繁忙，请稍后重试", ErrorCode.INTERNAL_ERROR.getMessage());
    }

    @Test
    @DisplayName("SERVICE_UNAVAILABLE 应具有 code=503, message=服务暂不可用")
    void serviceUnavailable_shouldHaveCode503() {
        assertEquals(503, ErrorCode.SERVICE_UNAVAILABLE.getCode());
        assertEquals("服务暂不可用", ErrorCode.SERVICE_UNAVAILABLE.getMessage());
    }
}
