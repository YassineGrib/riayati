import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/reports_screen.dart';

import 'screen_test_support.dart';

void main() {
  testWidgets('filters refetch with API status and cards open detail', (
    tester,
  ) async {
    final repo = FakeReports();
    await pumpReports(tester, const ReportsScreen(), repo);
    expect(repo.filters, [null]);
    for (final (label, status) in [
      ('قيد المراجعة', ReportStatus.underReview),
      ('تمت المراجعة', ReportStatus.reviewed),
      ('الكل', null),
    ]) {
      await tester.tap(find.widgetWithText(TextButton, label).first);
      await tester.pumpAndSettle();
      expect(repo.filters.last, status);
    }
    expect(find.text('وصف الواقعة المسجلة'), findsOneWidget);
    await tester.tap(find.text('RIA-2026-0142'));
    await tester.pumpAndSettle();
    expect(find.text('detail route'), findsOneWidget);
  });

  testWidgets('reports filter chips display corresponding icons', (tester) async {
    final repo = FakeReports();
    await pumpReports(tester, const ReportsScreen(), repo);

    expect(find.byIcon(Icons.list_alt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('empty state opens the new report route', (tester) async {
    await pumpReports(
      tester,
      const ReportsScreen(),
      FakeReports()..reports = [],
    );
    expect(find.text('لا توجد بلاغات بعد'), findsOneWidget);
    await tapReportButton(tester, 'بلاغ جديد');
    expect(find.text('new route'), findsOneWidget);
  });

  testWidgets('loading then server error can be retried', (tester) async {
    final pending = Completer<List<Report>>();
    final repo = FakeReports()..pendingList = pending;
    await pumpReports(tester, const ReportsScreen(), repo);
    expect(find.byType(LoadingView), findsOneWidget);
    pending.completeError(const ApiError(message: 'تعذر الاتصال بالخادم'));
    await tester.pumpAndSettle();
    expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);
    repo.pendingList = null;
    await tapReportButton(tester, 'إعادة المحاولة');
    expect(repo.filters.length, 2);
    expect(find.text('RIA-2026-0142'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic cards fit in $brightness', (tester) async {
      await pumpReports(
        tester,
        const ReportsScreen(),
        FakeReports()..reports = [sampleReport(long: true)],
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
