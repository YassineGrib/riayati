import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_error.dart';
import 'token_store.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  ref.onDispose(() => dio.close());
  return dio;
});
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    tokenStore: ref.watch(tokenStoreProvider),
    dio: ref.watch(dioProvider),
  ),
);

class ApiClient {
  ApiClient({required this.tokenStore, Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options.baseUrl = const String.fromEnvironment(
      'API_URL',
      defaultValue: 'http://10.0.2.2:8000/api',
    );
    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    _dio.options.headers['Accept'] = 'application/json';
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await tokenStore.read();
            options.headers.remove('Authorization');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            handler.next(options);
          } catch (error) {
            handler.reject(DioException(requestOptions: options, error: error));
          }
        },
      ),
    );
  }
  final Dio _dio;
  final TokenStore tokenStore;
  Future<void> Function()? onUnauthorized;
  void Function()? onNotLinked;
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _request(() => _dio.get<T>(path, queryParameters: queryParameters));
  Future<T> post<T>(
    String path, {
    Object? data,
    ProgressCallback? onSendProgress,
  }) => _request(
    () => _dio.post<T>(path, data: data, onSendProgress: onSendProgress),
  );
  Future<T> _request<T>(Future<Response<T>> Function() send) async {
    try {
      return (await send()).data as T;
    } on DioException catch (exception) {
      final error = ApiError.fromDio(exception);
      if (error.status == 401) {
        try {
          await tokenStore.clear();
        } finally {
          await onUnauthorized?.call();
        }
      }
      if (error.status == 403 && error.code == 'not_linked') {
        onNotLinked?.call();
      }
      throw error;
    }
  }
}
