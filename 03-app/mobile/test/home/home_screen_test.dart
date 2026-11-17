import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/watermark.dart';
import 'package:riayati/features/auth/auth_controller.dart';
import 'package:riayati/features/auth/user.dart';
import 'package:riayati/features/calendar/visit.dart';
import 'package:riayati/features/calendar/visit_repository.dart';
import 'package:riayati/features/home/home_screen.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/report_repository.dart';

const longArabic = 'نص عربي طويل جدًا للتأكد من عدم حدوث تجاوز في الحاويات أو البطاقات أو القوائم ';

Visit sampleVisit({bool long = false}) => Visit(
  id: 1,
  date: '2026-11-20',
  from: '10:00',
  to: '14:00',
  note: long ? List.filled(40, longArabic).join() : 'زيارة اعتيادية',
  status: VisitStatus.proposed,
  proposedByMe: false,
  needsMyResponse: true,
  canConfirm: false,
);

Report sampleHomeReport({bool long = false}) => Report(
  id: 42,
  reference: 'RIA-2026-0142',
  status: ReportStatus.underReview,
  incidentAt: DateTime(2026, 11, 17, 9, 30),
  description: long ? List.filled(50, longArabic).join() : 'وصف الحادثة التجريبية',
  attachmentsCount: 2,
);

class FakeHomeVisits extends Fake implements VisitRepository {
  List<Visit> upcomingVisits = [sampleVisit()];
  Object? upcomingError;
  Completer<List<Visit>>? pendingUpcoming;
  int upcomingCalls = 0;

  @override
  Future<List<Visit>> upcoming() async {
    upcomingCalls++;
    if (upcomingError != null) throw upcomingError!;
    return pendingUpcoming == null ? upcomingVisits : await pendingUpcoming!.future;
  }
}

class FakeHomeReports extends Fake implements ReportRepository {
  List<Report> reports = [sampleHomeReport()];
  Object? listError;
  Completer<List<Report>>? pendingList;
  int listCalls = 0;

  @override
  Future<List<Report>> list({ReportStatus? status}) async {
    listCalls++;
    if (listError != null) throw listError!;
    return pendingList == null ? reports : await pendingList!.future;
  }
}

class FakeAuthNotifier extends Notifier<AuthState> implements AuthController {
  @override
  AuthState build() => const AuthState.signedIn(
    User(
      id: 1,
      name: 'أمينة',
      email: 'amina@example.com',
      role: 'mother',
      linked: true,
      partnerRole: 'father',
    ),
  );

  @override
  Future<void> refresh() async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required bool terms,
  }) async {}

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}

