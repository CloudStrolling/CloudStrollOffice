/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.entity;

import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import org.cloudstrolling.cloudoffice.common.model.BaseEntity;

import java.time.LocalDateTime;

/**
 * 验证码实体，对应 t_auth_verification_code 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_verification_code")
public class VerificationCodeEntity extends BaseEntity {

    /**
     * 验证码发送目标（手机号或邮箱）
     */
    private String target;

    /**
     * 验证码内容
     */
    private String code;

    /**
     * 发送方式（SMS-短信，EMAIL-邮件）
     */
    private String sendMode;

    /**
     * 验证码用途（REGISTER-注册，LOGIN-登录，RESET_PWD-重置密码，BIND-绑定等）
     */
    private String purpose;

    /**
     * 过期时间
     */
    private LocalDateTime expireTime;

    /**
     * 是否已使用（0-未使用，1-已使用）
     */
    private Integer used;

    /**
     * 使用时间
     */
    private LocalDateTime usedTime;

    /**
     * 发送次数（用于频率控制）
     */
    private Integer sendCount;
}
