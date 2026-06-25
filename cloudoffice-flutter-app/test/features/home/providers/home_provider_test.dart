import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/core/http/api_result.dart';
import 'package:cloudoffice_flutter_app/features/home/providers/home_provider.dart';

import '../../../test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubAuthRepository stubAuthRepository;
  late HomeProvider homeProvider;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async => null,
    );

    stubAuthRepository = StubAuthRepository();
    homeProvider = HomeProvider(authRepository: stubAuthRepository);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  group('初始状态', () {
    test('初始状态 userInfo 为 null，isLoading 为 false', () {
      expect(homeProvider.userInfo, isNull);
      expect(homeProvider.isLoading, false);
    });
  });

  group('logout', () {
    test('退出登录成功时清除用户信息', () async {
      stubAuthRepository.onLogout =
          () async => ApiResult<void>.success(null);

      await homeProvider.logout();

      expect(stubAuthRepository.invocations.length, 1);
      expect(homeProvider.userInfo, isNull);
      expect(homeProvider.isLoading, false);
    });

    test('退出登录时即使 API 失败也清除本地状态', () async {
      stubAuthRepository.onLogout = () async => throw Exception('网络异常');

      await homeProvider.logout();

      expect(homeProvider.userInfo, isNull);
      expect(homeProvider.isLoading, false);
      expect(stubAuthRepository.invocations.length, 1);
    });
  });

  group('loadUserInfo', () {
    test('loadUserInfo 设置加载状态并完成', () async {
      await homeProvider.loadUserInfo();

      expect(homeProvider.isLoading, false);
    });
  });
}