Future<void> pumpHome(
  WidgetTester tester, {
  required FakeHomeVisits visitsRepo,
  required FakeHomeReports reportsRepo,
  Brightness brightness = Brightness.light,
  List<String>? pushedRoutes,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
      ),
      GoRoute(
        path: '/reports/new',
        builder: (_, _) {
          pushedRoutes?.add('/reports/new');
          return const Scaffold(body: Text('new report route'));
        },
      ),
      GoRoute(
        path: '/reports/:id',
        builder: (context, state) {
          final path = '/reports/${state.pathParameters['id']}';
          pushedRoutes?.add(path);
          return Scaffold(body: Text('report detail $path'));
        },
      ),
      GoRoute(
        path: '/link',
        builder: (_, _) {
          pushedRoutes?.add('/link');
          return const Scaffold(body: Text('link screen'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        visitRepositoryProvider.overrideWithValue(visitsRepo),
        reportRepositoryProvider.overrideWithValue(reportsRepo),
        authControllerProvider.overrideWith(FakeAuthNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildTheme(brightness).copyWith(
          splashFactory: InkRipple.splashFactory,
        ),
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
  testWidgets('SOS card is rendered before visits and reports sections', (tester) async {
    final visits = FakeHomeVisits();
    final reports = FakeHomeReports();
    final pushed = <String>[];

    await pumpHome(tester, visitsRepo: visits, reportsRepo: reports, pushedRoutes: pushed);

    final sosFinder = find.byKey(const ValueKey('home-sos-card'));
    final visitFinder = find.byKey(const ValueKey('home-visit-section'));
    final reportFinder = find.byKey(const ValueKey('home-reports-section'));

    expect(sosFinder, findsOneWidget);
    expect(visitFinder, findsOneWidget);
    expect(reportFinder, findsOneWidget);

    final sosTop = tester.getTopLeft(sosFinder).dy;
    final visitTop = tester.getTopLeft(visitFinder).dy;
    final reportTop = tester.getTopLeft(reportFinder).dy;

    // SOS is physically above the visits and reports sections
    expect(sosTop, lessThan(visitTop));
    expect(visitTop, lessThan(reportTop));

    // Tap SOS card navigates to /reports/new via context.push
    await tester.tap(sosFinder);
    await tester.pumpAndSettle();
    expect(pushed, contains('/reports/new'));
  });

  testWidgets('SOS card displays directional forward arrow and watermark', (tester) async {
    final visits = FakeHomeVisits();
    final reports = FakeHomeReports();
    await pumpHome(tester, visitsRepo: visits, reportsRepo: reports);

    final sosFinder = find.byKey(const ValueKey('home-sos-card'));
    expect(sosFinder, findsOneWidget);

    expect(
      find.descendant(
        of: sosFinder,
        matching: find.byType(Watermark),
      ),
      findsOneWidget,
    );

    expect(
      find.descendant(
        of: sosFinder,
        matching: find.byIcon(Icons.arrow_forward),
      ),
      findsOneWidget,
    );
  });

  testWidgets('home section titles have leading icons for visits and reports', (tester) async {
    final visits = FakeHomeVisits();
    final reports = FakeHomeReports();
    await pumpHome(tester, visitsRepo: visits, reportsRepo: reports);

    final visitSection = find.byKey(const ValueKey('home-visit-section'));
    expect(visitSection, findsOneWidget);
    expect(
      find.descendant(
        of: visitSection,
        matching: find.byIcon(Icons.calendar_month_outlined),
      ),
      findsOneWidget,
    );
    expect(find.text('الزيارات القادمة'), findsOneWidget);

    final reportsSection = find.byKey(const ValueKey('home-reports-section'));
    expect(reportsSection, findsOneWidget);
    expect(
      find.descendant(
        of: reportsSection,
        matching: find.byIcon(Icons.description_outlined),
      ),
      findsOneWidget,
    );
    expect(find.text('آخر البلاغات'), findsOneWidget);
  });

  testWidgets('shows empty state when no upcoming visits or when not_linked', (tester) async {
    final visits = FakeHomeVisits()..upcomingVisits = [];
    final reports = FakeHomeReports();

    await pumpHome(tester, visitsRepo: visits, reportsRepo: reports);
    expect(find.text('لا توجد زيارات قادمة'), findsOneWidget);

    // Now test not_linked
    final notLinkedVisits = FakeHomeVisits()
      ..upcomingError = const ApiError(
        message: 'الحساب غير مرتبط',
        code: 'not_linked',
        status: 403,
      );

    await pumpHome(tester, visitsRepo: notLinkedVisits, reportsRepo: reports);
    expect(find.text('لم يتم ربط الحساب بعد'), findsOneWidget);
  });

  testWidgets('visit section error allows retry', (tester) async {
    final visits = FakeHomeVisits()
      ..upcomingError = const ApiError(message: 'فشل تحميل الزيارات');
    final reports = FakeHomeReports();

    await pumpHome(tester, visitsRepo: visits, reportsRepo: reports);
    expect(find.text('فشل تحميل الزيارات'), findsOneWidget);

    // Fix error and retry
    visits.upcomingError = null;
    final retryBtn = find.byKey(const ValueKey('retry-visits-button'));
    expect(retryBtn, findsOneWidget);
    await tester.tap(retryBtn);
    await tester.pumpAndSettle();

    expect(visits.upcomingCalls, 2);
    expect(find.text('بانتظار ردّك'), findsOneWidget);
  });

  testWidgets('reports section shows empty and error with retry', (tester) async {
    final visits = FakeHomeVisits();
    final reports = FakeHomeReports()..reports = [];

    await pumpHome(tester, visitsRepo: visits, reportsRepo: reports);
    expect(find.text('لا توجد بلاغات مسجلة'), findsOneWidget);

    // Reports error
    final errorReports = FakeHomeReports()
      ..listError = const ApiError(message: 'فشل تحميل البلاغات');

    await pumpHome(tester, visitsRepo: visits, reportsRepo: errorReports);
    expect(find.text('فشل تحميل البلاغات'), findsOneWidget);

    errorReports.listError = null;
    final retryBtn = find.byKey(const ValueKey('retry-reports-button'));
    expect(retryBtn, findsOneWidget);
    await tester.tap(retryBtn);
    await tester.pumpAndSettle();

    expect(errorReports.listCalls, 2);
    expect(find.text('RIA-2026-0142'), findsOneWidget);
  });

  testWidgets('reports section shows at most 3 reports and tapping opens detail', (tester) async {
    final visits = FakeHomeVisits();
    final reports = FakeHomeReports()
      ..reports = [
        sampleHomeReport(),
        Report(
          id: 43,
          reference: 'RIA-2026-0143',
          status: ReportStatus.reviewed,
          incidentAt: DateTime(2026, 11, 16, 10, 0),
          description: 'تقرير ثان',
        ),
        Report(
          id: 44,
          reference: 'RIA-2026-0144',
          status: ReportStatus.underReview,
          incidentAt: DateTime(2026, 11, 15, 11, 0),
          description: 'تقرير ثالث',
        ),
        Report(
          id: 45,
          reference: 'RIA-2026-0145',
          status: ReportStatus.reviewed,
          incidentAt: DateTime(2026, 11, 14, 12, 0),
          description: 'تقرير رابع لن يظهر',
        ),
      ];
    final pushed = <String>[];

    await pumpHome(tester, visitsRepo: visits, reportsRepo: reports, pushedRoutes: pushed);

    expect(find.text('RIA-2026-0142'), findsOneWidget);
    expect(find.text('RIA-2026-0143'), findsOneWidget);
    expect(find.text('RIA-2026-0144'), findsOneWidget);
    expect(find.text('RIA-2026-0145'), findsNothing);

    await tester.tap(find.text('RIA-2026-0142'));
    await tester.pumpAndSettle();
    expect(pushed, contains('/reports/42'));
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic text does not overflow in $brightness', (tester) async {
      final visits = FakeHomeVisits()..upcomingVisits = [sampleVisit(long: true)];
      final reports = FakeHomeReports()..reports = [sampleHomeReport(long: true)];

      await pumpHome(tester, visitsRepo: visits, reportsRepo: reports, brightness: brightness);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
