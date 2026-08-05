import 'dart:async';

import 'package:dio/dio.dart';

import '../../config/api_config.dart';
import '../../features/auth/models/token_pair.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';
import 'api_result.dart';

/// API 请求/响应拦截器
///
/// 请求拦截：
/// - 白名单路径不注入 Token
/// - 非白名单路径自动注入 Authorization: Bearer {token}
///
/// 响应拦截：
/// - 401 自动触发 Token 刷新（含并发锁机制）
/// - 刷新失败时清除 Token 并通知应用退出登录
class ApiInterceptor extends Interceptor {
  /// Token 刷新中标志
  bool _isRefreshing = false;

  /// 等待队列：在 Token 刷新期间等待的请求
  final List<_PendingRequest> _pendingRequests = [];

  /// 认证相关白名单路径（不需要 Token）
  static const List<String> _whiteListPaths = [
    '/api/v1/auth/login',
    '/api/v1/auth/register',
    '/api/v1/auth/refresh',
    '/api/v1/auth/verification-code/send',
    '/api/v1/auth/password/forgot/send-code',
    '/api/v1/auth/password/forgot/reset',
    '/api/v1/auth/health',
  ];

  /// 判断路径是否为白名单路径
  bool _isWhiteListPath(String path) {
    return _whiteListPaths.any((whitePath) => path.startsWith(whitePath));
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 白名单路径不注入 Token
    if (_isWhiteListPath(options.path)) {
      return handler.next(options);
    }

    // 从安全存储获取 Access Token
    final accessToken = await SecureStorage.instance.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    // 如果响应成功但业务 code 非 200，可以在这里统一处理
    return handler.next(response);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 只处理 401 未授权错误
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // 避免对刷新接口本身的 401 进行无限重试
    if (_isWhiteListPath(err.requestOptions.path)) {
      return handler.next(err);
    }

    // 使用并发锁机制，防止多个请求同时刷新 Token
    if (_isRefreshing) {
      // 已有刷新操作进行中，将当前请求加入等待队列
      final completer = _PendingRequest(err.requestOptions);
      _pendingRequests.add(completer);
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (e) {
        return handler.next(e as DioException);
      }
    }

    // 开始刷新 Token
    _isRefreshing = true;
    try {
      final newToken = await _refreshToken();
      if (newToken != null) {
        // 刷新成功，重放原始请求
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await ApiClient.instance.dio.fetch(err.requestOptions);

        // 唤醒等待队列中的请求
        _processPendingRequests(newToken);
        return handler.resolve(response);
      } else {
        // 刷新失败，清除 Token
        await SecureStorage.instance.clearTokens();
        _isRefreshing = false;
        _failPendingRequests(err);
        return handler.next(err);
      }
    } catch (e) {
      await SecureStorage.instance.clearTokens();
      _isRefreshing = false;
      _failPendingRequests(err);
      return handler.next(err);
    }
  }

  /// 刷新 Token
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await SecureStorage.instance.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: ApiConfig.connectTimeout),
          receiveTimeout: const Duration(seconds: ApiConfig.receiveTimeout),
        ),
      ).post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final result = ApiResult<TokenPair>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: TokenPair.fromJson,
      );

      if (result.isSuccess() && result.data != null) {
        // 保存新的 Token 对
        await SecureStorage.instance.saveTokenPair(result.data!);
        return result.data!.accessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 处理等待队列中的请求（使用新 Token 重放）
  void _processPendingRequests(String newToken) {
    final pendingList = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    _isRefreshing = false;

    for (final pending in pendingList) {
      pending.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      ApiClient.instance.dio.fetch(pending.requestOptions).then(
        (response) => pending.completer.complete(response),
        onError: (error) => pending.completer.completeError(error),
      );
    }
  }

  /// 失败处理：让所有等待队列中的请求失败
  void _failPendingRequests(DioException err) {
    final pendingList = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    for (final pending in pendingList) {
      pending.completer.completeError(err);
    }
  }
}

/// 等待中的请求包装类
class _PendingRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer = Completer<Response>();

  _PendingRequest(this.requestOptions);

  Future<Response> get future => completer.future;
}
