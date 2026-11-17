import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/assistant/assistant_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/calendar/visit_detail_screen.dart';
import '../features/family/link_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/change_password_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/privacy_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/terms_screen.dart';
import '../features/reports/new_report_screen.dart';
import '../features/reports/report_detail_screen.dart';
import '../features/reports/reports_screen.dart';
import 'shell.dart';

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
      GoRoute(path: '/link', builder: (_, _) => const LinkScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            Shell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/reports', builder: (_, _) => ReportsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/calendar', builder: (_, _) => CalendarScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant',
                builder: (_, _) => const AssistantScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(path: '/profile/terms', builder: (_, _) => const TermsScreen()),
      GoRoute(
        path: '/profile/privacy',
        builder: (_, _) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/profile/password',
        builder: (_, _) => const ChangePasswordScreen(),
      ),
      GoRoute(path: '/reports/new', builder: (_, _) => NewReportScreen()),
      GoRoute(
        path: '/reports/:id',
        builder: (_, state) =>
            ReportDetailScreen(int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/calendar/:id',
        builder: (_, state) =>
            VisitDetailScreen(int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
