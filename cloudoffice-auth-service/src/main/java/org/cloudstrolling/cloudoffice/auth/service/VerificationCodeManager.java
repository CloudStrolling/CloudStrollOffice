/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

/**
 * 验证码管理器接口。
 *
 * <p>提供验证码生成、校验、频率控制和过期清理等核心能力。
 * 具体实现由 {@code VerificationCodeManagerImpl} 提供。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
public interface VerificationCodeManager {

    /**
     * 校验验证码（不含用途过滤）。
     *
     * <p>根据发送目标（手机号或邮箱）查询最新的验证码记录进行校验，
     * 校验成功后标记验证码为已使用。该方法不区分验证码用途，
     * 仅按目标查找最新未过期的验证码。</p>
     *
     * @param target 发送目标（手机号或邮箱）
     * @param code   用户输入的验证码
     * @return 校验通过返回 true，否则返回 false
     */
    boolean verifyCode(String target, String code);

    /**
     * 校验验证码（含用途过滤）。
     *
     * <p>根据发送目标和用途查询最新的验证码记录进行校验，
     * 校验成功后标记验证码为已使用。</p>
     *
     * @param target  发送目标（手机号或邮箱）
     * @param code    用户输入的验证码
     * @param purpose 验证码用途（REGISTER、LOGIN、RESET_PWD、BIND 等）
     * @return 校验通过返回 true，否则返回 false
     */
    boolean verifyCode(String target, String code, String purpose);

    /**
     * 生成验证码。
     *
     * <p>生成6位数字验证码，将记录写入数据库，
     * 并可选择写入 Redis 缓存（TTL = expireSeconds）。</p>
     *
     * @param target  发送目标（手机号或邮箱）
     * @param mode    发送方式（SMS-短信，EMAIL-邮件）
     * @param purpose 验证码用途（REGISTER、LOGIN、RESET_PWD、BIND 等）
     * @return 生成的验证码内容（6位数字字符串）
     */
    String generateCode(String target, String mode, String purpose);

    /**
     * 判断发送是否过于频繁。
     *
     * <p>查询最近60秒内是否有发送记录，如有则视为频繁发送。</p>
     *
     * @param target  发送目标（手机号或邮箱）
     * @param purpose 验证码用途
     * @return 如果发送过于频繁返回 true，否则返回 false
     */
    boolean isSendTooFrequent(String target, String purpose);

    /**
     * 清理过期验证码。
     *
     * <p>删除数据库中已过期的验证码记录，防止数据持续增长。</p>
     */
    void cleanExpiredCodes();
}
