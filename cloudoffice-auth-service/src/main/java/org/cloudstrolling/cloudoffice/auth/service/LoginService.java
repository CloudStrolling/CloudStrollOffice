/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.auth.dto.LoginRequest;
import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;

/**
 * 登录认证业务服务接口。
 *
 * <p>提供登录、登出、强制踢人等认证相关的业务逻辑。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface LoginService {

    /**
     * 用户登录。
     *
     * <p>执行完整的登录认证流程：</p>
     * <ol>
     *   <li>参数校验</li>
     *   <li>clientType 合法性校验</li>
     *   <li>租户查询与状态校验</li>
     *   <li>用户查询与状态校验</li>
     *   <li>BCrypt 密码校验</li>
     *   <li>角色权限查询</li>
     *   <li>双 Token 签发（Access + Refresh）</li>
     *   <li>同端互斥处理</li>
     *   <li>Redis 登录态写入</li>
     *   <li>账号/租户状态缓存</li>
     *   <li>登录日志记录</li>
     *   <li>用户表 last_login_time/ip 更新</li>
     * </ol>
     *
     * @param request 登录请求（loginName、password、tenantCode、clientType）
     * @return 双 Token 响应 DTO
     * @throws org.cloudstrolling.cloudoffice.common.exception.AuthException
     *         如果用户名或密码错误（LOGIN_FAILED）
     * @throws org.cloudstrolling.cloudoffice.common.exception.BusinessException
     *         如果租户不存在、租户状态异常、账号状态异常或 clientType 无效
     */
    TokenPairDTO login(LoginRequest request);

    /**
     * 强制踢人。
     *
     * <p>管理员强制指定用户下线。如果 {@code clientType} 非空则踢指定端的登录态，
     * 如果为空则踢所有端的登录态。流程包括：</p>
     * <ul>
     *   <li>校验操作者权限（需为管理员）</li>
     *   <li>校验目标用户存在</li>
     *   <li>Token 入黑名单</li>
     *   <li>登录态删除</li>
     *   <li>审计日志记录</li>
     * </ul>
     *
     * @param targetUserId 目标用户 ID
     * @param clientType   客户端类型（可选，为空时踢所有端）
     * @throws org.cloudstrolling.cloudoffice.common.exception.BusinessException
     *         如果操作者权限不足、目标用户不存在或 clientType 不合法
     */
    void kickout(Long targetUserId, String clientType);

    /**
     * 用户登出。
     *
     * <p>执行以下登出流程：</p>
     * <ol>
     *   <li>解析 Access Token 获取用户信息和签名指纹</li>
     *   <li>计算 Token 剩余有效期</li>
     *   <li>将 Token 加入黑名单（TTL = 剩余有效期）</li>
     *   <li>删除 Redis 中的登录态会话</li>
     *   <li>更新登录日志的登出时间</li>
     * </ol>
     *
     * <p>支持幂等处理：重复登出或 Token 已失效时返回成功，不抛出异常。</p>
     *
     * @param accessToken 用户的 Access Token
     * @param clientType  客户端类型编码
     */
    void logout(String accessToken, String clientType);
}
