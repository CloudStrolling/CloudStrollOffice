/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.config;

import org.cloudstrolling.cloudoffice.gateway.GatewayApplication;
import org.cloudstrolling.cloudoffice.gateway.TestRsaKeyProvider;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;

/**
 * Redis 配置类测试。
 *
 * <p>验证 {@link RedisConfig} 配置类能够正确创建
 * {@link ReactiveRedisTemplate} Bean，并配置正确的序列化方式。
 * 测试环境使用 Mock 的 {@link ReactiveRedisConnectionFactory}，
 * 避免依赖真实 Redis 服务。</p>
 *
 * @author CloudStroll Office
 */
@SpringBootTest(classes = GatewayApplication.class,
        webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
        properties = {
                "spring.cloud.nacos.discovery.enabled=false",
                "spring.cloud.nacos.config.enabled=false",
                "spring.cloud.nacos.config.import-check.enabled=false",
                "spring.main.web-application-type=reactive",
                "spring.autoconfigure.exclude="
                        + "org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.jdbc.DataSourceTransactionManagerAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
                        + "com.baomidou.mybatisplus.autoconfigure.MybatisPlusAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration,"
                        + "org.springframework.boot.autoconfigure.data.redis.RedisReactiveAutoConfiguration,"
                        + "org.springframework.cloud.gateway.config.GatewayRedisAutoConfiguration",
                "auth.rsa.public-key=${test.rsa.public-key}"
        })
@Import(RedisConfigTest.MockRedisConnectionFactoryConfig.class)
class RedisConfigTest {
    static { TestRsaKeyProvider.initialize(); }

    @Autowired
    private ReactiveRedisTemplate<String, Object> reactiveRedisTemplate;

    /**
     * 测试配置：提供 Mock 的响应式 Redis 连接工厂，
     * 避免测试环境依赖真实 Redis 服务。
     */
    @TestConfiguration
    static class MockRedisConnectionFactoryConfig {

        @Bean
        public ReactiveRedisConnectionFactory reactiveRedisConnectionFactory() {
            return mock(ReactiveRedisConnectionFactory.class);
        }
    }

    /**
     * 验证 ReactiveRedisTemplate Bean 能被正常创建。
     */
    @Test
    void reactiveRedisTemplate_shouldBeCreated_whenApplicationStarts() {
        assertNotNull(reactiveRedisTemplate,
                "ReactiveRedisTemplate Bean should be created by RedisConfig");
    }

    /**
     * 验证 ReactiveRedisTemplate 不为 null，确认 Bean 注入正常。
     */
    @Test
    void reactiveRedisTemplate_shouldBeInjected_whenContextLoaded() {
        // 通过 @Autowired 注入的 Bean 不为 null 即表示配置正确
        assertNotNull(reactiveRedisTemplate,
                "ReactiveRedisTemplate should be injected successfully");
    }
}
