import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:open_filex/open_filex.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import 'report.dart';
import 'report_repository.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  const ReportDetailScreen(
    this.id, {
    super.key,
    this.onOpenLink,
    this.onOpenPdf,
  });

  final int id;

  /// The host supplies a platform URL opener. Signed URLs are fetched per tap.
  final Future<void> Function(Uri)? onOpenLink;

  /// Optional platform seam; defaults to opening the downloaded file with OpenFilex.
  final Future<void> Function(File)? onOpenPdf;

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  late Future<Report> _report;
  bool _pdfLoading = false;
  String? _pdfError;
  final _opening = <int>{};
  final _attachmentErrors = <int, String>{};
  static const _fingerprintPrefixLength = 12;
  static const _fingerprintSuffixLength = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ReportDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _pdfError = null;
      _attachmentErrors.clear();
      _load();
    }
  }

  void _load() {
    _report = ref.read(reportRepositoryProvider).get(widget.id);
  }

  String _message(Object error, String fallback) =>
      error is ApiError ? error.message : fallback;

  void _notice(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pdf() async {
    if (_pdfLoading) return;
    final id = widget.id;
    setState(() {
      _pdfLoading = true;
      _pdfError = null;
    });
    try {
      final file = await ref.read(reportRepositoryProvider).pdf(id);
      if (!mounted || widget.id != id) return;
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
      if (mounted && widget.id == id) {
        setState(
          () => _pdfError = _message(error, 'تعذر تحميل PDF. حاول مجددًا.'),
        );
      }
    } finally {
      if (mounted) setState(() => _pdfLoading = false);
    }
  }

  Future<void> _openAttachment(ReportAttachment attachment) async {
    if (_opening.contains(attachment.id)) return;
    final reportId = widget.id;
    setState(() {
      _opening.add(attachment.id);
      _attachmentErrors.remove(attachment.id);
    });
    try {
      // Do not retain this signed URI in screen state or in a provider.
      final uri = await ref
          .read(reportRepositoryProvider)
          .attachmentLink(reportId, attachment.id);
      if (!mounted || widget.id != reportId) return;
      if (widget.onOpenLink != null) {
        await widget.onOpenLink!(uri);
      } else {
        _notice('فتح الروابط غير متاح حاليًا.');
      }
    } catch (error) {
      if (mounted && widget.id == reportId) {
        setState(
          () => _attachmentErrors[attachment.id] = _message(
            error,
            'تعذر فتح المرفق. حاول مجددًا.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening.remove(attachment.id));
    }
  }

  Future<void> _copyFingerprint(String fingerprint) async {
    try {
      await Clipboard.setData(ClipboardData(text: fingerprint));
      if (mounted) _notice('تم نسخ البصمة');
    } catch (_) {
      if (mounted) _notice('تعذر نسخ البصمة. حاول مجددًا.');
    }
  }

  String _shortFingerprint(String value) {
    if (value.length <= _fingerprintPrefixLength + _fingerprintSuffixLength) {
      return value;
    }
    return '${value.substring(0, _fingerprintPrefixLength)}…${value.substring(value.length - _fingerprintSuffixLength)}';
  }

  Widget _error(String message) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: RType.caption.copyWith(color: context.c.feedbackErrorText),
    ),
  );

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/reports'),
              icon: const BackButtonIcon(),
              color: context.c.textPrimary,
            ),
            Expanded(
              child: Text(
                'تفاصيل البلاغ',
                style: RType.heading3.copyWith(
                  fontFamily: RType.display.fontFamily,
                  color: context.c.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: FutureBuilder<Report>(
            future: _report,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return ErrorView(
                  message: _message(
                    snapshot.error!,
                    'تعذر تحميل البلاغ. تحقق من اتصالك وحاول مجددًا.',
                  ),
                  onRetry: () => setState(_load),
                );
              }
              final report = snapshot.requireData;
              return SingleChildScrollView(
                padding: const EdgeInsetsDirectional.symmetric(
                  vertical: RSpace.s4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: StatusChip(
                          label: report.reference,
                          tone: StatusTone.neutral,
                        ),
                      ),
                    ),
                    const SizedBox(height: RSpace.s4),
                    RCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: RSpace.s3,
                            runSpacing: RSpace.s2,
                            children: [
                              Text(
                                'الحالة',
                                style: RType.caption.copyWith(
                                  color: context.c.textSecondary,
                                ),
                              ),
                              StatusChip(
                                label: report.status.label,
                                tone: report.status == ReportStatus.reviewed
                                    ? StatusTone.success
                                    : StatusTone.info,
                              ),
                            ],
                          ),
                          _divider(),
                          Text(
                            'تاريخ الحادثة',
                            style: RType.caption.copyWith(
                              color: context.c.textSecondary,
                            ),
                          ),
                          Text(
                            (DateFormat('d MMMM yyyy · HH:mm', 'ar')
                                  ..useNativeDigits = false)
                                .format(report.incidentAt.toLocal()),
                            style: RType.label.copyWith(
                              color: context.c.textPrimary,
                            ),
                          ),
                          _divider(),
                          Text(
                            'المرفقات',
                            style: RType.caption.copyWith(
                              color: context.c.textSecondary,
                            ),
                          ),
                          Text(
                            switch (report.attachments.length) {
                              0 => 'بدون مرفقات',
                              1 => 'ملف واحد',
                              2 => 'ملفان',
                              final count => '$count ملفات',
                            },
                            style: RType.label.copyWith(
                              color: context.c.textPrimary,
                            ),
                          ),
                          _divider(),
                          Text(
                            'الوصف',
                            style: RType.caption.copyWith(
                              color: context.c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: RSpace.s2),
                          Text(
                            report.description,
                            style: RType.body.copyWith(
                              color: context.c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RSpace.s3),
                    if (report.attachments.isNotEmpty) ...[
                      Text(
                        'المرفقات',
                        style: RType.heading4.copyWith(
                          color: context.c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: RSpace.s2),
                      for (final attachment in report.attachments) ...[
                        _attachment(attachment),
                        const SizedBox(height: RSpace.s3),
                      ],
                    ],
                    RButton(
                      label: 'تحميل PDF',
                      icon: Icons.download_outlined,
                      loading: _pdfLoading,
                      onPressed: _pdf,
                    ),
                    if (_pdfError != null) ...[
                      const SizedBox(height: RSpace.s2),
                      _error(_pdfError!),
                    ],
                    const SizedBox(height: RSpace.s4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: RSpace.s5,
                          color: context.c.textSecondary,
                        ),
                        const SizedBox(width: RSpace.s2),
                        Expanded(
                          child: Text(
                            'لا يمكن حذف البلاغ بعد إرساله، للحفاظ عليه كدليل.',
                            style: RType.caption.copyWith(
                              color: context.c.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsetsDirectional.symmetric(vertical: RSpace.s3),
    child: Divider(
      height: RBorderWidth.thin,
      thickness: RBorderWidth.thin,
      color: context.c.border,
    ),
  );

  Widget _attachment(ReportAttachment attachment) => RCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          onPressed: _opening.contains(attachment.id)
              ? null
              : () => _openAttachment(attachment),
          style: TextButton.styleFrom(
            foregroundColor: context.c.textPrimary,
            minimumSize: const Size(RSpace.s12, RSpace.s12),
            padding: const EdgeInsetsDirectional.all(RSpace.s0),
          ),
          child: Row(
            children: [
              Icon(
                attachment.mime.startsWith('image/')
                    ? Icons.image_outlined
                    : attachment.mime.startsWith('video/')
                    ? Icons.videocam_outlined
                    : Icons.description_outlined,
                size: RSpace.s6,
              ),
              const SizedBox(width: RSpace.s3),
              Expanded(
                child: Text(
                  attachment.filename,
                  textAlign: TextAlign.start,
                  style: RType.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: RSpace.s2),
              if (_opening.contains(attachment.id))
                SizedBox.square(
                  dimension: RSpace.s5,
                  child: CircularProgressIndicator(
                    strokeWidth: RBorderWidth.medium,
                    color: context.c.primary,
                  ),
                )
              else
                const Icon(Icons.open_in_new, size: RSpace.s5),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'SHA-256: ${_shortFingerprint(attachment.sha256)}',
                textDirection: TextDirection.ltr,
                style: RType.caption.copyWith(color: context.c.textSecondary),
              ),
            ),
            IconButton(
              tooltip: 'نسخ البصمة',
              onPressed: () => _copyFingerprint(attachment.sha256),
              icon: Icon(
                Icons.copy_outlined,
                size: RSpace.s5,
                color: context.c.textSecondary,
              ),
            ),
          ],
        ),
        if (_attachmentErrors[attachment.id] != null)
          _error(_attachmentErrors[attachment.id]!),
      ],
    ),
  );
}
