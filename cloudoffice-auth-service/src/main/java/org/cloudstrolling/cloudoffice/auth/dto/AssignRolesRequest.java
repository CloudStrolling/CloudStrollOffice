/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

/**
 * 用户角色分配请求 DTO。
 *
 * <p>全量更新用户的角色分配。前端传入完整的角色 ID 列表，
 * 后端将用户现有角色替换为传入的新角色列表（先删后插）。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class AssignRolesRequest {

    /**
     * 角色 ID 列表
     */
    @NotNull(message = "角色ID列表不能为空")
    private List<Long> roleIds;
}
