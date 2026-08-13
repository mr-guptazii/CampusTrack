import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';

class CampusTrackApp extends StatefulWidget {
  const CampusTrackApp({super.key});

  @override
  State<CampusTrackApp> createState() => _CampusTrackAppState();
}

class _CampusTrackAppState extends State<CampusTrackApp> {
  // Built once and reused: router.dart already wires `refreshListenable:
  // auth` to react to auth changes, so rebuilding the GoRouter itself on
  // every AuthProvider.notifyListeners() (e.g. dragging the target-%
  // slider, toggling a switch) would hand MaterialApp.router a brand-new
  // router instance each time. Flutter then tears down and recreates the
  // whole Router/Navigator tree, discarding MainShellScreen's selected-tab
  // state and bouncing back through the redirect logic to /home.
  late final GoRouter _router = AppRouter.build(context.read<AuthProvider>());

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return MaterialApp.router(
      title: 'CampusTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: auth.currentUser?.darkModeEnabled == true
          ? ThemeMode.dark
          : ThemeMode.light,
      routerConfig: _router,
    );
  }
}
