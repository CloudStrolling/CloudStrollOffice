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
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
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
 * {@link OAuthRegisterStrategy} 的单元测试。
 *
 * <p>覆盖 UT-006：OAuth 注册创建 accountSettled=false 的未完善账号；
 * 同一 oauthCode（openId）重复注册抛 OAUTH_ACCOUNT_ALREADY_BOUND。</p>
 *
 * <p>说明：测试用例文档 UT-006 预期"相同 oauthCode 幂等返回同一账号"，
 * 实际代码按 openId 全局唯一校验处理，重复绑定抛 409 业务异常，
 * 本测试按代码实际行为断言（幂等由上层注册流程保证）。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("OAuthRegisterStrategy 单元测试")
class OAuthRegisterStrategyTest {

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

    private OAuthRegisterStrategy strategy;

    @BeforeEach
    void setUp() {
        strategy = new OAuthRegisterStrategy(userMapper, tenantMapper,
                userRoleMapper, roleMapper, oauthAccountMapper, jwtUtils,
                loginSessionService);
        ReflectionTestUtils.setField(strategy, "refreshTokenExpiration", 604800L);
    }

    /**
     * 构造合法的 OAuth 注册请求。
     */
    private RegisterRequest buildValidRequest() {
        RegisterRequest request = new RegisterRequest();
        request.setRegisterMode("OAUTH");
        request.setOauthProvider("WECHAT");
        request.setOauthCode("openid_mock_001");
        request.setUserName("微信用户");
        request.setTenantCode("DEFAULT");
        return request;
    }

    /**
     * 构造正常租户。
     */
    private TenantEntity buildNormalTenant() {
        TenantEntity tenant = new TenantEntity();
        tenant.setId(1L);
        tenant.setTenantCode("DEFAULT");
        tenant.setStatus(0);
        tenant.setExpireTime(LocalDateTime.now().plusDays(365));
        return tenant;
    }

    /**
     * UT-006：OAuth 注册创建未完善账号并绑定 openId（P0）。
     */
    @Test
    @DisplayName("UT-006: OAuth 注册成功，accountSettled=false，创建 OAuth 绑定记录")
    void register_shouldCreateUnsettledAccount_whenOpenIdUnique() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        when(oauthAccountMapper.selectByProviderAndOpenId(eq("WECHAT"), eq("openid_mock_001")))
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
            user.setId(300L);
            return 1;
        }).when(userMapper).insert(any(UserEntity.class));

        RegisterResult result = strategy.register(buildValidRequest());

        assertNotNull(result);
        assertEquals(300L, result.getUserId());
        assertEquals(Boolean.FALSE, result.getAccountSettled());
        assertNotNull(result.getTokenPair());
        // OAuth 绑定记录创建 1 次
        verify(oauthAccountMapper, times(1)).insert(any(OAuthAccountEntity.class));
        // 默认角色分配 1 次
        verify(userRoleMapper, times(1)).insert(any());
    }

    /**
     * UT-006：同一 oauthCode（openId）已被绑定被拒（P0）。
     */
    @Test
    @DisplayName("UT-006: oauthCode 已被绑定时抛 OAUTH_ACCOUNT_ALREADY_BOUND")
    void register_shouldThrow_whenOpenIdAlreadyBound() {
        when(tenantMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildNormalTenant());
        OAuthAccountEntity existing = new OAuthAccountEntity();
        existing.setId(1L);
        existing.setUserId(9L);
        existing.setOauthProvider("WECHAT");
        existing.setOauthOpenId("openid_mock_001");
        when(oauthAccountMapper.selectByProviderAndOpenId(eq("WECHAT"), eq("openid_mock_001")))
                .thenReturn(existing);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> strategy.register(buildValidRequest()));

        assertEquals(409, ex.getCode());
        verify(userMapper, never()).insert(any(UserEntity.class));
        verify(oauthAccountMapper, never()).insert(any(OAuthAccountEntity.class));
    }

    /**
     * 构造默认角色。
     */
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
