/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.cloudstrolling.cloudoffice.auth.entity.VerificationCodeEntity;

import java.time.LocalDateTime;

/**
 * 验证码 Mapper，提供 t_auth_verification_code 表的基本 CRUD 操作。
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Mapper
public interface VerificationCodeMapper extends BaseMapper<VerificationCodeEntity> {

    /**
     * 根据发送目标和用途查询最新的验证码（含逻辑删除条件）。
     *
     * @param target  发送目标（手机号或邮箱）
     * @param purpose 验证码用途
     * @return 验证码实体，未找到返回 null
     */
    VerificationCodeEntity selectLatestByTargetAndPurpose(@Param("target") String target, @Param("purpose") String purpose);

    /**
     * 更新验证码的使用状态。
     *
     * @param id       主键 ID
     * @param used     使用状态（0-未使用，1-已使用）
     * @param usedTime 使用时间
     * @return 影响的行数
     */
    int updateUsedStatus(@Param("id") Long id, @Param("used") Integer used, @Param("usedTime") LocalDateTime usedTime);

    /**
     * 删除已过期的验证码记录。
     *
     * @param expireTime 过期时间临界点
     * @return 影响的行数
     */
    int deleteExpired(@Param("expireTime") LocalDateTime expireTime);
}
