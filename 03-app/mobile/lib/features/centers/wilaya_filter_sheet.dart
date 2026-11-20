import 'package:flutter/material.dart';

import '../../core/theme/tokens.g.dart';
import '../../core/widgets/r_button.dart';
import '../profile/wilayas.dart';

class WilayaFilterSheet extends StatefulWidget {
  const WilayaFilterSheet({
    super.key,
    this.initialWilaya,
  });

  final String? initialWilaya;

  @override
  State<WilayaFilterSheet> createState() => _WilayaFilterSheetState();
}

class _WilayaFilterSheetState extends State<WilayaFilterSheet> {
  final TextEditingController _searchController = TextEditingController();
  late String? _selectedWilaya;

  @override
  void initState() {
    super.initState();
    _selectedWilaya = widget.initialWilaya;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Wilaya> get _filteredWilayas {
    final q = _searchController.text.trim();
    if (q.isEmpty) return wilayas;
    return wilayas.where((w) {
      final numStr = w.number.toString().padLeft(2, '0');
      return w.name.contains(q) || numStr.contains(q) || w.label.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final filtered = _filteredWilayas;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(RRadius.x2xl)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
          children: [
            // Handle bar
            const SizedBox(height: RSpace.s3),
            Container(
              width: RSpace.s10,
              height: RSpace.s1,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(RRadius.full),
              ),
            ),
            const SizedBox(height: RSpace.s3),

            // Header: Title + Close
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'اختر الولاية (58 ولاية)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RType.heading3.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('wilaya-filter-close-btn'),
                    tooltip: 'إغلاق',
                    icon: const Icon(Icons.close_rounded),
                    color: c.textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RSpace.s2),

            // Search box
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s6),
              child: Container(
                height: RSpace.s11,
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
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
                        key: const ValueKey('wilaya-sheet-search-field'),
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: RType.body.copyWith(color: c.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن ولاية أو رقم…',
                          hintStyle: RType.body.copyWith(color: c.textSecondary),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: Icon(Icons.close_rounded, size: RSpace.s4, color: c.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: RSpace.s3),

            // List of wilayas
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: RSpace.s6),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, _) => Divider(color: c.border, height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAllSelected = _selectedWilaya == null;
                    return ListTile(
                      key: const ValueKey('wilaya-option-all'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'كل الولايات (عرض الكل)',
                        style: RType.body.copyWith(
                          color: isAllSelected ? c.primary : c.textPrimary,
                          fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isAllSelected
                          ? Icon(Icons.check_rounded, color: c.primary, size: RSpace.s5)
                          : null,
                      onTap: () {
                        setState(() => _selectedWilaya = null);
                      },
                    );
                  }

                  final w = filtered[index - 1];
                  final wNumberStr = w.number.toString();
                  final isSelected = _selectedWilaya == wNumberStr || _selectedWilaya == w.label;

                  return ListTile(
                    key: ValueKey('wilaya-option-${w.number}'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      w.label,
                      style: RType.body.copyWith(
                        color: isSelected ? c.primary : c.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_rounded, color: c.primary, size: RSpace.s5)
                        : null,
                    onTap: () {
                      setState(() => _selectedWilaya = wNumberStr);
                    },
                  );
                },
              ),
            ),

            // Confirm button
            Padding(
              padding: const EdgeInsetsDirectional.all(RSpace.s6),
              child: RButton(
                key: const ValueKey('wilaya-filter-confirm-btn'),
                label: 'تأكيد اختيار الولاية',
                onPressed: () {
                  Navigator.of(context).pop(_selectedWilaya);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
