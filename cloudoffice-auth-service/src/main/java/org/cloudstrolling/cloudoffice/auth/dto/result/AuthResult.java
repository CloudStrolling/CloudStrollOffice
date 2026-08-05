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

import java.io.Serializable;
import java.util.List;

/**
 * 认证结果 DTO。
 *
 * <p>登录认证成功后返回的用户基本信息，包含用户标识、
 * 租户信息、角色和权限列表。前端可根据此信息进行页面路由和功能权限控制。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Schema(description = "认证结果 DTO，包含用户基本信息、角色和权限")
public class AuthResult implements Serializable {

    private static final long serialVersionUID = 1L;

    /**
     * 用户 ID
     */
    @Schema(description = "用户 ID", example = "1")
    private Long userId;

    /**
     * 租户 ID
     */
    @Schema(description = "租户 ID", example = "1")
    private Long tenantId;

    /**
     * 登录名
     */
    @Schema(description = "登录名", example = "admin")
    private String loginName;

    /**
     * 用户姓名
     */
    @Schema(description = "用户姓名", example = "张三")
    private String userName;

    /**
     * 手机号
     */
    @Schema(description = "手机号", example = "13800138000")
    private String phone;

    /**
     * 角色列表
     */
    @Schema(description = "角色列表", example = "[\"admin\", \"user\"]")
    private List<String> roles;

    /**
     * 权限列表
     */
    @Schema(description = "权限列表", example = "[\"user:create\", \"user:delete\"]")
    private List<String> permissions;
}
