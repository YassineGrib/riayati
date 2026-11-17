import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/features/auth/screens/login_screen.dart';

import 'screen_test_support.dart';

void main() {
  testWidgets('empty login fields show required messages without a request', (
    tester,
  ) async {
    var requests = 0;
    await pumpAuth(
      tester,
      const LoginScreen(),
      respond: (_) {
        requests++;
        return jsonResponse('{}', 200);
      },
    );
    await tapAuthButton(tester, 'تسجيل الدخول');
    expect(find.text('البريد الإلكتروني مطلوب.'), findsOneWidget);
    expect(find.text('كلمة المرور مطلوبة.'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('server error is shown below the form and login can retry', (
    tester,
  ) async {
    var requests = 0;
    const message =
        'البريد الإلكتروني أو كلمة المرور غير صحيحة. تحقق منهما وحاول مجددًا.';
    await pumpAuth(
      tester,
      const LoginScreen(),
      respond: (request) {
        expect(request.path, '/login');
        expect(request.data, {
          'email': 'amina@example.com',
          'password': 'password123',
        });
        requests++;
        return jsonResponse(jsonEncode({'message': message}), 422);
      },
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'amina@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tapAuthButton(tester, 'تسجيل الدخول');
    expect(find.text(message), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(message)).dy,
      greaterThan(tester.getBottomLeft(find.byType(TextFormField).last).dy),
    );
    await tapAuthButton(tester, 'تسجيل الدخول');
    expect(requests, 2);
  });

  testWidgets('offline failure is readable and leaves submit enabled', (
    tester,
  ) async {
    await pumpAuth(
      tester,
      const LoginScreen(),
      respond: (request) => throw DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      ),
    );
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'amina@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tapAuthButton(tester, 'تسجيل الدخول');
    expect(find.text(ApiError.offlineMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic login input fits in $brightness', (tester) async {
      await pumpAuth(tester, const LoginScreen(), brightness: brightness);
      for (final field in find.byType(TextFormField).evaluate().toList()) {
        await tester.enterText(find.byWidget(field.widget), longArabic * 5);
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
