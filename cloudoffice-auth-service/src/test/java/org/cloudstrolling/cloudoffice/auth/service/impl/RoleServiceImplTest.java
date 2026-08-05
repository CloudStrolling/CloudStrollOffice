/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.RolePermissionEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserRoleEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.RolePermissionMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.auth.service.RoleService;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link RoleServiceImpl} 的单元测试。
 *
 * <p>使用 Mockito 模拟 Mapper 层，验证角色管理的业务逻辑，
 * 包括 CRUD 操作、编码唯一性校验、删除前引用检查和权限分配。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("RoleServiceImpl 单元测试")
class RoleServiceImplTest {

    @Mock
    private RoleMapper roleMapper;

    @Mock
    private UserRoleMapper userRoleMapper;

    @Mock
    private RolePermissionMapper rolePermissionMapper;

    @Captor
    private ArgumentCaptor<RoleEntity> roleCaptor;

    @Captor
    private ArgumentCaptor<RolePermissionEntity> rolePermissionCaptor;

    private RoleService roleService;

    @BeforeEach
    void setUp() {
        roleService = new RoleServiceImpl(roleMapper, userRoleMapper, rolePermissionMapper);
    }

    // ========== 分页查询 ==========

    @Test
    @DisplayName("分页查询角色：返回分页结果")
    void list_shouldReturnPageResult() {
        // Given
        Long tenantId = 1L;
        int page = 1;
        int pageSize = 10;

        RoleEntity role = new RoleEntity();
        role.setId(1L);
        role.setTenantId(tenantId);
        role.setRoleCode("admin");
        role.setRoleName("管理员");

        Page<RoleEntity> mockPage = new Page<>(page, pageSize);
        mockPage.setRecords(List.of(role));
        mockPage.setTotal(1);

        when(roleMapper.selectPage(any(Page.class), any(LambdaQueryWrapper.class)))
                .thenReturn(mockPage);

        // When
        PageResult<RoleEntity> result = roleService.list(tenantId, page, pageSize);

        // Then
        assertNotNull(result);
        assertEquals(1, result.getRecords().size());
        assertEquals(1L, result.getTotal());
        assertEquals(page, result.getPage());
        assertEquals(pageSize, result.getPageSize());
        assertEquals("admin", result.getRecords().get(0).getRoleCode());
    }

    // ========== 全量列表 ==========

    @Test
    @DisplayName("查询所有角色：返回租户内所有角色")
    void listAll_shouldReturnAllRoles() {
        // Given
        Long tenantId = 1L;

        RoleEntity role1 = new RoleEntity();
        role1.setId(1L);
        role1.setTenantId(tenantId);
        role1.setRoleCode("admin");

        RoleEntity role2 = new RoleEntity();
        role2.setId(2L);
        role2.setTenantId(tenantId);
        role2.setRoleCode("user");

        when(roleMapper.selectList(any(LambdaQueryWrapper.class)))
                .thenReturn(Arrays.asList(role1, role2));

        // When
        List<RoleEntity> roles = roleService.listAll(tenantId);

        // Then
        assertNotNull(roles);
        assertEquals(2, roles.size());
        assertEquals("admin", roles.get(0).getRoleCode());
        assertEquals("user", roles.get(1).getRoleCode());
    }

    // ========== 详情查询 ==========

    @Test
    @DisplayName("查询角色详情：角色存在返回角色信息")
    void findById_shouldReturnRole_whenExists() {
        // Given
        Long roleId = 1L;
        RoleEntity role = new RoleEntity();
        role.setId(roleId);
        role.setRoleCode("admin");
        role.setRoleName("管理员");

        when(roleMapper.selectById(roleId)).thenReturn(role);

        // When
        RoleEntity result = roleService.findById(roleId);

        // Then
        assertNotNull(result);
        assertEquals(roleId, result.getId());
        assertEquals("admin", result.getRoleCode());
    }

    @Test
    @DisplayName("查询角色详情：角色不存在返回 null")
    void findById_shouldReturnNull_whenNotExists() {
        // Given
        Long roleId = 999L;
        when(roleMapper.selectById(roleId)).thenReturn(null);

        // When
        RoleEntity result = roleService.findById(roleId);

        // Then
        assertNull(result);
    }

    // ========== 创建角色 ==========

