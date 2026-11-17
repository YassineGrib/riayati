import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/floating_nav.dart';

import 'test_app.dart';

void main() {
  testWidgets('controlled selection follows taps in RTL tab order', (
    tester,
  ) async {
    var index = 0;
    await tester.pumpWidget(
      testApp(
        StatefulBuilder(
          builder: (context, setState) {
            return FloatingNav(
              index: index,
              onTap: (value) => setState(() => index = value),
            );
          },
        ),
      ),
    );
    expect(
      tester.getCenter(find.text('الرئيسية')).dx,
      greaterThan(tester.getCenter(find.text('حسابي')).dx),
    );
    const labels = ['الرئيسية', 'التقارير', 'التقويم', 'المساعد', 'حسابي'];
    for (
      var expectedIndex = 0;
      expectedIndex < labels.length;
      expectedIndex++
    ) {
      if (expectedIndex > 0) {
        expect(
          tester.getCenter(find.text(labels[expectedIndex - 1])).dx,
          greaterThan(tester.getCenter(find.text(labels[expectedIndex])).dx),
        );
      }
      await tester.tap(find.text(labels[expectedIndex]));
      await tester.pumpAndSettle();
      expect(index, expectedIndex);
      for (var i = 0; i < 5; i++) {
        expect(
          tester
              .widget<Semantics>(find.byKey(ValueKey('nav-$i')))
              .properties
              .selected,
          i == index,
        );
      }
      expect(
        tester.getSize(find.byKey(ValueKey('nav-$index'))).height,
        greaterThanOrEqualTo(48),
      );
    }
    expect(index, 4);
  });
}
