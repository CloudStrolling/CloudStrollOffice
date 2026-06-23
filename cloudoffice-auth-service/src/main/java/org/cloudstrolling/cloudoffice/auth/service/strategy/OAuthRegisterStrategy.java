/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.RegisterResult;
import org.cloudstrolling.cloudoffice.auth.entity.OAuthAccountEntity;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserRoleEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.OAuthAccountMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Random;

/**
 * OAuth 第三方注册策略。
 *
 * <p>处理 OAUTH 模式的注册流程：校验 oauthProvider+oauthCode → 校验 openId 全局唯一
 * → 创建用户（accountSetled=false） → 创建 OAuth 绑定记录 → 分配默认角色
 * → 自动登录签发 Token 对。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OAuthRegisterStrategy implements RegisterStrategy {

    private static final String DEFAULT_ROLE_CODE = "user";

    private final UserMapper userMapper;
    private final TenantMapper tenantMapper;
    private final UserRoleMapper userRoleMapper;
    private final RoleMapper roleMapper;
    private final OAuthAccountMapper oauthAccountMapper;
    private final JwtUtils jwtUtils;
    private final LoginSessionService loginSessionService;

    @Value("${jwt.refresh-token-expiration:604800}")
    private long refreshTokenExpiration;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public RegisterResult register(RegisterRequest request) {
        // 1. 校验必填字段
        Assert.hasText(request.getOauthProvider(), "oauthProvider must not be empty");
        Assert.hasText(request.getOauthCode(), "oauthCode must not be empty");
        Assert.hasText(request.getTenantCode(), "tenantCode must not be empty");

        log.info("OAuth 注册开始 | oauthProvider={} | oauthCode={} | tenantCode={}",
                request.getOauthProvider(), request.getOauthCode(), request.getTenantCode());

        // 2. 通过 tenantCode 查询租户并校验
        TenantEntity tenant = queryAndValidateTenant(request.getTenantCode());
        Long tenantId = tenant.getId();

        // 3. 校验 openId 全局唯一（oauthCode 作为 OAuth 平台的 openId）
        checkOpenIdUnique(request.getOauthProvider(), request.getOauthCode());

        // 4. 自动生成 loginName
        String loginName = generateLoginName();
        log.debug("自动生成登录名 | loginName={}", loginName);

        // 5. 创建用户记录（account_settled = false）
        UserEntity user = buildUser(request, tenantId, loginName);
        userMapper.insert(user);
        log.info("用户记录创建成功 | userId={} | loginName={}", user.getId(), user.getLoginName());

        // 6. 创建 OAuth 账号绑定记录
        createOAuthAccount(user.getId(), request.getOauthProvider(), request.getOauthCode());
        log.info("OAuth 账号绑定记录创建成功 | userId={} | oauthProvider={} | openId={}",
                user.getId(), request.getOauthProvider(), request.getOauthCode());

        // 7. 分配默认角色
        assignDefaultRole(user);

        // 8. 构建自动登录 Token 对
        TokenPairDTO tokenPair = generateTokenPair(user, tenant);

        // 9. 构建返回 RegisterResult（含 TokenPairDTO 自动登录）
        RegisterResult result = RegisterResult.builder()
                .userId(user.getId())
                .loginName(user.getLoginName())
                .userName(user.getUserName())
                .accountSettled(false)
                .tokenPair(tokenPair)
                .build();

        log.info("OAuth 注册完成 | userId={} | loginName={}", user.getId(), user.getLoginName());
        return result;
    }

    /**
     * 查询并校验租户状态。
     */
    private TenantEntity queryAndValidateTenant(String tenantCode) {
        LambdaQueryWrapper<TenantEntity> tenantQuery = Wrappers.lambdaQuery(TenantEntity.class)
                .eq(TenantEntity::getTenantCode, tenantCode);
        TenantEntity tenant = tenantMapper.selectOne(tenantQuery);
        if (tenant == null) {
            log.warn("租户不存在 | tenantCode={}", tenantCode);
            throw new BusinessException(ErrorCode.NOT_FOUND.getCode(), "租户不存在");
        }
        if (tenant.getStatus() != null && tenant.getStatus() != 0) {
            if (tenant.getStatus() == 1) {
                log.warn("租户已被禁用 | tenantId={}", tenant.getId());
                throw new BusinessException(ErrorCode.TENANT_DISABLED);
            }
            log.warn("租户已过期 | tenantId={}", tenant.getId());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
        if (tenant.getExpireTime() != null && tenant.getExpireTime().isBefore(LocalDateTime.now())) {
            log.warn("租户已过期 | tenantId={} | expireTime={}", tenant.getId(), tenant.getExpireTime());
            throw new BusinessException(ErrorCode.TENANT_EXPIRED);
        }
        return tenant;
    }

    /**
     * 校验 OAuth openId 全局唯一。
     *
     * @param provider OAuth 提供商
     * @param openId   OAuth openId
     * @throws BusinessException 如果 openId 已被绑定
     */
    private void checkOpenIdUnique(String provider, String openId) {
        OAuthAccountEntity existing = oauthAccountMapper.selectByProviderAndOpenId(provider, openId);
        if (existing != null) {
            log.warn("OAuth 账号已被绑定 | oauthProvider={} | openId={}", provider, openId);
            throw new BusinessException(ErrorCode.OAUTH_ACCOUNT_ALREADY_BOUND);
        }
    }

    /**
     * 自动生成登录名，格式为 oauth_{随机8位}。
     *
     * @return 生成的登录名
     */
    private String generateLoginName() {
        String randomSuffix = String.format("%08d", new Random().nextInt(100000000));
        return "oauth_" + randomSuffix;
    }

    /**
     * 构建用户实体（accountSettled = false）。
     */
    private UserEntity buildUser(RegisterRequest request, Long tenantId, String loginName) {
        UserEntity user = new UserEntity();
        user.setTenantId(tenantId);
        user.setLoginName(loginName);
        user.setUserName(request.getUserName());
        user.setPhone(request.getPhone());
        user.setEmail(request.getEmail());
        user.setStatus(0); // 0-正常
        user.setRegisterMode("OAUTH");
        user.setAccountSettled(0); // false
        return user;
    }

    /**
     * 创建 OAuth 账号绑定记录。
     *
     * @param userId   用户 ID
     * @param provider OAuth 提供商
     * @param openId   OAuth openId
     */
    private void createOAuthAccount(Long userId, String provider, String openId) {
        OAuthAccountEntity oauthAccount = new OAuthAccountEntity();
        oauthAccount.setUserId(userId);
        oauthAccount.setOauthProvider(provider);
        oauthAccount.setOauthOpenId(openId);
        oauthAccount.setBoundTime(LocalDateTime.now());
        oauthAccountMapper.insert(oauthAccount);
    }

    /**
     * 为用户分配默认角色。
     */
    private void assignDefaultRole(UserEntity user) {
        LambdaQueryWrapper<RoleEntity> queryWrapper = Wrappers.lambdaQuery(RoleEntity.class)
                .eq(RoleEntity::getTenantId, user.getTenantId())
                .eq(RoleEntity::getRoleCode, DEFAULT_ROLE_CODE)
                .eq(RoleEntity::getStatus, 0)
                .last("LIMIT 1");

        RoleEntity defaultRole = roleMapper.selectOne(queryWrapper);
        if (defaultRole != null) {
            UserRoleEntity userRole = new UserRoleEntity();
            userRole.setUserId(user.getId());
            userRole.setRoleId(defaultRole.getId());
            userRoleMapper.insert(userRole);
            log.info("默认角色分配成功 | userId={} | roleId={} | roleCode={}",
                    user.getId(), defaultRole.getId(), DEFAULT_ROLE_CODE);
        } else {
            log.warn("默认角色不存在 | tenantId={} | roleCode={}", user.getTenantId(), DEFAULT_ROLE_CODE);
        }
    }

    /**
     * 生成 Token 对并创建登录态会话（自动登录）。
     */
    private TokenPairDTO generateTokenPair(UserEntity user, TenantEntity tenant) {
        java.util.List<String> roles = userMapper.selectRoleCodesByUserId(user.getId());
        java.util.List<String> permissions = userMapper.selectPermissionCodesByUserId(user.getId());

        LoginUserDTO loginUser = LoginUserDTO.builder()
                .userId(user.getId())
                .tenantId(tenant.getId())
                .userName(user.getUserName())
                .clientType("H5")
                .roles(roles != null ? new ArrayList<>(roles) : new ArrayList<>())
                .permissions(permissions != null ? new ArrayList<>(permissions) : new ArrayList<>())
                .build();

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

        try {
            loginSessionService.createSession(user.getId(), "H5",
                    loginUser, refreshTokenExpiration);
        } catch (Exception e) {
            log.error("创建登录态会话失败 | userId={}", user.getId(), e);
        }

        return tokenPair;
    }
}
