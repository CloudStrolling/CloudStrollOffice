/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;
import org.cloudstrolling.cloudoffice.auth.entity.OAuthAccountEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.OAuthAccountMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.common.exception.AuthException;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.stereotype.Component;
import org.springframework.util.Assert;

import java.util.List;

/**
 * OAuth 第三方登录策略。
 *
 * <p>处理第三方 OAuth 授权登录，通过与第三方平台交互验证授权码，
 * 获取用户信息并完成登录认证。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OAuthLoginStrategy implements LoginStrategy {

    private final OAuthAccountMapper oauthAccountMapper;
    private final UserMapper userMapper;

    @Override
    public AuthResult authenticate(LoginRequest request) {
        // 1. 校验 oauthProvider 和 oauthCode 不为空
        Assert.hasText(request.getOauthProvider(), "oauthProvider must not be empty");
        Assert.hasText(request.getOauthCode(), "oauthCode must not be empty");

        // 2. 通过 oauthProvider + oauthCode 查询绑定关系
        // oauthCode 作为 OAuth 平台的 openId
        OAuthAccountEntity oauthAccount = oauthAccountMapper.selectByProviderAndOpenId(
                request.getOauthProvider(), request.getOauthCode());
        if (oauthAccount == null) {
            log.warn("第三方账号未绑定 | oauthProvider={} | oauthCode={}",
                    request.getOauthProvider(), request.getOauthCode());
            throw new BusinessException(ErrorCode.OAUTH_ACCOUNT_NOT_BOUND);
        }

        // 3. 通过绑定的 userId 查询用户信息
        UserEntity user = userMapper.selectById(oauthAccount.getUserId());
        if (user == null) {
            log.warn("绑定用户不存在 | oauthAccountId={} | userId={}",
                    oauthAccount.getId(), oauthAccount.getUserId());
            throw new AuthException(ErrorCode.USER_NOT_FOUND);
        }

        // 4. 查询角色和权限列表
        List<String> roles = userMapper.selectRoleCodesByUserId(user.getId());
        List<String> permissions = userMapper.selectPermissionCodesByUserId(user.getId());

        // 5. 构建并返回 AuthResult
        log.info("OAuth 第三方登录成功 | userId={} | oauthProvider={} | openId={}",
                user.getId(), request.getOauthProvider(), request.getOauthCode());
        return AuthResult.builder()
                .userId(user.getId())
                .tenantId(user.getTenantId())
                .loginName(user.getLoginName())
                .userName(user.getUserName())
                .phone(user.getPhone())
                .roles(roles)
                .permissions(permissions)
                .build();
    }
}
