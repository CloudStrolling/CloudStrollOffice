/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.exception;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ErrorCode 通用错误码枚举测试。
 * <p>
 * 验证所有枚举常量的 code 和 message 非 null，以及每个常量的预期值。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("ErrorCode 枚举测试")
class ErrorCodeTest {

    @Test
    @DisplayName("所有枚举常量应具有非 null 的 code 和 message")
    void allEnumConstants_shouldHaveNonNullCodeAndMessage() {
        for (ErrorCode errorCode : ErrorCode.values()) {
            assertNotNull(errorCode.getCode(), errorCode.name() + " 的 code 不应为 null");
            assertNotNull(errorCode.getMessage(), errorCode.name() + " 的 message 不应为 null");
        }
    }

    @Test
    @DisplayName("SUCCESS 应具有 code=200, message=操作成功")
    void success_shouldHaveCode200() {
        assertEquals(200, ErrorCode.SUCCESS.getCode());
        assertEquals("操作成功", ErrorCode.SUCCESS.getMessage());
    }

    @Test
    @DisplayName("BAD_REQUEST 应具有 code=400, message=请求参数错误")
    void badRequest_shouldHaveCode400() {
        assertEquals(400, ErrorCode.BAD_REQUEST.getCode());
        assertEquals("请求参数错误", ErrorCode.BAD_REQUEST.getMessage());
    }

    @Test
    @DisplayName("UNAUTHORIZED 应具有 code=401, message=未授权，请先登录")
    void unauthorized_shouldHaveCode401() {
        assertEquals(401, ErrorCode.UNAUTHORIZED.getCode());
        assertEquals("未授权，请先登录", ErrorCode.UNAUTHORIZED.getMessage());
    }

    @Test
    @DisplayName("FORBIDDEN 应具有 code=403, message=权限不足")
    void forbidden_shouldHaveCode403() {
        assertEquals(403, ErrorCode.FORBIDDEN.getCode());
        assertEquals("权限不足", ErrorCode.FORBIDDEN.getMessage());
    }

    @Test
    @DisplayName("NOT_FOUND 应具有 code=404, message=资源不存在")
    void notFound_shouldHaveCode404() {
        assertEquals(404, ErrorCode.NOT_FOUND.getCode());
        assertEquals("资源不存在", ErrorCode.NOT_FOUND.getMessage());
    }

    @Test
    @DisplayName("METHOD_NOT_ALLOWED 应具有 code=405, message=请求方法不支持")
    void methodNotAllowed_shouldHaveCode405() {
        assertEquals(405, ErrorCode.METHOD_NOT_ALLOWED.getCode());
        assertEquals("请求方法不支持", ErrorCode.METHOD_NOT_ALLOWED.getMessage());
    }

    @Test
    @DisplayName("CONFLICT 应具有 code=409, message=资源冲突")
    void conflict_shouldHaveCode409() {
        assertEquals(409, ErrorCode.CONFLICT.getCode());
        assertEquals("资源冲突", ErrorCode.CONFLICT.getMessage());
    }

    @Test
    @DisplayName("TOO_MANY_REQUESTS 应具有 code=429, message=请求频率过高")
    void tooManyRequests_shouldHaveCode429() {
        assertEquals(429, ErrorCode.TOO_MANY_REQUESTS.getCode());
        assertEquals("请求频率过高", ErrorCode.TOO_MANY_REQUESTS.getMessage());
    }

    @Test
    @DisplayName("INTERNAL_ERROR 应具有 code=500, message=系统繁忙，请稍后重试")
    void internalError_shouldHaveCode500() {
        assertEquals(500, ErrorCode.INTERNAL_ERROR.getCode());
        assertEquals("系统繁忙，请稍后重试", ErrorCode.INTERNAL_ERROR.getMessage());
    }

    @Test
    @DisplayName("SERVICE_UNAVAILABLE 应具有 code=503, message=服务暂不可用")
    void serviceUnavailable_shouldHaveCode503() {
        assertEquals(503, ErrorCode.SERVICE_UNAVAILABLE.getCode());
        assertEquals("服务暂不可用", ErrorCode.SERVICE_UNAVAILABLE.getMessage());
    }

    // ========== 认证授权错误码测试 (AUTH-0001 ~ AUTH-0019) ==========

    @Test
    @DisplayName("TOKEN_EXPIRED 应具有 code=401, message=令牌已过期，请刷新令牌")
    void tokenExpired_shouldHaveCode401() {
        assertEquals(401, ErrorCode.TOKEN_EXPIRED.getCode());
        assertEquals("令牌已过期，请刷新令牌", ErrorCode.TOKEN_EXPIRED.getMessage());
    }

    @Test
    @DisplayName("TOKEN_INVALID 应具有 code=401, message=令牌无效")
    void tokenInvalid_shouldHaveCode401() {
        assertEquals(401, ErrorCode.TOKEN_INVALID.getCode());
        assertEquals("令牌无效", ErrorCode.TOKEN_INVALID.getMessage());
    }

    @Test
    @DisplayName("TOKEN_BLACKLISTED 应具有 code=401, message=令牌已被吊销")
    void tokenBlacklisted_shouldHaveCode401() {
        assertEquals(401, ErrorCode.TOKEN_BLACKLISTED.getCode());
        assertEquals("令牌已被吊销", ErrorCode.TOKEN_BLACKLISTED.getMessage());
    }

    @Test
    @DisplayName("REFRESH_TOKEN_EXPIRED 应具有 code=401, message=刷新令牌已过期，请重新登录")
    void refreshTokenExpired_shouldHaveCode401() {
        assertEquals(401, ErrorCode.REFRESH_TOKEN_EXPIRED.getCode());
        assertEquals("刷新令牌已过期，请重新登录", ErrorCode.REFRESH_TOKEN_EXPIRED.getMessage());
    }

