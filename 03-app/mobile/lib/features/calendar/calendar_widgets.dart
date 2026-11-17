import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import 'visit.dart';

String visitDate(DateTime date, [String pattern = 'EEEE d MMMM']) =>
    (DateFormat(pattern, 'ar')..useNativeDigits = false).format(date);
String visitDayKey(DateTime date) =>
    DateFormat('yyyy-MM-dd', 'en').format(date);
StatusTone visitTone(Visit visit) => switch (visit.status) {
  VisitStatus.proposed => StatusTone.warning,
  VisitStatus.accepted => StatusTone.info,
  VisitStatus.declined => StatusTone.error,
  VisitStatus.confirmed => StatusTone.success,
};

class CalendarFailure extends StatelessWidget {
  const CalendarFailure({
    super.key,
    required this.error,
    required this.onRetry,
  });
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    if (error is ApiError && (error as ApiError).code == 'not_linked') {
      return EmptyView(
        title: 'اربط حسابك بالطرف الآخر',
        body: 'بعد الربط يمكنكما اقتراح الزيارات ومتابعتها في تقويم مشترك.',
        action: RButton(
          label: 'ربط الطرف الآخر',
          onPressed: () => context.go('/link'),
        ),
      );
    }
    return ErrorView(
      message: error is ApiError
          ? (error as ApiError).message
          : ApiError.offlineMessage,
      onRetry: onRetry,
    );
  }
}

class VisitCard extends StatelessWidget {
  const VisitCard({super.key, required this.visit, this.onTap, this.actions});
  final Visit visit;
  final VoidCallback? onTap;
  final Widget? actions;
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
            Text(visitDate(DateTime.parse(visit.date)), style: RType.heading4),
            StatusChip(
              label: visit.needsMyResponse
                  ? 'بانتظار ردّك'
                  : visit.statusLabel ?? visit.status.label,
              tone: visitTone(visit),
            ),
          ],
        ),
        const SizedBox(height: RSpace.s1),
        Text(
          '${visit.from} – ${visit.to} · ${visit.proposedByMe ? 'اقترحتها أنت' : 'اقترحها الطرف الآخر'}',
          style: RType.caption.copyWith(color: context.c.textSecondary),
        ),
        if (actions != null) ...[const SizedBox(height: RSpace.s3), actions!],
      ],
    ),
  );
}

class VisitActions extends StatelessWidget {
  const VisitActions({
    super.key,
    required this.visit,
    required this.onAction,
    this.loading = false,
  });
  final Visit visit;
  final ValueChanged<String> onAction;
  final bool loading;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (visit.needsMyResponse)
        Row(
          children: [
            Expanded(
              child: RButton(
                label: 'قبول',
                loading: loading,
                onPressed: () => onAction('accept'),
              ),
            ),
            const SizedBox(width: RSpace.s3),
            Expanded(
              child: RButton(
                label: 'رفض',
                kind: RButtonKind.secondary,
                loading: loading,
                onPressed: () => onAction('decline'),
              ),
            ),
          ],
        ),
      if (visit.canConfirm) ...[
        if (visit.needsMyResponse) const SizedBox(height: RSpace.s3),
        RButton(
          label: 'تأكيد الزيارة',
          loading: loading,
          onPressed: () => onAction('confirm'),
        ),
      ],
    ],
  );
}
