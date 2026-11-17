import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/api/api_error.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/reports/report_detail_screen.dart';

import 'screen_test_support.dart';

void main() {
  testWidgets('fingerprint is shortened and copies full SHA-256', (
    tester,
  ) async {
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
    await pumpReports(tester, const ReportDetailScreen(7), FakeReports());
    expect(find.text('SHA-256: 0123456789abâ€¦89abcdef'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Ù†Ø³Ø® Ø§Ù„Ø¨ØµÙ…Ø©'));
    await tester.tap(find.byTooltip('Ù†Ø³Ø® Ø§Ù„Ø¨ØµÙ…Ø©'));
    await tester.pumpAndSettle();
    expect(copied, fingerprint);
  });

  testWidgets('each attachment tap fetches a fresh signed link', (
    tester,
  ) async {
    final repo = FakeReports();
    final opened = <Uri>[];
    await pumpReports(
      tester,
      ReportDetailScreen(
        7,
        onOpenLink: (uri) async {
          opened.add(uri);
        },
      ),
      repo,
    );
    for (var i = 0; i < 2; i++) {
      await tester.ensureVisible(find.text('evidence.pdf'));
      await tester.tap(find.text('evidence.pdf'));
      await tester.pumpAndSettle();
    }
    expect(repo.links, [(7, 9), (7, 9)]);
    expect(opened.map((uri) => uri.query), ['signature=1', 'signature=2']);
    repo.linkError = const ApiError(message: 'ØªØ¹Ø°Ø± ÙØªØ­ Ø§Ù„Ù…Ø±ÙÙ‚');
    await tester.tap(find.text('evidence.pdf'));
    await tester.pumpAndSettle();
    expect(find.text('ØªØ¹Ø°Ø± ÙØªØ­ Ø§Ù„Ù…Ø±ÙÙ‚'), findsOneWidget);
  });

  testWidgets('default attachment opener explains platform hook', (
    tester,
  ) async {
    final repo = FakeReports();
    await pumpReports(tester, const ReportDetailScreen(7), repo);
    await tester.ensureVisible(find.text('evidence.pdf'));
    await tester.tap(find.text('evidence.pdf'));
    await tester.pumpAndSettle();
    expect(repo.links.length, 1);
    expect(find.text('ÙØªØ­ Ø§Ù„Ø±ÙˆØ§Ø¨Ø· ØºÙŠØ± Ù…ØªØ§Ø­ Ø­Ø§Ù„ÙŠÙ‹Ø§.'), findsOneWidget);
  });

  testWidgets('PDF calls once while pending and opens downloaded file', (
    tester,
  ) async {
    final pending = Completer<File>();
    final repo = FakeReports()..pendingPdf = pending;
    File? opened;
    await pumpReports(
      tester,
      ReportDetailScreen(
        7,
        onOpenPdf: (file) async {
          opened = file;
        },
      ),
      repo,
    );
    await tester.ensureVisible(reportButton('ØªØ­Ù…ÙŠÙ„ PDF'));
    await tester.tap(reportButton('ØªØ­Ù…ÙŠÙ„ PDF'));
    await tester.pump();
    expect(tester.widget<RButton>(reportButton('ØªØ­Ù…ÙŠÙ„ PDF')).loading, isTrue);
    await tester.tap(reportButton('ØªØ­Ù…ÙŠÙ„ PDF'));
    expect(repo.pdfs, [7]);
    pending.complete(File('downloaded.pdf'));
    await tester.pumpAndSettle();
    expect(opened?.path, 'downloaded.pdf');
  });

  testWidgets('PDF errors are visible and allow retry', (tester) async {
    final repo = FakeReports()
      ..pdfError = const ApiError(message: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ PDF');
    await pumpReports(
      tester,
      ReportDetailScreen(7, onOpenPdf: (_) async {}),
      repo,
    );
    await tapReportButton(tester, 'ØªØ­Ù…ÙŠÙ„ PDF');
    expect(repo.pdfs, [7]);
    expect(find.text('ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ PDF'), findsOneWidget);
    repo.pdfError = null;
    await tapReportButton(tester, 'ØªØ­Ù…ÙŠÙ„ PDF');
    expect(repo.pdfs, [7, 7]);
  });

  testWidgets('detail error retries', (tester) async {
    final repo = FakeReports()
      ..detailError = const ApiError(message: 'ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¨Ù„Ø§Øº');
    await pumpReports(tester, const ReportDetailScreen(7), repo);
    expect(find.text('ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ Ø§Ù„Ø¨Ù„Ø§Øº'), findsOneWidget);
    repo.detailError = null;
    await tapReportButton(tester, 'Ø¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©');
    expect(repo.gets, [7, 7]);
    expect(find.text('ÙˆØµÙ Ø§Ù„ÙˆØ§Ù‚Ø¹Ø© Ø§Ù„Ù…Ø³Ø¬Ù„Ø©'), findsOneWidget);
  });

  testWidgets('platform PDF opening failures are visible', (tester) async {
    final repo = FakeReports();
    await pumpReports(
      tester,
      ReportDetailScreen(
        7,
        onOpenPdf: (_) async {
          throw StateError('No PDF viewer');
        },
      ),
      repo,
    );
    await tapReportButton(tester, 'ØªØ­Ù…ÙŠÙ„ PDF');
    expect(repo.pdfs, [7]);
    expect(find.text('ØªØ¹Ø°Ø± ØªØ­Ù…ÙŠÙ„ PDF. Ø­Ø§ÙˆÙ„ Ù…Ø¬Ø¯Ø¯Ù‹Ø§.'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('long Arabic details and filenames fit in $brightness', (
      tester,
    ) async {
      await pumpReports(
        tester,
        const ReportDetailScreen(7),
        FakeReports()..detail = sampleReport(long: true),
        brightness: brightness,
      );
      await tester.ensureVisible(reportButton('ØªØ­Ù…ÙŠÙ„ PDF'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
