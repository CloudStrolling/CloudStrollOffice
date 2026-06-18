/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.cloud;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

import static org.junit.jupiter.api.Assertions.assertNotNull;

/**
 * Cloud 应用启动类测试。
 *
 * <p>验证 Spring 上下文可以正常加载。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@SpringBootTest(classes = CloudApplication.class, properties = {
        "spring.cloud.nacos.discovery.enabled=false",
        "spring.cloud.nacos.config.enabled=false",
        "spring.cloud.nacos.config.import-check.enabled=false",
        "spring.autoconfigure.exclude=org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration"
})
class CloudApplicationTest {

    /**
     * 测试 Spring 上下文能否正常加载。
     */
    @Test
    void contextLoads_shouldLoadSuccessfully_whenApplicationStarts() {
        // Spring 上下文已通过 @SpringBootTest 自动加载
        // 若测试方法执行成功，说明上下文加载正常
        assertNotNull(CloudApplication.class);
    }

    /**
     * 验证 @EnableDiscoveryClient 注解存在于启动类上。
     */
    @Test
    void enableDiscoveryClient_shouldBePresent_whenAnnotationCheck() {
        // Given: CloudApplication 启动类
        // When: 检查 @EnableDiscoveryClient 注解
        EnableDiscoveryClient annotation = CloudApplication.class.getAnnotation(EnableDiscoveryClient.class);

        // Then: 注解应存在
        assertNotNull(annotation, "CloudApplication 应标注 @EnableDiscoveryClient 注解");
    }
}
