import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/constants/app_constants.dart';
import '../repositories/auth_repository.dart';

/// 找回密码状态管理
///
/// 管理两步找回密码流程：
/// Step 0: 身份验证（输入手机号/邮箱 + 验证码）
/// Step 1: 重置密码（输入新密码）
class ForgotPasswordProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  ForgotPasswordProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  // 步骤状态
  int currentStep = 0;

  // 加载状态
  bool isLoading = false;

  // 错误信息
  String? errorMessage;

  // 第一步：身份验证
  String verificationMode = 'SMS'; // SMS / EMAIL
  String target = '';
  String verificationCode = '';
  int countdownSeconds = 0;
  bool codeSent = false;
  bool identityVerified = false;

  // 第二步：重置密码
  String newPassword = '';
  String confirmPassword = '';
  int successCountdown = 3;
  bool resetSuccessful = false;

  // 倒计时定时器
  Timer? _countdownTimer;
  Timer? _successTimer;

  /// 设置加载状态
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  /// 清除错误
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  /// 设置验证方式
  void setVerificationMode(String mode) {
    verificationMode = mode;
    notifyListeners();
  }

  /// 设置目标（手机号/邮箱）
  void setTarget(String value) {
    target = value;
    notifyListeners();
  }

  /// 设置验证码
  void setVerificationCode(String value) {
    verificationCode = value;
    notifyListeners();
  }

  /// 设置新密码
  void setNewPassword(String value) {
    newPassword = value;
    notifyListeners();
  }

  /// 设置确认密码
  void setConfirmPassword(String value) {
    confirmPassword = value;
    notifyListeners();
  }

  /// 发送验证码
  Future<bool> sendVerificationCode() async {
    if (target.isEmpty) {
      _setError('请输入手机号或邮箱');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final result = await _authRepository.sendVerificationCode(
        target,
        'RESET_PASSWORD',
        verificationMode,
      );

      if (result.isSuccess()) {
        codeSent = true;
        startCountdown();
        _setLoading(false);
        return true;
      } else {
        _setError(result.message ?? '发送验证码失败');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('发送验证码异常，请稍后重试');
      _setLoading(false);
      return false;
    }
  }

  /// 验证身份（第一步验证）
  bool verifyIdentity() {
    if (verificationCode.isEmpty || verificationCode.length < 6) {
      _setError('请输入完整的验证码');
      return false;
    }
    identityVerified = true;
    currentStep = 1;
    notifyListeners();
    return true;
  }

  /// 重置密码
  Future<bool> resetPassword() async {
    if (newPassword.isEmpty) {
      _setError('请输入新密码');
      return false;
    }
    if (newPassword.length < AppConstants.passwordMinLength) {
      _setError('密码长度不能少于${AppConstants.passwordMinLength}位');
      return false;
    }
    if (newPassword != confirmPassword) {
      _setError('两次输入的密码不一致');
      return false;
    }

    _setLoading(true);
    clearError();

    try {
      final result = await _authRepository.forgotPasswordReset(
        verificationMode,
        target,
        verificationCode,
        newPassword,
      );

      if (result.isSuccess()) {
        resetSuccessful = true;
        startSuccessCountdown();
        _setLoading(false);
        return true;
      } else {
        _setError(result.message ?? '密码重置失败');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('密码重置异常，请稍后重试');
      _setLoading(false);
      return false;
    }
  }

  /// 开始验证码倒计时
  void startCountdown() {
    countdownSeconds = AppConstants.countdownSeconds;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdownSeconds--;
      notifyListeners();
      if (countdownSeconds <= 0) {
        timer.cancel();
        _countdownTimer = null;
      }
    });
  }

  /// 开始重置成功倒计时
  void startSuccessCountdown() {
    successCountdown = AppConstants.successCountdownSeconds;
    notifyListeners();

    _successTimer?.cancel();
    _successTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      successCountdown--;
      notifyListeners();
      if (successCountdown <= 0) {
        timer.cancel();
        _successTimer = null;
      }
    });
  }

  /// 重置状态（用于重新开始流程）
  void reset() {
    currentStep = 0;
    isLoading = false;
    errorMessage = null;
    target = '';
    verificationCode = '';
    countdownSeconds = 0;
    codeSent = false;
    identityVerified = false;
    newPassword = '';
    confirmPassword = '';
    successCountdown = 3;
    resetSuccessful = false;
    _countdownTimer?.cancel();
    _successTimer?.cancel();
    _countdownTimer = null;
    _successTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }
}
