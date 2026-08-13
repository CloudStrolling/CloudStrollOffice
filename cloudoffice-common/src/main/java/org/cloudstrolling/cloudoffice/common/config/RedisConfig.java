package org.cloudstrolling.cloudoffice.common.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * Redis 配置类（cloudoffice-common）。
 *
 * <p>配置 {@link RedisTemplate} Bean，Key 与 Value 统一使用 {@link StringRedisSerializer}
 * （即 Value 以 JSON 字符串存储），供通用配置本地缓存（ConfigCacheManager）使用。</p>
 *
 * <p>安全说明：不使用 Jackson 的 {@code activateDefaultTyping}/{@code DefaultTyping}，
 * 序列化结果不携带 {@code @class} 多态类型信息；反序列化由 ConfigCacheManager
 * 通过 {@code JsonUtils.parseArray} 绑定固定类型 {@code List<ConfigItemVO>} 完成，
 * 从根本上消除 Jackson 多态反序列化（gadget chain）攻击面（v0.2.8 S-01 修复）。</p>
 *
 * @author CloudStroll Office
 */
@Configuration
public class RedisConfig {

    /**
     * 创建 RedisTemplate Bean，用于操作 Redis 缓存。
     * <ul>
     *   <li>Key 序列化：{@link StringRedisSerializer}</li>
     *   <li>Value 序列化：{@link StringRedisSerializer}（JSON 字符串，无类型信息）</li>
     * </ul>
     *
     * @param connectionFactory Redis 连接工厂
     * @return 配置完成的 RedisTemplate
     */
    @Bean
    public RedisTemplate<String, String> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, String> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);

        StringRedisSerializer stringSerializer = new StringRedisSerializer();
        template.setKeySerializer(stringSerializer);
        template.setHashKeySerializer(stringSerializer);
        template.setValueSerializer(stringSerializer);
        template.setHashValueSerializer(stringSerializer);
        template.afterPropertiesSet();

        return template;
    }
}
