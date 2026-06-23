/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Token 刷新请求 DTO。
 *
 * <p>包含 Refresh Token 字符串，用于申请新的双 Token 对。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class RefreshTokenRequest {

    /**
     * Refresh Token 字符串，不能为空。
     */
    @NotBlank(message = "refreshToken 不能为空")
    private String refreshToken;
}
