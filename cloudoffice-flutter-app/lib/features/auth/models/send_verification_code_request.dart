/// 发送验证码请求 DTO
class SendVerificationCodeRequest {
  /// 目标（手机号或邮箱）
  final String? target;

  /// 用途（REGISTER / RESET_PASSWORD / CHANGE_PHONE）
  final String? purpose;

  /// 验证方式（SMS / EMAIL）
  final String? mode;

  const SendVerificationCodeRequest({
    this.target,
    this.purpose,
    this.mode,
  });

  factory SendVerificationCodeRequest.fromJson(Map<String, dynamic> json) {
    return SendVerificationCodeRequest(
      target: json['target'] as String?,
      purpose: json['purpose'] as String?,
      mode: json['mode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (target != null) 'target': target,
      if (purpose != null) 'purpose': purpose,
      if (mode != null) 'mode': mode,
    };
  }
}
