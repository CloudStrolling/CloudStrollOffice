import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/login_request.dart';

void main() {
  group('LoginRequest', () {
    // ---------- fromJson 测试 ----------

    test('fromJson 应正确解析所有字段', () {
      final json = {
        'loginName': 'test_user',
        'password': 'Abc12345',
        'phone': '13800138000',
        'smsCode': '123456',
        'tenantCode': 'test_tenant',
        'clientType': 'H5',
        'loginMode': 'USERNAME_PASSWORD',
      };

      final request = LoginRequest.fromJson(json);

      expect(request.loginName, equals('test_user'));
      expect(request.password, equals('Abc12345'));
      expect(request.phone, equals('13800138000'));
      expect(request.smsCode, equals('123456'));
      expect(request.tenantCode, equals('test_tenant'));
      expect(request.clientType, equals('H5'));
      expect(request.loginMode, equals('USERNAME_PASSWORD'));
    });

    test('fromJson 当字段缺失时应返回 null', () {
      final json = <String, dynamic>{};

      final request = LoginRequest.fromJson(json);

      expect(request.loginName, isNull);
      expect(request.password, isNull);
      expect(request.phone, isNull);
      expect(request.smsCode, isNull);
      expect(request.tenantCode, isNull);
      expect(request.clientType, isNull);
      expect(request.loginMode, isNull);
    });

    test('fromJson 当值为 null 时应返回 null', () {
      final json = {
        'loginName': null,
        'password': null,
        'phone': null,
        'smsCode': null,
        'tenantCode': null,
        'clientType': null,
        'loginMode': null,
      };

      final request = LoginRequest.fromJson(json);

      expect(request.loginName, isNull);
      expect(request.password, isNull);
      expect(request.phone, isNull);
      expect(request.smsCode, isNull);
      expect(request.tenantCode, isNull);
      expect(request.clientType, isNull);
      expect(request.loginMode, isNull);
    });

    // ---------- toJson 测试 ----------

    test('toJson 应仅包含非空字段', () {
      final request = const LoginRequest(
        loginName: 'test_user',
        password: 'Abc12345',
      );

      final json = request.toJson();

      expect(json.containsKey('loginName'), isTrue);
      expect(json.containsKey('password'), isTrue);
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('smsCode'), isFalse);
      expect(json.containsKey('tenantCode'), isFalse);
      expect(json.containsKey('clientType'), isFalse);
      expect(json.containsKey('loginMode'), isFalse);
      expect(json['loginName'], equals('test_user'));
      expect(json['password'], equals('Abc12345'));
    });

    test('toJson 当所有字段均非空时应包含所有字段', () {
      final request = const LoginRequest(
        loginName: 'test_user',
        password: 'Abc12345',
        phone: '13800138000',
        smsCode: '123456',
        tenantCode: 'test_tenant',
        clientType: 'H5',
        loginMode: 'USERNAME_PASSWORD',
      );

      final json = request.toJson();

      expect(json['loginName'], equals('test_user'));
      expect(json['password'], equals('Abc12345'));
      expect(json['phone'], equals('13800138000'));
      expect(json['smsCode'], equals('123456'));
      expect(json['tenantCode'], equals('test_tenant'));
      expect(json['clientType'], equals('H5'));
      expect(json['loginMode'], equals('USERNAME_PASSWORD'));
    });

    test('toJson 当所有字段为空时应返回空 Map', () {
      const request = LoginRequest();

      final json = request.toJson();

      expect(json, isEmpty);
    });

    // ---------- toString 测试 ----------

    test('toString 应包含 loginMode 和 clientType', () {
      const request = LoginRequest(
        loginMode: 'USERNAME_PASSWORD',
        clientType: 'H5',
      );

      expect(
        request.toString(),
        equals('LoginRequest(loginMode: USERNAME_PASSWORD, clientType: H5)'),
      );
    });
  });
}
