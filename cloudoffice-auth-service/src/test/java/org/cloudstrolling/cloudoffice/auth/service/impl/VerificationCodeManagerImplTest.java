/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import org.cloudstrolling.cloudoffice.auth.entity.VerificationCodeEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.VerificationCodeMapper;
import org.cloudstrolling.cloudoffice.common.constant.RedisKeyConstants;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;

import java.time.LocalDateTime;
import java.util.concurrent.TimeUnit;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link VerificationCodeManagerImpl} 的单元测试。
 *
 * <p>覆盖 UT-031~UT-034：验证码生成与持久化（6 位数字、写库写缓存）、
 * 校验成功一次性失效、错误/过期/已用/不存在拒绝、用途隔离。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("VerificationCodeManagerImpl 单元测试")
class VerificationCodeManagerImplTest {

    @Mock
    private VerificationCodeMapper verificationCodeMapper;

    @Mock
    private RedisTemplate<String, Object> redisTemplate;

    @Mock
    private ValueOperations<String, Object> valueOperations;

    private VerificationCodeManagerImpl manager;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() {
        manager = new VerificationCodeManagerImpl(verificationCodeMapper, redisTemplate);
        // lenient：仅在 generateCode 相关用例中使用，避免其余用例报 UnnecessaryStubbing
        lenient().when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    /**
     * 构造未使用的有效验证码实体。
     */
    private VerificationCodeEntity buildValidCodeEntity() {
        VerificationCodeEntity entity = new VerificationCodeEntity();
        entity.setId(1L);
        entity.setTarget("13800000001");
        entity.setCode("123456");
        entity.setSendMode("SMS");
        entity.setPurpose("REGISTER");
        entity.setExpireTime(LocalDateTime.now().plusMinutes(5));
        entity.setUsed(0);
        return entity;
    }

    /**
     * UT-031：generateCode 生成 6 位数字（首位非 0）并写库写缓存（P0）。
     */
    @Test
    @DisplayName("UT-031: 生成 6 位验证码、insert 一次、写 Redis 缓存与频率标记")
    void generateCode_shouldPersistCodeAndCache() {
        String code = manager.generateCode("13800000001", "SMS", "REGISTER");

        assertNotNull(code);
        assertEquals(6, code.length());
        assertTrue(code.matches("\\d{6}"));
        assertNotEquals('0', code.charAt(0));
        verify(verificationCodeMapper, times(1)).insert(any(VerificationCodeEntity.class));
        verify(valueOperations, times(1)).set(
                eq(RedisKeyConstants.buildVerificationCodeKey("REGISTER", "13800000001")),
                eq(code), eq(300L), eq(TimeUnit.SECONDS));
        verify(valueOperations, times(1)).set(
                eq(RedisKeyConstants.buildVerificationCodeFreqKey("REGISTER", "13800000001")),
                eq("1"), eq(60L), eq(TimeUnit.SECONDS));
    }

    /**
     * UT-032：verifyCode 正确码通过并置 used=1（P0）。
     */
    @Test
    @DisplayName("UT-032: 正确验证码校验通过并标记已使用")
    void verifyCode_shouldReturnTrueAndMarkUsed() {
        when(verificationCodeMapper.selectLatestByTargetAndPurpose(eq("13800000001"), isNull()))
                .thenReturn(buildValidCodeEntity());

        boolean valid = manager.verifyCode("13800000001", "123456");

        assertTrue(valid);
        verify(verificationCodeMapper, times(1)).updateUsedStatus(eq(1L), eq(1), any());
    }

    /**
     * UT-033：错误码/过期/已用/不存在均返回 false 且不置 used（P0）。
     */
    @Test
    @DisplayName("UT-033: 错误码/过期/已用/不存在验证码均拒绝")
    void verifyCode_shouldReject_whenInvalid() {
        // 4.1 错误码
        when(verificationCodeMapper.selectLatestByTargetAndPurpose(eq("13800000001"), isNull()))
                .thenReturn(buildValidCodeEntity());
        assertFalse(manager.verifyCode("13800000001", "999999"));

        // 4.2 过期
        VerificationCodeEntity expired = buildValidCodeEntity();
        expired.setExpireTime(LocalDateTime.now().minusMinutes(1));
        when(verificationCodeMapper.selectLatestByTargetAndPurpose(eq("13800000002"), isNull()))
                .thenReturn(expired);
        assertFalse(manager.verifyCode("13800000002", "123456"));

        // 4.3 已使用
        VerificationCodeEntity used = buildValidCodeEntity();
        used.setUsed(1);
        when(verificationCodeMapper.selectLatestByTargetAndPurpose(eq("13800000003"), isNull()))
                .thenReturn(used);
        assertFalse(manager.verifyCode("13800000003", "123456"));

        // 4.4 不存在
        when(verificationCodeMapper.selectLatestByTargetAndPurpose(eq("13800000004"), isNull()))
                .thenReturn(null);
        assertFalse(manager.verifyCode("13800000004", "123456"));

        // 所有失败场景均不标记已使用
        verify(verificationCodeMapper, never()).updateUsedStatus(anyLong(), anyInt(), any());
    }

    /**
     * UT-034：按用途过滤，用途不匹配返回 false（P1）。
     */
    @Test
    @DisplayName("UT-034: verifyCode 按用途查询，无该用途记录时拒绝")
    void verifyCode_shouldReject_whenPurposeMismatch() {
        when(verificationCodeMapper.selectLatestByTargetAndPurpose(eq("13800000001"), eq("LOGIN")))
                .thenReturn(null);

        boolean valid = manager.verifyCode("13800000001", "123456", "LOGIN");

        assertFalse(valid);
        verify(verificationCodeMapper, never()).updateUsedStatus(anyLong(), anyInt(), any());
    }
}
