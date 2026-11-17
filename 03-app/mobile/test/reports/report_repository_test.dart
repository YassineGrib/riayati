import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/features/reports/file_rules.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/report_repository.dart';

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
  group('Report and ReportAttachment model parsing', () {
    test('parses report and attachments from API JSON', () {
      final json = {
        'id': 10,
        'reference': 'RIA-2026-0001',
        'status': 'under_review',
        'status_label': 'قيد المراجعة',
        'incident_at': '2026-11-15T10:30:00.000Z',
        'created_at': '2026-11-15T11:00:00.000Z',
        'attachments_count': 1,
        'description': 'حدثت مشكلة أثناء التسليم والتسلم',
        'attachments': [
          {
            'id': 101,
            'name': 'evidence.jpg',
            'mime': 'image/jpeg',
            'size': 204800,
            'sha256':
                'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
            'kind': 'image',
          },
        ],
      };

      final report = Report.fromJson(json);
      expect(report.id, equals(10));
      expect(report.reference, equals('RIA-2026-0001'));
      expect(report.status, equals(ReportStatus.underReview));
      expect(report.status.label, equals('قيد المراجعة'));
      expect(report.description, equals('حدثت مشكلة أثناء التسليم والتسلم'));
      expect(report.attachments.length, equals(1));

      final attachment = report.attachments.first;
      expect(attachment.id, equals(101));
      expect(attachment.filename, equals('evidence.jpg'));
      expect(attachment.mime, equals('image/jpeg'));
      expect(attachment.size, equals(204800));
      expect(
        attachment.sha256,
        equals(
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        ),
      );
    });

    test('parses reviewed status with Arabic label', () {
      final json = {
        'id': 11,
        'reference': 'RIA-2026-0002',
        'status': 'reviewed',
        'incident_at': '2026-11-10T09:00:00.000Z',
      };
      final report = Report.fromJson(json);
      expect(report.status, equals(ReportStatus.reviewed));
      expect(report.status.label, equals('تمت المراجعة'));
    });
  });

  group('ReportRepository', () {
    late MemoryTokenStore tokenStore;

    setUp(() {
      tokenStore = MemoryTokenStore();
    });

    test('create rejects 2-char description without any HTTP call', () async {
      var httpCalled = false;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          httpCalled = true;
          return jsonResponse('{}', 200);
        });
      final repo = ReportRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      await expectLater(
        repo.create(
          description: 'ab',
          incidentAt: DateTime.now().subtract(const Duration(hours: 1)),
          files: [],
        ),
        throwsA(
          isA<ApiError>().having((e) => e.fields.containsKey('description'),
              'has description error', isTrue),
        ),
      );

      expect(httpCalled, isFalse);
    });

    test('create rejects future date without any HTTP call', () async {
      var httpCalled = false;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          httpCalled = true;
          return jsonResponse('{}', 200);
        });
      final repo = ReportRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      await expectLater(
        repo.create(
          description: 'وصف كافٍ وواضح للواقعة',
          incidentAt: DateTime.now().add(const Duration(days: 1)),
          files: [],
        ),
        throwsA(
          isA<ApiError>().having((e) => e.fields.containsKey('incident_at'),
              'has incident_at error', isTrue),
        ),
      );

      expect(httpCalled, isFalse);
    });

    test('create sends multipart with description, incident_at, and files[]',
        () async {
      RequestOptions? capturedOptions;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          capturedOptions = options;
          return jsonResponse(
            '''
          {
            "report": {
              "id": 1,
              "reference": "RIA-2026-0001",
              "status": "under_review",
              "incident_at": "2026-11-17T12:00:00.000Z",
              "description": "تفاصيل الواقعة الموثقة هنا",
              "attachments": [
                {
                  "id": 1,
                  "name": "doc.pdf",
                  "mime": "application/pdf",
                  "size": 1024,
                  "sha256": "fakehash"
                }
              ]
            }
          }
          ''',
            201,
          );
        });

      final repo = ReportRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final tempDir = Directory.systemTemp.createTempSync('riayati_test_');
      final tempFile = File('${tempDir.path}/doc.pdf')
        ..writeAsStringSync('PDF content');

      final picked = PickedFile(
        path: tempFile.path,
        name: 'doc.pdf',
        size: 1024,
        mime: 'application/pdf',
      );

      final incidentTime = DateTime(2026, 11, 17, 12, 0);
      final report = await repo.create(
        description: 'تفاصيل الواقعة الموثقة هنا',
        incidentAt: incidentTime,
        files: [picked],
      );

      expect(report.id, equals(1));
      expect(report.reference, equals('RIA-2026-0001'));
      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, equals('/reports'));

      final formData = capturedOptions!.data as FormData;
      final descField =
          formData.fields.firstWhere((e) => e.key == 'description');
      expect(descField.value, equals('تفاصيل الواقعة الموثقة هنا'));

      final incidentField =
          formData.fields.firstWhere((e) => e.key == 'incident_at');
      expect(incidentField.value, equals(incidentTime.toIso8601String()));

      final filesList =
          formData.files.where((e) => e.key == 'files[]').toList();
      expect(filesList.length, equals(1));
      expect(filesList.first.value.filename, equals('doc.pdf'));

      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('list passes status query parameter when filtered', () async {
      String? queryStatus;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          queryStatus = options.queryParameters['status'] as String?;
          return jsonResponse('{"reports": []}', 200);
        });

      final repo = ReportRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      await repo.list(status: ReportStatus.reviewed);
      expect(queryStatus, equals('reviewed'));

      await repo.list();
      expect(queryStatus, isNull);
    });

    test('get returns single report', () async {
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/reports/42'));
          return jsonResponse(
            '''
          {
            "report": {
              "id": 42,
              "reference": "RIA-2026-0042",
              "status": "reviewed",
              "incident_at": "2026-11-10T12:00:00.000Z",
              "description": "تقرير مفصل"
            }
          }
          ''',
            200,
          );
        });

      final repo = ReportRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final report = await repo.get(42);
      expect(report.id, equals(42));
      expect(report.reference, equals('RIA-2026-0042'));
    });

    test('pdf downloads and writes file named reference.pdf', () async {
      final testTempDir =
          Directory.systemTemp.createTempSync('riayati_pdf_test_');

      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/reports/5/pdf'));
          return ResponseBody.fromString(
            '%PDF-1.4 mock binary stream',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/pdf'],
            },
          );
        });

      final repo = ReportRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
        tempDir: testTempDir,
      );

      final file = await repo.pdf(5);
      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('reference.pdf'), isTrue);
      expect(file.readAsStringSync(), contains('%PDF-1.4'));

      try {
        testTempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('attachmentLink calls API twice for two requests (never cached)',
        () async {
      var callCount = 0;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((options) {
          expect(options.path, equals('/reports/1/attachments/2/link'));
          callCount++;
          return jsonResponse(
            '{"url": "https://signed.url/file?call=$callCount", "expires_at": "2026-11-17T22:30:00Z"}',
            200,
          );
        });

      final repo = ReportRepository(
        ApiClient(tokenStore: tokenStore, dio: dio),
      );

      final uri1 = await repo.attachmentLink(1, 2);
      expect(uri1.toString(), contains('call=1'));

      final uri2 = await repo.attachmentLink(1, 2);
      expect(uri2.toString(), contains('call=2'));

      expect(callCount, equals(2));
    });

    test('reportRepositoryProvider resolves correctly', () {
      final container = ProviderContainer(
        overrides: [
          tokenStoreProvider.overrideWithValue(tokenStore),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(reportRepositoryProvider);
      expect(repo, isNotNull);
    });
  });
}
