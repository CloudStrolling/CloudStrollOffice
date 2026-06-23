/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.enums.LoginModeEnum;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 登录策略工厂。
 *
 * <p>管理所有登录策略的实现，根据登录模式编码获取对应的策略实例。
 * 使用 {@link PostConstruct} 初始化时将所有策略注册到策略映射表中。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class LoginStrategyFactory {

    /** 策略映射表，key 为登录模式编码，value 为对应策略实现 */
    private final Map<String, LoginStrategy> strategyMap = new ConcurrentHashMap<>();

    /** 用户名+密码登录策略 */
    private final UsernamePasswordStrategy usernamePasswordStrategy;

    /** 手机+验证码登录策略 */
    private final PhoneCodeLoginStrategy phoneCodeLoginStrategy;

    /** 手机+密码登录策略 */
    private final PhonePasswordLoginStrategy phonePasswordLoginStrategy;

    /** OAuth 第三方登录策略 */
    private final OAuthLoginStrategy oauthLoginStrategy;

    /**
     * 初始化策略映射表。
     *
     * <p>将所有支持的登录策略注册到 strategyMap 中，以便根据登录模式快速查找。</p>
     */
    @PostConstruct
    public void init() {
        strategyMap.put(LoginModeEnum.USERNAME_PASSWORD.getCode(), usernamePasswordStrategy);
        strategyMap.put(LoginModeEnum.PHONE_CODE.getCode(), phoneCodeLoginStrategy);
        strategyMap.put(LoginModeEnum.PHONE_PASSWORD.getCode(), phonePasswordLoginStrategy);
        strategyMap.put(LoginModeEnum.OAUTH.getCode(), oauthLoginStrategy);
        log.info("登录策略工厂初始化完成，注册策略数: {}", strategyMap.size());
    }

    /**
     * 根据登录模式编码获取对应的登录策略。
     *
     * @param loginMode 登录模式编码（如 USERNAME_PASSWORD、PHONE_CODE 等）
     * @return 匹配的登录策略实例
     * @throws BusinessException 如果传入的登录模式编码无效，抛出 LOGIN_MODE_INVALID 异常
     */
    public LoginStrategy getStrategy(String loginMode) {
        LoginStrategy strategy = strategyMap.get(loginMode);
        if (strategy == null) {
            log.warn("无效的登录模式: {}", loginMode);
            throw new BusinessException(ErrorCode.LOGIN_MODE_INVALID);
        }
        return strategy;
    }
}
