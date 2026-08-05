/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.gateway.config;

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.ReactiveRedisConnectionFactory;
import org.springframework.data.redis.core.ReactiveRedisTemplate;
import org.springframework.data.redis.serializer.Jackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * Redis 配置类。
 *
 * <p>配置响应式 Redis 客户端 {@link ReactiveRedisTemplate} Bean，
 * 用于在网关中非阻塞地查询 Token 黑名单、登录态会话、账号状态和租户状态。
 * 使用 Lettuce 作为底层响应式 Redis 驱动。</p>
 *
 * <p><b>序列化配置：</b></p>
 * <ul>
 *   <li>Key 序列化：{@link StringRedisSerializer} (UTF-8)</li>
 *   <li>Value 序列化：{@link Jackson2JsonRedisSerializer} (JSON)</li>
 *   <li>Hash Key 序列化：{@link StringRedisSerializer} (UTF-8)</li>
 *   <li>Hash Value 序列化：{@link Jackson2JsonRedisSerializer} (JSON)</li>
 * </ul>
 *
 * @author CloudStroll Office
 */
@Configuration
public class RedisConfig {

    /**
     * 创建响应式 Redis 模板 Bean。
     *
     * <p>该 Bean 专为 Spring Cloud Gateway 的 WebFlux 响应式模型设计，
     * 使用非阻塞 I/O 操作 Redis，避免阻塞网关事件循环线程。</p>
     *
     * @param factory 响应式 Redis 连接工厂（由 Spring Boot 自动配置）
     * @return 配置完成的响应式 Redis 模板
     */
    @Bean
    public ReactiveRedisTemplate<String, Object> reactiveRedisTemplate(
            ReactiveRedisConnectionFactory factory) {
        // Value 序列化：Jackson JSON
        Jackson2JsonRedisSerializer<Object> jsonSerializer =
                new Jackson2JsonRedisSerializer<>(Object.class);
        ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        jsonSerializer.setObjectMapper(objectMapper);

        // Key 序列化：String
        StringRedisSerializer stringSerializer = new StringRedisSerializer();

        // 构建序列化上下文
        RedisSerializationContext<String, Object> serializationContext =
                RedisSerializationContext
                        .<String, Object>newSerializationContext()
                        .key(stringSerializer)
                        .value(jsonSerializer)
                        .hashKey(stringSerializer)
                        .hashValue(jsonSerializer)
                        .build();

        return new ReactiveRedisTemplate<>(factory, serializationContext);
    }
}
