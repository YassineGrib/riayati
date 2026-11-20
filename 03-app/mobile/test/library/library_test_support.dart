import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:riayati/core/theme/app_theme.dart';
import 'package:riayati/features/library/content_item.dart';
import 'package:riayati/features/library/content_repository.dart';

const longArabic = 'نص قانوني أو مقال تعليمي طويل جدًا لتأكيد ملاءمة التصميم وعدم تجاوز الشاشة ';

ContentItem sampleContent({bool long = false, String slug = 'custody-eligibility'}) => ContentItem(
  id: 1,
  type: ContentType.law,
  typeLabel: 'قانون',
  title: 'شروط استحقاق الحضانة وسقوطها',
  slug: slug,
  category: 'قانون الأسرة',
  reference: 'المواد 64، 65 و66',
  summary: long ? List.filled(30, longArabic).join() : 'ملخص لأهم المواد المنظمة للحضانة في قانون الأسرة الجزائري.',
  publishedAt: DateTime(2026, 11, 18, 10, 0),
  body: long
      ? List.filled(50, longArabic).join()
      : 'الحضانة هي حفظ الولد وتربيته ورعايته بما يحقق مصلحته الفضلى. وتسقط الحضانة إذا اختلت الشروط الواجب توفرها.',
);

class FakeContentRepository extends Fake implements ContentRepository {
  List<ContentItem> items = [sampleContent()];
  ContentItem detail = sampleContent();
  Object? listError;
  Object? detailError;
  Completer<List<ContentItem>>? pendingList;
  Completer<ContentItem>? pendingDetail;
  final capturedTypes = <ContentType?>[];
  final capturedQueries = <String?>[];
  final capturedSlugs = <String>[];

  @override
  Future<List<ContentItem>> list({ContentType? type, String? query, int? page}) async {
    capturedTypes.add(type);
    capturedQueries.add(query);
    if (listError != null) throw listError!;
    return pendingList == null ? items : await pendingList!.future;
  }

  @override
  Future<ContentItem> get(String slug) async {
    capturedSlugs.add(slug);
    if (detailError != null) throw detailError!;
    return pendingDetail == null ? detail : await pendingDetail!.future;
  }
}

Future<void> pumpLibrary(
  WidgetTester tester,
  Widget screen,
  FakeContentRepository repo, {
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
        path: '/library',
        builder: (_, _) {
          pushedRoutes?.add('/library');
          return const Scaffold(body: Text('library route'));
        },
      ),
      GoRoute(
        path: '/library/:slug',
        builder: (_, state) {
          final slug = state.pathParameters['slug'];
          pushedRoutes?.add('/library/$slug');
          return Scaffold(body: Text('detail route: $slug'));
        },
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [contentRepositoryProvider.overrideWithValue(repo)],
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
