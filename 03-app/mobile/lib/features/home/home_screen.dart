import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/watermark.dart';
import '../auth/auth_controller.dart';
import '../calendar/visit.dart';
import '../calendar/visit_repository.dart';
import '../reports/report.dart';
import '../reports/report_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late Future<List<Visit>> _upcomingFuture;
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _fetchVisits();
    _fetchReports();
  }

  void _fetchVisits() {
    setState(() {
      _upcomingFuture = ref.read(visitRepositoryProvider).upcoming();
    });
  }

  void _fetchReports() {
    setState(() {
      _reportsFuture = ref.read(reportRepositoryProvider).list();
    });
  }

  String _formatToday() {
    try {
      return DateFormat('EEEE d MMMM', 'ar').format(DateTime.now());
    } catch (_) {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatVisitDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE d MMMM', 'ar').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatIncidentDate(DateTime dt) {
    try {
      return DateFormat('d MMMM yyyy · HH:mm', 'ar').format(dt);
    } catch (_) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _respondVisit(int id, bool accept) async {
    try {
      final repo = ref.read(visitRepositoryProvider);
      if (accept) {
        await repo.accept(id);
      } else {
        await repo.decline(id);
      }
      _fetchVisits();
    } catch (e) {
      if (mounted) {
        final message = e is ApiError ? e.message : 'تعذر تحديث الزيارة';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user?.name;
    final greeting = userName != null && userName.isNotEmpty
        ? 'مرحبًا، $userName'
        : 'مرحبًا بك';
    final todayText = _formatToday();

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchVisits();
          _fetchReports();
          try {
            await Future.wait([_upcomingFuture, _reportsFuture]);
          } catch (_) {}
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(
            top: RSpace.s1_5,
            bottom: RSpace.s20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top bar: greeting and notifications
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: RType.heading2.copyWith(
                            fontFamily: RType.display.fontFamily,
                            color: c.textPrimary,
                          ),
                        ),
                        const SizedBox(height: RSpace.s0_5),
                        Text(
                          todayText,
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<Visit>>(
                    future: _upcomingFuture,
                    builder: (context, snapshot) {
                      final visits = snapshot.data ?? const [];
                      final hasActionable =
                          visits.any((v) => v.needsMyResponse || v.canConfirm);

                      return Tooltip(
                        message: 'الإشعارات',
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            key: const ValueKey('home-bell-button'),
                            customBorder: const CircleBorder(),
                            onTap: () => context.push('/notifications'),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minWidth: RSpace.s12,
                                minHeight: RSpace.s12,
                              ),
                              child: Center(
                                child: Container(
                                  width: RSpace.s11,
                                  height: RSpace.s11,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.surface,
                                    border: Border.all(
                                      color: c.border,
                                      width: RBorderWidth.thin,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none_rounded,
                                        size: RSpace.s6,
                                        color: c.textPrimary,
                                      ),
                                      if (hasActionable)
                                        PositionedDirectional(
                                          key: const ValueKey(
                                              'bell-actionable-dot'),
                                          top: RSpace.s2,
                                          start: RSpace.s2_5,
                                          child: Container(
                                            width: RSpace.s2,
                                            height: RSpace.s2,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: c.sos,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: RSpace.s3),

              // 2. SOS card (MUST BE FIRST)
              Material(
                key: const ValueKey('home-sos-card'),
                color: c.sos,
                borderRadius: BorderRadius.circular(RRadius.x2xl),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    context.push('/reports/new');
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Watermark(
                          color: c.sosTextOnBg,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsetsDirectional.all(RSpace.s4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Badge
                            Container(
                              width: RSpace.s12,
                              height: RSpace.s12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: c.sosTextOnBg,
                              ),
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: RSpace.s6,
                                color: c.sos,
                              ),
                            ),
                            const SizedBox(width: RSpace.s3),
                            // Titles
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'الإبلاغ عن حادثة',
                                    style: RType.heading3.copyWith(
                                      color: c.sosTextOnBg,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: RSpace.s0_5),
                                  Text(
                                    'وثّق ما حدث بالنص والصور والفيديو.',
                                    style: RType.caption.copyWith(
                                      color: c.sosTextOnBg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: RSpace.s2),
                            Icon(
                              Icons.arrow_forward,
                              size: RSpace.s6,
                              color: c.sosTextOnBg,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: RSpace.s2_5),

              // Two shortcut cards under the SOS card
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutCard(
                      key: const ValueKey('home-shortcut-library'),
                      icon: Icons.menu_book_outlined,
                      label: 'المحتوى التعليمي',
                      onTap: () => context.push('/library'),
                    ),
                  ),
                  const SizedBox(width: RSpace.s2_5),
                  Expanded(
                    child: _buildShortcutCard(
                      key: const ValueKey('home-shortcut-centers'),
                      icon: Icons.account_balance_outlined,
                      label: 'مراكز وهيئات',
                      onTap: () => context.push('/centers'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: RSpace.s3),

              // 3. Upcoming Visit Section
              _buildVisitSection(context),
              const SizedBox(height: RSpace.s3),

              // 4. Last Reports Section
              _buildReportsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutCard({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final c = context.c;
    return Material(
      key: key,
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RRadius.x2xl),
        side: BorderSide(color: c.border, width: RBorderWidth.thin),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40.0),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: RSpace.s3,
              vertical: RSpace.s1_5,
            ),
            child: Row(
              children: [
                Icon(icon, size: RSpace.s5, color: c.primary),
                const SizedBox(width: RSpace.s2),
                Expanded(
                  child: Text(
                    label,
                    style: RType.label.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  size: RSpace.s4,
                  color: c.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitSection(BuildContext context) {
    final c = context.c;

    return Container(
      key: const ValueKey('home-visit-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: RSpace.s5,
                color: c.textPrimary,
              ),
              const SizedBox(width: RSpace.s2),
              Expanded(
                child: Text(
                  'الزيارات القادمة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RType.heading3.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RSpace.s3),
          FutureBuilder<List<Visit>>(
            future: _upcomingFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return RCard(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s6,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: c.primary,
                        strokeWidth: RBorderWidth.medium,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                final error = snapshot.error;
                final isNotLinked = error is ApiError &&
                    (error.code == 'not_linked' || error.status == 403);

                if (isNotLinked) {
                  return RCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.link_off_rounded,
                              size: RSpace.s6,
                              color: c.textSecondary,
                            ),
                            const SizedBox(width: RSpace.s2),
                            Expanded(
                              child: Text(
                                'لم يتم ربط الحساب بعد',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: RType.label.copyWith(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: RSpace.s1_5),
                        Text(
                          'اربط حسابك مع الطرف الآخر لتفعيل تقويم الزيارات المشترك.',
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: RSpace.s3),
                        RButton(
                          label: 'ربط الحساب',
                          kind: RButtonKind.secondary,
                          onPressed: () => context.push('/link'),
                        ),
                      ],
                    ),
                  );
                }

                final errorMessage = error is ApiError
                    ? error.message
                    : 'تعذر تحميل بيانات الزيارات.';

                return RCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: RSpace.s6,
                            color: c.feedbackErrorIcon,
                          ),
                          const SizedBox(width: RSpace.s2),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: RType.label.copyWith(
                                color: c.feedbackErrorText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RSpace.s3),
                      RButton(
                        key: const ValueKey('retry-visits-button'),
                        label: 'إعادة المحاولة',
                        kind: RButtonKind.secondary,
                        onPressed: _fetchVisits,
                      ),
                    ],
                  ),
                );
              }

              final visits = snapshot.data ?? const [];
              if (visits.isEmpty) {
                return RCard(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s4,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_available_outlined,
                            size: RSpace.s8,
                            color: c.textSecondary,
                          ),
                          const SizedBox(height: RSpace.s2),
                          Text(
                            'لا توجد زيارات قادمة',
                            style: RType.label.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: RSpace.s1),
                          Text(
                            'لم تُسجل أي زيارة قادمة في التقويم بعد.',
                            style: RType.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final visit = visits.first;
              final formattedDate = _formatVisitDate(visit.date);
              final partnerNote = visit.proposedByMe
                  ? 'اقترحتَها أنت'
                  : 'اقترحها الطرف الآخر';
              final timeAndParty = '${visit.from} – ${visit.to} · $partnerNote';

              final tone = visit.needsMyResponse
                  ? StatusTone.warning
                  : visit.status == VisitStatus.accepted ||
                          visit.status == VisitStatus.confirmed
                      ? StatusTone.success
                      : visit.status == VisitStatus.declined
                          ? StatusTone.error
                          : StatusTone.neutral;

              final statusLabel =
                  visit.needsMyResponse ? 'بانتظار ردّك' : visit.status.label;

              return RCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'الزيارة القادمة',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RType.label.copyWith(
                              color: c.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: RSpace.s2),
                        StatusChip(label: statusLabel, tone: tone),
                      ],
                    ),
                    const SizedBox(height: RSpace.s2),
                    Text(
                      formattedDate,
                      style: RType.heading3.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: RSpace.s1),
                    Text(
                      timeAndParty,
                      style: RType.caption.copyWith(color: c.textSecondary),
                    ),
                    if (visit.note != null && visit.note!.isNotEmpty) ...[
                      const SizedBox(height: RSpace.s2),
                      Text(
                        visit.note!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: RType.caption.copyWith(color: c.textSecondary),
                      ),
                    ],
                    if (visit.needsMyResponse) ...[
                      const SizedBox(height: RSpace.s4),
                      Row(
                        children: [
                          Expanded(
                            child: RButton(
                              label: 'قبول',
                              kind: RButtonKind.primary,
                              onPressed: () => _respondVisit(visit.id, true),
                            ),
                          ),
                          const SizedBox(width: RSpace.s2),
                          Expanded(
                            child: RButton(
                              label: 'رفض',
                              kind: RButtonKind.secondary,
                              onPressed: () => _respondVisit(visit.id, false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsSection(BuildContext context) {
    final c = context.c;

    return Container(
      key: const ValueKey('home-reports-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: RSpace.s5,
                      color: c.textPrimary,
                    ),
                    const SizedBox(width: RSpace.s2),
                    Expanded(
                      child: Text(
                        'آخر البلاغات',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RType.heading3.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: RSpace.s2),
              InkWell(
                onTap: () => context.push('/reports/new'),
                borderRadius: BorderRadius.circular(RRadius.lg),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: RSpace.s2,
                    vertical: RSpace.s1,
                  ),
                  child: Text(
                    'بلاغ جديد',
                    style: RType.label.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RSpace.s2),
          FutureBuilder<List<Report>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return RCard(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s6,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: c.primary,
                        strokeWidth: RBorderWidth.medium,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                final errorMessage = snapshot.error is ApiError
                    ? (snapshot.error as ApiError).message
                    : 'تعذر تحميل البلاغات.';

                return RCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: RSpace.s6,
                            color: c.feedbackErrorIcon,
                          ),
                          const SizedBox(width: RSpace.s2),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: RType.label.copyWith(
                                color: c.feedbackErrorText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RSpace.s3),
                      RButton(
                        key: const ValueKey('retry-reports-button'),
                        label: 'إعادة المحاولة',
                        kind: RButtonKind.secondary,
                        onPressed: _fetchReports,
                      ),
                    ],
                  ),
                );
              }

              final reports = snapshot.data ?? const [];
              if (reports.isEmpty) {
                return RCard(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      vertical: RSpace.s4,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: RSpace.s8,
                            color: c.textSecondary,
                          ),
                          const SizedBox(height: RSpace.s2),
                          Text(
                            'لا توجد بلاغات مسجلة',
                            style: RType.label.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: RSpace.s1),
                          Text(
                            'لم تقم بتسجيل أي بلاغ عن حادثة حتى الآن.',
                            style: RType.caption.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final displayReports = reports.take(3).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayReports.length,
                separatorBuilder: (_, _) => const SizedBox(height: RSpace.s3),
                itemBuilder: (context, index) {
                  final report = displayReports[index];
                  final formattedDate = _formatIncidentDate(report.incidentAt);
                  final tone = report.status == ReportStatus.reviewed
                      ? StatusTone.success
                      : StatusTone.info;

                  return RCard(
                    onTap: () => context.push('/reports/${report.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsetsDirectional.symmetric(
                                  horizontal: RSpace.s3,
                                  vertical: RSpace.s0_5,
                                ),
                                decoration: BoxDecoration(
                                  color: c.surfaceSunken,
                                  borderRadius:
                                      BorderRadius.circular(RRadius.full),
                                ),
                                child: Text(
                                  report.reference,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: RType.label.copyWith(
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: RSpace.s2),
                            StatusChip(
                              label: report.status.label,
                              tone: tone,
                            ),
                          ],
                        ),
                        const SizedBox(height: RSpace.s2),
                        Text(
                          formattedDate,
                          style: RType.caption.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: RSpace.s1),
                        Text(
                          report.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: RType.body.copyWith(color: c.textPrimary),
                        ),
                        if (report.attachmentsCount > 0) ...[
                          const SizedBox(height: RSpace.s2),
                          Row(
                            children: [
                              Icon(
                                Icons.attach_file_rounded,
                                size: RSpace.s4,
                                color: c.textSecondary,
                              ),
                              const SizedBox(width: RSpace.s1),
                              Text(
                                '${report.attachmentsCount} مرفقات',
                                style: RType.caption.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.chevron_left_rounded,
                                size: RSpace.s5,
                                color: c.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
