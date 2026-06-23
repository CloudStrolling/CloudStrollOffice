/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

/**
 * 登录日志审计服务接口。
 *
 * <p>提供登录成功、登录失败和登出日志的记录和更新功能。
 * 日志写入失败不应影响主业务流程（try-catch 包裹，记录错误日志）。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface LoginLogService {

    /**
     * 更新最近登录记录的登出时间。
     *
     * <p>查找指定用户和客户端类型的最新登录成功日志记录（logoutTime 为 null），
     * 将 logoutTime 更新为当前时间。</p>
     *
     * @param userId     用户 ID，不能为 null
     * @param clientType 客户端类型，不能为 null
     */
    void updateLogoutTime(Long userId, String clientType);
}
