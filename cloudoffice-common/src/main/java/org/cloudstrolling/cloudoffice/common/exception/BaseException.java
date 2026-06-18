package org.cloudstrolling.cloudoffice.common.exception;

import lombok.Getter;

/**
 * 系统异常基类。
 *
 * <p>所有自定义异常的抽象基类，继承 {@link RuntimeException}，使异常可被全局异常处理器捕获。
 * 子类必须提供错误码和错误消息。</p>
 *
 * @author CloudStroll Office
 */
@Getter
public abstract class BaseException extends RuntimeException {

    /**
     * 错误码
     */
    private final Integer code;

    /**
     * 错误消息
     */
    private final String message;

    /**
     * 使用指定错误码和错误消息构造异常。
     *
     * @param code    错误码
     * @param message 错误消息
     */
    protected BaseException(Integer code, String message) {
        super(message);
        this.code = code;
        this.message = message;
    }

    /**
     * 使用错误码枚举构造异常。
     *
     * @param errorCode 错误码枚举
     */
    protected BaseException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.code = errorCode.getCode();
        this.message = errorCode.getMessage();
    }
}
