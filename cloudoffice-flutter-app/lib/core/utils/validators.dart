import '../../shared/constants/app_constants.dart';

/// 表单校验工具函数
///
/// 所有校验函数返回 String?，null 表示通过，非 null 为错误提示信息。
class Validators {
  Validators._();

  /// 校验用户名（4-64 字符，仅允许字母、数字、下划线）
  static String? validateLoginName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入用户名';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.loginNameMinLength) {
      return '用户名不能少于${AppConstants.loginNameMinLength}个字符';
    }
    if (trimmed.length > AppConstants.loginNameMaxLength) {
      return '用户名不能超过${AppConstants.loginNameMaxLength}个字符';
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(trimmed)) {
      return '用户名仅允许字母、数字和下划线';
    }
    return null;
  }

  /// 校验密码（8-64 字符）
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < AppConstants.passwordMinLength) {
      return '密码不能少于${AppConstants.passwordMinLength}位';
    }
    if (value.length > AppConstants.passwordMaxLength) {
      return '密码不能超过${AppConstants.passwordMaxLength}位';
    }
    return null;
  }

  /// 校验确认密码（两次输入一致性）
  static String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return '请再次输入密码';
    }
    if (confirm != password) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  /// 校验手机号（11 位，1[3-9] 开头）
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入手机号';
    }
    final regex = RegExp(r'^1[3-9]\d{9}$');
    if (!regex.hasMatch(value.trim())) {
      return '请输入正确的手机号格式';
    }
    return null;
  }

  /// 校验验证码（6 位数字）
  static String? validateVerificationCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入验证码';
    }
    final regex = RegExp(r'^\d{6}$');
    if (!regex.hasMatch(value.trim())) {
      return '验证码为6位数字';
    }
    return null;
  }

  /// 校验真实姓名（2-50 字符）
  static String? validateUserName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入真实姓名';
    }
    if (value.trim().length < AppConstants.userNameMinLength) {
      return '真实姓名不能少于${AppConstants.userNameMinLength}个字';
    }
    if (value.trim().length > AppConstants.userNameMaxLength) {
      return '真实姓名不能超过${AppConstants.userNameMaxLength}个字';
    }
    return null;
  }

  /// 校验邮箱（简单格式校验）
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // 邮箱非必填
    }
    final regex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
    if (!regex.hasMatch(value.trim())) {
      return '请输入正确的邮箱格式';
    }
    return null;
  }

  /// 判断密码强度等级
  ///
  /// 返回 0（弱）、1（中）、2（强）
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    bool hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    bool hasDigit = RegExp(r'\d').hasMatch(password);
    bool hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    int length = password.length;

    if (hasLetter && hasDigit && hasSpecial && length >= 12) {
      return 2; // 强
    }
    if ((hasLetter && hasDigit) || (hasLetter && hasSpecial) || (hasDigit && hasSpecial)) {
      if (length >= 10) {
        return 1; // 中
      }
    }
    return 0; // 弱
  }

  /// 获取密码强度文字描述
  static String getPasswordStrengthLabel(int level) {
    switch (level) {
      case 0:
        return '弱';
      case 1:
        return '中';
      case 2:
        return '强';
      default:
        return '';
    }
  }
}
