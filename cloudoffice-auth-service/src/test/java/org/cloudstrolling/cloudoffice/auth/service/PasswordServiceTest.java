/*
 * SPDX-License-Identifier: Apache-2.0
 * Copyright 2026 CloudStrolling/jenemy8023 <jenemy8023@163.com>
 */

package org.cloudstrolling.cloudoffice.auth.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.cloudstrolling.cloudoffice.auth.dto.PhoneChangeRequest;
import org.cloudstrolling.cloudoffice.auth.entity.UserEntity;
import org.cloudstrolling.cloudoffice.auth.mapper.UserMapper;
import org.cloudstrolling.cloudoffice.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * {@link PasswordService} 的单元测试。
 *
 * <p>覆盖 UT-037~UT-042：修改密码成功与全端下线、旧密码错误/新旧相同拒绝、
 * 忘记密码发送/重置分支、换绑手机（短信/邮箱场景、占用拒绝、缺少验证码）、
 * 密码长度边界。</p>
 *
 * @author CloudStrolling
 * @since 1.0
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("PasswordService 单元测试")
class PasswordServiceTest {

    @Mock
    private UserMapper userMapper;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private LoginSessionService loginSessionService;

    @Mock
    private VerificationCodeManager verificationCodeManager;

    @Mock
    private VerificationCodeService verificationCodeService;

    private PasswordService passwordService;

    @BeforeEach
    void setUp() {
        passwordService = new PasswordService(userMapper, passwordEncoder,
                loginSessionService, verificationCodeManager, verificationCodeService);
    }

    /**
     * 构造用户实体（已绑定手机号与邮箱）。
     */
    private UserEntity buildUser() {
        UserEntity user = new UserEntity();
        user.setId(1L);
        user.setLoginName("tester_pwd");
        user.setUserName("测试用户");
        user.setPassword("$2a$10$oldPasswordMock");
        user.setPhone("13800000001");
        user.setEmail("tester@example.com");
        user.setStatus(0);
        return user;
    }

    /**
     * UT-037：修改密码成功，更新密码并清除全端会话（P0）。
     */
    @Test
    @DisplayName("UT-037: 修改密码成功，密码为 BCrypt 密文并 removeAllSessions")
    void changePassword_shouldUpdateAndKickAllSessions_whenOldPasswordValid() {
        when(userMapper.selectById(1L)).thenReturn(buildUser());
        when(passwordEncoder.matches("old_pass", "$2a$10$oldPasswordMock")).thenReturn(true);
        when(passwordEncoder.encode("new_pass")).thenReturn("$2a$10$newPasswordMock");

        passwordService.changePassword(1L, "old_pass", "new_pass");

        verify(userMapper, times(1)).updateById(argThat(user ->
                "$2a$10$newPasswordMock".equals(user.getPassword())));
        verify(loginSessionService, times(1)).removeAllSessions(1L);
    }

