import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/centers/wilaya_filter_sheet.dart';

void main() {
  testWidgets('displays wilayas and search filters list', (tester) async {
    String? selectedResult;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedResult = await showModalBottomSheet<String?>(
                  context: context,
                  builder: (_) => const WilayaFilterSheet(initialWilaya: '16'),
                );
              },
              child: const Text('افتح القائمة'),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('افتح القائمة'));
    await tester.pumpAndSettle();

    expect(find.text('اختر الولاية (58 ولاية)'), findsOneWidget);
    expect(find.text('كل الولايات (عرض الكل)'), findsOneWidget);
    expect(find.text('01 - أدرار'), findsOneWidget);

    // Filter by 'وهران'
    final search = find.byKey(const ValueKey('wilaya-sheet-search-field'));
    await tester.enterText(search, 'وهران');
    await tester.pumpAndSettle();

    expect(find.text('31 - وهران'), findsOneWidget);
    expect(find.text('01 - أدرار'), findsNothing);

    // Select وهران
    await tester.tap(find.byKey(const ValueKey('wilaya-option-31')));
    await tester.pumpAndSettle();

    // Confirm
    await tester.tap(find.byKey(const ValueKey('wilaya-filter-confirm-btn')));
    await tester.pumpAndSettle();

    expect(selectedResult, '31');
  });

  testWidgets('close button dismisses sheet without selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet<String?>(
                  context: context,
                  builder: (_) => const WilayaFilterSheet(),
                );
              },
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    final closeBtn = find.byKey(const ValueKey('wilaya-filter-close-btn'));
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();

    expect(find.text('اختر الولاية (58 ولاية)'), findsNothing);
  });
}
