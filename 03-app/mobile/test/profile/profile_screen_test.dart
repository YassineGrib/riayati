import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/auth/auth_controller.dart';
import 'package:riayati/features/auth/user.dart';
import 'package:riayati/features/profile/profile_screen.dart';

class _Tokens implements TokenStore {
  String? value = 'session-token';
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async => value = token;
  @override
  Future<void> clear() async => value = null;
}

class _Api extends ApiClient {
  _Api(TokenStore tokens) : super(tokenStore: tokens);
  final calls = <String>[];
  bool offline = false;

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      throw StateError('Unexpected GET $path');

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    ProgressCallback? onSendProgress,
  }) async {
    calls.add(path);
    if (path != '/logout' || offline) throw StateError('Request failed');
    return <String, dynamic>{} as T;
  }
}

class _SignedInAuth extends AuthController {
  _SignedInAuth(this.user);
  final User user;
  @override
  AuthState build() {
    super.build();
    return AuthState.signedIn(user);
  }
}

User _user({
  String name = 'أمينة',
  String role = 'mother',
  bool linked = true,
}) => User.fromJson({
  'id': 1,
  'name': name,
  'email': 'amina@example.com',
  'role': role,
  'linked': linked,
  'partner_role': role == 'mother' ? 'father' : 'mother',
  'partner_name': 'اسم الطرف الآخر',
  'partner_email': 'partner@example.com',
});

Future<ProviderContainer> _pump(
  WidgetTester tester,
  User user,
  _Tokens tokens,
  _Api api, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      tokenStoreProvider.overrideWithValue(tokens),
      apiClientProvider.overrideWithValue(api),
      authControllerProvider.overrideWith(() => _SignedInAuth(user)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(brightness),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const ProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _askToSignOut(WidgetTester tester) async {
  final button = find.widgetWithText(TextButton, 'تسجيل الخروج');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  for (final role in ['mother', 'father']) {
    testWidgets('shows only own identity and partner role for $role', (
      tester,
    ) async {
      final tokens = _Tokens();
      final api = _Api(tokens);
      await _pump(tester, _user(role: role), tokens, api);
      expect(find.text('أمينة'), findsOneWidget);
      expect(find.text('amina@example.com'), findsOneWidget);
      expect(find.text(role == 'mother' ? 'أم' : 'أب'), findsOneWidget);
      expect(
        find.text(role == 'mother' ? 'مرتبط بالأب' : 'مرتبط بالأم'),
        findsOneWidget,
      );
      expect(find.text('اسم الطرف الآخر'), findsNothing);
      expect(find.text('partner@example.com'), findsNothing);
      expect(api.calls, isEmpty);
    });
  }

  testWidgets('unlinked status does not imply a partner', (tester) async {
    final tokens = _Tokens();
    await _pump(tester, _user(linked: false), tokens, _Api(tokens));
    expect(find.text('لم يتم الربط بعد.'), findsOneWidget);
    expect(find.textContaining('مرتبط بالأب'), findsNothing);
  });

  for (final offline in [false, true]) {
    testWidgets(
      'sign-out confirms then clears auth and token (offline: $offline)',
      (tester) async {
        final tokens = _Tokens();
        final api = _Api(tokens)..offline = offline;
        final container = await _pump(tester, _user(), tokens, api);
        await _askToSignOut(tester);
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          container.read(authControllerProvider).status,
          AuthStatus.signedIn,
        );
        expect(api.calls, isEmpty);
        expect(tokens.value, 'session-token');
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();
        expect(
          container.read(authControllerProvider).status,
          AuthStatus.signedIn,
        );
        expect(api.calls, isEmpty);
        await _askToSignOut(tester);
        await tester.tap(find.text('تأكيد الخروج'));
        await tester.pumpAndSettle();
        expect(api.calls, ['/logout']);
        expect(tokens.value, isNull);
        expect(
          container.read(authControllerProvider).status,
          AuthStatus.signedOut,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('40-character Arabic name fits in $brightness', (tester) async {
      final name = List.filled(40, 'م').join();
      final tokens = _Tokens();
      await _pump(
        tester,
        _user(name: name),
        tokens,
        _Api(tokens),
        brightness: brightness,
      );
      expect(find.text(name), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('الإصدار 1.0.0'));
      expect(tester.takeException(), isNull);
    });
  }
}
