package org.cloudstrolling.cloudoffice.common.exception;

import lombok.Getter;
import lombok.extern.slf4j.Slf4j;

/**
 * 业务异常。
 *
 * <p>用于表示业务逻辑层面的异常，附带模块标识以便于问题定位。
 * 异常构造时会自动记录错误日志。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@Getter
public class BusinessException extends BaseException {

    /**
     * 模块标识（如 "BIZ-0001"）
     */
    private final String module;

    /**
     * 使用错误码、错误消息和模块标识构造业务异常。
     *
     * @param code    错误码
     * @param message 错误消息
     * @param module  模块标识
     */
    public BusinessException(Integer code, String message, String module) {
        super(code, message);
        this.module = module;
        log.error("BusinessException occurred | code={} | message={} | module={}", code, message, module);
    }

    /**
     * 使用错误码枚举和模块标识构造业务异常。
     *
     * @param errorCode 错误码枚举
     * @param module    模块标识
     */
    public BusinessException(ErrorCode errorCode, String module) {
        super(errorCode);
        this.module = module;
        log.error("BusinessException occurred | code={} | message={} | module={}",
                errorCode.getCode(), errorCode.getMessage(), module);
    }

    /**
     * 使用错误码和错误消息构造业务异常（无模块标识）。
     *
     * @param code    错误码
     * @param message 错误消息
     */
    public BusinessException(Integer code, String message) {
        super(code, message);
        this.module = null;
        log.error("BusinessException occurred | code={} | message={}", code, message);
    }

    /**
     * 使用错误码枚举构造业务异常（无模块标识）。
     *
     * @param errorCode 错误码枚举
     */
    public BusinessException(ErrorCode errorCode) {
        super(errorCode);
        this.module = null;
        log.error("BusinessException occurred | code={} | message={}",
                errorCode.getCode(), errorCode.getMessage());
    }
}
