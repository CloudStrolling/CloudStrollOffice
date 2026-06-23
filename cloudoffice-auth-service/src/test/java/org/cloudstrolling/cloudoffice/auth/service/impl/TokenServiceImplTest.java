/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.security.SignatureException;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.service.TokenService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.mockito.junit.jupiter.MockitoSettings;
import org.mockito.quality.Strictness;

import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link TokenServiceImpl} 的单元测试。
 *
 * <p>测试 Refresh Token 轮换机制的完整业务逻辑，
 * 包括正常刷新、Token 过期、黑名单校验、账号/租户状态校验等场景。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@MockitoSettings(strictness = Strictness.LENIENT)
@DisplayName("TokenServiceImpl 单元测试")
class TokenServiceImplTest {

    /** 测试用 Access Token 有效期（2 小时，单位秒） */
    private static final long ACCESS_TOKEN_EXPIRATION = 7200L;

    /** 测试用 Refresh Token 有效期（7 天，单位秒） */
    private static final long REFRESH_TOKEN_EXPIRATION = 604800L;

    @Mock
    private JwtUtils jwtUtils;

    @Mock
    private LoginSessionService loginSessionService;

    @Mock
    private UserMapper userMapper;

    @Mock
    private TenantMapper tenantMapper;

    @Captor
    private ArgumentCaptor<String> stringCaptor;

    @Captor
    private ArgumentCaptor<Long> longCaptor;

    private TokenService tokenService;

    /** 测试用户实体 */
    private UserEntity normalUser;

    /** 测试租户实体 */
    private TenantEntity normalTenant;

    /** 测试用 Claims（模拟 Refresh Token 解析结果） */
    private Claims mockClaims;

    @BeforeEach
    void setUp() {
        tokenService = new TokenServiceImpl(
                jwtUtils, loginSessionService, userMapper, tenantMapper,
                ACCESS_TOKEN_EXPIRATION, REFRESH_TOKEN_EXPIRATION);

        // 初始化正常用户（status=0 正常，deleted=0 未删除）
        normalUser = new UserEntity();
        normalUser.setId(1001L);
        normalUser.setTenantId(10L);
        normalUser.setLoginName("testUser");
        normalUser.setStatus(0);
        normalUser.setDeleted(0);

        // 初始化正常租户（status=0 正常，deleted=0 未删除）
        normalTenant = new TenantEntity();
        normalTenant.setId(10L);
        normalTenant.setTenantName("测试租户");
        normalTenant.setTenantCode("test");
        normalTenant.setStatus(0);
        normalTenant.setDeleted(0);

        // 模拟 Claims（模拟 ParseRefreshToken 返回）
        mockClaims = mock(Claims.class);
        when(mockClaims.getSubject()).thenReturn("1001");
        when(mockClaims.get("tenantId", Long.class)).thenReturn(10L);
        when(mockClaims.get("clientType", String.class)).thenReturn("WINDOWS");
        when(mockClaims.getExpiration()).thenReturn(new Date(System.currentTimeMillis() + 3600_000));
    }

    // ==================== 正常刷新流程 ====================

    @Nested
    @DisplayName("正常刷新流程")
    class HappyPath {

        @Test
        @DisplayName("有效 Refresh Token 应返回新的 TokenPairDTO")
        void refresh_validRefreshToken_shouldReturnNewTokenPair() {
            // Given
            String refreshToken = "valid.refresh.token";
            String clientType = "WINDOWS";
            String tokenSignature = "abcdef1234567890";
            String newAccessToken = "new.access.token";
            String newRefreshToken = "new.refresh.token";

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(normalTenant);
            when(userMapper.selectRoleCodesByUserId(1001L)).thenReturn(List.of("admin", "user"));
            when(userMapper.selectPermissionCodesByUserId(1001L)).thenReturn(List.of("system:user:list"));
            when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn(newAccessToken);
            when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn(newRefreshToken);

            // When
            TokenPairDTO result = tokenService.refresh(refreshToken, clientType);

            // Then
            assertNotNull(result, "返回的 TokenPairDTO 不应为空");
            assertEquals(newAccessToken, result.getAccessToken(), "Access Token 应与模拟值一致");
            assertEquals(newRefreshToken, result.getRefreshToken(), "Refresh Token 应与模拟值一致");
            assertEquals("Bearer", result.getTokenType(), "tokenType 应为 Bearer");
            assertNotNull(result.getAccessTokenExpireIn(), "accessTokenExpireIn 不应为空");
            assertNotNull(result.getRefreshTokenExpireIn(), "refreshTokenExpireIn 不应为空");
            assertTrue(result.getAccessTokenExpireIn() > System.currentTimeMillis(),
                    "Access Token 过期时间应在未来");
            assertTrue(result.getRefreshTokenExpireIn() > System.currentTimeMillis(),
                    "Refresh Token 过期时间应在未来");
        }

