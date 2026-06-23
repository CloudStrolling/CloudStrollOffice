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
import java.util.List;

/**
 * 用户实体，对应 t_auth_user 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_user")
public class UserEntity extends BaseEntity {

    /**
     * 所属租户 ID
     */
    private Long tenantId;

    /**
     * 登录名
     */
    private String loginName;

    /**
     * 密码（BCrypt 加密）
     */
    private String password;

    /**
     * 用户姓名
     */
    private String userName;

    /**
     * 手机号
     */
    private String phone;

    /**
     * 邮箱
     */
    private String email;

    /**
     * 头像 URL
     */
    private String avatar;

    /**
     * 状态（0-正常，1-停用，2-锁定，3-封禁）
     */
    private Integer status;

    /**
     * 锁定/封禁原因
     */
    private String lockReason;

    /**
     * 最后登录时间
     */
    private LocalDateTime lastLoginTime;

    /**
     * 最后登录 IP
     */
    private String lastLoginIp;

    /**
     * 角色编码列表（非数据库字段，用于返回用户详情时携带角色信息）
     */
    @TableField(exist = false)
    private List<String> roleCodes;
}
