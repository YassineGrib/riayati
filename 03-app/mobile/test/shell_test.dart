import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riayati/core/router.dart';
import 'package:riayati/core/shell.dart';
import 'package:riayati/core/widgets/floating_nav.dart';

import 'family/family_test_support.dart';

void main() {
  testWidgets('each tab switches branch and exposes the selected index', (
    tester,
  ) async {
    final container = await pumpFamilyApp(
      tester,
      FamilyTestApi()..linked = true,
    );
    final router = container.read(routerProvider);
    const paths = ['/home', '/reports', '/calendar', '/assistant', '/profile'];
    // Revisit home and reports to cover switching back to existing branches.
    for (final index in [0, 1, 2, 3, 4, 0, 1]) {
      await tester.tap(find.byKey(ValueKey('nav-$index')));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, paths[index]);
      expect(tester.widget<FloatingNav>(find.byType(FloatingNav)).index, index);
      for (var tab = 0; tab < paths.length; tab++) {
        expect(
          tester
              .widget<Semantics>(find.byKey(ValueKey('nav-$tab')))
              .properties
              .selected,
          tab == index,
        );
      }
      expect(find.byType(Shell), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'deep links select their branch; report forms and details are full screen',
    (tester) async {
      final container = await pumpFamilyApp(
        tester,
        FamilyTestApi()..linked = true,
      );
      final router = container.read(routerProvider);
      router.go('/calendar');
      await tester.pumpAndSettle();
      expect(tester.widget<FloatingNav>(find.byType(FloatingNav)).index, 2);
      for (final path in ['/reports/new', '/reports/123']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, path);
        expect(find.byType(FloatingNav), findsNothing);
        expect(find.byType(Shell), findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
