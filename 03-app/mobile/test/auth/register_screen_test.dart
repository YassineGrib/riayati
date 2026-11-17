import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/auth/screens/register_screen.dart';

import 'screen_test_support.dart';

void main() {
  testWidgets('registration requires an explicit role and consent', (
    tester,
  ) async {
    await pumpAuth(tester, const RegisterScreen());
    RButton submit() => tester.widget<RButton>(authButton('إنشاء الحساب'));
    expect(submit().onPressed, isNull);
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(submit().onPressed, isNull);
    await tester.tap(find.text('أب'));
    await tester.pump();
    expect(submit().onPressed, isNotNull);
    await tester.tap(find.text('أم'));
    await tester.pump();
    expect(submit().onPressed, isNotNull);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(submit().onPressed, isNull);
  });

  testWidgets('registration sends the selected role and consent', (
    tester,
  ) async {
    Object? payload;
    await pumpAuth(
      tester,
      const RegisterScreen(),
      respond: (request) {
        expect(request.path, '/register');
        payload = request.data;
        return jsonResponse('{"message":"تعذر إنشاء الحساب"}', 422);
      },
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'أمينة');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'amina@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password123');
    await tester.ensureVisible(find.text('أم'));
    await tester.tap(find.text('أم'));
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tapAuthButton(tester, 'إنشاء الحساب');
    expect(payload, {
      'name': 'أمينة',
      'email': 'amina@example.com',
      'password': 'password123',
      'role': 'mother',
      'terms': true,
    });
    expect(find.text('تعذر إنشاء الحساب'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long mixed Arabic registration input fits in $brightness', (
      tester,
    ) async {
      await pumpAuth(tester, const RegisterScreen(), brightness: brightness);
      for (var index = 0; index < 3; index++) {
        await tester.enterText(
          find.byType(TextFormField).at(index),
          longArabic * 5,
        );
      }
      await tester.ensureVisible(authButton('إنشاء الحساب'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
