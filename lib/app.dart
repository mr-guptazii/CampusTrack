import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/router.dart';
import 'providers/auth_provider.dart';

class CampusTrackApp extends StatelessWidget {
  const CampusTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final router = AppRouter.build(auth);

    return MaterialApp.router(
      title: 'CampusTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: auth.currentUser?.darkModeEnabled == true
          ? ThemeMode.dark
          : ThemeMode.light,
      routerConfig: router,
    );
  }
}
