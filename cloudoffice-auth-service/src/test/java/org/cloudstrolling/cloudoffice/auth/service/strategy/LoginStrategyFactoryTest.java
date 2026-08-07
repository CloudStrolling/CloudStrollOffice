/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import static org.junit.jupiter.api.Assertions.*;

/**
 * {@link LoginStrategyFactory} 的单元测试。
 *
 * <p>覆盖 UT-018：登录策略工厂注册 4 种策略；
 * 无效登录模式抛 LOGIN_MODE_INVALID。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("LoginStrategyFactory 单元测试")
class LoginStrategyFactoryTest {

    @Mock
    private UsernamePasswordStrategy usernamePasswordStrategy;

    @Mock
    private PhoneCodeLoginStrategy phoneCodeLoginStrategy;

    @Mock
    private PhonePasswordLoginStrategy phonePasswordLoginStrategy;

    @Mock
    private OAuthLoginStrategy oauthLoginStrategy;

    private LoginStrategyFactory factory;

    @BeforeEach
    void setUp() {
        factory = new LoginStrategyFactory(usernamePasswordStrategy, phoneCodeLoginStrategy,
                phonePasswordLoginStrategy, oauthLoginStrategy);
        factory.init();
    }

    /**
     * UT-018：4 种登录模式均返回对应策略实例（P0）。
     */
    @Test
    @DisplayName("UT-018: 登录工厂注册 USERNAME_PASSWORD/PHONE_CODE/PHONE_PASSWORD/OAUTH 四种策略")
    void getStrategy_shouldReturnAllRegisteredStrategies() {
        assertSame(usernamePasswordStrategy, factory.getStrategy("USERNAME_PASSWORD"));
        assertSame(phoneCodeLoginStrategy, factory.getStrategy("PHONE_CODE"));
        assertSame(phonePasswordLoginStrategy, factory.getStrategy("PHONE_PASSWORD"));
        assertSame(oauthLoginStrategy, factory.getStrategy("OAUTH"));
    }

    /**
     * UT-018：无效登录模式抛 LOGIN_MODE_INVALID（P0）。
     */
    @Test
    @DisplayName("UT-018: 无效登录模式 UNKNOWN 抛 LOGIN_MODE_INVALID")
    void getStrategy_shouldThrow_whenModeInvalid() {
        BusinessException ex = assertThrows(BusinessException.class,
                () -> factory.getStrategy("UNKNOWN"));
        assertEquals(400, ex.getCode());
        assertTrue(ex.getMessage().contains("无效的登录模式"));
    }
}
