import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/widgets/state_views.dart';

import 'test_app.dart';

void main() {
  testWidgets('error retries when requested', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      testApp(ErrorView(message: 'تعذر الاتصال', onRetry: () => calls++)),
    );
    await tester.tap(find.text('إعادة المحاولة'));
    expect(calls, 1);
  });
  testWidgets('empty displays supplied copy', (tester) async {
    await tester.pumpWidget(
      testApp(
        const EmptyView(title: 'لا توجد بلاغات بعد', body: 'ستظهر بلاغاتك هنا'),
      ),
    );
    expect(find.text('لا توجد بلاغات بعد'), findsOneWidget);
    expect(find.text('ستظهر بلاغاتك هنا'), findsOneWidget);
  });
}
