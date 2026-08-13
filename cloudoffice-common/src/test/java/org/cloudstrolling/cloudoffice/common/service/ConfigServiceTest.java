/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.service;

import org.cloudstrolling.cloudoffice.common.cache.ConfigCacheManager;
import org.cloudstrolling.cloudoffice.common.config.ConfigProperties;
import org.cloudstrolling.cloudoffice.common.entity.ConfigEntity;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.mapper.ConfigMapper;
import org.cloudstrolling.cloudoffice.common.model.PageResult;
import org.cloudstrolling.cloudoffice.common.vo.ConfigItemVO;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * 通用配置管理查询服务测试（TASK-004）。
 *
 * <p>验证 ConfigService 的查询编排核心逻辑：按条件/按服务名查询、
 * serviceName 合法性校验（非法 400）、敏感配置脱敏、缓存优先回源回填、
 * 空结果 200 空列表、存储异常向上抛出（由全局异常处理器兜底 500）。</p>
 *
 * @author CloudStroll Office
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("通用配置管理查询服务测试（TASK-004）")
class ConfigServiceTest {

    @Mock
    private ConfigMapper configMapper;

    @Mock
    private ConfigCacheManager configCacheManager;

    private ConfigService configService;

    @BeforeEach
    void setUp() {
        ConfigProperties props = new ConfigProperties();
        configService = new ConfigService(configMapper, configCacheManager, props);
    }

    /** 构造非敏感配置实体。 */
    private ConfigEntity buildEntity(String serviceName, String group, String key, String value, int sensitive) {
        ConfigEntity entity = new ConfigEntity();
        entity.setId(100L);
        entity.setServiceName(serviceName);
        entity.setConfigGroup(group);
        entity.setConfigKey(key);
        entity.setConfigValue(value);
        entity.setDataType("string");
        entity.setDescription("测试配置");
        entity.setSensitive(sensitive);
        entity.setStatus(0);
        return entity;
    }

    @Test
    @DisplayName("TC-TASK004-002: queryConfigList 按条件过滤返回统一分页结果")
    void queryConfigList_shouldReturnPagedResult() {
        // serviceName 非空走缓存优先：未命中 → 回源 selectList → 回填缓存
        when(configCacheManager.getCachedConfigs("auth-service")).thenReturn(null);
        when(configMapper.selectList(any())).thenAnswer(inv -> {
            List<ConfigEntity> list = new ArrayList<>();
            list.add(buildEntity("auth-service", "verification", "code-length", "6", 0));
            return list;
        });

        PageResult<ConfigItemVO> result = configService.queryConfigList("auth-service", "verification", "code-length", 1, 10);

        assertNotNull(result, "分页结果不应为空");
        assertEquals(1, result.getTotal(), "total 应为 1");
        assertEquals(1, result.getPage(), "page 应为 1");
        assertEquals(10, result.getPageSize(), "pageSize 应为 10");
        assertEquals(1, result.getRecords().size(), "records 应有 1 条");
        ConfigItemVO vo = result.getRecords().get(0);
        assertEquals("auth-service", vo.getServiceName(), "serviceName 应为 auth-service");
        assertEquals("verification", vo.getGroup(), "group 应为 verification");
        assertEquals("code-length", vo.getKey(), "key 应为 code-length");
        assertEquals("6", vo.getValue(), "非敏感配置 value 应为明文 6");
        assertFalse(vo.getSensitive(), "非敏感配置 sensitive 应为 false");
        verify(configCacheManager, times(1)).cacheConfigs(eq("auth-service"), anyList());
    }

