/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.service.VerificationCodeService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

/**
 * 模拟验证码发送服务实现。
 *
 * <p>在开发或测试环境下，通过日志输出验证码内容而不实际发送。
 * 使用 {@code app.verification-code.mock=true} 配置启用（默认启用）。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "app.verification-code.mock", havingValue = "true", matchIfMissing = true)
public class SimulatedVerificationCodeService implements VerificationCodeService {

    @Override
    public void sendSmsCode(String phone, String code, String purpose) {
        log.info("【模拟短信验证码】手机号：{}，验证码：{}，用途：{}", phone, code, purpose);
    }

    @Override
    public void sendEmailCode(String email, String code, String purpose) {
        log.info("【模拟邮件验证码】邮箱：{}，验证码：{}，用途：{}", email, code, purpose);
    }
}
