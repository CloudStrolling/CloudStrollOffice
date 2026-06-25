import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/user_info.dart';

void main() {
  group('UserInfo', () {
    // ---------- fromJson 测试 ----------

    test('fromJson 应正确解析所有字段', () {
      final json = {
        'userId': 1,
        'loginName': 'zhangsan',
        'userName': '张三',
        'phone': '13800138000',
        'email': 'zhangsan@example.com',
        'avatar': 'https://example.com/avatar.png',
      };

      final info = UserInfo.fromJson(json);

      expect(info.userId, equals(1));
      expect(info.loginName, equals('zhangsan'));
      expect(info.userName, equals('张三'));
      expect(info.phone, equals('13800138000'));
      expect(info.email, equals('zhangsan@example.com'));
      expect(info.avatar, equals('https://example.com/avatar.png'));
    });

    test('fromJson 当字段缺失时应返回 null', () {
      final json = <String, dynamic>{};

      final info = UserInfo.fromJson(json);

      expect(info.userId, isNull);
      expect(info.loginName, isNull);
      expect(info.userName, isNull);
      expect(info.phone, isNull);
      expect(info.email, isNull);
      expect(info.avatar, isNull);
    });

    test('fromJson 当值为 null 时应返回 null', () {
      final json = {
        'userId': null,
        'loginName': null,
        'userName': null,
        'phone': null,
        'email': null,
        'avatar': null,
      };

      final info = UserInfo.fromJson(json);

      expect(info.userId, isNull);
      expect(info.loginName, isNull);
      expect(info.userName, isNull);
      expect(info.phone, isNull);
      expect(info.email, isNull);
      expect(info.avatar, isNull);
    });

    // ---------- toJson 测试 ----------

    test('toJson 应仅包含非空字段', () {
      const info = UserInfo(
        userId: 1,
        loginName: 'zhangsan',
      );

      final json = info.toJson();

      expect(json['userId'], equals(1));
      expect(json['loginName'], equals('zhangsan'));
      expect(json.containsKey('userName'), isFalse);
      expect(json.containsKey('phone'), isFalse);
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('avatar'), isFalse);
    });

    test('toJson 当所有字段均非空时应包含所有字段', () {
      const info = UserInfo(
        userId: 1,
        loginName: 'zhangsan',
        userName: '张三',
        phone: '13800138000',
        email: 'zhangsan@example.com',
        avatar: 'https://example.com/avatar.png',
      );

      final json = info.toJson();

      expect(json['userId'], equals(1));
      expect(json['loginName'], equals('zhangsan'));
      expect(json['userName'], equals('张三'));
      expect(json['phone'], equals('13800138000'));
      expect(json['email'], equals('zhangsan@example.com'));
      expect(json['avatar'], equals('https://example.com/avatar.png'));
    });

    test('toJson 当所有字段为空时应返回空 Map', () {
      const info = UserInfo();

      final json = info.toJson();

      expect(json, isEmpty);
    });

    // ---------- toString 测试 ----------

    test('toString 应包含 userId 和 loginName', () {
      const info = UserInfo(userId: 1, loginName: 'zhangsan');

      expect(
        info.toString(),
        equals('UserInfo(userId: 1, loginName: zhangsan)'),
      );
    });
  });
}
