import 'package:cloudoffice_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:cloudoffice_flutter_app/features/auth/screens/forgot_password_screen.dart';
import 'package:cloudoffice_flutter_app/features/auth/screens/login_screen.dart';
import 'package:cloudoffice_flutter_app/features/auth/screens/register_screen.dart';
import 'package:cloudoffice_flutter_app/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 应用路由管理器
///
/// 使用 GoRouter 实现声明式路由，包含 4 个路由和登录路由守卫。
class AppRouter {
  /// 认证路由路径集合
  static const _authRoutes = {'/login', '/register', '/forgot-password'};

  final AuthProvider _authProvider;

  late final GoRouter _router = GoRouter(
    initialLocation: '/login',
    redirect: _guard,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (_, _) => const HomeScreen(),
      ),
    ],
  );

  /// 构造 [AppRouter]，需要外部传入 [AuthProvider] 以在守卫中检查登录状态。
  AppRouter({required this._authProvider});

  /// 获取 GoRouter 实例
  GoRouter get router => _router;

  /// 路由守卫：已登录用户访问认证路由 → 重定向到 /；未登录用户访问 / → 重定向到 /login。
  String? _guard(BuildContext context, GoRouterState state) {
    final isLoggedIn = _authProvider.isLoggedIn;
    final location = state.matchedLocation;

    if (isLoggedIn && _authRoutes.contains(location)) {
      return '/';
    }
    if (!isLoggedIn && !_authRoutes.contains(location)) {
      return '/login';
    }
    return null;
  }
}
