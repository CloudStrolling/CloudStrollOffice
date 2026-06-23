/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;
import org.cloudstrolling.cloudoffice.auth.dto.result.RegisterResult;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.service.strategy.LoginStrategyFactory;
import org.cloudstrolling.cloudoffice.auth.service.strategy.RegisterStrategyFactory;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
import org.cloudstrolling.cloudoffice.common.enums.ClientTypeEnum;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * 统一认证编排服务。
 *
 * <p>认证模块的核心入口，负责统一编排登录认证和注册流程。
 * 登录流程包括：策略认证 → 租户/用户状态校验 → LoginUserDTO 构建
 * → 双 Token 签发 → 同端互斥 → Redis 会话写入 → 状态缓存 → 日志记录。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AuthenticationService {

    /** 管理员角色编码 */
    private static final String ADMIN_ROLE_CODE = "admin";

    /** 正常状态值 */
    private static final int STATUS_NORMAL = 0;

    private final LoginStrategyFactory loginStrategyFactory;
    private final RegisterStrategyFactory registerStrategyFactory;
    private final LoginSessionService loginSessionService;
    private final LoginLogService loginLogService;
    private final JwtUtils jwtUtils;
    private final UserMapper userMapper;
    private final TenantMapper tenantMapper;

    /** Refresh Token 过期时间（秒），默认 7 天 */
    @Value("${jwt.refresh-token-expiration:604800}")
    private long refreshTokenExpiration;

    /**
     * 统一登录认证。
     *
     * <p>完整流程：</p>
     * <ol>
     *   <li>通过策略工厂获取对应登录模式的策略进行认证</li>
     *   <li>从认证结果中提取用户 ID 和租户 ID</li>
     *   <li>校验租户状态（禁用/过期）</li>
     *   <li>校验用户状态（禁用/锁定/封禁/过期）</li>
     *   <li>校验账号信息是否完善（accountSettled）</li>
     *   <li>构建 LoginUserDTO（含角色和权限）</li>
     *   <li>签发 Access Token 和 Refresh Token</li>
     *   <li>处理同端互斥（踢掉同设备分类的旧会话）</li>
     *   <li>写入 Redis 登录态会话</li>
     *   <li>缓存账号和租户状态到 Redis</li>
     *   <li>记录登录成功日志</li>
     *   <li>更新用户最后登录时间和 IP</li>
     * </ol>
     *
     * @param request 登录请求
     * @return 双 Token 响应 DTO
     */
    @Transactional(rollbackFor = Exception.class)
    public TokenPairDTO authenticate(LoginRequest request) {
        // 1. 策略认证
        AuthResult authResult = loginStrategyFactory.getStrategy(request.getLoginMode())
                .authenticate(request);

        Long userId = authResult.getUserId();
        Long tenantId = authResult.getTenantId();

        // 2. 查询用户和租户实体
        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("认证失败：用户不存在 | userId={}", userId);
            throw new AuthException(ErrorCode.USER_NOT_FOUND);
        }

        TenantEntity tenant = tenantMapper.selectById(tenantId);
        if (tenant == null) {
            log.warn("认证失败：租户不存在 | tenantId={}", tenantId);
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "租户不存在");
        }

        // 3. 校验租户状态
        checkTenantStatus(tenant);

        // 4. 校验用户状态
        checkUserStatus(user);

        // 5. 校验账号信息是否完善（accountSettled）
        if (user.getAccountSettled() != null && user.getAccountSettled() == 0) {
            log.warn("认证失败：账号信息未完善 | userId={}", userId);
            throw new BusinessException(ErrorCode.ACCOUNT_NOT_SETTLED);
        }

        // 6. 查询角色和权限列表
        List<String> roles = authResult.getRoles() != null
                ? authResult.getRoles()
                : userMapper.selectRoleCodesByUserId(userId);
        List<String> permissions = authResult.getPermissions() != null
                ? authResult.getPermissions()
                : userMapper.selectPermissionCodesByUserId(userId);

        // 7. 构建 LoginUserDTO
        LoginUserDTO loginUser = LoginUserDTO.builder()
                .userId(userId)
                .tenantId(tenantId)
                .userName(user.getUserName())
                .clientType(request.getClientType())
                .roles(roles != null ? new ArrayList<>(roles) : new ArrayList<>())
                .permissions(permissions != null ? new ArrayList<>(permissions) : new ArrayList<>())
                .build();

        // 8. 签发双 Token
        String accessToken = jwtUtils.generateAccessToken(loginUser);
        String refreshToken = jwtUtils.generateRefreshToken(loginUser);

        long nowMillis = System.currentTimeMillis();
        long accessTokenExpireIn = nowMillis + jwtUtils.getAccessTokenExpiration() * 1000L;
        long refreshTokenExpireIn = nowMillis + refreshTokenExpiration * 1000L;

        TokenPairDTO tokenPair = TokenPairDTO.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .accessTokenExpireIn(accessTokenExpireIn)
                .refreshTokenExpireIn(refreshTokenExpireIn)
                .tokenType("Bearer")
                .build();

        // 获取客户端 IP
        String loginIp = getClientIp();

        // 9. 处理同端互斥
        Optional<ClientTypeEnum> clientTypeOpt = ClientTypeEnum.fromCode(request.getClientType());
        clientTypeOpt.ifPresent(clientType -> processMutualExclusion(userId, clientType));

        // 10. 写入 Redis 登录态会话
        try {
            loginSessionService.createSession(userId, request.getClientType(),
                    loginUser, refreshTokenExpiration);
        } catch (Exception e) {
            log.error("Redis 登录态会话写入失败 | userId={}", userId, e);
        }

        // 11. 缓存账号和租户状态到 Redis
        try {
            loginSessionService.setAccountStatus(userId, user.getStatus());
            loginSessionService.setTenantStatus(tenantId, tenant.getStatus());
        } catch (Exception e) {
            log.error("状态缓存写入失败 | userId={} | tenantId={}", userId, tenantId, e);
        }

        // 12. 记录登录成功日志
        loginLogService.recordLoginSuccess(tenantId, userId, user.getLoginName(),
                loginIp, request.getClientType(), null);

        // 13. 更新用户最后登录时间和 IP
        user.setLastLoginTime(LocalDateTime.now());
        user.setLastLoginIp(loginIp);
        userMapper.updateById(user);

        log.info("统一认证登录成功 | userId={} | tenantId={} | clientType={} | ip={}",
                userId, tenantId, request.getClientType(), loginIp);

        return tokenPair;
    }

    /**
     * 统一注册。
     *
     * <p>通过策略工厂获取对应注册模式的策略执行注册逻辑。</p>
     *
     * @param request 注册请求
     * @return 注册结果
     */
    public RegisterResult register(RegisterRequest request) {
        return registerStrategyFactory.getStrategy(request.getRegisterMode()).register(request);
    }

    /**
     * 校验租户状态。
     *
     * <p>检查租户是否被禁用或已过期。</p>
     *
     * @param tenant 租户实体
     * @throws BusinessException 如果租户已禁用或已过期
     */
    private void checkTenantStatus(TenantEntity tenant) {
        if (tenant.getStatus() != null && tenant.getStatus() == 1) {
            log.warn("租户已被禁用 | tenantId={} | tenantCode={}",
                    tenant.getId(), tenant.getTenantCode());
            throw new BusinessException(ErrorCode.TENANT_DISABLED);
        }
        if (tenant.getExpireTime() != null && tenant.getExpireTime().isBefore(LocalDateTime.now())) {
            log.warn("租户已过期 | tenantId={} | tenantCode={} | expireTime={}",
                    tenant.getId(), tenant.getTenantCode(), tenant.getExpireTime());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
    }

    /**
     * 校验用户状态。
     *
     * <p>检查用户账号是否被禁用、锁定、封禁或已过期。
     * 用户状态：0-正常，1-禁用，2-锁定，3-封禁，4-过期。</p>
     *
     * @param user 用户实体
     * @throws BusinessException 如果账号状态异常
     */
    private void checkUserStatus(UserEntity user) {
        if (user.getStatus() == null || user.getStatus() == STATUS_NORMAL) {
            return;
        }
        switch (user.getStatus()) {
            case 1:
                log.warn("账号已被禁用 | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_DISABLED);
            case 2:
                log.warn("账号已被锁定 | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_LOCKED);
            case 3:
                log.warn("账号已被封禁 | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_BANNED);
            case 4:
                log.warn("账号已过期 | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_EXPIRED);
            default:
                log.warn("未知账号状态 | userId={} | status={}", user.getId(), user.getStatus());
                throw new BusinessException(ErrorCode.ACCOUNT_DISABLED);
        }
    }

    /**
     * 处理同端互斥。
     *
     * <p>遍历所有客户端类型，找出与当前登录客户端类型同设备分类的已有会话，
     * 清理旧会话的 Redis 登录态。</p>
     *
     * @param userId         用户 ID
     * @param clientTypeEnum 当前登录的客户端类型枚举
     */
    private void processMutualExclusion(Long userId, ClientTypeEnum clientTypeEnum) {
        try {
            for (ClientTypeEnum type : ClientTypeEnum.values()) {
                if (type.isSameCategory(clientTypeEnum)) {
                    LoginUserDTO oldSession = loginSessionService.getSession(userId, type.getCode());
                    if (oldSession != null) {
                        loginSessionService.removeSession(userId, type.getCode());
                        log.info("同端互斥：已清理旧会话 | userId={} | clientType={}",
                                userId, type.getCode());
                    }
                }
            }
        } catch (Exception e) {
            log.error("同端互斥处理失败 | userId={}", userId, e);
        }
    }

    /**
     * 获取客户端 IP 地址。
     *
     * <p>优先从 X-Forwarded-For 请求头获取，其次从 getRemoteAddr() 获取。</p>
     *
     * @return 客户端 IP 地址，无法获取时返回 "unknown"
     */
    private String getClientIp() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes)
                    RequestContextHolder.currentRequestAttributes();
            if (attributes == null) {
                return "unknown";
            }
            String ip = attributes.getRequest().getHeader("X-Forwarded-For");
            if (ip == null || ip.isEmpty() || "unknown".equalsIgnoreCase(ip)) {
                ip = attributes.getRequest().getRemoteAddr();
            }
            return ip != null ? ip : "unknown";
        } catch (Exception e) {
            log.warn("获取客户端 IP 失败", e);
            return "unknown";
        }
    }
}
