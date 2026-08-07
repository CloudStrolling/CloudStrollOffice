/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.VerificationCodeManager;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link PhoneCodeLoginStrategy} 的单元测试。
 *
 * <p>覆盖 UT-014、UT-015：手机验证码登录认证成功；
 * 验证码无效抛 SMS_CODE_INVALID。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PhoneCodeLoginStrategy 单元测试")
class PhoneCodeLoginStrategyTest {

    @Mock
    private VerificationCodeManager verificationCodeManager;

    @Mock
    private UserMapper userMapper;

    private PhoneCodeLoginStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new PhoneCodeLoginStrategy(verificationCodeManager, userMapper);
    }

    private LoginRequest buildRequest() {
        LoginRequest request = new LoginRequest();
        request.setLoginMode("PHONE_CODE");
        request.setPhone("13800000001");
        request.setSmsCode("123456");
        request.setTenantCode("DEFAULT");
        request.setClientType("H5");
        return request;
    }

    private UserEntity buildUser() {
        UserEntity user = new UserEntity();
        user.setId(5L);
        user.setTenantId(1L);
        user.setLoginName("user_0001_123");
        user.setUserName("手机用户");
        user.setPhone("13800000001");
        user.setStatus(0);
        return user;
    }

    /**
     * UT-014：验证码正确时认证成功，验证码校验调用 1 次（P0）。
     */
    @Test
    @DisplayName("UT-014: 手机验证码正确时认证成功")
    void authenticate_shouldReturnAuthResult_whenCodeValid() {
        when(verificationCodeManager.verifyCode(eq("13800000001"), eq("123456")))
                .thenReturn(true);
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildUser());
        when(userMapper.selectRoleCodesByUserId(5L))
                .thenReturn(Collections.singletonList("user"));
        when(userMapper.selectPermissionCodesByUserId(5L))
                .thenReturn(Collections.emptyList());

        AuthResult result = strategy.authenticate(buildRequest());

        assertNotNull(result);
        assertEquals(5L, result.getUserId());
        assertEquals(1L, result.getTenantId());
        assertEquals("13800000001", result.getPhone());
        // 验证码校验恰好调用 1 次
        verify(verificationCodeManager, times(1))
                .verifyCode(eq("13800000001"), eq("123456"));
    }

    /**
     * UT-015：验证码无效抛 SMS_CODE_INVALID（P0）。
     */
    @Test
    @DisplayName("UT-015: 验证码无效抛 SMS_CODE_INVALID")
    void authenticate_shouldThrow_whenCodeInvalid() {
        when(verificationCodeManager.verifyCode(eq("13800000001"), eq("000000")))
                .thenReturn(false);

        LoginRequest request = buildRequest();
        request.setSmsCode("000000");

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.authenticate(request));
        assertEquals("短信验证码无效", ex.getMessage());
        verify(userMapper, never()).selectOne(any(LambdaQueryWrapper.class));
    }
}
