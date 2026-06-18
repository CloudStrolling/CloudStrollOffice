package org.cloudstrolling.cloudoffice.gateway;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * Gateway 服务启动类。
 *
 * <p>作为 CloudStroll Office 微服务架构的统一入口网关，负责请求路由、
 * 负载均衡、认证鉴权、跨域处理等职责。启动时自动注册到服务注册中心（Nacos）。</p>
 *
 * @author CloudStroll Office
 */
@SpringBootApplication
@EnableDiscoveryClient
public class GatewayApplication {

    /**
     * Gateway 服务入口方法。
     *
     * @param args 启动参数
     */
    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }
}
