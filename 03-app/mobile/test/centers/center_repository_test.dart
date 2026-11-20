import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/features/centers/center_repository.dart';
import 'package:riayati/features/centers/support_center.dart';

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
  group('CenterRepository', () {
    late MemoryTokenStore tokenStore;

    setUp(() {
      tokenStore = MemoryTokenStore();
    });

    test('list passes kind, wilaya, and search query parameters', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          captured = options;
          return jsonResponse(
            '{"data": [{"id": 1, "name": "محكمة سيدي امحمد", "kind": "court", "kind_label": "محكمة", "wilaya": "16"}]}',
            200,
          );
        });

      final repo = CenterRepository(ApiClient(tokenStore: tokenStore, dio: dio));
      final items = await repo.list(
        kind: CenterKind.court,
        wilaya: '16',
        query: 'سيدي امحمد',
      );

      expect(captured?.path, '/centers');
      expect(captured?.queryParameters['kind'], 'court');
      expect(captured?.queryParameters['wilaya'], '16');
      expect(captured?.queryParameters['q'], 'سيدي امحمد');
      expect(items.length, 1);
      expect(items.first.name, 'محكمة سيدي امحمد');
      expect(items.first.kind, CenterKind.court);
    });

    test('get fetches center by id', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          captured = options;
          return jsonResponse(
            '{"data": {"id": 10, "name": "الهيئة الوطنية لحماية الطفولة", "kind": "child_protection", "kind_label": "حماية الطفولة", "notes": "ملاحظات إضافية"}}',
            200,
          );
        });

      final repo = CenterRepository(ApiClient(tokenStore: tokenStore, dio: dio));
      final item = await repo.get(10);

      expect(captured?.path, '/centers/10');
      expect(item.id, 10);
      expect(item.notes, 'ملاحظات إضافية');
    });

    test('throws ApiError on failure', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          return jsonResponse('{"message": "المركز غير موجود"}', 404);
        });

      final repo = CenterRepository(ApiClient(tokenStore: tokenStore, dio: dio));
      expect(() => repo.get(999), throwsA(isA<ApiError>()));
    });
  });
}
