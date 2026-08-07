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
 * {@link PhoneCodeRegisterStrategy} 的单元测试。
 *
 * <p>覆盖 UT-005：手机验证码注册成功创建未完善账号并自动登录；
 * 验证码无效时抛 SMS_CODE_INVALID。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PhoneCodeRegisterStrategy 单元测试")
class PhoneCodeRegisterStrategyTest {

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

    private PhoneCodeRegisterStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new PhoneCodeRegisterStrategy(userMapper, tenantMapper,
                userRoleMapper, roleMapper, verificationCodeManager, jwtUtils,
                loginSessionService);
        // 默认 Refresh Token 有效期 7 天
        ReflectionTestUtils.setField(strategy, "refreshTokenExpiration", 604800L);
    }

    /**
     * 构造合法的手机验证码注册请求。
     */
    private RegisterRequest buildValidRequest() {
        RegisterRequest request = new RegisterRequest();
        request.setRegisterMode("PHONE_CODE");
        request.setPhone("13800000002");
        request.setSmsCode("123456");
        request.setUserName("手机注册用户");
        request.setTenantCode("DEFAULT");
        return request;
    }

    /**
     * 构造正常租户。
     */
    private TenantEntity buildNormalTenant() {
        TenantEntity tenant = new TenantEntity();
        tenant.setId(1L);
        tenant.setTenantCode("DEFAULT");
        tenant.setStatus(0);
        tenant.setExpireTime(LocalDateTime.now().plusDays(365));
        return tenant;
    }

    /**
     * UT-005：验证码正确时注册成功，验证码校验调用 1 次（P0）。
     */
    @Test
    @DisplayName("UT-005: 手机验证码注册成功，accountSettled=false 且签发自动登录 Token")
    void register_shouldCreateUnsettledAccount_whenCodeValid() {
        when(verificationCodeManager.verifyCode(eq("13800000002"), eq("123456")))
                .thenReturn(true);
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);
        when(roleMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildDefaultRole());
        when(userMapper.selectRoleCodesByUserId(anyLong()))
                .thenReturn(Collections.singletonList("user"));
        when(userMapper.selectPermissionCodesByUserId(anyLong()))
                .thenReturn(Collections.singletonList("system:user:view"));
        when(jwtUtils.generateAccessToken(any())).thenReturn("access.token.mock");
        when(jwtUtils.generateRefreshToken(any())).thenReturn("refresh.token.mock");
        when(jwtUtils.getAccessTokenExpiration()).thenReturn(7200L);
        doAnswer(invocation -> {
            UserEntity user = invocation.getArgument(0);
            user.setId(200L);
            return 1;
        }).when(userMapper).insert(any(UserEntity.class));

        RegisterResult result = strategy.register(buildValidRequest());

        assertNotNull(result);
        assertEquals(200L, result.getUserId());
        assertEquals(Boolean.FALSE, result.getAccountSettled());
        assertNotNull(result.getTokenPair());
        assertEquals("access.token.mock", result.getTokenPair().getAccessToken());
        // 验证码校验恰好调用 1 次
        verify(verificationCodeManager, times(1))
                .verifyCode(eq("13800000002"), eq("123456"));
        verify(userMapper, times(1)).insert(any(UserEntity.class));
        verify(loginSessionService, times(1)).createSession(anyLong(), anyString(),
                any(), anyLong());
    }

    /**
     * UT-005：验证码无效时抛 SMS_CODE_INVALID（P0）。
     */
    @Test
    @DisplayName("UT-005: 验证码无效时抛 SMS_CODE_INVALID 且不创建用户")
    void register_shouldThrow_whenCodeInvalid() {
        when(verificationCodeManager.verifyCode(eq("13800000002"), eq("123456")))
                .thenReturn(false);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));

        assertEquals("短信验证码无效", ex.getMessage());
        verify(userMapper, never()).insert(any(UserEntity.class));
    }

    /**
     * 构造默认角色。
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
