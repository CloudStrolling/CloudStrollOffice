/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.cache;

import org.cloudstrolling.cloudoffice.common.config.ConfigProperties;
import org.cloudstrolling.cloudoffice.common.util.JsonUtils;
import org.cloudstrolling.cloudoffice.common.vo.ConfigItemVO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.Duration;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * 通用配置缓存管理器测试（TASK-004）。
 *
 * <p>验证 ConfigCacheManager 以 serviceName 为粒度的缓存读写与失效能力：
 * 缓存键 common:config:{serviceName}、值以 JSON 字符串存储（无 @class 类型信息）、
 * 写入带 TTL（默认 300s）、读取/删除、异常兜底。</p>
 *
 * @author CloudStroll Office
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("通用配置缓存管理器测试（TASK-004）")
class ConfigCacheManagerTest {

    @Mock
    private RedisTemplate<String, String> redisTemplate;

    @Mock
    private ValueOperations<String, String> valueOperations;

    private ConfigCacheManager cacheManager;

    @BeforeEach
    void setUp() {
        ConfigProperties props = new ConfigProperties();
        cacheManager = new ConfigCacheManager(redisTemplate, props);
    }

    @Test
    @DisplayName("TC-TASK004-007-1: cacheConfigs 以 JSON 字符串写入缓存并使用 TTL 300 秒")
    void cacheConfigs_shouldSetWithTtl() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        List<ConfigItemVO> configs = List.of(new ConfigItemVO());
        cacheManager.cacheConfigs("auth-service", configs);

        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<Duration> ttlCaptor = ArgumentCaptor.forClass(Duration.class);
        verify(valueOperations).set(keyCaptor.capture(), eq(JsonUtils.toJsonString(configs)), ttlCaptor.capture());
        assertEquals("common:config:auth-service", keyCaptor.getValue(), "缓存键应为 common:config:{serviceName}");
        assertEquals(300L, ttlCaptor.getValue().getSeconds(), "TTL 应为 300 秒（默认）");
    }

    @Test
    @DisplayName("TC-TASK004-007-2: getCachedConfigs 命中反序列化返回列表，未命中返回 null")
    void getCachedConfigs_shouldReturnCachedOrNull() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        List<ConfigItemVO> configs = List.of(new ConfigItemVO());
        when(valueOperations.get("common:config:auth-service")).thenReturn(JsonUtils.toJsonString(configs));
        List<ConfigItemVO> cached = cacheManager.getCachedConfigs("auth-service");
        assertNotNull(cached, "缓存命中应返回列表");
        assertEquals(configs, cached, "反序列化后列表应与缓存一致");

        when(valueOperations.get("common:config:missing")).thenReturn(null);
        assertNull(cacheManager.getCachedConfigs("missing"), "缓存未命中应返回 null");
    }

    @Test
    @DisplayName("TC-TASK004-007-3: evict 删除缓存")
    void evict_shouldDeleteCache() {
        cacheManager.evict("auth-service");
        verify(redisTemplate).delete("common:config:auth-service");
    }

    @Test
    @DisplayName("TC-TASK004-007-4: 缓存读写异常时兜底不抛出")
    void cache_shouldTolerateRedisErrors() {
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(valueOperations.get("common:config:auth-service")).thenThrow(new RuntimeException("redis down"));
        assertNull(cacheManager.getCachedConfigs("auth-service"), "读取异常应返回 null 而非抛出");

        doThrow(new RuntimeException("redis down")).when(valueOperations).set(any(), any(), any(Duration.class));
        assertDoesNotThrow(() -> cacheManager.cacheConfigs("auth-service", List.of(new ConfigItemVO())),
                "写入异常应被吞掉不抛出");

        doThrow(new RuntimeException("redis down")).when(redisTemplate).delete("common:config:auth-service");
        assertDoesNotThrow(() -> cacheManager.evict("auth-service"), "删除异常应被吞掉不抛出");
    }
}
