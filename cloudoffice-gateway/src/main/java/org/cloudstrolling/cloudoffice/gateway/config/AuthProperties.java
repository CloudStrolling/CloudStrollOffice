/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * 认证相关配置属性类。
 *
 * <p>从 {@code application.yml} 中读取 {@code auth.*} 前缀的配置项，
 * 当前用于管理网关白名单路径列表。</p>
 *
 * @author CloudStroll Office
 */
@Data
@Component
@ConfigurationProperties(prefix = "auth")
public class AuthProperties {

    /**
     * 白名单路径列表。
     *
     * <p>请求路径匹配白名单的请求将被 {@code AuthFilter} 直接放行，
     * 无需进行 Token 校验。支持 Ant 风格路径匹配（如 {@code /swagger-ui/**}）。</p>
     */
    private List<String> whiteList = new ArrayList<>();
}
