import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import 'report.dart';
import 'report_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  ReportStatus? _status;
  late Future<List<Report>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = ref.read(reportRepositoryProvider).list();
  }

  void _load() => setState(() {
    _reports = ref.read(reportRepositoryProvider).list(status: _status);
  });

  Future<void> _newReport() async {
    await context.push('/reports/new');
    if (mounted) _load();
  }

  IconData _statusFilterIcon(ReportStatus? status) {
    return switch (status) {
      null => Icons.list_alt_rounded,
      ReportStatus.underReview => Icons.hourglass_empty_rounded,
      ReportStatus.reviewed => Icons.check_rounded,
    };
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'بلاغاتي',
    body: Column(
      children: [
        const SizedBox(height: RSpace.s4),
        Semantics(
          label: 'تصفية البلاغات',
          child: Container(
            decoration: BoxDecoration(
              color: context.c.surfaceSunken,
              borderRadius: BorderRadius.circular(RRadius.xl),
            ),
            child: Row(
              children: [
                for (final status in <ReportStatus?>[
                  null,
                  ...ReportStatus.values,
                ])
                  Expanded(
                    child: Semantics(
                      selected: status == _status,
                      child: TextButton(
                        onPressed: () {
                          if (_status == status) return;
                          _status = status;
                          _load();
                        },
                        style: TextButton.styleFrom(
                          minimumSize: const Size(RSpace.s12, RSpace.s12),
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: RSpace.s1,
                            vertical: RSpace.s2,
                          ),
                          foregroundColor: status == _status
                              ? context.c.textPrimary
                              : context.c.textSecondary,
                          backgroundColor: status == _status
                              ? context.c.surface
                              : null,
                          textStyle: RType.label.copyWith(
                            fontWeight: status == _status
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(RRadius.xl),
                            side: status == _status
                                ? BorderSide(
                                    color: context.c.borderStrong,
                                    width: RBorderWidth.thin,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusFilterIcon(status),
                              size: RSpace.s4,
                            ),
                            const SizedBox(width: RSpace.s1),
                            Flexible(
                              child: Text(
                                status?.label ?? 'الكل',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RSpace.s4),
        Expanded(
          child: FutureBuilder<List<Report>>(
            future: _reports,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return ErrorView(
                  message: snapshot.error is ApiError
                      ? (snapshot.error! as ApiError).message
                      : 'تعذر تحميل البلاغات. تحقق من اتصالك وحاول مجددًا.',
                  onRetry: _load,
                );
              }
              final reports = snapshot.requireData;
              if (reports.isEmpty) {
                return EmptyView(
                  title: _status == null
                      ? 'لا توجد بلاغات بعد'
                      : 'لا توجد بلاغات بهذه الحالة',
                  body: 'عند توثيق حادثة ستظهر هنا بلاغاتك مع حالة كل بلاغ.',
                  action: RButton(
                    label: 'بلاغ جديد',
                    icon: Icons.add,
                    onPressed: _newReport,
                  ),
                );
              }
              return Stack(
                children: [
                  ListView.separated(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: RSpace.s24,
                    ),
                    itemCount: reports.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: RSpace.s3),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _ReportCard(
                        report: report,
                        onTap: () async {
                          await context.push('/reports/${report.id}');
                          if (mounted) _load();
                        },
                      );
                    },
                  ),
                  PositionedDirectional(
                    end: RSpace.s0,
                    bottom: RSpace.s4,
                    child: IntrinsicWidth(
                      child: RButton(
                        label: 'بلاغ جديد',
                        icon: Icons.add,
                        onPressed: _newReport,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});
  final Report report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => RCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: RSpace.s2,
          runSpacing: RSpace.s2,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: StatusChip(
                label: report.reference,
                tone: StatusTone.neutral,
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
        const SizedBox(height: RSpace.s2),
        Text(
          (DateFormat(
            'd MMMM yyyy · HH:mm',
            'ar',
          )..useNativeDigits = false).format(report.incidentAt.toLocal()),
          style: RType.caption.copyWith(color: context.c.textSecondary),
        ),
        const SizedBox(height: RSpace.s2),
        Text(
          report.excerpt ?? report.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: RType.caption.copyWith(color: context.c.textPrimary),
        ),
        const SizedBox(height: RSpace.s3),
        Row(
          children: [
            Icon(
              Icons.attach_file,
              size: RSpace.s5,
              color: context.c.textSecondary,
            ),
            const SizedBox(width: RSpace.s1_5),
            Expanded(
              child: Text(switch (report.attachmentsCount) {
                0 => 'بدون مرفقات',
                1 => 'ملف واحد',
                2 => 'ملفان',
                final count => '$count ملفات',
              }, style: RType.caption.copyWith(color: context.c.textSecondary)),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: RSpace.s4,
              color: context.c.textSecondary,
            ),
          ],
        ),
      ],
    ),
  );
}
