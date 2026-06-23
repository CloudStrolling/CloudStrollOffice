/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;

/**
 * 用户业务逻辑接口。
 *
 * <p>提供用户注册、查询、状态变更（封禁/解封/锁定/解锁）等核心业务方法。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface UserService {

    /**
     * 用户注册。
     *
     * <p>执行业务流程：租户状态校验 → loginName 唯一性校验 → BCrypt 密码加密
     * → 创建用户记录 → 分配默认角色 → 返回用户信息（不含密码）。</p>
     *
     * @param request 注册请求 DTO
     * @return 注册成功的用户实体（不含密码字段）
     * @throws BusinessException 租户不存在/已禁用、登录名重复等业务异常
     */
    UserEntity register(RegisterRequest request);

    /**
     * 根据用户 ID 查询用户信息。
     *
     * @param id 用户 ID
     * @return 用户实体（不含密码字段），不存在返回 null
     */
    UserEntity findById(Long id);

    /**
     * 封禁用户。
     *
     * <p>将用户状态设为 {@code 3-已封禁}，同步更新 Redis 缓存，
     * 并清除该用户的所有登录态会话。</p>
     *
     * @param userId 用户 ID
     * @throws IllegalArgumentException userId 为 null
     * @throws BusinessException      用户不存在（{@link org.cloudstrolling.cloudoffice.common.exception.ErrorCode#USER_NOT_FOUND}）
     */
    void banUser(Long userId);

    /**
     * 解封用户。
     *
     * <p>将用户状态恢复为 {@code 0-正常}，并移除 Redis 中的状态缓存。</p>
     *
     * @param userId 用户 ID
     * @throws IllegalArgumentException userId 为 null
     * @throws BusinessException      用户不存在（{@link org.cloudstrolling.cloudoffice.common.exception.ErrorCode#USER_NOT_FOUND}）
     */
    void unbanUser(Long userId);

    /**
     * 锁定用户。
     *
     * <p>将用户状态设为 {@code 2-已锁定}，同步更新 Redis 缓存，
     * 并清除该用户的所有登录态会话。</p>
     *
     * @param userId 用户 ID
     * @throws IllegalArgumentException userId 为 null
     * @throws BusinessException      用户不存在（{@link org.cloudstrolling.cloudoffice.common.exception.ErrorCode#USER_NOT_FOUND}）
     */
    void lockUser(Long userId);

    /**
     * 解锁用户。
     *
     * <p>将用户状态恢复为 {@code 0-正常}，并移除 Redis 中的状态缓存。</p>
     *
     * @param userId 用户 ID
     * @throws IllegalArgumentException userId 为 null
     * @throws BusinessException      用户不存在（{@link org.cloudstrolling.cloudoffice.common.exception.ErrorCode#USER_NOT_FOUND}）
     */
    void unlockUser(Long userId);
}
