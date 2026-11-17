import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/r_text_field.dart';

import 'test_app.dart';

void main() {
  testWidgets('validates and preserves mixed Arabic Latin digits', (
    tester,
  ) async {
    final form = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      testApp(
        Form(
          key: form,
          child: RTextField(
            label: 'البريد الإلكتروني',
            controller: controller,
            helper: 'أدخل بريدك',
            validator: (value) =>
                value == null || value.isEmpty ? 'هذا الحقل مطلوب' : null,
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('هذا الحقل مطلوب'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      'أمينة amina12@example.com',
    );
    expect(form.currentState!.validate(), isTrue);
    await tester.pumpAndSettle();
    expect(controller.text, 'أمينة amina12@example.com');
    expect(find.text('هذا الحقل مطلوب'), findsNothing);
  });

  testWidgets('obscures passwords', (tester) async {
    await tester.pumpWidget(
      testApp(const RTextField(label: 'كلمة المرور', obscure: true)),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
  });
}
