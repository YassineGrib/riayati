import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/watermark.dart';

import 'test_app.dart';

void main() {
  testWidgets('decorative watermark does not intercept taps', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      testApp(
        Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => calls++,
                child: const ColoredBox(color: Colors.white),
              ),
            ),
            const Positioned.fill(child: Watermark()),
          ],
        ),
      ),
    );
    await tester.tapAt(const Offset(100, 100));
    expect(calls, 1);
  });
}
