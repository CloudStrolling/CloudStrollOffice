import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/core/http/api_interceptor.dart';

// 用于 SecureStorage 的平台通道 mock
const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

/// 可拦截 next 调用的 ErrorInterceptorHandler
///
/// Dio 的 ErrorInterceptorHandler.next 使用 completeError 向 Dio 管道
/// 传递 InterceptorState，在独立测试（无 Dio 管道）中会导致未捕获异常。
/// 该 MockHandler 捕获 next/resolve/reject 调用，使测试可以验证拦截器的行为。
class _MockErrorInterceptorHandler extends ErrorInterceptorHandler {
  bool nextCalled = false;
  bool resolveCalled = false;
  bool rejectCalled = false;
  DioException? nextError;
  Response? resolveResponse;
  DioException? rejectError;
  Completer<void>? nextCompleter;

  @override
  void next(DioException error) {
    nextCalled = true;
    nextError = error;
    nextCompleter?.complete();
  }

  @override
  void resolve(Response response) {
    resolveCalled = true;
    resolveResponse = response;
  }

  @override
  void reject(DioException error) {
    rejectCalled = true;
    rejectError = error;
  }
}

/// 可捕获 next 调用的 ResponseInterceptorHandler
class _MockResponseInterceptorHandler extends ResponseInterceptorHandler {
  bool nextCalled = false;
  Response? nextResponse;

  @override
  void next(Response response) {
    nextCalled = true;
    nextResponse = response;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiInterceptor interceptor;

  setUp(() {
    // Mock flutter_secure_storage 平台通道，防止 MissingPluginException
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

    interceptor = ApiInterceptor();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  group('ApiInterceptor - 白名单路径判断', () {
    test('白名单路径不经过 Token 注入', () async {
      // 白名单路径：login, register, refresh 等
      final whiteListPaths = [
        '/api/v1/auth/login',
        '/api/v1/auth/register',
        '/api/v1/auth/refresh',
        '/api/v1/auth/verification-code/send',
        '/api/v1/auth/password/forgot/send-code',
        '/api/v1/auth/password/forgot/reset',
        '/api/v1/auth/health',
      ];

      for (final path in whiteListPaths) {
        final options = RequestOptions(path: path);
        final handler = RequestInterceptorHandler();

        // 直接调用 onRequest，拦截器应跳过 Token 注入
        interceptor.onRequest(options, handler);

        await Future<void>.delayed(const Duration(milliseconds: 10));

        // 白名单路径不应该有 Authorization 头
        expect(
          options.headers.containsKey('Authorization'),
          false,
          reason: '白名单路径 $path 不应注入 Token',
        );
      }
    });

    test('非白名单路径不带 Token 时不添加 Authorization 头', () async {
      final options = RequestOptions(path: '/api/v1/user/profile');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 没有 Token 时不添加 Authorization
      expect(options.headers.containsKey('Authorization'), false);
    });

    test('有 Token 时非白名单路径注入 Bearer Token', () async {
      // 设置 SecureStorage 返回 access_token
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        _secureStorageChannel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'read') {
            return 'mock_access_token_value';
          }
          return null;
        },
      );

      // 重新创建拦截器以重新绑定平台通道
      interceptor = ApiInterceptor();

      final options = RequestOptions(path: '/api/v1/user/profile');
      final handler = RequestInterceptorHandler();

      interceptor.onRequest(options, handler);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 验证 Authorization 头已注入
      expect(options.headers['Authorization'], equals('Bearer mock_access_token_value'));
    });
  });

  group('ApiInterceptor - onResponse（响应拦截）', () {
    test('onResponse 使用 resolve 传递正常响应', () async {
      final response = Response(
        requestOptions: RequestOptions(path: '/api/v1/auth/user/profile'),
        data: {'code': 200, 'message': '成功'},
        statusCode: 200,
      );
      final handler = _MockResponseInterceptorHandler();

      interceptor.onResponse(response, handler);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      // onResponse 应调用 next 传递响应，不修改响应内容
      expect(handler.nextCalled, true);
      expect(handler.nextResponse?.statusCode, 200);
    });
  });

  group('ApiInterceptor - onError（错误拦截）', () {
    test('非 401 错误直接通过 next 传递', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/v1/user/profile'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/user/profile'),
          statusCode: 403,
          data: {'message': '权限不足'},
        ),
        type: DioExceptionType.badResponse,
      );

      final handler = _MockErrorInterceptorHandler();

      // onError 是 async void，所以不能直接用 await
      interceptor.onError(err, handler);

      // 给异步操作一点处理时间
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 验证 next 被调用且错误未被修改
      expect(handler.nextCalled, true);
      expect(handler.nextError?.type, DioExceptionType.badResponse);
      expect(handler.nextError?.response?.statusCode, 403);
      expect(handler.resolveCalled, false);
      expect(handler.rejectCalled, false);
    });

    test('白名单路径的 401 直接通过 next 传递', () async {
      final err = DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/refresh'),
          statusCode: 401,
          data: {'message': '未授权'},
        ),
        type: DioExceptionType.badResponse,
      );

      final handler = _MockErrorInterceptorHandler();

      interceptor.onError(err, handler);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      // 白名单路径 401 不应该触发 Token 刷新
      expect(handler.nextCalled, true);
      expect(handler.nextError?.response?.statusCode, 401);
    });
  });
}
