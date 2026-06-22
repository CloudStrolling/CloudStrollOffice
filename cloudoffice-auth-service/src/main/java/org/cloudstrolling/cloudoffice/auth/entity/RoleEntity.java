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
 * 角色实体，对应 t_auth_role 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_role")
public class RoleEntity extends BaseEntity {

    /**
     * 所属租户 ID
     */
    private Long tenantId;

    /**
     * 角色名称
     */
    private String roleName;

    /**
     * 角色编码
     */
    private String roleCode;

    /**
     * 角色描述
     */
    private String description;

    /**
     * 状态（0-正常，1-停用）
     */
    private Integer status;
}
