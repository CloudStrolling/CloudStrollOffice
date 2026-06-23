/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 用户注册请求 DTO。
 *
 * <p>包含注册所需的全部参数，使用 Jakarta Validation 注解进行参数校验。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class RegisterRequest {

    /**
     * 登录名（4-64 字符，仅允许字母、数字、下划线）
     */
    @NotBlank(message = "登录名不能为空")
    @Size(min = 4, max = 64, message = "登录名长度4-64字符")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "登录名只能包含字母数字下划线")
    private String loginName;

    /**
     * 密码（8-64 字符）
     */
    @NotBlank(message = "密码不能为空")
    @Size(min = 8, max = 64, message = "密码长度8-64字符")
    private String password;

    /**
     * 用户姓名
     */
    @NotBlank(message = "用户姓名不能为空")
    @Size(max = 50, message = "用户姓名长度不能超过50字符")
    private String userName;

    /**
     * 手机号
     */
    private String phone;

    /**
     * 邮箱
     */
    private String email;

    /**
     * 租户 ID
     */
    private Long tenantId;
}
