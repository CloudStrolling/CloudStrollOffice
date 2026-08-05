import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/password_forgot_request.dart';

void main() {
  group('PasswordForgotRequest', () {
    // ---------- fromJson 测试 ----------

    test('fromJson 应正确解析所有字段', () {
      final json = {
        'mode': 'SMS',
        'target': '13800138000',
        'code': '123456',
        'newPassword': 'NewPass123',
      };

      final request = PasswordForgotRequest.fromJson(json);

      expect(request.mode, equals('SMS'));
      expect(request.target, equals('13800138000'));
      expect(request.code, equals('123456'));
      expect(request.newPassword, equals('NewPass123'));
    });

    test('fromJson 当字段缺失时应返回 null', () {
      final json = <String, dynamic>{};

      final request = PasswordForgotRequest.fromJson(json);

      expect(request.mode, isNull);
      expect(request.target, isNull);
      expect(request.code, isNull);
      expect(request.newPassword, isNull);
    });

    test('fromJson 当值为 null 时应返回 null', () {
      final json = {
        'mode': null,
        'target': null,
        'code': null,
        'newPassword': null,
      };

      final request = PasswordForgotRequest.fromJson(json);

      expect(request.mode, isNull);
      expect(request.target, isNull);
      expect(request.code, isNull);
      expect(request.newPassword, isNull);
    });

    // ---------- toJson 测试 ----------

    test('toJson 应仅包含非空字段', () {
      const request = PasswordForgotRequest(
        target: '13800138000',
        code: '123456',
      );

      final json = request.toJson();

      expect(json.containsKey('target'), isTrue);
      expect(json.containsKey('code'), isTrue);
      expect(json.containsKey('mode'), isFalse);
      expect(json.containsKey('newPassword'), isFalse);
      expect(json['target'], equals('13800138000'));
      expect(json['code'], equals('123456'));
    });

    test('toJson 当所有字段均非空时应包含所有字段', () {
      const request = PasswordForgotRequest(
        mode: 'EMAIL',
        target: 'test@example.com',
        code: '654321',
        newPassword: 'NewPass456',
      );

      final json = request.toJson();

      expect(json['mode'], equals('EMAIL'));
      expect(json['target'], equals('test@example.com'));
      expect(json['code'], equals('654321'));
      expect(json['newPassword'], equals('NewPass456'));
    });

    test('toJson 当所有字段为空时应返回空 Map', () {
      const request = PasswordForgotRequest();

      final json = request.toJson();

      expect(json, isEmpty);
    });
  });
}
