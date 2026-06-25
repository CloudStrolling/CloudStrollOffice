import 'package:flutter_test/flutter_test.dart';
import 'package:cloudoffice_flutter_app/core/http/api_result.dart';

/// 用于泛型测试的简单数据模型
class _TestData {
  final int id;
  final String name;

  const _TestData({required this.id, required this.name});

  factory _TestData.fromJson(Map<String, dynamic> json) {
    return _TestData(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TestData && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

void main() {
  group('ApiResult', () {
    // ---------- fromJson 测试 ----------

    test('fromJson（成功）应正确解析 data 并使用 fromJsonT', () {
      final json = {
        'code': 200,
        'message': '操作成功',
        'data': {'id': 1, 'name': '张三'},
        'timestamp': 1700000000000,
      };

      final result = ApiResult<_TestData>.fromJson(
        json,
        fromJsonT: _TestData.fromJson,
      );

      expect(result.code, equals(200));
      expect(result.message, equals('操作成功'));
      expect(result.data, equals(const _TestData(id: 1, name: '张三')));
      expect(result.timestamp, equals(1700000000000));
      expect(result.isSuccess(), isTrue);
    });

    test('fromJson（成功）当 fromJsonT 为 null 时 data 应为 null', () {
      final json = {
        'code': 200,
        'message': '操作成功',
        'data': {'id': 1, 'name': '张三'},
        'timestamp': 1700000000000,
      };

      final result = ApiResult<_TestData>.fromJson(json);

      expect(result.code, equals(200));
      expect(result.message, equals('操作成功'));
      expect(result.data, isNull);
      expect(result.isSuccess(), isTrue);
    });

    test('fromJson（错误）应解析错误信息且 data 为 null', () {
      final json = {
        'code': -1,
        'message': '服务器内部错误',
        'data': null,
        'timestamp': 1700000000000,
      };

      final result = ApiResult<_TestData>.fromJson(
        json,
        fromJsonT: _TestData.fromJson,
      );

      expect(result.code, equals(-1));
      expect(result.message, equals('服务器内部错误'));
      expect(result.data, isNull);
      expect(result.isSuccess(), isFalse);
    });

    test('fromJson 包含 null 字段时应正确解析', () {
      final json = {
        'code': null,
        'message': null,
        'data': null,
        'timestamp': null,
      };

      final result = ApiResult<_TestData>.fromJson(json);

      expect(result.code, isNull);
      expect(result.message, isNull);
      expect(result.data, isNull);
      expect(result.timestamp, isNull);
      expect(result.isSuccess(), isFalse);
    });

    // ---------- fromJsonList 测试 ----------

    test('fromJsonList 应正确解析列表数据', () {
      final json = {
        'code': 200,
        'message': '获取列表成功',
        'data': [
          {'id': 1, 'name': '张三'},
          {'id': 2, 'name': '李四'},
        ],
        'timestamp': 1700000000000,
      };

      final result = ApiResult<dynamic>.fromJsonList(
        json,
        fromJsonT: (map) => _TestData.fromJson(map),
      );

      expect(result.code, equals(200));
      expect(result.message, equals('获取列表成功'));
      expect(result.data, isA<List<dynamic>>());
      expect((result.data as List<dynamic>).length, equals(2));
      expect(
        (result.data as List<dynamic>)[0],
        equals(const _TestData(id: 1, name: '张三')),
      );
      expect(
        (result.data as List<dynamic>)[1],
        equals(const _TestData(id: 2, name: '李四')),
      );
      expect(result.isSuccess(), isTrue);
    });

    test('fromJsonList 当 data 为 null 时应返回空列表', () {
      final json = {
        'code': 200,
        'message': '获取列表成功',
        'data': null,
        'timestamp': 1700000000000,
      };

      final result = ApiResult<dynamic>.fromJsonList(
        json,
        fromJsonT: (map) => _TestData.fromJson(map),
      );

      expect(result.data, isA<List<dynamic>>());
      expect((result.data as List<dynamic>), isEmpty);
    });

    test('fromJsonList 当 data 为空列表时应返回空列表', () {
      final json = {
        'code': 200,
        'message': '获取列表成功',
        'data': <dynamic>[],
        'timestamp': 1700000000000,
      };

      final result = ApiResult<dynamic>.fromJsonList(
        json,
        fromJsonT: (map) => _TestData.fromJson(map),
      );

      expect(result.data, isA<List<dynamic>>());
      expect((result.data as List<dynamic>), isEmpty);
    });

    // ---------- isSuccess 测试 ----------

    test('isSuccess 当 code 为 200 时应返回 true', () {
      const result = ApiResult(code: 200);

      expect(result.isSuccess(), isTrue);
    });

    test('isSuccess 当 code 为非 200 时应返回 false', () {
      const result = ApiResult(code: 400);

      expect(result.isSuccess(), isFalse);
    });

    test('isSuccess 当 code 为 null 时应返回 false', () {
      const result = ApiResult<int>();

      expect(result.isSuccess(), isFalse);
    });

    // ---------- 静态工厂方法测试 ----------

    test('success() 应创建 code=200 的成功结果', () {
      final result = ApiResult<String>.success('hello', message: '自定义消息');

      expect(result.code, equals(200));
      expect(result.message, equals('自定义消息'));
      expect(result.data, equals('hello'));
      expect(result.timestamp, isNotNull);
      expect(result.isSuccess(), isTrue);
    });

    test('success() 不传 message 时应使用默认消息', () {
      final result = ApiResult<String>.success('hello');

      expect(result.message, equals('操作成功'));
    });

    test('error() 应创建错误结果', () {
      final result = ApiResult<String>.error('发生错误', code: 500);

      expect(result.code, equals(500));
      expect(result.message, equals('发生错误'));
      expect(result.data, isNull);
      expect(result.timestamp, isNotNull);
      expect(result.isSuccess(), isFalse);
    });

    test('error() 不传 code 时应使用默认值 -1', () {
      final result = ApiResult<String>.error('发生错误');

      expect(result.code, equals(-1));
      expect(result.message, equals('发生错误'));
    });

    // ---------- toJson 测试 ----------

    test('toJson 应正确序列化（含 toJsonT）', () {
      const data = _TestData(id: 1, name: '张三');
      final result = ApiResult<_TestData>.success(data);

      final json = result.toJson(toJsonT: (d) => d.toJson());

      expect(json['code'], equals(200));
      expect(json['message'], equals('操作成功'));
      expect(json['data'], isA<Map<String, dynamic>>());
      expect((json['data'] as Map<String, dynamic>)['id'], equals(1));
      expect((json['data'] as Map<String, dynamic>)['name'], equals('张三'));
      expect(json['timestamp'], isNotNull);
    });

    test('toJson 不传 toJsonT 时应保留原始 data', () {
      final result = ApiResult<int>.success(42);

      final json = result.toJson();

      expect(json['code'], equals(200));
      expect(json['data'], equals(42));
    });

    test('toJson 当 data 为 null 时应映射为 null', () {
      final result = ApiResult<String>.error('错误');

      final json = result.toJson();

      expect(json['code'], equals(-1));
      expect(json['data'], isNull);
    });

    // ---------- toString 测试 ----------

    test('toString 应包含 code、message 和 data', () {
      const result = ApiResult<int>(code: 200, message: '成功', data: 42, timestamp: 1000);

      expect(
        result.toString(),
        equals('ApiResult(code: 200, message: 成功, data: 42, timestamp: 1000)'),
      );
    });
  });
}
