import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/features/library/content_item.dart';
import 'package:riayati/features/library/content_repository.dart';

class MemoryTokenStore implements TokenStore {
  String? token = 'test-token';
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
  group('ContentRepository', () {
    late MemoryTokenStore tokenStore;

    setUp(() {
      tokenStore = MemoryTokenStore();
    });

    test('list passes query parameters and parses list', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          captured = options;
          return jsonResponse(
            '{"data": [{"id": 1, "type": "law", "type_label": "قانون", "title": "شروط الحضانة", "slug": "custody-rules"}], "current_page": 2}',
            200,
          );
        });

      final repo = ContentRepository(ApiClient(tokenStore: tokenStore, dio: dio));
      final items = await repo.list(type: ContentType.law, query: 'حضانة', page: 2);

      expect(captured?.path, '/contents');
      expect(captured?.queryParameters['type'], 'law');
      expect(captured?.queryParameters['q'], 'حضانة');
      expect(captured?.queryParameters['page'], 2);
      expect(items.length, 1);
      expect(items.first.title, 'شروط الحضانة');
      expect(items.first.type, ContentType.law);
    });

    test('get fetches item by slug', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          captured = options;
          return jsonResponse(
            '{"data": {"id": 1, "type": "law", "type_label": "قانون", "title": "شروط الحضانة", "slug": "custody-rules", "body": "نص القانون"}}',
            200,
          );
        });

      final repo = ContentRepository(ApiClient(tokenStore: tokenStore, dio: dio));
      final item = await repo.get('custody-rules');

      expect(captured?.path, '/contents/custody-rules');
      expect(item.id, 1);
      expect(item.body, 'نص القانون');
    });

    test('throws ApiError on error response', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          return jsonResponse('{"message": "المحتوى غير موجود"}', 404);
        });

      final repo = ContentRepository(ApiClient(tokenStore: tokenStore, dio: dio));
      expect(() => repo.get('not-found'), throwsA(isA<ApiError>()));
    });
  });
}
