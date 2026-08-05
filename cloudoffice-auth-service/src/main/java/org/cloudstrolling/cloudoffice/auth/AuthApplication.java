package org.cloudstrolling.cloudoffice.auth;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * 认证授权服务启动类
 *
 * @author CloudStroll Office
 */
@SpringBootApplication
@EnableDiscoveryClient
@EnableConfigurationProperties
public class AuthApplication {

    /**
     * 认证授权服务入口方法。
     *
     * @param args 启动参数
     */
    public static void main(String[] args) {
        SpringApplication.run(AuthApplication.class, args);
    }
}
