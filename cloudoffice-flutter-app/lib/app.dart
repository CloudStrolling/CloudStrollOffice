import 'package:cloudoffice_flutter_app/core/router/app_router.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/forgot_password_provider.dart';
import 'package:cloudoffice_flutter_app/features/home/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme_config.dart';

/// CloudStrollOffice 应用根组件
///
/// 使用 MultiProvider 注册全局状态，MaterialApp.router 集成 GoRouter 路由。
class CloudStrollOfficeApp extends StatelessWidget {
  const CloudStrollOfficeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ForgotPasswordProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
      ],
      child: const _AppWithRouter(),
    );
  }
}

/// 内部组件：在 Provider 树中创建 GoRouter
///
/// 需要访问 AuthProvider 来构造 AppRouter，因此必须在 MultiProvider 子树内。
class _AppWithRouter extends StatelessWidget {
  const _AppWithRouter();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appRouter = AppRouter(authProvider: authProvider);

    return MaterialApp.router(
      title: '云漫智企',
      theme: ThemeConfig.lightTheme,
      routerConfig: appRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
