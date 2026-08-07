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
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.service.VerificationCodeManager;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link PhoneSetUsernameStrategy} 的单元测试。
 *
 * <p>覆盖 UT-009（手机侧）：PHONE_SET_USERNAME 两步注册第一步
 * 创建未完善账号（accountSettled=false），验证码无效被拒。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PhoneSetUsernameStrategy 单元测试")
class PhoneSetUsernameStrategyTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private TenantMapper tenantMapper;

    @Mock
    private UserRoleMapper userRoleMapper;

    @Mock
    private RoleMapper roleMapper;

    @Mock
    private VerificationCodeManager verificationCodeManager;

    @Mock
    private JwtUtils jwtUtils;

    @Mock
    private LoginSessionService loginSessionService;

    private PhoneSetUsernameStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new PhoneSetUsernameStrategy(userMapper, tenantMapper,
                userRoleMapper, roleMapper, verificationCodeManager, jwtUtils,
                loginSessionService);
        ReflectionTestUtils.setField(strategy, "refreshTokenExpiration", 604800L);
    }

    /**
     * UT-009：PHONE_SET_USERNAME 注册成功创建未完善账号（P0）。
     */
    @Test
    @DisplayName("UT-009: 手机两步注册第一步创建 accountSettled=false 账号并自动登录")
    void register_shouldCreateUnsettledAccount_whenCodeValid() {
        when(verificationCodeManager.verifyCode(eq("13900000001"), eq("654321")))
                .thenReturn(true);
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);
        when(roleMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildDefaultRole());
        when(userMapper.selectRoleCodesByUserId(anyLong()))
                .thenReturn(Collections.singletonList("user"));
        when(userMapper.selectPermissionCodesByUserId(anyLong()))
                .thenReturn(Collections.emptyList());
        when(jwtUtils.generateAccessToken(any())).thenReturn("access.token.mock");
        when(jwtUtils.generateRefreshToken(any())).thenReturn("refresh.token.mock");
        when(jwtUtils.getAccessTokenExpiration()).thenReturn(7200L);
        doAnswer(invocation -> {
            UserEntity user = invocation.getArgument(0);
            user.setId(320L);
            return 1;
        }).when(userMapper).insert(any(UserEntity.class));

        RegisterRequest request = new RegisterRequest();
        request.setRegisterMode("PHONE_SET_USERNAME");
        request.setPhone("13900000001");
        request.setSmsCode("654321");
        request.setUserName("手机两步用户");
        request.setTenantCode("DEFAULT");

        RegisterResult result = strategy.register(request);

        assertNotNull(result);
        assertEquals(320L, result.getUserId());
        assertEquals(Boolean.FALSE, result.getAccountSettled());
        assertTrue(result.getLoginName().startsWith("user_"));
        assertNotNull(result.getTokenPair());
        verify(verificationCodeManager, times(1)).verifyCode(eq("13900000001"), eq("654321"));
    }

    /**
     * UT-009：验证码无效抛 SMS_CODE_INVALID（P0）。
     */
    @Test
    @DisplayName("UT-009: 验证码无效时抛 SMS_CODE_INVALID")
    void register_shouldThrow_whenCodeInvalid() {
        when(verificationCodeManager.verifyCode(eq("13900000001"), eq("654321")))
                .thenReturn(false);

        RegisterRequest request = new RegisterRequest();
        request.setRegisterMode("PHONE_SET_USERNAME");
        request.setPhone("13900000001");
        request.setSmsCode("654321");
        request.setTenantCode("DEFAULT");

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.register(request));
        assertEquals("短信验证码无效", ex.getMessage());
        verify(userMapper, never()).insert(any(UserEntity.class));
    }

    private TenantEntity buildNormalTenant() {
        TenantEntity tenant = new TenantEntity();
        tenant.setId(1L);
        tenant.setTenantCode("DEFAULT");
        tenant.setStatus(0);
        tenant.setExpireTime(LocalDateTime.now().plusDays(365));
        return tenant;
    }

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
