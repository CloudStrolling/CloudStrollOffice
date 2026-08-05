/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.common.constant.RedisKeyConstants;
import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.springframework.data.redis.core.Cursor;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ScanOptions;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.stereotype.Service;
import org.springframework.util.Assert;

import java.nio.charset.StandardCharsets;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Set;
import java.util.concurrent.TimeUnit;

/**
 * Redis 登录态管理服务实现类。
 *
 * <p>使用 {@link RedisTemplate} 实现登录态会话管理、Token 黑名单管理、
 * 账号状态缓存和租户状态缓存。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
public class LoginSessionServiceImpl implements LoginSessionService {

    /** Jackson ObjectMapper，用于类型转换 */
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private final RedisTemplate<String, Object> redisTemplate;
    private final ValueOperations<String, Object> valueOperations;

    /**
     * 构造器注入 RedisTemplate。
     *
     * @param redisTemplate Redis 操作模板
     */
    public LoginSessionServiceImpl(RedisTemplate<String, Object> redisTemplate) {
        Assert.notNull(redisTemplate, "redisTemplate must not be null");
        this.redisTemplate = redisTemplate;
        this.valueOperations = redisTemplate.opsForValue();
    }

    // ========== 登录态会话管理 ==========

    @Override
    public void createSession(Long userId, String clientType, LoginUserDTO loginUser, long ttlSeconds) {
        Assert.notNull(userId, "userId must not be null");
        Assert.hasText(clientType, "clientType must not be empty");
        Assert.notNull(loginUser, "loginUser must not be null");

        String key = RedisKeyConstants.buildSessionKey(userId, clientType);
        valueOperations.set(key, loginUser, ttlSeconds, TimeUnit.SECONDS);
        log.info("Session created | userId={} | clientType={} | ttl={}s", userId, clientType, ttlSeconds);
    }

    @Override
    public LoginUserDTO getSession(Long userId, String clientType) {
        Assert.notNull(userId, "userId must not be null");
        Assert.hasText(clientType, "clientType must not be empty");

        String key = RedisKeyConstants.buildSessionKey(userId, clientType);
        Object value = valueOperations.get(key);
        if (value == null) {
            log.debug("Session not found | userId={} | clientType={}", userId, clientType);
            return null;
        }

        // Jackson2JsonRedisSerializer 配合 default typing 时可直接返回目标类型，
        // 兜底处理：若返回 LinkedHashMap 则手动转换
        if (value instanceof LoginUserDTO) {
            return (LoginUserDTO) value;
        }
        if (value instanceof LinkedHashMap) {
            return OBJECT_MAPPER.convertValue(value, LoginUserDTO.class);
        }

        log.warn("Unexpected session value type: {}", value.getClass().getName());
        return null;
    }

    @Override
    public void removeSession(Long userId, String clientType) {
        Assert.notNull(userId, "userId must not be null");
        Assert.hasText(clientType, "clientType must not be empty");

        String key = RedisKeyConstants.buildSessionKey(userId, clientType);
        redisTemplate.delete(key);
        log.info("Session removed | userId={} | clientType={}", userId, clientType);
    }

    @Override
    public void removeAllSessions(Long userId) {
        Assert.notNull(userId, "userId must not be null");

        String pattern = RedisKeyConstants.SESSION_KEY_PREFIX + userId + ":*";
        log.info("Removing all sessions | userId={} | pattern={}", userId, pattern);

        Set<String> keys = new HashSet<>();
        redisTemplate.execute((RedisCallback<Object>) connection -> {
            try {
                try (Cursor<byte[]> cursor = connection.scan(
                        ScanOptions.scanOptions().match(pattern).count(100).build())) {
                    while (cursor.hasNext()) {
                        keys.add(new String(cursor.next(), StandardCharsets.UTF_8));
                    }
                }
            } catch (Exception e) {
                log.error("Redis SCAN failed | pattern={}", pattern, e);
            }
            return null;
        });

        if (!keys.isEmpty()) {
            redisTemplate.delete(keys);
            log.info("Removed {} session(s) | userId={}", keys.size(), userId);
        } else {
            log.debug("No sessions to remove | userId={}", userId);
        }
    }

    // ========== Token 黑名单管理 ==========

    @Override
    public void addToBlacklist(String tokenSignature, long ttlSeconds) {
        Assert.hasText(tokenSignature, "tokenSignature must not be empty");

        String key = RedisKeyConstants.buildBlacklistKey(tokenSignature);
        valueOperations.set(key, tokenSignature, ttlSeconds, TimeUnit.SECONDS);
        log.info("Token added to blacklist | signature={} | ttl={}s", maskSignature(tokenSignature), ttlSeconds);
    }

    @Override
    public boolean isBlacklisted(String tokenSignature) {
        Assert.hasText(tokenSignature, "tokenSignature must not be empty");

        String key = RedisKeyConstants.buildBlacklistKey(tokenSignature);
        Boolean exists = redisTemplate.hasKey(key);
        boolean result = Boolean.TRUE.equals(exists);
        if (result) {
            log.debug("Token is blacklisted | signature={}", maskSignature(tokenSignature));
        }
        return result;
    }

    // ========== 账号状态缓存 ==========

    @Override
    public void setAccountStatus(Long userId, Integer status) {
        Assert.notNull(userId, "userId must not be null");
        Assert.notNull(status, "status must not be null");

        String key = RedisKeyConstants.buildAccountStatusKey(userId);
        valueOperations.set(key, status);
        log.info("Account status cached | userId={} | status={}", userId, status);
    }

    @Override
    public Integer getAccountStatus(Long userId) {
        Assert.notNull(userId, "userId must not be null");

        String key = RedisKeyConstants.buildAccountStatusKey(userId);
        Object value = valueOperations.get(key);
        if (value == null) {
            return null;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        // 兜底：Jackson 可能返回 Integer 时自动装箱为 Integer，此处确保类型安全
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        log.warn("Unexpected account status value type: {}", value.getClass().getName());
        return null;
    }

    @Override
    public void removeAccountStatus(Long userId) {
        Assert.notNull(userId, "userId must not be null");

        String key = RedisKeyConstants.buildAccountStatusKey(userId);
        redisTemplate.delete(key);
        log.info("Account status cache removed | userId={}", userId);
    }

    // ========== 租户状态缓存 ==========

    @Override
    public void setTenantStatus(Long tenantId, Integer status) {
        Assert.notNull(tenantId, "tenantId must not be null");
        Assert.notNull(status, "status must not be null");

        String key = RedisKeyConstants.buildTenantStatusKey(tenantId);
        valueOperations.set(key, status);
        log.info("Tenant status cached | tenantId={} | status={}", tenantId, status);
    }

    @Override
    public Integer getTenantStatus(Long tenantId) {
        Assert.notNull(tenantId, "tenantId must not be null");

        String key = RedisKeyConstants.buildTenantStatusKey(tenantId);
        Object value = valueOperations.get(key);
        if (value == null) {
            return null;
        }
        if (value instanceof Integer) {
            return (Integer) value;
        }
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        log.warn("Unexpected tenant status value type: {}", value.getClass().getName());
        return null;
    }

    @Override
    public void removeTenantStatus(Long tenantId) {
        Assert.notNull(tenantId, "tenantId must not be null");

        String key = RedisKeyConstants.buildTenantStatusKey(tenantId);
        redisTemplate.delete(key);
        log.info("Tenant status cache removed | tenantId={}", tenantId);
    }

    /**
     * 对 Token 签名指纹进行脱敏处理，仅显示前 8 位，用于日志输出。
     *
     * @param signature Token 签名指纹
     * @return 脱敏后的签名
     */
    private static String maskSignature(String signature) {
        if (signature == null || signature.length() <= 8) {
            return signature;
        }
        return signature.substring(0, 8) + "****";
    }
}
