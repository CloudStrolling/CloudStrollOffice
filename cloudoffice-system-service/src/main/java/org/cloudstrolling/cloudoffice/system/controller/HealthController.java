/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.system.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 健康检查控制器。
 * <p>
 * 提供服务的存活探活（Health Check）与基础信息获取接口，
 * 用于 Kubernetes 等容器编排平台的就绪探针和存活探针检测。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@RestController
@RequestMapping("/api/v1/system")
@Slf4j
@Tag(name = "系统服务健康检查", description = "提供系统服务的存活探活与基础信息获取接口")
public class HealthController {

    private final Environment env;

    /**
     * 构造器注入 Environment。
     *
     * @param env Spring 环境配置，用于读取 application 名称等属性
     */
    public HealthController(Environment env) {
        this.env = env;
    }

    /**
     * 健康检查接口。
     *
     * @return 包含服务名称、状态、版本号和时间戳的健康信息
     */
    @GetMapping("/health")
    @Operation(summary = "健康检查", description = "返回系统服务运行状态、版本号和时间戳")
    public ApiResult<Map<String, Object>> health() {
        log.info("健康检查接口被调用");
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("service", env.getProperty("spring.application.name", "cloudoffice-system-service"));
        info.put("status", "UP");
        info.put("version", "0.0.1-SNAPSHOT");
        info.put("timestamp", System.currentTimeMillis());
        return ApiResult.success(info);
    }
}