    /**
     * UT-038：旧密码错误抛 OLD_PASSWORD_INCORRECT（P0）。
     */
    @Test
    @DisplayName("UT-038: 旧密码错误抛 OLD_PASSWORD_INCORRECT")
    void changePassword_shouldThrow_whenOldPasswordIncorrect() {
        when(userMapper.selectById(1L)).thenReturn(buildUser());
        when(passwordEncoder.matches("wrong_old", "$2a$10$oldPasswordMock")).thenReturn(false);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> passwordService.changePassword(1L, "wrong_old", "new_pass"));
        assertEquals("原密码错误", ex.getMessage());
        verify(userMapper, never()).updateById(any(UserEntity.class));
    }

    /**
     * UT-038：新旧密码相同被拒（P0）。
     */
    @Test
    @DisplayName("UT-038: 新密码与旧密码相同被拒")
    void changePassword_shouldThrow_whenNewSameAsOld() {
        when(userMapper.selectById(1L)).thenReturn(buildUser());
        when(passwordEncoder.matches("same_pass", "$2a$10$oldPasswordMock")).thenReturn(true);

        BusinessException ex = assertThrows(BusinessException.class,
                () -> passwordService.changePassword(1L, "same_pass", "same_pass"));
        assertEquals("新密码不能与旧密码相同", ex.getMessage());
        verify(userMapper, never()).updateById(any(UserEntity.class));
    }

    /**
     * UT-039：忘记密码发送验证码（账号存在发送成功 / 不存在抛 USER_NOT_FOUND）（P0）。
     */
    @Test
    @DisplayName("UT-039: 发送找回验证码成功与账号不存在拒绝")
    void forgotPasswordSendCode_shouldSendOrThrow() {
        // 账号存在：发送 SMS 验证码
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildUser());
        when(verificationCodeManager.generateCode(eq("13800000001"), eq("SMS"), eq("RESET_PWD")))
                .thenReturn("654321");

        passwordService.forgotPasswordSendCode("13800000001", "SMS");

        verify(verificationCodeService, times(1))
                .sendSmsCode("13800000001", "654321", "RESET_PWD");

        // 账号不存在：抛 USER_NOT_FOUND
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);
        BusinessException ex = assertThrows(BusinessException.class,
                () -> passwordService.forgotPasswordSendCode("13900000000", "SMS"));
        assertEquals("用户不存在", ex.getMessage());
    }

    /**
     * UT-039：忘记密码重置成功并全端下线 / 验证码无效被拒（P0）。
     */
    @Test
    @DisplayName("UT-039: 重置密码成功并全端下线，验证码无效抛 SMS_CODE_INVALID")
    void forgotPasswordReset_shouldResetOrReject() {
        // 验证码有效：重置成功并全端下线
        when(verificationCodeManager.verifyCode(eq("13800000001"), eq("654321"), eq("RESET_PWD")))
                .thenReturn(true);
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(buildUser());
        when(passwordEncoder.encode("new_pass")).thenReturn("$2a$10$resetPasswordMock");

        passwordService.forgotPasswordReset("13800000001", "SMS", "654321", "new_pass");

        verify(userMapper, times(1)).updateById(any(UserEntity.class));
        verify(loginSessionService, times(1)).removeAllSessions(1L);

        // 验证码无效：抛 SMS_CODE_INVALID
        when(verificationCodeManager.verifyCode(eq("13800000001"), eq("999999"), eq("RESET_PWD")))
                .thenReturn(false);
        BusinessException ex = assertThrows(BusinessException.class,
                () -> passwordService.forgotPasswordReset("13800000001", "SMS", "999999", "new_pass"));
        assertEquals("短信验证码无效", ex.getMessage());
    }

    /**
     * UT-040：换绑手机成功（旧手机短信场景）（P0）。
     */
    @Test
    @DisplayName("UT-040: 旧手机短信验证码场景换绑成功")
    void changePhone_shouldUpdatePhone_whenOldPhoneCodeValid() {
        when(userMapper.selectById(1L)).thenReturn(buildUser());
        when(verificationCodeManager.verifyCode(eq("13800000001"), eq("111111"), eq("CHANGE_PHONE")))
                .thenReturn(true);
        when(verificationCodeManager.verifyCode(eq("13900000009"), eq("222222"), eq("CHANGE_PHONE")))
                .thenReturn(true);
        // 新手机号未被其他账号绑定
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);

        PhoneChangeRequest request = new PhoneChangeRequest();
        request.setNewPhone("13900000009");
        request.setOldPhoneCode("111111");
        request.setNewPhoneCode("222222");

        passwordService.changePhone(1L, request);

        verify(userMapper, times(1)).updateById(argThat(user ->
                "13900000009".equals(user.getPhone())));
    }

    /**
     * UT-042：邮箱验证码场景换绑成功（P1）。
     */
    @Test
    @DisplayName("UT-042: 邮箱验证码场景换绑成功")
    void changePhone_shouldUpdatePhone_whenEmailCodeValid() {
        when(userMapper.selectById(1L)).thenReturn(buildUser());
        when(verificationCodeManager.verifyCode(eq("tester@example.com"), eq("333333"), eq("CHANGE_PHONE")))
                .thenReturn(true);
        when(verificationCodeManager.verifyCode(eq("13900000008"), eq("444444"), eq("CHANGE_PHONE")))
                .thenReturn(true);
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(null);

        PhoneChangeRequest request = new PhoneChangeRequest();
        request.setNewPhone("13900000008");
        request.setEmailCode("333333");
        request.setNewPhoneCode("444444");

        passwordService.changePhone(1L, request);

        verify(userMapper, times(1)).updateById(argThat(user ->
                "13900000008".equals(user.getPhone())));
    }

    /**
     * UT-040：新手机号被其他账号占用抛 PHONE_ALREADY_BOUND（P0）。
     */
    @Test
    @DisplayName("UT-040: 新手机号已被其他账号绑定抛 PHONE_ALREADY_BOUND")
    void changePhone_shouldThrow_whenNewPhoneAlreadyBound() {
        when(userMapper.selectById(1L)).thenReturn(buildUser());
        when(verificationCodeManager.verifyCode(eq("13800000001"), eq("111111"), eq("CHANGE_PHONE")))
                .thenReturn(true);
        when(verificationCodeManager.verifyCode(eq("13900000009"), eq("222222"), eq("CHANGE_PHONE")))
                .thenReturn(true);
        UserEntity other = new UserEntity();
        other.setId(99L);
        other.setPhone("13900000009");
        when(userMapper.selectOne(any(LambdaQueryWrapper.class))).thenReturn(other);

        PhoneChangeRequest request = new PhoneChangeRequest();
        request.setNewPhone("13900000009");
        request.setOldPhoneCode("111111");
        request.setNewPhoneCode("222222");

        BusinessException ex = assertThrows(BusinessException.class,
                () -> passwordService.changePhone(1L, request));
        assertEquals(409, ex.getCode());
        verify(userMapper, never()).updateById(any(UserEntity.class));
    }

    /**
     * UT-040：缺少旧手机验证码与邮箱验证码被拒（P0）。
     */
    @Test
    @DisplayName("UT-040: 缺少验证码时被拒")
    void changePhone_shouldThrow_whenNoCodeProvided() {
        when(userMapper.selectById(1L)).thenReturn(buildUser());

        PhoneChangeRequest request = new PhoneChangeRequest();
        request.setNewPhone("13900000009");
        request.setNewPhoneCode("222222");

        BusinessException ex = assertThrows(BusinessException.class,
                () -> passwordService.changePhone(1L, request));
        assertEquals("请提供旧手机号验证码或邮箱验证码", ex.getMessage());
    }

    /**
     * UT-041：修改密码 8 位/64 位边界可通过（P1）。
     *
     * <p>说明：7 位/65 位的 400 拒绝由 Controller 层 @Valid 校验
     * 与接口测试 TC-024/TC-026 覆盖，服务层仅校验非空。</p>
     */
    @Test
    @DisplayName("UT-041: 新密码 8 位与 64 位边界可通过修改")
    void changePassword_shouldPass_whenPasswordAtBoundary() {
        // 每次调用返回新实例，避免首次 updateById 修改密码后影响后续匹配
        when(userMapper.selectById(1L)).thenAnswer(invocation -> buildUser());
        when(passwordEncoder.matches("old_pass", "$2a$10$oldPasswordMock")).thenReturn(true);
        when(passwordEncoder.encode(anyString())).thenReturn("$2a$10$encryptedAny");

        passwordService.changePassword(1L, "old_pass", "abcdefgh");
        passwordService.changePassword(1L, "old_pass", "a".repeat(64));

        verify(userMapper, times(2)).updateById(any(UserEntity.class));
    }
}
