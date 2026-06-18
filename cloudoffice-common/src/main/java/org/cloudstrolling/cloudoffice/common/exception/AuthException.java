/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.exception;

import lombok.extern.slf4j.Slf4j;

/**
 * 认证异常。
 *
 * <p>用于表示用户认证失败（如未登录、Token 无效或过期）的场景，
 * 全局异常处理器会将其映射为 HTTP 401 状态码。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
public class AuthException extends BaseException {

    /**
     * 使用错误码枚举构造认证异常。
     *
     * @param errorCode 错误码枚举
     */
    public AuthException(ErrorCode errorCode) {
        super(errorCode);
        log.error("AuthException occurred | code={} | message={}", errorCode.getCode(), errorCode.getMessage());
    }

    /**
     * 使用错误码和错误消息构造认证异常。
     *
     * @param code    错误码
     * @param message 错误消息
     */
    public AuthException(Integer code, String message) {
        super(code, message);
        log.error("AuthException occurred | code={} | message={}", code, message);
    }

    /**
     * 使用错误码枚举和自定义消息构造认证异常。
     *
     * @param errorCode 错误码枚举
     * @param message   自定义错误消息
     */
    public AuthException(ErrorCode errorCode, String message) {
        super(errorCode.getCode(), message);
        log.error("AuthException occurred | code={} | message={}", errorCode.getCode(), message);
    }
}
