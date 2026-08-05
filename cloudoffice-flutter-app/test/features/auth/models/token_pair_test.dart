import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/token_pair.dart';

void main() {
  group('TokenPair', () {
    // ---------- fromJson 测试 ----------

    test('fromJson 应正确解析所有字段（包含 expireIn）', () {
      final json = {
        'accessToken': 'eyJhbGciOiJIUzI1NiIs...',
        'refreshToken': 'dGhpcyBpcyBhIHJlZnJl...',
        'accessTokenExpireIn': 7200,
        'refreshTokenExpireIn': 2592000,
        'tokenType': 'Bearer',
      };

      final pair = TokenPair.fromJson(json);

      expect(pair.accessToken, equals('eyJhbGciOiJIUzI1NiIs...'));
      expect(pair.refreshToken, equals('dGhpcyBpcyBhIHJlZnJl...'));
      expect(pair.accessTokenExpireIn, equals(7200));
      expect(pair.refreshTokenExpireIn, equals(2592000));
      expect(pair.tokenType, equals('Bearer'));
    });

    test('fromJson 当 expireIn 字段缺失时应返回 null', () {
      final json = {
        'accessToken': 'abc123',
        'refreshToken': 'def456',
        'tokenType': 'Bearer',
      };

      final pair = TokenPair.fromJson(json);

      expect(pair.accessToken, equals('abc123'));
      expect(pair.refreshToken, equals('def456'));
      expect(pair.accessTokenExpireIn, isNull);
      expect(pair.refreshTokenExpireIn, isNull);
      expect(pair.tokenType, equals('Bearer'));
    });

    test('fromJson 当所有字段都缺失时应返回全 null', () {
      final json = <String, dynamic>{};

      final pair = TokenPair.fromJson(json);

      expect(pair.accessToken, isNull);
      expect(pair.refreshToken, isNull);
      expect(pair.accessTokenExpireIn, isNull);
      expect(pair.refreshTokenExpireIn, isNull);
      expect(pair.tokenType, isNull);
    });

    test('fromJson 当 expireIn 为 null 时应返回 null', () {
      final json = {
        'accessToken': 'abc123',
        'accessTokenExpireIn': null,
        'refreshTokenExpireIn': null,
      };

      final pair = TokenPair.fromJson(json);

      expect(pair.accessToken, equals('abc123'));
      expect(pair.accessTokenExpireIn, isNull);
      expect(pair.refreshTokenExpireIn, isNull);
    });

    // ---------- toJson 测试 ----------

    test('toJson 应正确序列化所有字段', () {
      const pair = TokenPair(
        accessToken: 'eyJhbGciOiJIUzI1NiIs...',
        refreshToken: 'dGhpcyBpcyBhIHJlZnJl...',
        accessTokenExpireIn: 7200,
        refreshTokenExpireIn: 2592000,
        tokenType: 'Bearer',
      );

      final json = pair.toJson();

      expect(json['accessToken'], equals('eyJhbGciOiJIUzI1NiIs...'));
      expect(json['refreshToken'], equals('dGhpcyBpcyBhIHJlZnJl...'));
      expect(json['accessTokenExpireIn'], equals(7200));
      expect(json['refreshTokenExpireIn'], equals(2592000));
      expect(json['tokenType'], equals('Bearer'));
    });

    test('toJson 当 expireIn 为 null 时应映射为 null', () {
      const pair = TokenPair(
        accessToken: 'abc123',
        refreshToken: 'def456',
        tokenType: 'Bearer',
      );

      final json = pair.toJson();

      expect(json['accessToken'], equals('abc123'));
      expect(json['refreshToken'], equals('def456'));
      expect(json['accessTokenExpireIn'], isNull);
      expect(json['refreshTokenExpireIn'], isNull);
      expect(json['tokenType'], equals('Bearer'));
    });

    // ---------- toString 测试 ----------

    test('toString 应包含 accessToken 前10位和 tokenType', () {
      const pair = TokenPair(
        accessToken: 'eyJhbGciOiJIUzI1NiIs...',
        tokenType: 'Bearer',
      );

      final str = pair.toString();

      expect(str, startsWith('TokenPair(accessToken: '));
      expect(str, contains('Bearer'));
    });
  });
}
