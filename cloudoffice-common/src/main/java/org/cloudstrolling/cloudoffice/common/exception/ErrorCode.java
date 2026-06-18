package org.cloudstrolling.cloudoffice.common.exception;

import lombok.Getter;

/**
 * 通用错误码枚举
 *
 * <p>定义系统中使用的标准错误码，包含 HTTP 状态码和对应的中文描述。</p>
 *
 * @author CloudStroll Office
 */
@Getter
public enum ErrorCode implements org.cloudstrolling.cloudoffice.common.model.ErrorCode {

    SUCCESS(200, "操作成功"),
    BAD_REQUEST(400, "请求参数错误"),
    UNAUTHORIZED(401, "未授权，请先登录"),
    FORBIDDEN(403, "权限不足"),
    NOT_FOUND(404, "资源不存在"),
    METHOD_NOT_ALLOWED(405, "请求方法不支持"),
    CONFLICT(409, "资源冲突"),
    TOO_MANY_REQUESTS(429, "请求频率过高"),
    INTERNAL_ERROR(500, "系统繁忙，请稍后重试"),
    SERVICE_UNAVAILABLE(503, "服务暂不可用");

    /**
     * 错误码（通常对应 HTTP 状态码）
     */
    private final Integer code;

    /**
     * 错误描述
     */
    private final String message;

    ErrorCode(Integer code, String message) {
        this.code = code;
        this.message = message;
    }
}