        @Test
        @DisplayName("刷新成功后旧 Token 应加入黑名单并更新会话")
        void refresh_shouldAddOldTokenToBlacklistAndUpdateSession() {
            // Given
            String refreshToken = "valid.refresh.token";
            String clientType = "WINDOWS";
            String tokenSignature = "abcdef1234567890";

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(normalTenant);
            when(userMapper.selectRoleCodesByUserId(1001L)).thenReturn(List.of("admin"));
            when(userMapper.selectPermissionCodesByUserId(1001L)).thenReturn(List.of());
            when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("new.access.token");
            when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("new.refresh.token");

            // When
            tokenService.refresh(refreshToken, clientType);

            // Then: 验证旧 Token 被加入黑名单
            verify(loginSessionService).addToBlacklist(stringCaptor.capture(), longCaptor.capture());
            assertEquals(tokenSignature, stringCaptor.getValue(), "应使用旧 Token 的签名指纹加入黑名单");
            assertTrue(longCaptor.getValue() > 0, "黑名单 TTL 应大于 0");

            // Then: 验证旧会话被删除，新会话被创建
            verify(loginSessionService).removeSession(1001L, "WINDOWS");
            verify(loginSessionService).createSession(eq(1001L), eq("WINDOWS"),
                    any(LoginUserDTO.class), eq(REFRESH_TOKEN_EXPIRATION));

            // Then: 验证用户角色和权限被查询
            verify(userMapper).selectRoleCodesByUserId(1001L);
            verify(userMapper).selectPermissionCodesByUserId(1001L);
        }

        @Test
        @DisplayName("刷新时应使用正确的 LoginUserDTO 生成新 Token")
        void refresh_shouldBuildCorrectLoginUserDTO() {
            // Given
            String refreshToken = "valid.refresh.token";
            String clientType = "WINDOWS";
            String tokenSignature = "sig123";

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(normalTenant);
            when(userMapper.selectRoleCodesByUserId(1001L)).thenReturn(List.of("admin"));
            when(userMapper.selectPermissionCodesByUserId(1001L)).thenReturn(List.of());

            ArgumentCaptor<LoginUserDTO> loginUserCaptor = ArgumentCaptor.forClass(LoginUserDTO.class);
            when(jwtUtils.generateAccessToken(loginUserCaptor.capture())).thenReturn("new.access.token");
            when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("new.refresh.token");

            // When
            tokenService.refresh(refreshToken, clientType);

            // Then
            LoginUserDTO capturedLoginUser = loginUserCaptor.getValue();
            assertNotNull(capturedLoginUser, "LoginUserDTO 不应为空");
            assertEquals(1001L, capturedLoginUser.getUserId(), "userId 应正确");
            assertEquals(10L, capturedLoginUser.getTenantId(), "tenantId 应正确");
            assertEquals("testUser", capturedLoginUser.getUserName(), "userName 应正确");
            assertEquals("WINDOWS", capturedLoginUser.getClientType(), "clientType 应从 Claims 中提取");
            assertEquals(1, capturedLoginUser.getRoles().size(), "roles 应包含 1 个元素");
            assertTrue(capturedLoginUser.getRoles().contains("admin"), "roles 应包含 admin");
        }
    }

    // ==================== Token 过期场景 ====================

    @Nested
    @DisplayName("Token 过期场景")
    class TokenExpired {

