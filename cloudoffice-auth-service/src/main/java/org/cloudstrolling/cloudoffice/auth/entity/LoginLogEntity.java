/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import lombok.EqualsAndHashCode;
import org.cloudstrolling.cloudoffice.common.model.BaseEntity;

import java.time.LocalDateTime;

/**
 * 登录日志实体，对应 t_auth_login_log 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_login_log")
public class LoginLogEntity extends BaseEntity {

    /**
     * 用户 ID
     */
    private Long userId;

    /**
     * 租户 ID
     */
    private Long tenantId;

    /**
     * 登录 IP
     */
    private String loginIp;

    /**
     * 客户端类型（WEB / APP / API）
     */
    private String clientType;

    /**
     * 设备信息
     */
    private String deviceInfo;

    /**
     * 登录时间
     */
    private LocalDateTime loginTime;

    /**
     * 登出时间
     */
    private LocalDateTime logoutTime;

    /**
     * 登录结果（0-成功，1-失败）
     */
    private Integer loginResult;

    /**
     * 失败原因
     */
    private String failReason;
}
