
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' hide PickedFile;
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import 'file_rules.dart';
import 'report_repository.dart';
import 'report_summary_screen.dart';

class NewReportScreen extends ConsumerStatefulWidget {
  const NewReportScreen({
    super.key,
    this.pickImage,
    this.pickVideo,
    this.pickDocument,
    this.initialIncidentAt,
  });

  final Future<PickedFile?> Function()? pickImage;
  final Future<PickedFile?> Function()? pickVideo;
  final Future<PickedFile?> Function()? pickDocument;
  final DateTime? initialIncidentAt;

  @override
  ConsumerState<NewReportScreen> createState() => _NewReportScreenState();
}

class _NewReportScreenState extends ConsumerState<NewReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late DateTime _incidentAt;
  final _files = <PickedFile>[];

  bool _submitting = false;
  double? _uploadProgress;
  String? _serverError;
  String? _fileRuleError;
  String? _dateError;

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
      return '${mb.toStringAsFixed(1)} ميغابايت';
    }
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(0)} كيلوبايت';
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

  Future<void> _handlePick(Future<PickedFile?> Function()? customPicker, String defaultType) async {
    setState(() {
      _fileRuleError = null;
    });

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

      final err = FileRules.check(_files, candidate);
      if (err != null) {
        setState(() {
          _fileRuleError = err;
        });
        return;
      }

      setState(() {
        _files.add(candidate!);
        _fileRuleError = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileRuleError = 'تعذر إضافة الملف. حاول مجددًا.';
        });
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
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

    return AppScaffold(
      title: 'بلاغ جديد',
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
                  hintText: 'صف ما حدث بإيجاز: ماذا، ومتى، وأين، ومن كان حاضرًا.',
                  hintStyle: RType.body.copyWith(color: c.textTertiary),
                  errorStyle: RType.caption.copyWith(color: c.feedbackErrorText),
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
                      color: _dateError != null ? c.borderError : c.borderStrong,
                      width: _dateError != null ? RBorderWidth.medium : RBorderWidth.thin,
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
                    style: RType.label.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_files.length} من ${FileRules.maxFiles}',
                    style: RType.caption.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: RSpace.s2),

              // Picker buttons (Image, Video, Document)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const ValueKey('pick-image-button'),
                      onPressed: _submitting
                          ? null
                          : () => _handlePick(widget.pickImage, 'image'),
                      icon: const Icon(Icons.image_outlined, size: RSpace.s5),
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
                      icon: const Icon(Icons.videocam_outlined, size: RSpace.s5),
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
                          : () => _handlePick(widget.pickDocument, 'document'),
                      icon: const Icon(Icons.attach_file_rounded, size: RSpace.s5),
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
              if (_files.isNotEmpty) ...[
                const SizedBox(height: RSpace.s3),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _files.length,
                  separatorBuilder: (_, _) => const SizedBox(height: RSpace.s2),
                  itemBuilder: (context, index) {
                    final file = _files[index];
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
                            onPressed: _submitting ? null : () => _removeFile(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: RSpace.s3),

              // Limits Text
              Text(
                'حتى 5 ملفات، وبحد أقصى 30 ميغابايت للملف.',
                style: RType.caption.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: RSpace.s2),

              // Privacy note
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: RSpace.s4,
                    color: c.textSecondary,
                  ),
                  const SizedBox(width: RSpace.s1_5),
                  Expanded(
                    child: Text(
                      'لا يطّلع على هذا البلاغ إلا أنت وفريق الإدارة.',
                      style: RType.caption.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RSpace.s6),

              // Upload Progress Bar
              if (_uploadProgress != null) ...[
                Container(
                  key: const ValueKey('upload-progress-indicator'),
                  margin: const EdgeInsetsDirectional.only(bottom: RSpace.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'جارٍ رفع المرفقات...',
                            style: RType.caption.copyWith(color: c.textSecondary),
                          ),
                          Text(
                            '${(_uploadProgress! * 100).toInt()}٪',
                            style: RType.caption.copyWith(
                              color: c.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RSpace.s1_5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(RRadius.full),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: c.border,
                          valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                          minHeight: RSpace.s1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Submit Button
              RButton(
                label: 'إرسال البلاغ',
                kind: RButtonKind.primary,
                loading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),

              // Server Error under form
              if (_serverError != null) ...[
                const SizedBox(height: RSpace.s3),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
