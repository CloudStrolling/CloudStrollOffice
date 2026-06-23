/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 用户注册请求 DTO。
 *
 * <p>支持多种注册模式：用户名注册、手机号注册、邮箱注册、OAuth 第三方注册。
 * 不同模式下必填字段不同：</p>
 * <ul>
 *   <li><strong>USERNAME</strong> — loginName、password、userName 必填</li>
 *   <li><strong>PHONE</strong> — phone、smsCode、userName 必填</li>
 *   <li><strong>EMAIL</strong> — email、password、userName 必填</li>
 *   <li><strong>OAUTH</strong> — oauthProvider、oauthCode、userName 必填</li>
 * </ul>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "用户注册请求 DTO，支持用户名 / 手机 / 邮箱 / OAuth 四种模式")
public class RegisterRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 注册模式，不传时默认 USERNAME
     * <ul>
     *   <li>USERNAME — 用户名注册</li>
     *   <li>PHONE — 手机号注册</li>
     *   <li>EMAIL — 邮箱注册</li>
     *   <li>OAUTH — OAuth 第三方注册</li>
     * </ul>
     */
    @Schema(description = "注册模式", example = "USERNAME", allowableValues = {"USERNAME", "PHONE", "EMAIL", "OAUTH"})
    @Builder.Default
    private String registerMode = "USERNAME";

    /**
     * 登录名（USERNAME 模式必填，4-64 字符，仅允许字母、数字、下划线）
     */
    @Size(min = 4, max = 64, message = "登录名长度4-64字符")
    @Pattern(regexp = "^[a-zA-Z0-9_]+$", message = "登录名只能包含字母数字下划线")
    @Schema(description = "登录名，USERNAME 模式必填", example = "newuser")
    private String loginName;

    /**
     * 密码（USERNAME、EMAIL 模式必填，8-64 字符）
     */
    @Size(min = 8, max = 64, message = "密码长度8-64字符")
    @Schema(description = "密码，USERNAME 或 EMAIL 模式必填", example = "password123")
    private String password;

    /**
     * 用户姓名（所有模式必填）
     */
    @Size(max = 50, message = "用户姓名长度不能超过50字符")
    @Schema(description = "用户姓名，所有模式必填", example = "张三")
    private String userName;

    /**
     * 手机号（PHONE 模式必填）
     */
    @Schema(description = "手机号，PHONE 模式必填", example = "13800138000")
    private String phone;

    /**
     * 邮箱（EMAIL 模式必填）
     */
    @Schema(description = "邮箱，EMAIL 模式必填", example = "user@example.com")
    private String email;

    /**
     * 短信验证码（PHONE 模式必填）
     */
    @Schema(description = "短信验证码，PHONE 模式必填", example = "123456")
    private String smsCode;

    /**
     * OAuth 提供商（OAUTH 模式必填）
     */
    @Schema(description = "OAuth 第三方登录提供商，OAUTH 模式必填", example = "wechat")
    private String oauthProvider;

    /**
     * OAuth 授权码（OAUTH 模式必填）
     */
    @Schema(description = "OAuth 授权码，OAUTH 模式必填", example = "oauth_code_xxx")
    private String oauthCode;

    /**
     * 租户编码，所有模式必填（与 LoginRequest.tenantCode 一致）
     */
    @NotBlank(message = "租户编码不能为空")
    @Schema(description = "租户编码，所有模式下均必填", example = "default")
    private String tenantCode;
}
