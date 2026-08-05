/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 密码忘记/重置请求 DTO。
 *
 * <p>通过邮箱或短信验证码重置密码。
 * 支持两种模式：</p>
 * <ul>
 *   <li><strong>EMAIL</strong> — 通过邮箱验证码重置</li>
 *   <li><strong>SMS</strong> — 通过手机短信验证码重置</li>
 * </ul>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "密码重置请求 DTO，支持邮箱和短信两种验证方式")
public class PasswordForgotRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 验证方式（EMAIL|SMS）
     */
    @NotBlank(message = "验证方式不能为空")
    @Schema(description = "验证方式", example = "SMS", allowableValues = {"EMAIL", "SMS"})
    private String mode;

    /**
     * 验证目标（手机号或邮箱），不能为空
     */
    @NotBlank(message = "验证目标不能为空")
    @Schema(description = "验证目标，手机号或邮箱", example = "13800138000")
    private String target;

    /**
     * 验证码，不能为空
     */
    @NotBlank(message = "验证码不能为空")
    @Schema(description = "验证码", example = "123456")
    private String code;

    /**
     * 新密码，长度 8-64 字符
     */
    @NotBlank(message = "新密码不能为空")
    @Size(min = 8, max = 64, message = "新密码长度8-64字符")
    @Schema(description = "新密码，长度8-64字符", example = "newPassword456")
    private String newPassword;
}
