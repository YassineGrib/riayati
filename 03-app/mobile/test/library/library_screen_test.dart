import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/widgets/state_views.dart';
import 'package:riayati/features/library/content_item.dart';
import 'package:riayati/features/library/library_screen.dart';

import 'library_test_support.dart';

void main() {
  testWidgets('renders library screen and chips filter content by type', (tester) async {
    final repo = FakeContentRepository();
    await pumpLibrary(tester, const LibraryScreen(), repo);

    expect(find.text('المحتوى التعليمي'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-search-field')), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('مقال'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-chip-law')), findsOneWidget);
    expect(find.text('اجتهاد قضائي'), findsOneWidget);
    expect(find.text('دليل'), findsOneWidget);

    expect(repo.capturedTypes, [null]);

    // Tap on 'قانون'
    await tester.tap(find.byKey(const ValueKey('library-chip-law')));
    await tester.pumpAndSettle();
    expect(repo.capturedTypes.last, ContentType.law);

    // Tap on 'مقال'
    await tester.tap(find.byKey(const ValueKey('library-chip-article')));
    await tester.pumpAndSettle();
    expect(repo.capturedTypes.last, ContentType.article);

    // Tap on 'الكل'
    await tester.tap(find.byKey(const ValueKey('library-chip-all')));
    await tester.pumpAndSettle();
    expect(repo.capturedTypes.last, isNull);
  });

  testWidgets('search field triggers search after debounce and clear button resets', (tester) async {
    final repo = FakeContentRepository();
    await pumpLibrary(tester, const LibraryScreen(), repo);

    final searchField = find.byKey(const ValueKey('library-search-field'));
    await tester.enterText(searchField, 'حضانة');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(repo.capturedQueries.last, 'حضانة');

    // Clear search
    final clearBtn = find.byKey(const ValueKey('library-search-clear'));
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(repo.capturedQueries.last, isNull);
  });

  testWidgets('card tap pushes /library/:slug', (tester) async {
    final repo = FakeContentRepository();
    final pushed = <String>[];
    await pumpLibrary(tester, const LibraryScreen(), repo, pushedRoutes: pushed);

    expect(find.text('شروط استحقاق الحضانة وسقوطها'), findsOneWidget);
    await tester.tap(find.text('شروط استحقاق الحضانة وسقوطها'));
    await tester.pumpAndSettle();

    expect(pushed, contains('/library/custody-eligibility'));
  });

  testWidgets('empty state displays empty message', (tester) async {
    final repo = FakeContentRepository()..items = [];
    await pumpLibrary(tester, const LibraryScreen(), repo);

    expect(find.text('لم نعثر على نتائج مطابقة'), findsOneWidget);
    expect(find.text('لا يوجد محتوى تعليمي منشور حاليًا.'), findsOneWidget);
  });

  testWidgets('loading then error can be retried', (tester) async {
    final pending = Completer<List<ContentItem>>();
    final repo = FakeContentRepository()..pendingList = pending;
    await pumpLibrary(tester, const LibraryScreen(), repo);

    expect(find.byType(LoadingView), findsOneWidget);

    pending.completeError(const ApiError(message: 'تعذر الاتصال بالخادم'));
    await tester.pumpAndSettle();

    expect(find.text('تعذر الاتصال بالخادم'), findsOneWidget);

    repo.pendingList = null;
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    expect(find.text('شروط استحقاق الحضانة وسقوطها'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic content renders without errors in $brightness', (tester) async {
      final repo = FakeContentRepository()..items = [sampleContent(long: true)];
      await pumpLibrary(tester, const LibraryScreen(), repo, brightness: brightness);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
