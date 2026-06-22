/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;
import org.cloudstrolling.cloudoffice.auth.service.LoginSessionService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.RedisCallback;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link LoginSessionServiceImpl} 的单元测试。
 *
 * <p>使用 Mockito 模拟 {@link RedisTemplate}，验证各方法的行为和边界情况。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("LoginSessionServiceImpl 单元测试")
class LoginSessionServiceImplTest {

    @Mock
    private RedisTemplate<String, Object> redisTemplate;

    @Mock
    private ValueOperations<String, Object> valueOperations;

    @Captor
    private ArgumentCaptor<String> keyCaptor;

    @Captor
    private ArgumentCaptor<Object> valueCaptor;

    @Captor
    private ArgumentCaptor<Long> timeoutCaptor;

    @Captor
    private ArgumentCaptor<TimeUnit> timeUnitCaptor;

    private LoginSessionService loginSessionService;

    @BeforeEach
    void setUp() {
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        loginSessionService = new LoginSessionServiceImpl(redisTemplate);
    }

    // ==================== 创建会话 ====================

    @Test
    @DisplayName("创建会话：成功设置值与 TTL")
    void createSession_shouldSetValueWithTtl_whenCalled() {
        // Given
        Long userId = 1L;
        String clientType = "WINDOWS";
        LoginUserDTO loginUser = LoginUserDTO.builder()
                .userId(userId)
                .tenantId(10L)
                .userName("testUser")
                .clientType(clientType)
                .build();
        long ttlSeconds = 604800L;

        // When
        loginSessionService.createSession(userId, clientType, loginUser, ttlSeconds);

        // Then
        verify(valueOperations).set(keyCaptor.capture(), valueCaptor.capture(), timeoutCaptor.capture(), timeUnitCaptor.capture());
        assertEquals("auth:session:1:WINDOWS", keyCaptor.getValue());
        assertEquals(loginUser, valueCaptor.getValue());
        assertEquals(ttlSeconds, timeoutCaptor.getValue());
        assertEquals(TimeUnit.SECONDS, timeUnitCaptor.getValue());
    }

