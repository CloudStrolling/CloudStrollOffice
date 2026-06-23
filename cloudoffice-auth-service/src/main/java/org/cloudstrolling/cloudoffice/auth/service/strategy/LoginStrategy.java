/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;

/**
 * 登录策略接口。
 *
 * <p>每种登录方式实现此接口，实现不同的凭证校验逻辑。
 * 支持的登录方式包括：用户名密码登录、手机验证码登录、手机密码登录、OAuth 第三方登录。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface LoginStrategy {

    /**
     * 执行登录认证。
     *
     * @param request 登录请求（包含 loginMode 及对应凭证）
     * @return 认证结果 AuthResult
     */
    AuthResult authenticate(LoginRequest request);
}
