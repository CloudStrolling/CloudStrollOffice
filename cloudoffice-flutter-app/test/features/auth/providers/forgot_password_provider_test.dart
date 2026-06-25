import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/core/http/api_result.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/forgot_password_provider.dart';

import '../../../test_helpers.dart';

void main() {
  late StubAuthRepository stubAuthRepository;
  late ForgotPasswordProvider provider;

  setUp(() {
    stubAuthRepository = StubAuthRepository();
    provider = ForgotPasswordProvider(authRepository: stubAuthRepository);
  });

  group('初始状态', () {
    test('初始步骤为 0', () {
      expect(provider.currentStep, 0);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.codeSent, false);
      expect(provider.identityVerified, false);
      expect(provider.resetSuccessful, false);
    });
  });

  group('sendVerificationCode', () {
    test('发送验证码成功时 codeSent 为 true', () async {
      provider.setTarget('13800138000');
      stubAuthRepository.onSendCode =
          (target, purpose, mode) async => ApiResult<void>.success(null);

      final result = await provider.sendVerificationCode();

      expect(result, true);
      expect(provider.codeSent, true);
      expect(provider.isLoading, false);
      expect(stubAuthRepository.invocations.length, 1);
    });

    test('发送验证码失败时设置错误信息', () async {
      provider.setTarget('13800138000');
      stubAuthRepository.onSendCode =
          (target, purpose, mode) async =>
              ApiResult<void>.error('发送太频繁', code: 429);

      final result = await provider.sendVerificationCode();

      expect(result, false);
      expect(provider.codeSent, false);
      expect(provider.errorMessage, '发送太频繁');
    });

    test('目标为空时返回 false 并提示输入', () async {
      final result = await provider.sendVerificationCode();

      expect(result, false);
      expect(provider.errorMessage, '请输入手机号或邮箱');
      expect(stubAuthRepository.invocations.length, 0);
    });
  });

  group('verifyIdentity', () {
    test('验证码有效时 identityVerified 为 true，步骤进入 1', () {
      provider.setVerificationCode('123456');

      final result = provider.verifyIdentity();

      expect(result, true);
      expect(provider.identityVerified, true);
      expect(provider.currentStep, 1);
    });

    test('验证码为空或长度不足时返回 false，步骤保持 0', () {
      final result = provider.verifyIdentity();

      expect(result, false);
      expect(provider.identityVerified, false);
      expect(provider.currentStep, 0);
      expect(provider.errorMessage, '请输入完整的验证码');
    });

    test('验证码长度不足 6 位时返回 false', () {
      provider.setVerificationCode('12345');

      final result = provider.verifyIdentity();

      expect(result, false);
      expect(provider.identityVerified, false);
      expect(provider.currentStep, 0);
    });
  });

  group('resetPassword', () {
    test('密码重置成功时 resetSuccessful 为 true', () async {
      provider.setTarget('13800138000');
      provider.setVerificationCode('123456');
      provider.setNewPassword('NewP@ss123');
      provider.setConfirmPassword('NewP@ss123');

      stubAuthRepository.onForgotPassword =
          (mode, target, code, newPassword) async =>
              ApiResult<void>.success(null);

      final result = await provider.resetPassword();

      expect(result, true);
      expect(provider.resetSuccessful, true);
      expect(provider.isLoading, false);
      expect(stubAuthRepository.invocations.length, 1);
    });

    test('新密码为空时返回 false', () async {
      final result = await provider.resetPassword();

      expect(result, false);
      expect(provider.errorMessage, '请输入新密码');
      expect(stubAuthRepository.invocations.length, 0);
    });

    test('两次密码不一致时返回 false', () async {
      provider.setNewPassword('P@ssword1');
      provider.setConfirmPassword('P@ssword2');

      final result = await provider.resetPassword();

      expect(result, false);
      expect(provider.errorMessage, '两次输入的密码不一致');
      expect(stubAuthRepository.invocations.length, 0);
    });

    test('密码重置失败时设置错误信息', () async {
      provider.setTarget('13800138000');
      provider.setVerificationCode('123456');
      provider.setNewPassword('NewP@ss123');
      provider.setConfirmPassword('NewP@ss123');

      stubAuthRepository.onForgotPassword =
          (mode, target, code, newPassword) async =>
              ApiResult<void>.error('验证码已过期', code: 400);

      final result = await provider.resetPassword();

      expect(result, false);
      expect(provider.resetSuccessful, false);
      expect(provider.errorMessage, '验证码已过期');
    });
  });

  group('倒计时', () {
    test('startCountdown 开始倒计时并递减', () async {
      provider.startCountdown();

      expect(provider.countdownSeconds, 60);

      await Future.delayed(const Duration(milliseconds: 1100));

      expect(provider.countdownSeconds, 59);
    });

    test('dispose 取消所有定时器', () async {
      provider.startCountdown();
      provider.startSuccessCountdown();

      provider.dispose();

      await Future.delayed(const Duration(milliseconds: 1100));

      expect(provider.countdownSeconds, greaterThanOrEqualTo(0));
    });
  });

  group('reset', () {
    test('reset 将所有状态恢复初始值', () {
      provider.setTarget('13800138000');
      provider.setVerificationCode('123456');
      provider.setNewPassword('P@ssword');
      provider.setConfirmPassword('P@ssword');
      provider.codeSent = true;
      provider.identityVerified = true;
      provider.currentStep = 1;

      provider.reset();

      expect(provider.currentStep, 0);
      expect(provider.target, '');
      expect(provider.verificationCode, '');
      expect(provider.newPassword, '');
      expect(provider.confirmPassword, '');
      expect(provider.codeSent, false);
      expect(provider.identityVerified, false);
      expect(provider.resetSuccessful, false);
      expect(provider.errorMessage, isNull);
    });
  });
}
