/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 用户状态变更请求 DTO。
 *
 * <p>用于变更用户账号的状态：</p>
 * <ul>
 *   <li><strong>0</strong> — 正常</li>
 *   <li><strong>1</strong> — 停用</li>
 *   <li><strong>2</strong> — 锁定</li>
 *   <li><strong>3</strong> — 封禁</li>
 * </ul>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class UserStatusRequest {

    /**
     * 目标状态（0-正常，1-停用，2-锁定，3-封禁）
     */
    @NotNull(message = "用户状态不能为空")
    @Min(value = 0, message = "状态值范围为0-3")
    @Max(value = 3, message = "状态值范围为0-3")
    private Integer status;

    /**
     * 锁定/封禁原因（可选）
     */
    private String lockReason;
}
