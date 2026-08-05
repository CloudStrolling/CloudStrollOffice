/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.exception;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BaseException 异常基类测试。
 * <p>
 * 通过匿名子类测试 protected 构造函数，验证错误码和错误消息的存储。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("BaseException 异常基类测试")
class BaseExceptionTest {

    @Test
    @DisplayName("BaseException(code, message) 应正确设置 code 和 message")
    void constructorWithCodeAndMessage_shouldSetFields() {
        // 通过匿名子类测试抽象类的 protected 构造函数
        BaseException ex = new BaseException(400, "测试错误消息") {};

        assertEquals(400, ex.getCode());
        assertEquals("测试错误消息", ex.getMessage());
    }

    @Test
    @DisplayName("BaseException(ErrorCode) 应从枚举获取 code 和 message")
    void constructorWithErrorCode_shouldSetFieldsFromEnum() {
        BaseException ex = new BaseException(ErrorCode.BAD_REQUEST) {};

        assertEquals(400, ex.getCode());
        assertEquals("请求参数错误", ex.getMessage());
    }

    @Test
    @DisplayName("BaseException 应继承自 RuntimeException")
    void baseException_shouldExtendRuntimeException() {
        BaseException ex = new BaseException(500, "错误") {};

        assertInstanceOf(RuntimeException.class, ex);
    }

    @Test
    @DisplayName("BaseException 的 message 应传递给父类 RuntimeException")
    void message_shouldBePassedToRuntimeException() {
        String message = "测试消息";
        BaseException ex = new BaseException(400, message) {};

        // RuntimeException.getMessage() 应返回相同的消息
        assertEquals(message, ex.getMessage());
        assertEquals(message, ((RuntimeException) ex).getMessage());
    }
}
