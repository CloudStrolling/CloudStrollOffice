/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link UsernamePasswordStrategy} 的单元测试。
 *
 * <p>覆盖 UT-011~UT-013、UT-019：用户名密码认证成功、
 * 密码错误抛 LOGIN_FAILED、用户不存在抛 USER_NOT_FOUND、
 * 密码长度边界（8/64 位通过，7/65 位的 400 由 Controller 校验层覆盖）。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("UsernamePasswordStrategy 单元测试")
class UsernamePasswordStrategyTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private TenantMapper tenantMapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    private UsernamePasswordStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new UsernamePasswordStrategy(userMapper, tenantMapper, passwordEncoder);
    }

    /**
     * 构造登录请求。
     */
    private LoginRequest buildRequest(String loginName, String password) {
        LoginRequest request = new LoginRequest();
        request.setLoginMode("USERNAME_PASSWORD");
        request.setLoginName(loginName);
        request.setPassword(password);
        request.setTenantCode("DEFAULT");
        request.setClientType("H5");
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
     * 构造用户实体（密码为 BCrypt 密文）。
     */
    private UserEntity buildUser() {
        UserEntity user = new UserEntity();
        user.setId(1L);
        user.setTenantId(1L);
        user.setLoginName("admin");
        user.setUserName("管理员");
        user.setPassword("$2a$10$encryptedMock");
        user.setStatus(0);
        return user;
    }

    /**
     * UT-011：凭据正确认证成功，返回完整 AuthResult（P0）。
     */
    @Test
    @DisplayName("UT-011: 用户名密码正确时认证成功并返回角色权限")
    void authenticate_shouldReturnAuthResult_whenCredentialsValid() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectByTenantIdAndLoginName(eq(1L), eq("admin")))
                .thenReturn(buildUser());
        when(passwordEncoder.matches("admin123", "$2a$10$encryptedMock")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(1L))
                .thenReturn(Arrays.asList("admin", "user"));
        when(userMapper.selectPermissionCodesByUserId(1L))
                .thenReturn(Collections.singletonList("system:user:view"));

        AuthResult result = strategy.authenticate(buildRequest("admin", "admin123"));

        assertNotNull(result);
        assertEquals(1L, result.getUserId());
        assertEquals(1L, result.getTenantId());
        assertEquals("admin", result.getLoginName());
        assertEquals("管理员", result.getUserName());
        assertEquals(2, result.getRoles().size());
        assertEquals(1, result.getPermissions().size());
    }

    /**
     * UT-012：密码错误抛 LOGIN_FAILED（P0）。
     */
    @Test
    @DisplayName("UT-012: 密码错误抛 LOGIN_FAILED")
    void authenticate_shouldThrow_whenPasswordIncorrect() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectByTenantIdAndLoginName(eq(1L), eq("admin")))
                .thenReturn(buildUser());
        when(passwordEncoder.matches("wrong_pass", "$2a$10$encryptedMock")).thenReturn(false);

        AuthException ex = assertThrows(AuthException.class,
                () -> strategy.authenticate(buildRequest("admin", "wrong_pass")));
        assertEquals(401, ex.getCode());
    }

    /**
     * UT-013：用户不存在抛 USER_NOT_FOUND（P0）。
     */
    @Test
    @DisplayName("UT-013: 用户不存在抛 USER_NOT_FOUND")
    void authenticate_shouldThrow_whenUserNotFound() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectByTenantIdAndLoginName(eq(1L), eq("no_such_user")))
                .thenReturn(null);

        AuthException ex = assertThrows(AuthException.class,
                () -> strategy.authenticate(buildRequest("no_such_user", "any_pass")));
        assertEquals(404, ex.getCode());
    }

    /**
     * UT-019：租户不存在抛业务异常（P1）。
     */
    @Test
    @DisplayName("UT-019: 租户不存在抛业务异常")
    void authenticate_shouldThrow_whenTenantNotFound() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.authenticate(buildRequest("admin", "admin123")));
        assertEquals("租户不存在", ex.getMessage());
    }

    /**
     * UT-019：密码 8 位/64 位边界可通过认证（P1）。
     *
     * <p>说明：7 位/65 位的 400 拒绝由 Controller 层 @Valid 校验
     * 与接口测试 TC-010 覆盖，策略层仅校验非空。</p>
     */
    @Test
    @DisplayName("UT-019: 密码 8 位与 64 位边界可正常认证")
    void authenticate_shouldPass_whenPasswordAtBoundary() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(userMapper.selectByTenantIdAndLoginName(eq(1L), eq("admin")))
                .thenReturn(buildUser());
        when(passwordEncoder.matches(anyString(), eq("$2a$10$encryptedMock"))).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(1L)).thenReturn(Collections.emptyList());
        when(userMapper.selectPermissionCodesByUserId(1L)).thenReturn(Collections.emptyList());

        assertNotNull(strategy.authenticate(buildRequest("admin", "abcdefgh")));
        assertNotNull(strategy.authenticate(buildRequest("admin", "a".repeat(64))));
    }

    /**
     * UT-019：loginName/password 为空抛 IllegalArgumentException（P1）。
     */
    @Test
    @DisplayName("UT-019: loginName/password 为空被 Assert 拒绝")
    void authenticate_shouldReject_whenBlankCredential() {
        LoginRequest blankLogin = buildRequest("admin", "admin123");
        blankLogin.setLoginName("  ");
        assertThrows(IllegalArgumentException.class,
                () -> strategy.authenticate(blankLogin));

        LoginRequest blankPassword = buildRequest("admin", "admin123");
        blankPassword.setPassword(null);
        assertThrows(IllegalArgumentException.class,
                () -> strategy.authenticate(blankPassword));
    }
}
