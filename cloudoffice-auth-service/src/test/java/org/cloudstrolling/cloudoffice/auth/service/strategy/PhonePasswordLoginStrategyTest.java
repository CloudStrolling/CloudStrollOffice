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
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link PhonePasswordLoginStrategy} 的单元测试。
 *
 * <p>覆盖 UT-016：手机号+密码登录认证成功与密码错误拒绝。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PhonePasswordLoginStrategy 单元测试")
class PhonePasswordLoginStrategyTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    private PhonePasswordLoginStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new PhonePasswordLoginStrategy(userMapper, passwordEncoder);
    }

    private LoginRequest buildRequest(String password) {
        LoginRequest request = new LoginRequest();
        request.setLoginMode("PHONE_PASSWORD");
        request.setPhone("13800000001");
        request.setPassword(password);
        request.setTenantCode("DEFAULT");
        request.setClientType("ANDROID");
        return request;
    }

    private UserEntity buildUser() {
        UserEntity user = new UserEntity();
        user.setId(5L);
        user.setTenantId(1L);
        user.setLoginName("user_0001_123");
        user.setUserName("手机用户");
        user.setPhone("13800000001");
        user.setPassword("$2a$10$phonePasswordMock");
        user.setStatus(0);
        return user;
    }

    /**
     * UT-016：手机号+密码正确时认证成功（P1）。
     */
    @Test
    @DisplayName("UT-016: 手机号+密码匹配时认证成功返回 AuthResult")
    void authenticate_shouldReturnAuthResult_whenPasswordValid() {
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildUser());
        when(passwordEncoder.matches("phone123", "$2a$10$phonePasswordMock")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(5L))
                .thenReturn(Collections.singletonList("user"));
        when(userMapper.selectPermissionCodesByUserId(5L))
                .thenReturn(Collections.emptyList());

        AuthResult result = strategy.authenticate(buildRequest("phone123"));

        assertNotNull(result);
        assertEquals(5L, result.getUserId());
        assertEquals("13800000001", result.getPhone());
        assertEquals(1, result.getRoles().size());
    }

    /**
     * UT-016：密码错误抛 LOGIN_FAILED（P1）。
     */
    @Test
    @DisplayName("UT-016: 密码错误抛 LOGIN_FAILED")
    void authenticate_shouldThrow_whenPasswordIncorrect() {
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildUser());
        when(passwordEncoder.matches("wrong_pass", "$2a$10$phonePasswordMock")).thenReturn(false);

        AuthException ex = assertThrows(AuthException.class,
                () -> strategy.authenticate(buildRequest("wrong_pass")));
        assertEquals(401, ex.getCode());
    }
}
