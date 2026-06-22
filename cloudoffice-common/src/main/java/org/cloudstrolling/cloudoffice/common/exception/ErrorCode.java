package org.cloudstrolling.cloudoffice.common.exception;

import lombok.Getter;

/**
 * 通用错误码枚举
 *
 * <p>定义系统中使用的标准错误码，包含 HTTP 状态码和对应的中文描述。</p>
 *
 * <p>错误码分段规则：</p>
 * <ul>
 *   <li><strong>HTTP-XXXX</strong> — 基础 HTTP 状态码映射（如 SUCCESS、BAD_REQUEST 等）</li>
 *   <li><strong>AUTH-0001 ~ AUTH-9999</strong> — 认证授权相关错误码（令牌、账号、权限、租户等）</li>
 * </ul>
 *
 * @author CloudStroll Office
 */
@Getter
public enum ErrorCode implements org.cloudstrolling.cloudoffice.common.model.ErrorCode {

    SUCCESS(200, "操作成功"),                                                    /* HTTP-0200 */
    BAD_REQUEST(400, "请求参数错误"),                                            /* HTTP-0400 */
    UNAUTHORIZED(401, "未授权，请先登录"),                                       /* HTTP-0401 */
    FORBIDDEN(403, "权限不足"),                                                  /* HTTP-0403 */
    NOT_FOUND(404, "资源不存在"),                                                /* HTTP-0404 */
    METHOD_NOT_ALLOWED(405, "请求方法不支持"),                                   /* HTTP-0405 */
    CONFLICT(409, "资源冲突"),                                                   /* HTTP-0409 */
    TOO_MANY_REQUESTS(429, "请求频率过高"),                                      /* HTTP-0429 */
    INTERNAL_ERROR(500, "系统繁忙，请稍后重试"),                                 /* HTTP-0500 */
    SERVICE_UNAVAILABLE(503, "服务暂不可用"),                                    /* HTTP-0503 */

    // ========== 认证授权错误码 (AUTH-0001 ~ AUTH-9999) ==========
    TOKEN_EXPIRED(401, "令牌已过期，请刷新令牌"),                                          /* AUTH-0001 */
    TOKEN_INVALID(401, "令牌无效"),                                                          /* AUTH-0002 */
    TOKEN_BLACKLISTED(401, "令牌已被吊销"),                                                  /* AUTH-0003 */
    REFRESH_TOKEN_EXPIRED(401, "刷新令牌已过期，请重新登录"),                                 /* AUTH-0004 */
    REFRESH_TOKEN_INVALID(401, "刷新令牌无效"),                                              /* AUTH-0005 */
    ACCOUNT_DISABLED(403, "账号已被禁用"),                                                   /* AUTH-0006 */
    ACCOUNT_LOCKED(403, "账号已被锁定"),                                                     /* AUTH-0007 */
    ACCOUNT_BANNED(403, "账号已被封禁"),                                                     /* AUTH-0008 */
    ACCOUNT_EXPIRED(403, "账号已过期"),                                                      /* AUTH-0009 */
    LOGIN_FAILED(401, "用户名或密码错误"),                                                   /* AUTH-0010 */
    CAPTCHA_ERROR(400, "验证码错误"),                                                        /* AUTH-0011 */
    CLIENT_TYPE_INVALID(400, "无效的客户端类型"),                                            /* AUTH-0012 */
    SESSION_KICKED_OUT(401, "账号已在其他设备登录，您已被踢下线"),                            /* AUTH-0013 */
    TENANT_DISABLED(403, "租户已被禁用"),                                                    /* AUTH-0014 */
    TENANT_EXPIRED(403, "租户已过期"),                                                       /* AUTH-0015 */
    PERMISSION_DENIED(403, "权限不足"),                                                      /* AUTH-0016 */
    ROLE_NOT_FOUND(404, "角色不存在"),                                                       /* AUTH-0017 */
    USER_NOT_FOUND(404, "用户不存在"),                                                       /* AUTH-0018 */
    CAPTCHA_EXPIRED(400, "验证码已过期");                                                    /* AUTH-0019 */

    /**
     * 错误码（通常对应 HTTP 状态码）
     */
    private final Integer code;

    /**
     * 错误描述
     */
    private final String message;

    /**
     * 构造错误码枚举常量
     *
     * @param code    错误码，通常对应 HTTP 状态码
     * @param message 错误描述
     */
    ErrorCode(Integer code, String message) {
        this.code = code;
        this.message = message;
    }
}
