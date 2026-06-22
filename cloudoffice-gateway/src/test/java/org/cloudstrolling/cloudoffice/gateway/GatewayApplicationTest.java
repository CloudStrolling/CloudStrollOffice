/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway;

import org.cloudstrolling.cloudoffice.gateway.TestRsaKeyProvider;
import org.junit.jupiter.api.Test;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * Gateway 应用启动类测试。
 *
 * <p>验证 Spring 上下文可以正常加载，以及 @EnableDiscoveryClient 注解存在。</p>
 *
 * @author CloudStroll Office
 */
@SpringBootTest(classes = GatewayApplication.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
        "spring.cloud.nacos.discovery.enabled=false",
        "spring.cloud.nacos.config.enabled=false",
        "spring.cloud.nacos.config.import-check.enabled=false",
        "spring.main.web-application-type=reactive",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration,org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,com.baomidou.mybatisplus.autoconfigure.MybatisPlusAutoConfiguration",
        "auth.rsa.public-key=${test.rsa.public-key}"
})
class GatewayApplicationTest {
    static { TestRsaKeyProvider.initialize(); }

    /**
     * 测试 Spring 上下文能否正常加载。
     */
    @Test
    void contextLoads_shouldLoadSuccessfully_whenApplicationStarts() {
        // Spring 上下文已通过 @SpringBootTest 自动加载
        // 若测试方法执行成功，说明上下文加载正常
        assertNotNull(GatewayApplication.class);
    }

    /**
     * 验证 @EnableDiscoveryClient 注解存在于启动类上。
     */
    @Test
    void enableDiscoveryClient_shouldBePresent_whenAnnotationCheck() {
        // Given: GatewayApplication 启动类
        // When: 检查 @EnableDiscoveryClient 注解
        EnableDiscoveryClient annotation = GatewayApplication.class.getAnnotation(EnableDiscoveryClient.class);

        // Then: 注解应存在
        assertNotNull(annotation, "GatewayApplication 应标注 @EnableDiscoveryClient 注解");
    }

    /**
     * 验证 @SpringBootApplication 注解存在于启动类上。
     */
    @Test
    void springBootApplication_shouldBePresent_whenAnnotationCheck() {
        // Given: GatewayApplication 启动类
        // When: 检查 @SpringBootApplication 注解
        SpringBootApplication annotation = GatewayApplication.class.getAnnotation(SpringBootApplication.class);

        // Then: 注解应存在
        assertNotNull(annotation, "GatewayApplication 应标注 @SpringBootApplication 注解");
    }
}
