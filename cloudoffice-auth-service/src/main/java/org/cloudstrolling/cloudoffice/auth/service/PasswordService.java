/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.cloudstrolling.cloudoffice.auth.dto.PhoneChangeRequest;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.cloudstrolling.cloudoffice.common.exception.ErrorCode;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;

/**
 * 密码管理服务。
 *
 * <p>提供密码修改、忘记密码发送验证码、忘记密码重置等密码管理功能。
 * 涉及 {@link UserMapper}、{@link VerificationCodeManager}、
 * {@link VerificationCodeService} 和 {@link LoginSessionService} 等组件协作。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class PasswordService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final LoginSessionService loginSessionService;
    private final VerificationCodeManager verificationCodeManager;
    private final VerificationCodeService verificationCodeService;

    /**
     * 修改密码。
     *
     * <p>流程：</p>
     * <ol>
     *   <li>根据 userId 查询用户</li>
     *   <li>BCrypt 校验旧密码（不匹配时抛出 OLD_PASSWORD_INCORRECT）</li>
     *   <li>校验新密码与旧密码不同</li>
     *   <li>BCrypt 加密新密码</li>
     *   <li>更新用户密码和 lastPasswordChangeTime</li>
     *   <li>清除该用户所有 Redis 登录态会话</li>
     * </ol>
     *
     * @param userId      用户 ID
     * @param oldPassword 旧密码（明文）
     * @param newPassword 新密码（明文）
     */
    @Transactional(rollbackFor = Exception.class)
    public void changePassword(Long userId, String oldPassword, String newPassword) {
        Assert.notNull(userId, "userId must not be null");
        Assert.hasText(oldPassword, "oldPassword must not be empty");
        Assert.hasText(newPassword, "newPassword must not be empty");

        // 1. 查询用户
        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("修改密码失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. BCrypt 校验旧密码
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            log.warn("修改密码失败：原密码错误 | userId={}", userId);
            throw new BusinessException(ErrorCode.OLD_PASSWORD_INCORRECT);
        }

        // 3. 校验新密码与旧密码不同
        if (oldPassword.equals(newPassword)) {
            log.warn("修改密码失败：新密码不能与旧密码相同 | userId={}", userId);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "新密码不能与旧密码相同");
        }

        // 4. BCrypt 加密新密码
        String encryptedPassword = passwordEncoder.encode(newPassword);

        // 5. 更新用户密码和 lastPasswordChangeTime
        user.setPassword(encryptedPassword);
        user.setLastPasswordChangeTime(LocalDateTime.now());
        userMapper.updateById(user);
        log.info("密码修改成功 | userId={}", userId);

        // 6. 清除该用户所有 Redis 登录态会话
        try {
            loginSessionService.removeAllSessions(userId);
            log.info("密码修改后已清除所有登录态 | userId={}", userId);
        } catch (Exception e) {
            log.warn("密码修改后清除登录态失败 | userId={}", userId, e);
        }
    }

    /**
     * 忘记密码 - 发送验证码。
     *
     * <p>流程：</p>
     * <ol>
     *   <li>校验 target 对应的账号存在</li>
     *   <li>生成验证码并持久化</li>
     *   <li>调用验证码发送服务发送验证码</li>
     * </ol>
     *
     * @param target 验证目标（手机号或邮箱）
     * @param mode   发送方式（SMS-短信，EMAIL-邮件）
     */
    @Transactional(rollbackFor = Exception.class)
    public void forgotPasswordSendCode(String target, String mode) {
        Assert.hasText(target, "target must not be empty");
        Assert.hasText(mode, "mode must not be empty");

        // 1. 校验 target 对应的账号存在
        UserEntity user = queryUserByTarget(target, mode);
        if (user == null) {
            log.warn("忘记密码发送验证码失败：账号不存在 | target={}", maskTarget(target));
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. 生成验证码
        String purpose = "RESET_PWD";
        String code = verificationCodeManager.generateCode(target, mode, purpose);
        log.info("忘记密码验证码生成成功 | userId={} | mode={}", user.getId(), mode);

        // 3. 发送验证码
        if ("SMS".equalsIgnoreCase(mode)) {
            verificationCodeService.sendSmsCode(target, code, purpose);
        } else if ("EMAIL".equalsIgnoreCase(mode)) {
            verificationCodeService.sendEmailCode(target, code, purpose);
        } else {
            log.warn("忘记密码发送验证码失败：无效的发送方式 | mode={}", mode);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "无效的发送方式");
        }

        log.info("忘记密码验证码发送成功 | userId={} | mode={}", user.getId(), mode);
    }

    /**
     * 忘记密码 - 重置密码。
     *
     * <p>流程：</p>
     * <ol>
     *   <li>校验验证码</li>
     *   <li>查询用户</li>
     *   <li>BCrypt 加密新密码</li>
     *   <li>更新密码</li>
     *   <li>清除该用户所有 Redis 登录态</li>
     * </ol>
     *
     * @param target     验证目标（手机号或邮箱）
     * @param mode       发送方式（SMS-短信，EMAIL-邮件）
     * @param code       验证码
     * @param newPassword 新密码（明文）
     */
    @Transactional(rollbackFor = Exception.class)
    public void forgotPasswordReset(String target, String mode, String code, String newPassword) {
        Assert.hasText(target, "target must not be empty");
        Assert.hasText(mode, "mode must not be empty");
        Assert.hasText(code, "code must not be empty");
        Assert.hasText(newPassword, "newPassword must not be empty");

        // 1. 校验验证码
        String purpose = "RESET_PWD";
        boolean codeValid = verificationCodeManager.verifyCode(target, code, purpose);
        if (!codeValid) {
            log.warn("忘记密码重置失败：验证码无效 | target={}", maskTarget(target));
            throw new BusinessException(ErrorCode.SMS_CODE_INVALID);
        }

        // 2. 查询用户
        UserEntity user = queryUserByTarget(target, mode);
        if (user == null) {
            log.warn("忘记密码重置失败：账号不存在 | target={}", maskTarget(target));
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 3. BCrypt 加密新密码
        String encryptedPassword = passwordEncoder.encode(newPassword);

        // 4. 更新密码和 lastPasswordChangeTime
        user.setPassword(encryptedPassword);
        user.setLastPasswordChangeTime(LocalDateTime.now());
        userMapper.updateById(user);
        log.info("忘记密码重置成功 | userId={}", user.getId());

        // 5. 清除该用户所有 Redis 登录态
        try {
            loginSessionService.removeAllSessions(user.getId());
            log.info("密码重置后已清除所有登录态 | userId={}", user.getId());
        } catch (Exception e) {
            log.warn("密码重置后清除登录态失败 | userId={}", user.getId(), e);
        }
    }

    /**
     * 根据验证目标（手机号或邮箱）和发送方式查询用户。
     *
     * @param target 验证目标
     * @param mode   发送方式（SMS 按手机号查询，EMAIL 按邮箱查询）
     * @return 用户实体，未找到返回 null
     */
    private UserEntity queryUserByTarget(String target, String mode) {
        if ("SMS".equalsIgnoreCase(mode)) {
            LambdaQueryWrapper<UserEntity> query = Wrappers.lambdaQuery();
            query.eq(UserEntity::getPhone, target);
            return userMapper.selectOne(query);
        } else if ("EMAIL".equalsIgnoreCase(mode)) {
            LambdaQueryWrapper<UserEntity> query = Wrappers.lambdaQuery();
            query.eq(UserEntity::getEmail, target);
            return userMapper.selectOne(query);
        }
        return null;
    }

    /**
     * 更换手机号。
     *
     * <p>流程：</p>
     * <ol>
     *   <li>根据 userId 查询用户</li>
     *   <li>根据 oldPhoneCode 或 emailCode 的存在判断场景</li>
     *   <li>校验对应场景的验证码</li>
     *   <li>更新用户手机号</li>
     * </ol>
     *
     * @param userId  用户 ID
     * @param request 手机号更换请求
     */
    @Transactional(rollbackFor = Exception.class)
    public void changePhone(Long userId, PhoneChangeRequest request) {
        Assert.notNull(userId, "userId must not be null");
        Assert.notNull(request, "request must not be null");
        Assert.hasText(request.getNewPhone(), "newPhone must not be empty");
        Assert.hasText(request.getNewPhoneCode(), "newPhoneCode must not be empty");

        // 1. 查询用户
        UserEntity user = userMapper.selectById(userId);
        if (user == null) {
            log.warn("更换手机号失败：用户不存在 | userId={}", userId);
            throw new BusinessException(ErrorCode.USER_NOT_FOUND);
        }

        // 2. 判断场景并校验验证码
        if (StringUtils.hasText(request.getOldPhoneCode())) {
            // 场景一：已绑定手机号，需校验旧手机号验证码
            if (!StringUtils.hasText(user.getPhone())) {
                log.warn("更换手机号失败：用户未绑定旧手机号但提供了旧手机号验证码 | userId={}", userId);
                throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "用户未绑定手机号，无需提供旧手机号验证码");
            }
            boolean oldCodeValid = verificationCodeManager.verifyCode(user.getPhone(), request.getOldPhoneCode(), "CHANGE_PHONE");
            if (!oldCodeValid) {
                log.warn("更换手机号失败：旧手机号验证码无效 | userId={}", userId);
                throw new BusinessException(ErrorCode.SMS_CODE_INVALID);
            }
        } else if (StringUtils.hasText(request.getEmailCode())) {
            // 场景二：未绑定手机号（绑定了邮箱），需校验邮箱验证码
            if (!StringUtils.hasText(user.getEmail())) {
                log.warn("更换手机号失败：用户未绑定邮箱但提供了邮箱验证码 | userId={}", userId);
                throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "用户未绑定邮箱，无需提供邮箱验证码");
            }
            boolean emailCodeValid = verificationCodeManager.verifyCode(user.getEmail(), request.getEmailCode(), "CHANGE_PHONE");
            if (!emailCodeValid) {
                log.warn("更换手机号失败：邮箱验证码无效 | userId={}", userId);
                throw new BusinessException(ErrorCode.SMS_CODE_INVALID);
            }
        } else {
            log.warn("更换手机号失败：缺少验证码 | userId={}", userId);
            throw new BusinessException(ErrorCode.BAD_REQUEST.getCode(), "请提供旧手机号验证码或邮箱验证码");
        }

        // 3. 校验新手机号验证码
        boolean newCodeValid = verificationCodeManager.verifyCode(request.getNewPhone(), request.getNewPhoneCode(), "CHANGE_PHONE");
        if (!newCodeValid) {
            log.warn("更换手机号失败：新手机号验证码无效 | userId={}", userId);
            throw new BusinessException(ErrorCode.SMS_CODE_INVALID);
        }

        // 4. 校验新手机号是否已被其他账号绑定
        UserEntity existingUser = queryUserByTarget(request.getNewPhone(), "SMS");
        if (existingUser != null && !existingUser.getId().equals(userId)) {
            log.warn("更换手机号失败：新手机号已被其他账号绑定 | newPhone={}", maskTarget(request.getNewPhone()));
            throw new BusinessException(ErrorCode.PHONE_ALREADY_BOUND);
        }

        // 5. 更新用户手机号
        user.setPhone(request.getNewPhone());
        userMapper.updateById(user);
        log.info("手机号更换成功 | userId={} | newPhone={}", userId, maskTarget(request.getNewPhone()));
    }

    /**
     * 对目标进行脱敏处理，用于日志输出。
     *
     * @param target 手机号或邮箱
     * @return 脱敏后的字符串
     */
    private static String maskTarget(String target) {
        if (!StringUtils.hasText(target) || target.length() <= 3) {
            return target;
        }
        if (target.contains("@")) {
            int atIndex = target.indexOf("@");
            return target.substring(0, Math.min(atIndex, 1)) + "***" + target.substring(atIndex);
        }
        return target.substring(0, 3) + "****" + target.substring(target.length() - 4);
    }
}
