/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.controller;

import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.core.env.Environment;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

/**
 * common 健康检查端点与 API 服务测试（TASK-003）。
 *
 * <p>验证 HealthController 契约：类注解与路径、health 方法返回统一 ApiResult，
 * data 含 service/status/version/timestamp 四字段且取值正确。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("common 健康检查端点与 API 服务测试（TASK-003）")
class HealthControllerTest {

    @Test
    @DisplayName("TC-TASK003-001: HealthController 类注解与 health 方法存在")
    void healthController_shouldBeAnnotatedAndHaveHealthMethod() throws Exception {
        Class<?> clazz = HealthController.class;
        assertNotNull(clazz.getAnnotation(RestController.class), "HealthController 应标注 @RestController");
        RequestMapping rm = clazz.getAnnotation(RequestMapping.class);
        assertNotNull(rm, "HealthController 应标注 @RequestMapping");
        assertArrayEquals(new String[]{"/api/v1/common"}, rm.value(),
                "HealthController 请求映射应为 /api/v1/common");
        GetMapping gm = clazz.getMethod("health").getAnnotation(GetMapping.class);
        assertNotNull(gm, "health 方法应标注 @GetMapping");
        assertArrayEquals(new String[]{"/health"}, gm.value(), "health 方法映射应为 /health");
    }

    @Test
    @DisplayName("TC-TASK003-002: health 返回 200 与统一 ApiResult（service/status/version/timestamp）")
    void health_shouldReturnUnifiedApiResultWithHealthInfo() {
        Environment env = mock(Environment.class);
        when(env.getProperty("spring.application.name", "cloudoffice-common"))
                .thenReturn("cloudoffice-common");
        HealthController controller = new HealthController(env);

        ApiResult<Map<String, Object>> result = controller.health();

        assertNotNull(result, "health 返回值不应为空");
        assertEquals(200, result.getCode(), "code 应为 200");
        assertNotNull(result.getMessage(), "message 不应为空");
        assertNotNull(result.getTimestamp(), "响应体 timestamp 不应为空");

        Map<String, Object> data = result.getData();
        assertNotNull(data, "data 不应为空");
        assertEquals("cloudoffice-common", data.get("service"), "service 应为 cloudoffice-common");
        assertEquals("UP", data.get("status"), "status 应为 UP");
        assertNotNull(data.get("version"), "version 不应为空");
        assertNotNull(data.get("timestamp"), "data.timestamp 不应为空");
    }

    @Test
    @DisplayName("TC-TASK003-003: 响应体字段与 auth/biz/system 健康检查端点一致，timestamp 为 ISO 格式")
    void health_shouldMatchExistingServiceHealthContract() {
        Environment env = mock(Environment.class);
        when(env.getProperty("spring.application.name", "cloudoffice-common"))
                .thenReturn("cloudoffice-common");
        HealthController controller = new HealthController(env);

        Map<String, Object> data = controller.health().getData();

        // 键集合与 auth/biz/system 健康检查端点一致（service/status/version/timestamp）
        assertTrue(data.containsKey("service"), "data 应含 service");
        assertTrue(data.containsKey("status"), "data 应含 status");
        assertTrue(data.containsKey("version"), "data 应含 version");
        assertTrue(data.containsKey("timestamp"), "data 应含 timestamp");
        assertEquals(4, data.size(), "data 应恰有 4 个字段");

        // timestamp 应为 ISO 格式字符串
        assertInstanceOf(String.class, data.get("timestamp"), "data.timestamp 应为字符串");
        assertNotNull(java.time.Instant.parse((String) data.get("timestamp")),
                "data.timestamp 应为合法 ISO 格式时间戳");
    }
}
