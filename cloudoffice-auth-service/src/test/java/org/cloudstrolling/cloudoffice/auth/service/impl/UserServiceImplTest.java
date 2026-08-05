/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserRoleEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.service.UserService;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link UserServiceImpl} 的单元测试。
 *
 * <p>使用 Mockito 模拟 Mapper 层和 PasswordEncoder，验证用户注册业务逻辑。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("UserServiceImpl 单元测试")
class UserServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private TenantMapper tenantMapper;

    @Mock
    private UserRoleMapper userRoleMapper;

    @Mock
    private RoleMapper roleMapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private LoginSessionService loginSessionService;

    @Captor
    private ArgumentCaptor<UserEntity> userCaptor;

    @Captor
    private ArgumentCaptor<UserRoleEntity> userRoleCaptor;

    private UserService userService;

    @BeforeEach
    void setUp() {
        userService = new UserServiceImpl(userMapper, tenantMapper, userRoleMapper, roleMapper, passwordEncoder, loginSessionService);
    }

    @Test
    @DisplayName("注册成功：返回用户信息且不包含密码")
    void register_shouldReturnUserWithoutPassword_whenSuccess() {
        // Given
        Long tenantId = 1L;
        String tenantCode = "default";
        String loginName = "testuser";
        String rawPassword = "password123";
        String encryptedPassword = "$2a$10$encryptedHash";

        RegisterRequest request = new RegisterRequest();
        request.setTenantCode(tenantCode);
        request.setLoginName(loginName);
        request.setPassword(rawPassword);
        request.setUserName("测试用户");
        request.setPhone("13800138000");
        request.setEmail("test@example.com");

        TenantEntity tenant = new TenantEntity();
        tenant.setId(tenantId);
        tenant.setTenantCode(tenantCode);
        tenant.setStatus(0); // 正常

        RoleEntity defaultRole = new RoleEntity();
        defaultRole.setId(100L);
        defaultRole.setTenantId(tenantId);
        defaultRole.setRoleCode("user");
        defaultRole.setStatus(0);

        // Mock 租户查询（通过 tenantCode）
        when(tenantMapper.selectOne(any())).thenReturn(tenant);
        // Mock 唯一性校验（无重复）
        when(userMapper.selectByTenantIdAndLoginName(tenantId, loginName)).thenReturn(null);
        // Mock 密码加密
        when(passwordEncoder.encode(rawPassword)).thenReturn(encryptedPassword);
        // Mock 默认角色查询
        when(roleMapper.selectOne(any())).thenReturn(defaultRole);

        // When
        UserEntity result = userService.register(request);

        // Then
        // 验证密码加密被调用
        verify(passwordEncoder).encode(rawPassword);

        // 验证用户创建（捕获 insert 参数时的对象引用）
        verify(userMapper).insert(userCaptor.capture());
        UserEntity capturedUser = userCaptor.getValue();
        assertEquals(tenantId, capturedUser.getTenantId());
        assertEquals(loginName, capturedUser.getLoginName());
        assertEquals("测试用户", capturedUser.getUserName());
        assertEquals("13800138000", capturedUser.getPhone());
        assertEquals("test@example.com", capturedUser.getEmail());
        assertEquals(0, capturedUser.getStatus().intValue());

        // 验证角色分配
        verify(userRoleMapper).insert(userRoleCaptor.capture());
        UserRoleEntity capturedUserRole = userRoleCaptor.getValue();
        assertEquals(capturedUser.getId(), capturedUserRole.getUserId());
        assertEquals(defaultRole.getId(), capturedUserRole.getRoleId());

        // 验证返回的用户信息不含密码
        assertNotNull(result);
        assertNull(result.getPassword());
        assertEquals(loginName, result.getLoginName());
        assertEquals("测试用户", result.getUserName());
    }

    @Test
    @DisplayName("注册失败：重复 loginName 抛出 BusinessException")
    void register_shouldThrowBusinessException_whenLoginNameDuplicate() {
        // Given
        Long tenantId = 1L;
        String tenantCode = "default";
        String loginName = "existinguser";

        RegisterRequest request = new RegisterRequest();
        request.setTenantCode(tenantCode);
        request.setLoginName(loginName);
        request.setPassword("password123");
        request.setUserName("已存在用户");

        TenantEntity tenant = new TenantEntity();
        tenant.setId(tenantId);
        tenant.setTenantCode(tenantCode);
        tenant.setStatus(0);

        UserEntity existingUser = new UserEntity();
        existingUser.setId(100L);
        existingUser.setTenantId(tenantId);
        existingUser.setLoginName(loginName);

        // Mock 租户查询（通过 tenantCode）
        when(tenantMapper.selectOne(any())).thenReturn(tenant);
        // Mock 唯一性校验（已存在）
        when(userMapper.selectByTenantIdAndLoginName(tenantId, loginName)).thenReturn(existingUser);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.register(request));
        assertEquals(400, exception.getCode());
        assertEquals("登录名已存在", exception.getMessage());

        // 验证后续流程未执行
        verify(passwordEncoder, never()).encode(anyString());
        verify(userMapper, never()).insert(any(UserEntity.class));
        verify(userRoleMapper, never()).insert(any(UserRoleEntity.class));
    }

    @Test
    @DisplayName("注册失败：租户不存在抛出 BusinessException")
    void register_shouldThrowBusinessException_whenTenantNotFound() {
        // Given
        String tenantCode = "nonexistent";

        RegisterRequest request = new RegisterRequest();
        request.setTenantCode(tenantCode);
        request.setLoginName("newuser");
        request.setPassword("password123");
        request.setUserName("新用户");

        when(tenantMapper.selectOne(any())).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.register(request));
        assertEquals(404, exception.getCode());
        assertEquals("租户不存在", exception.getMessage());
    }

    @Test
    @DisplayName("注册失败：租户已禁用抛出 BusinessException")
    void register_shouldThrowBusinessException_whenTenantDisabled() {
        // Given
        Long tenantId = 1L;
        String tenantCode = "default";

        RegisterRequest request = new RegisterRequest();
        request.setTenantCode(tenantCode);
        request.setLoginName("newuser");
        request.setPassword("password123");
        request.setUserName("新用户");

        TenantEntity tenant = new TenantEntity();
        tenant.setId(tenantId);
        tenant.setTenantCode(tenantCode);
        tenant.setStatus(1); // 禁用

        when(tenantMapper.selectOne(any())).thenReturn(tenant);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.register(request));
        assertEquals(403, exception.getCode());
        assertEquals("租户已被禁用", exception.getMessage());
    }

    @Test
    @DisplayName("注册失败：租户已过期抛出 BusinessException")
    void register_shouldThrowBusinessException_whenTenantExpired() {
        // Given
        Long tenantId = 1L;
        String tenantCode = "default";

        RegisterRequest request = new RegisterRequest();
        request.setTenantCode(tenantCode);
        request.setLoginName("newuser");
        request.setPassword("password123");
        request.setUserName("新用户");

        TenantEntity tenant = new TenantEntity();
        tenant.setId(tenantId);
        tenant.setTenantCode(tenantCode);
        tenant.setStatus(2); // 过期

        when(tenantMapper.selectOne(any())).thenReturn(tenant);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.register(request));
        assertEquals(403, exception.getCode());
        assertEquals("租户已过期", exception.getMessage());
    }

    // ========== 封禁/解封/锁定/解锁 测试 ==========

    @Test
    @DisplayName("封禁成功：状态设为3，更新缓存，清除会话")
    void banUser_shouldSucceed_whenUserExists() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(0);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.banUser(userId);

        // Then
        verify(userMapper).updateById(argThat(u -> u.getStatus() == 3));
        verify(loginSessionService).setAccountStatus(userId, 3);
        verify(loginSessionService).removeAllSessions(userId);
    }

    @Test
    @DisplayName("封禁幂等：已是封禁状态则跳过")
    void banUser_shouldSkip_whenAlreadyBanned() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(3);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.banUser(userId);

        // Then
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).setAccountStatus(any(), any());
        verify(loginSessionService, never()).removeAllSessions(any());
    }

    @Test
    @DisplayName("封禁失败：用户不存在抛出 USER_NOT_FOUND")
    void banUser_shouldThrow_whenUserNotFound() {
        // Given
        Long userId = 999L;
        when(userMapper.selectById(userId)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.banUser(userId));
        assertEquals(404, exception.getCode());
        assertEquals("用户不存在", exception.getMessage());
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).setAccountStatus(any(), any());
        verify(loginSessionService, never()).removeAllSessions(any());
    }

    @Test
    @DisplayName("封禁失败：userId为null抛出 NullPointerException")
    void banUser_shouldThrow_whenUserIdNull() {
        assertThrows(NullPointerException.class,
                () -> userService.banUser(null));
        verify(userMapper, never()).selectById(any());
    }

    @Test
    @DisplayName("解封成功：状态设为0，删除缓存")
    void unbanUser_shouldSucceed_whenUserExists() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(3);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.unbanUser(userId);

        // Then
        verify(userMapper).updateById(argThat(u -> u.getStatus() == 0));
        verify(loginSessionService).removeAccountStatus(userId);
    }

    @Test
    @DisplayName("解封幂等：已是正常状态则跳过")
    void unbanUser_shouldSkip_whenAlreadyNormal() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(0);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.unbanUser(userId);

        // Then
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).removeAccountStatus(any());
    }

    @Test
    @DisplayName("解封失败：用户不存在抛出 USER_NOT_FOUND")
    void unbanUser_shouldThrow_whenUserNotFound() {
        // Given
        Long userId = 999L;
        when(userMapper.selectById(userId)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.unbanUser(userId));
        assertEquals(404, exception.getCode());
        assertEquals("用户不存在", exception.getMessage());
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).removeAccountStatus(any());
    }

    @Test
    @DisplayName("解封失败：userId为null抛出 NullPointerException")
    void unbanUser_shouldThrow_whenUserIdNull() {
        assertThrows(NullPointerException.class,
                () -> userService.unbanUser(null));
        verify(userMapper, never()).selectById(any());
    }

    @Test
    @DisplayName("锁定成功：状态设为2，更新缓存，清除会话")
    void lockUser_shouldSucceed_whenUserExists() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(0);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.lockUser(userId);

        // Then
        verify(userMapper).updateById(argThat(u -> u.getStatus() == 2));
        verify(loginSessionService).setAccountStatus(userId, 2);
        verify(loginSessionService).removeAllSessions(userId);
    }

    @Test
    @DisplayName("锁定幂等：已是锁定状态则跳过")
    void lockUser_shouldSkip_whenAlreadyLocked() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(2);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.lockUser(userId);

        // Then
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).setAccountStatus(any(), any());
        verify(loginSessionService, never()).removeAllSessions(any());
    }

    @Test
    @DisplayName("锁定失败：用户不存在抛出 USER_NOT_FOUND")
    void lockUser_shouldThrow_whenUserNotFound() {
        // Given
        Long userId = 999L;
        when(userMapper.selectById(userId)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.lockUser(userId));
        assertEquals(404, exception.getCode());
        assertEquals("用户不存在", exception.getMessage());
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).setAccountStatus(any(), any());
        verify(loginSessionService, never()).removeAllSessions(any());
    }

    @Test
    @DisplayName("锁定失败：userId为null抛出 NullPointerException")
    void lockUser_shouldThrow_whenUserIdNull() {
        assertThrows(NullPointerException.class,
                () -> userService.lockUser(null));
        verify(userMapper, never()).selectById(any());
    }

    @Test
    @DisplayName("解锁成功：状态设为0，删除缓存")
    void unlockUser_shouldSucceed_whenUserExists() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(2);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.unlockUser(userId);

        // Then
        verify(userMapper).updateById(argThat(u -> u.getStatus() == 0));
        verify(loginSessionService).removeAccountStatus(userId);
    }

    @Test
    @DisplayName("解锁幂等：已是正常状态则跳过")
    void unlockUser_shouldSkip_whenAlreadyNormal() {
        // Given
        Long userId = 1L;
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setStatus(0);
        when(userMapper.selectById(userId)).thenReturn(user);

        // When
        userService.unlockUser(userId);

        // Then
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).removeAccountStatus(any());
    }

    @Test
    @DisplayName("解锁失败：用户不存在抛出 USER_NOT_FOUND")
    void unlockUser_shouldThrow_whenUserNotFound() {
        // Given
        Long userId = 999L;
        when(userMapper.selectById(userId)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> userService.unlockUser(userId));
        assertEquals(404, exception.getCode());
        assertEquals("用户不存在", exception.getMessage());
        verify(userMapper, never()).updateById(any());
        verify(loginSessionService, never()).removeAccountStatus(any());
    }

    @Test
    @DisplayName("解锁失败：userId为null抛出 NullPointerException")
    void unlockUser_shouldThrow_whenUserIdNull() {
        assertThrows(NullPointerException.class,
                () -> userService.unlockUser(null));
        verify(userMapper, never()).selectById(any());
    }
}
