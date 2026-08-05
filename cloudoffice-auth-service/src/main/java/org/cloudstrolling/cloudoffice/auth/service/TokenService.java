/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import org.cloudstrolling.cloudoffice.common.dto.TokenPairDTO;

/**
 * Token 刷新服务接口。
 *
 * <p>提供 Refresh Token 轮换机制，包含 RS256 验签、黑名单校验、
 * 用户与租户状态校验、双 Token 签发、旧 Token 吊销和 Redis 会话更新。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface TokenService {

    /**
     * 刷新 Token（含轮换机制）。
     *
     * <p>执行 Refresh Token 的 RS256 验签、黑名单校验、用户/租户状态校验，
     * 生成新的 Access Token 和 Refresh Token，将旧 Refresh Token 加入黑名单，
     * 更新 Redis 登录态会话，返回新的双 Token 对。</p>
     *
     * @param refreshToken 待刷新的 Refresh Token 字符串，不能为空
     * @param clientType   客户端类型编码，用于上下文校验
     * @return 新的双 Token 对（Access Token + Refresh Token）
     * @throws org.cloudstrolling.cloudoffice.common.exception.AuthException
     *         如果 Token 过期、无效或已在黑名单中
     * @throws org.cloudstrolling.cloudoffice.common.exception.BusinessException
     *         如果账号或租户状态异常（封禁、禁用等）
     */
    TokenPairDTO refresh(String refreshToken, String clientType);
}
