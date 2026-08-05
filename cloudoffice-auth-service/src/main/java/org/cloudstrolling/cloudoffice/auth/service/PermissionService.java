/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.auth.entity.PermissionEntity;
import org.cloudstrolling.cloudoffice.auth.vo.PermissionVO;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;

import java.util.List;

/**
 * 权限业务逻辑接口。
 *
 * <p>提供权限的树形查询、CRUD 操作及引用关系校验等核心业务方法。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface PermissionService {

    /**
     * 查询树形权限列表。
     *
     * <p>查询所有权限，按 {@code parentId} 自关联组织成树形结构，
     * 每个父权限包含 {@link PermissionVO#children} 子权限列表。</p>
     *
     * @return 树形结构的权限列表（仅包含顶级权限，子权限嵌套在 children 中）
     */
    List<PermissionVO> tree();

    /**
     * 根据权限 ID 查询权限详情。
     *
     * @param permId 权限 ID
     * @return 权限实体，不存在时返回 null
     */
    PermissionEntity findById(Long permId);

    /**
     * 创建权限。
     *
     * <p>创建前校验 {@code permCode} 在全局范围内唯一。</p>
     *
     * @param permission 权限实体
     * @return 创建成功的权限实体（含自动生成的 ID）
     * @throws BusinessException 权限编码已存在
     */
    PermissionEntity create(PermissionEntity permission);

    /**
     * 更新权限。
     *
     * <p>更新前校验 {@code permCode} 在全局范围内唯一（排除自身）。</p>
     *
     * @param permission 权限实体（需包含 ID）
     * @return 更新后的权限实体
     * @throws BusinessException 权限不存在或权限编码已存在
     */
    PermissionEntity update(PermissionEntity permission);

    /**
     * 删除权限。
     *
     * <p>逻辑删除权限。删除前检查 {@link org.cloudstrolling.cloudoffice.auth.mapper.RolePermissionMapper}
     * 中是否存在引用关系，若被角色关联则阻止删除。</p>
     *
     * @param permId 权限 ID
     * @throws BusinessException 权限不存在或权限已被角色关联
     */
    void delete(Long permId);

    /**
     * 查询所有权限。
     *
     * @return 所有权限实体列表
     */
    List<PermissionEntity> listAll();
}