        @Test
        @DisplayName("过期 Refresh Token 应抛出 AuthException（REFRESH_TOKEN_EXPIRED）")
        void refresh_expiredRefreshToken_shouldThrowAuthException() {
            // Given
            String refreshToken = "expired.refresh.token";
            when(jwtUtils.parseRefreshToken(refreshToken))
                    .thenThrow(new ExpiredJwtException(null, null, "Token expired"));

            // When/Then
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.REFRESH_TOKEN_EXPIRED.getCode(), exception.getCode(),
                    "错误码应为 REFRESH_TOKEN_EXPIRED");
            assertEquals(ErrorCode.REFRESH_TOKEN_EXPIRED.getMessage(), exception.getMessage(),
                    "错误消息应与 REFRESH_TOKEN_EXPIRED 一致");
        }

        @Test
        @DisplayName("签名无效的 Refresh Token 应抛出 AuthException（REFRESH_TOKEN_INVALID）")
        void refresh_invalidSignature_shouldThrowAuthException() {
            // Given
            String refreshToken = "bad.signature.token";
            when(jwtUtils.parseRefreshToken(refreshToken))
                    .thenThrow(new SignatureException("Signature does not match"));

            // When/Then
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.REFRESH_TOKEN_INVALID.getCode(), exception.getCode(),
                    "错误码应为 REFRESH_TOKEN_INVALID");
        }

        @Test
        @DisplayName("格式错误的 Refresh Token 应抛出 AuthException（REFRESH_TOKEN_INVALID）")
        void refresh_malformedToken_shouldThrowAuthException() {
            // Given
            String refreshToken = "malformed.token";
            when(jwtUtils.parseRefreshToken(refreshToken))
                    .thenThrow(new MalformedJwtException("Malformed token"));

            // When/Then
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.REFRESH_TOKEN_INVALID.getCode(), exception.getCode(),
                    "错误码应为 REFRESH_TOKEN_INVALID");
        }

        @Test
        @DisplayName("Access Token 冒充 Refresh Token 应抛出 AuthException（REFRESH_TOKEN_INVALID）")
        void refresh_accessTokenUsedAsRefresh_shouldThrowAuthException() {
            // Given
            String accessToken = "access.token.used.as.refresh";
            when(jwtUtils.parseRefreshToken(accessToken))
                    .thenThrow(new JwtException("Invalid token type: expected 'refresh' but got 'access'"));

            // When/Then
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(accessToken, "WINDOWS"));
            assertEquals(ErrorCode.REFRESH_TOKEN_INVALID.getCode(), exception.getCode(),
                    "错误码应为 REFRESH_TOKEN_INVALID");
        }
    }

    // ==================== 黑名单场景 ====================

    @Nested
    @DisplayName("黑名单场景")
    class Blacklist {

        @Test
        @DisplayName("黑名单中的 Refresh Token 应抛出 AuthException（TOKEN_BLACKLISTED）")
        void refresh_blacklistedToken_shouldThrowAuthException() {
            // Given
            String refreshToken = "blacklisted.refresh.token";
            String tokenSignature = "blacklistedSignature";

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(true);

            // When/Then
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.TOKEN_BLACKLISTED.getCode(), exception.getCode(),
                    "错误码应为 TOKEN_BLACKLISTED");
            assertEquals(ErrorCode.TOKEN_BLACKLISTED.getMessage(), exception.getMessage(),
                    "错误消息应与 TOKEN_BLACKLISTED 一致");

            // Then: 不应继续后续查询
            verify(userMapper, never()).selectById(anyLong());
            verify(tenantMapper, never()).selectById(anyLong());
        }
    }

    // ==================== 账号状态场景 ====================

    @Nested
    @DisplayName("账号状态场景")
    class AccountStatus {

        @Test
        @DisplayName("用户不存在时抛出 AuthException（USER_NOT_FOUND）")
        void refresh_userNotFound_shouldThrowAuthException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(null);

            // When/Then
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.USER_NOT_FOUND.getCode(), exception.getCode(),
                    "错误码应为 USER_NOT_FOUND");
        }

        @Test
        @DisplayName("被封禁的账号应抛出 BusinessException（ACCOUNT_BANNED）")
        void refresh_bannedAccount_shouldThrowBusinessException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            UserEntity bannedUser = new UserEntity();
            bannedUser.setId(1001L);
            bannedUser.setTenantId(10L);
            bannedUser.setStatus(3); // 封禁
            bannedUser.setDeleted(0);

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(bannedUser);

            // When/Then
            BusinessException exception = assertThrows(BusinessException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.ACCOUNT_BANNED.getCode(), exception.getCode(),
                    "错误码应为 ACCOUNT_BANNED");
            assertEquals(ErrorCode.ACCOUNT_BANNED.getMessage(), exception.getMessage(),
                    "错误消息应与 ACCOUNT_BANNED 一致");

            // Then: 不应继续查询租户
            verify(tenantMapper, never()).selectById(anyLong());
        }

        @Test
        @DisplayName("被禁用的账号应抛出 BusinessException（ACCOUNT_DISABLED）")
        void refresh_disabledAccount_shouldThrowBusinessException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            UserEntity disabledUser = new UserEntity();
            disabledUser.setId(1001L);
            disabledUser.setTenantId(10L);
            disabledUser.setStatus(1); // 禁用
            disabledUser.setDeleted(0);

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(disabledUser);

            // When/Then
            BusinessException exception = assertThrows(BusinessException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.ACCOUNT_DISABLED.getCode(), exception.getCode(),
                    "错误码应为 ACCOUNT_DISABLED");
        }

        @Test
        @DisplayName("被锁定的账号应抛出 BusinessException（ACCOUNT_LOCKED）")
        void refresh_lockedAccount_shouldThrowBusinessException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            UserEntity lockedUser = new UserEntity();
            lockedUser.setId(1001L);
            lockedUser.setTenantId(10L);
            lockedUser.setStatus(2); // 锁定
            lockedUser.setDeleted(0);

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(lockedUser);

            // When/Then
            BusinessException exception = assertThrows(BusinessException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.ACCOUNT_LOCKED.getCode(), exception.getCode(),
                    "错误码应为 ACCOUNT_LOCKED");
        }

        @Test
        @DisplayName("逻辑删除的用户应抛出 AuthException（USER_NOT_FOUND）")
        void refresh_deletedUser_shouldThrowAuthException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            UserEntity deletedUser = new UserEntity();
            deletedUser.setId(1001L);
            deletedUser.setTenantId(10L);
            deletedUser.setStatus(0);
            deletedUser.setDeleted(1); // 逻辑删除

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(deletedUser);

            // When/Then
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.USER_NOT_FOUND.getCode(), exception.getCode(),
                    "错误码应为 USER_NOT_FOUND");
        }
    }

    // ==================== 租户状态场景 ====================

    @Nested
    @DisplayName("租户状态场景")
    class TenantStatus {

        @Test
        @DisplayName("被禁用的租户应抛出 BusinessException（TENANT_DISABLED）")
        void refresh_disabledTenant_shouldThrowBusinessException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            TenantEntity disabledTenant = new TenantEntity();
            disabledTenant.setId(10L);
            disabledTenant.setStatus(1); // 禁用
            disabledTenant.setDeleted(0);

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(disabledTenant);

            // When/Then
            BusinessException exception = assertThrows(BusinessException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.TENANT_DISABLED.getCode(), exception.getCode(),
                    "错误码应为 TENANT_DISABLED");
            assertEquals(ErrorCode.TENANT_DISABLED.getMessage(), exception.getMessage(),
                    "错误消息应与 TENANT_DISABLED 一致");

            // Then: 不应继续生成 Token
            verify(jwtUtils, never()).generateAccessToken(any(LoginUserDTO.class));
        }

        @Test
        @DisplayName("已过期的租户应抛出 BusinessException（TENANT_EXPIRED）")
        void refresh_expiredTenant_shouldThrowBusinessException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            TenantEntity expiredTenant = new TenantEntity();
            expiredTenant.setId(10L);
            expiredTenant.setStatus(2); // 过期
            expiredTenant.setDeleted(0);

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(expiredTenant);

            // When/Then
            BusinessException exception = assertThrows(BusinessException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.TENANT_EXPIRED.getCode(), exception.getCode(),
                    "错误码应为 TENANT_EXPIRED");
        }

        @Test
        @DisplayName("逻辑删除的租户应抛出 BusinessException（TENANT_DISABLED）")
        void refresh_deletedTenant_shouldThrowBusinessException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            TenantEntity deletedTenant = new TenantEntity();
            deletedTenant.setId(10L);
            deletedTenant.setStatus(0);
            deletedTenant.setDeleted(1); // 逻辑删除

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(deletedTenant);

            // When/Then
            BusinessException exception = assertThrows(BusinessException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.TENANT_DISABLED.getCode(), exception.getCode(),
                    "错误码应为 TENANT_DISABLED");
        }

        @Test
        @DisplayName("租户不存在时应抛出 BusinessException（TENANT_DISABLED）")
        void refresh_tenantNotFound_shouldThrowBusinessException() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(null);

            // When/Then
            BusinessException exception = assertThrows(BusinessException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.TENANT_DISABLED.getCode(), exception.getCode(),
                    "错误码应为 TENANT_DISABLED");
        }
    }

    // ==================== 边界场景 ====================

    @Nested
    @DisplayName("边界场景")
    class EdgeCases {

        @Test
        @DisplayName("refreshToken 为空时抛出 IllegalArgumentException")
        void refresh_emptyRefreshToken_shouldThrowIllegalArgumentException() {
            assertThrows(IllegalArgumentException.class,
                    () -> tokenService.refresh("", "WINDOWS"),
                    "空字符串应抛出 IllegalArgumentException");
        }

        @Test
        @DisplayName("角色列表为 null 时不影响正常刷新")
        void refresh_nullRoles_shouldStillSucceed() {
            // Given
            String refreshToken = "token";
            String tokenSignature = "sig";

            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            when(loginSessionService.isBlacklisted(tokenSignature)).thenReturn(false);
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(normalTenant);
            when(userMapper.selectRoleCodesByUserId(1001L)).thenReturn(null);
            when(userMapper.selectPermissionCodesByUserId(1001L)).thenReturn(null);
            when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("new.access");
            when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("new.refresh");

            // When
            TokenPairDTO result = tokenService.refresh(refreshToken, "WINDOWS");

            // Then
            assertNotNull(result, "即使角色权限为 null 也应刷新成功");
            verify(loginSessionService).addToBlacklist(eq(tokenSignature), anyLong());
        }

        @Test
        @DisplayName("同一 Token 重复刷新第二次应被黑名单拦截（防重放）")
        void refresh_sameTokenTwice_secondCallShouldBeRejected() {
            // Given
            String refreshToken = "replay.token";
            String tokenSignature = "replaySignature";

            // 第一次调用：刷新成功
            when(jwtUtils.parseRefreshToken(refreshToken)).thenReturn(mockClaims);
            when(jwtUtils.getTokenSignature(refreshToken)).thenReturn(tokenSignature);
            // 第2步：黑名单返回 false（第一次校验）
            when(loginSessionService.isBlacklisted(tokenSignature))
                    .thenReturn(false)   // 第一次调用：不在黑名单
                    .thenReturn(true);   // 第二次调用：已在黑名单（被上一步加入）
            when(userMapper.selectById(1001L)).thenReturn(normalUser);
            when(tenantMapper.selectById(10L)).thenReturn(normalTenant);
            when(userMapper.selectRoleCodesByUserId(1001L)).thenReturn(List.of());
            when(userMapper.selectPermissionCodesByUserId(1001L)).thenReturn(List.of());
            when(jwtUtils.generateAccessToken(any(LoginUserDTO.class))).thenReturn("new.access.1");
            when(jwtUtils.generateRefreshToken(any(LoginUserDTO.class))).thenReturn("new.refresh.1");

            // When: 第一次刷新
            TokenPairDTO firstResult = tokenService.refresh(refreshToken, "WINDOWS");
            assertNotNull(firstResult, "第一次刷新应成功");

            // When/Then: 第二次使用相同 Token 刷新应被拒绝
            AuthException exception = assertThrows(AuthException.class,
                    () -> tokenService.refresh(refreshToken, "WINDOWS"));
            assertEquals(ErrorCode.TOKEN_BLACKLISTED.getCode(), exception.getCode(),
                    "重放请求应返回 TOKEN_BLACKLISTED");
        }
    }
}
