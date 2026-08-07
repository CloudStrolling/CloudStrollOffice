/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.dto.result.RegisterResult;
import org.cloudstrolling.cloudoffice.auth.entity.OAuthAccountEntity;
import org.cloudstrolling.cloudoffice.auth.entity.RoleEntity;
import org.cloudstrolling.cloudoffice.auth.entity.TenantEntity;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.OAuthAccountMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.RoleMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.TenantMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.auth.mapper.UserRoleMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.time.LocalDateTime;
import java.util.Collections;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link OAuthSetInfoStrategy} 的单元测试。
 *
 * <p>覆盖 UT-009（OAuth 侧）：OAUTH_SET_INFO 模式创建未完善账号
 * （accountSettled=false）并绑定 OAuth openId。</p>
 *
 * <p>说明：测试用例文档 UT-009 描述"补全后 accountSettled=1"，
 * 实际代码中 OAUTH_SET_INFO 为两步注册第一步（创建未完善账号），
 * 账号补全（accountSettled 置 1）由账户补全接口（AccountSettlement）承担，
 * 本测试按代码实际行为断言。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("OAuthSetInfoStrategy 单元测试")
class OAuthSetInfoStrategyTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private TenantMapper tenantMapper;

    @Mock
    private UserRoleMapper userRoleMapper;

    @Mock
    private RoleMapper roleMapper;

    @Mock
    private OAuthAccountMapper oauthAccountMapper;

    @Mock
    private JwtUtils jwtUtils;

    @Mock
    private LoginSessionService loginSessionService;

    private OAuthSetInfoStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new OAuthSetInfoStrategy(userMapper, tenantMapper,
                userRoleMapper, roleMapper, oauthAccountMapper, jwtUtils,
                loginSessionService);
        ReflectionTestUtils.setField(strategy, "refreshTokenExpiration", 604800L);
    }

    /**
     * UT-009：OAUTH_SET_INFO 注册创建未完善账号并绑定 openId（P0）。
     */
    @Test
    @DisplayName("UT-009: OAuth 两步注册第一步创建 accountSettled=false 账号")
    void register_shouldCreateUnsettledOAuthAccount_whenOpenIdUnique() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(oauthAccountMapper.selectByProviderAndOpenId(anyString(), anyString()))
                .thenReturn(null);
        when(roleMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildDefaultRole());
        when(userMapper.selectRoleCodesByUserId(anyLong()))
                .thenReturn(Collections.singletonList("user"));
        when(userMapper.selectPermissionCodesByUserId(anyLong()))
                .thenReturn(Collections.emptyList());
        when(jwtUtils.generateAccessToken(any())).thenReturn("access.token.mock");
        when(jwtUtils.generateRefreshToken(any())).thenReturn("refresh.token.mock");
        when(jwtUtils.getAccessTokenExpiration()).thenReturn(7200L);
        doAnswer(invocation -> {
            UserEntity user = invocation.getArgument(0);
            user.setId(310L);
            return 1;
        }).when(userMapper).insert(any(UserEntity.class));

        RegisterRequest request = new RegisterRequest();
        request.setRegisterMode("OAUTH_SET_INFO");
        request.setOauthProvider("DINGTALK");
        request.setOauthCode("openid_dingtalk_001");
        request.setUserName("钉钉用户");
        request.setTenantCode("DEFAULT");

        RegisterResult result = strategy.register(request);

        assertNotNull(result);
        assertEquals(310L, result.getUserId());
        assertEquals(Boolean.FALSE, result.getAccountSettled());
        assertNotNull(result.getTokenPair());
        verify(oauthAccountMapper, times(1)).insert(any(OAuthAccountEntity.class));
    }

    private TenantEntity buildNormalTenant() {
        TenantEntity tenant = new TenantEntity();
        tenant.setId(1L);
        tenant.setTenantCode("DEFAULT");
        tenant.setStatus(0);
        tenant.setExpireTime(LocalDateTime.now().plusDays(365));
        return tenant;
    }

    private RoleEntity buildDefaultRole() {
        RoleEntity role = new RoleEntity();
        role.setId(1L);
        role.setTenantId(1L);
        role.setRoleCode("user");
        role.setRoleName("普通用户");
        role.setStatus(0);
        return role;
    }
}
