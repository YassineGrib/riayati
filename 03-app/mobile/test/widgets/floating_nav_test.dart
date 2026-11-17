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

  testWidgets('selected tab has no halo or pill background and differs only in color', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        FloatingNav(
          index: 0,
          onTap: (_) {},
        ),
      ),
    );

    final selectedNavFinder = find.byKey(const ValueKey('nav-0'));
    final unselectedNavFinder = find.byKey(const ValueKey('nav-1'));

    // Verify there is no DecoratedBox with a fill color inside the nav item (no halo/pill)
    final decoratedBoxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: selectedNavFinder,
        matching: find.byType(DecoratedBox),
      ),
    );
    for (final box in decoratedBoxes) {
      final decor = box.decoration;
      if (decor is BoxDecoration) {
        expect(decor.color, isNull);
      }
    }

    // Selected item differs in icon color
    final selectedIcon = tester.widget<Icon>(
      find.descendant(of: selectedNavFinder, matching: find.byType(Icon)),
    );
    final unselectedIcon = tester.widget<Icon>(
      find.descendant(of: unselectedNavFinder, matching: find.byType(Icon)),
    );
    expect(selectedIcon.color, isNot(equals(unselectedIcon.color)));

    // Selected item differs in label color
    final selectedText = tester.widget<Text>(find.text('الرئيسية'));
    final unselectedText = tester.widget<Text>(find.text('التقارير'));
    expect(selectedText.style?.color, isNot(equals(unselectedText.style?.color)));
  });
}
