/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto.result;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;

import java.io.Serializable;

/**
 * 注册结果 DTO。
 *
 * <p>用户注册成功后返回的信息，包含用户标识、
 * Token 对和账号结算状态。accountSettled 标识账号信息是否完整，
 * 前端可根据此字段决定是否跳转到信息补全页面。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "注册结果 DTO，包含用户信息和 Token 对")
public class RegisterResult implements Serializable {

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
     * 用户姓名
     */
    @Schema(description = "用户姓名", example = "张三")
    private String userName;

    /**
     * 账号结算状态（true=信息完整，false=需补全信息）
     */
    @Schema(description = "账号结算状态，true=信息完整，false=需补全信息", example = "true")
    private Boolean accountSettled;

    /**
     * Token 对（Access Token + Refresh Token）
     */
    @Schema(description = "Token 对")
    private TokenPairDTO tokenPair;
}
