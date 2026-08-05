import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/core/http/api_result.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/register_result.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/token_pair.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/auth_provider.dart';

import '../../../test_helpers.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubAuthRepository stubAuthRepository;
  late AuthProvider authProvider;

  setUp(() {
    // 模拟 flutter_secure_storage 平台通道，防止 MissingPluginException
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async => null,
    );

    stubAuthRepository = StubAuthRepository();
    authProvider = AuthProvider(
      authRepository: stubAuthRepository,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  group('初始状态', () {
    test('初始状态为未登录', () {
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.currentUser, isNull);
    });
  });

  group('login', () {
    test('登录成功时 isLoggedIn 变为 true', () async {
      final tokenPair = TokenPair(
        accessToken: 'access_token_value',
        refreshToken: 'refresh_token_value',
        tokenType: 'Bearer',
      );
      stubAuthRepository.onLogin =
          (_) async => ApiResult<TokenPair>.success(tokenPair);

      final result = await authProvider.login('testuser', 'password123');

      expect(result, true);
      expect(authProvider.isLoggedIn, true);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, isNull);
      expect(stubAuthRepository.invocations.length, 1);
    });

    test('登录失败时 isLoggedIn 保持 false 并设置错误信息', () async {
      stubAuthRepository.onLogin =
          (_) async => ApiResult<TokenPair>.error('用户名或密码错误', code: 401);

      final result = await authProvider.login('wronguser', 'wrongpass');

      expect(result, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, '用户名或密码错误');
    });

    test('网络异常时登录返回 false 并设置通用错误信息', () async {
      stubAuthRepository.onLogin = (_) async =>
          throw Exception('网络连接失败');

      final result = await authProvider.login('testuser', 'password123');

      expect(result, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.isLoading, false);
      expect(authProvider.errorMessage, '登录异常，请稍后重试');
    });
  });

  group('loginWithSmsCode', () {
    test('短信验证码登录成功', () async {
      final tokenPair = TokenPair(
        accessToken: 'sms_access_token',
        tokenType: 'Bearer',
      );
      stubAuthRepository.onLogin =
          (_) async => ApiResult<TokenPair>.success(tokenPair);

      final result =
          await authProvider.loginWithSmsCode('13800138000', '123456');

      expect(result, true);
      expect(authProvider.isLoggedIn, true);
      expect(stubAuthRepository.invocations.length, 1);
    });

    test('短信验证码登录失败', () async {
      stubAuthRepository.onLogin =
          (_) async => ApiResult<TokenPair>.error('验证码错误', code: 400);

      final result =
          await authProvider.loginWithSmsCode('13800138000', '000000');

      expect(result, false);
      expect(authProvider.isLoggedIn, false);
      expect(authProvider.errorMessage, '验证码错误');
    });
  });

  group('register', () {
    test('注册成功且返回 Token 时自动登录', () async {
      final tokenPair = TokenPair(accessToken: 'reg_token', tokenType: 'Bearer');
      final registerResult = RegisterResult(tokenPair: tokenPair);
      stubAuthRepository.onRegister =
          (_) async => ApiResult<RegisterResult>.success(registerResult);

      final result =
          await authProvider.register('newuser', 'password123', '新用户');

      expect(result, true);
    });

    test('注册失败时设置错误信息', () async {
      stubAuthRepository.onRegister =
          (_) async => ApiResult<RegisterResult>.error('用户名已存在', code: 409);

      final result =
          await authProvider.register('existing', 'password123', '已存在用户');

      expect(result, false);
      expect(authProvider.errorMessage, '用户名已存在');
    });
  });

  group('logout', () {
    test('退出登录清除状态', () async {
      authProvider.isLoggedIn = true;
      stubAuthRepository.onLogout =
          () async => ApiResult<void>.success(null);

      await authProvider.logout();

      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isLoading, false);
      expect(stubAuthRepository.invocations.length, 1);
    });

    test('退出登录时即使 API 调用失败也清除本地状态', () async {
      authProvider.isLoggedIn = true;
      stubAuthRepository.onLogout = () async => throw Exception('网络异常');

      await authProvider.logout();

      expect(authProvider.isLoggedIn, false);
      expect(authProvider.currentUser, isNull);
    });
  });

  group('clearError', () {
    test('clearError 清除错误信息', () {
      authProvider.errorMessage = '临时错误';
      authProvider.notifyListeners();

      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });
  });
}
