import 'dart:io' show Platform;

/// API 配置类
///
/// 集中管理后端 API 的基础地址、超时时间和客户端类型等配置。
class ApiConfig {
  ApiConfig._();

  /// 后端 API 基础地址（API 网关地址）
  static const String baseUrl = 'http://localhost:9000';

  /// 连接超时时间（秒）
  static const int connectTimeout = 15;

  /// 读取超时时间（秒）
  static const int receiveTimeout = 30;

  /// 获取当前平台的客户端类型标识
  ///
  /// - Web 平台返回 `H5`
  /// - Windows 平台返回 `WINDOWS`
  /// - 其他平台默认返回 `H5`
  static String get clientType {
    try {
      if (Platform.isWindows) {
        return 'WINDOWS';
      }
    } catch (_) {
      // Web 平台不支持 dart:io，捕获异常返回 H5
    }
    return 'H5';
  }

  /// 默认租户编码
  static const String defaultTenantCode = 'default';
}
