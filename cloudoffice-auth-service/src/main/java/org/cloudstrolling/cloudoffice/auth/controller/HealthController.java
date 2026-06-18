package org.cloudstrolling.cloudoffice.auth.controller;

import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

import lombok.extern.slf4j.Slf4j;

/**
 * 健康检查控制器
 *
 * <p>提供认证服务的健康检查端点，用于服务可用性监测。</p>
 */
@RestController
@RequestMapping("/api/v1/auth")
@Slf4j
public class HealthController {

    /** Spring 应用环境配置，用于读取服务名称等信息 */
    @Autowired
    private Environment env;

    /**
     * 健康检查接口
     *
     * <p>返回当前服务的运行状态、名称、版本和时间戳。</p>
     *
     * @return ApiResult 包含服务健康信息的 Map
     */
    @GetMapping("/health")
    public ApiResult<Map<String, Object>> health() {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("service", env.getProperty("spring.application.name", "cloudoffice-auth-service"));
        info.put("status", "UP");
        info.put("version", "0.0.1-SNAPSHOT");
        info.put("timestamp", Instant.now().toString());
        log.debug("健康检查被调用，返回状态：UP");
        return ApiResult.success(info);
    }
}
