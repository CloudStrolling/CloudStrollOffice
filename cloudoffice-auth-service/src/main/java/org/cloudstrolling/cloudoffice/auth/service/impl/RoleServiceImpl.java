/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.RolePermissionEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserRoleEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.RolePermissionMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.auth.service.RoleService;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 角色业务逻辑实现。
 *
 * <p>实现角色的 CRUD 操作和权限分配功能，
 * 包含租户内角色编码唯一性校验、删除前引用检查等业务逻辑。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RoleServiceImpl implements RoleService {

    private final RoleMapper roleMapper;
    private final UserRoleMapper userRoleMapper;
    private final RolePermissionMapper rolePermissionMapper;

    @Override
    public PageResult<RoleEntity> list(Long tenantId, int page, int pageSize) {
        log.debug("分页查询角色列表 | tenantId={} | page={} | pageSize={}", tenantId, page, pageSize);

        Page<RoleEntity> pageParam = new Page<>(page, pageSize);
        LambdaQueryWrapper<RoleEntity> queryWrapper = Wrappers.lambdaQuery(RoleEntity.class)
                .eq(RoleEntity::getTenantId, tenantId)
                .orderByAsc(RoleEntity::getSortOrder);

        Page<RoleEntity> pageResult = roleMapper.selectPage(pageParam, queryWrapper);

        return PageResult.of(pageResult.getRecords(), pageResult.getTotal(), page, pageSize);
    }

    @Override
    public List<RoleEntity> listAll(Long tenantId) {
        log.debug("查询所有角色 | tenantId={}", tenantId);

        LambdaQueryWrapper<RoleEntity> queryWrapper = Wrappers.lambdaQuery(RoleEntity.class)
                .eq(RoleEntity::getTenantId, tenantId)
                .orderByAsc(RoleEntity::getSortOrder);

        return roleMapper.selectList(queryWrapper);
    }

    @Override
    public RoleEntity findById(Long roleId) {
        return roleMapper.selectById(roleId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public RoleEntity create(RoleEntity role) {
        Objects.requireNonNull(role.getTenantId(), "tenantId must not be null");
        Objects.requireNonNull(role.getRoleCode(), "roleCode must not be null");

        log.info("创建角色 | tenantId={} | roleCode={} | roleName={}",
                role.getTenantId(), role.getRoleCode(), role.getRoleName());

        // 校验角色编码在租户内唯一
        checkRoleCodeUnique(role.getTenantId(), role.getRoleCode(), null);

        // 设置默认值
        if (role.getStatus() == null) {
            role.setStatus(0);
        }

        roleMapper.insert(role);
        log.info("角色创建成功 | roleId={} | roleCode={}", role.getId(), role.getRoleCode());

        return role;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public RoleEntity update(RoleEntity role) {
        Objects.requireNonNull(role.getId(), "id must not be null");
        Objects.requireNonNull(role.getTenantId(), "tenantId must not be null");

        log.info("更新角色 | roleId={} | tenantId={} | roleCode={} | roleName={}",
                role.getId(), role.getTenantId(), role.getRoleCode(), role.getRoleName());

        // 验证角色存在
        RoleEntity existing = roleMapper.selectById(role.getId());
        if (existing == null) {
            log.warn("更新失败：角色不存在 | roleId={}", role.getId());
            throw new BusinessException(ErrorCode.ROLE_NOT_FOUND);
        }

        // 若编码有变更，校验唯一性
        if (role.getRoleCode() != null && !role.getRoleCode().equals(existing.getRoleCode())) {
            checkRoleCodeUnique(role.getTenantId(), role.getRoleCode(), role.getId());
        }

        roleMapper.updateById(role);
        log.info("角色更新成功 | roleId={}", role.getId());

        return roleMapper.selectById(role.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long roleId) {
        Objects.requireNonNull(roleId, "roleId must not be null");

        log.info("删除角色 | roleId={}", roleId);

        // 验证角色存在
        RoleEntity existing = roleMapper.selectById(roleId);
        if (existing == null) {
            log.warn("删除失败：角色不存在 | roleId={}", roleId);
            throw new BusinessException(ErrorCode.ROLE_NOT_FOUND);
        }

        // 检查角色是否被用户引用
        Long userCount = userRoleMapper.selectCount(
                Wrappers.lambdaQuery(UserRoleEntity.class)
                        .eq(UserRoleEntity::getRoleId, roleId));
        if (userCount != null && userCount > 0) {
            log.warn("删除失败：角色已被分配给用户 | roleId={} | userCount={}", roleId, userCount);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "角色已被分配给用户，无法删除");
        }

        roleMapper.deleteById(roleId);
        log.info("角色删除成功 | roleId={}", roleId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void assignPermissions(Long roleId, List<Long> permIds) {
        Objects.requireNonNull(roleId, "roleId must not be null");
        Objects.requireNonNull(permIds, "permIds must not be null");

        log.info("分配角色权限 | roleId={} | permCount={}", roleId, permIds.size());

        // 验证角色存在
        RoleEntity existing = roleMapper.selectById(roleId);
        if (existing == null) {
            log.warn("权限分配失败：角色不存在 | roleId={}", roleId);
            throw new BusinessException(ErrorCode.ROLE_NOT_FOUND);
        }

        // 全量更新：先删再插
        rolePermissionMapper.delete(
                Wrappers.lambdaQuery(RolePermissionEntity.class)
                        .eq(RolePermissionEntity::getRoleId, roleId));

        if (!permIds.isEmpty()) {
            List<RolePermissionEntity> rpList = permIds.stream()
                    .map(permId -> {
                        RolePermissionEntity rp = new RolePermissionEntity();
                        rp.setRoleId(roleId);
                        rp.setPermId(permId);
                        return rp;
                    })
                    .collect(Collectors.toList());

            rpList.forEach(rolePermissionMapper::insert);
        }

        log.info("角色权限分配完成 | roleId={} | permCount={}", roleId, permIds.size());
    }

    /**
     * 校验角色编码在租户内唯一。
     *
     * <p>排除指定 ID（用于更新场景，排除自身），
     * 若编码已存在则抛出业务异常。</p>
     *
     * @param tenantId 租户 ID
     * @param roleCode 角色编码
     * @param excludeId 排除的角色 ID（更新时传入，创建时传 null）
     * @throws BusinessException 角色编码已存在
     */
    private void checkRoleCodeUnique(Long tenantId, String roleCode, Long excludeId) {
        LambdaQueryWrapper<RoleEntity> queryWrapper = Wrappers.lambdaQuery(RoleEntity.class)
                .eq(RoleEntity::getTenantId, tenantId)
                .eq(RoleEntity::getRoleCode, roleCode);

        if (excludeId != null) {
            queryWrapper.ne(RoleEntity::getId, excludeId);
        }

        Long count = roleMapper.selectCount(queryWrapper);
        if (count != null && count > 0) {
            log.warn("角色编码已存在 | tenantId={} | roleCode={}", tenantId, roleCode);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "角色编码已存在");
        }
    }
}
