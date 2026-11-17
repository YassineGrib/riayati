import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/reports/report_detail_screen.dart';
import 'package:riayati/features/reports/report_repository.dart';

import 'screen_test_support.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));
  Future<GoRouter> pump(WidgetTester tester, String start) async {
    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(
          path: '/reports',
          builder: (_, _) => const Scaffold(body: Text('LIST')),
        ),
        GoRoute(
          path: '/reports/:id',
          builder: (_, state) =>
              ReportDetailScreen(int.parse(state.pathParameters['id']!)),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [reportRepositoryProvider.overrideWithValue(FakeReports())],
        child: MaterialApp.router(
          theme: buildTheme(Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('back pops to the list when the detail was pushed', (
    tester,
  ) async {
    final router = await pump(tester, '/reports');
    unawaited(router.push('/reports/7'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('LIST'), findsOneWidget);
    expect(find.byType(ReportDetailScreen), findsNothing);
  });

  testWidgets('back goes to /reports when there is nothing to pop', (
    tester,
  ) async {
    final router = await pump(tester, '/reports/7');
    expect(router.canPop(), isFalse);
    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();
    expect(find.text('LIST'), findsOneWidget);
  });
}

void unawaited(Future<void> future) {}
