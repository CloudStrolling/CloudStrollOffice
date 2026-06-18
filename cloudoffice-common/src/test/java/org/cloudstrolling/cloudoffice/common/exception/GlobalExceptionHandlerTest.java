/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.exception;

import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindingResult;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * GlobalExceptionHandler 全局异常处理器测试。
 * <p>
 * 使用 Mockito 模拟各类异常，验证处理器返回正确的 HTTP 状态码和响应体。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("GlobalExceptionHandler 全局异常处理器测试")
class GlobalExceptionHandlerTest {

    private GlobalExceptionHandler handler;

    @BeforeEach
    void setUp() {
        handler = new GlobalExceptionHandler();
    }

    @Test
    @DisplayName("MethodArgumentNotValidException 应返回 400，消息包含字段错误详情")
    void handleMethodArgumentNotValid_shouldReturn400() {
        // 准备：模拟 MethodArgumentNotValidException
        MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
        BindingResult bindingResult = mock(BindingResult.class);
        FieldError fieldError = new FieldError("obj", "fieldName", "不能为空");
        when(bindingResult.getFieldErrors()).thenReturn(List.of(fieldError));
        when(ex.getBindingResult()).thenReturn(bindingResult);

        // 执行
        ResponseEntity<ApiResult<Void>> response = handler.handleMethodArgumentNotValid(ex);

        // 验证
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(400, response.getBody().getCode());
        assertTrue(response.getBody().getMessage().contains("fieldName"));
        assertTrue(response.getBody().getMessage().contains("不能为空"));
    }

    @Test
    @DisplayName("MethodArgumentNotValidException 多字段错误时应拼接所有错误信息")
    void handleMethodArgumentNotValid_withMultipleFieldErrors_shouldJoinMessages() {
        // 准备：多字段错误
        MethodArgumentNotValidException ex = mock(MethodArgumentNotValidException.class);
        BindingResult bindingResult = mock(BindingResult.class);
        FieldError fieldError1 = new FieldError("obj", "name", "不能为空");
        FieldError fieldError2 = new FieldError("obj", "age", "必须大于0");
        when(bindingResult.getFieldErrors()).thenReturn(List.of(fieldError1, fieldError2));
        when(ex.getBindingResult()).thenReturn(bindingResult);

        // 执行
        ResponseEntity<ApiResult<Void>> response = handler.handleMethodArgumentNotValid(ex);

        // 验证
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        String message = response.getBody().getMessage();
        assertTrue(message.contains("name: 不能为空"));
        assertTrue(message.contains("age: 必须大于0"));
        assertTrue(message.contains("; "), "多个错误应以分号分隔");
    }

    @Test
    @DisplayName("BusinessException 应返回 400 和对应 code/message")
    void handleBusinessException_shouldReturn400() {
        BusinessException ex = new BusinessException(400, "业务错误", "BIZ-TEST");

        ResponseEntity<ApiResult<Void>> response = handler.handleBusinessException(ex);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(400, response.getBody().getCode());
        assertEquals("业务错误", response.getBody().getMessage());
    }

    @Test
    @DisplayName("BusinessException 不同错误码应正确返回")
    void handleBusinessException_withDifferentErrorCode_shouldReturnCorrectly() {
        BusinessException ex = new BusinessException(409, "资源冲突", "BIZ-CONFLICT");

        ResponseEntity<ApiResult<Void>> response = handler.handleBusinessException(ex);

        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(409, response.getBody().getCode());
        assertEquals("资源冲突", response.getBody().getMessage());
    }

    @Test
    @DisplayName("AuthException 应返回 401")
    void handleAuthException_shouldReturn401() {
        AuthException ex = new AuthException(ErrorCode.UNAUTHORIZED);

        ResponseEntity<ApiResult<Void>> response = handler.handleAuthException(ex);

        assertEquals(HttpStatus.UNAUTHORIZED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(401, response.getBody().getCode());
        assertEquals("未授权，请先登录", response.getBody().getMessage());
    }

    @Test
    @DisplayName("HttpRequestMethodNotSupportedException 应返回 405")
    void handleMethodNotSupported_shouldReturn405() {
        HttpRequestMethodNotSupportedException ex =
                new HttpRequestMethodNotSupportedException("GET", List.of("POST"));

        ResponseEntity<ApiResult<Void>> response = handler.handleMethodNotSupported(ex);

        assertEquals(HttpStatus.METHOD_NOT_ALLOWED, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(405, response.getBody().getCode());
        assertEquals("请求方法不支持", response.getBody().getMessage());
    }

    @Test
    @DisplayName("Exception（兜底）应返回 500，message 为系统繁忙，请稍后重试")
    void handleException_shouldReturn500() {
        Exception ex = new RuntimeException("未知错误");

        ResponseEntity<ApiResult<Void>> response = handler.handleException(ex);

        assertEquals(HttpStatus.INTERNAL_SERVER_ERROR, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(500, response.getBody().getCode());
        assertEquals("系统繁忙，请稍后重试", response.getBody().getMessage());
    }

    @Test
    @DisplayName("Exception 兜底处理器应返回通用错误消息而非异常详情")
    void handleException_shouldReturnGenericMessageNotDetail() {
        Exception ex = new RuntimeException("数据库连接失败: timeout");

        ResponseEntity<ApiResult<Void>> response = handler.handleException(ex);

        assertNotNull(response.getBody());
        // 不应返回具体的异常细节，防止信息泄露
        assertNotEquals("数据库连接失败: timeout", response.getBody().getMessage());
        assertEquals("系统繁忙，请稍后重试", response.getBody().getMessage());
    }
}
