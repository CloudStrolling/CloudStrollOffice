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
 * OAuth 第三方账号关联实体，对应 t_auth_oauth_account 表。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Data
@EqualsAndHashCode(callSuper = true)
@TableName("t_auth_oauth_account")
public class OAuthAccountEntity extends BaseEntity {

    /**
     * 用户 ID，关联 t_auth_user 表
     */
    private Long userId;

    /**
     * OAuth 提供商（如 wechat、qq、gitee、github 等）
     */
    private String oauthProvider;

    /**
     * OAuth 开放平台唯一 ID（openId）
     */
    private String oauthOpenId;

    /**
     * OAuth 开放平台 unionId（适用于微信等支持 UnionID 的平台）
     */
    private String oauthUnionId;

    /**
     * OAuth 第三方昵称
     */
    private String oauthNickname;

    /**
     * OAuth 第三方头像 URL
     */
    private String oauthAvatar;

    /**
     * 绑定时间
     */
    private LocalDateTime boundTime;
}
