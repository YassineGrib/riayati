import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/reports/file_rules.dart';
import 'package:riayati/features/reports/new_report_screen.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/report_repository.dart';

const longArabic = 'وصف طويل للواقعة مع نصوص تفصيلية باللغة العربية للاختبار ';

class FakeNewReportRepository extends Fake implements ReportRepository {
  Report? createdReport;
  Object? createError;
  Completer<Report>? pendingCreate;
  int createCalls = 0;
  String? lastDescription;
  DateTime? lastIncidentAt;
  List<PickedFile>? lastFiles;
  void Function(int sent, int total)? lastOnProgress;

  @override
  Future<Report> create({
    required String description,
    required DateTime incidentAt,
    required List<PickedFile> files,
    void Function(int sent, int total)? onProgress,
  }) async {
    createCalls++;
    lastDescription = description;
    lastIncidentAt = incidentAt;
    lastFiles = files;
    lastOnProgress = onProgress;

    if (createError != null) throw createError!;

    final report = createdReport ??
        Report(
          id: 7,
          reference: 'RIA-2026-0142',
          status: ReportStatus.underReview,
          incidentAt: incidentAt,
          description: description,
          attachmentsCount: files.length,
        );

    if (pendingCreate != null) {
      return await pendingCreate!.future;
    }
    return report;
  }
}

Future<void> pumpNewReport(
  WidgetTester tester, {
  required FakeNewReportRepository repo,
  Brightness brightness = Brightness.light,
  Future<PickedFile?> Function()? pickImage,
  Future<PickedFile?> Function()? pickVideo,
  Future<PickedFile?> Function()? pickDocument,
  DateTime? initialIncidentAt,
  List<String>? pushedRoutes,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    initialLocation: '/reports/new',
    routes: [
      GoRoute(
        path: '/reports/new',
        builder: (_, _) => NewReportScreen(
          pickImage: pickImage,
          pickVideo: pickVideo,
          pickDocument: pickDocument,
          initialIncidentAt: initialIncidentAt,
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, _) {
          pushedRoutes?.add('/home');
          return const Scaffold(body: Text('home screen'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reportRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildTheme(brightness).copyWith(
          splashFactory: InkRipple.splashFactory,
        ),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder submitButton() => find.widgetWithText(RButton, 'إرسال البلاغ');

void main() {
  testWidgets('2-char description is blocked with validation message', (tester) async {
    final repo = FakeNewReportRepository();
    await pumpNewReport(tester, repo: repo);

    // Enter 2 chars
    await tester.enterText(find.byKey(const ValueKey('report-description-input')), 'أب');
    await tester.pumpAndSettle();

    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(repo.createCalls, 0);
    expect(find.text('يجب أن يكون وصف الواقعة بين 3 و5000 حرف.'), findsOneWidget);
  });

  testWidgets('future incident date is blocked', (tester) async {
    final repo = FakeNewReportRepository();
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    await pumpNewReport(
      tester,
      repo: repo,
      initialIncidentAt: tomorrow,
    );

    await tester.enterText(find.byKey(const ValueKey('report-description-input')), 'وصف واقعة صحيح');
    await tester.pumpAndSettle();

    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(repo.createCalls, 0);
    expect(find.text('لا يمكن أن يكون موعد الحادثة في المستقبل.'), findsOneWidget);
  });

  testWidgets('FileRules errors shown for the 6th file', (tester) async {
    final repo = FakeNewReportRepository();
    var fileIndex = 0;
    PickedFile nextFile() {
      fileIndex++;
      return PickedFile(
        path: '/test/photo_$fileIndex.jpg',
        name: 'صورة $fileIndex.jpg',
        size: 1024 * 1024,
        mime: 'image/jpeg',
      );
    }

    await pumpNewReport(
      tester,
      repo: repo,
      pickImage: () async => nextFile(),
    );

    // Add 5 files
    final addImageBtn = find.byKey(const ValueKey('pick-image-button'));
    for (var i = 0; i < 5; i++) {
      await tester.tap(addImageBtn);
      await tester.pumpAndSettle();
    }

    expect(find.text('5 من 5'), findsOneWidget);

    // Try to add 6th file
    await tester.tap(addImageBtn);
    await tester.pumpAndSettle();

    expect(find.text('الحد الأقصى للمرفقات هو 5 ملفات.'), findsOneWidget);
  });

  testWidgets('attachments are removable', (tester) async {
    final repo = FakeNewReportRepository();
    await pumpNewReport(
      tester,
      repo: repo,
      pickImage: () async => const PickedFile(
        path: '/test/img.png',
        name: 'دليل.png',
        size: 2 * 1024 * 1024,
        mime: 'image/png',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pick-image-button')));
    await tester.pumpAndSettle();
    expect(find.text('دليل.png'), findsOneWidget);
    expect(find.text('1 من 5'), findsOneWidget);

    // Remove the file
    final removeBtn = find.byKey(const ValueKey('remove-file-0'));
    await tester.tap(removeBtn);
    await tester.pumpAndSettle();

    expect(find.text('دليل.png'), findsNothing);
    expect(find.text('0 من 5'), findsOneWidget);
  });

  testWidgets('progress is shown during upload', (tester) async {
    final repo = FakeNewReportRepository();
    final completer = Completer<Report>();
    repo.pendingCreate = completer;

    await pumpNewReport(tester, repo: repo);

    await tester.enterText(find.byKey(const ValueKey('report-description-input')), 'وصف واقعة مكتمل للاختبار');
    await tester.pumpAndSettle();

    await tester.tap(submitButton());
    await tester.pump();

    expect(repo.createCalls, 1);
    expect(repo.lastOnProgress, isNotNull);

    // Simulate progress
    repo.lastOnProgress!(60, 100);
    await tester.pump();

    expect(find.byKey(const ValueKey('upload-progress-indicator')), findsOneWidget);
    expect(find.textContaining('60٪'), findsOneWidget);

    // Complete upload
    completer.complete(
      Report(
        id: 7,
        reference: 'RIA-2026-0142',
        status: ReportStatus.underReview,
        incidentAt: DateTime(2026, 11, 17, 9, 30),
        description: 'وصف واقعة مكتمل للاختبار',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RIA-2026-0142'), findsOneWidget);
    expect(find.text('تم إرسال البلاغ'), findsOneWidget);
  });

  testWidgets('server errors shown under the form', (tester) async {
    final repo = FakeNewReportRepository()
      ..createError = const ApiError(message: 'تعذر حفظ البلاغ على الخادم.');

    await pumpNewReport(tester, repo: repo);

    await tester.enterText(find.byKey(const ValueKey('report-description-input')), 'وصف واقعة صالح');
    await tester.pumpAndSettle();

    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(find.text('تعذر حفظ البلاغ على الخادم.'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic text does not overflow in $brightness', (tester) async {
      final repo = FakeNewReportRepository();
      await pumpNewReport(
        tester,
        repo: repo,
        brightness: brightness,
        pickImage: () async => PickedFile(
          path: '/test/long.png',
          name: List.filled(5, longArabic).join(),
          size: 5 * 1024 * 1024,
          mime: 'image/png',
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('report-description-input')),
        List.filled(20, longArabic).join(),
      );
      await tester.tap(find.byKey(const ValueKey('pick-image-button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
