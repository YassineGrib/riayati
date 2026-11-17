import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/welcome_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, route) {
      final auth = ref.read(authControllerProvider);
      final path = route.uri.path;
      const public = ['/welcome', '/login', '/register', '/forgot'];
      if (auth.status == AuthStatus.unknown) {
        return public.contains(path) ? null : '/welcome';
      }
      if (auth.status == AuthStatus.signedOut) {
        return public.contains(path) ? null : '/welcome';
      }
      if (!auth.user!.linked) return path == '/link' ? null : '/link';
      return public.contains(path) || path == '/link' ? '/home' : null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (_, _) => const ForgotPasswordScreen()),
      for (final entry in const {
        '/link': 'ربط الوالد الآخر',
        '/home': 'الرئيسية',
        '/reports': 'التقارير',
        '/reports/new': 'تقرير جديد',
        '/reports/:id': 'تفاصيل التقرير',
        '/calendar': 'التقويم',
        '/assistant': 'المساعد',
        '/profile': 'حسابي',
      }.entries)
        GoRoute(path: entry.key, builder: (_, _) => Text(entry.value)),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
