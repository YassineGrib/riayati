import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_error.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import 'content_item.dart';
import 'content_repository.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  ContentType? _selectedType;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<ContentItem>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _future = ref.read(contentRepositoryProvider).list(
        type: _selectedType,
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      );
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _load();
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

  IconData _iconForType(ContentType type) {
    return switch (type) {
      ContentType.article => Icons.article_outlined,
      ContentType.law => Icons.gavel_outlined,
      ContentType.ruling => Icons.balance_outlined,
      ContentType.guide => Icons.menu_book_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top bar: Back button + Title
          Row(
            children: [
              IconButton(
                key: const ValueKey('library-back-button'),
                tooltip: 'رجوع',
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
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
            ],
          ),
          const SizedBox(height: RSpace.s2),

          // 2. Search box
          Container(
            height: RSpace.s11,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(RRadius.xl),
              border: Border.all(color: c.border, width: RBorderWidth.thin),
            ),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s3),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: RSpace.s5, color: c.textSecondary),
                const SizedBox(width: RSpace.s2),
                Expanded(
                  child: TextField(
                    key: const ValueKey('library-search-field'),
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    style: RType.body.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'ابحث في المقالات والقوانين…',
                      hintStyle: RType.body.copyWith(color: c.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    key: const ValueKey('library-search-clear'),
                    onTap: () {
                      _searchController.clear();
                      _load();
                    },
                    child: Icon(Icons.close_rounded, size: RSpace.s4, color: c.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(height: RSpace.s3),

          // 3. Type filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(
                  key: const ValueKey('library-chip-all'),
                  label: 'الكل',
                  selected: _selectedType == null,
                  onTap: () {
                    if (_selectedType != null) {
                      setState(() => _selectedType = null);
                      _load();
                    }
                  },
                ),
                for (final type in ContentType.values) ...[
                  const SizedBox(width: RSpace.s2),
                  _buildChip(
                    key: ValueKey('library-chip-${type.value}'),
                    label: type.label,
                    icon: _iconForType(type),
                    selected: _selectedType == type,
                    onTap: () {
                      if (_selectedType != type) {
                        setState(() => _selectedType = type);
                        _load();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: RSpace.s4),

          // 4. Content List / Loading / Empty / Error
          Expanded(
            child: FutureBuilder<List<ContentItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final msg = err is ApiError ? err.message : 'حدث خطأ أثناء محاولة جلب المقالات والنصوص. يُرجى التحقق من اتصال الإنترنت ثم إعادة المحاولة.';
                  return ErrorView(
                    message: msg,
                    onRetry: _load,
                  );
                }

                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  final query = _searchController.text.trim();
                  return EmptyView(
                    title: 'لم نعثر على نتائج مطابقة',
                    body: query.isNotEmpty
                        ? 'لم نجد أي مقالات أو نصوص قانونية تطابق «$query».'
                        : 'لا يوجد محتوى تعليمي منشور حاليًا.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsetsDirectional.only(bottom: RSpace.s6),
                    itemCount: items.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: RSpace.s3),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return _buildLegalNoteBanner(c);
                      }
                      final item = items[index];
                      return _buildContentCard(context, item);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    Key? key,
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final c = context.c;
    return Material(
      key: key,
      color: selected ? c.primary : c.surfaceSunken,
      borderRadius: BorderRadius.circular(RRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RRadius.xl),
        child: Container(
          constraints: const BoxConstraints(minHeight: RSpace.s8),
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: RSpace.s3,
            vertical: RSpace.s1_5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: RSpace.s4,
                  color: selected ? c.onPrimary : c.textSecondary,
                ),
                const SizedBox(width: RSpace.s1_5),
              ],
              Text(
                label,
                style: RType.label.copyWith(
                  color: selected ? c.onPrimary : c.textPrimary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, ContentItem item) {
    final c = context.c;
    final dateText = _formatDate(item.publishedAt);
    final readingTime = '${item.readingTimeMinutes} د قراءة';
    // Each part is isolated so digits of the date and the reading time do not
    // merge into one run in right-to-left text.
    final metaText = dateText.isNotEmpty
        ? '\u2067$dateText\u2069  ·  \u2067$readingTime\u2069'
        : readingTime;

    return RCard(
      onTap: () => context.push('/library/${item.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: RSpace.s2),
          Text(
            item.title,
            style: RType.heading4.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.summary != null && item.summary!.isNotEmpty) ...[
            const SizedBox(height: RSpace.s1),
            Text(
              item.summary!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: RType.caption.copyWith(color: c.textSecondary),
            ),
          ],
          const SizedBox(height: RSpace.s2),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Icon(
              Icons.chevron_left,
              size: RSpace.s5,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalNoteBanner(RColors c) {
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(RRadius.xl),
        border: Border.all(color: c.border, width: RBorderWidth.thin),
      ),
      padding: const EdgeInsetsDirectional.all(RSpace.s3_5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.verified_outlined, size: RSpace.s5, color: c.primary),
          const SizedBox(width: RSpace.s2_5),
          Expanded(
            child: Text(
              'محتوى تعريفي للإرشاد الأولي، ولا يغني عن استشارة مختص أو عن نص القانون الرسمي.',
              style: RType.caption.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
