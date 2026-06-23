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
 * 密码修改请求 DTO。
 *
 * <p>用户修改密码时需要提供旧密码、新密码和确认新密码。
 * 新密码需满足长度 8-64 字符的要求。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "密码修改请求 DTO，包含旧密码和新密码")
public class PasswordChangeRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 旧密码，不能为空
     */
    @NotBlank(message = "旧密码不能为空")
    @Schema(description = "旧密码", example = "oldPassword123")
    private String oldPassword;

    /**
     * 新密码，长度 8-64 字符
     */
    @NotBlank(message = "新密码不能为空")
    @Size(min = 8, max = 64, message = "新密码长度8-64字符")
    @Schema(description = "新密码，长度8-64字符", example = "newPassword456")
    private String newPassword;

    /**
     * 确认新密码，必须与新密码一致
     */
    @NotBlank(message = "确认密码不能为空")
    @Schema(description = "确认新密码，需与新密码一致", example = "newPassword456")
    private String confirmPassword;
}
