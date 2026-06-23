/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.controller;

import io.jsonwebtoken.Claims;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.KickoutRequest;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.RefreshTokenRequest;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.service.LoginService;
import org.cloudstrolling.cloudoffice.auth.service.TokenService;
import org.cloudstrolling.cloudoffice.auth.service.UserService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 认证控制器。
 *
 * <p>提供登录、注册、Token 刷新、登出、强制踢人等认证相关 API 端点。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "认证管理", description = "登录、注册、Token 刷新、登出、强制踢人等认证接口")
public class AuthController {

    private final LoginService loginService;

    private final UserService userService;

    private final TokenService tokenService;

    private final JwtUtils jwtUtils;

    /**
     * 构造器注入。
     *
     * @param loginService 登录认证服务
     * @param userService  用户服务
     * @param tokenService Token 刷新服务
     * @param jwtUtils     JWT 令牌工具类
     */
    public AuthController(LoginService loginService, UserService userService,
                          TokenService tokenService, JwtUtils jwtUtils) {
        this.loginService = loginService;
        this.userService = userService;
        this.tokenService = tokenService;
        this.jwtUtils = jwtUtils;
    }

    /**
     * 用户登录。
     *
     * <p>接收登录名、密码、租户编码和客户端类型，执行完整的登录认证流程。
     * 成功时返回双 Token（Access Token + Refresh Token）。</p>
     *
     * @param request 登录请求
     * @return 统一响应体，包含双 Token 数据
     */
    @PostMapping("/login")
    @Operation(summary = "用户登录", description = "用户名密码登录，支持多端互斥和双 Token 签发")
    public ApiResult<TokenPairDTO> login(@Valid @RequestBody LoginRequest request) {
        TokenPairDTO tokenPair = loginService.login(request);
        log.info("Login success | loginName={} | tenantCode={} | clientType={}",
                request.getLoginName(), request.getTenantCode(), request.getClientType());
        return ApiResult.success("登录成功", tokenPair);
    }

    /**
     * 用户注册。
     *
     * <p>接收注册信息，校验参数有效性和唯一性，创建新用户并分配默认角色。
     * 返回用户基本信息（不含密码）。</p>
     *
     * @param request 注册请求
     * @return 统一响应体，包含注册成功的用户信息
     */
    @PostMapping("/register")
    @Operation(summary = "用户注册", description = "新用户注册，分配默认角色")
    public ApiResult<UserEntity> register(@Valid @RequestBody RegisterRequest request) {
        UserEntity user = userService.register(request);
        log.info("Register success | userId={} | loginName={}",
                user.getId(), user.getLoginName());
        return ApiResult.success("注册成功", user);
    }

    /**
     * Token 刷新。
     *
     * <p>使用 Refresh Token 申请新的双 Token 对（轮换机制）。
     * 旧的 Refresh Token 将被加入黑名单防止重放攻击。</p>
     *
     * @param request Token 刷新请求，包含 Refresh Token
     * @return 统一响应体，包含新的双 Token 数据
     */
    @PostMapping("/refresh")
    @Operation(summary = "刷新 Token", description = "Refresh Token 轮换，返回新的双 Token 对")
    public ApiResult<TokenPairDTO> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        // 从 Refresh Token 中提取 clientType
        Claims claims = jwtUtils.parseRefreshToken(request.getRefreshToken());
        String clientType = claims.get("clientType", String.class);

        TokenPairDTO tokenPair = tokenService.refresh(request.getRefreshToken(), clientType);
        log.info("Token refresh success");
        return ApiResult.success("刷新成功", tokenPair);
    }

    /**
     * 用户登出。
     *
     * <p>从请求头中提取 Access Token，将其加入黑名单并清除登录态。
     * 支持幂等处理，重复登出返回成功。</p>
     *
     * @param servletRequest HTTP 请求，需包含 {@code Authorization: Bearer <token>} 头
     * @return 统一响应体，登出成功返回 200
     */
    @PostMapping("/logout")
    @Operation(summary = "用户登出", description = "将当前 Access Token 加入黑名单并清除登录态")
    public ApiResult<Void> logout(HttpServletRequest servletRequest) {
        String authHeader = servletRequest.getHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new AuthException(ErrorCode.TOKEN_INVALID);
        }
        String accessToken = authHeader.substring(7);

        // 从 Token 中提取 clientType
        Claims claims = jwtUtils.parseAccessToken(accessToken);
        String clientType = claims.get("clientType", String.class);

        loginService.logout(accessToken, clientType);
        log.info("Logout success");
        return ApiResult.<Void>success().setMessage("登出成功");
    }

    /**
     * 强制踢人。
     *
     * <p>管理员强制指定用户下线。可指定客户端类型踢指定端，或不指定客户端类型踢所有端。</p>
     *
     * @param request 踢人请求，包含目标用户 ID 和可选的客户端类型
     * @return 统一响应体，踢人成功返回 200
     */
    @PostMapping("/kickout")
    @Operation(summary = "强制踢人", description = "管理员强制指定用户下线，支持踢指定端或所有端")
    public ApiResult<Void> kickout(@Valid @RequestBody KickoutRequest request) {
        loginService.kickout(request.getUserId(), request.getClientType());
        log.info("Kickout request processed | targetUserId={} | clientType={}",
                request.getUserId(), request.getClientType());
        return ApiResult.success();
    }
}
