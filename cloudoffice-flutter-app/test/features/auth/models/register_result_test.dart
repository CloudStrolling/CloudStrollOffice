import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/register_result.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/token_pair.dart';

void main() {
  group('RegisterResult', () {
    // ---------- fromJson 测试 ----------

    test('fromJson 应正确解析所有字段（包含嵌套 TokenPair）', () {
      final json = {
        'userId': 100,
        'loginName': 'new_user',
        'userName': '李四',
        'accountSettled': false,
        'tokenPair': {
          'accessToken': 'eyJhbGciOiJIUzI1NiIs...',
          'refreshToken': 'dGhpcyBpcyBhIHJlZnJl...',
          'accessTokenExpireIn': 7200,
          'refreshTokenExpireIn': 2592000,
          'tokenType': 'Bearer',
        },
      };

      final result = RegisterResult.fromJson(json);

      expect(result.userId, equals(100));
      expect(result.loginName, equals('new_user'));
      expect(result.userName, equals('李四'));
      expect(result.accountSettled, isFalse);
      expect(result.tokenPair, isNotNull);
      expect(result.tokenPair?.accessToken, equals('eyJhbGciOiJIUzI1NiIs...'));
      expect(result.tokenPair?.refreshToken, equals('dGhpcyBpcyBhIHJlZnJl...'));
      expect(result.tokenPair?.accessTokenExpireIn, equals(7200));
      expect(result.tokenPair?.refreshTokenExpireIn, equals(2592000));
      expect(result.tokenPair?.tokenType, equals('Bearer'));
    });

    test('fromJson 当 tokenPair 为 null 时应返回 null', () {
      final json = {
        'userId': 100,
        'loginName': 'new_user',
        'userName': '李四',
        'accountSettled': true,
        'tokenPair': null,
      };

      final result = RegisterResult.fromJson(json);

      expect(result.userId, equals(100));
      expect(result.loginName, equals('new_user'));
      expect(result.userName, equals('李四'));
      expect(result.accountSettled, isTrue);
      expect(result.tokenPair, isNull);
    });

    test('fromJson 当 tokenPair 字段缺失时应返回 null', () {
      final json = {
        'userId': 100,
        'loginName': 'new_user',
      };

      final result = RegisterResult.fromJson(json);

      expect(result.userId, equals(100));
      expect(result.loginName, equals('new_user'));
      expect(result.tokenPair, isNull);
    });

    test('fromJson 当所有字段都缺失时应返回全 null', () {
      final json = <String, dynamic>{};

      final result = RegisterResult.fromJson(json);

      expect(result.userId, isNull);
      expect(result.loginName, isNull);
      expect(result.userName, isNull);
      expect(result.accountSettled, isNull);
      expect(result.tokenPair, isNull);
    });

    // ---------- toJson 测试 ----------

    test('toJson 应正确序列化（包含嵌套 TokenPair）', () {
      const result = RegisterResult(
        userId: 100,
        loginName: 'new_user',
        userName: '李四',
        accountSettled: false,
        tokenPair: TokenPair(
          accessToken: 'abc123',
          refreshToken: 'def456',
          accessTokenExpireIn: 7200,
          refreshTokenExpireIn: 2592000,
          tokenType: 'Bearer',
        ),
      );

      final json = result.toJson();

      expect(json['userId'], equals(100));
      expect(json['loginName'], equals('new_user'));
      expect(json['userName'], equals('李四'));
      expect(json['accountSettled'], isFalse);
      expect(json['tokenPair'], isA<Map<String, dynamic>>());
      expect((json['tokenPair'] as Map<String, dynamic>)['accessToken'], equals('abc123'));
      expect((json['tokenPair'] as Map<String, dynamic>)['refreshToken'], equals('def456'));
      expect((json['tokenPair'] as Map<String, dynamic>)['tokenType'], equals('Bearer'));
    });

    test('toJson 当 tokenPair 为 null 时应不包含 tokenPair 字段', () {
      const result = RegisterResult(
        userId: 100,
        loginName: 'new_user',
      );

      final json = result.toJson();

      expect(json['userId'], equals(100));
      expect(json.containsKey('tokenPair'), isFalse);
    });
  });
}
