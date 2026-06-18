/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.model;

/**
 * 错误码接口。
 * <p>
 * 各业务模块的错误码枚举实现此接口，统一错误码规范。
 * </p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface ErrorCode {

    /**
     * 获取错误码。
     *
     * @return 错误码编号
     */
    Integer getCode();

    /**
     * 获取错误信息。
     *
     * @return 错误描述
     */
    String getMessage();
}
