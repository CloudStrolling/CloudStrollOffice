/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.enums;

import lombok.Getter;

import java.io.Serializable;
import java.util.Arrays;

/**
 * 登录模式枚举。
 * <p>
 * 定义系统支持的登录方式，包含用户名密码登录、手机验证码登录、手机密码登录、
 * 第三方 OAuth 登录等模式。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Getter
public enum LoginModeEnum implements Serializable {

    /** 用户名+密码登录 */
    USERNAME_PASSWORD("USERNAME_PASSWORD", "用户名+密码登录"),

    /** 手机+验证码登录 */
    PHONE_CODE("PHONE_CODE", "手机+验证码登录"),

    /** 手机+密码登录 */
    PHONE_PASSWORD("PHONE_PASSWORD", "手机+密码登录"),

    /** 第三方 OAuth 登录 */
    OAUTH("OAUTH", "第三方OAuth登录");

    /** 模式编码 */
    private final String code;

    /** 模式描述 */
    private final String label;

    LoginModeEnum(String code, String label) {
        this.code = code;
        this.label = label;
    }

    /**
     * 根据编码查询登录模式，大小写不敏感。
     *
     * @param code 登录模式编码，可为 null
     * @return 匹配的枚举常量，若未找到则返回 null
     */
    public static LoginModeEnum fromCode(String code) {
        if (code == null) {
            return null;
        }
        return Arrays.stream(values())
                .filter(mode -> mode.code.equalsIgnoreCase(code))
                .findFirst()
                .orElse(null);
    }
}
