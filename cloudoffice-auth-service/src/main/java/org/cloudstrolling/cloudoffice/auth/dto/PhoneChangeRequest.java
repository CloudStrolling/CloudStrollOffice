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
 * 手机号更换请求 DTO。
 *
 * <p>用户更换手机号时需要验证新旧手机号。
 * 其中 oldPhoneCode 和 emailCode 为条件必填：</p>
 * <ul>
 *   <li><strong>oldPhoneCode</strong> — 当用户已绑定手机号时必填</li>
 *   <li><strong>emailCode</strong> — 当用户未绑定手机号时，需通过邮箱验证，此时必填</li>
 * </ul>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "手机号更换请求 DTO")
public class PhoneChangeRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 新手机号，不能为空
     */
    @NotBlank(message = "新手机号不能为空")
    @Schema(description = "新手机号", example = "13900139000")
    private String newPhone;

    /**
     * 旧手机号验证码（条件必填：已绑定手机号时必填）
     */
    @Schema(description = "旧手机号验证码，已绑定手机号时必填", example = "654321")
    private String oldPhoneCode;

    /**
     * 新手机号验证码，不能为空
     */
    @NotBlank(message = "新手机号验证码不能为空")
    @Schema(description = "新手机号验证码", example = "123456")
    private String newPhoneCode;

    /**
     * 邮箱验证码（条件必填：未绑定手机号、仅绑定邮箱时必填）
     */
    @Schema(description = "邮箱验证码，未绑定手机号时必填", example = "888888")
    private String emailCode;
}
