import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import 'center_repository.dart';
import 'support_center.dart';

class CenterDetailScreen extends ConsumerStatefulWidget {
  const CenterDetailScreen({
    super.key,
    required this.id,
  });

  final int id;

  @override
  ConsumerState<CenterDetailScreen> createState() => _CenterDetailScreenState();
}

class _CenterDetailScreenState extends ConsumerState<CenterDetailScreen> {
  late Future<SupportCenter> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CenterDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _load();
    }
  }

  void _load() {
    setState(() {
      _future = ref.read(centerRepositoryProvider).get(widget.id);
    });
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

  Future<void> _copyPhone(String phone) async {
    try {
      await Clipboard.setData(ClipboardData(text: phone));
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ رقم الهاتف')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppScaffold(
      body: Column(
        children: [
          // 1. Top bar: Back button + Title
          Row(
            children: [
              IconButton(
                key: const ValueKey('center-detail-back-button'),
                tooltip: 'رجوع',
                onPressed: () => context.canPop() ? context.pop() : context.go('/centers'),
                icon: const BackButtonIcon(),
                color: c.textPrimary,
              ),
              Expanded(
                child: Text(
                  'تفاصيل المركز',
                  style: RType.heading3.copyWith(
                    fontFamily: RType.display.fontFamily,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RSpace.s2),

          // 2. Detail Body
          Expanded(
            child: FutureBuilder<SupportCenter>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  final err = snapshot.error;
                  final msg = err is ApiError ? err.message : 'تعذر تحميل بيانات المركز.';
                  return ErrorView(
                    message: msg,
                    onRetry: _load,
                  );
                }

                final item = snapshot.data!;
                final phone = item.phone ?? item.hotline;

                return SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.only(bottom: RSpace.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kind badge & Demo badge
                      Wrap(
                        spacing: RSpace.s2,
                        runSpacing: RSpace.s2,
                        children: [
                          StatusChip(
                            label: item.kindLabel,
                            tone: _toneForKind(item.kind),
                          ),
                          Container(
                            height: RSpace.s7,
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: RSpace.s3,
                              vertical: RSpace.s0_5,
                            ),
                            decoration: BoxDecoration(
                              color: c.surfaceSunken,
                              borderRadius: BorderRadius.circular(RRadius.full),
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

                      // Name
                      Text(
                        item.name,
                        style: RType.heading1.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: RSpace.s4),

                      // Info Card
                      Container(
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(RRadius.x2xl),
                          border: Border.all(color: c.border, width: RBorderWidth.thin),
                        ),
                        padding: const EdgeInsetsDirectional.all(RSpace.s4),
                        child: Column(
                          children: [
                            _buildInfoRow('الولاية', item.wilayaLabel ?? 'غير محدد'),
                            Divider(color: c.border, height: RSpace.s5),
                            _buildInfoRow('العنوان الكامل', item.address ?? 'غير محدد'),
                            Divider(color: c.border, height: RSpace.s5),
                            _buildInfoRow(
                              'أوقات العمل',
                              item.hours ?? 'الأحد إلى الخميس: 08:30 – 16:30',
                            ),
                            Divider(color: c.border, height: RSpace.s5),
                            _buildInfoRow(
                              'الهاتف الرئيسي',
                              item.phone != null ? '${item.phone!} (رقم تجريبي)' : 'غير متوفر',
                            ),
                            Divider(color: c.border, height: RSpace.s5),
                            _buildInfoRow(
                              'الرقم الأخضر / المساعدة',
                              item.hotline ?? 'غير متوفر',
                            ),
                            Divider(color: c.border, height: RSpace.s5),
                            _buildInfoRow(
                              'الاختصاص والمهام',
                              item.notes ?? 'النظر في دعاوى الحضانة والزيارة والنفقة. يجب إحضار الوثائق الرسمية والأحكام السابقة.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: RSpace.s4),

                      // Note banner
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: c.surfaceSunken,
                          borderRadius: BorderRadius.circular(RRadius.xl),
                          border: Border.all(color: c.border, width: RBorderWidth.thin),
                        ),
                        padding: const EdgeInsetsDirectional.all(RSpace.s3_5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, size: RSpace.s5, color: c.textSecondary),
                            const SizedBox(width: RSpace.s2_5),
                            Expanded(
                              child: Text(
                                'هذه المعلومات مخصصة للإرشاد الأولي ولا تعوّض التوجيه الصادر عن أمانة الضبط.',
                                style: RType.caption.copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: RSpace.s5),

                      // Actions
                      if (phone != null && phone.isNotEmpty) ...[
                        RButton(
                          key: const ValueKey('center-detail-call-btn'),
                          label: 'اتصال بالمركز ($phone)',
                          icon: Icons.phone_outlined,
                          onPressed: () => _callPhone(phone),
                        ),
                        const SizedBox(height: RSpace.s3),
                        RButton(
                          key: const ValueKey('center-detail-copy-btn'),
                          label: 'نسخ رقم الهاتف',
                          icon: Icons.copy_rounded,
                          kind: RButtonKind.secondary,
                          onPressed: () => _copyPhone(phone),
                        ),
                      ],
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

  Widget _buildInfoRow(String label, String value) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: RType.caption.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: RSpace.s2),
        Expanded(
          child: Text(
            value,
            style: RType.body.copyWith(
              color: c.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
