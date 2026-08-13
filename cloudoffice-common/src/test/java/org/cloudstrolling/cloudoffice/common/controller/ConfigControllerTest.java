/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.controller;

import org.cloudstrolling.cloudoffice.common.model.ApiResult;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.cloudstrolling.cloudoffice.common.service.ConfigService;
import org.cloudstrolling.cloudoffice.common.vo.ConfigItemVO;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.lang.reflect.Method;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

/**
 * 通用配置管理控制器测试（TASK-004）。
 *
 * <p>验证 ConfigController 契约：类注解与路径、API-035/API-036 查询方法、
 * 响应统一 ApiResult，且本版本不提供任何写入端点（POST/PUT/DELETE 预留扩展点）。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("通用配置管理控制器测试（TASK-004）")
class ConfigControllerTest {

    @Test
    @DisplayName("TC-TASK004-001: ConfigController 类注解与查询方法契约正确")
    void configController_shouldBeAnnotatedAndHaveQueryMethods() throws Exception {
        Class<?> clazz = ConfigController.class;
        assertNotNull(clazz.getAnnotation(RestController.class), "ConfigController 应标注 @RestController");
        RequestMapping rm = clazz.getAnnotation(RequestMapping.class);
        assertNotNull(rm, "ConfigController 应标注 @RequestMapping");
        assertArrayEquals(new String[]{"/api/v1/common"}, rm.value(),
                "ConfigController 请求映射应为 /api/v1/common");

        Method list = clazz.getMethod("queryConfigList", String.class, String.class, String.class,
                Integer.class, Integer.class);
        GetMapping gm = list.getAnnotation(GetMapping.class);
        assertNotNull(gm, "queryConfigList 应标注 @GetMapping");
        assertArrayEquals(new String[]{"/config"}, gm.value(), "queryConfigList 映射应为 /config");

        Method byService = clazz.getMethod("queryConfigsByService", String.class);
        GetMapping gm2 = byService.getAnnotation(GetMapping.class);
        assertNotNull(gm2, "queryConfigsByService 应标注 @GetMapping");
        assertArrayEquals(new String[]{"/config/{serviceName}"}, gm2.value(),
                "queryConfigsByService 映射应为 /config/{serviceName}");
    }

    @Test
    @DisplayName("TC-TASK004-002: queryConfigList 委托 ConfigService 返回统一 ApiResult 分页")
    void queryConfigList_shouldDelegateToService() {
        ConfigService service = mock(ConfigService.class);
        PageResult<ConfigItemVO> pageResult = PageResult.of(List.of(new ConfigItemVO()), 1L, 1, 10);
        when(service.queryConfigList("auth-service", "verification", "code-length", 1, 10))
                .thenReturn(pageResult);

        ConfigController controller = new ConfigController(service);
        ApiResult<PageResult<ConfigItemVO>> result =
                controller.queryConfigList("auth-service", "verification", "code-length", 1, 10);

        assertNotNull(result, "返回不应为空");
        assertEquals(200, result.getCode(), "code 应为 200");
        assertEquals(pageResult, result.getData(), "data 应为 ConfigService 返回的分页结果");
    }

    @Test
    @DisplayName("TC-TASK004-003: queryConfigsByService 委托 ConfigService 返回统一 ApiResult 列表")
    void queryConfigsByService_shouldDelegateToService() {
        ConfigService service = mock(ConfigService.class);
        List<ConfigItemVO> list = List.of(new ConfigItemVO());
        when(service.queryConfigsByService("auth-service")).thenReturn(list);

        ConfigController controller = new ConfigController(service);
        ApiResult<List<ConfigItemVO>> result = controller.queryConfigsByService("auth-service");

        assertNotNull(result, "返回不应为空");
        assertEquals(200, result.getCode(), "code 应为 200");
        assertEquals(list, result.getData(), "data 应为 ConfigService 返回的配置列表");
    }

    @Test
    @DisplayName("TC-TASK004-010-2: 本版本不提供 POST/PUT/DELETE 写入端点")
    void configController_shouldHaveNoWriteEndpoints() {
        for (Method method : ConfigController.class.getMethods()) {
            assertNull(method.getAnnotation(PostMapping.class),
                    "本版本不应有 POST 写入端点（扩展预留）");
            assertNull(method.getAnnotation(PutMapping.class),
                    "本版本不应有 PUT 写入端点（扩展预留）");
            assertNull(method.getAnnotation(DeleteMapping.class),
                    "本版本不应有 DELETE 写入端点（扩展预留）");
        }
    }
}
