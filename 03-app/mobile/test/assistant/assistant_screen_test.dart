import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/api/token_store.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/assistant/assistant_screen.dart';

class _NoTokens implements TokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async {}
  @override
  Future<void> clear() async {}
}

class _FakeApi extends ApiClient {
  _FakeApi() : super(tokenStore: _NoTokens());
  final posted = <Map<String, dynamic>>[];
  Object? error;
  Map<String, dynamic> reply = {
    'answer': 'مساعد آلي، وليس محاميًا. هذه إجابة من النص.',
    'sufficient': true,
    'sources': [
      {'id': 7, 'title': 'نص تجريبي', 'reference': 'م 1', 'slug': 'text-1'},
    ],
  };

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    ProgressCallback? onSendProgress,
  }) async {
    expect(path, '/assistant');
    posted.add(Map<String, dynamic>.from(data! as Map));
    if (error != null) throw error!;
    return reply as T;
  }
}

Future<(_FakeApi, String?)> _pump(
  WidgetTester tester,
  Brightness brightness, {
  _FakeApi? api,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fake = api ?? _FakeApi();
  final pushed = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AssistantScreen()),
      GoRoute(
        path: '/library/:slug',
        builder: (_, s) {
          pushed.add(s.pathParameters['slug']!);
          return const Scaffold(body: Text('LIBRARY'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fake)],
      child: MaterialApp.router(
        theme: buildTheme(brightness),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (fake, pushed.isEmpty ? null : pushed.last);
}

void main() {
  testWidgets('shows the notice and examples, send is disabled when empty', (
    tester,
  ) async {
    await _pump(tester, Brightness.light);
    expect(find.textContaining('لا تكتب أسماء'), findsOneWidget);
    expect(find.text('أمثلة على الأسئلة'), findsOneWidget);
    final send = tester.widget<IconButton>(find.byKey(const ValueKey('assistant-send')));
    expect(send.onPressed, isNull);
  });

  testWidgets('sends only the question and shows answer with sources', (
    tester,
  ) async {
    final (api, _) = await _pump(tester, Brightness.light);
    await tester.enterText(find.byKey(const ValueKey('assistant-input')), 'ما مدة التسليم؟');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();
    expect(api.posted, [
      {'question': 'ما مدة التسليم؟'},
    ]);
    expect(find.text('ما مدة التسليم؟'), findsOneWidget);
    expect(find.textContaining('هذه إجابة من النص'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-source-7')), findsOneWidget);
  });

  testWidgets('tapping a source opens the library text', (tester) async {
    final (api, _) = await _pump(tester, Brightness.light);
    await tester.tap(find.text('كيف أستعمل التقويم المشترك للزيارات؟'));
    await tester.pumpAndSettle();
    expect(api.posted.length, 1);
    await tester.tap(find.byKey(const ValueKey('assistant-source-7')));
    await tester.pumpAndSettle();
    expect(find.text('LIBRARY'), findsOneWidget);
  });

  testWidgets('insufficient sources: no source chips', (tester) async {
    final api = _FakeApi()
      ..reply = {
        'answer': 'لا تتوفر لدي مصادر كافية في النصوص المدخلة للإجابة عن هذا السؤال.',
        'sufficient': false,
        'sources': [],
      };
    await _pump(tester, Brightness.light, api: api);
    await tester.enterText(find.byKey(const ValueKey('assistant-input')), 'سؤال');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();
    expect(find.textContaining('مصادر كافية'), findsOneWidget);
    expect(find.text('المصادر'), findsNothing);
  });

  testWidgets('503 shows the server message and retry asks again', (
    tester,
  ) async {
    final api = _FakeApi()
      ..error = const ApiError(
        message: 'المساعد غير متاح حاليًا، حاول لاحقًا.',
        status: 503,
      );
    await _pump(tester, Brightness.light, api: api);
    await tester.enterText(find.byKey(const ValueKey('assistant-input')), 'سؤال');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();
    expect(find.text('المساعد غير متاح حاليًا، حاول لاحقًا.'), findsOneWidget);
    api.error = null;
    await tester.tap(find.byKey(const ValueKey('assistant-retry')));
    await tester.pumpAndSettle();
    expect(api.posted.length, 2);
    expect(find.textContaining('هذه إجابة من النص'), findsOneWidget);
    expect(find.byKey(const ValueKey('assistant-retry')), findsNothing);
  });

  testWidgets('422 shows the question message', (tester) async {
    final api = _FakeApi()
      ..error = const ApiError(
        message: 'خطأ',
        status: 422,
        fields: {'question': ['السؤال طويل جدًا.']},
      );
    await _pump(tester, Brightness.light, api: api);
    await tester.enterText(find.byKey(const ValueKey('assistant-input')), 'سؤال');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('assistant-send')));
    await tester.pumpAndSettle();
    expect(find.text('السؤال طويل جدًا.'), findsOneWidget);
  });

  testWidgets('new conversation clears the thread', (tester) async {
    await _pump(tester, Brightness.light);
    await tester.ensureVisible(find.text('أين أجد الجهات المختصة في ولايتي؟'));
    await tester.tap(find.text('أين أجد الجهات المختصة في ولايتي؟'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('assistant-new')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('assistant-new')));
    await tester.pumpAndSettle();
    expect(find.text('أمثلة على الأسئلة'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic answer renders without overflow in $brightness', (
      tester,
    ) async {
      final api = _FakeApi()
        ..reply = {
          'answer': List.filled(30, 'هذه جملة طويلة جدًا لاختبار التفاف النص العربي').join(' '),
          'sufficient': true,
          'sources': [
            {
              'id': 1,
              'title': 'عنوان طويل جدًا لمصدر قانوني يحتاج إلى أكثر من سطر لعرضه كاملًا',
              'reference': 'مرجع طويل',
              'slug': 'a',
            },
          ],
        };
      await _pump(tester, brightness, api: api);
      await tester.tap(find.text('ما الذي تتضمنه المكتبة التعريفية؟'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
