import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/assistant/assistant_screen.dart';

class _NoTokens implements TokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async => throw StateError('No token writes');
  @override
  Future<void> clear() async => throw StateError('No token changes');
}

class _NoNetworkApi extends ApiClient {
  _NoNetworkApi() : super(tokenStore: _NoTokens());
  int calls = 0;
  Never _fail(String path) {
    calls++;
    throw StateError('Assistant must never call the API: $path');
  }

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _fail(path);
  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    ProgressCallback? onSendProgress,
  }) => _fail(path);
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('private coming-soon UI cannot send in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = _NoNetworkApi();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiClientProvider.overrideWithValue(api)],
          child: MaterialApp(
            theme: buildTheme(brightness),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const AssistantScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('لا تكتب أسماء أو تفاصيل القضية'),
        findsOneWidget,
      );
      expect(find.text('قريبًا'), findsOneWidget);
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.enabled, isFalse);
      expect(input.onSubmitted, isNull);
      expect(input.onChanged, isNull);
      for (final question in [
        'من الأحق بحضانة الطفل؟',
        'كيف تُنظَّم زيارة الطفل؟',
        'ما الذي تشمله نفقة الأولاد؟',
      ]) {
        await tester.ensureVisible(find.text(question));
        await tester.tap(find.text(question));
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byType(TextField));
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      final send = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.send_outlined),
      );
      expect(send.onPressed, isNull);
      expect(api.calls, 0);
      expect(tester.takeException(), isNull);
    });
  }
}
