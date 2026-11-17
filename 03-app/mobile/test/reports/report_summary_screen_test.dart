import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/report_summary_screen.dart';

const longArabic = 'نص بلاغ مفصل باللغة العربية يتضمن كل التفاصيل المتعلقة بالواقعة للتحقق من عدم حدوث فيض ';

Report sampleSummaryReport({bool long = false}) => Report(
  id: 142,
  reference: 'RIA-2026-0142',
  status: ReportStatus.underReview,
  incidentAt: DateTime(2026, 11, 17, 9, 30),
  description: long
      ? List.filled(50, longArabic).join()
      : 'عند تسليم الطفل بعد الزيارة لاحظتُ كدمة على ذراعه ولم يُقدَّم أي تفسير.',
  attachmentsCount: 2,
  attachments: const [
    ReportAttachment(
      id: 1,
      filename: 'صورة 1.jpg',
      mime: 'image/jpeg',
      size: 2400000,
      sha256: 'abcdef123456',
    ),
    ReportAttachment(
      id: 2,
      filename: 'فيديو 1.mp4',
      mime: 'video/mp4',
      size: 15000000,
      sha256: '7890abcdef12',
    ),
  ],
);

Future<void> pumpSummary(
  WidgetTester tester, {
  required Report report,
  Brightness brightness = Brightness.light,
  List<String>? navigatedRoutes,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/reports/summary',
    routes: [
      GoRoute(
        path: '/reports/summary',
        builder: (_, _) => ReportSummaryScreen(report),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) {
          navigatedRoutes?.add('/home');
          return const Scaffold(body: Text('home screen'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
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
  testWidgets('displays sent confirmation, reference and report details', (tester) async {
    final report = sampleSummaryReport();
    await pumpSummary(tester, report: report);

    expect(find.text('تم إرسال البلاغ'), findsOneWidget);
    expect(find.text('RIA-2026-0142'), findsOneWidget);
    expect(find.text('قيد المراجعة'), findsOneWidget);
    expect(find.text('عند تسليم الطفل بعد الزيارة لاحظتُ كدمة على ذراعه ولم يُقدَّم أي تفسير.'), findsOneWidget);
    expect(find.text('لا يمكن حذف البلاغ بعد إرساله، للحفاظ عليه كدليل.'), findsOneWidget);
  });

  testWidgets('tapping back arrow navigates to /home', (tester) async {
    final report = sampleSummaryReport();
    final routes = <String>[];
    await pumpSummary(tester, report: report, navigatedRoutes: routes);

    final backBtn = find.byTooltip('رجوع');
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(routes, contains('/home'));
  });

  testWidgets('tapping back to home button navigates to /home', (tester) async {
    final report = sampleSummaryReport();
    final routes = <String>[];
    await pumpSummary(tester, report: report, navigatedRoutes: routes);

    final homeBtn = find.widgetWithText(RButton, 'العودة للرئيسية');
    expect(homeBtn, findsOneWidget);

    await tester.ensureVisible(homeBtn);
    await tester.tap(homeBtn);
    await tester.pumpAndSettle();

    expect(routes, contains('/home'));
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic text does not overflow in $brightness', (tester) async {
      final report = sampleSummaryReport(long: true);
      await pumpSummary(tester, report: report, brightness: brightness);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
