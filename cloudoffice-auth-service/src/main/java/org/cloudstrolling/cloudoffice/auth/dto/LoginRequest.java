/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 登录请求 DTO。
 *
 * <p>包含用户登录所需的凭证信息：登录名、密码、租户编码和客户端类型。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class LoginRequest {

    /**
     * 登录名
     */
    @NotBlank(message = "登录名不能为空")
    private String loginName;

    /**
     * 密码
     */
    @NotBlank(message = "密码不能为空")
    private String password;

    /**
     * 租户编码
     */
    @NotBlank(message = "租户编码不能为空")
    private String tenantCode;

    /**
     * 客户端类型（WINDOWS|UBUNTU|H5|ANDROID|IOS|WECHAT_MINI）
     */
    @NotBlank(message = "客户端类型不能为空")
    private String clientType;
}
