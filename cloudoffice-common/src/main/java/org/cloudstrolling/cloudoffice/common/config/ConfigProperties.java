package org.cloudstrolling.cloudoffice.common.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

/**
 * 通用配置管理属性。
 *
 * <p>从配置文件读取通用配置管理的缓存与脱敏参数，支持通过
 * {@code common.config.*} 配置项覆盖默认值。</p>
 *
 * @author CloudStroll Office
 */
@Data
@Component
@ConfigurationProperties(prefix = "common.config")
public class ConfigProperties {

    /** 通用配置本地缓存 TTL（秒），默认 300（与 DBD 种子数据 common/config/cache-ttl-seconds 一致） */
    private long cacheTtlSeconds = 300;

    /** 敏感配置脱敏掩码，默认 ****（可由 common 配置 sensitive-mask 覆盖） */
    private String sensitiveMask = "****";
}
