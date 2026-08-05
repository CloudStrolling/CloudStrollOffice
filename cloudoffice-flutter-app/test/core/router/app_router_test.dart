import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloudoffice_flutter_app/core/router/app_router.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:cloudoffice_flutter_app/features/auth/screens/login_screen.dart';
import 'package:cloudoffice_flutter_app/features/home/providers/home_provider.dart';
import 'package:cloudoffice_flutter_app/features/home/screens/home_screen.dart';

void main() {
  // flutter_secure_storage 平台通道 mock
  const _secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    // Mock flutter_secure_storage 平台通道
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _secureStorageChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'write') return null;
        if (methodCall.method == 'read') return null;
        if (methodCall.method == 'deleteAll') return null;
        if (methodCall.method == 'delete') return null;
        if (methodCall.method == 'containsKey') return false;
        if (methodCall.method == 'readAll') return <String, String>{};
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  group('AppRouter - 路由构造', () {
    test('AppRouter 构造成功', () {
      final authProvider = AuthProvider();
      final appRouter = AppRouter(authProvider: authProvider);

      expect(appRouter, isNotNull);
      expect(appRouter.router, isNotNull);
    });
  });

  group('AppRouter - 路由守卫', () {
    testWidgets('未登录时重定向到 LoginScreen', (WidgetTester tester) async {
      // 设置 SharedPreferences mock 值（空列表）
      SharedPreferences.setMockInitialValues({});

      final authProvider = AuthProvider();
      final homeProvider = HomeProvider();
      final appRouter = AppRouter(authProvider: authProvider);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter.router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 未登录时应显示 LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('已登录时显示 HomeScreen', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      final authProvider = AuthProvider();
      authProvider.isLoggedIn = true;
      final homeProvider = HomeProvider();
      final appRouter = AppRouter(authProvider: authProvider);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<HomeProvider>.value(value: homeProvider),
          ],
          child: MaterialApp.router(
            routerConfig: appRouter.router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 已登录用户应显示 HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}
