import 'package:flutter/material.dart';
import 'package:riayati/core/router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/auth/auth_controller.dart';

import '../api/api_client_test.dart'
    show MemoryTokenStore, FakeAdapter, jsonResponse;

void main() {
  test('login persists token; any 401 clears it and signs out', () async {
    final store = MemoryTokenStore();
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter(
        (request) => request.path == '/login'
            ? jsonResponse(
                '{"token":"secret","user":{"id":1,"name":"أحمد","email":"a@example.com","role":"father","linked":true,"partner_role":"mother"}}',
                200,
              )
            : jsonResponse('{"message":"انتهت الجلسة"}', 401),
      );
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);
    await controller.refresh();
    await controller.signIn(email: 'a@example.com', password: 'password');
    expect(store.token, 'secret');
    expect(container.read(authControllerProvider).status, AuthStatus.signedIn);
    expect(container.read(authControllerProvider).user!.partnerRole, 'mother');
    await expectLater(
      container.read(apiClientProvider).get<dynamic>('/reports'),
      throwsA(isA<ApiError>()),
    );
    expect(store.token, isNull);
    expect(container.read(authControllerProvider).status, AuthStatus.signedOut);
  });
  setUpAll(() => initializeDateFormatting('ar'));
  testWidgets('guards routes and reacts to not_linked and sign out', (
    tester,
  ) async {
    final store = MemoryTokenStore();
    var serverSaysNotLinked = false;
    final dio = Dio()
      ..httpClientAdapter = FakeAdapter((request) {
        if (request.path == '/login') {
          return jsonResponse(
            '{"token":"session","user":{"id":1,"name":"أحمد","email":"a@example.com","role":"father","linked":true}}',
            200,
          );
        }
        if (request.path == '/logout') return jsonResponse('{}', 200);
        // Real screens fetch their own data while the guard is exercised: stay
        // quiet (empty data) until the test deliberately makes the server say
        // the parent is not linked.
        if (serverSaysNotLinked) {
          return jsonResponse('{"code":"not_linked"}', 403);
        }
        return jsonResponse('{"data":[],"visits":[],"reports":[]}', 200);
      });
    final container = ProviderContainer(
      overrides: [
        tokenStoreProvider.overrideWithValue(store),
        dioProvider.overrideWithValue(dio),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(authControllerProvider.notifier);
    await controller.refresh();
    final router = container.read(routerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildTheme(Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    router.go('/calendar');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/welcome');
    router.go('/login');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/login');
    // Dio schedules interceptor work with timer-backed Futures. Run HTTP work
    // outside the widget test's fake clock, then pump the resulting redirects.
    await tester.runAsync(
      () => controller.signIn(email: 'a@example.com', password: 'password'),
    );
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    for (final path in [
      '/reports',
      '/reports/new',
      '/reports/1',
      '/calendar',
      '/assistant',
      '/profile',
    ]) {
      router.go(path);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, path);
      expect(tester.takeException(), isNull);
    }
    serverSaysNotLinked = true;
    await tester.runAsync(() async {
      await expectLater(
        container.read(apiClientProvider).get<dynamic>('/visits'),
        throwsA(isA<ApiError>()),
      );
    });
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/link');
    await tester.runAsync(controller.signOut);
    await tester.pumpAndSettle();
    expect(store.token, isNull);
    expect(router.routeInformationProvider.value.uri.path, '/welcome');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
