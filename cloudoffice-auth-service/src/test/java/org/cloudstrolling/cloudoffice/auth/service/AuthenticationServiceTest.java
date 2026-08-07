/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.strategy.LoginStrategy;
import org.cloudstrolling.cloudoffice.auth.service.strategy.LoginStrategyFactory;
import org.cloudstrolling.cloudoffice.auth.service.strategy.RegisterStrategyFactory;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
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
 * {@link AuthenticationService} 的单元测试。
 *
 * <p>覆盖 UT-058~UT-060：统一认证登录全流程（策略认证→状态校验→
 * 双 Token→会话→日志）、用户 5 状态×租户状态矩阵拒绝、
 * Redis 失败容错与同端互斥清理。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("AuthenticationService 单元测试")
class AuthenticationServiceTest {

    @Mock
    private LoginStrategyFactory loginStrategyFactory;

    @Mock
    private RegisterStrategyFactory registerStrategyFactory;

    @Mock
    private LoginSessionService loginSessionService;

    @Mock
    private LoginLogService loginLogService;

    @Mock
    private JwtUtils jwtUtils;

    @Mock
    private UserMapper userMapper;

    @Mock
    private TenantMapper tenantMapper;

    @Mock
    private LoginStrategy loginStrategy;

    private AuthenticationService authenticationService;

    @BeforeEach
    void setUp() {
        authenticationService = new AuthenticationService(loginStrategyFactory,
                registerStrategyFactory, loginSessionService, loginLogService,
                jwtUtils, userMapper, tenantMapper);
        ReflectionTestUtils.setField(authenticationService, "refreshTokenExpiration", 604800L);
    }

    /**
     * 构造正常用户（status=0，accountSettled=1）。
     */
    private UserEntity buildNormalUser() {
        UserEntity user = new UserEntity();
        user.setId(1L);
        user.setTenantId(1L);
        user.setLoginName("admin");
        user.setUserName("管理员");
        user.setStatus(0);
        user.setAccountSettled(1);
        return user;
    }

    /**
     * 构造正常租户（status=0，有效期未来）。
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
     * 构造登录请求。
     */
    private LoginRequest buildRequest() {
        LoginRequest request = new LoginRequest();
        request.setLoginMode("USERNAME_PASSWORD");
        request.setLoginName("admin");
        request.setPassword("admin123");
        request.setTenantCode("DEFAULT");
        request.setClientType("H5");
        return request;
    }

    /**
     * 构造认证结果。
     */
    private AuthResult buildAuthResult() {
        return AuthResult.builder()
                .userId(1L)
                .tenantId(1L)
                .loginName("admin")
                .userName("管理员")
                .roles(Collections.singletonList("admin"))
                .permissions(Collections.singletonList("system:user:view"))
                .build();
    }

