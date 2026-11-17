import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({
    required this.message,
    this.status,
    this.code,
    this.fields = const {},
  });
  static const offlineMessage =
      'تعذر الاتصال بالخادم. تحقق من اتصالك وحاول مجددًا.';
  final String message;
  final int? status;
  final String? code;
  final Map<String, List<String>> fields;
  factory ApiError.fromDio(DioException error) {
    final data = error.response?.data;
    final json = data is Map ? data : const {};
    final errors = json['errors'];
    return ApiError(
      message: json['message'] is String
          ? json['message'] as String
          : error.response == null
          ? offlineMessage
          : 'تعذر إتمام الطلب. حاول مجددًا.',
      status: error.response?.statusCode,
      code: json['code'] is String ? json['code'] as String : null,
      fields: errors is Map
          ? errors.map(
              (key, value) => MapEntry(
                key.toString(),
                value is List
                    ? value.map((e) => e.toString()).toList()
                    : [value.toString()],
              ),
            )
          : const {},
    );
  }
  @override
  String toString() => message;
}
