/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.cloud;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.client.discovery.EnableDiscoveryClient;

/**
 * CloudService 启动入口。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@SpringBootApplication
@EnableDiscoveryClient
public class CloudApplication {

    public static void main(String[] args) {
        SpringApplication.run(CloudApplication.class, args);
    }
}
