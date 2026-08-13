package org.cloudstrolling.cloudoffice.common.cache;

import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.config.ConfigProperties;
import org.cloudstrolling.cloudoffice.common.constant.RedisKeyConstants;
import org.cloudstrolling.cloudoffice.common.util.JsonUtils;
import org.cloudstrolling.cloudoffice.common.vo.ConfigItemVO;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.List;

/**
 * 通用配置缓存管理器（ConfigCacheManager）。
 *
 * <p>管理以微服务名称为粒度的通用配置本地缓存（Redis）：</p>
 * <ul>
 *   <li>缓存键：{@code common:config:{serviceName}}（见 RedisKeyConstants）</li>
 *   <li>缓存值：已脱敏的 {@link ConfigItemVO} 列表，以 JSON 字符串存储（不存敏感明文）</li>
 *   <li>TTL：默认 300 秒，可由 common 配置 {@code common.config.cache-ttl-seconds} 覆盖</li>
 * </ul>
 *
 * <p>安全说明：缓存值统一以 JSON 字符串存储（Redis Value 序列化器为 StringRedisSerializer），
 * 读取时通过 {@link JsonUtils#parseArray} 绑定固定类型 {@code List<ConfigItemVO>} 反序列化，
 * 不携带也不解析 {@code @class} 多态类型信息（v0.2.8 S-01 修复）。</p>
 *
 * <p>本版本仅提供查询相关缓存读写与按服务名失效能力；
 * 配置变更触发的失效在后续增删改接口版本接入。</p>
 *
 * @author CloudStroll Office
 */
@Slf4j
@Component
public class ConfigCacheManager {

    private final RedisTemplate<String, String> redisTemplate;
    private final ConfigProperties configProperties;

    /**
     * 构造器注入 RedisTemplate 与配置属性。
     *
     * @param redisTemplate    Redis 操作模板（Value 为 JSON 字符串）
     * @param configProperties 通用配置管理属性（缓存 TTL）
     */
    public ConfigCacheManager(RedisTemplate<String, String> redisTemplate, ConfigProperties configProperties) {
        this.redisTemplate = redisTemplate;
        this.configProperties = configProperties;
    }

    /**
     * 读取指定微服务名称的缓存配置项列表。
     *
     * @param serviceName 微服务名称
     * @return 配置项列表（已脱敏），缓存未命中时返回 null
     */
    public List<ConfigItemVO> getCachedConfigs(String serviceName) {
        try {
            String json = redisTemplate.opsForValue().get(RedisKeyConstants.buildConfigCacheKey(serviceName));
            if (json == null) {
                return null;
            }
            return JsonUtils.parseArray(json, ConfigItemVO.class);
        } catch (Exception e) {
            log.warn("读取通用配置缓存失败 | serviceName={} | 原因={}", serviceName, e.getMessage());
            return null;
        }
    }

    /**
     * 将指定微服务名称的配置项列表写入缓存（覆盖写，设置 TTL）。
     *
     * @param serviceName 微服务名称
     * @param configs     配置项列表（必须为已脱敏数据）
     */
    public void cacheConfigs(String serviceName, List<ConfigItemVO> configs) {
        try {
            redisTemplate.opsForValue().set(
                    RedisKeyConstants.buildConfigCacheKey(serviceName),
                    JsonUtils.toJsonString(configs),
                    Duration.ofSeconds(configProperties.getCacheTtlSeconds()));
        } catch (Exception e) {
            log.warn("写入通用配置缓存失败 | serviceName={} | 原因={}", serviceName, e.getMessage());
        }
    }

    /**
     * 失效指定微服务名称的缓存。
     *
     * @param serviceName 微服务名称
     */
    public void evict(String serviceName) {
        try {
            redisTemplate.delete(RedisKeyConstants.buildConfigCacheKey(serviceName));
        } catch (Exception e) {
            log.warn("失效通用配置缓存失败 | serviceName={} | 原因={}", serviceName, e.getMessage());
        }
    }
}
