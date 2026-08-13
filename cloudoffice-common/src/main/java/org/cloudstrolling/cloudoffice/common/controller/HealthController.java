/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.controller;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.model.ApiResult;
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
 * <p>提供 common 服务的存活探活（Health Check）与基础信息获取接口，
 * 供部署脚本（deploy-start-all）与监控探活使用，响应格式与
 * auth/biz/system 服务的健康检查端点保持一致（统一 {@link ApiResult} 响应体）。</p>
 *
 * @author CloudStroll Office
 */
@RestController
@RequestMapping("/api/v1/common")
@Slf4j
@Tag(name = "common 服务健康检查", description = "提供 common 服务的存活探活与基础信息获取接口")
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
     * <p>返回 common 服务运行状态、服务名、版本号与时间戳（ISO 格式），
     * 全部字段经统一 {@link ApiResult} 响应体包裹，由公共模块全局异常处理器兜底。</p>
     *
     * @return 包含服务名称、状态、版本号和时间戳的健康信息
     */
    @GetMapping("/health")
    @Operation(summary = "健康检查", description = "返回 common 服务运行状态、版本号和时间戳")
    public ApiResult<Map<String, Object>> health() {
        log.info("健康检查接口被调用");
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("service", env.getProperty("spring.application.name", "cloudoffice-common"));
        info.put("status", "UP");
        info.put("version", "0.2.8-SNAPSHOT");
        info.put("timestamp", Instant.now().toString());
        return ApiResult.success(info);
    }
}
