package org.cloudstrolling.cloudoffice.auth.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 密码策略配置属性。
 *
 * <p>从配置文件中读取密码强度相关参数，支持通过 {@code app.password.*} 配置项覆盖默认值。</p>
 *
 * @author CloudStroll Office
 */
@Data
@ConfigurationProperties(prefix = "app.password")
public class PasswordProperties {

    /** 密码最小长度，默认 8 位 */
    private int minLength = 8;

    /** 密码最大长度，默认 64 位 */
    private int maxLength = 64;
}
