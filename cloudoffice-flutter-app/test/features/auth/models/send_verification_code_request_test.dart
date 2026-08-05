import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/send_verification_code_request.dart';

void main() {
  group('SendVerificationCodeRequest', () {
    // ---------- fromJson 测试 ----------

    test('fromJson 应正确解析所有字段', () {
      final json = {
        'target': '13800138000',
        'purpose': 'REGISTER',
        'mode': 'SMS',
      };

      final request = SendVerificationCodeRequest.fromJson(json);

      expect(request.target, equals('13800138000'));
      expect(request.purpose, equals('REGISTER'));
      expect(request.mode, equals('SMS'));
    });

    test('fromJson 当字段缺失时应返回 null', () {
      final json = <String, dynamic>{};

      final request = SendVerificationCodeRequest.fromJson(json);

      expect(request.target, isNull);
      expect(request.purpose, isNull);
      expect(request.mode, isNull);
    });

    test('fromJson 当值为 null 时应返回 null', () {
      final json = {
        'target': null,
        'purpose': null,
        'mode': null,
      };

      final request = SendVerificationCodeRequest.fromJson(json);

      expect(request.target, isNull);
      expect(request.purpose, isNull);
      expect(request.mode, isNull);
    });

    // ---------- toJson 测试 ----------

    test('toJson 应仅包含非空字段', () {
      const request = SendVerificationCodeRequest(target: '13800138000');

      final json = request.toJson();

      expect(json.containsKey('target'), isTrue);
      expect(json.containsKey('purpose'), isFalse);
      expect(json.containsKey('mode'), isFalse);
      expect(json['target'], equals('13800138000'));
    });

    test('toJson 当所有字段均非空时应包含所有字段', () {
      const request = SendVerificationCodeRequest(
        target: 'test@example.com',
        purpose: 'RESET_PASSWORD',
        mode: 'EMAIL',
      );

      final json = request.toJson();

      expect(json['target'], equals('test@example.com'));
      expect(json['purpose'], equals('RESET_PASSWORD'));
      expect(json['mode'], equals('EMAIL'));
    });

    test('toJson 当所有字段为空时应返回空 Map', () {
      const request = SendVerificationCodeRequest();

      final json = request.toJson();

      expect(json, isEmpty);
    });
  });
}
