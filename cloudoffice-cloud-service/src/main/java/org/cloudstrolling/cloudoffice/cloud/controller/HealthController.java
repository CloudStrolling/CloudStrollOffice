/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.cloud.controller;

import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 健康检查控制器。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@RestController
@RequestMapping("/api/v1/cloud")
@Slf4j
public class HealthController {

    @Autowired
    private Environment env; // Spring 环境配置，用于读取应用名称等属性

    /**
     * 健康检查接口。
     * <p>返回当前服务的健康状态，包括服务名称、运行状态、版本号及当前时间戳。</p>
     *
     * @return 包含服务健康信息的 ApiResult 响应
     */
    @GetMapping("/health")
    public ApiResult<Map<String, Object>> health() {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("service", env.getProperty("spring.application.name", "cloudoffice-cloud-service"));
        info.put("status", "UP");
        info.put("version", "0.0.1-SNAPSHOT");
        info.put("timestamp", Instant.now().toString());
        return ApiResult.success(info);
    }
}
