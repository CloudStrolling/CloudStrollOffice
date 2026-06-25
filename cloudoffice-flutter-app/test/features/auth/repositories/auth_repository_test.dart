import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/core/http/api_client.dart';
import 'package:cloudoffice_flutter_app/core/http/api_result.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/login_request.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/register_request.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/token_pair.dart';
import 'package:cloudoffice_flutter_app/features/auth/repositories/auth_repository.dart';

/// ApiClient 的测试替身——记录调用的 path 和 data，返回预设的 Response
///
/// 避免使用 Mockito 对具体类 ApiClient 进行 mock 时的兼容性问题。
class ApiClientSpy implements ApiClient {
  String? lastPostPath;
  dynamic lastPostData;
  final Response Function()? responseBuilder;

  ApiClientSpy({this.responseBuilder});

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    return responseBuilder != null
        ? responseBuilder!()
        : Response(
            requestOptions: RequestOptions(path: path),
            data: {'code': 200, 'message': '成功'},
            statusCode: 200,
          );
  }

  // ApiClient 的其他方法——未使用但必须实现
  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }

  @override
  Dio get dio => throw UnimplementedError();
}

// 使用 Dio 的 Response 类构建测试响应
Response _makeResponse(String path, Map<String, dynamic> data,
    {int statusCode = 200}) {
  return Response(
    requestOptions: RequestOptions(path: path),
    data: data,
    statusCode: statusCode,
  );
}

void main() {
  group('AuthRepository', () {
    test('构造函数正确接收 ApiClient 实例', () {
      final spy = ApiClientSpy();
      final repo = AuthRepository(apiClient: spy);
      expect(repo, isNotNull);
    });

    group('login', () {
      test('调用 POST /api/v1/auth/login 并传递登录请求数据', () async {
        // 准备
        final loginRequest = LoginRequest(
          loginName: 'testuser',
          password: 'password123',
          loginMode: 'USERNAME_PASSWORD',
        );
        final spy = ApiClientSpy(
          responseBuilder: () => _makeResponse('/api/v1/auth/login', {
            'code': 200,
            'message': '登录成功',
            'data': {
              'accessToken': 'mock_access_token',
              'refreshToken': 'mock_refresh_token',
              'tokenType': 'Bearer',
            },
          }),
        );
        final repo = AuthRepository(apiClient: spy);

        // 执行
        final result = await repo.login(loginRequest);

        // 验证
        expect(spy.lastPostPath, '/api/v1/auth/login');
        expect(spy.lastPostData, loginRequest.toJson());
        expect(result.isSuccess(), true);
        expect(result.data?.accessToken, 'mock_access_token');
        expect(result.data?.refreshToken, 'mock_refresh_token');
        expect(result.data?.tokenType, 'Bearer');
      });
    });

    group('register', () {
      test('调用 POST /api/v1/auth/register 并传递注册请求数据', () async {
        final registerRequest = RegisterRequest(
          loginName: 'newuser',
          password: 'password123',
          userName: '新用户',
          registerMode: 'USERNAME',
        );
        final spy = ApiClientSpy(
          responseBuilder: () => _makeResponse('/api/v1/auth/register', {
            'code': 200,
            'message': '注册成功',
            'data': {'userId': 1, 'loginName': 'newuser', 'userName': '新用户'},
          }),
        );
        final repo = AuthRepository(apiClient: spy);

        final result = await repo.register(registerRequest);

        expect(spy.lastPostPath, '/api/v1/auth/register');
        expect(spy.lastPostData, registerRequest.toJson());
        expect(result.isSuccess(), true);
      });
    });

    group('refreshToken', () {
      test('调用 POST /api/v1/auth/refresh 并传递 Refresh Token', () async {
        final spy = ApiClientSpy(
          responseBuilder: () => _makeResponse('/api/v1/auth/refresh', {
            'code': 200,
            'message': '刷新成功',
            'data': {
              'accessToken': 'new_access_token',
              'refreshToken': 'new_refresh_token',
              'tokenType': 'Bearer',
            },
          }),
        );
        final repo = AuthRepository(apiClient: spy);

        final result = await repo.refreshToken('old_refresh_token');

        expect(spy.lastPostPath, '/api/v1/auth/refresh');
        expect(spy.lastPostData, {'refreshToken': 'old_refresh_token'});
        expect(result.isSuccess(), true);
        expect(result.data?.accessToken, 'new_access_token');
      });
    });

    group('logout', () {
      test('调用 POST /api/v1/auth/logout', () async {
        final spy = ApiClientSpy(
          responseBuilder: () => _makeResponse('/api/v1/auth/logout', {
            'code': 200,
            'message': '退出成功',
          }),
        );
        final repo = AuthRepository(apiClient: spy);

        final result = await repo.logout();

        expect(spy.lastPostPath, '/api/v1/auth/logout');
        expect(result.isSuccess(), true);
      });
    });

    group('sendVerificationCode', () {
      test('调用 POST /api/v1/auth/verification-code/send 并传递验证码请求参数',
          () async {
        final spy = ApiClientSpy(
          responseBuilder: () =>
              _makeResponse('/api/v1/auth/verification-code/send', {
            'code': 200,
            'message': '验证码已发送',
          }),
        );
        final repo = AuthRepository(apiClient: spy);

        final result = await repo.sendVerificationCode(
          '13800138000',
          'RESET_PASSWORD',
          'SMS',
        );

        expect(spy.lastPostPath, '/api/v1/auth/verification-code/send');
        expect(spy.lastPostData, {
          'target': '13800138000',
          'purpose': 'RESET_PASSWORD',
          'mode': 'SMS',
        });
        expect(result.isSuccess(), true);
      });
    });

    group('forgotPasswordReset', () {
      test('调用 POST /api/v1/auth/password/forgot/reset 并传递重置密码请求参数',
          () async {
        final spy = ApiClientSpy(
          responseBuilder: () =>
              _makeResponse('/api/v1/auth/password/forgot/reset', {
            'code': 200,
            'message': '密码重置成功',
          }),
        );
        final repo = AuthRepository(apiClient: spy);

        final result = await repo.forgotPasswordReset(
          'SMS',
          '13800138000',
          '123456',
          'NewP@ss123',
        );

        expect(spy.lastPostPath, '/api/v1/auth/password/forgot/reset');
        expect(spy.lastPostData, {
          'mode': 'SMS',
          'target': '13800138000',
          'code': '123456',
          'newPassword': 'NewP@ss123',
        });
        expect(result.isSuccess(), true);
      });
    });
  });
}
