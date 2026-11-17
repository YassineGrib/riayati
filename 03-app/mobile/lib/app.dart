import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_controller.dart';

class RiayatiApp extends ConsumerStatefulWidget {
  const RiayatiApp({super.key});
  @override
  ConsumerState<RiayatiApp> createState() => _RiayatiAppState();
}

class _RiayatiAppState extends ConsumerState<RiayatiApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(authControllerProvider.notifier).refresh();
      } catch (_) {
        /* Welcome remains available; login can retry authentication. */
      }
    });
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Riayati',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
  );
}
