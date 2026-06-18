/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.util;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

/**
 * JsonUtils JSON 工具类测试。
 * <p>
 * 验证基于 Jackson 的序列化功能，包括正常对象、null 输入等场景。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("JsonUtils JSON 工具类测试")
class JsonUtilsTest {

    @Test
    @DisplayName("toJsonString(Map) 应正确序列化为 JSON 字符串")
    void toJsonString_withMap_shouldReturnJsonString() {
        Map<String, Object> data = new HashMap<>();
        data.put("name", "CloudStroll");
        data.put("version", 1);
        data.put("active", true);

        String json = JsonUtils.toJsonString(data);

        assertNotNull(json);
        assertTrue(json.contains("\"name\""));
        assertTrue(json.contains("\"CloudStroll\""));
        assertTrue(json.contains("\"version\""));
        assertTrue(json.contains("1"));
        assertTrue(json.contains("\"active\""));
        assertTrue(json.contains("true"));
    }

    @Test
    @DisplayName("toJsonString(null) 应返回 null")
    void toJsonString_withNull_shouldReturnNull() {
        assertNull(JsonUtils.toJsonString(null));
    }

    @Test
    @DisplayName("toJsonString(String) 应返回 JSON 字符串表示（带引号）")
    void toJsonString_withString_shouldReturnQuotedString() {
        String result = JsonUtils.toJsonString("hello");

        assertEquals("\"hello\"", result);
    }

    @Test
    @DisplayName("toJsonString(Integer) 应返回数字字符串")
    void toJsonString_withInteger_shouldReturnNumberString() {
        String result = JsonUtils.toJsonString(42);

        assertEquals("42", result);
    }

    @Test
    @DisplayName("toJsonString(Boolean) 应返回布尔字符串")
    void toJsonString_withBoolean_shouldReturnBooleanString() {
        String result = JsonUtils.toJsonString(true);

        assertEquals("true", result);
    }

    @Test
    @DisplayName("toJsonString(List) 应返回 JSON 数组字符串")
    void toJsonString_withList_shouldReturnJsonArrayString() {
        String result = JsonUtils.toJsonString(java.util.List.of("a", "b", "c"));

        assertEquals("[\"a\",\"b\",\"c\"]", result);
    }

    @Test
    @DisplayName("toJsonString(empty String) 应返回空字符串的 JSON 表示")
    void toJsonString_withEmptyString_shouldReturnQuotedEmptyString() {
        String result = JsonUtils.toJsonString("");

        assertEquals("\"\"", result);
    }
}
