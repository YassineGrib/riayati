import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/app_scaffold.dart';
import 'package:riayati/core/widgets/floating_nav.dart';
import 'package:riayati/core/widgets/watermark.dart';

import 'test_app.dart';

void main() {
  testWidgets('scaffold forces RTL and reserves space for bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        AppScaffold(
          title: 'بلاغاتي',
          body: const SizedBox.expand(key: ValueKey('body')),
          bottom: FloatingNav(index: 0, onTap: (_) {}),
        ),
      ),
    );
    expect(
      Directionality.of(tester.element(find.byKey(const ValueKey('body')))),
      TextDirection.rtl,
    );
    expect(find.byType(Watermark), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byKey(const ValueKey('body'))).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.byType(FloatingNav)).dy),
    );
    await tester.pumpWidget(
      testApp(const AppScaffold(showWatermark: false, body: Text('المحتوى'))),
    );
    expect(find.byType(Watermark), findsNothing);
  });
}
