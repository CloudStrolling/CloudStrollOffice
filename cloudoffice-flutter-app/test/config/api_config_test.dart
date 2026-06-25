import 'package:flutter_test/flutter_test.dart';

import 'package:cloudoffice_flutter_app/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl 默认为 localhost:9000', () {
      expect(ApiConfig.baseUrl, equals('http://localhost:9000'));
    });

    test('connectTimeout 为 15 秒', () {
      expect(ApiConfig.connectTimeout, equals(15));
    });

    test('receiveTimeout 为 30 秒', () {
      expect(ApiConfig.receiveTimeout, equals(30));
    });

    test('defaultTenantCode 为 default', () {
      expect(ApiConfig.defaultTenantCode, equals('default'));
    });

    test('clientType 返回字符串类型', () {
      final type = ApiConfig.clientType;
      expect(type, isA<String>());
    });

    test('所有配置值类型正确', () {
      expect(ApiConfig.baseUrl, isA<String>());
      expect(ApiConfig.connectTimeout, isA<int>());
      expect(ApiConfig.receiveTimeout, isA<int>());
      expect(ApiConfig.defaultTenantCode, isA<String>());
      expect(ApiConfig.clientType, isA<String>());
    });

    test('ApiConfig 为静态常量类（私有构造）', () {
      // 验证 ApiConfig 的静态常量都可通过类名访问
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.connectTimeout, greaterThan(0));
      expect(ApiConfig.receiveTimeout, greaterThan(0));
    });
  });
}
