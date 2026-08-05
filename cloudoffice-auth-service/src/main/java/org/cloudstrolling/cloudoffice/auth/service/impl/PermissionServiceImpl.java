/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.entity.PermissionEntity;
import org.cloudstrolling.cloudoffice.auth.entity.RolePermissionEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.PermissionMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.RolePermissionMapper;
import org.cloudstrolling.cloudoffice.auth.service.PermissionService;
import org.cloudstrolling.cloudoffice.auth.vo.PermissionVO;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

/**
 * 权限业务逻辑实现。
 *
 * <p>实现权限的树形查询、CRUD 操作及引用关系校验等业务逻辑。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PermissionServiceImpl implements PermissionService {

    private final PermissionMapper permissionMapper;
    private final RolePermissionMapper rolePermissionMapper;

    @Override
    public List<PermissionVO> tree() {
        // 查询所有未删除的权限
        List<PermissionEntity> allPermissions = permissionMapper.selectList(
                Wrappers.lambdaQuery(PermissionEntity.class)
                        .orderByAsc(PermissionEntity::getSortOrder));

        // 转换为 VO 列表
        List<PermissionVO> voList = allPermissions.stream()
                .map(this::convertToVO)
                .collect(Collectors.toList());

        // 按 parentId 分组
        Map<Long, List<PermissionVO>> parentIdMap = voList.stream()
                .collect(Collectors.groupingBy(
                        vo -> vo.getParentId() != null ? vo.getParentId() : 0L));

        // 为每个权限设置子权限列表
        for (PermissionVO vo : voList) {
            List<PermissionVO> children = parentIdMap.getOrDefault(vo.getId(), new ArrayList<>());
            vo.setChildren(children);
        }

        // 返回顶级权限（parentId 为 null 的权限）
        return voList.stream()
                .filter(vo -> vo.getParentId() == null)
                .collect(Collectors.toList());
    }

    @Override
    public PermissionEntity findById(Long permId) {
        return permissionMapper.selectById(permId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public PermissionEntity create(PermissionEntity permission) {
        Objects.requireNonNull(permission, "permission must not be null");
        Objects.requireNonNull(permission.getPermCode(), "permCode must not be null");

        // 校验 perm_code 全局唯一
        checkPermCodeUnique(null, permission.getPermCode());

        permissionMapper.insert(permission);
        log.info("权限创建成功 | permId={} | permCode={} | permName={}",
                permission.getId(), permission.getPermCode(), permission.getPermName());
        return permission;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public PermissionEntity update(PermissionEntity permission) {
        Objects.requireNonNull(permission, "permission must not be null");
        Objects.requireNonNull(permission.getId(), "permission id must not be null");

        // 校验权限存在
        PermissionEntity existing = permissionMapper.selectById(permission.getId());
        if (existing == null) {
            log.warn("更新失败：权限不存在 | permId={}", permission.getId());
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "权限不存在");
        }

        // 校验 perm_code 全局唯一（排除自身）
        if (permission.getPermCode() != null) {
            checkPermCodeUnique(permission.getId(), permission.getPermCode());
        }

        permissionMapper.updateById(permission);
        log.info("权限更新成功 | permId={} | permCode={} | permName={}",
                permission.getId(), permission.getPermCode(), permission.getPermName());
        return permissionMapper.selectById(permission.getId());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void delete(Long permId) {
        Objects.requireNonNull(permId, "permId must not be null");

        // 校验权限存在
        PermissionEntity existing = permissionMapper.selectById(permId);
        if (existing == null) {
            log.warn("删除失败：权限不存在 | permId={}", permId);
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "权限不存在");
        }

        // 检查是否被角色关联
        Long refCount = rolePermissionMapper.selectCount(
                Wrappers.lambdaQuery(RolePermissionEntity.class)
                        .eq(RolePermissionEntity::getPermId, permId));
        if (refCount != null && refCount > 0) {
            log.warn("删除失败：权限已被角色关联 | permId={} | refCount={}", permId, refCount);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "权限已被关联到角色，无法删除");
        }

        permissionMapper.deleteById(permId);
        log.info("权限删除成功 | permId={} | permCode={}", permId, existing.getPermCode());
    }

    @Override
    public List<PermissionEntity> listAll() {
        return permissionMapper.selectList(Wrappers.emptyWrapper());
    }

    /**
     * 校验权限编码在全局范围内唯一。
     *
     * @param excludePermId 排除的权限 ID（更新时排除自身），可为 null
     * @param permCode      权限编码
     * @throws BusinessException 权限编码已存在
     */
    private void checkPermCodeUnique(Long excludePermId, String permCode) {
        LambdaQueryWrapper<PermissionEntity> queryWrapper = Wrappers.lambdaQuery(PermissionEntity.class)
                .eq(PermissionEntity::getPermCode, permCode)
                .last("LIMIT 1");

        PermissionEntity existing = permissionMapper.selectOne(queryWrapper);
        if (existing != null && (excludePermId == null || !excludePermId.equals(existing.getId()))) {
            log.warn("权限编码已存在 | permCode={} | existingPermId={}", permCode, existing.getId());
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "权限编码已存在");
        }
    }

    /**
     * 将权限实体转换为视图对象。
     *
     * @param entity 权限实体
     * @return 权限视图对象
     */
    private PermissionVO convertToVO(PermissionEntity entity) {
        if (entity == null) {
            return null;
        }
        PermissionVO vo = new PermissionVO();
        vo.setId(entity.getId());
        vo.setPermName(entity.getPermName());
        vo.setPermCode(entity.getPermCode());
        vo.setPermType(entity.getPermType());
        vo.setParentId(entity.getParentId());
        vo.setPath(entity.getPath());
        vo.setComponent(entity.getComponent());
        vo.setIcon(entity.getIcon());
        vo.setSortOrder(entity.getSortOrder());
        vo.setStatus(entity.getStatus());
        return vo;
    }
}
