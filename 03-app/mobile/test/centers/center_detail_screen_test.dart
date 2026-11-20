import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/features/centers/center_detail_screen.dart';
import 'package:riayati/features/centers/support_center.dart';

import 'centers_test_support.dart';

void main() {
  testWidgets('renders center detail information and info rows', (tester) async {
    final repo = FakeCenterRepository();
    await pumpCenters(
      tester,
      const CenterDetailScreen(id: 1),
      repo,
    );

    expect(find.text('تفاصيل المركز'), findsOneWidget);
    expect(find.text('محكمة سيدي امحمد - قسم الأسرة'), findsOneWidget);
    expect(find.text('بيانات تجريبية'), findsOneWidget);
    expect(find.text('الولاية'), findsOneWidget);
    expect(find.text('16 - الجزائر'), findsOneWidget);
    expect(find.text('العنوان الكامل'), findsOneWidget);
    expect(find.text('شارع عبان رمضان، الجزائر العاصمة'), findsOneWidget);
    expect(find.text('الهاتف الرئيسي'), findsOneWidget);
    expect(find.text('000-000-000 (رقم تجريبي)'), findsOneWidget);
    expect(find.text('الرقم الأخضر / المساعدة'), findsOneWidget);
    expect(find.text('11-11'), findsOneWidget);
    expect(find.text('الاختصاص والمهام'), findsOneWidget);
    expect(find.textContaining('هذه المعلومات مخصصة للإرشاد الأولي'), findsOneWidget);

    expect(find.byKey(const ValueKey('center-detail-call-btn')), findsOneWidget);
    expect(find.byKey(const ValueKey('center-detail-copy-btn')), findsOneWidget);
  });

  testWidgets('copy button copies phone and shows feedback snackbar', (tester) async {
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

    final repo = FakeCenterRepository();
    await pumpCenters(
      tester,
      const CenterDetailScreen(id: 1),
      repo,
    );

    final copyBtn = find.byKey(const ValueKey('center-detail-copy-btn'));
    expect(copyBtn, findsOneWidget);
    await tester.ensureVisible(copyBtn);    await tester.pumpAndSettle();    await tester.tap(copyBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(copied, '000-000-000');
    expect(find.text('تم نسخ رقم الهاتف'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('call button triggers tel launch without error', (tester) async {
    final repo = FakeCenterRepository();
    await pumpCenters(
      tester,
      const CenterDetailScreen(id: 1),
      repo,
    );

    final callBtn = find.byKey(const ValueKey('center-detail-call-btn'));
    expect(callBtn, findsOneWidget);
    await tester.ensureVisible(callBtn);    await tester.pumpAndSettle();    await tester.tap(callBtn);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('back button pops or navigates to /centers', (tester) async {
    final repo = FakeCenterRepository();
    final pushed = <String>[];
    await pumpCenters(
      tester,
      const CenterDetailScreen(id: 1),
      repo,
      pushedRoutes: pushed,
    );

    final backBtn = find.byKey(const ValueKey('center-detail-back-button'));
    expect(backBtn, findsOneWidget);
    await tester.ensureVisible(backBtn);    await tester.pumpAndSettle();    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(pushed, contains('/centers'));
  });

  testWidgets('loading then error can be retried on center detail screen', (tester) async {
    final pending = Completer<SupportCenter>();
    final repo = FakeCenterRepository()..pendingDetail = pending;
    await pumpCenters(
      tester,
      const CenterDetailScreen(id: 1),
      repo,
    );

    expect(find.byType(LoadingView), findsOneWidget);

    pending.completeError(const ApiError(message: 'تعذر تحميل بيانات المركز'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر تحميل بيانات المركز'), findsOneWidget);

    repo.pendingDetail = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('محكمة سيدي امحمد - قسم الأسرة'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('center detail renders without errors in $brightness with long Arabic text', (tester) async {
      final repo = FakeCenterRepository()..detail = sampleCenter(long: true);
      await pumpCenters(
        tester,
        const CenterDetailScreen(id: 1),
        repo,
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
