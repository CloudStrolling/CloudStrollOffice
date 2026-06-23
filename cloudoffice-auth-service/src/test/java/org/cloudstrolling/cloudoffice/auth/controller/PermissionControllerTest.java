/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.cloudstrolling.cloudoffice.auth.entity.PermissionEntity;
import org.cloudstrolling.cloudoffice.auth.service.PermissionService;
import org.cloudstrolling.cloudoffice.auth.vo.PermissionVO;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Arrays;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * 权限管理控制器测试。
 *
 * <p>使用 Mockito + 独立 MockMvc 配置测试权限管理 API 的所有端点，
 * 验证 CRUD 操作、树形结构、唯一性校验和被关联时阻止删除等场景。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("PermissionController 测试")
@ExtendWith(MockitoExtension.class)
class PermissionControllerTest {

    private MockMvc mockMvc;

    @Mock
    private PermissionService permissionService;

    private ObjectMapper objectMapper;

    private PermissionEntity parentPerm;
    private PermissionEntity childPerm;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        PermissionController controller = new PermissionController(permissionService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();

        parentPerm = new PermissionEntity();
        parentPerm.setId(1L);
        parentPerm.setPermName("用户管理");
        parentPerm.setPermCode("user:manage");
        parentPerm.setPermType(1);
        parentPerm.setParentId(null);
        parentPerm.setPath("/user");
        parentPerm.setIcon("user");
        parentPerm.setSortOrder(1);
        parentPerm.setStatus(0);

        childPerm = new PermissionEntity();
        childPerm.setId(2L);
        childPerm.setPermName("用户列表");
        childPerm.setPermCode("user:list");
        childPerm.setPermType(2);
        childPerm.setParentId(1L);
        childPerm.setPath("/user/list");
        childPerm.setSortOrder(1);
        childPerm.setStatus(0);
    }

    @Test
    @DisplayName("GET /api/v1/auth/permissions/tree -> 200 + 树形结构")
    void tree_shouldReturnTreeStructure_whenPermissionsExist() throws Exception {
        // Given: 准备树形数据
        PermissionVO parentVO = new PermissionVO();
        parentVO.setId(1L);
        parentVO.setPermName("用户管理");
        parentVO.setPermCode("user:manage");
        parentVO.setPermType(1);
        parentVO.setParentId(null);
        parentVO.setPath("/user");
        parentVO.setIcon("user");
        parentVO.setSortOrder(1);
        parentVO.setStatus(0);

        PermissionVO childVO = new PermissionVO();
        childVO.setId(2L);
        childVO.setPermName("用户列表");
        childVO.setPermCode("user:list");
        childVO.setPermType(2);
        childVO.setParentId(1L);
        childVO.setPath("/user/list");
        childVO.setSortOrder(1);
        childVO.setStatus(0);

        parentVO.setChildren(Arrays.asList(childVO));

        when(permissionService.tree()).thenReturn(Arrays.asList(parentVO));

        // When & Then
        mockMvc.perform(get("/api/v1/auth/permissions/tree")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data[0].id").value(1))
                .andExpect(jsonPath("$.data[0].permName").value("用户管理"))
                .andExpect(jsonPath("$.data[0].children").isArray())
                .andExpect(jsonPath("$.data[0].children[0].id").value(2))
                .andExpect(jsonPath("$.data[0].children[0].permName").value("用户列表"));
    }

    @Test
    @DisplayName("GET /api/v1/auth/permissions/list -> 200 + 权限列表")
    void list_shouldReturnAllPermissions_whenCalled() throws Exception {
        // Given
        when(permissionService.listAll()).thenReturn(Arrays.asList(parentPerm, childPerm));

        // When & Then
        mockMvc.perform(get("/api/v1/auth/permissions/list")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data").isArray())
                .andExpect(jsonPath("$.data.length()").value(2));
    }

    @Test
    @DisplayName("GET /api/v1/auth/permissions/{id} -> 200 + 权限详情")
    void getById_shouldReturnPermission_whenPermissionExists() throws Exception {
        // Given
        when(permissionService.findById(1L)).thenReturn(parentPerm);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/permissions/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.permName").value("用户管理"))
                .andExpect(jsonPath("$.data.permCode").value("user:manage"));
    }

    @Test
    @DisplayName("GET /api/v1/auth/permissions/{id} -> 404 + 错误响应")
    void getById_shouldReturn404_whenPermissionNotFound() throws Exception {
        // Given
        when(permissionService.findById(999L)).thenReturn(null);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/permissions/{id}", 999L)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("权限不存在"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/permissions -> 201 + 创建成功")
    void create_shouldReturnCreatedPermission_whenValidRequest() throws Exception {
        // Given
        PermissionEntity created = new PermissionEntity();
        created.setId(10L);
        created.setPermName("新增权限");
        created.setPermCode("new:perm");
        created.setPermType(2);
        created.setParentId(1L);
        created.setSortOrder(1);
        created.setStatus(0);

        when(permissionService.create(any(PermissionEntity.class))).thenReturn(created);

        String requestBody = objectMapper.writeValueAsString(created);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/permissions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").value(10))
                .andExpect(jsonPath("$.data.permCode").value("new:perm"));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/permissions/{id} -> 200 + 更新成功")
    void update_shouldReturnUpdatedPermission_whenValidRequest() throws Exception {
        // Given
        PermissionEntity updated = new PermissionEntity();
        updated.setId(1L);
        updated.setPermName("用户管理(已更新)");
        updated.setPermCode("user:manage");
        updated.setStatus(0);

        when(permissionService.update(any(PermissionEntity.class))).thenReturn(updated);

        String requestBody = objectMapper.writeValueAsString(updated);

        // When & Then
        mockMvc.perform(put("/api/v1/auth/permissions/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.permName").value("用户管理(已更新)"));
    }

    @Test
    @DisplayName("DELETE /api/v1/auth/permissions/{id} -> 200 + 删除成功")
    void delete_shouldReturnSuccess_whenPermissionNotReferenced() throws Exception {
        // Given
        doNothing().when(permissionService).delete(1L);

        // When & Then
        mockMvc.perform(delete("/api/v1/auth/permissions/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
    }

    @Test
    @DisplayName("DELETE /api/v1/auth/permissions/{id} -> 400 + 阻止删除（被角色关联）")
    void delete_shouldReturn400_whenPermissionReferencedByRole() throws Exception {
        // Given: 权限已被角色关联时，service 抛出 BusinessException
        doThrow(new BusinessException(400, "权限已被关联到角色，无法删除"))
                .when(permissionService).delete(1L);

        // When & Then
        mockMvc.perform(delete("/api/v1/auth/permissions/{id}", 1L)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("权限已被关联到角色，无法删除"));
    }

    @Test
    @DisplayName("POST /api/v1/auth/permissions -> 400 + 权限编码重复")
    void create_shouldReturn400_whenPermCodeDuplicate() throws Exception {
        // Given: perm_code 重复时 service 抛出 BusinessException
        doThrow(new BusinessException(400, "权限编码已存在"))
                .when(permissionService).create(any(PermissionEntity.class));

        PermissionEntity request = new PermissionEntity();
        request.setPermName("测试权限");
        request.setPermCode("user:manage");
        request.setPermType(1);
        request.setSortOrder(1);
        request.setStatus(0);

        String requestBody = objectMapper.writeValueAsString(request);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/permissions")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(requestBody))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("权限编码已存在"));
    }
}
