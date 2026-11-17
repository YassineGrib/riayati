import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/features/auth/auth_controller.dart';
import 'package:riayati/features/auth/auth_repository.dart';
import 'package:riayati/features/auth/user.dart';

import '../api/api_client_test.dart'
    show MemoryTokenStore, FakeAdapter, jsonResponse;

void main() {
  test('profile PUT preserves token and updates signed-in auth state from response', () async {
    final tokens = MemoryTokenStore()..token = 'current-session';
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((request) {
        if (request.method == 'PUT') {
          expect(request.path, '/me');
          expect(request.headers['Authorization'], 'Bearer current-session');
          expect(request.data, {
            'name': 'أمينة الجديدة',
            'email': 'new@example.com',
            'phone': '0555123456',
            'wilaya': 'الجزائر',
            'children_count': 2,
            'current_password': 'secret',
          });
          return jsonResponse(
            '{"user":{"id":1,"name":"أمينة الجديدة","email":"new@example.com","role":"mother","linked":false,"phone":"0555123456","wilaya":"الجزائر","children_count":2}}',
            200,
          );
        }
        return jsonResponse(
          '{"user":{"id":1,"name":"أمينة","email":"amina@example.com","role":"mother","linked":false}}',
          200,
        );
      });
    addTearDown(dio.close);
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokens),
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);
    await controller.refresh();
    await controller.updateProfile(
      name: 'أمينة الجديدة',
      email: 'new@example.com',
      phone: '0555123456',
      wilaya: 'الجزائر',
      childrenCount: 2,
      currentPassword: 'secret',
    );
    final user = container.read(authControllerProvider).user!;
    expect(user.name, 'أمينة الجديدة');
    expect(user.email, 'new@example.com');
    expect(user.phone, '0555123456');
    expect(user.wilaya, 'الجزائر');
    expect(user.childrenCount, 2);
    expect(tokens.token, 'current-session');
  });

  test('profile validation failure preserves user and repository omits unused password', () async {
    final tokens = MemoryTokenStore()..token = 'current-session';
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((request) {
        if (request.method == 'PUT') {
          expect(
            (request.data as Map).containsKey('current_password'),
            isFalse,
          );
          return jsonResponse(
            '{"errors":{"phone":["رقم الهاتف غير صالح"]}}',
            422,
          );
        }
        return jsonResponse(
          '{"user":{"id":1,"name":"أمينة","email":"amina@example.com","role":"mother","linked":false}}',
          200,
        );
      });
    addTearDown(dio.close);
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokens),
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);
    await controller.refresh();
    final before = container.read(authControllerProvider).user;
    await expectLater(
      controller.updateProfile(
        name: 'أمينة الجديدة',
        email: 'amina@example.com',
        phone: 'bad',
      ),
      throwsA(
        isA<ApiError>().having((e) => e.fields['phone'], 'phone field', [
          'رقم الهاتف غير صالح',
        ]),
      ),
    );
    expect(container.read(authControllerProvider).user, same(before));
    expect(tokens.token, 'current-session');
  });

  test('unlinked user retains optional profile details', () {
    final user = User.fromJson({
      'id': 1,
      'name': 'أمينة',
      'email': 'a@example.com',
      'role': 'mother',
      'linked': true,
      'partner_role': 'father',
      'phone': '0555123456',
      'wilaya': 'الجزائر',
      'children_count': 0,
    });
    final unlinked = user.unlinked();
    expect(unlinked.linked, isFalse);
    expect(unlinked.partnerRole, isNull);
    expect(unlinked.phone, user.phone);
    expect(unlinked.wilaya, user.wilaya);
    expect(unlinked.childrenCount, 0);
  });

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
