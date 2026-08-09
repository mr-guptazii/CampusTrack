import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/main_shell_screen.dart';
import '../screens/subjects/add_edit_subject_screen.dart';
import '../screens/attendance/attendance_history_screen.dart';
import '../screens/timetable/add_timetable_entry_screen.dart';
import '../screens/analytics/bunk_calculator_screen.dart';
import '../screens/settings/profile_screen.dart';

/// Central go_router configuration. Redirect logic keeps unauthenticated
/// users out of the app shell and authenticated users out of the auth
/// screens.
class AppRouter {
  AppRouter._();

  static GoRouter build(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';
        final onSplash = state.matchedLocation == '/splash';

        if (auth.status == AuthStatus.unknown) {
          return onSplash ? null : '/splash';
        }
        if (auth.status == AuthStatus.unauthenticated) {
          return loggingIn ? null : '/login';
        }
        // authenticated
        if (loggingIn || onSplash) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
        GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
        GoRoute(path: '/home', builder: (c, s) => const MainShellScreen()),
        GoRoute(
          path: '/subjects/add',
          builder: (c, s) => const AddEditSubjectScreen(),
        ),
        GoRoute(
          path: '/subjects/edit/:id',
          builder: (c, s) => AddEditSubjectScreen(subjectId: s.pathParameters['id']),
        ),
        GoRoute(
          path: '/attendance-history/:subjectId',
          builder: (c, s) =>
              AttendanceHistoryScreen(subjectId: s.pathParameters['subjectId']!),
        ),
        GoRoute(
          path: '/timetable/add',
          builder: (c, s) => const AddTimetableEntryScreen(),
        ),
        GoRoute(
          path: '/timetable/edit/:id',
          builder: (c, s) => AddTimetableEntryScreen(entryId: s.pathParameters['id']),
        ),
        GoRoute(
          path: '/bunk-calculator',
          builder: (c, s) => const BunkCalculatorScreen(),
        ),
        GoRoute(path: '/profile', builder: (c, s) => const ProfileScreen()),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text('Route not found: ${state.uri}')),
      ),
    );
  }
}