    @Test
    @DisplayName("创建角色成功：返回创建后的角色信息")
    void create_shouldSucceed_whenRoleCodeUnique() {
        // Given
        Long tenantId = 1L;
        RoleEntity role = new RoleEntity();
        role.setTenantId(tenantId);
        role.setRoleCode("editor");
        role.setRoleName("编辑者");

        when(roleMapper.selectCount(any(LambdaQueryWrapper.class))).thenReturn(0L);

        // When
        RoleEntity result = roleService.create(role);

        // Then
        verify(roleMapper).insert(roleCaptor.capture());
        RoleEntity captured = roleCaptor.getValue();
        assertEquals(tenantId, captured.getTenantId());
        assertEquals("editor", captured.getRoleCode());
        assertEquals(0, captured.getStatus().intValue());
        assertNotNull(result);
    }

    @Test
    @DisplayName("创建角色失败：角色编码已存在抛出 BusinessException")
    void create_shouldThrow_whenRoleCodeDuplicate() {
        // Given
        Long tenantId = 1L;
        RoleEntity role = new RoleEntity();
        role.setTenantId(tenantId);
        role.setRoleCode("admin");
        role.setRoleName("管理员");

        when(roleMapper.selectCount(any(LambdaQueryWrapper.class))).thenReturn(1L);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> roleService.create(role));
        assertEquals(400, exception.getCode());
        assertEquals("角色编码已存在", exception.getMessage());

