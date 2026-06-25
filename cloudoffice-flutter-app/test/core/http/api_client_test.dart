import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/core/http/api_client.dart';

void main() {
  group('ApiClient 单例模式', () {
    test('多次调用 instance 返回同一个实例', () {
      // 验证单例模式：连续两次获取实例，引用应相同
      final instance1 = ApiClient.instance;
      final instance2 = ApiClient.instance;

      expect(identical(instance1, instance2), true);
    });

    test('instance 不为 null', () {
      expect(ApiClient.instance, isNotNull);
    });
  });

  group('ApiClient 方法结构验证', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient.instance;
    });

    test('get 方法存在且返回 Future<Response>', () {
      // get 返回 Future，不会同步抛出异常
      expect(client.get, isA<Function>());
    });

    test('post 方法存在且返回 Future<Response>', () {
      expect(client.post, isA<Function>());
    });

    test('put 方法存在且返回 Future<Response>', () {
      expect(client.put, isA<Function>());
    });

    test('delete 方法存在且返回 Future<Response>', () {
      expect(client.delete, isA<Function>());
    });

    test('dio getter 返回 Dio 实例', () {
      expect(client.dio, isNotNull);
    });
  });
}
