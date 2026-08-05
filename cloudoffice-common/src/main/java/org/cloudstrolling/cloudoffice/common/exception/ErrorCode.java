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
    CAPTCHA_EXPIRED(400, "验证码已过期"),                                                    /* AUTH-0019 */

    // ===== 密码管理错误码 =====
    PASSWORD_RESET_TOKEN_INVALID("AUTH-0020", 400, "密码重置令牌无效"),
    PASSWORD_RESET_TOKEN_EXPIRED("AUTH-0021", 400, "密码重置令牌已过期"),
    OLD_PASSWORD_INCORRECT("AUTH-0022", 400, "原密码错误"),

    // ===== 短信验证码错误码 =====
    SMS_CODE_INVALID("AUTH-0023", 400, "短信验证码无效"),
    SMS_CODE_EXPIRED("AUTH-0024", 400, "短信验证码已过期"),
    SMS_SEND_TOO_FREQUENT("AUTH-0025", 429, "验证码发送过于频繁"),

    // ===== OAuth认证错误码 =====
    OAUTH_LOGIN_FAILED("AUTH-0026", 401, "第三方登录失败"),
    OAUTH_ACCOUNT_NOT_BOUND("AUTH-0027", 404, "第三方账号未绑定"),
    OAUTH_ACCOUNT_ALREADY_BOUND("AUTH-0029", 409, "第三方账号已被其他用户绑定"),

    // ===== 手机号错误码 =====
    PHONE_ALREADY_BOUND("AUTH-0028", 409, "手机号已被其他账号绑定"),

    // ===== 账号状态错误码 =====
    EMAIL_VERIFICATION_REQUIRED("AUTH-0030", 403, "需要邮箱验证"),
    ACCOUNT_NOT_SETTLED("AUTH-0031", 403, "账号信息未完善，请先补充资料"),

    // ===== 模式错误码 =====
    REGISTER_MODE_INVALID("AUTH-0032", 400, "无效的注册模式"),
    LOGIN_MODE_INVALID("AUTH-0033", 400, "无效的登录模式");

    /**
     * 业务错误码（如 AUTH-0020）
     */
    private final String bizCode;

    /**
     * 错误码（通常对应 HTTP 状态码）
     */
    private final Integer code;

    /**
     * 错误描述
     */
    private final String message;

    /**
     * 构造错误码枚举常量（用于业务错误码）。
     *
     * @param bizCode 业务错误码，如 "AUTH-0020"
     * @param code    错误码，通常对应 HTTP 状态码
     * @param message 错误描述
     */
    ErrorCode(String bizCode, Integer code, String message) {
        this.bizCode = bizCode;
        this.code = code;
        this.message = message;
    }

    /**
     * 构造错误码枚举常量（用于基础 HTTP 错误码）。
     *
     * @param code    错误码，通常对应 HTTP 状态码
     * @param message 错误描述
     */
    ErrorCode(Integer code, String message) {
        this.bizCode = null;
        this.code = code;
        this.message = message;
    }
}
