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
 * 权限实体，对应 t_auth_permission 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_permission")
public class PermissionEntity extends BaseEntity {

    /**
     * 权限名称
     */
    private String permName;

    /**
     * 权限编码
     */
    private String permCode;

    /**
     * 权限类型（1-菜单，2-按钮，3-API）
     */
    private Integer permType;

    /**
     * 父权限 ID
     */
    private Long parentId;

    /**
     * 前端路由路径
     */
    private String path;

    /**
     * 前端组件路径
     */
    private String component;

    /**
     * 图标
     */
    private String icon;

    /**
     * 排序号
     */
    private Integer sortOrder;

    /**
     * 状态（0-正常，1-停用）
     */
    private Integer status;
}
