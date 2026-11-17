import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/features/auth/auth_repository.dart';

import '../api/api_client_test.dart'
    show MemoryTokenStore, FakeAdapter, jsonResponse;

void main() {
  test(
    'change password sends authenticated PUT and preserves current token',
    () async {
      final tokens = MemoryTokenStore()..token = 'current-session';
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((request) {
          expect(request.method, 'PUT');
          expect(request.path, '/password');
          expect(request.headers['Authorization'], 'Bearer current-session');
          expect(request.data, {
            'current_password': 'old-password',
            'password': 'new-password',
            'password_confirmation': 'new-password',
          });
          return jsonResponse('{}', 200);
        });
      addTearDown(dio.close);
      await AuthRepository(
        ApiClient(tokenStore: tokens, dio: dio),
        tokens,
      ).changePassword(
        current: 'old-password',
        next: 'new-password',
        confirmation: 'new-password',
      );
      expect(tokens.token, 'current-session');
    },
  );

  test('change password preserves Arabic server field errors', () async {
    final tokens = MemoryTokenStore()..token = 'current-session';
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter(
        (_) => jsonResponse(
          '{"errors":{"current_password":["كلمة المرور الحالية غير صحيحة."]}}',
          422,
        ),
      );
    addTearDown(dio.close);
    await expectLater(
      AuthRepository(
        ApiClient(tokenStore: tokens, dio: dio),
        tokens,
      ).changePassword(
        current: 'wrong',
        next: 'new-password',
        confirmation: 'new-password',
      ),
      throwsA(
        isA<ApiError>().having(
          (e) => e.fields['current_password'],
          'current field',
          ['كلمة المرور الحالية غير صحيحة.'],
        ),
      ),
    );
    expect(tokens.token, 'current-session');
  });

  for (final status in [200, 500]) {
    test('real API logout clears token after HTTP $status', () async {
      final tokens = MemoryTokenStore()..token = 'current-session';
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((request) {
          expect(request.path, '/logout');
          expect(request.headers['Authorization'], 'Bearer current-session');
          return jsonResponse('{}', status);
        });
      addTearDown(dio.close);
      await AuthRepository(
        ApiClient(tokenStore: tokens, dio: dio),
        tokens,
      ).signOut();
      expect(tokens.token, isNull);
    });
  }
}
