/// 统一 API 响应模型
///
/// 对应后端 `ApiResult<T>` 响应体结构。
/// 使用泛型 T 支持不同数据类型的反序列化。
class ApiResult<T> {
  /// 创建成功结果的工厂方法
  factory ApiResult.success(T data, {String? message}) {
    return ApiResult<T>(
      code: 200,
      message: message ?? '操作成功',
      data: data,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 创建错误结果的工厂方法
  factory ApiResult.error(String message, {int? code}) {
    return ApiResult<T>(
      code: code ?? -1,
      message: message,
      data: null,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// 从 JSON 创建 ApiResult 实例
  ///
  /// [json] 原始 JSON Map
  /// [fromJsonT] 将 data 字段的 JSON 转换为 T 类型的函数
  factory ApiResult.fromJson(
    Map<String, dynamic> json, {
    T Function(Map<String, dynamic>)? fromJsonT,
  }) {
    T? data;
    if (fromJsonT != null && json['data'] != null) {
      if (json['data'] is Map<String, dynamic>) {
        data = fromJsonT(json['data'] as Map<String, dynamic>);
      }
    }
    return ApiResult<T>(
      code: json['code'] as int?,
      message: json['message'] as String?,
      data: data,
      timestamp: json['timestamp'] as int?,
    );
  }

  /// 从 JSON 创建包含列表数据的 ApiResult 实例
  factory ApiResult.fromJsonList(
    Map<String, dynamic> json, {
    required T Function(Map<String, dynamic>) fromJsonT,
  }) {
    final List<T> items = [];
    if (json['data'] != null && json['data'] is List) {
      for (final item in json['data'] as List) {
        if (item is Map<String, dynamic>) {
          items.add(fromJsonT(item));
        }
      }
    }
    return ApiResult<T>(
      code: json['code'] as int?,
      message: json['message'] as String?,
      data: items as T?,
      timestamp: json['timestamp'] as int?,
    );
  }

  /// 状态码（200 表示成功）
  final int? code;

  /// 提示信息
  final String? message;

  /// 响应数据
  final T? data;

  /// 时间戳
  final int? timestamp;

  const ApiResult({
    this.code,
    this.message,
    this.data,
    this.timestamp,
  });

  /// 判断请求是否成功（code == 200）
  bool isSuccess() => code == 200;

  /// 转换为 JSON Map
  Map<String, dynamic> toJson({Map<String, dynamic> Function(T)? toJsonT}) {
    return {
      'code': code,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() =>
      'ApiResult(code: $code, message: $message, data: $data, timestamp: $timestamp)';
}
