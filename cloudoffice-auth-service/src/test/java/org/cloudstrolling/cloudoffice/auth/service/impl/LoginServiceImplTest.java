/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.impl.DefaultClaims;
import org.cloudstrolling.cloudoffice.auth.entity.LoginLogEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.LoginLogMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginLogService;
import org.cloudstrolling.cloudoffice.auth.service.LoginService;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
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
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.Date;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

/**
 * {@link LoginServiceImpl} 的单元测试，覆盖 kickout 和 logout 方法。
 *
 * <p>使用 Mockito 模拟所有依赖，验证登出和强制踢人方法的业务逻辑和边界情况。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("LoginServiceImpl 单元测试")
class LoginServiceImplTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private LoginSessionService loginSessionService;

    @Mock
    private LoginLogMapper loginLogMapper;

    @Mock
    private JwtUtils jwtUtils;

    @Mock
    private LoginLogService loginLogService;

    @Captor
    private ArgumentCaptor<LoginLogEntity> logCaptor;

    @Captor
    private ArgumentCaptor<Long> longCaptor;

    private LoginService loginService;

    /** 模拟的 HTTP 请求，用于设置操作者上下文 */
    private MockHttpServletRequest request;

    @BeforeEach
    void setUp() {
        loginService = new LoginServiceImpl(userMapper, loginSessionService,
                loginLogMapper, jwtUtils, loginLogService);

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

    @AfterEach
    void tearDown() {
        // 清理请求上下文，防止污染其他测试
        RequestContextHolder.resetRequestAttributes();
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
