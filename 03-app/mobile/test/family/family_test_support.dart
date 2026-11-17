import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/core/router.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/auth/auth_controller.dart';

import '../api/api_client_test.dart' show MemoryTokenStore;

// Immediate API responses keep widget tests independent of Dio's real timers.
// The repository tests exercise Dio and the HTTP contract separately.
class FamilyTestApi extends ApiClient {
  FamilyTestApi() : super(tokenStore: MemoryTokenStore());

  bool linked = false;
  ApiError? inviteError;
  ApiError? linkError;
  int invites = 0;
  final linkedCodes = <String>[];

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) async {
    if (path != '/me') throw StateError('Unexpected GET $path');
    return <String, dynamic>{
      'user': {
        'id': 1,
        'name': 'أمينة',
        'email': 'amina@example.com',
        'role': 'mother',
        'linked': linked,
        'partner_role': linked ? 'father' : null,
      },
    } as T;
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    ProgressCallback? onSendProgress,
  }) async {
    if (path == '/family/invite') {
      invites++;
      if (inviteError != null) throw inviteError!;
      return <String, dynamic>{
        'code': 'K7M-4Q2',
        'expires_at': '2026-11-19T12:30:00Z',
      } as T;
    }
    if (path == '/family/link') {
      linkedCodes.add((data as Map<String, dynamic>)['code'] as String);
      if (linkError != null) throw linkError!;
      linked = true;
      return <String, dynamic>{'linked': true, 'partner_role': 'father'} as T;
    }
    if (path == '/logout') return <String, dynamic>{} as T;
    throw StateError('Unexpected POST $path');
  }
}

Future<ProviderContainer> pumpFamilyApp(
  WidgetTester tester,
  FamilyTestApi api, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      apiClientProvider.overrideWithValue(api),
      tokenStoreProvider.overrideWithValue(
        MemoryTokenStore()..token = 'session',
      ),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authControllerProvider.notifier).refresh();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: buildTheme(brightness),
        routerConfig: container.read(routerProvider),
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> tapFamilyButton(WidgetTester tester, String label) async {
  // Text editing schedules the parent's rebuild. Apply it before hit testing
  // buttons whose enabled state depends on the newly entered code.
  await tester.pump();
  final button = find.byWidgetPredicate(
    (widget) => widget is RButton && widget.label == label,
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}
