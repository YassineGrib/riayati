import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/r_button.dart';

import 'test_app.dart';

void main() {
  testWidgets('loading disables taps and announces progress', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      testApp(
        RButton(label: 'تسجيل الدخول', loading: true, onPressed: () => calls++),
      ),
    );
    await tester.tap(find.byType(RButton));
    expect(calls, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });

  testWidgets('all kinds activate and meet the touch target', (tester) async {
    var calls = 0;
    for (final kind in RButtonKind.values) {
      await tester.pumpWidget(
        testApp(RButton(label: 'متابعة', kind: kind, onPressed: () => calls++)),
      );
      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('متابعة'));
      await tester.pump();
    }
    expect(calls, RButtonKind.values.length);
  });
}
