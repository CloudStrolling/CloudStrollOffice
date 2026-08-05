/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.config;

import org.apache.ibatis.reflection.MetaObject;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * MyBatisPlusConfig 自动填充处理器测试。
 * <p>
 * 使用 spy 模式验证 insertFill 和 updateFill 正确调用了
 * strictInsertFill / strictUpdateFill 方法及正确的参数。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("MyBatisPlusConfig 自动填充处理器测试")
class MyBatisPlusConfigTest {

    private MyBatisPlusConfig config;

    @Mock
    private MetaObject metaObject;

    @BeforeEach
    void setUp() {
        config = spy(new MyBatisPlusConfig());
    }

    @Test
    @DisplayName("insertFill 应调用 strictInsertFill — createTime(LocalDateTime.class)")
    void insertFill_shouldCallStrictInsertFillForCreateTime() {
        // 阻止 strictInsertFill 执行真实的默认方法（避免调用 findTableInfo）
        doReturn(config).when(config).strictInsertFill(any(MetaObject.class), anyString(), any(Class.class), any());

        config.insertFill(metaObject);

        verify(config).strictInsertFill(eq(metaObject), eq("createTime"),
                eq(LocalDateTime.class), any(LocalDateTime.class));
    }

    @Test
    @DisplayName("insertFill 应调用 strictInsertFill — updateTime(LocalDateTime.class)")
    void insertFill_shouldCallStrictInsertFillForUpdateTime() {
        doReturn(config).when(config).strictInsertFill(any(MetaObject.class), anyString(), any(Class.class), any());

        config.insertFill(metaObject);

        verify(config).strictInsertFill(eq(metaObject), eq("updateTime"),
                eq(LocalDateTime.class), any(LocalDateTime.class));
    }

    @Test
    @DisplayName("insertFill 应调用 strictInsertFill — deleted(Integer.class, 0)")
    void insertFill_shouldCallStrictInsertFillForDeleted() {
        doReturn(config).when(config).strictInsertFill(any(MetaObject.class), anyString(), any(Class.class), any());

        config.insertFill(metaObject);

        verify(config).strictInsertFill(eq(metaObject), eq("deleted"),
                eq(Integer.class), eq(0));
    }

    @Test
    @DisplayName("updateFill 应调用 strictUpdateFill — updateTime(LocalDateTime.class)")
    void updateFill_shouldCallStrictUpdateFill() {
        doReturn(config).when(config).strictUpdateFill(any(MetaObject.class), anyString(), any(Class.class), any());

        config.updateFill(metaObject);

        verify(config).strictUpdateFill(eq(metaObject), eq("updateTime"),
                eq(LocalDateTime.class), any(LocalDateTime.class));
    }

    @Test
    @DisplayName("insertFill 应恰好调用三次 strictInsertFill")
    void insertFill_shouldCallStrictInsertFillExactlyThreeTimes() {
        doReturn(config).when(config).strictInsertFill(any(MetaObject.class), anyString(), any(Class.class), any());

        config.insertFill(metaObject);

        verify(config, times(3)).strictInsertFill(
                any(MetaObject.class), anyString(), any(Class.class), any());
    }

    @Test
    @DisplayName("updateFill 不应调用 strictInsertFill")
    void updateFill_shouldNotCallStrictInsertFill() {
        doReturn(config).when(config).strictUpdateFill(any(MetaObject.class), anyString(), any(Class.class), any());

        config.updateFill(metaObject);

        verify(config, never()).strictInsertFill(
                any(MetaObject.class), anyString(), any(Class.class), any());
    }
}
