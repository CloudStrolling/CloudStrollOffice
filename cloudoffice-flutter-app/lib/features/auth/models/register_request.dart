/// 注册请求 DTO
///
/// 对应后端 RegisterRequest，支持多种注册模式。
class RegisterRequest {
  /// 登录名（用户名注册模式必填）
  final String? loginName;

  /// 密码（密码模式必填）
  final String? password;

  /// 真实姓名
  final String? userName;

  /// 手机号（手机注册模式必填）
  final String? phone;

  /// 邮箱
  final String? email;

  /// 注册模式（USERNAME / PHONE / OAUTH）
  final String? registerMode;

  /// 租户编码
  final String? tenantCode;

  const RegisterRequest({
    this.loginName,
    this.password,
    this.userName,
    this.phone,
    this.email,
    this.registerMode,
    this.tenantCode,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      loginName: json['loginName'] as String?,
      password: json['password'] as String?,
      userName: json['userName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      registerMode: json['registerMode'] as String?,
      tenantCode: json['tenantCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (loginName != null) 'loginName': loginName,
      if (password != null) 'password': password,
      if (userName != null) 'userName': userName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (registerMode != null) 'registerMode': registerMode,
      if (tenantCode != null) 'tenantCode': tenantCode,
    };
  }

  @override
  String toString() => 'RegisterRequest(registerMode: $registerMode)';
}
