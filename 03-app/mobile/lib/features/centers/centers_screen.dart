import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../profile/wilayas.dart';
import 'center_repository.dart';
import 'support_center.dart';
import 'wilaya_filter_sheet.dart';

class CentersScreen extends ConsumerStatefulWidget {
  const CentersScreen({super.key});

  @override
  ConsumerState<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends ConsumerState<CentersScreen> {
  CenterKind? _selectedKind;
  String? _selectedWilaya;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  late Future<List<SupportCenter>> _future;

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
      _future = ref.read(centerRepositoryProvider).list(
        kind: _selectedKind,
        wilaya: _selectedWilaya,
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

  String _getWilayaLabel(String wVal) {
    final wNumber = int.tryParse(wVal);
    if (wNumber != null) {
      for (final w in wilayas) {
        if (w.number == wNumber) {
          return w.label;
        }
      }
    }
    return wVal;
  }

  Future<void> _openWilayaFilter() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WilayaFilterSheet(initialWilaya: _selectedWilaya),
    );
    if (result != _selectedWilaya) {
      setState(() => _selectedWilaya = result);
      _load();
    }
  }

  StatusTone _toneForKind(CenterKind kind) {
    return switch (kind) {
      CenterKind.court => StatusTone.info,
      CenterKind.legalAid => StatusTone.info,
      CenterKind.childProtection => StatusTone.warning,
      CenterKind.psychological => StatusTone.success,
      CenterKind.social => StatusTone.info,
      CenterKind.ngo => StatusTone.neutral,
      CenterKind.hotline => StatusTone.error,
    };
  }

  Future<void> _callPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: clean);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Top Bar: Back button + Title
          Row(
            children: [
              IconButton(
                key: const ValueKey('centers-back-button'),
                tooltip: 'رجوع',
                onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                icon: const BackButtonIcon(),
                color: c.textPrimary,
              ),
              Expanded(
                child: Text(
                  'مراكز وهيئات',
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
                    key: const ValueKey('centers-search-field'),
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _load(),
                    style: RType.body.copyWith(color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'ابحث باسم المركز أو العنوان…',
                      hintStyle: RType.body.copyWith(color: c.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    key: const ValueKey('centers-search-clear'),
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

          // 3. Wilaya filter button & Demo badge row
          Row(
            children: [
              // Wilaya filter button
              Expanded(
                child: Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RRadius.xl),
                    side: BorderSide(color: c.border, width: RBorderWidth.thin),
                  ),
                  child: InkWell(
                    key: const ValueKey('centers-wilaya-filter-btn'),
                    onTap: _openWilayaFilter,
                    borderRadius: BorderRadius.circular(RRadius.xl),
                    child: Container(
                      height: RSpace.s9,
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s3),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: RSpace.s4, color: c.primary),
                          const SizedBox(width: RSpace.s2),
                          Expanded(
                            child: Text(
                              _selectedWilaya != null
                                  ? 'الولاية: ${_getWilayaLabel(_selectedWilaya!)}'
                                  : 'الولاية: كل الولايات',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RType.caption.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down_rounded, size: RSpace.s4, color: c.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: RSpace.s2),

              // Demo badge
              Container(
                height: RSpace.s9,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s3),
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
                  borderRadius: BorderRadius.circular(RRadius.xl),
                  border: Border.all(color: c.border, width: RBorderWidth.thin),
                ),
                alignment: Alignment.center,
                child: Text(
                  'بيانات تجريبية',
                  style: RType.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: RSpace.s3),

          // 4. Kind filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip(
                  key: const ValueKey('centers-chip-all'),
                  label: 'الكل',
                  selected: _selectedKind == null,
                  onTap: () {
                    if (_selectedKind != null) {
                      setState(() => _selectedKind = null);
                      _load();
                    }
                  },
                ),
                for (final kind in CenterKind.values) ...[
                  const SizedBox(width: RSpace.s2),
                  _buildChip(
                    key: ValueKey('centers-chip-${kind.value}'),
                    label: kind.label,
                    selected: _selectedKind == kind,
                    onTap: () {
                      if (_selectedKind != kind) {
                        setState(() => _selectedKind = kind);
                        _load();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: RSpace.s4),

          // 5. Centers list
          Expanded(
            child: FutureBuilder<List<SupportCenter>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final msg = err is ApiError ? err.message : 'تعذر تحميل بيانات المراكز والهيئات.';
                  return ErrorView(
                    message: msg,
                    onRetry: _load,
                  );
                }

                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return EmptyView(
                    title: 'لا توجد مراكز مطابقة',
                    body: 'لم نعثر على أي مراكز قضائية أو هيئات حماية تطابق البحث. يمكنك تصفح باقي الولايات.',
                    action: RButton(
                      key: const ValueKey('centers-empty-reset-btn'),
                      label: 'عرض جميع المراكز في الوطن',
                      onPressed: () {
                        setState(() {
                          _selectedWilaya = null;
                          _selectedKind = null;
                          _searchController.clear();
                        });
                        _load();
                      },
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView.separated(
                    padding: const EdgeInsetsDirectional.only(bottom: RSpace.s6),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: RSpace.s3),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildCenterCard(context, item);
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
          child: Text(
            label,
            style: RType.label.copyWith(
              color: selected ? c.onPrimary : c.textPrimary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterCard(BuildContext context, SupportCenter item) {
    final c = context.c;
    final phone = item.phone ?? item.hotline;

    return RCard(
      onTap: () => context.push('/centers/${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: StatusChip(
                  label: item.kindLabel,
                  tone: _toneForKind(item.kind),
                ),
              ),
              if (item.wilayaLabel != null) ...[
                const SizedBox(width: RSpace.s2),
                Expanded(
                  child: Text(
                    item.wilayaLabel!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: RSpace.s2),
          Text(
            item.name,
            style: RType.heading4.copyWith(
              color: c.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.address != null && item.address!.isNotEmpty) ...[
            const SizedBox(height: RSpace.s1),
            Row(
              children: [
                Icon(Icons.place_outlined, size: RSpace.s4, color: c.textSecondary),
                const SizedBox(width: RSpace.s1),
                Expanded(
                  child: Text(
                    item.address!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RType.caption.copyWith(color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: RSpace.s3),
            Material(
              color: c.surfaceSunken,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(RRadius.lg),
                side: BorderSide(color: c.border, width: RBorderWidth.thin),
              ),
              child: InkWell(
                key: ValueKey('center-call-btn-${item.id}'),
                onTap: () => _callPhone(phone),
                borderRadius: BorderRadius.circular(RRadius.lg),
                child: Container(
                  height: RSpace.s9,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s3),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_outlined, size: RSpace.s4, color: c.primary),
                      const SizedBox(width: RSpace.s2),
                      Flexible(
                        child: Text(
                          'اتصال: $phone (تجريبي)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RType.caption.copyWith(
                            color: c.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
