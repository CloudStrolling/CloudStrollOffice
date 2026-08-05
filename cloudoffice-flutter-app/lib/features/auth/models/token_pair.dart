/// Token 对数据模型
///
/// 对应后端返回的 TokenPairDTO，包含访问令牌和刷新令牌。
class TokenPair {
  /// 访问令牌（Access Token）
  final String? accessToken;

  /// 刷新令牌（Refresh Token）
  final String? refreshToken;

  /// 访问令牌过期时间（秒）
  final int? accessTokenExpireIn;

  /// 刷新令牌过期时间（秒）
  final int? refreshTokenExpireIn;

  /// 令牌类型（如 Bearer）
  final String? tokenType;

  const TokenPair({
    this.accessToken,
    this.refreshToken,
    this.accessTokenExpireIn,
    this.refreshTokenExpireIn,
    this.tokenType,
  });

  /// 从 JSON 创建 TokenPair
  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      accessTokenExpireIn: json['accessTokenExpireIn'] as int?,
      refreshTokenExpireIn: json['refreshTokenExpireIn'] as int?,
      tokenType: json['tokenType'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'accessTokenExpireIn': accessTokenExpireIn,
      'refreshTokenExpireIn': refreshTokenExpireIn,
      'tokenType': tokenType,
    };
  }

  @override
  String toString() =>
      'TokenPair(accessToken: ${accessToken?.substring(0, 10)}..., tokenType: $tokenType)';
}
