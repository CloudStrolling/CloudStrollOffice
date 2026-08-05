/// 登录请求 DTO
///
/// 对应后端 LoginRequest，支持多种登录模式。
class LoginRequest {
  /// 登录名（用户名模式必填）
  final String? loginName;

  /// 密码（密码模式必填）
  final String? password;

  /// 手机号（手机验证码模式必填）
  final String? phone;

  /// 短信验证码（手机验证码模式必填）
  final String? smsCode;

  /// 租户编码
  final String? tenantCode;

  /// 客户端类型（H5 / WINDOWS）
  final String? clientType;

  /// 登录模式（USERNAME_PASSWORD / SMS / PHONE_PASSWORD / OAUTH）
  final String? loginMode;

  const LoginRequest({
    this.loginName,
    this.password,
    this.phone,
    this.smsCode,
    this.tenantCode,
    this.clientType,
    this.loginMode,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      loginName: json['loginName'] as String?,
      password: json['password'] as String?,
      phone: json['phone'] as String?,
      smsCode: json['smsCode'] as String?,
      tenantCode: json['tenantCode'] as String?,
      clientType: json['clientType'] as String?,
      loginMode: json['loginMode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (loginName != null) 'loginName': loginName,
      if (password != null) 'password': password,
      if (phone != null) 'phone': phone,
      if (smsCode != null) 'smsCode': smsCode,
      if (tenantCode != null) 'tenantCode': tenantCode,
      if (clientType != null) 'clientType': clientType,
      if (loginMode != null) 'loginMode': loginMode,
    };
  }

  @override
  String toString() => 'LoginRequest(loginMode: $loginMode, clientType: $clientType)';
}
