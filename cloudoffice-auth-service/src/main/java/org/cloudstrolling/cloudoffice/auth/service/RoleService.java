/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.model.PageResult;

import java.util.List;

/**
 * 角色业务逻辑接口。
 *
 * <p>提供角色的分页查询、全量列表、详情查询、创建、更新、删除
 * 以及权限分配等核心业务方法。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface RoleService {

    /**
     * 分页查询角色列表。
     *
     * @param tenantId 租户 ID
     * @param page     页码（从 1 开始）
     * @param pageSize 每页大小
     * @return 分页结果
     */
    PageResult<RoleEntity> list(Long tenantId, int page, int pageSize);

    /**
     * 查询租户内所有角色列表（不分页）。
     *
     * @param tenantId 租户 ID
     * @return 角色列表
     */
    List<RoleEntity> listAll(Long tenantId);

    /**
     * 根据角色 ID 查询角色详情。
     *
     * @param roleId 角色 ID
     * @return 角色实体，不存在返回 null
     */
    RoleEntity findById(Long roleId);

    /**
     * 创建角色。
     *
     * <p>创建时校验角色编码在租户内唯一。</p>
     *
     * @param role 角色实体（需包含 tenantId、roleName、roleCode）
     * @return 创建后的角色实体（含自动生成的 ID）
     * @throws BusinessException 角色编码已存在
     */
    RoleEntity create(RoleEntity role);

    /**
     * 更新角色。
     *
     * <p>更新时校验角色编码在租户内不与其他角色冲突。</p>
     *
     * @param role 角色实体（需包含 id、tenantId、roleName、roleCode）
     * @return 更新后的角色实体
     * @throws BusinessException 角色不存在或角色编码与其他角色冲突
     */
    RoleEntity update(RoleEntity role);

    /**
     * 逻辑删除角色。
     *
     * <p>若角色已被分配给用户，则阻止删除并抛出业务异常。</p>
     *
     * @param roleId 角色 ID
     * @throws BusinessException 角色已被分配给用户
     */
    void delete(Long roleId);

    /**
     * 分配角色权限（全量更新）。
     *
     * <p>先删除当前角色的所有权限关联，再批量插入新的权限关联。</p>
     *
     * @param roleId  角色 ID
     * @param permIds 权限 ID 列表
     * @throws BusinessException 角色不存在
     */
    void assignPermissions(Long roleId, List<Long> permIds);
}
