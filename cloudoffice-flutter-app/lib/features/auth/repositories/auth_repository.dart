import 'package:dio/dio.dart';

import '../../../core/http/api_client.dart';
import '../../../core/http/api_result.dart';
import '../models/login_request.dart';
import '../models/password_forgot_request.dart';
import '../models/register_request.dart';
import '../models/register_result.dart';
import '../models/send_verification_code_request.dart';
import '../models/token_pair.dart';

/// Auth API 数据仓库
///
/// 封装认证相关的后端 API 调用逻辑，提供 6 个认证方法。
/// 所有方法返回 `Future<ApiResult<T>>`，统一错误处理。
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient.instance;

  /// 用户登录
  ///
  /// 调用 POST /api/v1/auth/login
  Future<ApiResult<TokenPair>> login(LoginRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/login',
        data: request.toJson(),
      );
      return ApiResult<TokenPair>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: TokenPair.fromJson,
      );
    } on DioException catch (e) {
      return _handleDioException<TokenPair>(e);
    }
  }

  /// 用户注册
  ///
  /// 调用 POST /api/v1/auth/register
  Future<ApiResult<RegisterResult>> register(RegisterRequest request) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/register',
        data: request.toJson(),
      );
      return ApiResult<RegisterResult>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: RegisterResult.fromJson,
      );
    } on DioException catch (e) {
      return _handleDioException<RegisterResult>(e);
    }
  }

  /// 刷新 Token
  ///
  /// 调用 POST /api/v1/auth/refresh
  Future<ApiResult<TokenPair>> refreshToken(String refreshToken) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      return ApiResult<TokenPair>.fromJson(
        response.data as Map<String, dynamic>,
        fromJsonT: TokenPair.fromJson,
      );
    } on DioException catch (e) {
      return _handleDioException<TokenPair>(e);
    }
  }

  /// 退出登录
  ///
  /// 调用 POST /api/v1/auth/logout
  Future<ApiResult<void>> logout() async {
    try {
      final response = await _apiClient.post('/api/v1/auth/logout');
      final result = ApiResult<void>.fromJson(
        response.data as Map<String, dynamic>,
      );
      return result;
    } on DioException catch (e) {
      return _handleDioException<void>(e);
    }
  }

  /// 发送验证码
  ///
  /// 调用 POST /api/v1/auth/verification-code/send
  Future<ApiResult<void>> sendVerificationCode(
    String target,
    String purpose, [
    String? mode,
  ]) async {
    try {
      final request = SendVerificationCodeRequest(
        target: target,
        purpose: purpose,
        mode: mode,
      );
      final response = await _apiClient.post(
        '/api/v1/auth/verification-code/send',
        data: request.toJson(),
      );
      final result = ApiResult<void>.fromJson(
        response.data as Map<String, dynamic>,
      );
      return result;
    } on DioException catch (e) {
      return _handleDioException<void>(e);
    }
  }

  /// 找回密码重置
  ///
  /// 调用 POST /api/v1/auth/password/forgot/reset
  Future<ApiResult<void>> forgotPasswordReset(
    String mode,
    String target,
    String code,
    String newPassword,
  ) async {
    try {
      final request = PasswordForgotRequest(
        mode: mode,
        target: target,
        code: code,
        newPassword: newPassword,
      );
      final response = await _apiClient.post(
        '/api/v1/auth/password/forgot/reset',
        data: request.toJson(),
      );
      final result = ApiResult<void>.fromJson(
        response.data as Map<String, dynamic>,
      );
      return result;
    } on DioException catch (e) {
      return _handleDioException<void>(e);
    }
  }

  /// 统一处理 DioException 为 ApiResult
  ApiResult<T> _handleDioException<T>(DioException e) {
    String message;
    int? code;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = '网络连接超时，请检查网络后重试';
        code = -1;
        break;
      case DioExceptionType.connectionError:
        message = '无法连接到服务器，请检查网络连接';
        code = -1;
        break;
      case DioExceptionType.cancel:
        message = '请求已取消';
        code = -2;
        break;
      case DioExceptionType.badResponse:
        // 尝试从响应体中提取后端错误信息
        if (e.response?.data != null) {
          final responseData = e.response!.data;
          if (responseData is Map<String, dynamic>) {
            message = responseData['message'] as String? ?? '请求失败';
            code = responseData['code'] as int? ?? e.response?.statusCode;
          } else {
            message = '请求失败 (${e.response?.statusCode})';
            code = e.response?.statusCode;
          }
        } else {
          message = '请求失败 (${e.response?.statusCode})';
          code = e.response?.statusCode;
        }
        break;
      default:
        message = '网络异常，请稍后重试';
        code = -1;
    }

    return ApiResult<T>.error(message, code: code);
  }
}
