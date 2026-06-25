/// 用户信息模型
class UserInfo {
  /// 用户 ID
  final int? userId;

  /// 登录名
  final String? loginName;

  /// 真实姓名
  final String? userName;

  /// 手机号
  final String? phone;

  /// 邮箱
  final String? email;

  /// 头像 URL
  final String? avatar;

  const UserInfo({
    this.userId,
    this.loginName,
    this.userName,
    this.phone,
    this.email,
    this.avatar,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['userId'] as int?,
      loginName: json['loginName'] as String?,
      userName: json['userName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      if (loginName != null) 'loginName': loginName,
      if (userName != null) 'userName': userName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (avatar != null) 'avatar': avatar,
    };
  }

  @override
  String toString() => 'UserInfo(userId: $userId, loginName: $loginName)';
}
