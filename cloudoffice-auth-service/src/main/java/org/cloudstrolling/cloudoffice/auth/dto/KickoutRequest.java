/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * 强制踢人请求 DTO。
 *
 * <p>管理员通过此请求体指定要踢下线的目标用户和客户端类型。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class KickoutRequest {

    /**
     * 目标用户 ID，不能为空。
     */
    @NotNull(message = "目标用户ID不能为空")
    private Long userId;

    /**
     * 客户端类型，可选。
     * <ul>
     *   <li>非空时：踢指定端的登录态</li>
     *   <li>为空时：踢所有端的登录态</li>
     * </ul>
     */
    private String clientType;
}
