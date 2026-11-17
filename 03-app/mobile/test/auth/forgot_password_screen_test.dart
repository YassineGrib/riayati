import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/features/auth/screens/forgot_password_screen.dart';

import 'screen_test_support.dart';

void main() {
  for (final email in ['amina@example.com', 'unknown@example.com']) {
    testWidgets('reset uses the same success message for $email', (
      tester,
    ) async {
      await pumpAuth(
        tester,
        const ForgotPasswordScreen(),
        respond: (request) {
          expect(request.path, '/forgot-password');
          expect(request.data, {'email': email});
          return jsonResponse('{"message":"private server response"}', 200);
        },
      );
      await tester.enterText(find.byType(TextFormField), email);
      await tapAuthButton(tester, 'إرسال الرابط');
      expect(find.text('تحقق من بريدك'), findsOneWidget);
      expect(
        find.text(
          'إذا كان البريد مسجّلًا لدينا فقد أرسلنا إليه رابط الاستعادة.',
        ),
        findsOneWidget,
      );
      expect(find.text('private server response'), findsNothing);
      expect(find.text(email), findsNothing);
    });
  }

  testWidgets('reset failure preserves the form for retry', (tester) async {
    await pumpAuth(
      tester,
      const ForgotPasswordScreen(),
      respond: (_) =>
          jsonResponse('{"message":"تعذر الاتصال، حاول مجددًا"}', 503),
    );
    await tester.enterText(find.byType(TextFormField), 'amina@example.com');
    await tapAuthButton(tester, 'إرسال الرابط');
    expect(find.text('تعذر الاتصال، حاول مجددًا'), findsOneWidget);
    expect(find.text('تحقق من بريدك'), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic reset input fits in $brightness', (tester) async {
      await pumpAuth(
        tester,
        const ForgotPasswordScreen(),
        brightness: brightness,
      );
      await tester.enterText(find.byType(TextFormField), longArabic * 5);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
