import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/centers/center_repository.dart';
import 'package:riayati/features/centers/support_center.dart';

const longArabic = 'مركز قضائي أو هيئة حماية ذات عنوان طويل وتفاصيل شاملة لضمان عدم حدوث تجاوز في الشاشة ';

SupportCenter sampleCenter({bool long = false, int id = 1}) => SupportCenter(
  id: id,
  name: long ? List.filled(6, longArabic).join() : 'محكمة سيدي امحمد - قسم الأسرة',
  kind: CenterKind.court,
  kindLabel: 'محكمة',
  wilaya: '16',
  address: long ? List.filled(8, longArabic).join() : 'شارع عبان رمضان، الجزائر العاصمة',
  phone: '000-000-000',
  hotline: '11-11',
  email: 'contact@court.dz',
  website: 'https://court.dz',
  hours: 'الأحد إلى الخميس: 08:30 – 16:30',
  notes: long
      ? List.filled(20, longArabic).join()
      : 'النظر في دعاوى الحضانة والزيارة والنفقة. يجب إحضار الوثائق الرسمية والأحكام السابقة.',
);

class FakeCenterRepository extends Fake implements CenterRepository {
  List<SupportCenter> items = [sampleCenter()];
  SupportCenter detail = sampleCenter();
  Object? listError;
  Object? detailError;
  Completer<List<SupportCenter>>? pendingList;
  Completer<SupportCenter>? pendingDetail;
  final capturedKinds = <CenterKind?>[];
  final capturedWilayas = <String?>[];
  final capturedQueries = <String?>[];
  final capturedIds = <int>[];

  @override
  Future<List<SupportCenter>> list({CenterKind? kind, String? wilaya, String? query}) async {
    capturedKinds.add(kind);
    capturedWilayas.add(wilaya);
    capturedQueries.add(query);
    if (listError != null) throw listError!;
    return pendingList == null ? items : await pendingList!.future;
  }

  @override
  Future<SupportCenter> get(int id) async {
    capturedIds.add(id);
    if (detailError != null) throw detailError!;
    return pendingDetail == null ? detail : await pendingDetail!.future;
  }
}

Future<void> pumpCenters(
  WidgetTester tester,
  Widget screen,
  FakeCenterRepository repo, {
  Brightness brightness = Brightness.light,
  List<String>? pushedRoutes,
}) async {
  await initializeDateFormatting('ar');
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: '/home',
        builder: (_, _) {
          pushedRoutes?.add('/home');
          return const Scaffold(body: Text('home route'));
        },
      ),
      GoRoute(
        path: '/centers',
        builder: (_, _) {
          pushedRoutes?.add('/centers');
          return const Scaffold(body: Text('centers route'));
        },
      ),
      GoRoute(
        path: '/centers/:id',
        builder: (_, state) {
          final id = state.pathParameters['id'];
          pushedRoutes?.add('/centers/$id');
          return Scaffold(body: Text('center detail: $id'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [centerRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp.router(
        routerConfig: router,
        theme: buildTheme(brightness).copyWith(
          splashFactory: InkRipple.splashFactory,
        ),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}
