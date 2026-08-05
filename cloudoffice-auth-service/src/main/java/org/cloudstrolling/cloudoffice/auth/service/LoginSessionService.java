/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.common.dto.LoginUserDTO;

/**
 * Redis 登录态管理服务接口。
 *
 * <p>提供登录态会话管理、Token 黑名单管理、账号状态缓存、租户状态缓存等功能，
 * 所有操作均基于 Redis 实现。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface LoginSessionService {

    // ========== 登录态会话管理 ==========

    /**
     * 创建登录态会话。
     *
     * <p>将会话数据以 JSON 格式存储到 Redis 中，设置指定过期时间。
     * 键格式：{@code auth:session:{userId}:{clientType}}</p>
     *
     * @param userId     用户 ID，不能为 null
     * @param clientType 客户端类型，不能为 null 或空
     * @param loginUser  登录用户信息，不能为 null
     * @param ttlSeconds 过期时间（秒）
     */
    void createSession(Long userId, String clientType, LoginUserDTO loginUser, long ttlSeconds);

    /**
     * 获取登录态会话。
     *
     * <p>从 Redis 中查询指定用户和客户端类型的登录态信息，
     * 并将 JSON 反序列化为 {@link LoginUserDTO}。</p>
     *
     * @param userId     用户 ID，不能为 null
     * @param clientType 客户端类型，不能为 null 或空
     * @return 登录用户信息，不存在时返回 null
     */
    LoginUserDTO getSession(Long userId, String clientType);

    /**
     * 删除登录态会话。
     *
     * <p>从 Redis 中删除指定用户和客户端类型的登录态。</p>
     *
     * @param userId     用户 ID，不能为 null
     * @param clientType 客户端类型，不能为 null 或空
     */
    void removeSession(Long userId, String clientType);

    /**
     * 删除用户所有客户端类型的登录态会话。
     *
     * <p>使用 Redis SCAN 命令匹配 {@code auth:session:{userId}:*} 模式，
     * 批量删除该用户所有端的登录态。</p>
     *
     * @param userId 用户 ID，不能为 null
     */
    void removeAllSessions(Long userId);

    // ========== Token 黑名单管理 ==========

    /**
     * 将 Token 签名加入黑名单。
     *
     * <p>键格式：{@code auth:blacklist:{tokenSignature}}</p>
     *
     * @param tokenSignature Token 签名指纹，不能为 null 或空
     * @param ttlSeconds     过期时间（秒），通常设为 Token 剩余有效期
     */
    void addToBlacklist(String tokenSignature, long ttlSeconds);

    /**
     * 判断 Token 签名是否在黑名单中。
     *
     * @param tokenSignature Token 签名指纹，不能为 null 或空
     * @return true 如果在黑名单中，否则 false
     */
    boolean isBlacklisted(String tokenSignature);

    // ========== 账号状态缓存 ==========

    /**
     * 设置账号状态缓存。
     *
     * <p>键格式：{@code auth:account:status:{userId}}</p>
     *
     * @param userId 用户 ID，不能为 null
     * @param status 账号状态（0-正常，1-禁用，2-锁定，3-封禁）
     */
    void setAccountStatus(Long userId, Integer status);

    /**
     * 获取账号状态缓存。
     *
     * @param userId 用户 ID，不能为 null
     * @return 账号状态，不存在时返回 null
     */
    Integer getAccountStatus(Long userId);

    /**
     * 删除账号状态缓存。
     *
     * @param userId 用户 ID，不能为 null
     */
    void removeAccountStatus(Long userId);

    // ========== 租户状态缓存 ==========

    /**
     * 设置租户状态缓存。
     *
     * <p>键格式：{@code auth:tenant:status:{tenantId}}</p>
     *
     * @param tenantId 租户 ID，不能为 null
     * @param status   租户状态（0-正常，1-禁用，2-过期）
     */
    void setTenantStatus(Long tenantId, Integer status);

    /**
     * 获取租户状态缓存。
     *
     * @param tenantId 租户 ID，不能为 null
     * @return 租户状态，不存在时返回 null
     */
    Integer getTenantStatus(Long tenantId);

    /**
     * 删除租户状态缓存。
     *
     * @param tenantId 租户 ID，不能为 null
     */
    void removeTenantStatus(Long tenantId);
}
