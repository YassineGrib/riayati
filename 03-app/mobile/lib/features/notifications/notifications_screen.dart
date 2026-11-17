import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import '../calendar/visit.dart';
import '../calendar/visit_repository.dart';
import '../reports/report.dart';
import '../reports/report_repository.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.date,
    required this.icon,
    required this.route,
    required this.sortDate,
  });

  final String id;
  final String title;
  final String date;
  final IconData icon;
  final String route;
  final DateTime sortDate;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late Future<List<NotificationItem>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    setState(() {
      _notificationsFuture = _loadNotifications();
    });
  }

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('d MMMM yyyy', 'ar').format(dt);
    } catch (_) {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  String _formatVisitDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE d MMMM yyyy', 'ar').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  DateTime _parseVisitDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<List<NotificationItem>> _loadNotifications() async {
    final items = <NotificationItem>[];

    List<Visit> visits = const [];
    try {
      visits = await ref.read(visitRepositoryProvider).upcoming();
    } catch (e) {
      final isNotLinked =
          e is ApiError && (e.code == 'not_linked' || e.status == 403);
      if (!isNotLinked) {
        rethrow;
      }
    }

    for (final visit in visits) {
      if (visit.needsMyResponse) {
        items.add(
          NotificationItem(
            id: 'visit_response_${visit.id}',
            title: 'طلب زيارة جديد بانتظار ردك',
            date: _formatVisitDate(visit.date),
            icon: Icons.schedule_rounded,
            route: '/calendar/${visit.id}',
            sortDate: _parseVisitDate(visit.date),
          ),
        );
      } else if (visit.status == VisitStatus.accepted && visit.canConfirm) {
        items.add(
          NotificationItem(
            id: 'visit_confirm_${visit.id}',
            title: 'وافق الطرف الآخر، أكّد الزيارة',
            date: _formatVisitDate(visit.date),
            icon: Icons.check_circle_outline_rounded,
            route: '/calendar/${visit.id}',
            sortDate: _parseVisitDate(visit.date),
          ),
        );
      } else if (visit.status == VisitStatus.confirmed) {
        items.add(
          NotificationItem(
            id: 'visit_confirmed_${visit.id}',
            title: 'تم تأكيد الزيارة',
            date: _formatVisitDate(visit.date),
            icon: Icons.event_available_outlined,
            route: '/calendar/${visit.id}',
            sortDate: _parseVisitDate(visit.date),
          ),
        );
      } else if (visit.status == VisitStatus.declined) {
        items.add(
          NotificationItem(
            id: 'visit_declined_${visit.id}',
            title: 'رُفضت زيارتك',
            date: _formatVisitDate(visit.date),
            icon: Icons.cancel_outlined,
            route: '/calendar/${visit.id}',
            sortDate: _parseVisitDate(visit.date),
          ),
        );
      }
    }

    try {
      final reports = await ref.read(reportRepositoryProvider).list();
      for (final report in reports) {
        if (report.status == ReportStatus.reviewed) {
          final sortDt = report.createdAt ?? report.incidentAt;
          items.add(
            NotificationItem(
              id: 'report_reviewed_${report.id}',
              title: 'تمت مراجعة بلاغك ${report.reference}',
              date: _formatDate(sortDt),
              icon: Icons.assignment_turned_in_outlined,
              route: '/reports/${report.id}',
              sortDate: sortDt,
            ),
          );
        }
      }
    } catch (_) {
      // If reports fetch throws, allow it to rethrow if visits was also empty
      if (visits.isEmpty) rethrow;
    }

    items.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return AppScaffold(
      title: 'الإشعارات',
      leading: SizedBox(
        width: RSpace.s12,
        height: RSpace.s12,
        child: IconButton(
          tooltip: 'رجوع',
          icon: const Icon(Icons.arrow_back),
          color: c.textPrimary,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: FutureBuilder<List<NotificationItem>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final isNotLinked =
                error is ApiError && (error.code == 'not_linked' || error.status == 403);
            if (isNotLinked) {
              return const EmptyView(
                title: 'لا توجد إشعارات',
                body: 'ستظهر هنا التنبيهات المتعلقة بالزيارات والبلاغات.',
              );
            }
            final message = error is ApiError
                ? error.message
                : 'تعذر تحميل الإشعارات. تحقق من الاتصال وحاول مجددًا.';
            return ErrorView(
              message: message,
              onRetry: _fetch,
            );
          }

          final notifications = snapshot.data ?? const [];
          if (notifications.isEmpty) {
            return const EmptyView(
              title: 'لا توجد إشعارات',
              body: 'ستظهر هنا التنبيهات المتعلقة بالزيارات والبلاغات.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _fetch();
              try {
                await _notificationsFuture;
              } catch (_) {}
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsetsDirectional.only(
                top: RSpace.s2,
                bottom: RSpace.s12,
              ),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: RSpace.s3),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return RCard(
                  onTap: () => context.push(item.route),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: RSpace.s6,
                        color: c.textPrimary,
                      ),
                      const SizedBox(width: RSpace.s3_5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: RType.label.copyWith(
                                color: c.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: RSpace.s1),
                            Text(
                              item.date,
                              style: RType.caption.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: RSpace.s2),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: RSpace.s5,
                        color: c.textTertiary,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
