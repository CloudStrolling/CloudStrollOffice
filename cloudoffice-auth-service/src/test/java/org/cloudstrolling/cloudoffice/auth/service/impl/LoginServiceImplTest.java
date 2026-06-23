/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.impl.DefaultClaims;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.entity.LoginLogEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.LoginLogMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginLogService;
import org.cloudstrolling.cloudoffice.auth.service.LoginService;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
import org.cloudstrolling.cloudoffice.common.enums.ClientTypeEnum;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link LoginServiceImpl} 的单元测试，覆盖 login、kickout 和 logout 方法。
 *
 * <p>使用 Mockito 模拟所有依赖，验证登录、登出和强制踢人方法的业务逻辑和边界情况。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("LoginServiceImpl 单元测试")
class LoginServiceImplTest {

    /** 模拟的用户 Mapper（查询用户、角色、权限） */
    @Mock
    private UserMapper userMapper;

    /** 模拟的租户 Mapper */
    @Mock
    private TenantMapper tenantMapper;

    /** 模拟的 Redis 登录态管理服务 */
    @Mock
    private LoginSessionService loginSessionService;

    /** 模拟的登录日志 Mapper */
    @Mock
    private LoginLogMapper loginLogMapper;

    /** 模拟的 JWT 令牌工具类 */
    @Mock
    private JwtUtils jwtUtils;

    /** 模拟的登录日志审计服务 */
    @Mock
    private LoginLogService loginLogService;

    /** 模拟的 BCrypt 密码编码器 */
    @Mock
    private PasswordEncoder passwordEncoder;

    /** 捕获插入的登录日志实体，用于验证日志内容 */
    @Captor
    private ArgumentCaptor<LoginLogEntity> logCaptor;

    /** 捕获 Long 类型参数（如黑名单 TTL），用于验证数值 */
    @Captor
    private ArgumentCaptor<Long> longCaptor;

    /** 捕获 LoginUserDTO 参数，用于验证会话内容 */
    @Captor
    private ArgumentCaptor<LoginUserDTO> loginUserCaptor;

    /** 被测试的登录业务服务实现 */
    private LoginService loginService;

    /** 模拟的 HTTP 请求，用于设置操作者上下文 */
    private MockHttpServletRequest request;

    /**
     * 测试前置初始化。
     *
     * <p>创建 {@link LoginServiceImpl} 实例并注入 Mock 依赖；
     * 设置默认的管理员操作者上下文（X-Roles 包含 admin）。</p>
     */
    @BeforeEach
    void setUp() {
        lenient().when(jwtUtils.getAccessTokenExpiration()).thenReturn(7200L);
        loginService = new LoginServiceImpl(userMapper, tenantMapper, loginSessionService,
                loginLogMapper, jwtUtils, loginLogService, passwordEncoder, 604800L);

        // 设置操作者上下文（默认管理员）
        request = new MockHttpServletRequest();
        request.addHeader("X-User-Id", "1");
        request.addHeader("X-Tenant-Id", "10");
        request.addHeader("X-User-Name", "adminUser");
        request.addHeader("X-Client-Type", "WINDOWS");
        request.addHeader("X-Roles", "admin,operator");
        request.addHeader("X-Permissions", "system:user:kickout");
        RequestContextHolder.setRequestAttributes(new ServletRequestAttributes(request));
    }

    /**
     * 测试后置清理。
     *
     * <p>重置 RequestContextHolder 中的请求属性，防止 MockHttpServletRequest
     * 的副作用污染其他测试用例的上下文。</p>
     */
    @AfterEach
    void tearDown() {
        // 清理请求上下文，防止污染其他测试
        RequestContextHolder.resetRequestAttributes();
    }

    // ==================== 登录（login）成功场景 ====================

