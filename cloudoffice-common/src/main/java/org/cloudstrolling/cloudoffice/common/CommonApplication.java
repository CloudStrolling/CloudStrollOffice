package org.cloudstrolling.cloudoffice.common;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * 公共模块服务启动类
 *
 * <p>将 cloudoffice-common 从纯公共 jar 模块升级为可独立部署的 Spring Boot 微服务，
 * 注册到 Nacos（服务名 cloudoffice-common，端口 ${COMMON_PORT:9300}），提供 API 接口能力。
 * 同时保留公共 jar 模块能力（ApiResult/PageResult/异常体系/枚举常量/工具类），
 * 下游 gateway/auth/biz/system 对 common 的 Maven 依赖关系不受影响。</p>
 *
 * @author CloudStroll Office
 */
@SpringBootApplication
@EnableDiscoveryClient
public class CommonApplication {

    /**
     * 公共模块服务入口方法。
     *
     * @param args 启动参数
     */
    public static void main(String[] args) {
        SpringApplication.run(CommonApplication.class, args);
    }
}
