import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../core/api/api_error.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/status_chip.dart';
import 'report.dart';
import 'report_repository.dart';

class ReportSummaryScreen extends ConsumerStatefulWidget {
  const ReportSummaryScreen(this.report, {super.key, this.onOpenPdf});

  final Report report;

  /// Test seam; defaults to opening the downloaded file with OpenFilex.
  final Future<void> Function(File)? onOpenPdf;

  @override
  ConsumerState<ReportSummaryScreen> createState() =>
      _ReportSummaryScreenState();
}

class _ReportSummaryScreenState extends ConsumerState<ReportSummaryScreen> {
  Report get report => widget.report;
  bool _pdfLoading = false;
  String? _pdfError;

  Future<void> _openPdf() async {
    if (_pdfLoading) return;
    setState(() {
      _pdfLoading = true;
      _pdfError = null;
    });
    try {
      final file = await ref.read(reportRepositoryProvider).pdf(report.id);
      if (!mounted) return;
      if (widget.onOpenPdf != null) {
        await widget.onOpenPdf!(file);
      } else {
        final result = await OpenFilex.open(file.path);
        if (result.type != ResultType.done) {
          throw const ApiError(
            message:
                'تعذر فتح PDF. تأكد من وجود تطبيق لقراءة PDF وحاول مجددًا.',
          );
        }
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _pdfError = error is ApiError
              ? error.message
              : 'تعذر تحميل PDF. حاول مجددًا.',
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  String _formatIncidentDate(DateTime dt) => formatDateTime(dt);

  String _attachmentsSummary(Report report) {
    final count = report.attachmentsCount > 0
        ? report.attachmentsCount
        : report.attachments.length;
    if (count == 0) return 'بدون مرفقات';
    if (count == 1) return 'مرفق واحد';
    if (count == 2) return 'مرفقان';
    if (count <= 10) return '$count مرفقات';
    return '$count مرفقًا';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final formattedDate = _formatIncidentDate(report.incidentAt);
    final attachmentsText = _attachmentsSummary(report);

    return AppScaffold(
      title: 'تفاصيل البلاغ',
      leading: SizedBox(
        width: RSpace.s12,
        height: RSpace.s12,
        child: IconButton(
          tooltip: 'رجوع',
          icon: const Icon(Icons.arrow_back),
          color: c.textPrimary,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.only(
          top: RSpace.s2,
          bottom: RSpace.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: RSpace.s16,
                  height: RSpace.s16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.accentSoft,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: RSpace.s8,
                    color: c.actionPrimary,
                  ),
                ),
                const SizedBox(width: RSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تم إرسال البلاغ',
                        style: RType.heading2.copyWith(
                          fontFamily: RType.display.fontFamily,
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: RSpace.s1),
                      Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: RSpace.s3,
                          vertical: RSpace.s0_5,
                        ),
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(RRadius.full),
                        ),
                        child: Text(
                          report.reference,
                          style: RType.label.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: RSpace.s4),

            // Facts Card
            RCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Row
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الحالة',
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                        StatusChip(
                          label: report.status.label,
                          tone: report.status == ReportStatus.reviewed
                              ? StatusTone.success
                              : StatusTone.info,
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: RSpace.s2,
                    thickness: RBorderWidth.thin,
                    color: c.border,
                  ),

                  // Date Row
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تاريخ الحادثة',
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                        Flexible(
                          child: Text(
                            formattedDate,
                            textAlign: TextAlign.end,
                            style: RType.label.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: RSpace.s2,
                    thickness: RBorderWidth.thin,
                    color: c.border,
                  ),

                  // Attachments Row
                  Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'المرفقات',
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                        Text(
                          attachmentsText,
                          style: RType.label.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: RSpace.s2,
                    thickness: RBorderWidth.thin,
                    color: c.border,
                  ),

                  // Description Block
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: RSpace.s3,
                      bottom: RSpace.s1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الوصف',
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: RSpace.s1_5),
                        Text(
                          report.description,
                          style: RType.body.copyWith(
                            color: c.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RSpace.s3),

            // PDF Card
            RCard(
              onTap: _pdfLoading ? null : _openPdf,
              child: Row(
                children: [
                  Container(
                    width: RSpace.s10,
                    height: RSpace.s10,
                    decoration: BoxDecoration(
                      color: c.surfaceSunken,
                      borderRadius: BorderRadius.circular(RRadius.lg),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: RSpace.s5,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(width: RSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تقرير البلاغ',
                          style: RType.label.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _pdfError ??
                              (_pdfLoading
                                  ? 'جارٍ تجهيز الملف…'
                                  : 'اضغط لفتح ملف PDF للأرشفة والمشاركة'),
                          style: RType.caption.copyWith(
                            color: _pdfError != null
                                ? c.feedbackErrorText
                                : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_pdfLoading)
                    const SizedBox(
                      width: RSpace.s5,
                      height: RSpace.s5,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.download_rounded,
                      size: RSpace.s5,
                      color: c.textSecondary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: RSpace.s3),

            // Note on evidence immutability
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: RSpace.s5,
                  color: c.textSecondary,
                ),
                const SizedBox(width: RSpace.s2),
                Expanded(
                  child: Text(
                    'لا يمكن حذف البلاغ بعد إرساله، للحفاظ عليه كدليل.',
                    style: RType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RSpace.s6),

            // Return to Home button
            RButton(
              label: 'العودة للرئيسية',
              kind: RButtonKind.primary,
              onPressed: () {
                if (context.mounted) {
                  context.go('/home');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
