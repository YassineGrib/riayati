import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/features/centers/centers_screen.dart';
import 'package:riayati/features/centers/support_center.dart';

import 'centers_test_support.dart';

void main() {
  testWidgets('renders centers screen and chips filter by kind', (tester) async {
    final repo = FakeCenterRepository();
    await pumpCenters(tester, const CentersScreen(), repo);

    expect(find.text('مراكز وهيئات'), findsOneWidget);
    expect(find.byKey(const ValueKey('centers-search-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('centers-wilaya-filter-btn')), findsOneWidget);
    expect(find.text('بيانات تجريبية'), findsOneWidget);

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('محكمة'), findsWidgets);
    expect(find.text('حماية الطفولة'), findsOneWidget);

    expect(repo.capturedKinds, [null]);

    // Tap 'محكمة'
    await tester.ensureVisible(find.byKey(const ValueKey('centers-chip-court')));    await tester.pumpAndSettle();    await tester.tap(find.byKey(const ValueKey('centers-chip-court')));
    await tester.pumpAndSettle();
    expect(repo.capturedKinds.last, CenterKind.court);

    // Tap 'حماية الطفولة'
    await tester.ensureVisible(find.byKey(const ValueKey('centers-chip-child_protection')));    await tester.pumpAndSettle();    await tester.tap(find.byKey(const ValueKey('centers-chip-child_protection')));
    await tester.pumpAndSettle();
    expect(repo.capturedKinds.last, CenterKind.childProtection);

    // Tap 'الكل'
    await tester.ensureVisible(find.byKey(const ValueKey('centers-chip-all')));    await tester.pumpAndSettle();    await tester.tap(find.byKey(const ValueKey('centers-chip-all')));
    await tester.pumpAndSettle();
    expect(repo.capturedKinds.last, isNull);
  });

  testWidgets('search field triggers search after debounce and clear button resets', (tester) async {
    final repo = FakeCenterRepository();
    await pumpCenters(tester, const CentersScreen(), repo);

    final searchField = find.byKey(const ValueKey('centers-search-field'));
    await tester.enterText(searchField, 'العدالة');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(repo.capturedQueries.last, 'العدالة');

    final clearBtn = find.byKey(const ValueKey('centers-search-clear'));
    expect(clearBtn, findsOneWidget);
    await tester.ensureVisible(clearBtn);    await tester.pumpAndSettle();    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(repo.capturedQueries.last, isNull);
  });

  testWidgets('card tap pushes /centers/:id', (tester) async {
    final repo = FakeCenterRepository();
    final pushed = <String>[];
    await pumpCenters(tester, const CentersScreen(), repo, pushedRoutes: pushed);

    expect(find.text('محكمة سيدي امحمد - قسم الأسرة'), findsOneWidget);
    await tester.tap(find.text('محكمة سيدي امحمد - قسم الأسرة'));
    await tester.pumpAndSettle();

    expect(pushed, contains('/centers/1'));
  });

  testWidgets('tapping call button triggers call without error', (tester) async {
    final repo = FakeCenterRepository();
    await pumpCenters(tester, const CentersScreen(), repo);

    final callBtn = find.byKey(const ValueKey('center-call-btn-1'));
    expect(callBtn, findsOneWidget);
    await tester.ensureVisible(callBtn);    await tester.pumpAndSettle();    await tester.tap(callBtn);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('opening wilaya filter sheet allows selecting a wilaya and reloads', (tester) async {
    final repo = FakeCenterRepository();
    await pumpCenters(tester, const CentersScreen(), repo);

    // Open sheet
    await tester.ensureVisible(find.byKey(const ValueKey('centers-wilaya-filter-btn')));    await tester.pumpAndSettle();    await tester.tap(find.byKey(const ValueKey('centers-wilaya-filter-btn')));
    await tester.pumpAndSettle();

    expect(find.text('اختر الولاية (58 ولاية)'), findsOneWidget);

    // Select wilaya 16 (the list is lazy, so narrow it with the search box)
    await tester.enterText(
      find.byKey(const ValueKey('wilaya-sheet-search-field')),
      '16',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('wilaya-option-16')));    await tester.pumpAndSettle();    await tester.tap(find.byKey(const ValueKey('wilaya-option-16')));
    await tester.pumpAndSettle();

    // Confirm selection
    await tester.ensureVisible(find.byKey(const ValueKey('wilaya-filter-confirm-btn')));    await tester.pumpAndSettle();    await tester.tap(find.byKey(const ValueKey('wilaya-filter-confirm-btn')));
    await tester.pumpAndSettle();

    expect(repo.capturedWilayas.last, '16');
  });

  testWidgets('empty state displays reset button and resets filters', (tester) async {
    final repo = FakeCenterRepository()..items = [];
    await pumpCenters(tester, const CentersScreen(), repo);

    expect(find.text('لا توجد مراكز مطابقة'), findsOneWidget);
    final resetBtn = find.byKey(const ValueKey('centers-empty-reset-btn'));
    expect(resetBtn, findsOneWidget);

    await tester.ensureVisible(resetBtn);
    await tester.pumpAndSettle();
    await tester.tap(resetBtn);
    await tester.pumpAndSettle();

    expect(repo.capturedWilayas.last, isNull);
    expect(repo.capturedKinds.last, isNull);
  });

  testWidgets('loading then error can be retried', (tester) async {
    final pending = Completer<List<SupportCenter>>();
    final repo = FakeCenterRepository()..pendingList = pending;
    await pumpCenters(tester, const CentersScreen(), repo);

    expect(find.byType(LoadingView), findsOneWidget);

    pending.completeError(const ApiError(message: 'تعذر الاتصال بقاعدة البيانات'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر الاتصال بقاعدة البيانات'), findsOneWidget);

    repo.pendingList = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('محكمة سيدي امحمد - قسم الأسرة'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('centers list renders without errors in $brightness with long Arabic text', (tester) async {
      final repo = FakeCenterRepository()..items = [sampleCenter(long: true)];
      await pumpCenters(tester, const CentersScreen(), repo, brightness: brightness);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
