import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/register_request.dart';

void main() {
  group('RegisterRequest', () {
    // ---------- fromJson 测试 ----------

    test('fromJson 应正确解析所有字段', () {
      final json = {
        'loginName': 'new_user',
        'password': 'Pass1234',
        'userName': '张三',
        'phone': '13800138000',
        'email': 'zhangsan@example.com',
        'registerMode': 'USERNAME',
        'tenantCode': 'test_tenant',
      };

      final request = RegisterRequest.fromJson(json);

      expect(request.loginName, equals('new_user'));
      expect(request.password, equals('Pass1234'));
      expect(request.userName, equals('张三'));
      expect(request.phone, equals('13800138000'));
      expect(request.email, equals('zhangsan@example.com'));
      expect(request.registerMode, equals('USERNAME'));
      expect(request.tenantCode, equals('test_tenant'));
    });

    test('fromJson 当字段缺失时应返回 null', () {
      final json = <String, dynamic>{};

      final request = RegisterRequest.fromJson(json);

      expect(request.loginName, isNull);
      expect(request.password, isNull);
      expect(request.userName, isNull);
      expect(request.phone, isNull);
      expect(request.email, isNull);
      expect(request.registerMode, isNull);
      expect(request.tenantCode, isNull);
    });

    test('fromJson 当值为 null 时应返回 null', () {
      final json = {
        'loginName': null,
        'password': null,
        'userName': null,
        'phone': null,
        'email': null,
        'registerMode': null,
        'tenantCode': null,
      };

      final request = RegisterRequest.fromJson(json);

      expect(request.loginName, isNull);
      expect(request.password, isNull);
      expect(request.userName, isNull);
      expect(request.phone, isNull);
      expect(request.email, isNull);
      expect(request.registerMode, isNull);
      expect(request.tenantCode, isNull);
    });

    // ---------- toJson 测试 ----------

    test('toJson 应仅包含非空字段', () {
      const request = RegisterRequest(
        loginName: 'new_user',
        password: 'Pass1234',
      );

      final json = request.toJson();

      expect(json.containsKey('loginName'), isTrue);
      expect(json.containsKey('password'), isTrue);
      expect(json.containsKey('userName'), isFalse);
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('registerMode'), isFalse);
      expect(json.containsKey('tenantCode'), isFalse);
      expect(json['loginName'], equals('new_user'));
      expect(json['password'], equals('Pass1234'));
    });

    test('toJson 当所有字段均非空时应包含所有字段', () {
      const request = RegisterRequest(
        loginName: 'new_user',
        password: 'Pass1234',
        userName: '张三',
        phone: '13800138000',
        email: 'zhangsan@example.com',
        registerMode: 'USERNAME',
        tenantCode: 'test_tenant',
      );

      final json = request.toJson();

      expect(json['loginName'], equals('new_user'));
      expect(json['password'], equals('Pass1234'));
      expect(json['userName'], equals('张三'));
      expect(json['phone'], equals('13800138000'));
      expect(json['email'], equals('zhangsan@example.com'));
      expect(json['registerMode'], equals('USERNAME'));
      expect(json['tenantCode'], equals('test_tenant'));
    });

    test('toJson 当所有字段为空时应返回空 Map', () {
      const request = RegisterRequest();

      final json = request.toJson();

      expect(json, isEmpty);
    });

    // ---------- toString 测试 ----------

    test('toString 应包含 registerMode', () {
      const request = RegisterRequest(registerMode: 'USERNAME');

      expect(
        request.toString(),
        equals('RegisterRequest(registerMode: USERNAME)'),
      );
    });
  });
}
