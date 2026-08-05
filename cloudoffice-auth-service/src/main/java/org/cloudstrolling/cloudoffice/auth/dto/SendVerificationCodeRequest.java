/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 发送验证码请求 DTO。
 *
 * <p>向指定目标（手机号或邮箱）发送验证码。
 * 不同用途的验证码适用于不同的业务场景：</p>
 * <ul>
 *   <li><strong>REGISTER</strong> — 注册验证</li>
 *   <li><strong>LOGIN</strong> — 登录验证</li>
 *   <li><strong>RESET_PASSWORD</strong> — 重置密码</li>
 *   <li><strong>CHANGE_PHONE</strong> — 更换手机号</li>
 * </ul>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "发送验证码请求 DTO")
public class SendVerificationCodeRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 验证码接收目标（手机号或邮箱），不能为空
     */
    @NotBlank(message = "验证码接收目标不能为空")
    @Schema(description = "验证码接收目标，手机号或邮箱", example = "13800138000")
    private String target;

    /**
     * 验证码用途（REGISTER|LOGIN|RESET_PASSWORD|CHANGE_PHONE）
     */
    @NotBlank(message = "验证码用途不能为空")
    @Schema(description = "验证码用途", example = "REGISTER", allowableValues = {"REGISTER", "LOGIN", "RESET_PASSWORD", "CHANGE_PHONE"})
    private String purpose;

    /**
     * 发送方式（SMS|EMAIL）
     */
    @NotBlank(message = "发送方式不能为空")
    @Schema(description = "发送方式", example = "SMS", allowableValues = {"SMS", "EMAIL"})
    private String mode;
}
