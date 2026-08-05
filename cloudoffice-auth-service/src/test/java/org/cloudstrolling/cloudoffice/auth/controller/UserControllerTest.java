/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.cloudstrolling.cloudoffice.auth.dto.AssignRolesRequest;
import org.cloudstrolling.cloudoffice.auth.dto.UserStatusRequest;
import org.cloudstrolling.cloudoffice.auth.dto.UserUpdateRequest;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.service.UserService;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.exception.GlobalExceptionHandler;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.nullValue;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * {@link UserController} 的 MockMvc 测试。
 *
 * <p>使用 MockMvc 独立配置（standaloneSetup）进行控制器层测试，
 * 模拟 UserService 的行为，验证 HTTP 状态码、响应结构和业务逻辑。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("UserController MockMvc 测试")
class UserControllerTest {

    @Mock
    private UserService userService;

    private MockMvc mockMvc;

    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        UserController controller = new UserController(userService);
        mockMvc = MockMvcBuilders.standaloneSetup(controller)
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
        objectMapper = new ObjectMapper();
    }

    @Test
    @DisplayName("GET /api/v1/auth/users -> 200 + 分页数据")
    void list_shouldReturnPageResult_whenCalled() throws Exception {
        // Given
        Long tenantId = 1L;
        UserEntity user = new UserEntity();
        user.setId(100L);
        user.setTenantId(tenantId);
        user.setLoginName("testuser");
        user.setUserName("测试用户");
        user.setStatus(0);

        PageResult<UserEntity> pageResult = PageResult.of(
                List.of(user), 1L, 1, 10);

        when(userService.list(eq(tenantId), eq("test"), eq(1), eq(10)))
                .thenReturn(pageResult);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/users")
                        .header("X-Tenant-Id", tenantId)
                        .param("page", "1")
                        .param("pageSize", "10")
                        .param("keyword", "test"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.records").isArray())
                .andExpect(jsonPath("$.data.records", hasSize(1)))
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.page").value(1))
                .andExpect(jsonPath("$.data.pageSize").value(10))
                .andExpect(jsonPath("$.data.records[0].loginName").value("testuser"))
                .andExpect(jsonPath("$.data.records[0].userName").value("测试用户"));
    }

    @Test
    @DisplayName("GET /api/v1/auth/users（无keyword）-> 200 + 分页数据")
    void list_shouldReturnPageResult_whenNoKeyword() throws Exception {
        // Given
        Long tenantId = 1L;
        PageResult<UserEntity> emptyResult = PageResult.empty();

        when(userService.list(eq(tenantId), isNull(), eq(1), eq(10)))
                .thenReturn(emptyResult);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/users")
                        .header("X-Tenant-Id", tenantId)
                        .param("page", "1")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.records", hasSize(0)))
                .andExpect(jsonPath("$.data.total").value(0));
    }

    @Test
    @DisplayName("GET /api/v1/auth/users/{id} -> 200 + 用户详情（含角色编码）")
    void findById_shouldReturnUserWithRoles_whenUserExists() throws Exception {
        // Given
        Long userId = 100L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setTenantId(1L);
        user.setLoginName("testuser");
        user.setUserName("测试用户");
        user.setStatus(0);
        user.setRoleCodes(List.of("admin", "user"));

        when(userService.findById(userId)).thenReturn(user);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/users/{id}", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.id").value(userId))
                .andExpect(jsonPath("$.data.loginName").value("testuser"))
                .andExpect(jsonPath("$.data.userName").value("测试用户"))
                .andExpect(jsonPath("$.data.roleCodes", hasSize(2)))
                .andExpect(jsonPath("$.data.roleCodes[0]").value("admin"))
                .andExpect(jsonPath("$.data.roleCodes[1]").value("user"))
                .andExpect(jsonPath("$.data.password").doesNotExist());
    }

    @Test
    @DisplayName("GET /api/v1/auth/users/{id} -> 用户不存在返回 404")
    void findById_shouldReturn404_whenUserNotFound() throws Exception {
        // Given
        Long userId = 999L;
        when(userService.findById(userId)).thenReturn(null);

        // When & Then
        mockMvc.perform(get("/api/v1/auth/users/{id}", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("用户不存在"));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/users/{id} -> 200 + 更新后用户信息")
    void updateUser_shouldReturnUpdatedUser_whenSuccess() throws Exception {
        // Given
        Long userId = 100L;
        UserUpdateRequest request = new UserUpdateRequest();
        request.setUserName("新用户名");
        request.setPhone("13900139000");
        request.setEmail("new@example.com");

        UserEntity updatedUser = new UserEntity();
        updatedUser.setId(userId);
        updatedUser.setTenantId(1L);
        updatedUser.setLoginName("testuser");
        updatedUser.setUserName("新用户名");
        updatedUser.setPhone("13900139000");
        updatedUser.setEmail("new@example.com");
        updatedUser.setStatus(0);

        when(userService.update(any(UserEntity.class))).thenReturn(updatedUser);

        // When & Then
        mockMvc.perform(put("/api/v1/auth/users/{id}", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.userName").value("新用户名"))
                .andExpect(jsonPath("$.data.phone").value("13900139000"))
                .andExpect(jsonPath("$.data.email").value("new@example.com"));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/users/{id} -> 404 用户不存在")
    void updateUser_shouldReturn404_whenUserNotFound() throws Exception {
        // Given
        Long userId = 999L;
        UserUpdateRequest request = new UserUpdateRequest();
        request.setUserName("新用户名");

        when(userService.update(any(UserEntity.class)))
                .thenThrow(new BusinessException(ErrorCode.USER_NOT_FOUND));

        // When & Then
        // BusinessException 被 GlobalExceptionHandler 处理，返回 HTTP 400
        mockMvc.perform(put("/api/v1/auth/users/{id}", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("用户不存在"));
    }

    @Test
    @DisplayName("DELETE /api/v1/auth/users/{id} -> 200 逻辑删除成功")
    void deleteUser_shouldReturnSuccess_whenUserExists() throws Exception {
        // Given
        Long userId = 100L;
        doNothing().when(userService).delete(userId);

        // When & Then
        mockMvc.perform(delete("/api/v1/auth/users/{id}", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
    }

    @Test
    @DisplayName("DELETE /api/v1/auth/users/{id} -> 404 用户不存在")
    void deleteUser_shouldReturn404_whenUserNotFound() throws Exception {
        // Given
        Long userId = 999L;
        doThrow(new BusinessException(ErrorCode.USER_NOT_FOUND))
                .when(userService).delete(userId);

        // When & Then
        // BusinessException 被 GlobalExceptionHandler 处理，返回 HTTP 400
        mockMvc.perform(delete("/api/v1/auth/users/{id}", userId))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("用户不存在"));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/users/{id}/roles -> 200 角色分配成功")
    void assignRoles_shouldReturnSuccess_whenCalled() throws Exception {
        // Given
        Long userId = 100L;
        AssignRolesRequest request = new AssignRolesRequest();
        request.setRoleIds(List.of(1L, 2L, 3L));

        doNothing().when(userService).assignRoles(eq(userId), eq(List.of(1L, 2L, 3L)));

        // When & Then
        mockMvc.perform(put("/api/v1/auth/users/{id}/roles", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/users/{id}/roles -> 404 用户不存在")
    void assignRoles_shouldReturn404_whenUserNotFound() throws Exception {
        // Given
        Long userId = 999L;
        AssignRolesRequest request = new AssignRolesRequest();
        request.setRoleIds(List.of(1L));

        doThrow(new BusinessException(ErrorCode.USER_NOT_FOUND))
                .when(userService).assignRoles(eq(userId), eq(List.of(1L)));

        // When & Then
        // BusinessException 被 GlobalExceptionHandler 处理，返回 HTTP 400
        mockMvc.perform(put("/api/v1/auth/users/{id}/roles", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("用户不存在"));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/users/{id}/status -> 200 状态变更成功")
    void updateStatus_shouldReturnSuccess_whenCalled() throws Exception {
        // Given
        Long userId = 100L;
        UserStatusRequest request = new UserStatusRequest();
        request.setStatus(3); // 封禁

        doNothing().when(userService).updateStatus(eq(userId), eq(3), isNull());

        // When & Then
        mockMvc.perform(put("/api/v1/auth/users/{id}/status", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/users/{id}/status -> 404 用户不存在")
    void updateStatus_shouldReturn404_whenUserNotFound() throws Exception {
        // Given
        Long userId = 999L;
        UserStatusRequest request = new UserStatusRequest();
        request.setStatus(3);

        doThrow(new BusinessException(ErrorCode.USER_NOT_FOUND))
                .when(userService).updateStatus(eq(userId), eq(3), isNull());

        // When & Then
        // BusinessException 被 GlobalExceptionHandler 处理，返回 HTTP 400
        mockMvc.perform(put("/api/v1/auth/users/{id}/status", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(404))
                .andExpect(jsonPath("$.message").value("用户不存在"));
    }

    @Test
    @DisplayName("PUT /api/v1/auth/users/{id}/status -> 400 状态值超出范围触发校验异常")
    void updateStatus_shouldReturn400_whenStatusInvalid() throws Exception {
        // Given
        Long userId = 100L;
        UserStatusRequest request = new UserStatusRequest();
        request.setStatus(5); // 无效状态，会触发 @Max(3) 校验失败

        // When & Then
        // @Max(3) 校验在 Controller 层被 MethodArgumentNotValidException 捕获
        mockMvc.perform(put("/api/v1/auth/users/{id}/status", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("状态值范围为0-3")));
    }
}
