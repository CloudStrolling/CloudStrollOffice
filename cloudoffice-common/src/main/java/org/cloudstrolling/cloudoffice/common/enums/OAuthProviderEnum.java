/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.enums;

import lombok.Getter;

import java.io.Serializable;
import java.util.Arrays;

/**
 * OAuth 提供商枚举。
 * <p>
 * 定义系统支持的第三方 OAuth 认证提供商，包含微信、钉钉、企业微信、支付宝等。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Getter
public enum OAuthProviderEnum implements Serializable {

    /** 微信 */
    WECHAT("WECHAT", "微信"),

    /** 钉钉 */
    DINGTALK("DINGTALK", "钉钉"),

    /** 企业微信 */
    WECHAT_WORK("WECHAT_WORK", "企业微信"),

    /** 支付宝 */
    ALIPAY("ALIPAY", "支付宝");

    /** 提供商编码 */
    private final String code;

    /** 提供商名称 */
    private final String label;

    OAuthProviderEnum(String code, String label) {
        this.code = code;
        this.label = label;
    }

    /**
     * 根据编码查询 OAuth 提供商，大小写不敏感。
     *
     * @param code 提供商编码，可为 null
     * @return 匹配的枚举常量，若未找到则返回 null
     */
    public static OAuthProviderEnum fromCode(String code) {
        if (code == null) {
            return null;
        }
        return Arrays.stream(values())
                .filter(provider -> provider.code.equalsIgnoreCase(code))
                .findFirst()
                .orElse(null);
    }
}
