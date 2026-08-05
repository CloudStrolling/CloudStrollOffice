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
import java.util.ArrayList;
import java.util.List;

/**
 * 登录用户信息 DTO。
 *
 * <p>包含登录用户的基本信息、角色和权限标识，
 * 用于认证通过后在系统内传递用户上下文。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Accessors(chain = true)
public class LoginUserDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 用户ID */
    private Long userId;

    /** 租户ID */
    private Long tenantId;

    /** 用户名 */
    private String userName;

    /** 客户端类型编码 */
    private String clientType;

    /** 角色编码列表（默认空列表） */
    @Builder.Default
    private List<String> roles = new ArrayList<>();

    /** 权限标识列表（默认空列表） */
    @Builder.Default
    private List<String> permissions = new ArrayList<>();
}
