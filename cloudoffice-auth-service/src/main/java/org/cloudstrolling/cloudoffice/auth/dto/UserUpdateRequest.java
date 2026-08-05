/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.dto;

import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 用户信息更新请求 DTO。
 *
 * <p>用于更新用户的基本信息，如姓名、手机号、邮箱等。
 * 密码变更需通过独立的密码修改接口处理。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
public class UserUpdateRequest {

    /**
     * 用户姓名
     */
    @Size(max = 50, message = "用户姓名长度不能超过50字符")
    private String userName;

    /**
     * 手机号
     */
    private String phone;

    /**
     * 邮箱
     */
    private String email;
}
