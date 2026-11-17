import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/r_card.dart';

import 'test_app.dart';

void main() {
  testWidgets('card activates once and accommodates long Arabic', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      testApp(
        RCard(
          onTap: () => calls++,
          child: const Text(
            'عند تسليم الطفل بعد الزيارة لاحظت كدمة على ذراعه RIA-2026-0142 ولم يقدم أي تفسير',
          ),
        ),
      ),
    );
    await tester.tap(find.byType(RCard));
    expect(calls, 1);
    expect(tester.takeException(), isNull);
  });
}
