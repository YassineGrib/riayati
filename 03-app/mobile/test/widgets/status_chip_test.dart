import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/theme/tokens.g.dart';
import 'package:riayati/core/widgets/status_chip.dart';

import 'test_app.dart';

void main() {
  testWidgets('status tones follow semantic colors in both themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final c = brightness == Brightness.light ? RColors.light : RColors.dark;
      for (final tone in StatusTone.values) {
        await tester.pumpWidget(
          testApp(
            StatusChip(label: 'قيد المراجعة RIA-2026-0142', tone: tone),
            brightness: brightness,
          ),
        );
        // MaterialApp animates theme changes; assert the destination tokens.
        await tester.pumpAndSettle();
        final text = tester.widget<Text>(
          find.text('قيد المراجعة RIA-2026-0142'),
        );
        expect(text.style!.letterSpacing, 0);
        expect(text.style!.color, switch (tone) {
          StatusTone.neutral => c.textPrimary,
          StatusTone.info => c.feedbackInfoText,
          StatusTone.success => c.feedbackSuccessText,
          StatusTone.warning => c.feedbackWarningText,
          StatusTone.error => c.feedbackErrorText,
        });
        expect(tester.takeException(), isNull);
      }
    }
  });
}
