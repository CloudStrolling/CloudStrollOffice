package org.cloudstrolling.cloudoffice.auth.config;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * 验证码配置属性。
 *
 * <p>从配置文件中读取验证码相关参数，支持通过 {@code app.verification-code.*} 配置项覆盖默认值。</p>
 *
 * @author CloudStroll Office
 */
@Data
@ConfigurationProperties(prefix = "app.verification-code")
public class VerificationCodeProperties {

    /** 是否启用模拟模式（开发环境默认开启，直接返回固定验证码） */
    private boolean mock = true;

    /** 验证码过期时间（秒），默认 300 秒（5 分钟） */
    private int expireSeconds = 300;

    /** 验证码发送间隔（秒），默认 60 秒（1 分钟） */
    private int sendIntervalSeconds = 60;

    /** 验证码长度，默认 6 位 */
    private int length = 6;
}
