import 'package:flutter_secure_storage_x/flutter_secure_storage_x.dart';

import '../../features/auth/models/token_pair.dart';

/// 安全存储封装类
///
/// 基于 flutter_secure_storage 实现 Token 等敏感数据的安全持久化。
/// Windows 平台使用 DPAPI/Credential Manager，Web 平台使用加密 localStorage。
class SecureStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyTokenType = 'token_type';

  static SecureStorage? _instance;
  late final FlutterSecureStorage _storage;

  SecureStorage._internal() {
    _storage = const FlutterSecureStorage();
  }

  /// 获取单例实例
  static SecureStorage get instance {
    _instance ??= SecureStorage._internal();
    return _instance!;
  }

  /// 保存 Token 对
  Future<void> saveTokenPair(TokenPair pair) async {
    if (pair.accessToken != null) {
      await _storage.write(key: _keyAccessToken, value: pair.accessToken);
    }
    if (pair.refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: pair.refreshToken);
    }
    if (pair.tokenType != null) {
      await _storage.write(key: _keyTokenType, value: pair.tokenType);
    }
  }

  /// 获取 Access Token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// 获取 Refresh Token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// 获取 Token 类型
  Future<String?> getTokenType() async {
    return await _storage.read(key: _keyTokenType);
  }

  /// 获取完整的 TokenPair 对象
  Future<TokenPair?> getTokenPair() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    final tokenType = await getTokenType();
    if (accessToken == null && refreshToken == null) {
      return null;
    }
    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
    );
  }

  /// 清除所有 Token
  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTokenType);
  }

  /// 检查是否存在 Token
  Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
