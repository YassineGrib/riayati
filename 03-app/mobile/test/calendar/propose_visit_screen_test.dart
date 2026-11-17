import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/features/calendar/propose_visit_sheet.dart';

import 'screen_test_support.dart';

void main() {
  Future<void> fill(
    WidgetTester tester, {
    String from = '10:00',
    String to = '14:00',
  }) async {
    await tester.enterText(
      find.byKey(const ValueKey('visit-date')),
      '2099-11-27',
    );
    await tester.enterText(find.byKey(const ValueKey('visit-from')), from);
    await tester.enterText(find.byKey(const ValueKey('visit-to')), to);
  }

  testWidgets('overlap error appears below form and preserves input', (
    tester,
  ) async {
    final repo = FakeVisits()
      ..proposeError = const ApiError(
        message: 'تتداخل الزيارة مع زيارة أخرى',
        fields: {
          'date': ['اختر وقتًا آخر'],
        },
      );
    await pumpCalendar(tester, const Scaffold(body: ProposeVisitSheet()), repo);
    await fill(tester);
    await tapCalendarButton(tester, 'إرسال الاقتراح');
    expect(find.textContaining('تتداخل الزيارة'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('proposal-error'))).dy,
      greaterThan(
        tester.getTopLeft(find.byKey(const ValueKey('visit-note'))).dy,
      ),
    );
    expect(repo.proposals, 1);
  });
  testWidgets('end must follow start and past date is blocked', (tester) async {
    final repo = FakeVisits();
    await pumpCalendar(tester, const Scaffold(body: ProposeVisitSheet()), repo);
    await fill(tester, to: '09:00');
    await tapCalendarButton(tester, 'إرسال الاقتراح');
    expect(find.text('يجب أن يكون وقت النهاية بعد البداية.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('visit-date')),
      '2020-01-01',
    );
    await tapCalendarButton(tester, 'إرسال الاقتراح');
    expect(find.text('اختر موعدًا في المستقبل.'), findsOneWidget);
    expect(repo.proposals, 0);
  });
}
