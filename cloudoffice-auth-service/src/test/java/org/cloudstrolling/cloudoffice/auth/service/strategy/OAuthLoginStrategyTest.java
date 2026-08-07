/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.AuthResult;
import org.cloudstrolling.cloudoffice.auth.entity.OAuthAccountEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.OAuthAccountMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link OAuthLoginStrategy} 的单元测试。
 *
 * <p>覆盖 UT-017：OAuth 账号关联存在时认证成功；
 * 未绑定时抛 OAUTH_ACCOUNT_NOT_BOUND。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("OAuthLoginStrategy 单元测试")
class OAuthLoginStrategyTest {

    @Mock
    private OAuthAccountMapper oauthAccountMapper;

    @Mock
    private UserMapper userMapper;

    private OAuthLoginStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new OAuthLoginStrategy(oauthAccountMapper, userMapper);
    }

    private LoginRequest buildRequest() {
        LoginRequest request = new LoginRequest();
        request.setLoginMode("OAUTH");
        request.setOauthProvider("WECHAT");
        request.setOauthCode("openid_wechat_001");
        request.setTenantCode("DEFAULT");
        request.setClientType("WECHAT_MINI");
        return request;
    }

    private OAuthAccountEntity buildOAuthAccount() {
        OAuthAccountEntity account = new OAuthAccountEntity();
        account.setId(1L);
        account.setUserId(5L);
        account.setOauthProvider("WECHAT");
        account.setOauthOpenId("openid_wechat_001");
        return account;
    }

    private UserEntity buildUser() {
        UserEntity user = new UserEntity();
        user.setId(5L);
        user.setTenantId(1L);
        user.setLoginName("oauth_00000001");
        user.setUserName("微信用户");
        user.setStatus(0);
        return user;
    }

    /**
     * UT-017：OAuth 绑定关系存在时认证成功（P1）。
     */
    @Test
    @DisplayName("UT-017: OAuth 账号已绑定且用户存在时认证成功")
    void authenticate_shouldReturnAuthResult_whenAccountBound() {
        when(oauthAccountMapper.selectByProviderAndOpenId(eq("WECHAT"), eq("openid_wechat_001")))
                .thenReturn(buildOAuthAccount());
        when(userMapper.selectById(5L)).thenReturn(buildUser());
        when(userMapper.selectRoleCodesByUserId(5L))
                .thenReturn(Collections.singletonList("user"));
        when(userMapper.selectPermissionCodesByUserId(5L))
                .thenReturn(Collections.emptyList());

        AuthResult result = strategy.authenticate(buildRequest());

        assertNotNull(result);
        assertEquals(5L, result.getUserId());
        assertEquals(1L, result.getTenantId());
        assertEquals(1, result.getRoles().size());
    }

    /**
     * UT-017：OAuth 账号未绑定时抛 OAUTH_ACCOUNT_NOT_BOUND（P1）。
     */
    @Test
    @DisplayName("UT-017: OAuth 账号未绑定时抛 OAUTH_ACCOUNT_NOT_BOUND")
    void authenticate_shouldThrow_whenAccountNotBound() {
        when(oauthAccountMapper.selectByProviderAndOpenId(eq("WECHAT"), eq("openid_wechat_001")))
                .thenReturn(null);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.authenticate(buildRequest()));
        assertEquals(404, ex.getCode());
        assertEquals("第三方账号未绑定", ex.getMessage());
        verify(userMapper, never()).selectById(anyLong());
    }
}