    /**
     * 配置登录成功的公共 Mock 链路。
     */
    private void stubSuccessfulLogin() {
        when(loginStrategyFactory.getStrategy("USERNAME_PASSWORD")).thenReturn(loginStrategy);
        when(loginStrategy.authenticate(any(LoginRequest.class))).thenReturn(buildAuthResult());
        when(userMapper.selectById(1L)).thenReturn(buildNormalUser());
        when(tenantMapper.selectById(1L)).thenReturn(buildNormalTenant());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access.token.mock");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh.token.mock");
        when(jwtUtils.getAccessTokenExpiration()).thenReturn(7200L);
    }

    /**
     * UT-058：登录成功全流程（P0）。
     */
    @Test
    @DisplayName("UT-058: 认证成功签发双 Token，会话/状态缓存/日志/最后登录均执行")
    void authenticate_shouldReturnTokenPair_whenAllValid() {
        stubSuccessfulLogin();

        TokenPairDTO tokenPair = authenticationService.authenticate(buildRequest());

        assertNotNull(tokenPair);
        assertEquals("access.token.mock", tokenPair.getAccessToken());
        assertEquals("refresh.token.mock", tokenPair.getRefreshToken());
        assertEquals("Bearer", tokenPair.getTokenType());
        verify(loginSessionService, times(1)).createSession(eq(1L), eq("H5"),
                any(LoginUserDTO.class), eq(604800L));
        verify(loginSessionService, times(1)).setAccountStatus(1L, 0);
        verify(loginSessionService, times(1)).setTenantStatus(1L, 0);
        verify(loginLogService, times(1)).recordLoginSuccess(eq(1L), eq(1L),
                eq("admin"), anyString(), eq("H5"), isNull());
        verify(userMapper, times(1)).updateById(any(UserEntity.class));
    }

    /**
     * UT-059：用户状态矩阵（1 禁用/2 锁定/3 封禁/4 过期）均被拒（P0）。
     */
    @Test
    @DisplayName("UT-059: 用户状态 1/2/3/4 分别抛 ACCOUNT_DISABLED/LOCKED/BANNED/EXPIRED")
    void authenticate_shouldReject_whenUserStatusAbnormal() {
        when(loginStrategyFactory.getStrategy("USERNAME_PASSWORD")).thenReturn(loginStrategy);
        when(loginStrategy.authenticate(any(LoginRequest.class))).thenReturn(buildAuthResult());
        when(tenantMapper.selectById(1L)).thenReturn(buildNormalTenant());

        UserEntity user = buildNormalUser();
        user.setStatus(1);
        when(userMapper.selectById(1L)).thenReturn(user);
        assertEquals("账号已被禁用", assertThrows(BusinessException.class,
                () -> authenticationService.authenticate(buildRequest())).getMessage());

        user.setStatus(2);
        assertEquals("账号已被锁定", assertThrows(BusinessException.class,
                () -> authenticationService.authenticate(buildRequest())).getMessage());

        user.setStatus(3);
        assertEquals("账号已被封禁", assertThrows(BusinessException.class,
                () -> authenticationService.authenticate(buildRequest())).getMessage());

        user.setStatus(4);
        assertEquals("账号已过期", assertThrows(BusinessException.class,
                () -> authenticationService.authenticate(buildRequest())).getMessage());
    }

    /**
     * UT-059：租户禁用/过期与账号未完善被拒（P0）。
     */
    @Test
    @DisplayName("UT-059: 租户禁用/过期与 accountSettled=0 被拒")
    void authenticate_shouldReject_whenTenantOrAccountAbnormal() {
        when(loginStrategyFactory.getStrategy("USERNAME_PASSWORD")).thenReturn(loginStrategy);
        when(loginStrategy.authenticate(any(LoginRequest.class))).thenReturn(buildAuthResult());
        when(userMapper.selectById(1L)).thenReturn(buildNormalUser());

        // 租户 status=1（禁用）
        TenantEntity disabledTenant = buildNormalTenant();
        disabledTenant.setStatus(1);
        when(tenantMapper.selectById(1L)).thenReturn(disabledTenant);
        assertEquals("租户已被禁用", assertThrows(BusinessException.class,
                () -> authenticationService.authenticate(buildRequest())).getMessage());

        // 租户已过期
        TenantEntity expiredTenant = buildNormalTenant();
        expiredTenant.setStatus(0);
        expiredTenant.setExpireTime(LocalDateTime.now().minusDays(1));
        when(tenantMapper.selectById(1L)).thenReturn(expiredTenant);
        assertEquals("租户已过期", assertThrows(BusinessException.class,
                () -> authenticationService.authenticate(buildRequest())).getMessage());

        // 账号未完善
        when(tenantMapper.selectById(1L)).thenReturn(buildNormalTenant());
        UserEntity unsettled = buildNormalUser();
        unsettled.setAccountSettled(0);
        when(userMapper.selectById(1L)).thenReturn(unsettled);
        assertEquals("账号信息未完善，请先补充资料", assertThrows(BusinessException.class,
                () -> authenticationService.authenticate(buildRequest())).getMessage());
    }

    /**
     * UT-060：Redis 会话/状态缓存写入失败不影响登录（P0）。
     */
    @Test
    @DisplayName("UT-060: Redis 会话写入与状态缓存失败时登录仍成功")
    void authenticate_shouldStillSucceed_whenRedisFails() {
        stubSuccessfulLogin();
        doThrow(new RuntimeException("redis down"))
                .when(loginSessionService).createSession(anyLong(), anyString(),
                        any(LoginUserDTO.class), anyLong());
        // setAccountStatus 抛异常后同 try 块内 setTenantStatus 不会执行
        doThrow(new RuntimeException("redis down"))
                .when(loginSessionService).setAccountStatus(anyLong(), anyInt());

        TokenPairDTO tokenPair = authenticationService.authenticate(buildRequest());

        assertNotNull(tokenPair);
        assertEquals("access.token.mock", tokenPair.getAccessToken());
        // 日志记录仍执行
        verify(loginLogService, times(1)).recordLoginSuccess(anyLong(), anyLong(),
                anyString(), anyString(), anyString(), isNull());
    }

    /**
     * UT-060：同端互斥清理旧会话（P0）。
     */
    @Test
    @DisplayName("UT-060: 同设备分类旧会话被清理（互斥）")
    void authenticate_shouldRemoveOldSession_whenSameCategoryExists() {
        stubSuccessfulLogin();
        // H5 分类下已存在旧会话
        when(loginSessionService.getSession(anyLong(), anyString()))
                .thenReturn(LoginUserDTO.builder().userId(1L).tenantId(1L).build());

        authenticationService.authenticate(buildRequest());

        // H5（WEB 分类）唯一同分类端点被清理
        verify(loginSessionService, atLeastOnce()).removeSession(eq(1L), eq("H5"));
    }
}
