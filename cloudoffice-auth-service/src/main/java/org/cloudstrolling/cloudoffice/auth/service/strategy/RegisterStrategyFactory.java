/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.strategy;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.enums.RegisterModeEnum;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 注册策略工厂。
 *
 * <p>管理所有注册策略的实现，根据注册模式编码获取对应的策略实例。
 * 使用 {@link PostConstruct} 初始化时将所有策略注册到策略映射表中。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class RegisterStrategyFactory {

    /** 策略映射表，key 为注册模式编码，value 为对应策略实现 */
    private final Map<String, RegisterStrategy> strategyMap = new ConcurrentHashMap<>();

    /** 用户名+密码注册策略 */
    private final UsernamePwdRegisterStrategy usernamePwdStrategy;

    /** 手机+验证码注册策略 */
    private final PhoneCodeRegisterStrategy phoneCodeStrategy;

    /** OAuth 第三方注册策略 */
    private final OAuthRegisterStrategy oauthStrategy;

    /** 手机注册后设置用户名策略 */
    private final PhoneSetUsernameStrategy phoneSetUsernameStrategy;

    /** OAuth 注册后设置信息策略 */
    private final OAuthSetInfoStrategy oauthSetInfoStrategy;

    /**
     * 初始化策略映射表。
     *
     * <p>将所有支持的注册策略注册到 strategyMap 中，以便根据注册模式快速查找。</p>
     */
    @PostConstruct
    public void init() {
        strategyMap.put(RegisterModeEnum.USERNAME.getCode(), usernamePwdStrategy);
        strategyMap.put(RegisterModeEnum.PHONE_CODE.getCode(), phoneCodeStrategy);
        strategyMap.put(RegisterModeEnum.OAUTH.getCode(), oauthStrategy);
        strategyMap.put(RegisterModeEnum.PHONE_SET_USERNAME.getCode(), phoneSetUsernameStrategy);
        strategyMap.put(RegisterModeEnum.OAUTH_SET_INFO.getCode(), oauthSetInfoStrategy);
        log.info("注册策略工厂初始化完成，注册策略数: {}", strategyMap.size());
    }

    /**
     * 根据注册模式编码获取对应的注册策略。
     *
     * @param registerMode 注册模式编码（如 USERNAME、PHONE_CODE、OAUTH 等）
     * @return 匹配的注册策略实例
     * @throws BusinessException 如果传入的注册模式编码无效，抛出 REGISTER_MODE_INVALID 异常
     */
    public RegisterStrategy getStrategy(String registerMode) {
        RegisterStrategy strategy = strategyMap.get(registerMode);
        if (strategy == null) {
            log.warn("无效的注册模式: {}", registerMode);
            throw new BusinessException(ErrorCode.REGISTER_MODE_INVALID);
        }
        return strategy;
    }
}
