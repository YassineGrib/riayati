import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/api/api_error.dart';
import '../../core/theme/tokens.g.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/r_button.dart';
import '../../core/widgets/state_views.dart';
import 'calendar_widgets.dart';
import 'propose_visit_sheet.dart';
import 'visit.dart';
import 'visit_repository.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key, this.initialMonth});
  final DateTime? initialMonth;
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _month;
  DateTime? _selected;
  late Future<List<List<Visit>>> _data;
  int? _actingId;
  Object? _actionError;
  @override
  void initState() {
    super.initState();
    final now = widget.initialMonth ?? DateTime.now();
    _month = DateTime(now.year, now.month);
    _data = _fetch();
  }

  Future<List<List<Visit>>> _fetch() {
    final repo = ref.read(visitRepositoryProvider);
    return Future.wait([
      repo.month(DateFormat('yyyy-MM', 'en').format(_month)),
      repo.upcoming(),
    ]);
  }

  void _load() => setState(() {
    _actionError = null;
    _data = _fetch();
  });
  Future<void> _act(Visit visit, String action) async {
    if (_actingId != null) return;
    setState(() {
      _actingId = visit.id;
      _actionError = null;
    });
    final repo = ref.read(visitRepositoryProvider);
    try {
      await switch (action) {
        'accept' => repo.accept(visit.id),
        'decline' => repo.decline(visit.id),
        _ => repo.confirm(visit.id),
      };
      if (mounted) _load();
    } catch (error) {
      if (mounted) setState(() => _actionError = error);
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  void _move(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    _selected = null;
    _data = _fetch();
  });
  Future<void> _propose() async {
    final created = await showProposeVisitSheet(
      context,
      initialDate: _selected,
    );
    if (mounted && created != null) _load();
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: 'التقويم',
    body: FutureBuilder<List<List<Visit>>>(
      future: _data,
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
        final monthVisits = snapshot.requireData.first;
        final visits = _selected == null
            ? snapshot.requireData.last
            : monthVisits
                  .where((v) => v.date == visitDayKey(_selected!))
                  .toList();
        return Stack(
          children: [
            ListView(
              padding: const EdgeInsetsDirectional.only(bottom: RSpace.s24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'الشهر السابق',
                      onPressed: () => _move(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        visitDate(_month, 'MMMM yyyy'),
                        textAlign: TextAlign.center,
                        style: RType.heading3.copyWith(
                          fontFamily: RType.display.fontFamily,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'الشهر التالي',
                      onPressed: () => _move(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                _grid(monthVisits),
                const SizedBox(height: RSpace.s5),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _selected == null
                          ? 'الزيارات القادمة'
                          : 'زيارات ${visitDate(_selected!)}',
                      style: RType.heading4,
                    ),
                    if (_selected != null)
                      TextButton(
                        onPressed: () => setState(() => _selected = null),
                        child: const Text('الزيارات القادمة'),
                      ),
                  ],
                ),
                const SizedBox(height: RSpace.s3),
                if (_actionError != null)
                  Semantics(
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
                if (visits.isEmpty)
                  EmptyView(
                    title: _selected == null
                        ? 'لا توجد زيارات قادمة'
                        : 'لا توجد زيارات في هذا اليوم',
                    body: 'اقترح موعدًا جديدًا للزيارة من التقويم.',
                  ),
                for (final visit in visits)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: RSpace.s3,
                    ),
                    child: VisitCard(
                      visit: visit,
                      onTap: () async {
                        await context.push('/calendar/${visit.id}');
                        if (mounted) _load();
                      },
                      actions: visit.needsMyResponse || visit.canConfirm
                          ? VisitActions(
                              visit: visit,
                              loading: _actingId != null,
                              onAction: (action) => _act(visit, action),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            PositionedDirectional(
              end: RSpace.s0,
              bottom: RSpace.s4,
              child: IntrinsicWidth(
                child: RButton(
                  label: 'اقتراح زيارة',
                  icon: Icons.add,
                  onPressed: _propose,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _grid(List<Visit> visits) {
    const weekdays = [
      'السبت',
      'الأحد',
      'الإثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
    ];
    const daysPerWeek = DateTime.daysPerWeek;
    final offset =
        (_month.weekday - DateTime.saturday + daysPerWeek) % daysPerWeek;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = (offset + days + daysPerWeek - 1) ~/ daysPerWeek;
    return Column(
      children: [
        Row(
          children: [
            for (final day in weekdays)
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    day,
                    style: RType.label.copyWith(color: context.c.textSecondary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: RSpace.s2),
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < daysPerWeek; col++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final day = row * daysPerWeek + col - offset + 1;
                      if (day < 1 || day > days) {
                        return const SizedBox(height: RSpace.s12);
                      }
                      final date = DateTime(_month.year, _month.month, day);
                      final selected = _selected == date;
                      final today =
                          visitDayKey(date) == visitDayKey(DateTime.now());
                      final statuses = visits
                          .where((v) => v.date == visitDayKey(date))
                          .map((v) => v.status)
                          .toSet();
                      return Semantics(
                        selected: selected,
                        label: visitDate(date, 'EEEE d MMMM yyyy'),
                        child: TextButton(
                          key: ValueKey('day-${visitDayKey(date)}'),
                          onPressed: () => setState(() => _selected = date),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(RSpace.s0, RSpace.s12),
                            foregroundColor: selected
                                ? context.c.onPrimary
                                : context.c.textPrimary,
                            backgroundColor: selected
                                ? context.c.primary
                                : null,
                            shape: CircleBorder(
                              side: today
                                  ? BorderSide(
                                      color: context.c.primary,
                                      width: RBorderWidth.medium,
                                    )
                                  : BorderSide.none,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$day', style: RType.label),
                              SizedBox(
                                height: RSpace.s2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (final status in statuses)
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.symmetric(
                                              horizontal: RSpace.s0_5,
                                            ),
                                        child: Container(
                                          width: RSpace.s1,
                                          height: RSpace.s1,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: selected
                                                ? context.c.onPrimary
                                                : switch (status) {
                                                    VisitStatus.proposed =>
                                                      context
                                                          .c
                                                          .feedbackWarningIcon,
                                                    VisitStatus.accepted =>
                                                      context
                                                          .c
                                                          .feedbackInfoIcon,
                                                    VisitStatus.declined =>
                                                      context
                                                          .c
                                                          .feedbackErrorIcon,
                                                    VisitStatus.confirmed =>
                                                      context.c.primary,
                                                  },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
