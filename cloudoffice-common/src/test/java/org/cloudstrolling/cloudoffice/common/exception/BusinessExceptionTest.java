/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.exception;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BusinessException 业务异常测试。
 * <p>
 * 验证各种构造函数重载以及继承链：
 * BusinessException → BaseException → RuntimeException。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("BusinessException 业务异常测试")
class BusinessExceptionTest {

    @Test
    @DisplayName("BusinessException(code, message, module) 应正确设置所有字段")
    void constructorWithCodeMessageModule_shouldSetAllFields() {
        BusinessException ex = new BusinessException(400, "业务异常", "BIZ-0001");

        assertEquals(400, ex.getCode());
        assertEquals("业务异常", ex.getMessage());
        assertEquals("BIZ-0001", ex.getModule());
    }

    @Test
    @DisplayName("BusinessException(ErrorCode, module) 应从枚举获取 code/message 并设置 module")
    void constructorWithErrorCodeModule_shouldSetAllFields() {
        BusinessException ex = new BusinessException(ErrorCode.BAD_REQUEST, "BIZ-0001");

        assertEquals(400, ex.getCode());
        assertEquals("请求参数错误", ex.getMessage());
        assertEquals("BIZ-0001", ex.getModule());
    }

    @Test
    @DisplayName("BusinessException(code, message) 应设置 code 和 message，module 为 null")
    void constructorWithCodeMessage_shouldSetCodeAndMessage() {
        BusinessException ex = new BusinessException(500, "系统异常");

        assertEquals(500, ex.getCode());
        assertEquals("系统异常", ex.getMessage());
        assertNull(ex.getModule());
    }

    @Test
    @DisplayName("BusinessException(ErrorCode) 应从枚举获取，module 为 null")
    void constructorWithErrorCode_shouldSetFromEnum() {
        BusinessException ex = new BusinessException(ErrorCode.INTERNAL_ERROR);

        assertEquals(500, ex.getCode());
        assertEquals("系统繁忙，请稍后重试", ex.getMessage());
        assertNull(ex.getModule());
    }

    @Test
    @DisplayName("BusinessException 应继承自 BaseException 和 RuntimeException")
    void businessException_shouldExtendBaseException() {
        BusinessException ex = new BusinessException(400, "test", "MODULE");

        assertInstanceOf(BaseException.class, ex);
        assertInstanceOf(RuntimeException.class, ex);
    }

    @Test
    @DisplayName("BusinessException 的 getter 应返回正确的字段值")
    void getters_shouldReturnCorrectValues() {
        BusinessException ex = new BusinessException(403, "权限不足", "AUTH-001");

        assertEquals(403, ex.getCode());
        assertEquals("权限不足", ex.getMessage());
        assertEquals("AUTH-001", ex.getModule());
    }
}
