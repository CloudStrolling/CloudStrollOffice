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
 * 租户实体，对应 t_auth_tenant 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_tenant")
public class TenantEntity extends BaseEntity {

    /**
     * 租户名称
     */
    private String tenantName;

    /**
     * 租户编码
     */
    private String tenantCode;

    /**
     * 联系人姓名
     */
    private String contactName;

    /**
     * 联系人电话
     */
    private String contactPhone;

    /**
     * 状态（0-正常，1-停用）
     */
    private Integer status;

    /**
     * 过期时间
     */
    private LocalDateTime expireTime;
}
