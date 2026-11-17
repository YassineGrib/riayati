import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/features/calendar/calendar_screen.dart';
import 'package:riayati/features/calendar/visit.dart';

import 'screen_test_support.dart';

void main() {
  testWidgets('successful proposal closes sheet and refreshes month', (
    tester,
  ) async {
    final repo = FakeVisits();
    await pumpCalendar(tester, const CalendarScreen(), repo);
    await tapCalendarButton(tester, 'اقتراح زيارة');
    await tester.enterText(
      find.byKey(const ValueKey('visit-date')),
      '2099-11-27',
    );
    await tester.enterText(find.byKey(const ValueKey('visit-from')), '10:00');
    await tester.enterText(find.byKey(const ValueKey('visit-to')), '14:00');
    await tapCalendarButton(tester, 'إرسال الاقتراح');
    expect(find.byKey(const ValueKey('visit-date')), findsNothing);
    expect(repo.proposals, 1);
    expect(repo.months.length, 2);
  });
  testWidgets(
    'Saturday is rightmost; November first is Sunday; navigation refetches',
    (tester) async {
      final repo = FakeVisits();
      await pumpCalendar(
        tester,
        CalendarScreen(initialMonth: DateTime(2026, 11)),
        repo,
      );
      expect(
        tester.getCenter(find.text('السبت')).dx,
        greaterThan(tester.getCenter(find.text('الأحد')).dx),
      );
      expect(
        tester.getCenter(find.byKey(const ValueKey('day-2026-11-01'))).dx,
        tester.getCenter(find.text('الأحد')).dx,
      );
      await tester.tap(find.byTooltip('الشهر التالي'));
      await tester.pumpAndSettle();
      expect(repo.months, ['2026-11', '2026-12']);
    },
  );
  testWidgets('not linked offers navigation to link', (tester) async {
    await pumpCalendar(
      tester,
      const CalendarScreen(),
      FakeVisits()
        ..error = const ApiError(message: 'اربط الحساب', code: 'not_linked'),
    );
    await tapCalendarButton(tester, 'ربط الطرف الآخر');
    expect(find.text('link route'), findsOneWidget);
  });
  testWidgets('loading, retry and empty state', (tester) async {
    final pending = Completer<List<Visit>>();
    final repo = FakeVisits()..pending = pending;
    await pumpCalendar(tester, const CalendarScreen(), repo);
    expect(find.byType(LoadingView), findsOneWidget);
    pending.completeError(const ApiError(message: 'تعذر الاتصال'));
    await tester.pumpAndSettle();
    repo.pending = null;
    repo.visits = [];
    await tapCalendarButton(tester, 'إعادة المحاولة');
    expect(find.text('لا توجد زيارات قادمة'), findsOneWidget);
  });
}
