import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/features/library/content_detail_screen.dart';
import 'package:riayati/features/library/content_item.dart';

import 'library_test_support.dart';

void main() {
  testWidgets('renders content detail with serif body and reference', (tester) async {
    final repo = FakeContentRepository();
    await pumpLibrary(
      tester,
      const ContentDetailScreen(slug: 'custody-eligibility'),
      repo,
    );

    expect(find.text('المحتوى التعليمي'), findsOneWidget);
    expect(find.text('شروط استحقاق الحضانة وسقوطها'), findsOneWidget);
    expect(find.text('قانون'), findsOneWidget);
    expect(find.text('المصدر: المواد 64، 65 و66'), findsOneWidget);
    expect(
      find.text('الحضانة هي حفظ الولد وتربيته ورعايته بما يحقق مصلحته الفضلى. وتسقط الحضانة إذا اختلت الشروط الواجب توفرها.'),
      findsOneWidget,
    );
    expect(find.textContaining('ملاحظة: تُراعى مصلحة المحضون دائمًا'), findsOneWidget);
  });

  testWidgets('copy button copies content and displays feedback', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    final repo = FakeContentRepository();
    await pumpLibrary(
      tester,
      const ContentDetailScreen(slug: 'custody-eligibility'),
      repo,
    );

    final copyBtn = find.byKey(const ValueKey('content-detail-copy-button'));
    expect(copyBtn, findsOneWidget);
    await tester.tap(copyBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(copied, contains('شروط استحقاق الحضانة وسقوطها'));
    expect(find.text('تم نسخ نص المقال'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('back button pops or navigates to /library', (tester) async {
    final repo = FakeContentRepository();
    final pushed = <String>[];
    await pumpLibrary(
      tester,
      const ContentDetailScreen(slug: 'custody-eligibility'),
      repo,
      pushedRoutes: pushed,
    );

    final backBtn = find.byKey(const ValueKey('content-detail-back-button'));
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(pushed, contains('/library'));
  });

  testWidgets('loading then error can be retried on detail screen', (tester) async {
    final pending = Completer<ContentItem>();
    final repo = FakeContentRepository()..pendingDetail = pending;
    await pumpLibrary(
      tester,
      const ContentDetailScreen(slug: 'custody-eligibility'),
      repo,
    );

    expect(find.byType(LoadingView), findsOneWidget);

    pending.completeError(const ApiError(message: 'تعذر تحميل المحتوى'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل المحتوى'), findsOneWidget);

    repo.pendingDetail = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('شروط استحقاق الحضانة وسقوطها'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('detail renders without errors in $brightness with long Arabic text', (tester) async {
      final repo = FakeContentRepository()..detail = sampleContent(long: true);
      await pumpLibrary(
        tester,
        const ContentDetailScreen(slug: 'custody-eligibility'),
        repo,
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
