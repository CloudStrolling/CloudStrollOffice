import 'token_pair.dart';

/// 注册结果 DTO
///
/// 对应后端 RegisterResult，注册成功后返回的用户信息和 Token。
class RegisterResult {
  /// 用户 ID
  final int? userId;

  /// 登录名
  final String? loginName;

  /// 真实姓名
  final String? userName;

  /// 账号是否已补全信息
  final bool? accountSettled;

  /// Token 对
  final TokenPair? tokenPair;

  const RegisterResult({
    this.userId,
    this.loginName,
    this.userName,
    this.accountSettled,
    this.tokenPair,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    return RegisterResult(
      userId: json['userId'] as int?,
      loginName: json['loginName'] as String?,
      userName: json['userName'] as String?,
      accountSettled: json['accountSettled'] as bool?,
      tokenPair: json['tokenPair'] != null
          ? TokenPair.fromJson(json['tokenPair'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      if (loginName != null) 'loginName': loginName,
      if (userName != null) 'userName': userName,
      if (accountSettled != null) 'accountSettled': accountSettled,
      if (tokenPair != null) 'tokenPair': tokenPair!.toJson(),
    };
  }
}
