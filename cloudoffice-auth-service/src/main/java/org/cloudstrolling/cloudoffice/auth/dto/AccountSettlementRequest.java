/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * 账号结算（补全信息）请求 DTO。
 *
 * <p>用户在首次登录或信息不完整时，需要补全账号信息。
 * 该 DTO 用于将临时授权账号转为完整账号：</p>
 * <ul>
 *   <li>OAuth 首次登录后设置登录名和密码</li>
 *   <li>手机验证码登录后绑定登录名和密码</li>
 * </ul>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "账号结算（补全信息）请求 DTO")
public class AccountSettlementRequest implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 用户 ID
     */
    @Schema(description = "用户 ID", example = "1")
    private Long userId;

    /**
     * 登录名
     */
    @Schema(description = "登录名", example = "newuser")
    private String loginName;

    /**
     * 密码
     */
    @Schema(description = "密码", example = "password123")
    private String password;

    /**
     * 手机号
     */
    @Schema(description = "手机号", example = "13800138000")
    private String phone;

    /**
     * 短信验证码
     */
    @Schema(description = "短信验证码", example = "123456")
    private String smsCode;
}