    @Test
    @DisplayName("REFRESH_TOKEN_INVALID 应具有 code=401, message=刷新令牌无效")
    void refreshTokenInvalid_shouldHaveCode401() {
        assertEquals(401, ErrorCode.REFRESH_TOKEN_INVALID.getCode());
        assertEquals("刷新令牌无效", ErrorCode.REFRESH_TOKEN_INVALID.getMessage());
    }

    @Test
    @DisplayName("ACCOUNT_DISABLED 应具有 code=403, message=账号已被禁用")
    void accountDisabled_shouldHaveCode403() {
        assertEquals(403, ErrorCode.ACCOUNT_DISABLED.getCode());
        assertEquals("账号已被禁用", ErrorCode.ACCOUNT_DISABLED.getMessage());
    }

    @Test
    @DisplayName("ACCOUNT_LOCKED 应具有 code=403, message=账号已被锁定")
    void accountLocked_shouldHaveCode403() {
        assertEquals(403, ErrorCode.ACCOUNT_LOCKED.getCode());
        assertEquals("账号已被锁定", ErrorCode.ACCOUNT_LOCKED.getMessage());
    }

    @Test
    @DisplayName("ACCOUNT_BANNED 应具有 code=403, message=账号已被封禁")
    void accountBanned_shouldHaveCode403() {
        assertEquals(403, ErrorCode.ACCOUNT_BANNED.getCode());
        assertEquals("账号已被封禁", ErrorCode.ACCOUNT_BANNED.getMessage());
    }

    @Test
    @DisplayName("ACCOUNT_EXPIRED 应具有 code=403, message=账号已过期")
    void accountExpired_shouldHaveCode403() {
        assertEquals(403, ErrorCode.ACCOUNT_EXPIRED.getCode());
        assertEquals("账号已过期", ErrorCode.ACCOUNT_EXPIRED.getMessage());
    }

    @Test
    @DisplayName("LOGIN_FAILED 应具有 code=401, message=用户名或密码错误")
    void loginFailed_shouldHaveCode401() {
        assertEquals(401, ErrorCode.LOGIN_FAILED.getCode());
        assertEquals("用户名或密码错误", ErrorCode.LOGIN_FAILED.getMessage());
    }

    @Test
    @DisplayName("CAPTCHA_ERROR 应具有 code=400, message=验证码错误")
    void captchaError_shouldHaveCode400() {
        assertEquals(400, ErrorCode.CAPTCHA_ERROR.getCode());
        assertEquals("验证码错误", ErrorCode.CAPTCHA_ERROR.getMessage());
    }

    @Test
    @DisplayName("CLIENT_TYPE_INVALID 应具有 code=400, message=无效的客户端类型")
    void clientTypeInvalid_shouldHaveCode400() {
        assertEquals(400, ErrorCode.CLIENT_TYPE_INVALID.getCode());
        assertEquals("无效的客户端类型", ErrorCode.CLIENT_TYPE_INVALID.getMessage());
    }

    @Test
    @DisplayName("SESSION_KICKED_OUT 应具有 code=401, message=账号已在其他设备登录，您已被踢下线")
    void sessionKickedOut_shouldHaveCode401() {
        assertEquals(401, ErrorCode.SESSION_KICKED_OUT.getCode());
        assertEquals("账号已在其他设备登录，您已被踢下线", ErrorCode.SESSION_KICKED_OUT.getMessage());
    }

    @Test
    @DisplayName("TENANT_DISABLED 应具有 code=403, message=租户已被禁用")
    void tenantDisabled_shouldHaveCode403() {
        assertEquals(403, ErrorCode.TENANT_DISABLED.getCode());
        assertEquals("租户已被禁用", ErrorCode.TENANT_DISABLED.getMessage());
    }

    @Test
    @DisplayName("TENANT_EXPIRED 应具有 code=403, message=租户已过期")
    void tenantExpired_shouldHaveCode403() {
        assertEquals(403, ErrorCode.TENANT_EXPIRED.getCode());
        assertEquals("租户已过期", ErrorCode.TENANT_EXPIRED.getMessage());
    }

    @Test
    @DisplayName("PERMISSION_DENIED 应具有 code=403, message=权限不足")
    void permissionDenied_shouldHaveCode403() {
        assertEquals(403, ErrorCode.PERMISSION_DENIED.getCode());
        assertEquals("权限不足", ErrorCode.PERMISSION_DENIED.getMessage());
    }

    @Test
    @DisplayName("ROLE_NOT_FOUND 应具有 code=404, message=角色不存在")
    void roleNotFound_shouldHaveCode404() {
        assertEquals(404, ErrorCode.ROLE_NOT_FOUND.getCode());
        assertEquals("角色不存在", ErrorCode.ROLE_NOT_FOUND.getMessage());
    }

    @Test
    @DisplayName("USER_NOT_FOUND 应具有 code=404, message=用户不存在")
    void userNotFound_shouldHaveCode404() {
        assertEquals(404, ErrorCode.USER_NOT_FOUND.getCode());
        assertEquals("用户不存在", ErrorCode.USER_NOT_FOUND.getMessage());
    }

    @Test
    @DisplayName("CAPTCHA_EXPIRED 应具有 code=400, message=验证码已过期")
    void captchaExpired_shouldHaveCode400() {
        assertEquals(400, ErrorCode.CAPTCHA_EXPIRED.getCode());
        assertEquals("验证码已过期", ErrorCode.CAPTCHA_EXPIRED.getMessage());
    }
}
