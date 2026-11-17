import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/watermark.dart';
import 'package:riayati/features/auth/screens/welcome_screen.dart';

import 'screen_test_support.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'welcome copy and actions fit in $brightness with large Arabic type',
      (tester) async {
        await pumpAuth(
          tester,
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: WelcomeScreen(),
          ),
          brightness: brightness,
        );
        expect(find.text('رعايتي'), findsOneWidget);
        expect(
          find.text('مساحة آمنة لحماية الأطفال ومعرفة الحقوق في إطار الحضانة.'),
          findsOneWidget,
        );
        expect(authButton('إنشاء حساب'), findsOneWidget);
        expect(authButton('تسجيل الدخول'), findsOneWidget);
        expect(find.byType(Watermark), findsWidgets);
        expect(
          Directionality.of(tester.element(find.text('رعايتي'))),
          TextDirection.rtl,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
