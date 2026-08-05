/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.constant;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullSource;
import org.junit.jupiter.params.provider.ValueSource;

import static org.junit.jupiter.api.Assertions.*;

/**
 * RedisKeyConstants Redis Key 常量管理类测试。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("RedisKeyConstants Redis Key 常量管理类测试")
class RedisKeyConstantsTest {

    // ========== 常量值验证 ==========

    @Test
    @DisplayName("SESSION_KEY_PREFIX 常量值应为 auth:session:")
    void sessionKeyPrefix_shouldBeCorrect() {
        assertEquals("auth:session:", RedisKeyConstants.SESSION_KEY_PREFIX);
    }

    @Test
    @DisplayName("BLACKLIST_KEY_PREFIX 常量值应为 auth:blacklist:")
    void blacklistKeyPrefix_shouldBeCorrect() {
        assertEquals("auth:blacklist:", RedisKeyConstants.BLACKLIST_KEY_PREFIX);
    }

    @Test
    @DisplayName("ACCOUNT_STATUS_KEY_PREFIX 常量值应为 auth:account:status:")
    void accountStatusKeyPrefix_shouldBeCorrect() {
        assertEquals("auth:account:status:", RedisKeyConstants.ACCOUNT_STATUS_KEY_PREFIX);
    }

    @Test
    @DisplayName("TENANT_STATUS_KEY_PREFIX 常量值应为 auth:tenant:status:")
    void tenantStatusKeyPrefix_shouldBeCorrect() {
        assertEquals("auth:tenant:status:", RedisKeyConstants.TENANT_STATUS_KEY_PREFIX);
    }

    // ========== buildSessionKey 方法测试 ==========

    @Test
    @DisplayName("buildSessionKey 应返回 auth:session:{userId}:{clientType} 格式")
    void buildSessionKey_shouldReturnCorrectFormat() {
        String key = RedisKeyConstants.buildSessionKey(10001L, "WINDOWS");
        assertEquals("auth:session:10001:WINDOWS", key);
    }

    @Test
    @DisplayName("buildSessionKey 应支持不同 clientType 值")
    void buildSessionKey_shouldSupportDifferentClientTypes() {
        assertEquals("auth:session:10001:H5", RedisKeyConstants.buildSessionKey(10001L, "H5"));
        assertEquals("auth:session:10001:ANDROID", RedisKeyConstants.buildSessionKey(10001L, "ANDROID"));
        assertEquals("auth:session:10001:IOS", RedisKeyConstants.buildSessionKey(10001L, "IOS"));
    }

    @Test
    @DisplayName("buildSessionKey userId 为 null 时应抛出 IllegalArgumentException")
    void buildSessionKey_withNullUserId_shouldThrowException() {
        assertThrows(IllegalArgumentException.class,
                () -> RedisKeyConstants.buildSessionKey(null, "WINDOWS"));
    }

    @Test
    @DisplayName("buildSessionKey clientType 为 null 时应抛出 IllegalArgumentException")
    void buildSessionKey_withNullClientType_shouldThrowException() {
        assertThrows(IllegalArgumentException.class,
                () -> RedisKeyConstants.buildSessionKey(10001L, null));
    }

    // ========== buildBlacklistKey 方法测试 ==========

    @Test
    @DisplayName("buildBlacklistKey 应返回 auth:blacklist:{tokenSignature} 格式")
    void buildBlacklistKey_shouldReturnCorrectFormat() {
        String key = RedisKeyConstants.buildBlacklistKey("abc123signature");
        assertEquals("auth:blacklist:abc123signature", key);
    }

    @Test
    @DisplayName("buildBlacklistKey tokenSignature 为 null 时应抛出 IllegalArgumentException")
    void buildBlacklistKey_withNullSignature_shouldThrowException() {
        assertThrows(IllegalArgumentException.class,
                () -> RedisKeyConstants.buildBlacklistKey(null));
    }

    // ========== buildAccountStatusKey 方法测试 ==========

    @Test
    @DisplayName("buildAccountStatusKey 应返回 auth:account:status:{userId} 格式")
    void buildAccountStatusKey_shouldReturnCorrectFormat() {
        String key = RedisKeyConstants.buildAccountStatusKey(20001L);
        assertEquals("auth:account:status:20001", key);
    }

    @Test
    @DisplayName("buildAccountStatusKey userId 为 null 时应抛出 IllegalArgumentException")
    void buildAccountStatusKey_withNullUserId_shouldThrowException() {
        assertThrows(IllegalArgumentException.class,
                () -> RedisKeyConstants.buildAccountStatusKey(null));
    }

    // ========== buildTenantStatusKey 方法测试 ==========

    @Test
    @DisplayName("buildTenantStatusKey 应返回 auth:tenant:status:{tenantId} 格式")
    void buildTenantStatusKey_shouldReturnCorrectFormat() {
        String key = RedisKeyConstants.buildTenantStatusKey(30001L);
        assertEquals("auth:tenant:status:30001", key);
    }

    @Test
    @DisplayName("buildTenantStatusKey tenantId 为 null 时应抛出 IllegalArgumentException")
    void buildTenantStatusKey_withNullTenantId_shouldThrowException() {
        assertThrows(IllegalArgumentException.class,
                () -> RedisKeyConstants.buildTenantStatusKey(null));
    }
}
