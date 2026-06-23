/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * Auth 应用启动类测试。
 *
 * <p>轻量级测试，验证启动类基本结构和关键注解，无需加载 Spring 上下文。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("AuthApplication 启动类测试")
class AuthApplicationTest {

    /**
     * 测试 AuthApplication 启动类存在。
     */
    @Test
    void contextLoads_shouldLoadSuccessfully_whenApplicationStarts() {
        assertNotNull(AuthApplication.class, "AuthApplication 类应存在");
    }

    /**
     * 验证 @EnableDiscoveryClient 注解存在于启动类上。
     */
    @Test
    void enableDiscoveryClient_shouldBePresent_whenAnnotationCheck() {
        EnableDiscoveryClient annotation = AuthApplication.class.getAnnotation(EnableDiscoveryClient.class);
        assertNotNull(annotation, "AuthApplication 应标注 @EnableDiscoveryClient 注解");
    }
}
