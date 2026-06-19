/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.system.controller;

import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * System 服务健康检查控制器测试。
 *
 * <p>验证 /api/v1/system/health 端点的正确响应。
 * 使用纯单元测试方式直接测试控制器逻辑，避免完整 Spring 上下文加载。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("System HealthController 测试")
class HealthControllerTest {

    private HealthController healthController;

    @BeforeEach
    void setUp() {
        // 构造器注入模拟的 Environment
        Environment mockEnv = mock(Environment.class);
        when(mockEnv.getProperty("spring.application.name", "cloudoffice-system-service"))
                .thenReturn("cloudoffice-system-service");
        healthController = new HealthController(mockEnv);
    }

    @Test
    @DisplayName("GET /api/v1/system/health -> 200 + ApiResult + 健康信息")
    void health_shouldReturn200AndApiResult_whenCalled() {
        // When: 执行健康检查
        ApiResult<Map<String, Object>> result = healthController.health();

        // Then: 验证响应
        assertNotNull(result, "返回结果不应为空");
        assertEquals(200, result.getCode().intValue(), "状态码应为200");
        assertEquals("操作成功", result.getMessage(), "消息应为'操作成功'");

        // 验证 data 字段
        Map<String, Object> data = result.getData();
        assertNotNull(data, "data 不应为空");
        assertEquals("cloudoffice-system-service", data.get("service"), "service 名称应正确");
        assertEquals("UP", data.get("status"), "状态应为 UP");
        assertEquals("0.0.1-SNAPSHOT", data.get("version"), "版本号应正确");
        assertNotNull(data.get("timestamp"), "timestamp 不应为空");
        assertInstanceOf(Long.class, data.get("timestamp"), "timestamp 应为 Long 类型");

        // 验证顶层 timestamp
        assertNotNull(result.getTimestamp(), "顶层 timestamp 不应为空");
        assertTrue(result.getTimestamp() > 0, "timestamp 应为正数");
    }
}