        verify(roleMapper, never()).insert(any(RoleEntity.class));
    }

    // ========== 更新角色 ==========

    @Test
    @DisplayName("更新角色成功：角色编码未变更时直接更新")
    void update_shouldSucceed_whenRoleCodeUnchanged() {
        // Given
        RoleEntity existing = new RoleEntity();
        existing.setId(1L);
        existing.setTenantId(1L);
        existing.setRoleCode("admin");
        existing.setRoleName("管理员");

        RoleEntity updateRole = new RoleEntity();
        updateRole.setId(1L);
        updateRole.setTenantId(1L);
        updateRole.setRoleCode("admin"); // 编码未变
        updateRole.setRoleName("超级管理员");

        when(roleMapper.selectById(1L)).thenReturn(existing);
        when(roleMapper.selectById(1L)).thenReturn(updateRole); // for return value

        // When
        RoleEntity result = roleService.update(updateRole);

        // Then
        verify(roleMapper).updateById(updateRole);
        // 编码相同，不应校验唯一性
        verify(roleMapper, never()).selectCount(any(LambdaQueryWrapper.class));
    }

    @Test
    @DisplayName("更新角色成功：角色编码变更且唯一时更新")
    void update_shouldSucceed_whenRoleCodeChangedAndUnique() {
        // Given
        RoleEntity existing = new RoleEntity();
        existing.setId(1L);
        existing.setTenantId(1L);
        existing.setRoleCode("admin");

        RoleEntity updateRole = new RoleEntity();
        updateRole.setId(1L);
        updateRole.setTenantId(1L);
        updateRole.setRoleCode("super_admin"); // 编码变更
        updateRole.setRoleName("超级管理员");

        when(roleMapper.selectById(1L)).thenReturn(existing, updateRole);
        when(roleMapper.selectCount(any(LambdaQueryWrapper.class))).thenReturn(0L);

        // When
        RoleEntity result = roleService.update(updateRole);

        // Then
        verify(roleMapper).updateById(updateRole);
        assertEquals("super_admin", result.getRoleCode());
    }

    @Test
    @DisplayName("更新角色失败：角色不存在抛出 ROLE_NOT_FOUND")
    void update_shouldThrow_whenRoleNotFound() {
        // Given
        RoleEntity role = new RoleEntity();
        role.setId(999L);
        role.setTenantId(1L);
        role.setRoleCode("admin");

        when(roleMapper.selectById(999L)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> roleService.update(role));
        assertEquals(404, exception.getCode());
        assertEquals("角色不存在", exception.getMessage());

        verify(roleMapper, never()).updateById(any());
    }

    @Test
    @DisplayName("更新角色失败：角色编码与其他角色冲突抛出 BusinessException")
    void update_shouldThrow_whenRoleCodeConflicts() {
        // Given
        RoleEntity existing = new RoleEntity();
        existing.setId(1L);
        existing.setTenantId(1L);
        existing.setRoleCode("admin");

        RoleEntity updateRole = new RoleEntity();
        updateRole.setId(1L);
        updateRole.setTenantId(1L);
        updateRole.setRoleCode("super_admin");

        when(roleMapper.selectById(1L)).thenReturn(existing);
        when(roleMapper.selectCount(any(LambdaQueryWrapper.class))).thenReturn(1L);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> roleService.update(updateRole));
        assertEquals(400, exception.getCode());
        assertEquals("角色编码已存在", exception.getMessage());

        verify(roleMapper, never()).updateById(any());
    }

    // ========== 删除角色 ==========

    @Test
    @DisplayName("删除角色成功：角色未被引用时逻辑删除")
    void delete_shouldSucceed_whenNotReferenced() {
        // Given
        Long roleId = 1L;
        RoleEntity role = new RoleEntity();
        role.setId(roleId);
        role.setRoleCode("editor");

        when(roleMapper.selectById(roleId)).thenReturn(role);
        when(userRoleMapper.selectCount(any(LambdaQueryWrapper.class))).thenReturn(0L);

        // When
        roleService.delete(roleId);

        // Then
        verify(roleMapper).deleteById(roleId);
    }

    @Test
    @DisplayName("删除角色失败：角色已被用户引用抛出 BusinessException")
    void delete_shouldThrow_whenRoleReferenced() {
        // Given
        Long roleId = 1L;
        RoleEntity role = new RoleEntity();
        role.setId(roleId);
        role.setRoleCode("admin");

        when(roleMapper.selectById(roleId)).thenReturn(role);
        when(userRoleMapper.selectCount(any(LambdaQueryWrapper.class))).thenReturn(3L);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> roleService.delete(roleId));
        assertEquals(400, exception.getCode());
        assertEquals("角色已被分配给用户，无法删除", exception.getMessage());

        verify(roleMapper, never()).deleteById((java.io.Serializable) any());
    }

    @Test
    @DisplayName("删除角色失败：角色不存在抛出 ROLE_NOT_FOUND")
    void delete_shouldThrow_whenRoleNotFound() {
        // Given
        Long roleId = 999L;
        when(roleMapper.selectById(roleId)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> roleService.delete(roleId));
        assertEquals(404, exception.getCode());
        assertEquals("角色不存在", exception.getMessage());

        verify(userRoleMapper, never()).selectCount(any());
        verify(roleMapper, never()).deleteById((java.io.Serializable) any());
    }

    // ========== 权限分配 ==========

    @Test
    @DisplayName("分配权限成功：先删后插全量更新")
    void assignPermissions_shouldSucceed_whenRoleExists() {
        // Given
        Long roleId = 1L;
        List<Long> permIds = Arrays.asList(10L, 20L, 30L);

        RoleEntity role = new RoleEntity();
        role.setId(roleId);
        role.setRoleCode("admin");

        when(roleMapper.selectById(roleId)).thenReturn(role);

        // When
        roleService.assignPermissions(roleId, permIds);

        // Then
        // 验证先删除
        verify(rolePermissionMapper).delete(any(LambdaQueryWrapper.class));
        // 验证插入 3 条
        verify(rolePermissionMapper, times(3)).insert(any(RolePermissionEntity.class));
    }

    @Test
    @DisplayName("分配权限成功：空权限列表时只删除不插入")
    void assignPermissions_shouldDeleteOnly_whenPermIdsEmpty() {
        // Given
        Long roleId = 1L;
        List<Long> permIds = List.of();

        RoleEntity role = new RoleEntity();
        role.setId(roleId);
        role.setRoleCode("editor");

        when(roleMapper.selectById(roleId)).thenReturn(role);

        // When
        roleService.assignPermissions(roleId, permIds);

        // Then
        verify(rolePermissionMapper).delete(any(LambdaQueryWrapper.class));
        verify(rolePermissionMapper, never()).insert(any(RolePermissionEntity.class));
    }

    @Test
    @DisplayName("分配权限失败：角色不存在抛出 ROLE_NOT_FOUND")
    void assignPermissions_shouldThrow_whenRoleNotFound() {
        // Given
        Long roleId = 999L;
        List<Long> permIds = List.of(1L, 2L);

        when(roleMapper.selectById(roleId)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> roleService.assignPermissions(roleId, permIds));
        assertEquals(404, exception.getCode());
        assertEquals("角色不存在", exception.getMessage());

        verify(rolePermissionMapper, never()).delete(any());
        verify(rolePermissionMapper, never()).insert(any());
    }
}
