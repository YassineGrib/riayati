import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/auth/auth_repository.dart';
import 'package:riayati/features/auth/user.dart';

import '../api/api_client_test.dart'
    show FakeAdapter, MemoryTokenStore, jsonResponse;

export '../api/api_client_test.dart' show jsonResponse;

Future<void>? _pendingRequest;

// Wait for the actual repository operation outside the widget test's fake
// clock: Dio schedules interceptor work with timer-backed Futures.
class _TrackedAuthRepository extends AuthRepository {
  _TrackedAuthRepository(super.api, super.tokens);

  Future<T> _track<T>(Future<T> operation) {
    _pendingRequest = operation.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return operation;
  }

  @override
  Future<User> signIn({required String email, required String password}) =>
      _track(super.signIn(email: email, password: password));

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required bool terms,
  }) => _track(
    super.register(
      name: name,
      email: email,
      password: password,
      role: role,
      terms: terms,
    ),
  );

  @override
  Future<void> forgotPassword(String email) =>
      _track(super.forgotPassword(email));
}

Future<void> pumpAuth(
  WidgetTester tester,
  Widget screen, {
  ResponseBody Function(RequestOptions)? respond,
  Brightness brightness = Brightness.light,
}) async {
  _pendingRequest = null;
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final dio = Dio()
    ..httpClientAdapter = FakeAdapter(
      respond ?? (_) => jsonResponse('{}', 200),
    );
  addTearDown(dio.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWithValue(MemoryTokenStore()),
        dioProvider.overrideWithValue(dio),
        authRepositoryProvider.overrideWith(
          (ref) => _TrackedAuthRepository(
            ref.watch(apiClientProvider),
            ref.watch(tokenStoreProvider),
          ),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildTheme(brightness),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder authButton(String label) => find.byWidgetPredicate(
  (widget) => widget is RButton && widget.label == label,
);

Future<void> tapAuthButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(authButton(label));
  await tester.runAsync(() async {
    await tester.tap(authButton(label));
    await _pendingRequest;
  });
  await tester.pumpAndSettle();
}

const longArabic =
    'عبد الرحمن محمد أمين بن عبد الله اسم طويل جدًا للاختبار مع Arabic123@example.com';
