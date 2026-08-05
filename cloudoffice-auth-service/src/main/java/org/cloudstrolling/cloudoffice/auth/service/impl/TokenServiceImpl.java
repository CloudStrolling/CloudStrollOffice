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
import lombok.extern.slf4j.Slf4j;
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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.Assert;

import java.util.Collections;
import java.util.Date;
import java.util.List;

/**
 * Token 刷新服务实现类。
 *
 * <p>实现 Refresh Token 轮换机制，每次刷新同时更换 Access Token 和 Refresh Token，
 * 旧 Refresh Token 加入黑名单防止重放攻击。</p>
 *
 * <p>刷新流程：</p>
 * <ol>
 *   <li>RS256 验签 Refresh Token（{@link JwtUtils#parseRefreshToken}）</li>
 *   <li>校验 Refresh Token 是否在黑名单中</li>
 *   <li>从 Claims 中提取 userId、tenantId、clientType</li>
 *   <li>查询用户最新状态（禁用/封禁/过期）</li>
 *   <li>查询租户状态（禁用/过期）</li>
 *   <li>查询用户角色和权限列表</li>
 *   <li>生成新的双 Token</li>
 *   <li>旧 Refresh Token 加入黑名单（TTL = 旧 Token 剩余有效期）</li>
 *   <li>更新 Redis 登录态会话</li>
 *   <li>返回新的 TokenPairDTO</li>
 * </ol>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
public class TokenServiceImpl implements TokenService {

    private final JwtUtils jwtUtils;
    private final LoginSessionService loginSessionService;
    private final UserMapper userMapper;
    private final TenantMapper tenantMapper;
    private final long accessTokenExpiration;
    private final long refreshTokenExpiration;

    /**
     * 构造器注入所有依赖。
     *
     * @param jwtUtils               JWT 令牌工具类
     * @param loginSessionService    Redis 登录态管理服务
     * @param userMapper             用户数据访问层
     * @param tenantMapper           租户数据访问层
     * @param accessTokenExpiration  Access Token 过期时间（秒）
     * @param refreshTokenExpiration Refresh Token 过期时间（秒）
     */
    public TokenServiceImpl(JwtUtils jwtUtils,
                            LoginSessionService loginSessionService,
                            UserMapper userMapper,
                            TenantMapper tenantMapper,
                            @Value("${jwt.access-token-expiration:7200}") long accessTokenExpiration,
                            @Value("${jwt.refresh-token-expiration:604800}") long refreshTokenExpiration) {
        this.jwtUtils = jwtUtils;
        this.loginSessionService = loginSessionService;
        this.userMapper = userMapper;
        this.tenantMapper = tenantMapper;
        this.accessTokenExpiration = accessTokenExpiration;
        this.refreshTokenExpiration = refreshTokenExpiration;
    }

    /**
     * 刷新 Token。
     *
     * <p>完整的轮换流程：验签 → 黑名单校验 → 用户状态校验 → 租户状态校验
     * → 新 Token 签发 → 旧 Token 吊销 → 会话更新。</p>
     *
     * @param refreshToken 待刷新的 Refresh Token
     * @param clientType   客户端类型（作为额外校验，非核心判定依据）
     * @return 新的双 Token 对
     */
    @Override
    public TokenPairDTO refresh(String refreshToken, String clientType) {
        // 1. 参数基础校验
        Assert.hasText(refreshToken, "refreshToken must not be empty");

        // 2. RS256 验签 Refresh Token
        Claims claims = parseAndValidateRefreshToken(refreshToken);

        // 3. 校验 Refresh Token 是否在黑名单中
        String tokenSignature = jwtUtils.getTokenSignature(refreshToken);
        if (loginSessionService.isBlacklisted(tokenSignature)) {
            log.warn("Refresh Token is blacklisted | signature={}", maskSignature(tokenSignature));
            throw new AuthException(ErrorCode.TOKEN_BLACKLISTED);
        }

        // 4. 从 Claims 中提取用户信息
        Long userId = Long.valueOf(claims.getSubject());
        Long tenantId = claims.get("tenantId", Long.class);
        String tokenClientType = claims.get("clientType", String.class);

        log.debug("Refreshing token | userId={} | tenantId={} | clientType={}",
                userId, tenantId, tokenClientType);

        // 5. 查询并校验用户状态
        UserEntity user = userMapper.selectById(userId);
        if (user == null || (user.getDeleted() != null && user.getDeleted() == 1)) {
            log.warn("User not found or deleted during token refresh | userId={}", userId);
            throw new AuthException(ErrorCode.USER_NOT_FOUND);
        }
        checkUserStatus(user);

        // 6. 查询并校验租户状态
        TenantEntity tenant = tenantMapper.selectById(tenantId);
        if (tenant == null || (tenant.getDeleted() != null && tenant.getDeleted() == 1)) {
            log.warn("Tenant not found or deleted during token refresh | tenantId={}", tenantId);
            throw new BusinessException(ErrorCode.TENANT_DISABLED, "AUTH");
        }
        checkTenantStatus(tenant);

        // 7. 查询用户角色和权限列表
        List<String> roles = userMapper.selectRoleCodesByUserId(userId);
        List<String> permissions = userMapper.selectPermissionCodesByUserId(userId);
        if (roles == null) {
            roles = Collections.emptyList();
        }
        if (permissions == null) {
            permissions = Collections.emptyList();
        }

        // 8. 构建 LoginUserDTO
        LoginUserDTO loginUser = LoginUserDTO.builder()
                .userId(userId)
                .tenantId(tenantId)
                .userName(user.getLoginName())
                .clientType(tokenClientType)
                .roles(roles)
                .permissions(permissions)
                .build();

        // 9. 生成新的双 Token
        String newAccessToken = jwtUtils.generateAccessToken(loginUser);
        String newRefreshToken = jwtUtils.generateRefreshToken(loginUser);

        // 10. 计算旧 Refresh Token 的剩余有效期（秒），用于黑名单 TTL
        long remainingSeconds = calculateRemainingSeconds(claims.getExpiration());

        // 11. 旧 Refresh Token 加入黑名单（防止重放）
        loginSessionService.addToBlacklist(tokenSignature, Math.max(remainingSeconds, 1L));

        // 12. 更新 Redis 登录态会话（先删除旧会话，再创建新会话）
        //     createSession 会自动覆盖旧值，此处先 remove 确保状态清除
        loginSessionService.removeSession(userId, tokenClientType);
        loginSessionService.createSession(userId, tokenClientType, loginUser, refreshTokenExpiration);

        // 13. 构建并返回 TokenPairDTO
        long now = System.currentTimeMillis();
        TokenPairDTO tokenPair = TokenPairDTO.builder()
                .accessToken(newAccessToken)
                .refreshToken(newRefreshToken)
                .accessTokenExpireIn(now + accessTokenExpiration)
                .refreshTokenExpireIn(now + refreshTokenExpiration)
                .tokenType("Bearer")
                .build();

        log.info("Token refreshed successfully | userId={} | clientType={}", userId, tokenClientType);
        return tokenPair;
    }

    /**
     * 解析并验证 Refresh Token。
     *
     * <p>捕获 JJWT 的各类异常，转换为对应的业务异常。</p>
     *
     * @param token Refresh Token 字符串
     * @return JWT Claims 载荷
     * @throws AuthException 如果 Token 过期、无效或签名错误
     */
    private Claims parseAndValidateRefreshToken(String token) {
        try {
            return jwtUtils.parseRefreshToken(token);
        } catch (ExpiredJwtException e) {
            log.warn("Refresh Token expired");
            throw new AuthException(ErrorCode.REFRESH_TOKEN_EXPIRED);
        } catch (SignatureException e) {
            log.warn("Refresh Token signature invalid");
            throw new AuthException(ErrorCode.REFRESH_TOKEN_INVALID);
        } catch (MalformedJwtException e) {
            log.warn("Refresh Token malformed");
            throw new AuthException(ErrorCode.REFRESH_TOKEN_INVALID);
        } catch (JwtException e) {
            // tokenType 不匹配或其他 JWT 异常
            log.warn("Refresh Token invalid: {}", e.getMessage());
            throw new AuthException(ErrorCode.REFRESH_TOKEN_INVALID);
        }
    }

    /**
     * 校验用户状态。
     *
     * <p>状态说明：0-正常，1-禁用，2-锁定，3-封禁。</p>
     *
     * @param user 用户实体
     * @throws BusinessException 如果用户状态异常
     */
    private void checkUserStatus(UserEntity user) {
        if (user.getStatus() == null) {
            return;
        }
        switch (user.getStatus()) {
            case 1:
                log.warn("Account disabled | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_DISABLED, "AUTH");
            case 2:
                log.warn("Account locked | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_LOCKED, "AUTH");
            case 3:
                log.warn("Account banned | userId={}", user.getId());
                throw new BusinessException(ErrorCode.ACCOUNT_BANNED, "AUTH");
            default:
                // 0 或其他值视为正常
                break;
        }
    }

    /**
     * 校验租户状态。
     *
     * <p>状态说明：0-正常，1-禁用，2-过期。</p>
     *
     * @param tenant 租户实体
     * @throws BusinessException 如果租户状态异常
     */
    private void checkTenantStatus(TenantEntity tenant) {
        if (tenant.getStatus() == null) {
            return;
        }
        switch (tenant.getStatus()) {
            case 1:
                log.warn("Tenant disabled | tenantId={}", tenant.getId());
                throw new BusinessException(ErrorCode.TENANT_DISABLED, "AUTH");
            case 2:
                log.warn("Tenant expired | tenantId={}", tenant.getId());
                throw new BusinessException(ErrorCode.TENANT_EXPIRED, "AUTH");
            default:
                // 0 或其他值视为正常
                break;
        }
    }

    /**
     * 计算 Token 剩余有效期（秒）。
     *
     * @param expiration Token 过期时间
     * @return 剩余秒数，最小为 0
     */
    private long calculateRemainingSeconds(Date expiration) {
        long remaining = (expiration.getTime() - System.currentTimeMillis()) / 1000L;
        return Math.max(remaining, 0L);
    }

    /**
     * 对 Token 签名指纹进行脱敏处理，仅显示前 8 位，用于日志输出。
     *
     * @param signature Token 签名指纹
     * @return 脱敏后的签名
     */
    private static String maskSignature(String signature) {
        if (signature == null || signature.length() <= 8) {
            return signature;
        }
        return signature.substring(0, 8) + "****";
    }
}