    @Test
    @DisplayName("TC-TASK004-002-2: queryConfigList serviceName 为空时直连数据库（不缓存）")
    void queryConfigList_shouldQueryAllWithoutCacheWhenServiceNameBlank() {
        when(configMapper.selectList(any())).thenAnswer(inv -> {
            List<ConfigEntity> list = new ArrayList<>();
            list.add(buildEntity("auth-service", "verification", "code-length", "6", 0));
            list.add(buildEntity("gateway", "security", "whitelist-paths", "/health", 0));
            return list;
        });

        PageResult<ConfigItemVO> result = configService.queryConfigList(null, "verification", null, 1, 10);

        assertNotNull(result, "分页结果不应为空");
        assertEquals(1, result.getTotal(), "跨服务按 group 过滤后 total 应为 1");
        assertEquals("auth-service", result.getRecords().get(0).getServiceName(), "应命中 auth-service 的 verification 分组");
        verify(configCacheManager, never()).getCachedConfigs(any());
        verify(configCacheManager, never()).cacheConfigs(any(), any());
    }

    @Test
    @DisplayName("TC-TASK004-002-3: queryConfigList serviceName 非空且缓存命中时不回源")
    void queryConfigList_shouldPreferCacheWhenServiceNamePresent() {
        ConfigItemVO cachedVo = new ConfigItemVO();
        cachedVo.setServiceName("gateway");
        cachedVo.setGroup("security");
        cachedVo.setKey("whitelist-paths");
        cachedVo.setValue("/health");
        cachedVo.setSensitive(false);
        when(configCacheManager.getCachedConfigs("gateway")).thenReturn(List.of(cachedVo));

        PageResult<ConfigItemVO> result = configService.queryConfigList("gateway", "security", "whitelist-paths", 1, 10);

        assertNotNull(result, "分页结果不应为空");
        assertEquals(1, result.getTotal(), "缓存命中 total 应为 1");
        assertEquals("gateway", result.getRecords().get(0).getServiceName(), "应返回缓存中的 serviceName");
        verify(configMapper, never()).selectList(any());
        verify(configCacheManager, never()).cacheConfigs(any(), any());
    }

    @Test
    @DisplayName("TC-TASK004-003: queryConfigsByService 按微服务名称返回列表（不分页）")
    void queryConfigsByService_shouldReturnList() {
        when(configCacheManager.getCachedConfigs("auth-service")).thenReturn(null);
        when(configMapper.selectList(any())).thenAnswer(inv -> {
            List<ConfigEntity> list = new ArrayList<>();
            list.add(buildEntity("auth-service", "verification", "code-length", "6", 0));
            return list;
        });

        List<ConfigItemVO> result = configService.queryConfigsByService("auth-service");

        assertNotNull(result, "查询结果不应为空");
        assertEquals(1, result.size(), "应返回 1 条配置");
        assertEquals("auth-service", result.get(0).getServiceName(), "serviceName 应为 auth-service");
        verify(configCacheManager, times(1)).cacheConfigs(eq("auth-service"), anyList());
    }

    @Test
    @DisplayName("TC-TASK004-004: serviceName 非法时抛 BusinessException(400)")
    void query_shouldRejectInvalidServiceName() {
        BusinessException ex = assertThrows(BusinessException.class,
                () -> configService.queryConfigsByService("non-existent"));
        assertEquals(400, ex.getCode(), "非法 serviceName 错误码应为 400");
        verify(configMapper, never()).selectList(any());

        BusinessException ex2 = assertThrows(BusinessException.class,
                () -> configService.queryConfigList("invalid-svc", null, null, 1, 10));
        assertEquals(400, ex2.getCode(), "非法 serviceName（列表查询）错误码应为 400");
    }

    @Test
    @DisplayName("TC-TASK004-005: 敏感配置脱敏为掩码，非敏感返回明文")
    void query_shouldMaskSensitiveConfigs() {
        when(configCacheManager.getCachedConfigs("auth-service")).thenReturn(null);
        when(configMapper.selectList(any())).thenAnswer(inv -> {
            List<ConfigEntity> list = new ArrayList<>();
            list.add(buildEntity("auth-service", "token", "sign-secret", "secret-token", 1));
            list.add(buildEntity("auth-service", "verification", "code-length", "6", 0));
            return list;
        });

        List<ConfigItemVO> result = configService.queryConfigsByService("auth-service");

        assertEquals("****", result.get(0).getValue(), "敏感配置 value 应脱敏为掩码 ****");
        assertNotEquals("secret-token", result.get(0).getValue(), "敏感配置不应暴露明文");
        assertTrue(result.get(0).getSensitive(), "敏感配置 sensitive 应为 true");
        assertEquals("6", result.get(1).getValue(), "非敏感配置 value 应保持明文");
    }

