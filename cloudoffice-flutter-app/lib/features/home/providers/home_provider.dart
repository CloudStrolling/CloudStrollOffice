import 'package:flutter/foundation.dart';

import '../../../core/storage/secure_storage.dart';
import '../../auth/models/user_info.dart';
import '../../auth/repositories/auth_repository.dart';

/// 首页状态管理
///
/// 管理用户信息展示和退出登录等首页相关状态。
class HomeProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  HomeProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  /// 是否正在加载
  bool isLoading = false;

  /// 用户信息
  UserInfo? userInfo;

  /// 设置加载状态
  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  /// 加载用户信息（预留，后续对接获取用户信息接口）
  Future<void> loadUserInfo() async {
    _setLoading(true);
    // TODO: 对接后端用户信息接口
    // 当前从本地 Token 或简单数据初始化
    _setLoading(false);
  }

  /// 退出登录
  ///
  /// 调用后端登出 API，无论成功与否都清除本地 Token。
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
    } catch (_) {
      // API 调用失败不影响本地退出
    }

    // 清除本地 Token
    await SecureStorage.instance.clearTokens();
    userInfo = null;
    _setLoading(false);
  }
}