    @Test
    @DisplayName("创建会话：userId 为 null 时抛出异常")
    void createSession_shouldThrowException_whenUserIdIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.createSession(null, "WINDOWS", new LoginUserDTO(), 3600L));
    }

    @Test
    @DisplayName("创建会话：clientType 为 null 时抛出异常")
    void createSession_shouldThrowException_whenClientTypeIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.createSession(1L, null, new LoginUserDTO(), 3600L));
    }

    @Test
    @DisplayName("创建会话：loginUser 为 null 时抛出异常")
    void createSession_shouldThrowException_whenLoginUserIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.createSession(1L, "WINDOWS", null, 3600L));
    }

    // ==================== 获取会话 ====================

    @Test
    @DisplayName("获取会话：会话存在时返回 LoginUserDTO")
    void getSession_shouldReturnLoginUserDTO_whenSessionExists() {
        // Given
        Long userId = 1L;
        String clientType = "WINDOWS";
        LoginUserDTO expectedUser = LoginUserDTO.builder()
                .userId(userId)
                .tenantId(10L)
                .userName("testUser")
                .clientType(clientType)
                .build();

        when(valueOperations.get("auth:session:1:WINDOWS")).thenReturn(expectedUser);

        // When
        LoginUserDTO result = loginSessionService.getSession(userId, clientType);

        // Then
        assertNotNull(result);
        assertEquals(expectedUser.getUserId(), result.getUserId());
        assertEquals(expectedUser.getTenantId(), result.getTenantId());
        assertEquals(expectedUser.getUserName(), result.getUserName());
        assertEquals(expectedUser.getClientType(), result.getClientType());
    }

    @Test
    @DisplayName("获取会话：会话不存在时返回 null")
    void getSession_shouldReturnNull_whenSessionNotExists() {
        when(valueOperations.get("auth:session:1:WINDOWS")).thenReturn(null);

        LoginUserDTO result = loginSessionService.getSession(1L, "WINDOWS");

        assertNull(result);
    }

    @Test
    @DisplayName("获取会话：userId 为 null 时抛出异常")
    void getSession_shouldThrowException_whenUserIdIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.getSession(null, "WINDOWS"));
    }

    @Test
    @DisplayName("获取会话：clientType 为 null 时抛出异常")
    void getSession_shouldThrowException_whenClientTypeIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.getSession(1L, null));
    }

    // ==================== 删除会话 ====================

    @Test
    @DisplayName("删除会话：成功删除指定会话")
    void removeSession_shouldDeleteKey_whenCalled() {
        // When
        loginSessionService.removeSession(1L, "WINDOWS");

        // Then
        verify(redisTemplate).delete(keyCaptor.capture());
        assertEquals("auth:session:1:WINDOWS", keyCaptor.getValue());
    }

    @Test
    @DisplayName("删除会话：userId 为 null 时抛出异常")
    void removeSession_shouldThrowException_whenUserIdIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.removeSession(null, "WINDOWS"));
    }

    // ==================== 批量删除会话 ====================

    @Test
    @DisplayName("批量删除会话：userId 为 null 时抛出异常")
    void removeAllSessions_shouldThrowException_whenUserIdIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.removeAllSessions(null));
    }

    @Test
    @DisplayName("批量删除会话：成功调用 execute 执行扫描删除")
    void removeAllSessions_shouldExecuteScanAndDelete_whenCalled() {
        // Given
        Long userId = 1L;
        // redisTemplate.execute(RedisCallback) will return null by default (Mockito),
        // which means the callback won't be invoked in a mocked context.
        // The test verifies the execute call is made with correct arguments.

        // When
        loginSessionService.removeAllSessions(userId);

        // Then
        verify(redisTemplate).execute(any(RedisCallback.class));
    }

    // ==================== 黑名单管理 ====================

    @Test
    @DisplayName("添加黑名单：成功设置值与 TTL")
    void addToBlacklist_shouldSetValueWithTtl_whenCalled() {
        // Given
        String signature = "abcdef1234567890signature";
        long ttlSeconds = 7200L;

        // When
        loginSessionService.addToBlacklist(signature, ttlSeconds);

        // Then
        verify(valueOperations).set(keyCaptor.capture(), valueCaptor.capture(), timeoutCaptor.capture(), timeUnitCaptor.capture());
        assertEquals("auth:blacklist:" + signature, keyCaptor.getValue());
        assertEquals(signature, valueCaptor.getValue());
        assertEquals(ttlSeconds, timeoutCaptor.getValue());
        assertEquals(TimeUnit.SECONDS, timeUnitCaptor.getValue());
    }

    @Test
    @DisplayName("校验黑名单：Token 在黑名单中返回 true")
    void isBlacklisted_shouldReturnTrue_whenSignatureInBlacklist() {
        // Given
        when(redisTemplate.hasKey("auth:blacklist:testSignature")).thenReturn(true);

        // When
        boolean result = loginSessionService.isBlacklisted("testSignature");

        // Then
        assertTrue(result);
        verify(redisTemplate).hasKey("auth:blacklist:testSignature");
    }

    @Test
    @DisplayName("校验黑名单：Token 不在黑名单中返回 false")
    void isBlacklisted_shouldReturnFalse_whenSignatureNotInBlacklist() {
        // Given
        when(redisTemplate.hasKey("auth:blacklist:testSignature")).thenReturn(false);

        // When
        boolean result = loginSessionService.isBlacklisted("testSignature");

        // Then
        assertFalse(result);
    }

    @Test
    @DisplayName("添加黑名单：tokenSignature 为空时抛出异常")
    void addToBlacklist_shouldThrowException_whenSignatureIsEmpty() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.addToBlacklist("", 3600L));
    }

    @Test
    @DisplayName("校验黑名单：tokenSignature 为 null 时抛出异常")
    void isBlacklisted_shouldThrowException_whenSignatureIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.isBlacklisted(null));
    }

    // ==================== 账号状态缓存 ====================

    @Test
    @DisplayName("设置账号状态：成功设置值")
    void setAccountStatus_shouldSetValue_whenCalled() {
        // When
        loginSessionService.setAccountStatus(1L, 3);

        // Then
        verify(valueOperations).set(keyCaptor.capture(), valueCaptor.capture());
        assertEquals("auth:account:status:1", keyCaptor.getValue());
        assertEquals(3, valueCaptor.getValue());
    }

    @Test
    @DisplayName("获取账号状态：状态存在时返回值")
    void getAccountStatus_shouldReturnStatus_whenCalled() {
        // Given
        when(valueOperations.get("auth:account:status:1")).thenReturn(1);

        // When
        Integer status = loginSessionService.getAccountStatus(1L);

        // Then
        assertNotNull(status);
        assertEquals(1, status);
    }

    @Test
    @DisplayName("获取账号状态：状态不存在时返回 null")
    void getAccountStatus_shouldReturnNull_whenNotExists() {
        when(valueOperations.get("auth:account:status:1")).thenReturn(null);

        Integer status = loginSessionService.getAccountStatus(1L);

        assertNull(status);
    }

    @Test
    @DisplayName("删除账号状态：成功删除键")
    void removeAccountStatus_shouldDeleteKey_whenCalled() {
        loginSessionService.removeAccountStatus(1L);

        verify(redisTemplate).delete(keyCaptor.capture());
        assertEquals("auth:account:status:1", keyCaptor.getValue());
    }

    @Test
    @DisplayName("设置账号状态：userId 为 null 时抛出异常")
    void setAccountStatus_shouldThrowException_whenUserIdIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.setAccountStatus(null, 1));
    }

    @Test
    @DisplayName("获取账号状态：userId 为 null 时抛出异常")
    void getAccountStatus_shouldThrowException_whenUserIdIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.getAccountStatus(null));
    }

    // ==================== 租户状态缓存 ====================

    @Test
    @DisplayName("设置租户状态：成功设置值")
    void setTenantStatus_shouldSetValue_whenCalled() {
        // When
        loginSessionService.setTenantStatus(10L, 0);

        // Then
        verify(valueOperations).set(keyCaptor.capture(), valueCaptor.capture());
        assertEquals("auth:tenant:status:10", keyCaptor.getValue());
        assertEquals(0, valueCaptor.getValue());
    }

    @Test
    @DisplayName("获取租户状态：状态存在时返回值")
    void getTenantStatus_shouldReturnStatus_whenCalled() {
        // Given
        when(valueOperations.get("auth:tenant:status:10")).thenReturn(0);

        // When
        Integer status = loginSessionService.getTenantStatus(10L);

        // Then
        assertNotNull(status);
        assertEquals(0, status);
    }

    @Test
    @DisplayName("获取租户状态：状态不存在时返回 null")
    void getTenantStatus_shouldReturnNull_whenNotExists() {
        when(valueOperations.get("auth:tenant:status:10")).thenReturn(null);

        Integer status = loginSessionService.getTenantStatus(10L);

        assertNull(status);
    }

    @Test
    @DisplayName("删除租户状态：成功删除键")
    void removeTenantStatus_shouldDeleteKey_whenCalled() {
        loginSessionService.removeTenantStatus(10L);

        verify(redisTemplate).delete(keyCaptor.capture());
        assertEquals("auth:tenant:status:10", keyCaptor.getValue());
    }

    @Test
    @DisplayName("设置租户状态：tenantId 为 null 时抛出异常")
    void setTenantStatus_shouldThrowException_whenTenantIdIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.setTenantStatus(null, 0));
    }

    @Test
    @DisplayName("设置租户状态：status 为 null 时抛出异常")
    void setTenantStatus_shouldThrowException_whenStatusIsNull() {
        assertThrows(IllegalArgumentException.class,
                () -> loginSessionService.setTenantStatus(10L, null));
    }
}
