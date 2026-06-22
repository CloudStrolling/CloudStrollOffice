/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import org.cloudstrolling.cloudoffice.common.model.BaseEntity;

/**
 * 角色-权限关联实体，对应 t_auth_role_permission 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_role_permission")
public class RolePermissionEntity extends BaseEntity {

    /**
     * 角色 ID
     */
    private Long roleId;

    /**
     * 权限 ID
     */
    private Long permId;
}
