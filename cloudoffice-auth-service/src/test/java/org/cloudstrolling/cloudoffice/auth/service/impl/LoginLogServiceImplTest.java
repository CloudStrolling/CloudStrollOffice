/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.cloudstrolling.cloudoffice.auth.entity.LoginLogEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.LoginLogMapper;
import org.cloudstrolling.cloudoffice.auth.service.LoginLogService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link LoginLogServiceImpl} 的单元测试。
 *
 * <p>使用 Mockito 模拟 {@link LoginLogMapper}，验证更新登出时间的行为和边界情况。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("LoginLogServiceImpl 单元测试")
class LoginLogServiceImplTest {

    @Mock
    private LoginLogMapper loginLogMapper;

    @Captor
    private ArgumentCaptor<LoginLogEntity> logEntityCaptor;

    private LoginLogService loginLogService;

    @BeforeEach
    void setUp() {
        loginLogService = new LoginLogServiceImpl(loginLogMapper);
    }

    @Test
    @DisplayName("更新登出时间：活跃日志存在时更新 logoutTime")
    void updateLogoutTime_shouldUpdateLogoutTime_whenActiveLogExists() {
        // Given
        Long userId = 1L;
        String clientType = "WINDOWS";

        LoginLogEntity existingLog = new LoginLogEntity();
        existingLog.setId(100L);
        existingLog.setUserId(userId);
        existingLog.setClientType(clientType);
        existingLog.setLoginTime(LocalDateTime.now().minusHours(1));
        existingLog.setLogoutTime(null);

        when(loginLogMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(existingLog);

        // When
        loginLogService.updateLogoutTime(userId, clientType);

        // Then
        verify(loginLogMapper).updateById(logEntityCaptor.capture());
        LoginLogEntity updatedLog = logEntityCaptor.getValue();
        assertEquals(100L, updatedLog.getId());
        assertNotNull(updatedLog.getLogoutTime());
        assertTrue(updatedLog.getLogoutTime().isAfter(LocalDateTime.now().minusSeconds(5)));
    }

    @Test
    @DisplayName("更新登出时间：无活跃日志时不执行更新")
    void updateLogoutTime_shouldNotUpdate_whenNoActiveLog() {
        // Given
        Long userId = 1L;
        String clientType = "WINDOWS";

        when(loginLogMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);

        // When
        loginLogService.updateLogoutTime(userId, clientType);

        // Then
        verify(loginLogMapper, never()).updateById(any());
    }

    @Test
    @DisplayName("更新登出时间：Mapper 异常时不影响主流程")
    void updateLogoutTime_shouldHandleException_whenMapperFails() {
        // Given
        Long userId = 1L;
        String clientType = "WINDOWS";

        when(loginLogMapper.selectOne(any(LambdaQueryWrapper.class)))
                .thenThrow(new RuntimeException("Database connection error"));

        // When - should not throw exception
        assertDoesNotThrow(() -> loginLogService.updateLogoutTime(userId, clientType));

        // Then
        verify(loginLogMapper, never()).updateById(any());
    }

    @Test
    @DisplayName("更新登出时间：userId 为 null 时不做更新")
    void updateLogoutTime_shouldNotUpdate_whenUserIdIsNull() {
        // Given
        String clientType = "WINDOWS";

        when(loginLogMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);

        // When
        loginLogService.updateLogoutTime(null, clientType);

        // Then
        verify(loginLogMapper, never()).updateById(any());
    }

    @Test
    @DisplayName("更新登出时间：clientType 为 null 时不做更新")
    void updateLogoutTime_shouldNotUpdate_whenClientTypeIsNull() {
        // Given
        Long userId = 1L;

        when(loginLogMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);

        // When
        loginLogService.updateLogoutTime(userId, null);

        // Then
        verify(loginLogMapper, never()).updateById(any());
    }
}
