/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.cloudstrolling.cloudoffice.auth.entity.LoginLogEntity;

/**
 * 登录日志 Mapper，提供对 t_auth_login_log 表的基本 CRUD 操作。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Mapper
public interface LoginLogMapper extends BaseMapper<LoginLogEntity> {
}
