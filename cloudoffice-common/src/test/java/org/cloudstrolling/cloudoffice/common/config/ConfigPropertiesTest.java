/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.config;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

/**
 * 通用配置管理属性测试（TASK-004）。
 *
 * <p>验证 ConfigProperties 默认值：缓存 TTL 300 秒、敏感配置脱敏掩码 ****。</p>
 *
 * @author CloudStroll Office
 */
@DisplayName("通用配置管理属性测试（TASK-004）")
class ConfigPropertiesTest {

    @Test
    @DisplayName("TC-TASK004-006-2: 默认缓存 TTL 为 300 秒，脱敏掩码为 ****")
    void defaults_shouldMatchDesign() {
        ConfigProperties props = new ConfigProperties();
        assertEquals(300, props.getCacheTtlSeconds(), "默认缓存 TTL 应为 300 秒");
        assertEquals("****", props.getSensitiveMask(), "默认脱敏掩码应为 ****");
    }

    @Test
    @DisplayName("TC-TASK004-006-3: 属性可通过 setter 覆盖")
    void setters_shouldOverrideDefaults() {
        ConfigProperties props = new ConfigProperties();
        props.setCacheTtlSeconds(600);
        props.setSensitiveMask("####");
        assertEquals(600, props.getCacheTtlSeconds());
        assertEquals("####", props.getSensitiveMask());
    }
}
