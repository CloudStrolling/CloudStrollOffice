/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.exception;

import jakarta.validation.ConstraintViolationException;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.beans.TypeMismatchException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.validation.BindException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.NoHandlerFoundException;

import java.util.stream.Collectors;

/**
 * 全局异常处理器。
 *
 * <p>使用 {@link RestControllerAdvice} 统一捕获并处理系统中抛出的各类异常，
 * 返回结构统一的 {@link ApiResult} 响应体，避免堆栈信息泄露到客户端。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 参数校验异常（{@link jakarta.validation.Valid} + {@link org.springframework.web.bind.annotation.RequestBody}）。
     * <p>提取所有字段错误信息并拼接为字符串返回。</p>
     *
     * @param ex 异常
     * @return 400 + 字段错误详情
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResult<Void>> handleMethodArgumentNotValid(MethodArgumentNotValidException ex) {
        String message = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .collect(Collectors.joining("; "));
        log.error("参数校验异常 | 字段错误: {}", message, ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResult.error(ErrorCode.BAD_REQUEST.getCode(), message));
    }

    /**
     * 业务异常，由 {@link BusinessException} 抛出。
     *
     * @param ex 业务异常
     * @return 400 + 错误码和消息
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<ApiResult<Void>> handleBusinessException(BusinessException ex) {
        log.error("业务异常 | code={} | message={}", ex.getCode(), ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResult.error(ex.getCode(), ex.getMessage()));
    }

    /**
     * 认证异常，由 {@link AuthException} 抛出。
     *
     * @param ex 认证异常
     * @return 401 Unauthorized
     */
    @ExceptionHandler(AuthException.class)
    public ResponseEntity<ApiResult<Void>> handleAuthException(AuthException ex) {
        log.error("认证异常 | code={} | message={}", ex.getCode(), ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResult.error(ErrorCode.UNAUTHORIZED.getCode(), ErrorCode.UNAUTHORIZED.getMessage()));
    }

    /**
     * 凭证异常（Spring Security），登录密码错误等场景。
     *
     * @param ex 凭证异常
     * @return 401 Unauthorized
     */
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ApiResult<Void>> handleBadCredentialsException(BadCredentialsException ex) {
        log.error("凭证认证失败 | message={}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResult.error(ErrorCode.UNAUTHORIZED.getCode(), ex.getMessage()));
    }

    /**
     * 权限不足异常（Spring Security），访问未授权资源时抛出。
     *
     * @param ex 权限异常
     * @return 403 Forbidden
     */
    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<ApiResult<Void>> handleAccessDeniedException(AccessDeniedException ex) {
        log.error("权限不足 | message={}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(ApiResult.error(ErrorCode.FORBIDDEN.getCode(), ErrorCode.FORBIDDEN.getMessage()));
    }

    /**
     * 绑定异常（表单提交或 {@link org.springframework.web.bind.annotation.ModelAttribute}）。
     *
     * @param ex 绑定异常
     * @return 400 Bad Request
     */
    @ExceptionHandler(BindException.class)
    public ResponseEntity<ApiResult<Void>> handleBindException(BindException ex) {
        String message = ex.getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .collect(Collectors.joining("; "));
        log.error("参数绑定异常 | 字段错误: {}", message, ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResult.error(ErrorCode.BAD_REQUEST.getCode(), message));
    }

    /**
     * HTTP 请求方法不支持。
     *
     * @param ex 方法不支持异常
     * @return 405 Method Not Allowed
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    public ResponseEntity<ApiResult<Void>> handleMethodNotSupported(HttpRequestMethodNotSupportedException ex) {
        log.error("请求方法不支持 | {} {}", ex.getMethod(), ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.METHOD_NOT_ALLOWED)
                .body(ApiResult.error(ErrorCode.METHOD_NOT_ALLOWED.getCode(), ErrorCode.METHOD_NOT_ALLOWED.getMessage()));
    }

    /**
     * 404 未找到处理器（需配置 {@code spring.mvc.throw-exception-if-no-handler-found=true}）。
     *
     * @param ex 未找到处理器异常
     * @return 404 Not Found
     */
    @ExceptionHandler(NoHandlerFoundException.class)
    public ResponseEntity<ApiResult<Void>> handleNoHandlerFound(NoHandlerFoundException ex) {
        log.error("接口不存在 | {} {}", ex.getHttpMethod(), ex.getRequestURL(), ex);
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiResult.error(ErrorCode.NOT_FOUND.getCode(), ErrorCode.NOT_FOUND.getMessage()));
    }

    /**
     * 缺少必需的请求参数。
     *
     * @param ex 缺少参数异常
     * @return 400 Bad Request
     */
    @ExceptionHandler(MissingServletRequestParameterException.class)
    public ResponseEntity<ApiResult<Void>> handleMissingServletRequestParameter(
            MissingServletRequestParameterException ex) {
        log.error("缺少请求参数 | {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResult.error(ErrorCode.BAD_REQUEST.getCode(), ex.getMessage()));
    }

    /**
     * Bean Validation 参数约束违规（{@link jakarta.validation.constraints} 直接标注在方法参数上）。
     *
     * @param ex 约束违规异常
     * @return 400 Bad Request
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ApiResult<Void>> handleConstraintViolation(ConstraintViolationException ex) {
        String message = ex.getConstraintViolations().stream()
                .map(cv -> cv.getPropertyPath() + ": " + cv.getMessage())
                .collect(Collectors.joining("; "));
        log.error("参数约束违规 | {}", message, ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResult.error(ErrorCode.BAD_REQUEST.getCode(), message));
    }

    /**
     * 请求参数类型不匹配（如字符串无法转换为数字）。
     *
     * @param ex 类型不匹配异常
     * @return 400 Bad Request
     */
    @ExceptionHandler(TypeMismatchException.class)
    public ResponseEntity<ApiResult<Void>> handleTypeMismatch(TypeMismatchException ex) {
        log.error("参数类型转换异常 | {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResult.error(ErrorCode.BAD_REQUEST.getCode(), ex.getMessage()));
    }

    /**
     * HTTP 消息不可读（JSON 解析失败等）。
     *
     * @param ex 消息不可读异常
     * @return 400 Bad Request
     */
    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<ApiResult<Void>> handleHttpMessageNotReadable(HttpMessageNotReadableException ex) {
        log.error("请求体解析失败 | {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiResult.error(ErrorCode.BAD_REQUEST.getCode(), "请求体格式错误"));
    }

    /**
     * 顶层兜底异常处理器，捕获所有未单独处理的异常。
     * <p>记录完整堆栈日志，但仅向客户端返回通用错误信息，避免泄露敏感细节。</p>
     *
     * @param ex 异常
     * @return 500 Internal Server Error
     */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResult<Void>> handleException(Exception ex) {
        log.error("系统内部异常 | 类型={} | 消息={}", ex.getClass().getSimpleName(), ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(ApiResult.error(ErrorCode.INTERNAL_ERROR.getCode(), ErrorCode.INTERNAL_ERROR.getMessage()));
    }
}
