/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.experimental.Accessors;

import java.io.Serializable;

/**
 * 双 Token 响应 DTO。
 *
 * <p>包含 Access Token 和 Refresh Token 的响应数据传输对象，
 * 用于认证接口返回令牌信息。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Accessors(chain = true)
public class TokenPairDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** Access Token 字符串 */
    private String accessToken;

    /** Refresh Token 字符串 */
    private String refreshToken;

    /** Access Token 过期时间（秒） */
    private Long accessTokenExpireIn;

    /** Refresh Token 过期时间（秒） */
    private Long refreshTokenExpireIn;

    /** Token 类型，固定为 "Bearer" */
    private String tokenType;
}
