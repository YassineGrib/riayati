import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';

class MemoryTokenStore implements TokenStore {
  String? token;
  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<void> clear() async {
    token = null;
  }
}

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

void main() {
  test('adds bearer token and exposes not_linked', () async {
    final store = MemoryTokenStore()..token = 'secret';
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((request) {
        expect(request.headers['Authorization'], 'Bearer secret');
        return jsonResponse(
          '{"code":"not_linked","message":"اربط الحساب"}',
          403,
        );
      });
    final api = ApiClient(tokenStore: store, dio: dio);
    await expectLater(
      api.get<dynamic>('/visits'),
      throwsA(
        isA<ApiError>()
            .having((e) => e.code, 'code', 'not_linked')
            .having((e) => e.status, 'status', 403),
      ),
    );
  });
  test('network failure has fixed Arabic message', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((request) {
        throw DioException(
          requestOptions: request,
          type: DioExceptionType.connectionError,
        );
      });
    await expectLater(
      ApiClient(tokenStore: MemoryTokenStore(), dio: dio).get<dynamic>('/me'),
      throwsA(
        isA<ApiError>().having(
          (e) => e.message,
          'message',
          ApiError.offlineMessage,
        ),
      ),
    );
  });
  test('422 preserves Arabic validation fields', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter(
        (_) => jsonResponse(
          '{"message":"راجع البيانات","errors":{"email":["البريد غير صالح"]}}',
          422,
        ),
      );
    await expectLater(
      ApiClient(
        tokenStore: MemoryTokenStore(),
        dio: dio,
      ).post<dynamic>('/login'),
      throwsA(
        isA<ApiError>().having((e) => e.fields['email'], 'email', [
          'البريد غير صالح',
        ]),
      ),
    );
  });
}
