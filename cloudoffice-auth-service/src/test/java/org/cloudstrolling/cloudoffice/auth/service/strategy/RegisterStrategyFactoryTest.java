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
 * {@link RegisterStrategyFactory} 的单元测试。
 *
 * <p>覆盖 UT-007、UT-008：注册策略工厂 5 种策略全部注册；
 * 无效注册模式抛 REGISTER_MODE_INVALID。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("RegisterStrategyFactory 单元测试")
class RegisterStrategyFactoryTest {

    @Mock
    private UsernamePwdRegisterStrategy usernamePwdStrategy;

    @Mock
    private PhoneCodeRegisterStrategy phoneCodeStrategy;

    @Mock
    private OAuthRegisterStrategy oauthStrategy;

    @Mock
    private PhoneSetUsernameStrategy phoneSetUsernameStrategy;

    @Mock
    private OAuthSetInfoStrategy oauthSetInfoStrategy;

    private RegisterStrategyFactory factory;

    @BeforeEach
    void setUp() {
        factory = new RegisterStrategyFactory(usernamePwdStrategy, phoneCodeStrategy,
                oauthStrategy, phoneSetUsernameStrategy, oauthSetInfoStrategy);
        factory.init();
    }

    /**
     * UT-008：5 种注册模式均返回对应策略实例（P0）。
     */
    @Test
    @DisplayName("UT-008: 注册工厂注册 USERNAME/PHONE_CODE/OAUTH/PHONE_SET_USERNAME/OAUTH_SET_INFO 五种策略")
    void getStrategy_shouldReturnAllRegisteredStrategies() {
        assertSame(usernamePwdStrategy, factory.getStrategy("USERNAME"));
        assertSame(phoneCodeStrategy, factory.getStrategy("PHONE_CODE"));
        assertSame(oauthStrategy, factory.getStrategy("OAUTH"));
        assertSame(phoneSetUsernameStrategy, factory.getStrategy("PHONE_SET_USERNAME"));
        assertSame(oauthSetInfoStrategy, factory.getStrategy("OAUTH_SET_INFO"));
    }

    /**
     * UT-007：无效注册模式抛 REGISTER_MODE_INVALID（P0）。
     */
    @Test
    @DisplayName("UT-007: 无效注册模式 UNKNOWN 抛 REGISTER_MODE_INVALID")
    void getStrategy_shouldThrow_whenModeInvalid() {
        BusinessException ex = assertThrows(BusinessException.class,
                () -> factory.getStrategy("UNKNOWN"));
        assertEquals(400, ex.getCode());
        assertTrue(ex.getMessage().contains("无效的注册模式"));
    }
}
