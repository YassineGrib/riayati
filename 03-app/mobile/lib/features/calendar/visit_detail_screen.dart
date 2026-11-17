import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_card.dart';
import '../../core/widgets/state_views.dart';
import 'calendar_widgets.dart';
import 'visit.dart';
import 'visit_repository.dart';

class VisitDetailScreen extends ConsumerStatefulWidget {
  const VisitDetailScreen(this.id, {super.key});
  final int id;
  @override
  ConsumerState<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends ConsumerState<VisitDetailScreen> {
  late Future<Visit> _visit;
  bool _busy = false;
  Object? _actionError;
  @override
  void initState() {
    super.initState();
    _visit = ref.read(visitRepositoryProvider).get(widget.id);
  }

  void _load() => setState(() {
    _actionError = null;
    _visit = ref.read(visitRepositoryProvider).get(widget.id);
  });
  Future<void> _act(String action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    final repo = ref.read(visitRepositoryProvider);
    try {
      final visit = await switch (action) {
        'accept' => repo.accept(widget.id),
        'decline' => repo.decline(widget.id),
        _ => repo.confirm(widget.id),
      };
      if (mounted) {
        setState(() {
          _visit = Future.value(visit);
          _busy = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _actionError = error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'رجوع',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const BackButtonIcon(),
            ),
            Expanded(
              child: Text(
                'تفاصيل الزيارة',
                style: RType.heading3.copyWith(
                  fontFamily: RType.display.fontFamily,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: RSpace.s2),
        Expanded(
          child: FutureBuilder<Visit>(
            future: _visit,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LoadingView();
              }
              if (snapshot.hasError) {
                return CalendarFailure(error: snapshot.error!, onRetry: _load);
              }
              if (_actionError is ApiError &&
                  (_actionError as ApiError).code == 'not_linked') {
                return CalendarFailure(error: _actionError!, onRetry: _load);
              }
              final visit = snapshot.requireData;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: RSpace.s6,
                      ),
                      children: [
                        VisitCard(visit: visit),
                        if (visit.note?.isNotEmpty == true) ...[
                          const SizedBox(height: RSpace.s4),
                          RCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('ملاحظة', style: RType.label),
                                const SizedBox(height: RSpace.s2),
                                Text(visit.note!, style: RType.body),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: RSpace.s5),
                        Text('مراحل الزيارة', style: RType.heading4),
                        const SizedBox(height: RSpace.s3),
                        for (final entry in visit.timeline)
                          _step(
                            switch (entry.step) {
                              'proposed' => 'تم اقتراح الزيارة',
                              'accepted' => 'تم قبول الزيارة',
                              'declined' => 'تم رفض الزيارة',
                              'confirmed' => 'تم تأكيد الزيارة',
                              _ => 'تحديث الزيارة',
                            },
                            visitDate(
                              entry.at.toLocal(),
                              'EEEE d MMMM · HH:mm',
                            ),
                            done: true,
                            declined: entry.step == 'declined',
                            last:
                                entry == visit.timeline.last &&
                                (visit.status == VisitStatus.confirmed ||
                                    visit.status == VisitStatus.declined),
                          ),
                        if (visit.status == VisitStatus.proposed)
                          _step(
                            visit.needsMyResponse ? 'ردّك' : 'ردّ الطرف الآخر',
                            visit.needsMyResponse
                                ? 'بانتظار قبولك أو رفضك'
                                : 'بانتظار قبول الطرف الآخر أو رفضه',
                            current: true,
                          ),
                        if (visit.status != VisitStatus.confirmed &&
                            visit.status != VisitStatus.declined)
                          _step(
                            'تأكيد الزيارة',
                            visit.canConfirm
                                ? 'بانتظار تأكيدك'
                                : visit.status == VisitStatus.accepted
                                ? 'بانتظار تأكيد الطرف الآخر'
                                : 'بعد القبول',
                            current: visit.canConfirm,
                            last: true,
                          ),
                      ],
                    ),
                  ),
                  if (_actionError != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: RSpace.s3,
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _actionError is ApiError
                              ? (_actionError as ApiError).message
                              : ApiError.offlineMessage,
                          style: RType.caption.copyWith(
                            color: context.c.feedbackErrorText,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: RSpace.s6,
                    ),
                    child: VisitActions(
                      visit: visit,
                      onAction: _act,
                      loading: _busy,
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
  Widget _step(
    String title,
    String subtitle, {
    bool done = false,
    bool current = false,
    bool declined = false,
    bool last = false,
  }) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: RSpace.s8,
          child: Column(
            children: [
              Container(
                width: RSpace.s8,
                height: RSpace.s8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? declined
                            ? context.c.feedbackErrorBg
                            : context.c.primary
                      : context.c.surfaceSunken,
                  border: Border.all(
                    color: current
                        ? context.c.feedbackWarningIcon
                        : context.c.border,
                    width: RBorderWidth.medium,
                  ),
                ),
                child: Icon(
                  declined
                      ? Icons.close
                      : done
                      ? Icons.check
                      : current
                      ? Icons.schedule
                      : Icons.event_available,
                  size: RSpace.s5,
                  color: declined
                      ? context.c.feedbackErrorIcon
                      : current
                      ? context.c.feedbackWarningIcon
                      : done
                      ? context.c.onPrimary
                      : context.c.textTertiary,
                ),
              ),
              if (!last)
                Expanded(
                  child: Center(
                    child: Container(
                      width: RBorderWidth.medium,
                      color: context.c.border,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: RSpace.s4),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(bottom: RSpace.s5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: RType.heading4),
                Text(
                  subtitle,
                  style: RType.caption.copyWith(color: context.c.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