    @Test
    @DisplayName("TC-001: 正常登录成功返回双 Token")
    void login_shouldReturnTokenPair_whenValidCredentials() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin", "user"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(List.of("system:read", "system:write"));
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token_123");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token_456");

        // When
        TokenPairDTO result = loginService.login(loginRequest);

        // Then
        assertNotNull(result);
        assertEquals("access_token_123", result.getAccessToken());
        assertEquals("refresh_token_456", result.getRefreshToken());
        assertEquals("Bearer", result.getTokenType());
        assertNotNull(result.getAccessTokenExpireIn());
        assertTrue(result.getAccessTokenExpireIn() > System.currentTimeMillis());
        assertNotNull(result.getRefreshTokenExpireIn());
        assertTrue(result.getRefreshTokenExpireIn() > System.currentTimeMillis());

        // 验证角色权限查询
        verify(userMapper).selectRoleCodesByUserId(100L);
        verify(userMapper).selectPermissionCodesByUserId(100L);

        // 验证会话创建
        verify(loginSessionService).createSession(eq(100L), eq("WINDOWS"),
                any(LoginUserDTO.class), eq(604800L));

        // 验证状态缓存
        verify(loginSessionService).setAccountStatus(100L, 0);
        verify(loginSessionService).setTenantStatus(10L, 0);

        // 验证登录日志
        verify(loginLogService).recordLoginSuccess(eq(10L), eq(100L), eq("admin"),
                anyString(), eq("WINDOWS"), isNull());

        // 验证用户表更新
        verify(userMapper).updateById(argThat(u ->
                u.getId().equals(100L)
                        && u.getLastLoginTime() != null
                        && u.getLastLoginIp() != null));
    }

    @Test
    @DisplayName("TC-002: 租户不存在时登录失败")
    void login_shouldThrowException_whenTenantNotFound() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "NOT_EXIST", "WINDOWS");
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);

        // When
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.NOT_FOUND.getCode(), exception.getCode());
        assertEquals("租户不存在", exception.getMessage());
        verify(userMapper, never()).selectByTenantIdAndLoginName(anyLong(), anyString());
    }

    @Test
    @DisplayName("TC-003: 租户已禁用时登录失败")
    void login_shouldThrowException_whenTenantDisabled() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DISABLED_TENANT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DISABLED_TENANT", 1, null);
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);

        // When
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.TENANT_DISABLED.getCode(), exception.getCode());
        assertEquals(ErrorCode.TENANT_DISABLED.getMessage(), exception.getMessage());
        verify(userMapper, never()).selectByTenantIdAndLoginName(anyLong(), anyString());
    }

    @Test
    @DisplayName("TC-004: 租户已过期时登录失败")
    void login_shouldThrowException_whenTenantExpired() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "EXPIRED_TENANT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "EXPIRED_TENANT", 0, LocalDateTime.now().minusDays(1));
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);

        // When
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.TENANT_EXPIRED.getCode(), exception.getCode());
        assertEquals(ErrorCode.TENANT_EXPIRED.getMessage(), exception.getMessage());
        verify(userMapper, never()).selectByTenantIdAndLoginName(anyLong(), anyString());
    }

    @Test
    @DisplayName("TC-005: 用户不存在时登录失败（返回 401 LOGIN_FAILED，不记录失败日志）")
    void login_shouldThrowAuthException_whenUserNotFound() {
        // Given
        LoginRequest loginRequest = createLoginRequest("nonexistent_user", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "nonexistent_user")).thenReturn(null);

        // When
        AuthException exception = assertThrows(AuthException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.LOGIN_FAILED.getCode(), exception.getCode());
        assertEquals(ErrorCode.LOGIN_FAILED.getMessage(), exception.getMessage());
        verify(loginLogService, never()).recordLoginFailure(anyString(), anyString(), anyString(), anyString());
    }

    @Test
    @DisplayName("TC-006: 密码错误时登录失败（记录失败日志）")
    void login_shouldThrowAuthException_whenPasswordMismatch() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "WrongPassword123", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");
        request.addHeader("X-Forwarded-For", "192.168.1.1");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("WrongPassword123", "bcryptPassword")).thenReturn(false);

        // When
        AuthException exception = assertThrows(AuthException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.LOGIN_FAILED.getCode(), exception.getCode());
        assertEquals(ErrorCode.LOGIN_FAILED.getMessage(), exception.getMessage());
        verify(loginLogService).recordLoginFailure(eq("admin"), anyString(), eq("WINDOWS"), eq("密码错误"));
        // 验证用户表未更新
        verify(userMapper, never()).updateById(any());
    }

    @Test
    @DisplayName("TC-007: 用户已禁用时登录失败")
    void login_shouldThrowException_whenUserDisabled() {
        // Given
        LoginRequest loginRequest = createLoginRequest("disabled_user", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "disabled_user", "已禁用用户", 1, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "disabled_user")).thenReturn(user);

        // When
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.ACCOUNT_DISABLED.getCode(), exception.getCode());
        assertEquals(ErrorCode.ACCOUNT_DISABLED.getMessage(), exception.getMessage());
        verify(passwordEncoder, never()).matches(anyString(), anyString());
    }

    @Test
    @DisplayName("TC-008: 用户已锁定时登录失败")
    void login_shouldThrowException_whenUserLocked() {
        // Given
        LoginRequest loginRequest = createLoginRequest("locked_user", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "locked_user", "已锁定用户", 2, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "locked_user")).thenReturn(user);

        // When
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.ACCOUNT_LOCKED.getCode(), exception.getCode());
        assertEquals(ErrorCode.ACCOUNT_LOCKED.getMessage(), exception.getMessage());
        verify(passwordEncoder, never()).matches(anyString(), anyString());
    }

    @Test
    @DisplayName("TC-009: 用户已封禁时登录失败")
    void login_shouldThrowException_whenUserBanned() {
        // Given
        LoginRequest loginRequest = createLoginRequest("banned_user", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "banned_user", "已封禁用户", 3, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "banned_user")).thenReturn(user);

        // When
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.ACCOUNT_BANNED.getCode(), exception.getCode());
        assertEquals(ErrorCode.ACCOUNT_BANNED.getMessage(), exception.getMessage());
        verify(passwordEncoder, never()).matches(anyString(), anyString());
    }

    @Test
    @DisplayName("TC-010: 同端互斥 — 清理同设备分类旧会话")
    void login_shouldRemoveOldSession_whenSameDeviceCategory() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        // 已有同PC分类的 UBUNTU 旧会话
        LoginUserDTO oldUbuntuSession = LoginUserDTO.builder()
                .userId(100L).tenantId(10L).userName("admin").clientType("UBUNTU").build();

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(new ArrayList<>());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token");

        // 模拟 UBUNTU 和 WINDOWS 的旧会话存在
        when(loginSessionService.getSession(100L, "WINDOWS")).thenReturn(null);
        when(loginSessionService.getSession(100L, "UBUNTU")).thenReturn(oldUbuntuSession);

        // When
        TokenPairDTO result = loginService.login(loginRequest);

        // Then
        assertNotNull(result);
        // 验证同分类的 UBUNTU 会话被清理
        verify(loginSessionService).removeSession(100L, "UBUNTU");
        // 验证 WINDOWS 无旧会话，未调用 removeSession
        verify(loginSessionService, never()).removeSession(100L, "WINDOWS");
        // 验证新会话创建
        verify(loginSessionService).createSession(eq(100L), eq("WINDOWS"),
                any(LoginUserDTO.class), eq(604800L));
    }

    @Test
    @DisplayName("TC-011: 多端共存 — 不同设备分类互不影响")
    void login_shouldNotRemoveOldSession_whenDifferentDeviceCategory() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "H5");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        // 已有 PC 分类（WINDOWS）的旧会话，但 H5 是 WEB 分类
        LoginUserDTO oldWindowsSession = LoginUserDTO.builder()
                .userId(100L).tenantId(10L).userName("admin").clientType("WINDOWS").build();

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(new ArrayList<>());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token");

        // WINDOWS 会话存在，但 H5 是 WEB 类，不同分类
        when(loginSessionService.getSession(100L, "H5")).thenReturn(null);

        // When
        TokenPairDTO result = loginService.login(loginRequest);

        // Then
        assertNotNull(result);
        // H5 登录不会清理 WINDOWS 会话（不同分类）
        verify(loginSessionService, never()).removeSession(eq(100L), eq("WINDOWS"));
        // H5 会话创建
        verify(loginSessionService).createSession(eq(100L), eq("H5"),
                any(LoginUserDTO.class), eq(604800L));
    }

    @Test
    @DisplayName("TC-012: 无效 clientType 时登录失败")
    void login_shouldThrowException_whenInvalidClientType() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "INVALID_TYPE");

        // When
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.login(loginRequest));

        // Then
        assertEquals(ErrorCode.CLIENT_TYPE_INVALID.getCode(), exception.getCode());
        assertEquals(ErrorCode.CLIENT_TYPE_INVALID.getMessage(), exception.getMessage());
        verify(tenantMapper, never()).selectOne(any());
    }

    @Test
    @DisplayName("TC-014: Redis 异常降级 — 不因 Redis 异常中断登录")
    void login_shouldSucceed_whenRedisThrowsException() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(new ArrayList<>());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token");

        // Redis 操作抛出异常
        doThrow(new RuntimeException("Redis connection failed"))
                .when(loginSessionService).createSession(anyLong(), anyString(), any(LoginUserDTO.class), anyLong());

        // When - should not throw
        TokenPairDTO result = loginService.login(loginRequest);

        // Then - login still succeeds
        assertNotNull(result);
        verify(loginLogService).recordLoginSuccess(anyLong(), anyLong(), anyString(),
                anyString(), anyString(), isNull());
        verify(userMapper).updateById(any());
    }

    @Test
    @DisplayName("TC-017: 密码为空时抛出 IllegalArgumentException")
    void login_shouldThrowException_whenPasswordIsEmpty() {
        // Given
        LoginRequest requestWithNullPassword = createLoginRequest("admin", null, "DEFAULT", "WINDOWS");
        LoginRequest requestWithEmptyPassword = createLoginRequest("admin", "", "DEFAULT", "WINDOWS");

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithNullPassword));
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithEmptyPassword));
    }

    @Test
    @DisplayName("TC-018: loginName 为空时抛出 IllegalArgumentException")
    void login_shouldThrowException_whenLoginNameIsEmpty() {
        // Given
        LoginRequest requestWithNullLoginName = createLoginRequest(null, "Abc12345", "DEFAULT", "WINDOWS");
        LoginRequest requestWithEmptyLoginName = createLoginRequest("", "Abc12345", "DEFAULT", "WINDOWS");

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithNullLoginName));
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithEmptyLoginName));
    }

    @Test
    @DisplayName("TC-019: tenantCode 为空时抛出 IllegalArgumentException")
    void login_shouldThrowException_whenTenantCodeIsEmpty() {
        // Given
        LoginRequest requestWithNullTenantCode = createLoginRequest("admin", "Abc12345", null, "WINDOWS");
        LoginRequest requestWithEmptyTenantCode = createLoginRequest("admin", "Abc12345", "", "WINDOWS");

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithNullTenantCode));
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithEmptyTenantCode));
    }

    @Test
    @DisplayName("TC-020: clientType 为空时抛出 IllegalArgumentException")
    void login_shouldThrowException_whenClientTypeIsEmpty() {
        // Given
        LoginRequest requestWithNullClientType = createLoginRequest("admin", "Abc12345", "DEFAULT", null);
        LoginRequest requestWithEmptyClientType = createLoginRequest("admin", "Abc12345", "DEFAULT", "");

        // When & Then
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithNullClientType));
        assertThrows(IllegalArgumentException.class, () -> loginService.login(requestWithEmptyClientType));
    }

    @Test
    @DisplayName("TC-021: 密码错误时用户表未更新")
    void login_shouldNotUpdateUser_whenPasswordMismatch() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "WrongPassword", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("WrongPassword", "bcryptPassword")).thenReturn(false);

        // When & Then
        assertThrows(AuthException.class, () -> loginService.login(loginRequest));
        verify(userMapper, never()).updateById(any());
    }

    @Test
    @DisplayName("TC-022: 登录成功后更新用户表的 last_login_time 和 last_login_ip")
    void login_shouldUpdateLastLoginTimeAndIp_whenSuccess() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");
        request.addHeader("X-Forwarded-For", "192.168.1.100");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(new ArrayList<>());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token");

        // When
        loginService.login(loginRequest);

        // Then
        ArgumentCaptor<UserEntity> userCaptor = ArgumentCaptor.forClass(UserEntity.class);
        verify(userMapper).updateById(userCaptor.capture());
        UserEntity updatedUser = userCaptor.getValue();

        assertNotNull(updatedUser.getLastLoginTime());
        assertEquals("192.168.1.100", updatedUser.getLastLoginIp());
    }

    @Test
    @DisplayName("TC-029: 无旧会话时同端互斥逻辑跳过")
    void login_shouldSkipMutualExclusion_whenNoOldSession() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(new ArrayList<>());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token");

        // 所有旧会话均为 null
        when(loginSessionService.getSession(anyLong(), anyString())).thenReturn(null);

        // When
        TokenPairDTO result = loginService.login(loginRequest);

        // Then
        assertNotNull(result);
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        verify(loginSessionService).createSession(eq(100L), eq("WINDOWS"),
                any(LoginUserDTO.class), eq(604800L));
    }

    @Test
    @DisplayName("TC-028: 同端互斥时仅清理同设备分类的旧会话")
    void login_shouldOnlyRemoveSameCategorySessions_whenMutualExclusion() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        // 已有 UBUNTU（PC 类）的会话（ANDROID 是 MOBILE 类，不会被交互）
        LoginUserDTO ubuntuSession = LoginUserDTO.builder()
                .userId(100L).tenantId(10L).userName("admin").clientType("UBUNTU").build();

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(new ArrayList<>());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token");

        // WINDOWS 无旧会话, UBUNTU（同分类 PC）有旧会话
        when(loginSessionService.getSession(100L, "WINDOWS")).thenReturn(null);
        when(loginSessionService.getSession(100L, "UBUNTU")).thenReturn(ubuntuSession);

        // When
        TokenPairDTO result = loginService.login(loginRequest);

        // Then
        assertNotNull(result);
        // 同分类（PC）的 UBUNTU 会话被清理
        verify(loginSessionService).removeSession(100L, "UBUNTU");
        // 不同分类（MOBILE）的 ANDROID 会话未被清理（由于不同分类，getSession 不会被调用）
        verify(loginSessionService, never()).removeSession(100L, "ANDROID");
    }

    @Test
    @DisplayName("TC-015: 登录成功日志记录验证")
    void login_shouldRecordLoginSuccessLog() {
        // Given
        LoginRequest loginRequest = createLoginRequest("admin", "Abc12345", "DEFAULT", "WINDOWS");
        TenantEntity tenant = createTenant(10L, "DEFAULT", 0, null);
        UserEntity user = createUser(100L, 10L, "admin", "管理员", 0, "bcryptPassword");

        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(tenant);
        when(userMapper.selectByTenantIdAndLoginName(10L, "admin")).thenReturn(user);
        when(passwordEncoder.matches("Abc12345", "bcryptPassword")).thenReturn(true);
        when(userMapper.selectRoleCodesByUserId(100L)).thenReturn(List.of("admin"));
        when(userMapper.selectPermissionCodesByUserId(100L)).thenReturn(new ArrayList<>());
        when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("access_token");
        when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("refresh_token");

        // When
        loginService.login(loginRequest);

        // Then
        verify(loginLogService, times(1)).recordLoginSuccess(
                eq(10L), eq(100L), eq("admin"),
                anyString(), eq("WINDOWS"), isNull());
    }

    // ==================== 登出（logout）测试 ====================

    @Test
    @DisplayName("登出成功：有效 Token 完成全流程清理")
    void logout_shouldCompleteFullFlow_whenValidToken() {
        // Given
        String accessToken = "validAccessToken";
        String clientType = "WINDOWS";
        Long userId = 1L;
        String signature = "abcdef1234567890";

        Claims claims = createClaims(userId, 7200000L); // 2 hours remaining
        when(jwtUtils.parseAccessToken(accessToken)).thenReturn(claims);
        when(jwtUtils.getTokenSignature(accessToken)).thenReturn(signature);

        // When
        loginService.logout(accessToken, clientType);

        // Then
        verify(jwtUtils).parseAccessToken(accessToken);
        verify(jwtUtils).getTokenSignature(accessToken);
        verify(loginSessionService).addToBlacklist(eq(signature), anyLong());
        verify(loginSessionService).removeSession(userId, clientType);
        verify(loginLogService).updateLogoutTime(userId, clientType);
    }

    @Test
    @DisplayName("登出成功：黑名单 TTL 为 Token 剩余有效期")
    void logout_shouldSetBlacklistTtlToTokenRemainingTime() {
        // Given
        String accessToken = "validAccessToken";
        String clientType = "WINDOWS";
        Long userId = 1L;
        String signature = "signature123";

        // Token 剩余 3600 秒（1 小时）
        Claims claims = createClaims(userId, 3600000L);
        when(jwtUtils.parseAccessToken(accessToken)).thenReturn(claims);
        when(jwtUtils.getTokenSignature(accessToken)).thenReturn(signature);

        // When
        loginService.logout(accessToken, clientType);

        // Then
        // 验证 TTL 约为 3600 秒（允许 ±2 秒的测试执行时间差）
        verify(loginSessionService).addToBlacklist(eq(signature), longCaptor.capture());
        long actualTtl = longCaptor.getValue();
        assertTrue(actualTtl >= 3598L && actualTtl <= 3600L,
                "Expected TTL ~3600s but got " + actualTtl);
    }

    @Test
    @DisplayName("登出成功：Token 剩余 0 秒时最小 TTL 为 1 秒")
    void logout_shouldUseMinTtl_whenTokenExpiring() {
        // Given
        String accessToken = "expiringToken";
        String clientType = "H5";
        Long userId = 2L;
        String signature = "signature456";

        // Token 将在 500ms 后过期（剩余 0 秒）
        Claims claims = createClaims(userId, 500L);
        when(jwtUtils.parseAccessToken(accessToken)).thenReturn(claims);
        when(jwtUtils.getTokenSignature(accessToken)).thenReturn(signature);

        // When
        loginService.logout(accessToken, clientType);

        // Then
        verify(loginSessionService).addToBlacklist(signature, 1L);
    }

    @Test
    @DisplayName("重复登出：Token 无效时不抛出异常（幂等）")
    void logout_shouldNotThrow_whenTokenIsInvalid() {
        // Given
        String accessToken = "invalidToken";
        String clientType = "WINDOWS";

        when(jwtUtils.parseAccessToken(accessToken))
                .thenThrow(new RuntimeException("Token invalid or expired"));

        // When - should not throw
        assertDoesNotThrow(() -> loginService.logout(accessToken, clientType));

        // Then
        verify(jwtUtils).parseAccessToken(accessToken);
        verify(jwtUtils, never()).getTokenSignature(anyString());
        verify(loginSessionService, never()).addToBlacklist(anyString(), anyLong());
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        verify(loginLogService, never()).updateLogoutTime(anyLong(), anyString());
    }

    @Test
    @DisplayName("重复登出：黑名单添加失败时仍完成后续清理")
    void logout_shouldContinueCleanup_whenBlacklistFails() {
        // Given
        String accessToken = "validToken";
        String clientType = "WINDOWS";
        Long userId = 1L;
        String signature = "sig789";

        Claims claims = createClaims(userId, 7200000L);
        when(jwtUtils.parseAccessToken(accessToken)).thenReturn(claims);
        when(jwtUtils.getTokenSignature(accessToken)).thenReturn(signature);
        doThrow(new RuntimeException("Redis error")).when(loginSessionService)
                .addToBlacklist(anyString(), anyLong());

        // When - should not throw
        assertDoesNotThrow(() -> loginService.logout(accessToken, clientType));

        // Then - still attempts session removal and log update
        verify(loginSessionService).removeSession(userId, clientType);
        verify(loginLogService).updateLogoutTime(userId, clientType);
    }

    @Test
    @DisplayName("登出：accessToken 为 null 时不抛出异常")
    void logout_shouldNotThrow_whenAccessTokenIsNull() {
        assertDoesNotThrow(() -> loginService.logout(null, "WINDOWS"));
    }

    @Test
    @DisplayName("登出：clientType 为 null 时不抛出异常")
    void logout_shouldNotThrow_whenClientTypeIsNull() {
        assertDoesNotThrow(() -> loginService.logout("someToken", null));
    }

    // ==================== 踢人（kickout）成功场景 ====================

    @Test
    @DisplayName("踢人成功：管理员踢指定客户端类型")
    void kickout_adminUserKickSpecificClientType_success() {
        // Given
        Long targetUserId = 2L;
        String clientType = "WINDOWS";
        setupTargetUserExists(targetUserId);

        LoginUserDTO session = LoginUserDTO.builder()
                .userId(targetUserId)
                .tenantId(10L)
                .userName("targetUser")
                .clientType(clientType)
                .build();
        when(loginSessionService.getSession(targetUserId, clientType)).thenReturn(session);

        // When
        loginService.kickout(targetUserId, clientType);

        // Then
        // 验证指定端的登录态被删除
        verify(loginSessionService).removeSession(targetUserId, clientType);
        // 验证未调用删除所有端
        verify(loginSessionService, never()).removeAllSessions(anyLong());
        // 验证审计日志记录
        verify(loginLogMapper).insert(logCaptor.capture());
        LoginLogEntity logEntity = logCaptor.getValue();
        assertEquals(targetUserId, logEntity.getUserId());
        assertEquals(clientType, logEntity.getClientType());
        assertEquals(2, logEntity.getLoginResult());
        assertTrue(logEntity.getFailReason().contains("强制踢人"));
    }

    @Test
    @DisplayName("踢人成功：管理员踢所有端（clientType 为空）")
    void kickout_adminUserKickAllClientTypes_success() {
        // Given
        Long targetUserId = 2L;
        String clientType = null;  // 踢所有端
        setupTargetUserExists(targetUserId);

        // When
        loginService.kickout(targetUserId, clientType);

        // Then
        // 验证所有端的登录态被删除
        verify(loginSessionService).removeAllSessions(targetUserId);
        // 验证未调用删除指定端
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        // 验证审计日志记录
        verify(loginLogMapper).insert(logCaptor.capture());
        LoginLogEntity logEntity = logCaptor.getValue();
        assertEquals(targetUserId, logEntity.getUserId());
        assertEquals("ALL", logEntity.getClientType());
        assertEquals(2, logEntity.getLoginResult());
    }

    @Test
    @DisplayName("踢人成功：空字符串 clientType 也视为踢所有端")
    void kickout_adminUserKickWithEmptyClientType_success() {
        // Given
        Long targetUserId = 2L;
        String clientType = "";  // 空字符串，踢所有端
        setupTargetUserExists(targetUserId);

        // When
        loginService.kickout(targetUserId, clientType);

        // Then
        verify(loginSessionService).removeAllSessions(targetUserId);
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        verify(loginLogMapper).insert(any(LoginLogEntity.class));
    }

    @Test
    @DisplayName("踢人成功：目标用户无活跃会话时仍返回成功")
    void kickout_userWithoutSession_success() {
        // Given
        Long targetUserId = 2L;
        String clientType = "H5";
        setupTargetUserExists(targetUserId);
        when(loginSessionService.getSession(targetUserId, clientType)).thenReturn(null);

        // When
        loginService.kickout(targetUserId, clientType);

        // Then
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        verify(loginLogMapper).insert(any(LoginLogEntity.class));
    }

    // ==================== 踢人异常场景 ====================

    @Test
    @DisplayName("踢人失败：非管理员操作返回 403 PERMISSION_DENIED")
    void kickout_nonAdminUser_throwsPermissionDenied() {
        // Given
        // 将操作者角色改为非管理员
        request.removeHeader("X-Roles");
        request.addHeader("X-Roles", "user,operator");

        Long targetUserId = 2L;

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.kickout(targetUserId, "WINDOWS"));
        assertEquals(ErrorCode.PERMISSION_DENIED.getCode(), exception.getCode());
        assertEquals(ErrorCode.PERMISSION_DENIED.getMessage(), exception.getMessage());
        // 验证未执行任何踢人操作
        verify(userMapper, never()).selectById(anyLong());
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        verify(loginSessionService, never()).removeAllSessions(anyLong());
        verify(loginLogMapper, never()).insert(any());
    }

    @Test
    @DisplayName("踢人失败：无请求上下文时返回 403 PERMISSION_DENIED")
    void kickout_noRequestContext_throwsPermissionDenied() {
        // Given
        // 清除请求上下文
        RequestContextHolder.resetRequestAttributes();
        Long targetUserId = 2L;

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.kickout(targetUserId, "WINDOWS"));
        assertEquals(ErrorCode.PERMISSION_DENIED.getCode(), exception.getCode());
    }

    @Test
    @DisplayName("踢人失败：目标用户不存在返回 404 USER_NOT_FOUND")
    void kickout_targetUserNotFound_throwsUserNotFound() {
        // Given
        Long targetUserId = 999L;
        when(userMapper.selectById(targetUserId)).thenReturn(null);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.kickout(targetUserId, "WINDOWS"));
        assertEquals(ErrorCode.USER_NOT_FOUND.getCode(), exception.getCode());
        assertEquals(ErrorCode.USER_NOT_FOUND.getMessage(), exception.getMessage());
        // 验证未操作会话
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        verify(loginSessionService, never()).removeAllSessions(anyLong());
        verify(loginLogMapper, never()).insert(any());
    }

    @Test
    @DisplayName("踢人失败：指定无效 clientType 返回 400 CLIENT_TYPE_INVALID")
    void kickout_invalidClientType_throwsClientTypeInvalid() {
        // Given
        Long targetUserId = 2L;
        String invalidClientType = "INVALID_TYPE";
        setupTargetUserExists(targetUserId);

        // When & Then
        BusinessException exception = assertThrows(BusinessException.class,
                () -> loginService.kickout(targetUserId, invalidClientType));
        assertEquals(ErrorCode.CLIENT_TYPE_INVALID.getCode(), exception.getCode());
        // 验证未操作会话
        verify(loginSessionService, never()).removeSession(anyLong(), anyString());
        verify(loginSessionService, never()).removeAllSessions(anyLong());
    }

    @Test
    @DisplayName("踢人失败：targetUserId 为 null 时抛出 IllegalArgumentException")
    void kickout_nullTargetUserId_throwsIllegalArgumentException() {
        assertThrows(IllegalArgumentException.class,
                () -> loginService.kickout(null, "WINDOWS"));
    }

    // ==================== 审计日志异常处理 ====================

    @Test
    @DisplayName("踢人成功：审计日志写入失败不影响主流程")
    void kickout_auditLogWriteFailure_shouldNotAffectKickout() {
        // Given
        Long targetUserId = 2L;
        String clientType = "WINDOWS";
        setupTargetUserExists(targetUserId);

        LoginUserDTO session = LoginUserDTO.builder()
                .userId(targetUserId)
                .build();
        when(loginSessionService.getSession(targetUserId, clientType)).thenReturn(session);

        // 模拟日志写入抛出异常
        doThrow(new RuntimeException("数据库连接失败"))
                .when(loginLogMapper).insert(any(LoginLogEntity.class));

        // When (不应抛出异常)
        assertDoesNotThrow(() -> loginService.kickout(targetUserId, clientType));

        // Then - 踢人操作已正常执行
        verify(loginSessionService).removeSession(targetUserId, clientType);
        // 验证 insert 被调用过（虽然失败了）
        verify(loginLogMapper).insert(any(LoginLogEntity.class));
    }

    // ==================== 辅助方法 ====================

    /**
     * 创建测试用登录请求。
     */
    private LoginRequest createLoginRequest(String loginName, String password,
                                            String tenantCode, String clientType) {
        LoginRequest request = new LoginRequest();
        request.setLoginName(loginName);
        request.setPassword(password);
        request.setTenantCode(tenantCode);
        request.setClientType(clientType);
        return request;
    }

    /**
     * 创建测试用租户实体。
     */
    private TenantEntity createTenant(Long id, String tenantCode,
                                      Integer status, LocalDateTime expireTime) {
        TenantEntity tenant = new TenantEntity();
        tenant.setId(id);
        tenant.setTenantCode(tenantCode);
        tenant.setTenantName("测试租户");
        tenant.setStatus(status);
        tenant.setExpireTime(expireTime);
        return tenant;
    }

    /**
     * 创建测试用用户实体。
     */
    private UserEntity createUser(Long id, Long tenantId, String loginName,
                                  String userName, Integer status, String password) {
        UserEntity user = new UserEntity();
        user.setId(id);
        user.setTenantId(tenantId);
        user.setLoginName(loginName);
        user.setUserName(userName);
        user.setStatus(status);
        user.setPassword(password);
        return user;
    }

    /**
     * 创建测试用 Claims。
     *
     * @param userId                   用户 ID
     * @param expirationOffsetMillis   从当前时间到过期的偏移毫秒数
     * @return JWT Claims
     */
    private Claims createClaims(Long userId, long expirationOffsetMillis) {
        Claims claims = mock(Claims.class);
        lenient().when(claims.getSubject()).thenReturn(String.valueOf(userId));
        lenient().when(claims.getExpiration())
                .thenReturn(new Date(System.currentTimeMillis() + expirationOffsetMillis));
        return claims;
    }

    /**
     * 设置目标用户存在。
     */
    private void setupTargetUserExists(Long userId) {
        UserEntity user = new UserEntity();
        user.setId(userId);
        user.setLoginName("targetUser");
        user.setStatus(0);
        when(userMapper.selectById(userId)).thenReturn(user);
    }
}
