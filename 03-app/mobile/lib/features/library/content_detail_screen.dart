import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import 'content_item.dart';
import 'content_repository.dart';

class ContentDetailScreen extends ConsumerStatefulWidget {
  const ContentDetailScreen({
    super.key,
    required this.slug,
  });

  final String slug;

  @override
  ConsumerState<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends ConsumerState<ContentDetailScreen> {
  late Future<ContentItem> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ContentDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slug != widget.slug) {
      _load();
    }
  }

  void _load() {
    setState(() {
      _future = ref.read(contentRepositoryProvider).get(widget.slug);
    });
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return formatDay(dt.toLocal(), year: true);
  }

  StatusTone _toneForType(ContentType type) {
    return switch (type) {
      ContentType.article => StatusTone.info,
      ContentType.law => StatusTone.info,
      ContentType.ruling => StatusTone.warning,
      ContentType.guide => StatusTone.success,
    };
  }

  Future<void> _copyContent(ContentItem item) async {
    final buffer = StringBuffer();
    buffer.writeln(item.title);
    if (item.reference != null && item.reference!.isNotEmpty) {
      buffer.writeln('المصدر: ${item.reference}');
    }
    buffer.writeln();
    buffer.writeln(item.cleanBody);

    try {
      await Clipboard.setData(ClipboardData(text: buffer.toString()));
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ نص المقال')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppScaffold(
      body: Column(
        children: [
          // 1. Top Bar: Back button + Title + Copy action
          Row(
            children: [
              IconButton(
                key: const ValueKey('content-detail-back-button'),
                tooltip: 'رجوع',
                onPressed: () => context.canPop() ? context.pop() : context.go('/library'),
                icon: const BackButtonIcon(),
                color: c.textPrimary,
              ),
              Expanded(
                child: Text(
                  'المحتوى التعليمي',
                  style: RType.heading3.copyWith(
                    fontFamily: RType.display.fontFamily,
                    color: c.textPrimary,
                  ),
                ),
              ),
              FutureBuilder<ContentItem>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final item = snapshot.data!;
                  return IconButton(
                    key: const ValueKey('content-detail-copy-button'),
                    tooltip: 'نسخ المحتوى',
                    icon: const Icon(Icons.copy_rounded),
                    color: c.textPrimary,
                    onPressed: () => _copyContent(item),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: RSpace.s2),

          // 2. Detail Body
          Expanded(
            child: FutureBuilder<ContentItem>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final msg = err is ApiError ? err.message : 'تعذر تحميل المحتوى المطلوب.';
                  return ErrorView(
                    message: msg,
                    onRetry: _load,
                  );
                }

                final item = snapshot.data!;
                final dateText = _formatDate(item.publishedAt);
                final readingTime = '${item.readingTimeMinutes} دقائق قراءة';
                // Isolated parts keep the date and reading-time digits apart.
                final metaText = dateText.isNotEmpty
                    ? '\u2067$dateText\u2069  ·  \u2067$readingTime\u2069'
                    : readingTime;

                return SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.only(bottom: RSpace.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge & Reading Meta
                      Row(
                        children: [
                          Flexible(
                            child: StatusChip(
                              label: item.typeLabel,
                              tone: _toneForType(item.type),
                            ),
                          ),
                          const SizedBox(width: RSpace.s2),
                          Expanded(
                            child: Text(
                              metaText,
                              textAlign: TextAlign.end,
                              style: RType.caption.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RSpace.s3),

                      // Title
                      Text(
                        item.title,
                        style: RType.heading1.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: RSpace.s3),

                      // Reference box
                      if (item.reference != null && item.reference!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: c.surfaceSunken,
                            borderRadius: BorderRadius.circular(RRadius.xl),
                            border: Border.all(color: c.border, width: RBorderWidth.thin),
                          ),
                          padding: const EdgeInsetsDirectional.all(RSpace.s3),
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_outline_rounded, size: RSpace.s5, color: c.primary),
                              const SizedBox(width: RSpace.s2),
                              Expanded(
                                child: Text(
                                  'المصدر: ${item.reference}',
                                  style: RType.caption.copyWith(
                                    color: c.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: RSpace.s4),
                      ],

                      // Serif Body Text
                      SelectableText(
                        item.cleanBody,
                        style: RType.bodyLegal.copyWith(
                          color: c.textPrimary,
                        ),
                      ),
                      const SizedBox(height: RSpace.s6),

                      // Caveat notice box
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(RRadius.xl),
                          border: Border.all(color: c.border, width: RBorderWidth.thin),
                        ),
                        padding: const EdgeInsetsDirectional.all(RSpace.s4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: RSpace.s5, color: c.textSecondary),
                            const SizedBox(width: RSpace.s3),
                            Expanded(
                              child: Text(
                                'ملاحظة: تُراعى مصلحة المحضون دائمًا في جميع القرارات القضائية كمعيار أسمى، وتختص محكمة شؤون الأسرة بالفصل في النزاعات.',
                                style: RType.caption.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
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
  }
}
