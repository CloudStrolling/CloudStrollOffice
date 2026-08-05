/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.vo;

import lombok.Data;

import java.util.ArrayList;
import java.util.List;

/**
 * 权限视图对象，用于树形结构展示。
 *
 * <p>包含权限的基本信息及子权限列表，通过 {@link #parentId} 自关联组织树形结构。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class PermissionVO {

    /**
     * 权限 ID
     */
    private Long id;

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

    /**
     * 子权限列表
     */
    private List<PermissionVO> children = new ArrayList<>();
}
