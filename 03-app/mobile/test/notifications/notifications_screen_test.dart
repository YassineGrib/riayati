import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/features/calendar/visit.dart';
import 'package:riayati/features/calendar/visit_repository.dart';
import 'package:riayati/features/notifications/notifications_screen.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/report_repository.dart';

class FakeVisitRepo extends Fake implements VisitRepository {
  List<Visit> visits = [];
  Object? error;
  int upcomingCalls = 0;

  @override
  Future<List<Visit>> upcoming() async {
    upcomingCalls++;
    if (error != null) throw error!;
    return visits;
  }
}

class FakeReportRepo extends Fake implements ReportRepository {
  List<Report> reports = [];
  Object? error;
  int listCalls = 0;

  @override
  Future<List<Report>> list({ReportStatus? status}) async {
    listCalls++;
    if (error != null) throw error!;
    if (status != null) {
      return reports.where((r) => r.status == status).toList();
    }
    return reports;
  }
}

Future<void> pumpNotifications(
  WidgetTester tester, {
  required FakeVisitRepo visitRepo,
  required FakeReportRepo reportRepo,
  List<String>? pushedRoutes,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/calendar/:id',
        builder: (_, state) {
          pushedRoutes?.add('/calendar/${state.pathParameters['id']}');
          return Scaffold(body: Text('visit ${state.pathParameters['id']}'));
        },
      ),
      GoRoute(
        path: '/reports/:id',
        builder: (_, state) {
          pushedRoutes?.add('/reports/${state.pathParameters['id']}');
          return Scaffold(body: Text('report ${state.pathParameters['id']}'));
        },
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) {
          pushedRoutes?.add('/home');
          return const Scaffold(body: Text('home screen'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        visitRepositoryProvider.overrideWithValue(visitRepo),
        reportRepositoryProvider.overrideWithValue(reportRepo),
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
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('displays items from visit and report repositories', (tester) async {
    final visitRepo = FakeVisitRepo()
      ..visits = [
        const Visit(
          id: 101,
          date: '2026-11-20',
          from: '10:00',
          to: '12:00',
          status: VisitStatus.proposed,
          proposedByMe: false,
          needsMyResponse: true,
          canConfirm: false,
        ),
        const Visit(
          id: 102,
          date: '2026-11-22',
          from: '14:00',
          to: '16:00',
          status: VisitStatus.accepted,
          proposedByMe: true,
          needsMyResponse: false,
          canConfirm: true,
        ),
        const Visit(
          id: 103,
          date: '2026-11-25',
          from: '09:00',
          to: '11:00',
          status: VisitStatus.confirmed,
          proposedByMe: false,
          needsMyResponse: false,
          canConfirm: false,
        ),
        const Visit(
          id: 104,
          date: '2026-11-26',
          from: '09:00',
          to: '11:00',
          status: VisitStatus.declined,
          proposedByMe: true,
          needsMyResponse: false,
          canConfirm: false,
        ),
      ];

    final reportRepo = FakeReportRepo()
      ..reports = [
        Report(
          id: 201,
          reference: 'RIA-2026-0099',
          status: ReportStatus.reviewed,
          incidentAt: DateTime(2026, 11, 15, 10, 0),
        ),
        Report(
          id: 202,
          reference: 'RIA-2026-0100',
          status: ReportStatus.underReview,
          incidentAt: DateTime(2026, 11, 16, 10, 0),
        ),
      ];

    final pushed = <String>[];
    await pumpNotifications(tester, visitRepo: visitRepo, reportRepo: reportRepo, pushedRoutes: pushed);

    expect(find.text('طلب زيارة جديد بانتظار ردك'), findsOneWidget);
    expect(find.text('وافق الطرف الآخر، أكّد الزيارة'), findsOneWidget);
    expect(find.text('تم تأكيد الزيارة'), findsOneWidget);
    expect(find.text('رُفضت زيارتك'), findsOneWidget);
    expect(find.text('تمت مراجعة بلاغك RIA-2026-0099'), findsOneWidget);
    // under_review report should not be shown as notification
    expect(find.text('تمت مراجعة بلاغك RIA-2026-0100'), findsNothing);

    // Tap visit notification
    await tester.tap(find.text('طلب زيارة جديد بانتظار ردك'));
    await tester.pumpAndSettle();
    expect(pushed, contains('/calendar/101'));
  });

  testWidgets('tapping report notification navigates to /reports/:id', (tester) async {
    final visitRepo = FakeVisitRepo()..visits = [];
    final reportRepo = FakeReportRepo()
      ..reports = [
        Report(
          id: 201,
          reference: 'RIA-2026-0099',
          status: ReportStatus.reviewed,
          incidentAt: DateTime(2026, 11, 15, 10, 0),
        ),
      ];

    final pushed = <String>[];
    await pumpNotifications(tester, visitRepo: visitRepo, reportRepo: reportRepo, pushedRoutes: pushed);

    await tester.tap(find.text('تمت مراجعة بلاغك RIA-2026-0099'));
    await tester.pumpAndSettle();
    expect(pushed, contains('/reports/201'));
  });

  testWidgets('shows empty state when no notifications exist', (tester) async {
    final visitRepo = FakeVisitRepo()..visits = [];
    final reportRepo = FakeReportRepo()..reports = [];

    await pumpNotifications(tester, visitRepo: visitRepo, reportRepo: reportRepo);

    expect(find.text('لا توجد إشعارات'), findsOneWidget);
  });

  testWidgets('shows empty state when not_linked error is received', (tester) async {
    final visitRepo = FakeVisitRepo()
      ..error = const ApiError(message: 'الحساب غير مرتبط', code: 'not_linked');
    final reportRepo = FakeReportRepo()..reports = [];

    await pumpNotifications(tester, visitRepo: visitRepo, reportRepo: reportRepo);

    expect(find.text('لا توجد إشعارات'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('shows error view with retry when API fails', (tester) async {
    final visitRepo = FakeVisitRepo()
      ..error = const ApiError(message: 'خطأ في الخادم', status: 500);
    final reportRepo = FakeReportRepo()..reports = [];

    await pumpNotifications(tester, visitRepo: visitRepo, reportRepo: reportRepo);

    expect(find.byType(ErrorView), findsOneWidget);

    visitRepo.error = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('لا توجد إشعارات'), findsOneWidget);
  });

  testWidgets('back arrow pops or falls back to /home', (tester) async {
    final visitRepo = FakeVisitRepo()..visits = [];
    final reportRepo = FakeReportRepo()..reports = [];
    final pushed = <String>[];

    await pumpNotifications(tester, visitRepo: visitRepo, reportRepo: reportRepo, pushedRoutes: pushed);

    final backBtn = find.byTooltip('رجوع');
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(pushed, contains('/home'));
  });
}
