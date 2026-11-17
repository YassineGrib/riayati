import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/core/widgets/r_button.dart';
import 'package:riayati/features/calendar/visit.dart';
import 'package:riayati/features/calendar/visit_repository.dart';

Visit sampleVisit({
  bool response = false,
  bool confirm = false,
  String? note,
}) => Visit(
  id: 7,
  date: '2026-11-20',
  from: '10:00',
  to: '14:00',
  note: note,
  status: confirm ? VisitStatus.accepted : VisitStatus.proposed,
  proposedByMe: confirm,
  needsMyResponse: response,
  canConfirm: confirm,
  timeline: [
    VisitTimelineEntry(step: 'proposed', at: DateTime(2026, 11, 15, 18, 20)),
  ],
);

class FakeVisits extends Fake implements VisitRepository {
  Visit detail = sampleVisit();
  List<Visit> visits = [sampleVisit()];
  Object? error;
  Object? proposeError;
  Object? actionError;
  Completer<List<Visit>>? pending;
  final months = <String>[];
  final actions = <String>[];
  int proposals = 0;
  @override
  Future<List<Visit>> month(String ym) async {
    months.add(ym);
    if (error != null) throw error!;
    return pending == null ? visits : await pending!.future;
  }

  @override
  Future<List<Visit>> upcoming() async => visits;
  @override
  Future<Visit> get(int id) async {
    if (error != null) throw error!;
    return detail;
  }

  Future<Visit> act(String action) async {
    actions.add(action);
    if (actionError != null) throw actionError!;
    return detail = sampleVisit();
  }

  @override
  Future<Visit> accept(int id) => act('accept');
  @override
  Future<Visit> decline(int id) => act('decline');
  @override
  Future<Visit> confirm(int id) => act('confirm');
  @override
  Future<Visit> propose({
    required String date,
    required String from,
    required String to,
    String? note,
  }) async {
    proposals++;
    if (proposeError != null) throw proposeError!;
    return detail;
  }
}

Future<void> pumpCalendar(
  WidgetTester tester,
  Widget screen,
  FakeVisits repo, {
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: '/link',
        builder: (_, _) => const Scaffold(body: Text('link route')),
      ),
      GoRoute(
        path: '/calendar/7',
        builder: (_, _) => const Scaffold(body: Text('detail route')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [visitRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildTheme(brightness),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Finder calendarButton(String label) =>
    find.byWidgetPredicate((w) => w is RButton && w.label == label);
Future<void> tapCalendarButton(WidgetTester tester, String label) async {
  await tester.ensureVisible(calendarButton(label));
  await tester.tap(calendarButton(label));
  await tester.pumpAndSettle();
}
