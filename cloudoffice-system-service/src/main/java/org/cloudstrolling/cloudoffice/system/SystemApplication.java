/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.system;

import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * 系统服务启动入口。
 * <p>
 * 作为 Spring Boot 应用的主启动类，负责初始化并启动整个 system-service 模块。
 * 通过 {@code @EnableDiscoveryClient} 启用服务注册与发现能力，
 * 排除 {@link DataSourceAutoConfiguration} 以支持无数据库环境下的独立启动。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@SpringBootApplication(exclude = DataSourceAutoConfiguration.class)
@EnableDiscoveryClient
public class SystemApplication {

    /**
     * 应用主方法，Spring Boot 启动入口。
     *
     * @param args 命令行传入的启动参数
     */
    public static void main(String[] args) {
        log.info("============================================");
        log.info("  CloudStrollOffice System Service Starting...");
        log.info("============================================");
        SpringApplication.run(SystemApplication.class, args);
    }
}
