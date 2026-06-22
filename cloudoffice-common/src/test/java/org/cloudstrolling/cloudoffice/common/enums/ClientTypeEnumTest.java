/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.enums;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * ClientTypeEnum 客户端类型枚举测试。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@DisplayName("ClientTypeEnum 客户端类型枚举测试")
class ClientTypeEnumTest {

    // ========== 枚举常量属性验证 ==========

    @Test
    @DisplayName("WINDOWS 应具有 code=WINDOWS, category=PC")
    void windows_shouldHaveCorrectProperties() {
        assertEquals("WINDOWS", ClientTypeEnum.WINDOWS.getCode());
        assertEquals(ClientTypeEnum.DeviceCategory.PC, ClientTypeEnum.WINDOWS.getDeviceCategory());
    }

    @Test
    @DisplayName("UBUNTU 应具有 code=UBUNTU, category=PC")
    void ubuntu_shouldHaveCorrectProperties() {
        assertEquals("UBUNTU", ClientTypeEnum.UBUNTU.getCode());
        assertEquals(ClientTypeEnum.DeviceCategory.PC, ClientTypeEnum.UBUNTU.getDeviceCategory());
    }

    @Test
    @DisplayName("H5 应具有 code=H5, category=WEB")
    void h5_shouldHaveCorrectProperties() {
        assertEquals("H5", ClientTypeEnum.H5.getCode());
        assertEquals(ClientTypeEnum.DeviceCategory.WEB, ClientTypeEnum.H5.getDeviceCategory());
    }

    @Test
    @DisplayName("ANDROID 应具有 code=ANDROID, category=MOBILE")
    void android_shouldHaveCorrectProperties() {
        assertEquals("ANDROID", ClientTypeEnum.ANDROID.getCode());
        assertEquals(ClientTypeEnum.DeviceCategory.MOBILE, ClientTypeEnum.ANDROID.getDeviceCategory());
    }

    @Test
    @DisplayName("IOS 应具有 code=IOS, category=MOBILE")
    void ios_shouldHaveCorrectProperties() {
        assertEquals("IOS", ClientTypeEnum.IOS.getCode());
        assertEquals(ClientTypeEnum.DeviceCategory.MOBILE, ClientTypeEnum.IOS.getDeviceCategory());
    }

    @Test
    @DisplayName("WECHAT_MINI 应具有 code=WECHAT_MINI, category=MINI_PROGRAM")
    void wechatMini_shouldHaveCorrectProperties() {
        assertEquals("WECHAT_MINI", ClientTypeEnum.WECHAT_MINI.getCode());
        assertEquals(ClientTypeEnum.DeviceCategory.MINI_PROGRAM, ClientTypeEnum.WECHAT_MINI.getDeviceCategory());
    }

    // ========== fromCode() 静态工厂方法测试 ==========

    @Test
    @DisplayName("fromCode 应支持大小写不敏感查询")
    void fromCode_shouldBeCaseInsensitive() {
        assertEquals(ClientTypeEnum.WINDOWS, ClientTypeEnum.fromCode("windows").get());
        assertEquals(ClientTypeEnum.WINDOWS, ClientTypeEnum.fromCode("WINDOWS").get());
        assertEquals(ClientTypeEnum.WINDOWS, ClientTypeEnum.fromCode("Windows").get());
        assertEquals(ClientTypeEnum.H5, ClientTypeEnum.fromCode("h5").get());
        assertEquals(ClientTypeEnum.H5, ClientTypeEnum.fromCode("H5").get());
    }

    @Test
    @DisplayName("fromCode 不存在的编码应返回 Optional.empty()")
    void fromCode_withUnknownCode_shouldReturnEmpty() {
        Optional<ClientTypeEnum> result = ClientTypeEnum.fromCode("UNKNOWN");
        assertTrue(result.isEmpty());
    }

    @Test
    @DisplayName("fromCode(null) 应返回 Optional.empty()")
    void fromCode_withNull_shouldReturnEmpty() {
        Optional<ClientTypeEnum> result = ClientTypeEnum.fromCode(null);
        assertTrue(result.isEmpty());
    }

    // ========== isSameCategory() 同端互斥逻辑测试 ==========

    @Test
    @DisplayName("isSameCategory 同设备分类应返回 true")
    void isSameCategory_sameCategory_shouldReturnTrue() {
        // PC 分类
        assertTrue(ClientTypeEnum.WINDOWS.isSameCategory(ClientTypeEnum.UBUNTU));
        assertTrue(ClientTypeEnum.UBUNTU.isSameCategory(ClientTypeEnum.WINDOWS));

        // MOBILE 分类
        assertTrue(ClientTypeEnum.ANDROID.isSameCategory(ClientTypeEnum.IOS));
        assertTrue(ClientTypeEnum.IOS.isSameCategory(ClientTypeEnum.ANDROID));

        // 相同枚举
        assertTrue(ClientTypeEnum.H5.isSameCategory(ClientTypeEnum.H5));
        assertTrue(ClientTypeEnum.WECHAT_MINI.isSameCategory(ClientTypeEnum.WECHAT_MINI));
    }

    @Test
    @DisplayName("isSameCategory 不同设备分类应返回 false")
    void isSameCategory_differentCategory_shouldReturnFalse() {
        assertFalse(ClientTypeEnum.WINDOWS.isSameCategory(ClientTypeEnum.H5));
        assertFalse(ClientTypeEnum.WINDOWS.isSameCategory(ClientTypeEnum.ANDROID));
        assertFalse(ClientTypeEnum.WINDOWS.isSameCategory(ClientTypeEnum.WECHAT_MINI));
        assertFalse(ClientTypeEnum.H5.isSameCategory(ClientTypeEnum.ANDROID));
        assertFalse(ClientTypeEnum.ANDROID.isSameCategory(ClientTypeEnum.WECHAT_MINI));
    }
}
