/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.enums;

import lombok.Getter;

import java.io.Serializable;
import java.util.Arrays;
import java.util.Optional;

/**
 * 客户端类型枚举。
 * <p>
 * 定义系统支持的客户端类型及其所属设备分类，用于客户端身份标识、同端互斥等场景。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Getter
public enum ClientTypeEnum implements Serializable {

    /** Windows 桌面端 */
    WINDOWS("WINDOWS", DeviceCategory.PC),

    /** Ubuntu 桌面端 */
    UBUNTU("UBUNTU", DeviceCategory.PC),

    /** 移动端 H5 */
    H5("H5", DeviceCategory.WEB),

    /** Android 移动端 */
    ANDROID("ANDROID", DeviceCategory.MOBILE),

    /** iOS 移动端 */
    IOS("IOS", DeviceCategory.MOBILE),

    /** 微信小程序 */
    WECHAT_MINI("WECHAT_MINI", DeviceCategory.MINI_PROGRAM);

    /** 客户端编码 */
    private final String code;

    /** 设备分类 */
    private final DeviceCategory deviceCategory;

    ClientTypeEnum(String code, DeviceCategory deviceCategory) {
        this.code = code;
        this.deviceCategory = deviceCategory;
    }

    /**
     * 设备分类枚举。
     * <p>
     * 用于对客户端类型进行分组，同组客户端之间互斥（不可同时在线）。
     * </p>
     */
    public enum DeviceCategory {
        PC,
        WEB,
        MOBILE,
        MINI_PROGRAM
    }

    /**
     * 根据编码查询客户端类型，大小写不敏感。
     *
     * @param code 客户端编码，可为 null
     * @return 包含匹配枚举的 Optional，若未找到则返回 {@link Optional#empty()}
     */
    public static Optional<ClientTypeEnum> fromCode(String code) {
        if (code == null) {
            return Optional.empty();
        }
        return Arrays.stream(values())
                .filter(clientType -> clientType.code.equalsIgnoreCase(code))
                .findFirst();
    }

    /**
     * 判断当前客户端类型是否与指定客户端类型属于同一设备分类。
     * <p>
     * 同一设备分类的客户端互斥，不可同时在线。
     * </p>
     *
     * @param other 另一个客户端类型
     * @return 若属于同一设备分类返回 true，否则返回 false
     */
    public boolean isSameCategory(ClientTypeEnum other) {
        return this.deviceCategory == other.deviceCategory;
    }
}
