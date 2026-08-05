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
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

/**
 * 认证控制器。
 *
 * <p>提供登录、注册、Token 刷新、登出、强制踢人、密码管理、
 * 手机号更换、账号信息完善和验证码发送等认证相关 API 端点。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "认证管理", description = "登录、注册、Token 刷新、密码管理、手机号更换、账号完善等认证接口")
public class AuthController {

    private final LoginService loginService;

    private final UserService userService;

    private final TokenService tokenService;

    private final JwtUtils jwtUtils;

    private final AuthenticationService authenticationService;

    private final PasswordService passwordService;

    private final VerificationCodeManager verificationCodeManager;

    private final VerificationCodeService verificationCodeService;

    /**
     * 构造器注入。
     *
     * @param loginService              登录认证服务
     * @param userService               用户服务
     * @param tokenService              Token 刷新服务
     * @param jwtUtils                  JWT 令牌工具类
     * @param authenticationService     统一认证编排服务
     * @param passwordService           密码管理服务
     * @param verificationCodeManager   验证码管理器
     * @param verificationCodeService   验证码发送服务
     */
    public AuthController(LoginService loginService, UserService userService,
                          TokenService tokenService, JwtUtils jwtUtils,
                          AuthenticationService authenticationService,
                          PasswordService passwordService,
                          VerificationCodeManager verificationCodeManager,
                          VerificationCodeService verificationCodeService) {
        this.loginService = loginService;
        this.userService = userService;
        this.tokenService = tokenService;
        this.jwtUtils = jwtUtils;
        this.authenticationService = authenticationService;
        this.passwordService = passwordService;
        this.verificationCodeManager = verificationCodeManager;
        this.verificationCodeService = verificationCodeService;
    }

    // ==================== 认证端点 ====================

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
        TokenPairDTO tokenPair = authenticationService.authenticate(request);
        log.info("Login success | loginName={} | tenantCode={} | clientType={}",
                request.getLoginName(), request.getTenantCode(), request.getClientType());
        return ApiResult.success("登录成功", tokenPair);
    }

    /**
     * 用户注册。
     *
     * <p>接收注册信息，校验参数有效性和唯一性，创建新用户并分配默认角色。
     * 返回用户基本信息和 Token 对。</p>
     *
     * @param request 注册请求
     * @return 统一响应体，包含注册结果（用户信息和 Token 对）
     */
    @PostMapping("/register")
    @Operation(summary = "用户注册", description = "新用户注册，分配默认角色，返回用户信息和 Token 对")
    public ApiResult<RegisterResult> register(@Valid @RequestBody RegisterRequest request) {
        RegisterResult result = authenticationService.register(request);
        log.info("Register success | userId={} | loginName={}",
                result.getUserId(), result.getLoginName());
        return ApiResult.success("注册成功", result);
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

    // ==================== 密码管理端点 ====================

    /**
     * 修改密码。
     *
     * <p>当前登录用户修改自己的密码。需要提供旧密码进行身份校验，
     * 新密码需满足长度 8-64 字符的要求。
     * 修改成功后清除该用户的所有登录态会话。</p>
     *
     * @param request 密码修改请求，包含旧密码和新密码
     * @return 统一响应体，修改成功返回 200
     */
    @PutMapping("/password/change")
    @Operation(summary = "修改密码", description = "当前用户修改自己的密码，修改成功后清除所有登录态")
    public ApiResult<Void> changePassword(@Valid @RequestBody PasswordChangeRequest request) {
        Long userId = getCurrentUserId();
        passwordService.changePassword(userId, request.getOldPassword(), request.getNewPassword());
        log.info("Password change success | userId={}", userId);
        return ApiResult.success();
    }

    /**
     * 密码找回 - 发送验证码。
     *
     * <p>通过手机短信或邮箱发送密码重置验证码。
     * 验证目标对应的账号需存在，否则返回用户不存在错误。</p>
     *
     * @param request 发送验证码请求，包含目标（手机号/邮箱）和发送方式
     * @return 统一响应体，发送成功返回 200
     */
    @PostMapping("/password/forgot/send-code")
    @Operation(summary = "密码找回-发送验证码", description = "通过手机短信或邮箱发送密码重置验证码")
    public ApiResult<Void> forgotPasswordSendCode(@Valid @RequestBody SendVerificationCodeRequest request) {
        passwordService.forgotPasswordSendCode(request.getTarget(), request.getMode());
        log.info("Forgot password code sent | target={} | mode={}",
                request.getTarget(), request.getMode());
        return ApiResult.success();
    }

    /**
     * 密码找回 - 重置密码。
     *
     * <p>通过验证码重置密码。校验验证码有效性后更新密码，
     * 并清除该用户的所有登录态会话。</p>
     *
     * @param request 密码重置请求，包含目标、验证方式、验证码和新密码
     * @return 统一响应体，重置成功返回 200
     */
    @PostMapping("/password/forgot/reset")
    @Operation(summary = "密码找回-重置密码", description = "通过验证码重置密码，重置成功后清除所有登录态")
    public ApiResult<Void> forgotPasswordReset(@Valid @RequestBody PasswordForgotRequest request) {
        passwordService.forgotPasswordReset(
                request.getTarget(), request.getMode(), request.getCode(), request.getNewPassword());
        log.info("Forgot password reset success | target={} | mode={}", request.getTarget(), request.getMode());
        return ApiResult.success();
    }

    // ==================== 账号管理端点 ====================

    /**
     * 修改手机号。
     *
     * <p>当前登录用户更换手机号。需验证旧手机号或邮箱验证码，
     * 具体验证场景由服务层根据请求参数判断。</p>
     *
     * @param request 手机号更换请求，包含新旧手机号和验证码
     * @return 统一响应体，修改成功返回 200
     */
    @PutMapping("/phone/change")
    @Operation(summary = "修改手机号", description = "当前用户更换手机号，需验证旧手机号或邮箱验证码")
    public ApiResult<Void> changePhone(@Valid @RequestBody PhoneChangeRequest request) {
        Long userId = getCurrentUserId();
        passwordService.changePhone(userId, request);
        log.info("Phone change success | userId={}", userId);
        return ApiResult.success();
    }

    /**
     * 完善账号信息（两步注册第二步）。
     *
     * <p>用户在首次登录或信息不完整时补全账号信息。
     * 校验当前用户与请求要求一致，且账号未完善，然后更新登录名、密码和手机号。</p>
     *
     * @param request 账号补全请求，包含用户 ID、登录名、密码和手机号
     * @return 统一响应体，完善成功返回 200
     */
    @PutMapping("/account/settlement")
    @Operation(summary = "完善账号信息", description = "两步注册第二步，补全登录名、密码和手机号")
    public ApiResult<Void> accountSettlement(@Valid @RequestBody AccountSettlementRequest request) {
        Long userId = getCurrentUserId();
        // 校验当前用户与请求的用户 ID 一致
        if (!userId.equals(request.getUserId())) {
            log.warn("账号完善失败：用户 ID 不匹配 | currentUserId={} | requestUserId={}",
                    userId, request.getUserId());
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "用户 ID 不匹配");
        }
        userService.accountSettlement(userId, request);
        log.info("Account settlement success | userId={}", userId);
        return ApiResult.success();
    }

    // ==================== 验证码端点 ====================

    /**
     * 发送验证码。
     *
     * <p>向指定目标（手机号或邮箱）发送验证码。
     * 支持多种验证码用途：注册、登录、重置密码、更换手机号等。
     * 该端点为白名单，无需登录即可访问。</p>
     *
     * @param request 发送验证码请求，包含目标、发送方式和用途
     * @return 统一响应体，发送成功返回 200
     */
    @PostMapping("/verification-code/send")
    @Operation(summary = "发送验证码", description = "向手机号或邮箱发送验证码，支持多种用途，无需登录")
    public ApiResult<Void> sendVerificationCode(@Valid @RequestBody SendVerificationCodeRequest request) {
        // 检查频率
        if (verificationCodeManager.isSendTooFrequent(request.getTarget(), request.getPurpose())) {
            throw new BusinessException(ErrorCode.SMS_SEND_TOO_FREQUENT);
        }
        // 生成验证码
        String code = verificationCodeManager.generateCode(request.getTarget(), request.getMode(), request.getPurpose());
        // 发送验证码
        if ("SMS".equals(request.getMode())) {
            verificationCodeService.sendSmsCode(request.getTarget(), code, request.getPurpose());
        } else if ("EMAIL".equals(request.getMode())) {
            verificationCodeService.sendEmailCode(request.getTarget(), code, request.getPurpose());
        }
        log.info("Verification code sent | target={} | mode={} | purpose={}",
                request.getTarget(), request.getMode(), request.getPurpose());
        return ApiResult.success();
    }

    // ==================== 私有方法 ====================

    /**
     * 从当前请求上下文中获取当前登录用户 ID。
     *
     * <p>从网关透传的 X-User-Id 请求头中提取用户 ID。</p>
     *
     * @return 当前用户 ID
     * @throws BusinessException 如果无法获取用户 ID
     */
    private Long getCurrentUserId() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes)
                    RequestContextHolder.currentRequestAttributes();
            if (attributes == null) {
                log.warn("无法获取当前请求上下文");
                throw new BusinessException(ErrorCode.UNAUTHORIZED);
            }
            String userIdStr = attributes.getRequest().getHeader("X-User-Id");
            if (userIdStr == null || userIdStr.isEmpty()) {
                log.warn("无法获取当前用户 ID：请求头中缺少 X-User-Id");
                throw new BusinessException(ErrorCode.UNAUTHORIZED);
            }
            return Long.valueOf(userIdStr);
        } catch (BusinessException e) {
            throw e;
        } catch (Exception e) {
            log.warn("获取当前用户 ID 失败", e);
            throw new BusinessException(ErrorCode.UNAUTHORIZED);
        }
    }
}
