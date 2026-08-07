/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.RegisterResult;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link UsernamePwdRegisterStrategy} 的单元测试。
 *
 * <p>覆盖 UT-001~UT-004、UT-010：用户名密码注册成功与默认角色分配、
 * 登录名重复/手机号已绑定/租户状态异常被拒、密码长度边界。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("UsernamePwdRegisterStrategy 单元测试")
class UsernamePwdRegisterStrategyTest {

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

    private UsernamePwdRegisterStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new UsernamePwdRegisterStrategy(userMapper, tenantMapper,
                userRoleMapper, roleMapper, passwordEncoder);
    }

    /**
     * 构造可用的注册请求（合法密码 8 位）。
     */
    private RegisterRequest buildValidRequest() {
        RegisterRequest request = new RegisterRequest();
        request.setRegisterMode("USERNAME");
        request.setLoginName("tester_ut001");
        request.setPassword("pass1234");
        request.setUserName("测试用户");
        request.setPhone("13800000001");
        request.setTenantCode("DEFAULT");
        return request;
    }

    /**
     * 构造正常状态的租户。
     */
    private TenantEntity buildNormalTenant() {
        TenantEntity tenant = new TenantEntity();
        tenant.setId(1L);
        tenant.setTenantCode("DEFAULT");
        tenant.setTenantName("默认租户");
        tenant.setStatus(0);
        tenant.setExpireTime(LocalDateTime.now().plusDays(365));
        return tenant;
    }

    /**
     * UT-001：注册成功创建完整账号并分配默认角色（P0）。
     */
    @Test
    @DisplayName("UT-001: 用户名密码注册成功，accountSettled=true，分配默认角色")
    void register_shouldCreateSettledAccountWithDefaultRole_whenInputValid() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectByTenantIdAndLoginName(anyLong(), anyString())).thenReturn(null);
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);
        when(passwordEncoder.encode("pass1234")).thenReturn("$2a$10$mockEncrypted");
        when(roleMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildDefaultRole());
        doAnswer(invocation -> {
            UserEntity user = invocation.getArgument(0);
            user.setId(100L);
            return 1;
        }).when(userMapper).insert(any(UserEntity.class));

        RegisterResult result = strategy.register(buildValidRequest());

        assertNotNull(result);
        assertEquals(100L, result.getUserId());
        assertEquals("tester_ut001", result.getLoginName());
        assertEquals(Boolean.TRUE, result.getAccountSettled());
        verify(userMapper, times(1)).insert(any(UserEntity.class));
        verify(userRoleMapper, times(1)).insert(any());
        ArgumentCaptor<UserEntity> captor = ArgumentCaptor.forClass(UserEntity.class);
        verify(userMapper).insert(captor.capture());
        // 密码必须为 BCrypt 密文（非明文）
        assertEquals("$2a$10$mockEncrypted", captor.getValue().getPassword());
        assertEquals(0, captor.getValue().getStatus());
        assertEquals("USERNAME", captor.getValue().getRegisterMode());
        assertEquals(1, captor.getValue().getAccountSettled());
    }

    /**
     * UT-002：登录名在租户内重复被拒（P0）。
     */
    @Test
    @DisplayName("UT-002: 登录名在租户内重复时抛业务异常且不插入")
    void register_shouldThrow_whenLoginNameDuplicate() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        UserEntity existing = new UserEntity();
        existing.setId(9L);
        existing.setLoginName("tester_ut001");
        when(userMapper.selectByTenantIdAndLoginName(eq(1L), eq("tester_ut001")))
                .thenReturn(existing);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));

        assertEquals("登录名已存在", ex.getMessage());
        verify(userMapper, never()).insert(any(UserEntity.class));
        verify(userRoleMapper, never()).insert(any());
    }

    /**
     * UT-003：手机号已被其他用户绑定被拒（P1）。
     */
    @Test
    @DisplayName("UT-003: 手机号全局唯一性校验，已被绑定抛 PHONE_ALREADY_BOUND")
    void register_shouldThrow_whenPhoneAlreadyBound() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectByTenantIdAndLoginName(anyLong(), anyString())).thenReturn(null);
        UserEntity phoneOwner = new UserEntity();
        phoneOwner.setId(8L);
        phoneOwner.setPhone("13800000001");
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(phoneOwner);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));

        assertEquals(409, ex.getCode());
        verify(userMapper, never()).insert(any(UserEntity.class));
    }

    /**
     * UT-004：租户不存在/禁用/过期被拒（P1）。
     */
    @Test
    @DisplayName("UT-004: 租户不存在/status=1 禁用/status=2 过期/有效期已过均被拒")
    void register_shouldThrow_whenTenantInvalid() {
        // 4.1 租户不存在
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);
        BusinessException notFound = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));
        assertEquals("租户不存在", notFound.getMessage());
        verify(userMapper, never()).insert(any(UserEntity.class));

        // 4.2 租户 status=1（禁用）
        TenantEntity disabled = buildNormalTenant();
        disabled.setStatus(1);
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(disabled);
        BusinessException disabledEx = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));
        assertEquals("租户已被禁用", disabledEx.getMessage());

        // 4.3 租户 status=2（过期）
        TenantEntity expired = buildNormalTenant();
        expired.setStatus(2);
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(expired);
        BusinessException expiredEx = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));
        assertEquals("租户已过期", expiredEx.getMessage());

        // 4.4 租户有效期已过（expireTime 在过去）
        TenantEntity expirePast = buildNormalTenant();
        expirePast.setStatus(0);
        expirePast.setExpireTime(LocalDateTime.now().minusDays(1));
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(expirePast);
        BusinessException expireEx = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));
        assertEquals("租户已过期", expireEx.getMessage());
    }

    /**
     * UT-010：密码长度边界 8 位/64 位可通过注册（P1）。
     *
     * <p>说明：7 位/65 位的 400 拒绝由 Controller 层 @Valid 校验（@Size(min=8,max=64)）
     * 与接口测试 TC-004 覆盖，策略层仅校验非空。</p>
     */
    @Test
    @DisplayName("UT-010: 密码 8 位与 64 位边界可注册通过")
    void register_shouldPass_whenPasswordAtBoundary() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectByTenantIdAndLoginName(anyLong(), anyString())).thenReturn(null);
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);
        when(roleMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildDefaultRole());
        doAnswer(invocation -> {
            UserEntity user = invocation.getArgument(0);
            user.setId(101L);
            return 1;
        }).when(userMapper).insert(any(UserEntity.class));

        // 8 位密码
        RegisterRequest min8 = buildValidRequest();
        min8.setPassword("abcdefgh");
        min8.setLoginName("tester_min8");
        assertNotNull(strategy.register(min8));

        // 64 位密码
        RegisterRequest max64 = buildValidRequest();
        max64.setPassword("a".repeat(64));
        max64.setLoginName("tester_max64");
        assertNotNull(strategy.register(max64));

        verify(userMapper, times(2)).insert(any(UserEntity.class));
    }

    /**
     * 构造默认角色实体。
     */
    private RoleEntity buildDefaultRole() {
        RoleEntity role = new RoleEntity();
        role.setId(1L);
        role.setTenantId(1L);
        role.setRoleCode("user");
        role.setRoleName("普通用户");
        role.setStatus(0);
        return role;
    }
}
