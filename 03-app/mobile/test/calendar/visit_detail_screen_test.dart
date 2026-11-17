import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/features/calendar/visit_detail_screen.dart';

import 'screen_test_support.dart';

void main() {
  testWidgets('decline shows server failure and can retry', (tester) async {
    final repo = FakeVisits()
      ..detail = sampleVisit(response: true)
      ..actionError = const ApiError(message: 'تعذر حفظ الرد');
    await pumpCalendar(tester, const VisitDetailScreen(7), repo);
    await tapCalendarButton(tester, 'رفض');
    expect(find.text('تعذر حفظ الرد'), findsOneWidget);
    repo.actionError = null;
    await tapCalendarButton(tester, 'رفض');
    expect(repo.actions, ['decline', 'decline']);
    expect(calendarButton('رفض'), findsNothing);
  });
  for (final response in [false, true]) {
    for (final confirm in [false, true]) {
      testWidgets('actions follow response=$response confirm=$confirm', (
        tester,
      ) async {
        final repo = FakeVisits()
          ..detail = sampleVisit(response: response, confirm: confirm);
        await pumpCalendar(tester, const VisitDetailScreen(7), repo);
        expect(
          calendarButton('قبول'),
          response ? findsOneWidget : findsNothing,
        );
        expect(calendarButton('رفض'), response ? findsOneWidget : findsNothing);
        expect(
          calendarButton('تأكيد الزيارة'),
          confirm ? findsOneWidget : findsNothing,
        );
        if (response || confirm) {
          await tapCalendarButton(tester, response ? 'قبول' : 'تأكيد الزيارة');
          expect(repo.actions, [response ? 'accept' : 'confirm']);
          expect(calendarButton('قبول'), findsNothing);
        }
      });
    }
  }
  for (final brightness in Brightness.values) {
    testWidgets('long mixed Arabic note fits $brightness', (tester) async {
      await pumpCalendar(
        tester,
        const VisitDetailScreen(7),
        FakeVisits()
          ..detail = sampleVisit(
            note: List.filled(30, 'ملاحظة عربية طويلة Test123 ').join(),
          ),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
