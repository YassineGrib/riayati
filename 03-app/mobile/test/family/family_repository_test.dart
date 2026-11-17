import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/features/auth/auth_controller.dart';
import 'package:riayati/features/family/family_repository.dart';

import '../api/api_client_test.dart'
    show FakeAdapter, MemoryTokenStore, jsonResponse;

void main() {
  test(
    'invite posts and parses server code and expiry; link refreshes me',
    () async {
      final requests = <String>[];
      var linked = false;
      final dio = Dio()
        ..httpClientAdapter = FakeAdapter((request) {
          requests.add('${request.method} ${request.path}');
          expect(request.headers['Authorization'], 'Bearer session');
          if (request.path == '/family/invite') {
            return jsonResponse(
              '{"code":"K7M-4Q2","expires_at":"2026-11-19T12:30:00Z"}',
              201,
            );
          }
          if (request.path == '/family/link') {
            expect(request.data, {'code': 'ABC-123'});
            linked = true;
            return jsonResponse('{"linked":true,"partner_role":"father"}', 200);
          }
          expect(request.path, '/me');
          return jsonResponse(
            jsonEncode({
              'user': {
                'id': 1,
                'name': 'أمينة',
                'email': 'a@example.com',
                'role': 'mother',
                'linked': linked,
                'partner_role': linked ? 'father' : null,
              },
            }),
            200,
          );
        });
      addTearDown(dio.close);
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(dio),
          tokenStoreProvider.overrideWithValue(
            MemoryTokenStore()..token = 'session',
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).refresh();
      final repository = container.read(familyRepositoryProvider);
      final invite = await repository.invite();
      expect(invite.code, 'K7M-4Q2');
      expect(invite.expiresAt, DateTime.utc(2026, 11, 19, 12, 30));
      await repository.link(' ABC-123 ');
      expect(container.read(authControllerProvider).user!.linked, isTrue);
      expect(requests, [
        'GET /me',
        'POST /family/invite',
        'POST /family/link',
        'GET /me',
      ]);
    },
  );

  test('rejected link preserves the server message without refreshing auth', () async {
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((request) {
        expect(request.path, '/family/link');
        return jsonResponse(
          '{"message":"رمز غير صالح","errors":{"code":["انتهت صلاحية الرمز"]}}',
          422,
        );
      });
    addTearDown(dio.close);
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        tokenStoreProvider.overrideWithValue(
          MemoryTokenStore()..token = 'session',
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(familyRepositoryProvider).link('BAD'),
      throwsA(
        isA<ApiError>()
            .having((e) => e.message, 'message', 'رمز غير صالح')
            .having((e) => e.fields['code'], 'code errors', [
              'انتهت صلاحية الرمز',
            ]),
      ),
    );
  });
}
