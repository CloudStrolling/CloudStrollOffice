/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.cloudstrolling.cloudoffice.auth.entity.OAuthAccountEntity;

import java.util.List;

/**
 * OAuth 第三方账号关联 Mapper，提供 t_auth_oauth_account 表的基本 CRUD 操作。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Mapper
public interface OAuthAccountMapper extends BaseMapper<OAuthAccountEntity> {

    /**
     * 根据用户 ID 查询所有绑定的 OAuth 账号（含逻辑删除条件）。
     *
     * @param userId 用户 ID
     * @return OAuth 账号列表
     */
    List<OAuthAccountEntity> selectByUserId(@Param("userId") Long userId);

    /**
     * 根据提供商和 openId 查询 OAuth 账号（含逻辑删除条件）。
     *
     * @param provider OAuth 提供商
     * @param openId   OAuth openId
     * @return OAuth 账号实体，未找到返回 null
     */
    OAuthAccountEntity selectByProviderAndOpenId(@Param("provider") String provider, @Param("openId") String openId);
}
