/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.service.RoleService;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.exception.GlobalExceptionHandler;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Arrays;
import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * {@link RoleController} 的 MockMvc 单元测试。
 *
 * <p>使用 Mockito + 独立 MockMvc 配置测试角色管理 API 的所有端点，
 * 验证 CRUD 操作、权限分配、角色编码唯一性校验和被关联时阻止删除等场景。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("RoleController 测试")
@ExtendWith(MockitoExtension.class)
class RoleControllerTest {

    private MockMvc mockMvc;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private RoleService roleService;

    @InjectMocks
    private RoleController roleController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(roleController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .defaultRequest(get("/").contentType(MediaType.APPLICATION_JSON))
                .build();
    }

    // ========== GET /api/v1/auth/roles - 分页查询 ==========

    @Test
    @DisplayName("GET /api/v1/auth/roles -> 200 + 分页数据")
    void list_shouldReturnPageResult() throws Exception {
        // Given
        RoleEntity role = new RoleEntity();
        role.setId(1L);
        role.setTenantId(1L);
        role.setRoleCode("admin");
        role.setRoleName("管理员");

        PageResult<RoleEntity> pageResult = PageResult.of(List.of(role), 1L, 1, 10);
        when(roleService.list(anyLong(), anyInt(), anyInt())).thenReturn(pageResult);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/roles")
                        .param("tenantId", "1")
                        .param("page", "1")
                        .param("pageSize", "10")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.records[0].roleCode").value("admin"))
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.pageSize").value(10));
    }

    // ========== GET /api/v1/auth/roles/list - 所有角色 ==========

    @Test
    @DisplayName("GET /api/v1/auth/roles/list -> 200 + 角色列表")
    void listAll_shouldReturnRoleList() throws Exception {
        // Given
        RoleEntity role1 = new RoleEntity();
        role1.setId(1L);
        role1.setTenantId(1L);
        role1.setRoleCode("admin");
        role1.setRoleName("管理员");

        RoleEntity role2 = new RoleEntity();
        role2.setId(2L);
        role2.setTenantId(1L);
        role2.setRoleCode("user");
        role2.setRoleName("普通用户");

        when(roleService.listAll(anyLong())).thenReturn(Arrays.asList(role1, role2));

        // When & Then
        mockMvc.perform(get("/api/v1/auth/roles/list")
                        .param("tenantId", "1")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data[0].roleCode").value("admin"))
                .andExpect(jsonPath("$.data[1].roleCode").value("user"));
    }

    // ========== GET /api/v1/auth/roles/{id} - 角色详情 ==========

    @Test
    @DisplayName("GET /api/v1/auth/roles/{id} -> 200 + 角色详情")
    void findById_shouldReturnRole() throws Exception {
        // Given
        RoleEntity role = new RoleEntity();
        role.setId(1L);
        role.setTenantId(1L);
        role.setRoleCode("admin");
        role.setRoleName("管理员");

        when(roleService.findById(1L)).thenReturn(role);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/roles/1")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.roleCode").value("admin"))
                .andExpect(jsonPath("$.data.roleName").value("管理员"));
    }

    // ========== POST /api/v1/auth/roles - 创建角色 ==========

    @Test
    @DisplayName("POST /api/v1/auth/roles -> 200 + 创建成功")
    void create_shouldReturnCreatedRole() throws Exception {
        // Given
        RoleEntity requestRole = new RoleEntity();
        requestRole.setTenantId(1L);
        requestRole.setRoleCode("editor");
        requestRole.setRoleName("编辑者");

        RoleEntity createdRole = new RoleEntity();
        createdRole.setId(100L);
        createdRole.setTenantId(1L);
        createdRole.setRoleCode("editor");
        createdRole.setRoleName("编辑者");

        when(roleService.create(any(RoleEntity.class))).thenReturn(createdRole);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/roles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestRole)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").value(100))
                .andExpect(jsonPath("$.data.roleCode").value("editor"));
    }

    // ========== PUT /api/v1/auth/roles/{id} - 更新角色 ==========

    @Test
    @DisplayName("PUT /api/v1/auth/roles/{id} -> 200 + 更新成功")
    void update_shouldReturnUpdatedRole() throws Exception {
        // Given
        RoleEntity updateRole = new RoleEntity();
        updateRole.setTenantId(1L);
        updateRole.setRoleCode("admin");
        updateRole.setRoleName("超级管理员");

        RoleEntity updatedRole = new RoleEntity();
        updatedRole.setId(1L);
        updatedRole.setTenantId(1L);
        updatedRole.setRoleCode("admin");
        updatedRole.setRoleName("超级管理员");

        when(roleService.update(any(RoleEntity.class))).thenReturn(updatedRole);

        // When & Then
        mockMvc.perform(put("/api/v1/auth/roles/1")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateRole)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.roleName").value("超级管理员"));
    }

    // ========== DELETE /api/v1/auth/roles/{id} - 删除角色 ==========

    @Test
    @DisplayName("DELETE /api/v1/auth/roles/{id} -> 200 + 删除成功")
    void delete_shouldReturnSuccess() throws Exception {
        // Given
        doNothing().when(roleService).delete(1L);

        // When & Then
        mockMvc.perform(delete("/api/v1/auth/roles/1")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("操作成功"));
    }

    // ========== PUT /api/v1/auth/roles/{id}/permissions - 分配权限 ==========

    @Test
    @DisplayName("PUT /api/v1/auth/roles/{id}/permissions -> 200 + 分配成功")
    void assignPermissions_shouldReturnSuccess() throws Exception {
        // Given
        Map<String, List<Long>> request = Map.of("permissionIds", Arrays.asList(10L, 20L, 30L));
        doNothing().when(roleService).assignPermissions(eq(1L), anyList());

        // When & Then
        mockMvc.perform(put("/api/v1/auth/roles/1/permissions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("操作成功"));
    }

    // ========== 边界情况测试 ==========

    @Test
    @DisplayName("POST /api/v1/auth/roles -> 角色编码重复时返回 400")
    void create_shouldReturn400_whenRoleCodeDuplicate() throws Exception {
        // Given
        RoleEntity requestRole = new RoleEntity();
        requestRole.setTenantId(1L);
        requestRole.setRoleCode("admin");
        requestRole.setRoleName("管理员");

        when(roleService.create(any(RoleEntity.class)))
                .thenThrow(new BusinessException(400, "角色编码已存在"));

        // When & Then
        mockMvc.perform(post("/api/v1/auth/roles")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestRole)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("角色编码已存在"));
    }

    @Test
    @DisplayName("DELETE /api/v1/auth/roles/{id} -> 角色被引用时返回 400")
    void delete_shouldReturn400_whenRoleReferenced() throws Exception {
        // Given
        doThrow(new BusinessException(400, "角色已被分配给用户，无法删除"))
                .when(roleService).delete(1L);

        // When & Then
        mockMvc.perform(delete("/api/v1/auth/roles/1")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("角色已被分配给用户，无法删除"));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/roles/{id}/permissions -> 角色不存在返回 404")
    void assignPermissions_shouldReturn404_whenRoleNotFound() throws Exception {
        // Given
        Map<String, List<Long>> request = Map.of("permissionIds", List.of(1L));

        doThrow(new BusinessException(ErrorCode.ROLE_NOT_FOUND))
                .when(roleService).assignPermissions(eq(999L), anyList());

        // When & Then
        mockMvc.perform(put("/api/v1/auth/roles/999/permissions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("角色不存在"));
    }
}
