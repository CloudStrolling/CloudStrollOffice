/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.auth.dto.AccountSettlementRequest;
import org.cloudstrolling.cloudoffice.auth.dto.RegisterRequest;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.model.PageResult;

import java.util.List;

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

    /**
     * 分页查询用户列表。
     *
     * <p>支持按 login_name 和 user_name 字段模糊搜索，结果按创建时间降序排列。</p>
     *
     * @param tenantId 租户 ID
     * @param keyword  搜索关键词（可选，匹配 login_name 或 user_name）
     * @param page     当前页码（从1开始）
     * @param pageSize 每页条数
     * @return 分页结果，密码字段已脱敏
     */
    PageResult<UserEntity> list(Long tenantId, String keyword, int page, int pageSize);

    /**
     * 更新用户基本信息。
     *
     * <p>不包含密码变更，密码变更需通过独立的密码修改接口处理。</p>
     *
     * @param user 包含待更新字段的用户实体
     * @return 更新后的用户信息（不含密码）
     * @throws BusinessException 用户不存在
     */
    UserEntity update(UserEntity user);

    /**
     * 全量更新用户角色。
     *
     * <p>先删除用户现有的所有角色关联，再插入传入的角色 ID 列表（先删后插）。</p>
     *
     * @param userId  用户 ID
     * @param roleIds 新的角色 ID 列表
     * @throws BusinessException 用户不存在
     */
    void assignRoles(Long userId, List<Long> roleIds);

    /**
     * 逻辑删除用户。
     *
     * <p>将用户的 deleted 标记设为 1（已删除）。</p>
     *
     * @param userId 用户 ID
     * @throws BusinessException 用户不存在
     */
    void delete(Long userId);

    /**
     * 变更用户状态。
     *
     * <p>统一的状态变更入口，支持 0-正常、1-停用、2-锁定、3-封禁。
     * 锁定和封禁时会同步更新 Redis 缓存并清除用户登录态。</p>
     *
     * @param userId     用户 ID
     * @param status     目标状态（0-正常，1-停用，2-锁定，3-封禁）
     * @param lockReason 锁定/封禁原因（可选）
     * @throws BusinessException 用户不存在或状态值无效
     */
    void updateStatus(Long userId, Integer status, String lockReason);

    /**
     * 完善账号信息（两步注册第二步）。
     *
     * <p>用户在首次登录或信息不完整时补全账号信息。
     * 校验用户状态为 {@code account_settled=false}，
     * 然后更新登录名、密码和手机号，最后设置 {@code account_settled=true}。</p>
     *
     * @param userId  当前登录用户 ID
     * @param request 账号补全请求
     * @throws BusinessException 用户不存在、账号信息已完善或参数非法
     */
    void accountSettlement(Long userId, AccountSettlementRequest request);
}
