/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.util;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JavaType;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import lombok.experimental.UtilityClass;

import java.util.ArrayList;
import java.util.List;

/**
 * JSON 工具类。
 *
 * <p>基于 Jackson 提供的 JSON 序列化/反序列化工具方法。
 * 默认注册 {@link JavaTimeModule} 以支持 Java 8 日期时间类型。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@UtilityClass
public class JsonUtils {

    /**
     * 线程安全的 ObjectMapper 单例。
     */
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper()
            .registerModule(new JavaTimeModule());

    /**
     * 将对象序列化为 JSON 字符串。
     *
     * @param obj 待序列化对象
     * @return JSON 字符串，序列化失败时返回 null
     */
    public static String toJsonString(Object obj) {
        if (obj == null) {
            return null;
        }
        try {
            return OBJECT_MAPPER.writeValueAsString(obj);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("JSON 序列化失败", e);
        }
    }

    /**
     * 将 JSON 字符串反序列化为指定元素类型的 List。
     *
     * <p>通过 {@link JavaType} 绑定具体元素类型进行固定类型反序列化，
     * 不解析任何 {@code @class} 多态类型信息，避免 Jackson 多态反序列化攻击面。</p>
     *
     * @param json  JSON 字符串
     * @param clazz 列表元素类型
     * @param <T>   元素类型
     * @return 反序列化后的列表；json 为空时返回空列表
     */
    public static <T> List<T> parseArray(String json, Class<T> clazz) {
        if (json == null || json.isEmpty()) {
            return new ArrayList<>();
        }
        try {
            JavaType type = OBJECT_MAPPER.getTypeFactory().constructCollectionType(List.class, clazz);
            return OBJECT_MAPPER.readValue(json, type);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("JSON 反序列化失败", e);
        }
    }
}
