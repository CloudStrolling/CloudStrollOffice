/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.common.model;

import lombok.Data;
import lombok.experimental.Accessors;

/**
 * 统一响应体。
 * <p>
 * 所有 REST 接口统一返回此结构，包含状态码、提示信息、泛型数据和时间戳。
 * </p>
 *
 * @param <T> 响应数据类型
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@Accessors(chain = true)
public class ApiResult<T> {

    /** 状态码 */
    private Integer code;

    /** 提示信息 */
    private String message;

    /** 响应数据 */
    private T data;

    /** 时间戳（毫秒） */
    private Long timestamp;

    /**
     * 无参构造，自动填充时间戳。
     */
    public ApiResult() {
        this.timestamp = System.currentTimeMillis();
    }

    // ==================== 静态工厂方法 ====================

    /**
     * 成功响应（带数据）。
     *
     * @param data 响应数据
     * @param <T>  数据类型
     * @return ApiResult
     */
    public static <T> ApiResult<T> success(T data) {
        return new ApiResult<T>()
                .setCode(200)
                .setMessage("操作成功")
                .setData(data);
    }

    /**
     * 成功响应（无数据）。
     *
     * @param <T> 数据类型
     * @return ApiResult
     */
    public static <T> ApiResult<T> success() {
        return new ApiResult<T>()
                .setCode(200)
                .setMessage("操作成功");
    }

    /**
     * 错误响应。
     *
     * @param code    错误码
     * @param message 错误信息
     * @param <T>     数据类型
     * @return ApiResult
     */
    public static <T> ApiResult<T> error(Integer code, String message) {
        return new ApiResult<T>()
                .setCode(code)
                .setMessage(message);
    }

    /**
     * 通过错误码枚举创建错误响应。
     *
     * @param errorCode 错误码枚举
     * @param <T>       数据类型
     * @return ApiResult
     */
    public static <T> ApiResult<T> error(ErrorCode errorCode) {
        return new ApiResult<T>()
                .setCode(errorCode.getCode())
                .setMessage(errorCode.getMessage());
    }

    /**
     * 带数据的错误响应。
     *
     * @param code    错误码
     * @param message 错误信息
     * @param data    附加数据
     * @param <T>     数据类型
     * @return ApiResult
     */
    public static <T> ApiResult<T> error(Integer code, String message, T data) {
        return new ApiResult<T>()
                .setCode(code)
                .setMessage(message)
                .setData(data);
    }
}
