/// 应用常量定义
class AppConstants {
  AppConstants._();

  /// 密码最小长度
  static const int passwordMinLength = 8;

  /// 密码最大长度
  static const int passwordMaxLength = 64;

  /// 用户名最小长度
  static const int loginNameMinLength = 4;

  /// 用户名最大长度
  static const int loginNameMaxLength = 64;

  /// 真实姓名最小长度
  static const int userNameMinLength = 2;

  /// 真实姓名最大长度
  static const int userNameMaxLength = 50;

  /// 验证码倒计时秒数
  static const int countdownSeconds = 60;

  /// 重置成功跳转倒计时秒数
  static const int successCountdownSeconds = 3;

  /// 验证码长度
  static const int codeLength = 6;

  /// 手机号长度
  static const int phoneLength = 11;
}
