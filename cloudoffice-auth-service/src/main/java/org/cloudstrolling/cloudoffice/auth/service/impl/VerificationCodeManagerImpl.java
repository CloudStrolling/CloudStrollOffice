/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service.impl;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.entity.VerificationCodeEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.VerificationCodeMapper;
import org.cloudstrolling.cloudoffice.auth.service.VerificationCodeManager;
import org.cloudstrolling.cloudoffice.common.constant.RedisKeyConstants;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;

/**
 * 验证码管理器实现类。
 *
 * <p>使用 {@link VerificationCodeMapper} 实现验证码的数据库持久化，
 * 使用 {@link RedisTemplate} 实现验证码缓存和频率控制。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class VerificationCodeManagerImpl implements VerificationCodeManager {

    /** 验证码长度 */
    private static final int CODE_LENGTH = 6;

    /** 验证码默认过期时间（秒），默认 5 分钟 */
    private static final int DEFAULT_EXPIRE_SECONDS = 300;

    /** 验证码发送频率限制（秒），默认 60 秒 */
    private static final int FREQ_LIMIT_SECONDS = 60;

    private final VerificationCodeMapper verificationCodeMapper;
    private final RedisTemplate<String, Object> redisTemplate;

    @Override
    public boolean verifyCode(String target, String code) {
        // 从数据库查询该目标的最新未使用验证码（不区分用途）
        VerificationCodeEntity entity = verificationCodeMapper.selectLatestByTargetAndPurpose(target, null);
        return verifyCodeInternal(entity, code);
    }

    @Override
    public boolean verifyCode(String target, String code, String purpose) {
        // 从数据库查询该目标和用途的最新验证码
        VerificationCodeEntity entity = verificationCodeMapper.selectLatestByTargetAndPurpose(target, purpose);
        return verifyCodeInternal(entity, code);
    }

    @Override
    public String generateCode(String target, String mode, String purpose) {
        // 1. 生成6位数字验证码（首位不为0）
        String code = String.valueOf(ThreadLocalRandom.current().nextInt(100000, 999999));

        // 2. 计算过期时间
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime expireTime = now.plusSeconds(DEFAULT_EXPIRE_SECONDS);

        // 3. 写入数据库
        VerificationCodeEntity entity = new VerificationCodeEntity();
        entity.setTarget(target);
        entity.setCode(code);
        entity.setSendMode(mode);
        entity.setPurpose(purpose);
        entity.setExpireTime(expireTime);
        entity.setUsed(0);
        verificationCodeMapper.insert(entity);

        log.info("验证码生成成功 | target={} | mode={} | purpose={} | expireTime={}",
                maskTarget(target), mode, purpose, expireTime);

        // 4. 写入 Redis 缓存（TTL = DEFAULT_EXPIRE_SECONDS）
        try {
            String cacheKey = RedisKeyConstants.buildVerificationCodeKey(purpose, target);
            redisTemplate.opsForValue().set(cacheKey, code, DEFAULT_EXPIRE_SECONDS, TimeUnit.SECONDS);
        } catch (Exception e) {
            log.warn("验证码写入 Redis 缓存失败 | target={} | purpose={}", maskTarget(target), purpose, e);
        }

        // 5. 写入频率控制标记（TTL = FREQ_LIMIT_SECONDS）
        try {
            String freqKey = RedisKeyConstants.buildVerificationCodeFreqKey(purpose, target);
            redisTemplate.opsForValue().set(freqKey, "1", FREQ_LIMIT_SECONDS, TimeUnit.SECONDS);
        } catch (Exception e) {
            log.warn("验证码频率控制写入 Redis 失败 | target={} | purpose={}", maskTarget(target), purpose, e);
        }

        return code;
    }

    @Override
    public boolean isSendTooFrequent(String target, String purpose) {
        try {
            String freqKey = RedisKeyConstants.buildVerificationCodeFreqKey(purpose, target);
            return Boolean.TRUE.equals(redisTemplate.hasKey(freqKey));
        } catch (Exception e) {
            log.warn("验证码频率检查失败 | target={} | purpose={}", maskTarget(target), purpose, e);
            // Redis 异常时放行，避免阻塞正常发送
            return false;
        }
    }

    @Override
    public void cleanExpiredCodes() {
        LocalDateTime now = LocalDateTime.now();
        int deletedCount = verificationCodeMapper.deleteExpired(now);
        if (deletedCount > 0) {
            log.info("清理过期验证码完成 | 删除数量={}", deletedCount);
        }
    }

    /**
     * 验证码校验内部方法。
     *
     * <p>校验实体不为空、未过期、未使用且验证码匹配，校验通过后标记为已使用。</p>
     *
     * @param entity 验证码实体，可能为 null
     * @param code   用户输入的验证码
     * @return 校验通过返回 true，否则返回 false
     */
    private boolean verifyCodeInternal(VerificationCodeEntity entity, String code) {
        // 1. 校验存在性
        if (entity == null) {
            log.warn("验证码校验失败：验证码不存在");
            return false;
        }

        // 2. 校验是否过期
        if (entity.getExpireTime() != null && entity.getExpireTime().isBefore(LocalDateTime.now())) {
            log.warn("验证码校验失败：验证码已过期 | target={}", maskTarget(entity.getTarget()));
            return false;
        }

        // 3. 校验是否已使用
        if (entity.getUsed() != null && entity.getUsed() == 1) {
            log.warn("验证码校验失败：验证码已使用 | target={}", maskTarget(entity.getTarget()));
            return false;
        }

        // 4. 校验验证码内容
        if (!entity.getCode().equals(code)) {
            log.warn("验证码校验失败：验证码不匹配 | target={}", maskTarget(entity.getTarget()));
            return false;
        }

        // 5. 标记为已使用
        verificationCodeMapper.updateUsedStatus(entity.getId(), 1, LocalDateTime.now());

        log.info("验证码校验成功 | target={}", maskTarget(entity.getTarget()));
        return true;
    }

    /**
     * 对验证码目标进行脱敏处理，用于日志输出。
     *
     * @param target 发送目标（手机号或邮箱）
     * @return 脱敏后的目标字符串
     */
    private static String maskTarget(String target) {
        if (target == null || target.length() <= 3) {
            return target;
        }
        if (target.contains("@")) {
            // 邮箱脱敏：a***@example.com
            int atIndex = target.indexOf("@");
            String prefix = target.substring(0, Math.min(atIndex, 1));
            return prefix + "***" + target.substring(atIndex);
        }
        // 手机号脱敏：138****0000
        return target.substring(0, 3) + "****" + target.substring(target.length() - 4);
    }
}
