/// 密码找回请求 DTO
class PasswordForgotRequest {
  /// 验证方式（SMS / EMAIL）
  final String? mode;

  /// 目标（手机号或邮箱）
  final String? target;

  /// 验证码
  final String? code;

  /// 新密码
  final String? newPassword;

  const PasswordForgotRequest({
    this.mode,
    this.target,
    this.code,
    this.newPassword,
  });

  factory PasswordForgotRequest.fromJson(Map<String, dynamic> json) {
    return PasswordForgotRequest(
      mode: json['mode'] as String?,
      target: json['target'] as String?,
      code: json['code'] as String?,
      newPassword: json['newPassword'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (mode != null) 'mode': mode,
      if (target != null) 'target': target,
      if (code != null) 'code': code,
      if (newPassword != null) 'newPassword': newPassword,
    };
  }
}
