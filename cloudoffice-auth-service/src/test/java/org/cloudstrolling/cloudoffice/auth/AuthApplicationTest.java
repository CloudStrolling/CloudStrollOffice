/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth;

import org.cloudstrolling.cloudoffice.auth.util.JwtUtils;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * Auth 应用启动类测试。
 *
 * <p>验证 Spring 上下文可以正常加载，以及 JwtUtils Bean 注入正常。</p>
 *
 * @author CloudStroll Office
 */
@SpringBootTest(classes = AuthApplication.class, properties = {
        "spring.cloud.nacos.discovery.enabled=false",
        "spring.cloud.nacos.config.enabled=false",
        "spring.cloud.nacos.config.import-check.enabled=false",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration",
        "jwt.secret=testSecretKeyThatIsLongEnoughForHS256Algorithm1234567890"
})
class AuthApplicationTest {

    @Autowired(required = false)
    private JwtUtils jwtUtils;

    /**
     * 测试 Spring 上下文能否正常加载。
     */
    @Test
    void contextLoads_shouldLoadSuccessfully_whenApplicationStarts() {
        // Spring 上下文已通过 @SpringBootTest 自动加载
        // 若测试方法执行成功，说明上下文加载正常
        assertNotNull(AuthApplication.class);
    }

    /**
     * 验证 JwtUtils Bean 存在且可用。
     */
    @Test
    void jwtUtils_shouldBeLoaded_whenContextIsReady() {
        // Then: JwtUtils Bean 应被注入
        assertNotNull(jwtUtils, "JwtUtils Bean 应能被 Spring 上下文加载");
    }

    /**
     * 验证 @EnableDiscoveryClient 注解存在于启动类上。
     */
    @Test
    void enableDiscoveryClient_shouldBePresent_whenAnnotationCheck() {
        // Given: AuthApplication 启动类
        // When: 检查 @EnableDiscoveryClient 注解
        EnableDiscoveryClient annotation = AuthApplication.class.getAnnotation(EnableDiscoveryClient.class);

        // Then: 注解应存在
        assertNotNull(annotation, "AuthApplication 应标注 @EnableDiscoveryClient 注解");
    }
}
