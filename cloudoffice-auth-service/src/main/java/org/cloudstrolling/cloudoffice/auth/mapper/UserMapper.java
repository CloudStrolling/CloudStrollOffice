/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;

import java.util.List;

/**
 * 用户 Mapper，提供 t_auth_user 表的基本 CRUD 操作及联表查询。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Mapper
public interface UserMapper extends BaseMapper<UserEntity> {

    /**
     * 根据租户 ID 和登录名查询用户（含逻辑删除条件）。
     *
     * @param tenantId  租户 ID
     * @param loginName 登录名
     * @return 用户实体，未找到返回 null
     */
    UserEntity selectByTenantIdAndLoginName(@Param("tenantId") Long tenantId, @Param("loginName") String loginName);

    /**
     * 查询用户的所有角色编码列表。
     *
     * @param userId 用户 ID
     * @return 角色编码列表
     */
    List<String> selectRoleCodesByUserId(@Param("userId") Long userId);

    /**
     * 查询用户的所有权限标识列表。
     *
     * @param userId 用户 ID
     * @return 权限标识列表
     */
    List<String> selectPermissionCodesByUserId(@Param("userId") Long userId);
}
