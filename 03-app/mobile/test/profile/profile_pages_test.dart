import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/api/api_client.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/auth/auth_repository.dart';
import 'package:riayati/features/profile/change_password_screen.dart';
import 'package:riayati/features/profile/terms_screen.dart';
import 'package:riayati/features/profile/privacy_screen.dart';

import '../api/api_client_test.dart' show MemoryTokenStore;

class _Repository extends AuthRepository {
  _Repository()
    : super(ApiClient(tokenStore: MemoryTokenStore()), MemoryTokenStore());
  ApiError? error;
  List<String>? submitted;
  @override
  Future<void> changePassword({
    required String current,
    required String next,
    required String confirmation,
  }) async {
    submitted = [current, next, confirmation];
    if (error != null) throw error!;
  }
}

Future<GoRouter> _pump(
  WidgetTester tester,
  Widget page, {
  _Repository? repository,
}) async {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: Text('profile')),
      ),
      GoRoute(path: '/page', builder: (_, _) => page),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (repository != null)
          authRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildTheme(Brightness.light),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  router.push('/page');
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final page in [const TermsScreen(), const PrivacyScreen()]) {
    testWidgets(
      '${page.runtimeType} renders update date, serif body and back',
      (tester) async {
        final router = await _pump(tester, page);
        expect(
          find.text('آخر تحديث: نوفمبر 2026'),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.style?.fontFamily == 'ThmanyahSerifText',
          ),
          findsWidgets,
        );
        await tester.tap(find.byTooltip('رجوع'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/profile');
      },
    );
  }

  testWidgets(
    'password server errors appear beneath their fields, retry succeeds and returns',
    (tester) async {
      final repository = _Repository()
        ..error = const ApiError(
          message: 'تحقق من الحقول',
          status: 422,
          fields: {
            'current_password': ['الحالية غير صحيحة'],
            'password': ['الجديدة غير صالحة'],
            'password_confirmation': ['التأكيد غير مطابق'],
          },
        );
      final router = await _pump(
        tester,
        const ChangePasswordScreen(),
        repository: repository,
      );
      for (var i = 0; i < 3; i++) {
        await tester.enterText(
          find.byType(TextFormField).at(i),
          i == 0 ? 'old-password' : 'new-password',
        );
      }
      await tester.ensureVisible(find.text('حفظ كلمة المرور'));
      await tester.tap(find.text('حفظ كلمة المرور'));
      await tester.pumpAndSettle();
      expect(repository.submitted, [
        'old-password',
        'new-password',
        'new-password',
      ]);
      for (final message in [
        'الحالية غير صحيحة',
        'الجديدة غير صالحة',
        'التأكيد غير مطابق',
      ]) {
        expect(find.text(message), findsOneWidget);
      }
      expect(
        tester.getTopLeft(find.text('الحالية غير صحيحة')).dy,
        greaterThan(tester.getTopLeft(find.byType(TextFormField).first).dy),
      );
      repository.error = null;
      await tester.ensureVisible(find.text('حفظ كلمة المرور'));
      await tester.tap(find.text('حفظ كلمة المرور'));
      await tester.pumpAndSettle();
      expect(find.text('تم تغيير كلمة المرور بنجاح.'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/profile');
    },
  );
}
