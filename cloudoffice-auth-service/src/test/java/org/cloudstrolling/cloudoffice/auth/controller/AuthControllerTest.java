/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Claims;
import org.cloudstrolling.cloudoffice.auth.dto.AccountSettlementRequest;
import org.cloudstrolling.cloudoffice.auth.dto.KickoutRequest;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.PasswordChangeRequest;
import org.cloudstrolling.cloudoffice.auth.dto.PasswordForgotRequest;
import org.cloudstrolling.cloudoffice.auth.dto.PhoneChangeRequest;
import org.cloudstrolling.cloudoffice.auth.dto.RefreshTokenRequest;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.dto.SendVerificationCodeRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.RegisterResult;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.service.AuthenticationService;
import org.cloudstrolling.cloudoffice.auth.service.LoginService;
import org.cloudstrolling.cloudoffice.auth.service.PasswordService;
import org.cloudstrolling.cloudoffice.auth.service.TokenService;
import org.cloudstrolling.cloudoffice.auth.service.UserService;
import org.cloudstrolling.cloudoffice.auth.service.VerificationCodeManager;
import org.cloudstrolling.cloudoffice.auth.service.VerificationCodeService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doNothing;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * {@link AuthController} 的 MockMvc 单元测试。
 *
 * <p>使用 Mockito + 独立 MockMvc 配置测试认证控制器中登录、注册、Token 刷新、
 * 登出、强制踢人等所有端点的正常流程与异常场景。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("AuthController 测试")
