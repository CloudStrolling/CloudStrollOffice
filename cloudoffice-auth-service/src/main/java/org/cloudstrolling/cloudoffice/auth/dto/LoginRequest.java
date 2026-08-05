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
 * 登录请求 DTO。
 *
 * <p>支持多种登录模式：用户名密码登录、手机验证码登录、OAuth 第三方登录。
 * 不同模式下必填字段不同：</p>
 * <ul>
 *   <li><strong>USERNAME_PASSWORD</strong> — loginName 和 password 必填</li>
 *   <li><strong>SMS</strong> — phone 和 smsCode 必填</li>
 *   <li><strong>OAUTH</strong> — oauthProvider 和 oauthCode 必填</li>
 * </ul>
 * <p>tenantCode 和 clientType 在所有模式下均为必填。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "登录请求 DTO，支持用户名密码 / 短信 / OAuth 三种模式")
public class LoginRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 登录模式，不传时默认 USERNAME_PASSWORD
     * <ul>
     *   <li>USERNAME_PASSWORD — 用户名密码登录</li>
     *   <li>SMS — 手机验证码登录</li>
     *   <li>OAUTH — OAuth 第三方登录</li>
     * </ul>
     */
    @Schema(description = "登录模式", example = "USERNAME_PASSWORD", allowableValues = {"USERNAME_PASSWORD", "SMS", "OAUTH"})
    @Builder.Default
    private String loginMode = "USERNAME_PASSWORD";

    /**
     * 登录名（USERNAME_PASSWORD 模式必填）
     */
    @Size(min = 4, max = 64, message = "登录名长度4-64字符")
    @Schema(description = "登录名，USERNAME_PASSWORD 模式必填", example = "admin")
    private String loginName;

    /**
     * 密码（USERNAME_PASSWORD 模式必填）
     */
    @Size(min = 8, max = 64, message = "密码长度8-64字符")
    @Schema(description = "密码，USERNAME_PASSWORD 模式必填", example = "password123")
    private String password;

    /**
     * 手机号（SMS 模式必填）
     */
    @Schema(description = "手机号，SMS 模式必填", example = "13800138000")
    private String phone;

    /**
     * 短信验证码（SMS 模式必填）
     */
    @Schema(description = "短信验证码，SMS 模式必填", example = "123456")
    private String smsCode;

    /**
     * OAuth 提供商（OAUTH 模式必填）
     */
    @Schema(description = "OAuth 第三方登录提供商", example = "wechat")
    private String oauthProvider;

    /**
     * OAuth 授权码（OAUTH 模式必填）
     */
    @Schema(description = "OAuth 授权码", example = "oauth_code_xxx")
    private String oauthCode;

    /**
     * 租户编码，所有模式必填
     */
    @NotBlank(message = "租户编码不能为空")
    @Schema(description = "租户编码，所有模式下均必填", example = "default")
    private String tenantCode;

    /**
     * 客户端类型（WINDOWS|UBUNTU|H5|ANDROID|IOS|WECHAT_MINI），所有模式必填
     */
    @NotBlank(message = "客户端类型不能为空")
    @Schema(description = "客户端类型", example = "WINDOWS", allowableValues = {"WINDOWS", "UBUNTU", "H5", "ANDROID", "IOS", "WECHAT_MINI"})
    private String clientType;
}
