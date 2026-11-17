import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/features/calendar/visit.dart';
import 'package:riayati/features/calendar/visit_repository.dart';

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
  group('Visit model parsing', () {
    test('parses full visit JSON with flags and timeline', () {
      final json = {
        'id': 100,
        'date': '2026-11-20',
        'from': '10:00',
        'to': '14:00',
        'starts_at': '2026-11-20T10:00:00.000Z',
        'ends_at': '2026-11-20T14:00:00.000Z',
        'note': 'زيارة حديقة التجارب',
        'status': 'proposed',
        'status_label': 'بانتظار الرد',
        'proposed_by_me': false,
        'needs_my_response': true,
        'can_confirm': false,
        'timeline': [
          {'step': 'proposed', 'at': '2026-11-17T09:00:00.000Z'},
        ],
      };

      final visit = Visit.fromJson(json);
      expect(visit.id, equals(100));
      expect(visit.date, equals('2026-11-20'));
      expect(visit.from, equals('10:00'));
      expect(visit.to, equals('14:00'));
      expect(visit.note, equals('زيارة حديقة التجارب'));
      expect(visit.status, equals(VisitStatus.proposed));
      expect(visit.status.label, equals('بانتظار الرد'));
      expect(visit.proposedByMe, isFalse);
      expect(visit.needsMyResponse, isTrue);
      expect(visit.canConfirm, isFalse);
      expect(visit.timeline.length, equals(1));
      expect(visit.timeline.first.step, equals('proposed'));
      expect(
        visit.timeline.first.at,
        equals(DateTime.parse('2026-11-17T09:00:00.000Z')),
      );
    });

    test('parses all visit statuses with Arabic labels', () {
      expect(VisitStatus.proposed.label, equals('بانتظار الرد'));
      expect(VisitStatus.accepted.label, equals('تم القبول'));
      expect(VisitStatus.declined.label, equals('مرفوضة'));
      expect(VisitStatus.confirmed.label, equals('مؤكدة'));

      expect(VisitStatus.fromValue('proposed'), equals(VisitStatus.proposed));
      expect(VisitStatus.fromValue('accepted'), equals(VisitStatus.accepted));
      expect(VisitStatus.fromValue('declined'), equals(VisitStatus.declined));
      expect(VisitStatus.fromValue('confirmed'), equals(VisitStatus.confirmed));
    });
  });

  group('VisitRepository', () {
    late MemoryTokenStore tokenStore;

    setUp(() {
      tokenStore = MemoryTokenStore();
    });

    test('month passes Y-m query parameter', () async {
      String? queriedMonth;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/visits'));
          queriedMonth = options.queryParameters['month'] as String?;
          return jsonResponse('{"month": "2026-11", "visits": []}', 200);
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final visits = await repo.month('2026-11');
      expect(queriedMonth, equals('2026-11'));
      expect(visits, isEmpty);
    });

    test('upcoming fetches active upcoming visits', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/visits/upcoming'));
          return jsonResponse(
            '''
          {
            "visits": [
              {
                "id": 1,
                "date": "2026-11-25",
                "from": "16:00",
                "to": "18:00",
                "status": "confirmed",
                "status_label": "مؤكدة",
                "proposed_by_me": true,
                "needs_my_response": false,
                "can_confirm": false,
                "timeline": []
              }
            ]
          }
          ''',
            200,
          );
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final visits = await repo.upcoming();
      expect(visits.length, equals(1));
      expect(visits.first.id, equals(1));
      expect(visits.first.status, equals(VisitStatus.confirmed));
    });

    test('get fetches a single visit by id', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/visits/42'));
          return jsonResponse(
            '''
          {
            "visit": {
              "id": 42,
              "date": "2026-11-26",
              "from": "10:00",
              "to": "12:00",
              "status": "accepted",
              "status_label": "تم القبول",
              "proposed_by_me": true,
              "needs_my_response": false,
              "can_confirm": true,
              "timeline": []
            }
          }
          ''',
            200,
          );
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final visit = await repo.get(42);
      expect(visit.id, equals(42));
      expect(visit.canConfirm, isTrue);
    });

    test('propose sends date, from, to, note and returns created visit',
        () async {
      Map<String, dynamic>? postedData;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/visits'));
          postedData = options.data as Map<String, dynamic>?;
          return jsonResponse(
            '''
          {
            "visit": {
              "id": 50,
              "date": "2026-11-28",
              "from": "09:00",
              "to": "12:00",
              "note": "موعد الأسبوع القادم",
              "status": "proposed",
              "proposed_by_me": true,
              "needs_my_response": false,
              "can_confirm": false,
              "timeline": []
            }
          }
          ''',
            201,
          );
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final visit = await repo.propose(
        date: '2026-11-28',
        from: '09:00',
        to: '12:00',
        note: 'موعد الأسبوع القادم',
      );

      expect(postedData, isNotNull);
      expect(postedData!['date'], equals('2026-11-28'));
      expect(postedData!['from'], equals('09:00'));
      expect(postedData!['to'], equals('12:00'));
      expect(postedData!['note'], equals('موعد الأسبوع القادم'));
      expect(visit.id, equals(50));
    });

    test('accept posts to /visits/{id}/accept', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/visits/10/accept'));
          return jsonResponse(
            '''
          {
            "visit": {
              "id": 10,
              "date": "2026-11-28",
              "from": "09:00",
              "to": "12:00",
              "status": "accepted",
              "proposed_by_me": false,
              "needs_my_response": false,
              "can_confirm": false,
              "timeline": []
            }
          }
          ''',
            200,
          );
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final visit = await repo.accept(10);
      expect(visit.status, equals(VisitStatus.accepted));
    });

    test('decline posts to /visits/{id}/decline', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/visits/10/decline'));
          return jsonResponse(
            '''
          {
            "visit": {
              "id": 10,
              "date": "2026-11-28",
              "from": "09:00",
              "to": "12:00",
              "status": "declined",
              "proposed_by_me": false,
              "needs_my_response": false,
              "can_confirm": false,
              "timeline": []
            }
          }
          ''',
            200,
          );
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final visit = await repo.decline(10);
      expect(visit.status, equals(VisitStatus.declined));
    });

    test('confirm posts to /visits/{id}/confirm', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/visits/10/confirm'));
          return jsonResponse(
            '''
          {
            "visit": {
              "id": 10,
              "date": "2026-11-28",
              "from": "09:00",
              "to": "12:00",
              "status": "confirmed",
              "proposed_by_me": true,
              "needs_my_response": false,
              "can_confirm": false,
              "timeline": []
            }
          }
          ''',
            200,
          );
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final visit = await repo.confirm(10);
      expect(visit.status, equals(VisitStatus.confirmed));
    });

    test('403 with code not_linked surfaces unchanged as ApiError', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          return jsonResponse(
            '{"code": "not_linked", "message": "يجب ربط الحساب مع الطرف الآخر"}',
            403,
          );
        });

      final repo = VisitRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      await expectLater(
        repo.upcoming(),
        throwsA(
          isA<ApiError>()
              .having((e) => e.status, 'status', 403)
              .having((e) => e.code, 'code', 'not_linked')
              .having((e) => e.message, 'message',
                  'يجب ربط الحساب مع الطرف الآخر'),
        ),
      );
    });

    test('visitRepositoryProvider resolves correctly', () {
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(visitRepositoryProvider);
      expect(repo, isNotNull);
    });
  });
}
