import 'package:flutter/foundation.dart';

import '../../../config/api_config.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/token_pair.dart';
import '../models/user_info.dart';
import '../repositories/auth_repository.dart';

/// 认证状态管理
///
/// 管理登录、注册、登出、Token 管理等认证相关状态。
/// 继承 ChangeNotifier 以支持 Provider 状态监听。
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  /// 是否正在加载
  bool isLoading = false;

  /// 错误信息
  String? errorMessage;

  /// 当前登录用户信息
  UserInfo? currentUser;

  /// 是否已登录
  bool isLoggedIn = false;

  /// 设置加载状态并通知 UI
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  /// 设置错误信息并通知 UI
  void _setError(String? message) {
    errorMessage = message;
    notifyListeners();
  }

  /// 清除错误信息
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  /// 用户名密码登录
  Future<bool> login(String loginName, String password) async {
    _setLoading(true);
    clearError();

    try {
      final request = LoginRequest(
        loginName: loginName,
        password: password,
        clientType: ApiConfig.clientType,
        loginMode: 'USERNAME_PASSWORD',
        tenantCode: ApiConfig.defaultTenantCode,
      );

      final result = await _authRepository.login(request);

      if (result.isSuccess() && result.data != null) {
        await _saveAndSetLoginState(result.data!);
        _setLoading(false);
        return true;
      } else {
        _setError(result.message ?? '登录失败');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('登录异常，请稍后重试');
      _setLoading(false);
      return false;
    }
  }

  /// 手机验证码登录
  Future<bool> loginWithSmsCode(String phone, String smsCode) async {
    _setLoading(true);
    clearError();

    try {
      final request = LoginRequest(
        phone: phone,
        smsCode: smsCode,
        clientType: ApiConfig.clientType,
        loginMode: 'SMS',
        tenantCode: ApiConfig.defaultTenantCode,
      );

      final result = await _authRepository.login(request);

      if (result.isSuccess() && result.data != null) {
        await _saveAndSetLoginState(result.data!);
        _setLoading(false);
        return true;
      } else {
        _setError(result.message ?? '登录失败');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('登录异常，请稍后重试');
      _setLoading(false);
      return false;
    }
  }

  /// 用户名密码注册
  Future<bool> register(
    String loginName,
    String password,
    String userName,
  ) async {
    _setLoading(true);
    clearError();

    try {
      final request = RegisterRequest(
        loginName: loginName,
        password: password,
        userName: userName,
        registerMode: 'USERNAME',
        tenantCode: ApiConfig.defaultTenantCode,
      );

      final result = await _authRepository.register(request);

      if (result.isSuccess()) {
        final registerResult = result.data;
        // 如果注册返回了 Token，直接登录
        if (registerResult?.tokenPair != null) {
          await _saveAndSetLoginState(registerResult!.tokenPair!);
        }
        _setLoading(false);
        return true;
      } else {
        _setError(result.message ?? '注册失败');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('注册异常，请稍后重试');
      _setLoading(false);
      return false;
    }
  }

  /// 手机号注册
  Future<bool> registerWithPhone(
    String phone,
    String smsCode,
    String userName,
  ) async {
    _setLoading(true);
    clearError();

    try {
      final request = RegisterRequest(
        phone: phone,
        userName: userName,
        registerMode: 'PHONE',
        tenantCode: ApiConfig.defaultTenantCode,
      );

      final result = await _authRepository.register(request);

      if (result.isSuccess()) {
        final registerResult = result.data;
        if (registerResult?.tokenPair != null) {
          await _saveAndSetLoginState(registerResult!.tokenPair!);
        }
        _setLoading(false);
        return true;
      } else {
        _setError(result.message ?? '注册失败');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('注册异常，请稍后重试');
      _setLoading(false);
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
    } catch (_) {
      // 即使 API 调用失败，也要清除本地 Token
    }

    await SecureStorage.instance.clearTokens();
    currentUser = null;
    isLoggedIn = false;
    _setLoading(false);
  }

  /// 检查登录状态
  ///
  /// 应用启动时调用，检查本地是否存储了有效的 Token。
  Future<bool> checkLoginStatus() async {
    final hasTokens = await SecureStorage.instance.hasTokens();
    isLoggedIn = hasTokens;
    notifyListeners();
    return hasTokens;
  }

  /// 保存 Token 并设置登录状态
  Future<void> _saveAndSetLoginState(TokenPair tokenPair) async {
    await SecureStorage.instance.saveTokenPair(tokenPair);
    isLoggedIn = true;
    // 从 Token 中解析基本信息
    currentUser = UserInfo(
      loginName: '',  // 从后端用户信息接口获取
    );
  }
}
