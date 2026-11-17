import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';

class RiayatiApp extends StatefulWidget {
  const RiayatiApp({super.key});
  @override
  State<RiayatiApp> createState() => _RiayatiAppState();
}

class _RiayatiAppState extends State<RiayatiApp> {
  late final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const _Placeholder()),
    ],
  );
  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'رعايتي',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    routerConfig: _router,
    builder: (context, child) =>
        Directionality(textDirection: TextDirection.rtl, child: child!),
  );
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Text('رعايتي', style: Theme.of(context).textTheme.displayLarge),
      ),
    ),
  );
}
