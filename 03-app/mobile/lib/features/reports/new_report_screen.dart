import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import 'attachment_compressor.dart';
import 'file_rules.dart';
import 'report_repository.dart';
import 'report_summary_screen.dart';

class AttachmentEntry {
  AttachmentEntry({
    required this.original,
    this.compressed,
    this.isCompressing = false,
    this.progress = 0.0,
    this.cancelled = false,
    this.failed = false,
  });

  final PickedFile original;
  PickedFile? compressed;
  bool isCompressing;
  double progress;
  bool cancelled;
  bool failed;

  PickedFile get effectiveFile => compressed ?? original;
}

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({
    super.key,
    this.pickImage,
    this.pickVideo,
    this.pickDocument,
    this.compressor,
    this.initialIncidentAt,
  });

  final Future<PickedFile?> Function()? pickImage;
  final Future<PickedFile?> Function()? pickVideo;
  final Future<PickedFile?> Function()? pickDocument;
  final AttachmentCompressor? compressor;
  final DateTime? initialIncidentAt;

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late DateTime _incidentAt;
  final _attachments = <AttachmentEntry>[];

  bool _submitting = false;
  double? _uploadProgress;
  String? _serverError;
  String? _fileRuleError;
  String? _dateError;

  List<PickedFile> get _files =>
      _attachments.map((e) => e.effectiveFile).toList();

  bool get _hasUnsentContent =>
      _descriptionController.text.trim().isNotEmpty || _attachments.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _incidentAt = widget.initialIncidentAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatIncidentDate(DateTime dt) {
    try {
      return DateFormat('d MMMM yyyy · HH:mm', 'ar').format(dt);
    } catch (_) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes >= 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _incidentAt.isAfter(now) ? now : _incidentAt,
      firstDate: DateTime(2020),
      lastDate: now,
      locale: const Locale('ar'),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentAt),
    );
    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _incidentAt = combined;
      if (_incidentAt.isAfter(DateTime.now())) {
        _dateError = 'لا يمكن أن يكون موعد الحادثة في المستقبل.';
      } else {
        _dateError = null;
      }
    });
  }

  Future<bool> _confirmDiscardIfNeeded() async {
    if (!_hasUnsentContent) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final dc = dialogCtx.c;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: dc.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RRadius.x2xl),
            ),
            title: Text(
              'تجاهل البلاغ؟',
              style: RType.heading3.copyWith(
                fontFamily: RType.display.fontFamily,
                color: dc.textPrimary,
              ),
            ),
            content: Text(
              'لديك بيانات غير محفوظة. هل تريد تجاهل البلاغ؟',
              style: RType.body.copyWith(color: dc.textSecondary),
            ),
            actions: [
              TextButton(
                key: const ValueKey('dialog-continue-button'),
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                child: Text(
                  'متابعة الكتابة',
                  style: RType.label.copyWith(color: dc.actionPrimary),
                ),
              ),
              TextButton(
                key: const ValueKey('dialog-discard-button'),
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                child: Text(
                  'تجاهل',
                  style: RType.label.copyWith(color: dc.actionDestructive),
                ),
              ),
            ],
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _handleBack() async {
    final shouldLeave = await _confirmDiscardIfNeeded();
    if (shouldLeave && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    }
  }

  Future<void> _handlePick(
    Future<PickedFile?> Function()? customPicker,
    String defaultType,
  ) async {
    setState(() {
      _fileRuleError = null;
    });

    if (_attachments.length >= FileRules.maxFiles) {
      setState(() {
        _fileRuleError = 'الحد الأقصى للمرفقات هو ${FileRules.maxFiles} ملفات.';
      });
      return;
    }

    try {
      PickedFile? candidate;
      if (customPicker != null) {
        candidate = await customPicker();
      } else {
        if (defaultType == 'image') {
          final picker = ImagePicker();
          final picked = await picker.pickImage(source: ImageSource.gallery);
          if (picked != null) {
            final len = await picked.length();
            candidate = PickedFile(
              path: picked.path,
              name: picked.name,
              size: len,
              mime: picked.mimeType ?? 'image/jpeg',
            );
          }
        } else if (defaultType == 'video') {
          final picker = ImagePicker();
          final picked = await picker.pickVideo(source: ImageSource.gallery);
          if (picked != null) {
            final len = await picked.length();
            candidate = PickedFile(
              path: picked.path,
              name: picked.name,
              size: len,
              mime: picked.mimeType ?? 'video/mp4',
            );
          }
        } else if (defaultType == 'document') {
          final result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: const ['pdf'],
          );
          if (result.isNotEmpty) {
            final f = result.first;
            final path = f.path;
            if (path != null) {
              final size = f.lengthSync() ?? (await f.length()) ?? 0;
              candidate = PickedFile(
                path: path,
                name: f.name,
                size: size,
                mime: 'application/pdf',
              );
            }
          }
        }
      }

      if (candidate == null || !mounted) return;

      final normMime = candidate.mime.toLowerCase().split(';').first.trim();
      final isPdf = normMime == 'application/pdf';

      if (isPdf) {
        final err = FileRules.check(_files, candidate);
        if (err != null) {
          setState(() {
            _fileRuleError = err;
          });
          return;
        }

        setState(() {
          _attachments.add(AttachmentEntry(original: candidate!));
          _fileRuleError = null;
        });
        return;
      }

      // Images and Videos are compressed BEFORE upload
      final entry = AttachmentEntry(
        original: candidate,
        isCompressing: true,
      );

      setState(() {
        _attachments.add(entry);
        _fileRuleError = null;
      });

      _compressAttachment(entry);
    } catch (_) {
      if (mounted) {
        setState(() {
          _fileRuleError = 'تعذر إضافة الملف. حاول مجددًا.';
        });
      }
    }
  }

  Future<void> _compressAttachment(AttachmentEntry entry) async {
    final AttachmentCompressor compressor =
        widget.compressor ?? ref.read(attachmentCompressorProvider);

    try {
      final compressed = await compressor.compress(
        entry.original,
        onProgress: (p) {
          if (mounted && !entry.cancelled) {
            setState(() {
              entry.progress = p;
            });
          }
        },
        isCancelled: () => entry.cancelled,
      );

      if (!mounted || entry.cancelled) return;

      final existingFiles = _attachments
          .where((e) => e != entry && !e.isCompressing)
          .map((e) => e.effectiveFile)
          .toList();

      // FileRules is applied to the COMPRESSED file size
      final err = FileRules.check(existingFiles, compressed);
      if (err != null) {
        setState(() {
          _attachments.remove(entry);
          _fileRuleError = err;
        });
        return;
      }

      setState(() {
        entry.compressed = compressed;
        entry.isCompressing = false;
        _fileRuleError = null;
      });
    } catch (_) {
      if (!mounted || entry.cancelled) return;

      // Fallback to the original file
      final existingFiles = _attachments
          .where((e) => e != entry && !e.isCompressing)
          .map((e) => e.effectiveFile)
          .toList();

      final err = FileRules.check(existingFiles, entry.original);
      if (err != null) {
        setState(() {
          _attachments.remove(entry);
          _fileRuleError = err;
        });
        return;
      }

      setState(() {
        entry.failed = true;
        entry.isCompressing = false;
        _fileRuleError = 'تعذر الضغط، سيُرفع الملف الأصلي';
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      final entry = _attachments.removeAt(index);
      entry.cancelled = true;
      _fileRuleError = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _serverError = null;
    });

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (_incidentAt.isAfter(DateTime.now())) {
      setState(() {
        _dateError = 'لا يمكن أن يكون موعد الحادثة في المستقبل.';
      });
      return;
    }

    if (_attachments.any((e) => e.isCompressing)) {
      setState(() {
        _fileRuleError = 'يرجى الانتظار حتى اكتمال ضغط الملفات.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _uploadProgress = 0.0;
    });

    try {
      final repo = ref.read(reportRepositoryProvider);
      final report = await repo.create(
        description: _descriptionController.text.trim(),
        incidentAt: _incidentAt,
        files: _files,
        onProgress: (sent, total) {
          if (mounted && total > 0) {
            setState(() {
              _uploadProgress = sent / total;
            });
          }
        },
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ReportSummaryScreen(report),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _uploadProgress = null;
        if (error is ApiError) {
          _serverError = error.message;
        } else {
          _serverError = 'تعذر إرسال البلاغ. تحقق من الاتصال وحاول مجددًا.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final formattedDate = _formatIncidentDate(_incidentAt);

    return PopScope(
      canPop: !_hasUnsentContent,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: AppScaffold(
        title: 'بلاغ جديد',
        leading: SizedBox(
          width: RSpace.s12,
          height: RSpace.s12,
          child: IconButton(
            key: const ValueKey('new-report-back-button'),
            tooltip: 'رجوع',
            icon: const Icon(Icons.arrow_back),
            color: c.textPrimary,
            onPressed: _handleBack,
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.only(
              top: RSpace.s2,
              bottom: RSpace.s8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Description Label & Field
                Text(
                  'ماذا حدث؟',
                  style: RType.label.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: RSpace.s1_5),
                TextFormField(
                  key: const ValueKey('report-description-input'),
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 8,
                  textAlign: TextAlign.start,
                  style: RType.body.copyWith(color: c.textPrimary),
                  cursorColor: c.primary,
                  validator: (val) {
                    final text = val?.trim() ?? '';
                    if (text.length < 3 || text.length > 5000) {
                      return 'يجب أن يكون وصف الواقعة بين 3 و5000 حرف.';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText:
                        'صف ما حدث بإيجاز: ماذا، ومتى، وأين، ومن كان حاضرًا.',
                    hintStyle: RType.body.copyWith(color: c.textTertiary),
                    errorStyle:
                        RType.caption.copyWith(color: c.feedbackErrorText),
                    filled: true,
                    fillColor: c.surface,
                    contentPadding: const EdgeInsetsDirectional.all(RSpace.s4),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RRadius.xl),
                      borderSide: BorderSide(
                        color: c.borderStrong,
                        width: RBorderWidth.thin,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RRadius.xl),
                      borderSide: BorderSide(
                        color: c.borderFocus,
                        width: RBorderWidth.medium,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RRadius.xl),
                      borderSide: BorderSide(
                        color: c.borderError,
                        width: RBorderWidth.medium,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RRadius.xl),
                      borderSide: BorderSide(
                        color: c.borderError,
                        width: RBorderWidth.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: RSpace.s4),

                // Date/Time Label & Picker
                Text(
                  'تاريخ الحادثة ووقتها',
                  style: RType.label.copyWith(color: c.textPrimary),
                ),
                const SizedBox(height: RSpace.s1_5),
                InkWell(
                  onTap: _submitting ? null : _selectDateTime,
                  borderRadius: BorderRadius.circular(RRadius.xl),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: RSpace.s14),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: RSpace.s4,
                      vertical: RSpace.s3,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(RRadius.xl),
                      border: Border.all(
                        color:
                            _dateError != null ? c.borderError : c.borderStrong,
                        width: _dateError != null
                            ? RBorderWidth.medium
                            : RBorderWidth.thin,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: RSpace.s5,
                          color: c.textSecondary,
                        ),
                        const SizedBox(width: RSpace.s3),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: RType.body.copyWith(color: c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_dateError != null) ...[
                  const SizedBox(height: RSpace.s1),
                  Text(
                    _dateError!,
                    style: RType.caption.copyWith(color: c.feedbackErrorText),
                  ),
                ],
                const SizedBox(height: RSpace.s4),

                // Attachments Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المرفقات',
                      style: RType.label.copyWith(color: c.textPrimary),
                    ),
                    Text(
                      '${_attachments.length} من ${FileRules.maxFiles}',
                      style: RType.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: RSpace.s1_5),

                // Attachments action buttons (image, video, document)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('pick-image-button'),
                        onPressed: _submitting
                            ? null
                            : () => _handlePick(widget.pickImage, 'image'),
                        icon:
                            const Icon(Icons.image_outlined, size: RSpace.s5),
                        label: const Text('صورة'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(
                            color: c.borderStrong,
                            width: RBorderWidth.thin,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RRadius.xl),
                          ),
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: RSpace.s3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: RSpace.s2),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('pick-video-button'),
                        onPressed: _submitting
                            ? null
                            : () => _handlePick(widget.pickVideo, 'video'),
                        icon: const Icon(Icons.videocam_outlined,
                            size: RSpace.s5),
                        label: const Text('فيديو'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(
                            color: c.borderStrong,
                            width: RBorderWidth.thin,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RRadius.xl),
                          ),
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: RSpace.s3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: RSpace.s2),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const ValueKey('pick-file-button'),
                        onPressed: _submitting
                            ? null
                            : () =>
                                _handlePick(widget.pickDocument, 'document'),
                        icon: const Icon(Icons.attach_file_rounded,
                            size: RSpace.s5),
                        label: const Text('ملف'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: c.textPrimary,
                          side: BorderSide(
                            color: c.borderStrong,
                            width: RBorderWidth.thin,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RRadius.xl),
                          ),
                          padding: const EdgeInsetsDirectional.symmetric(
                            vertical: RSpace.s3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // FileRules error message if any
                if (_fileRuleError != null) ...[
                  const SizedBox(height: RSpace.s2),
                  Container(
                    padding: const EdgeInsetsDirectional.all(RSpace.s3),
                    decoration: BoxDecoration(
                      color: c.feedbackErrorBg,
                      borderRadius: BorderRadius.circular(RRadius.lg),
                      border: Border.all(
                        color: c.feedbackErrorBorder,
                        width: RBorderWidth.thin,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: RSpace.s5,
                          color: c.feedbackErrorIcon,
                        ),
                        const SizedBox(width: RSpace.s2),
                        Expanded(
                          child: Text(
                            _fileRuleError!,
                            style: RType.caption.copyWith(
                              color: c.feedbackErrorText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Picked files list
                if (_attachments.isNotEmpty) ...[
                  const SizedBox(height: RSpace.s3),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _attachments.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: RSpace.s2),
                    itemBuilder: (context, index) {
                      final entry = _attachments[index];
                      final file = entry.effectiveFile;
                      final isImage = file.mime.startsWith('image/');
                      final isVideo = file.mime.startsWith('video/');
                      final icon = isImage
                          ? Icons.image_outlined
                          : isVideo
                              ? Icons.videocam_outlined
                              : Icons.description_outlined;

                      return RCard(
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
                                icon,
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
                                    file.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: RType.label.copyWith(
                                      color: c.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (entry.isCompressing)
                                    Text(
                                      entry.progress > 0
                                          ? 'جارٍ الضغط… (${(entry.progress * 100).toInt()}%)'
                                          : 'جارٍ الضغط…',
                                      style: RType.caption.copyWith(
                                        color: c.accentDefault,
                                      ),
                                    )
                                  else
                                    Text(
                                      _formatFileSize(file.size),
                                      style: RType.caption.copyWith(
                                        color: c.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              key: ValueKey('remove-file-$index'),
                              icon: const Icon(Icons.close_rounded),
                              iconSize: RSpace.s5,
                              color: c.textSecondary,
                              onPressed: _submitting
                                  ? null
                                  : () => _removeFile(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: RSpace.s3),

                // Submit error message if any
                if (_serverError != null) ...[
                  Container(
                    padding: const EdgeInsetsDirectional.all(RSpace.s3),
                    decoration: BoxDecoration(
                      color: c.feedbackErrorBg,
                      borderRadius: BorderRadius.circular(RRadius.lg),
                      border: Border.all(
                        color: c.feedbackErrorBorder,
                        width: RBorderWidth.thin,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: RSpace.s5,
                          color: c.feedbackErrorIcon,
                        ),
                        const SizedBox(width: RSpace.s2),
                        Expanded(
                          child: Text(
                            _serverError!,
                            style: RType.caption.copyWith(
                              color: c.feedbackErrorText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RSpace.s3),
                ],

                // Upload progress indicator
                if (_uploadProgress != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'جارٍ رفع البلاغ…',
                        style: RType.caption.copyWith(color: c.textSecondary),
                      ),
                      Text(
                        '${(_uploadProgress! * 100).toInt()}٪',
                        style: RType.caption.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RSpace.s1_5),
                  LinearProgressIndicator(
                    key: const ValueKey('upload-progress-indicator'),
                    value: _uploadProgress,
                    backgroundColor: c.borderStrong,
                    color: c.primary,
                    minHeight: RSpace.s1_5,
                    borderRadius: BorderRadius.circular(RRadius.full),
                  ),
                  const SizedBox(height: RSpace.s4),
                ],

                // Submit button
                RButton(
                  key: const ValueKey('submit-report-button'),
                  label: 'إرسال البلاغ',
                  kind: RButtonKind.primary,
                  loading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