    @Test
    @DisplayName("TC-TASK004-005-2: 掩码可由 common 配置 sensitive-mask 覆盖")
    void query_shouldUseCustomizableSensitiveMask() {
        ConfigProperties props = new ConfigProperties();
        props.setSensitiveMask("####");
        ConfigService service = new ConfigService(configMapper, configCacheManager, props);

        when(configCacheManager.getCachedConfigs("auth-service")).thenReturn(null);
        when(configMapper.selectList(any())).thenAnswer(inv -> {
            List<ConfigEntity> list = new ArrayList<>();
            list.add(buildEntity("auth-service", "token", "sign-secret", "secret-token", 1));
            return list;
        });

        List<ConfigItemVO> result = service.queryConfigsByService("auth-service");
        assertEquals("####", result.get(0).getValue(), "掩码应为可配置的 ####");
    }

    @Test
    @DisplayName("TC-TASK004-006: 缓存优先，未命中回源回填，命中不再回源")
    void query_shouldPreferCacheAndBackfillOnMiss() {
        // 第一次查询：缓存未命中 → 回源 DB → 回填缓存
        when(configCacheManager.getCachedConfigs("gateway")).thenReturn(null);
        when(configMapper.selectList(any())).thenAnswer(inv -> {
            List<ConfigEntity> list = new ArrayList<>();
            list.add(buildEntity("gateway", "security", "whitelist-paths", "/health", 0));
            return list;
        });
        List<ConfigItemVO> first = configService.queryConfigsByService("gateway");
        assertNotNull(first);
        verify(configMapper, times(1)).selectList(any());
        verify(configCacheManager, times(1)).cacheConfigs(eq("gateway"), anyList());

        // 第二次查询：缓存命中 → 不再回源
        reset(configMapper, configCacheManager);
        when(configCacheManager.getCachedConfigs("gateway")).thenReturn(List.of(new ConfigItemVO()));
        configService.queryConfigsByService("gateway");
        verify(configMapper, never()).selectList(any());
        verify(configCacheManager, never()).cacheConfigs(any(), any());
    }

    @Test
    @DisplayName("TC-TASK004-009: 查询结果为空返回 200 空列表/空分页")
    void query_shouldReturnEmptyOnNoMatch() {
        when(configCacheManager.getCachedConfigs("system-service")).thenReturn(null);
        when(configMapper.selectList(any())).thenReturn(new ArrayList<>());
        List<ConfigItemVO> list = configService.queryConfigsByService("system-service");
        assertNotNull(list, "空结果不应为 null");
        assertTrue(list.isEmpty(), "空结果应为空列表（200）");

        // serviceName 为空走 queryEnabledConfigs（selectList），复用上面的空列表 mock
        PageResult<ConfigItemVO> pageResult = configService.queryConfigList(null, null, "not-exist-key", 1, 10);
        assertNotNull(pageResult, "空分页不应为 null");
        assertTrue(pageResult.getRecords().isEmpty(), "空分页 records 应为空");
        assertEquals(0L, pageResult.getTotal(), "空分页 total 应为 0");
    }

    @Test
    @DisplayName("TC-TASK004-010: 存储异常向上抛出（由全局处理器兜底 500）")
    void query_shouldPropagateStorageException() {
        when(configCacheManager.getCachedConfigs("auth-service")).thenReturn(null);
        when(configMapper.selectList(any())).thenThrow(new RuntimeException("db down"));

        assertThrows(RuntimeException.class, () -> configService.queryConfigsByService("auth-service"));
    }
}
