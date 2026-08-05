/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.RegisterResult;

/**
 * 注册策略接口。
 *
 * <p>每种注册模式实现此接口，处理不同的注册流程。
 * 支持的注册模式包括：用户名密码注册、手机验证码注册、OAuth 第三方注册等。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface RegisterStrategy {

    /**
     * 执行注册。
     *
     * @param request 注册请求（包含 registerMode 及对应凭证）
     * @return 注册结果 RegisterResult
     */
    RegisterResult register(RegisterRequest request);
}
