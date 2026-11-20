import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/reports/attachment_compressor.dart';
import 'package:riayati/features/reports/file_rules.dart';
import 'package:riayati/features/reports/new_report_screen.dart';
import 'package:riayati/features/reports/report.dart';
import 'package:riayati/features/reports/report_repository.dart';
import 'package:riayati/features/reports/report_summary_screen.dart';

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
  AttachmentCompressor? compressor,
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
          compressor: compressor,
          initialIncidentAt: initialIncidentAt,
        ),
      ),
      GoRoute(
        path: '/reports/summary',
        builder: (_, state) => ReportSummaryScreen(state.extra! as Report),
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
        attachmentCompressorProvider.overrideWithValue(
          compressor ?? FakeAttachmentCompressor(),
        ),
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
    expect(find.textContaining('دليل.png'), findsOneWidget);
    expect(find.text('1 من 5'), findsOneWidget);

    // Remove the file
    final removeBtn = find.byKey(const ValueKey('remove-file-0'));
    await tester.tap(removeBtn);
    await tester.pumpAndSettle();

    expect(find.textContaining('دليل.png'), findsNothing);
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

  testWidgets('back arrow without unsent content navigates to /home', (tester) async {
    final repo = FakeNewReportRepository();
    final pushed = <String>[];
    await pumpNewReport(tester, repo: repo, pushedRoutes: pushed);

    final backBtn = find.byKey(const ValueKey('new-report-back-button'));
    expect(backBtn, findsOneWidget);

    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(pushed, contains('/home'));
    expect(find.text('تجاهل البلاغ؟'), findsNothing);
  });

  testWidgets('back arrow with unsent description shows discard dialog', (tester) async {
    final repo = FakeNewReportRepository();
    final pushed = <String>[];
    await pumpNewReport(tester, repo: repo, pushedRoutes: pushed);

    await tester.enterText(find.byKey(const ValueKey('report-description-input')), 'نص تجريبي');
    await tester.pumpAndSettle();

    final backBtn = find.byKey(const ValueKey('new-report-back-button'));
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Dialog appears
    expect(find.text('تجاهل البلاغ؟'), findsOneWidget);
    expect(find.byKey(const ValueKey('dialog-continue-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('dialog-discard-button')), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.byKey(const ValueKey('dialog-continue-button')));
    await tester.pumpAndSettle();
    expect(pushed, isEmpty);
    expect(find.text('تجاهل البلاغ؟'), findsNothing);

    // Tap back again and confirm discard
    await tester.tap(backBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dialog-discard-button')));
    await tester.pumpAndSettle();

    expect(pushed, contains('/home'));
  });

  testWidgets('attachments are compressed before upload and compressed copy is sent to repository', (tester) async {
    final repo = FakeNewReportRepository();
    final fakeCompressor = FakeAttachmentCompressor(compressFactor: 0.5);

    await pumpNewReport(
      tester,
      repo: repo,
      compressor: fakeCompressor,
      pickImage: () async => const PickedFile(
        path: '/test/large_photo.jpg',
        name: 'large_photo.jpg',
        size: 10 * 1024 * 1024,
        mime: 'image/jpeg',
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('report-description-input')), 'وصف واقعة صحيح للاختبار');
    await tester.tap(find.byKey(const ValueKey('pick-image-button')));
    await tester.pumpAndSettle();

    expect(fakeCompressor.compressCalls, 1);
    expect(find.textContaining('large_photo.jpg'), findsOneWidget);
    // Shows compressed size (5.0 MB)
    expect(find.textContaining('5.0 MB'), findsOneWidget);

    await tester.tap(submitButton());
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.lastFiles, isNotNull);
    expect(repo.lastFiles!.first.path, contains('.compressed'));
    expect(repo.lastFiles!.first.size, 5 * 1024 * 1024);
  });

  testWidgets('progress is shown during compression and cancel button removes the file', (tester) async {
    final repo = FakeNewReportRepository();
    final fakeCompressor = FakeAttachmentCompressor(
      delay: const Duration(milliseconds: 500),
      reportProgress: true,
    );

    await pumpNewReport(
      tester,
      repo: repo,
      compressor: fakeCompressor,
      pickVideo: () async => const PickedFile(
        path: '/test/clip.mp4',
        name: 'clip.mp4',
        size: 12 * 1024 * 1024,
        mime: 'video/mp4',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pick-video-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Visible per-file "جارٍ الضغط…" progress state
    expect(find.textContaining('جارٍ الضغط…'), findsOneWidget);

    // Cancel / remove while compressing
    final removeBtn = find.byKey(const ValueKey('remove-file-0'));
    expect(removeBtn, findsOneWidget);
    await tester.tap(removeBtn);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.textContaining('clip.mp4'), findsNothing);
    expect(find.textContaining('جارٍ الضغط…'), findsNothing);
  });

  testWidgets('compression failure falls back to original and shows message', (tester) async {
    final repo = FakeNewReportRepository();
    final fakeCompressor = FakeAttachmentCompressor(shouldFail: true);

    await pumpNewReport(
      tester,
      repo: repo,
      compressor: fakeCompressor,
      pickImage: () async => const PickedFile(
        path: '/test/fail_photo.jpg',
        name: 'fail_photo.jpg',
        size: 2 * 1024 * 1024,
        mime: 'image/jpeg',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pick-image-button')));
    await tester.pumpAndSettle();

    expect(find.text('تعذر الضغط، سيُرفع الملف الأصلي'), findsOneWidget);
    expect(find.textContaining('fail_photo.jpg'), findsOneWidget);
  });

  testWidgets('FileRules applies to COMPRESSED size', (tester) async {
    final repo = FakeNewReportRepository();
    // Original is 35MB (which exceeds 30MB limit), but compresses to 14MB
    final fakeCompressor = FakeAttachmentCompressor(compressFactor: 0.4);

    await pumpNewReport(
      tester,
      repo: repo,
      compressor: fakeCompressor,
      pickImage: () async => const PickedFile(
        path: '/test/huge.jpg',
        name: 'huge.jpg',
        size: 35 * 1024 * 1024,
        mime: 'image/jpeg',
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pick-image-button')));
    await tester.pumpAndSettle();

    // Accepted because compressed size (14MB) is under 30MB
    expect(find.textContaining('huge.jpg'), findsOneWidget);
    expect(find.text('1 من 5'), findsOneWidget);
    expect(find.text('حجم الملف يتجاوز الحد الأقصى (30 ميغابايت).'), findsNothing);
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
