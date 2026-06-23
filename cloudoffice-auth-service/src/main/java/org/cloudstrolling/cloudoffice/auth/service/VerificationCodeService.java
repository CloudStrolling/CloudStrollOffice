/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

/**
 * 验证码发送服务接口。
 *
 * <p>提供短信和邮件验证码的实际发送能力，
 * 具体发送方式由实现类决定（模拟、阿里云短信、腾讯云短信等）。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface VerificationCodeService {

    /**
     * 发送短信验证码。
     *
     * @param phone   目标手机号
     * @param code    验证码内容
     * @param purpose 验证码用途（REGISTER、LOGIN、RESET_PWD、BIND 等）
     */
    void sendSmsCode(String phone, String code, String purpose);

    /**
     * 发送邮件验证码。
     *
     * @param email   目标邮箱
     * @param code    验证码内容
     * @param purpose 验证码用途（REGISTER、LOGIN、RESET_PWD、BIND 等）
     */
    void sendEmailCode(String email, String code, String purpose);
}
