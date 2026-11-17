import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/report_repository.dart';

const fingerprint =
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const longArabic = 'وصف طويل جدًا للواقعة مع أسماء عربية وملفات Test123.pdf ';

Report sampleReport({bool long = false}) => Report(
  id: 7,
  reference: 'RIA-2026-0142',
  status: ReportStatus.underReview,
  incidentAt: DateTime(2026, 11, 17, 9, 30),
  description: long
      ? List.filled(60, longArabic).join()
      : 'وصف الواقعة المسجلة',
  attachmentsCount: 1,
  attachments: [
    ReportAttachment(
      id: 9,
      filename: long ? List.filled(8, longArabic).join() : 'evidence.pdf',
      mime: 'application/pdf',
      size: 1024,
      sha256: fingerprint,
    ),
  ],
);

class FakeReports extends Fake implements ReportRepository {
  List<Report> reports = [sampleReport()];
  Report detail = sampleReport();
  Object? listError;
  Object? detailError;
  Object? pdfError;
  Object? linkError;
  Completer<File>? pendingPdf;
  Completer<List<Report>>? pendingList;
  final filters = <ReportStatus?>[];
  final gets = <int>[];
  final pdfs = <int>[];
  final links = <(int, int)>[];

  @override
  Future<List<Report>> list({ReportStatus? status}) async {
    filters.add(status);
    if (listError != null) throw listError!;
    return pendingList == null ? reports : await pendingList!.future;
  }

  @override
  Future<Report> get(int id) async {
    gets.add(id);
    if (detailError != null) throw detailError!;
    return detail;
  }

  @override
  Future<File> pdf(int id) async {
    pdfs.add(id);
    if (pdfError != null) throw pdfError!;
    return pendingPdf == null ? File('report.pdf') : await pendingPdf!.future;
  }

  @override
  Future<Uri> attachmentLink(int reportId, int attachmentId) async {
    links.add((reportId, attachmentId));
    if (linkError != null) throw linkError!;
    return Uri.parse('https://example.test/file?signature=${links.length}');
  }
}

Future<void> pumpReports(
  WidgetTester tester,
  Widget screen,
  FakeReports repo, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: '/reports/new',
        builder: (_, _) => const Scaffold(body: Text('new route')),
      ),
      GoRoute(
        path: '/reports/7',
        builder: (_, _) => const Scaffold(body: Text('detail route')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reportRepositoryProvider.overrideWithValue(repo)],
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

Finder reportButton(String label) => find.byWidgetPredicate(
  (widget) => widget is RButton && widget.label == label,
);

Future<void> tapReportButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(reportButton(label));
  await tester.tap(reportButton(label));
  await tester.pumpAndSettle();
}
