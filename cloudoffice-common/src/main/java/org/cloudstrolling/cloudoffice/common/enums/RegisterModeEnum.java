/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.enums;

import lombok.Getter;

import java.io.Serializable;
import java.util.Arrays;

/**
 * 注册模式枚举。
 * <p>
 * 定义系统支持的注册方式，包含用户名密码注册、手机验证码注册、第三方 OAuth 注册等模式，
 * 并标识各模式是否需要手机号。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Getter
public enum RegisterModeEnum implements Serializable {

    /** 用户名+密码+手机号注册 */
    USERNAME("USERNAME", "用户名+密码+手机号注册", true),

    /** 手机+短信验证码注册 */
    PHONE_CODE("PHONE_CODE", "手机+短信验证码注册", true),

    /** 第三方 OAuth 注册 */
    OAUTH("OAUTH", "第三方OAuth注册", false),

    /** 手机注册后设置用户名 */
    PHONE_SET_USERNAME("PHONE_SET_USERNAME", "手机注册后设置用户名", true),

    /** OAuth 注册后设置用户名、密码、手机 */
    OAUTH_SET_INFO("OAUTH_SET_INFO", "OAuth注册后设置用户名、密码、手机", false);

    /** 模式编码 */
    private final String code;

    /** 模式描述 */
    private final String label;

    /** 是否需要手机号 */
    private final boolean requiresPhone;

    RegisterModeEnum(String code, String label, boolean requiresPhone) {
        this.code = code;
        this.label = label;
        this.requiresPhone = requiresPhone;
    }

    /**
     * 根据编码查询注册模式，大小写不敏感。
     *
     * @param code 注册模式编码，可为 null
     * @return 匹配的枚举常量，若未找到则返回 null
     */
    public static RegisterModeEnum fromCode(String code) {
        if (code == null) {
            return null;
        }
        return Arrays.stream(values())
                .filter(mode -> mode.code.equalsIgnoreCase(code))
                .findFirst()
                .orElse(null);
    }
}