@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    /** MockMvc 实例，用于模拟 HTTP 请求调用控制器 */
    private MockMvc mockMvc;

    /** Jackson JSON 序列化/反序列化工具 */
    private final ObjectMapper objectMapper = new ObjectMapper();

    /** 模拟的登录认证服务 */
    @Mock
    private LoginService loginService;

    /** 模拟的用户服务 */
    @Mock
    private UserService userService;

    /** 模拟的 Token 刷新服务 */
    @Mock
    private TokenService tokenService;

    /** 模拟的 JWT 令牌工具类 */
    @Mock
    private JwtUtils jwtUtils;

    /** 模拟的统一认证编排服务 */
    @Mock
    private AuthenticationService authenticationService;

    /** 模拟的密码管理服务 */
    @Mock
    private PasswordService passwordService;

    /** 模拟的验证码管理器 */
    @Mock
    private VerificationCodeManager verificationCodeManager;

    /** 模拟的验证码发送服务 */
    @Mock
    private VerificationCodeService verificationCodeService;

    @InjectMocks
    private AuthController authController;

    /**
     * 测试前置初始化。
     *
     * <p>构建独立 MockMvc 实例并注册 {@link AuthController} 和 {@link GlobalExceptionHandler}，
     * 每个测试用例执行前自动调用。</p>
     */
    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(authController)
                .setControllerAdvice(new GlobalExceptionHandler())
                .defaultRequest(post("/").contentType(MediaType.APPLICATION_JSON))
                .build();
    }

    // ========== POST /api/v1/auth/login - 登录 ==========

    @Test
    @DisplayName("TC-001: POST /api/v1/auth/login 成功 -> 200 + TokenPairDTO")
    void login_shouldReturnTokenPairDTO() throws Exception {
        // Given
        LoginRequest request = new LoginRequest();
        request.setLoginName("admin");
        request.setPassword("password123");
        request.setTenantCode("default");
        request.setClientType("WINDOWS");

        TokenPairDTO tokenPair = TokenPairDTO.builder()
                .accessToken("access-token-value")
                .refreshToken("refresh-token-value")
                .accessTokenExpireIn(7200000L)
                .refreshTokenExpireIn(604800000L)
                .tokenType("Bearer")
                .build();

        when(authenticationService.authenticate(any(LoginRequest.class))).thenReturn(tokenPair);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("登录成功"))
                .andExpect(jsonPath("$.data.accessToken").value("access-token-value"))
                .andExpect(jsonPath("$.data.refreshToken").value("refresh-token-value"))
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"));
    }

    @Test
    @DisplayName("TC-002: POST /api/v1/auth/login 参数无效 -> 400")
    void login_shouldReturn400_whenParamsInvalid() throws Exception {
        // Given - empty request body triggers @NotBlank validation failures
        LoginRequest request = new LoginRequest();

        // When & Then
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    // ========== POST /api/v1/auth/register - 注册 ==========

    @Test
    @DisplayName("TC-003: POST /api/v1/auth/register 成功 -> 200 + RegisterResult")
    void register_shouldReturnRegisterResult() throws Exception {
        // Given
        RegisterRequest request = new RegisterRequest();
        request.setLoginName("newuser");
        request.setPassword("password123");
        request.setUserName("新用户");
        request.setTenantCode("default");

        RegisterResult result = RegisterResult.builder()
                .userId(100L)
                .loginName("newuser")
                .userName("新用户")
                .accountSettled(true)
                .build();

        when(authenticationService.register(any(RegisterRequest.class))).thenReturn(result);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("注册成功"))
                .andExpect(jsonPath("$.data.userId").value(100))
                .andExpect(jsonPath("$.data.loginName").value("newuser"))
                .andExpect(jsonPath("$.data.accountSettled").value(true));
    }

    @Test
    @DisplayName("TC-004: POST /api/v1/auth/register 参数无效 -> 400")
    void register_shouldReturn400_whenParamsInvalid() throws Exception {
        // Given - empty request body triggers @NotBlank validation failures
        RegisterRequest request = new RegisterRequest();

        // When & Then
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    // ========== POST /api/v1/auth/refresh - Token 刷新 ==========

    @Test
    @DisplayName("TC-005: POST /api/v1/auth/refresh 成功 -> 200 + 新 TokenPairDTO")
    void refresh_shouldReturnNewTokenPair() throws Exception {
        // Given
        String refreshTokenValue = "valid-refresh-token";
        RefreshTokenRequest request = new RefreshTokenRequest();
        request.setRefreshToken(refreshTokenValue);

        TokenPairDTO tokenPair = TokenPairDTO.builder()
                .accessToken("new-access-token")
                .refreshToken("new-refresh-token")
                .accessTokenExpireIn(7200000L)
                .refreshTokenExpireIn(604800000L)
                .tokenType("Bearer")
                .build();

        Claims mockClaims = mock(Claims.class);
        when(jwtUtils.parseRefreshToken(refreshTokenValue)).thenReturn(mockClaims);
        when(mockClaims.get("clientType", String.class)).thenReturn("WINDOWS");
        when(tokenService.refresh(refreshTokenValue, "WINDOWS")).thenReturn(tokenPair);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("刷新成功"))
                .andExpect(jsonPath("$.data.accessToken").value("new-access-token"))
                .andExpect(jsonPath("$.data.refreshToken").value("new-refresh-token"))
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"));
    }

    @Test
    @DisplayName("TC-006: POST /api/v1/auth/refresh refreshToken 为空 -> 400")
    void refresh_shouldReturn400_whenRefreshTokenEmpty() throws Exception {
        // Given - empty refreshToken triggers @NotBlank validation
        RefreshTokenRequest request = new RefreshTokenRequest();
        request.setRefreshToken("");

        // When & Then
        mockMvc.perform(post("/api/v1/auth/refresh")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }

    // ========== POST /api/v1/auth/logout - 登出 ==========

    @Test
    @DisplayName("TC-007: POST /api/v1/auth/logout 成功 -> 200")
    void logout_shouldReturnSuccess() throws Exception {
        // Given
        String accessToken = "valid-access-token";
        String clientType = "WINDOWS";

        Claims mockClaims = mock(Claims.class);
        when(jwtUtils.parseAccessToken(accessToken)).thenReturn(mockClaims);
        when(mockClaims.get("clientType", String.class)).thenReturn(clientType);
        doNothing().when(loginService).logout(accessToken, clientType);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/logout")
                        .header("Authorization", "Bearer " + accessToken)
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("登出成功"));
    }

    @Test
    @DisplayName("TC-008: POST /api/v1/auth/logout 无 Authorization Header -> 401")
    void logout_shouldReturn401_whenNoAuthHeader() throws Exception {
        // When & Then - no Authorization header
        mockMvc.perform(post("/api/v1/auth/logout")
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    // ========== POST /api/v1/auth/kickout - 强制踢人 ==========

    @Test
    @DisplayName("TC-009: POST /api/v1/auth/kickout 成功 -> 200")
    void kickout_shouldReturnSuccess() throws Exception {
        // Given
        KickoutRequest request = new KickoutRequest();
        request.setUserId(100L);
        request.setClientType("WINDOWS");

        doNothing().when(loginService).kickout(100L, "WINDOWS");

        // When & Then
        mockMvc.perform(post("/api/v1/auth/kickout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.message").value("操作成功"));
    }

    @Test
    @DisplayName("TC-010: POST /api/v1/auth/kickout 参数无效 -> 400")
    void kickout_shouldReturn400_whenParamsInvalid() throws Exception {
        // Given - null userId triggers @NotNull validation failure
        KickoutRequest request = new KickoutRequest();
        request.setUserId(null);

        // When & Then
        mockMvc.perform(post("/api/v1/auth/kickout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400));
    }
}
