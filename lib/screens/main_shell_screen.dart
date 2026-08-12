import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'subjects/subject_list_screen.dart';
import 'timetable/timetable_screen.dart';
import 'analytics/analytics_screen.dart';
import 'settings/settings_screen.dart';
import '../providers/subject_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/timetable_provider.dart';

/// Hosts the 5 primary tabs behind a Material 3 NavigationBar. Pushed
/// screens (add/edit subject, attendance history, bunk calculator, profile,
/// timetable entry) live outside this shell as top-level go_router routes.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    SubjectListScreen(),
    TimetableScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final subjectProvider = context.read<SubjectProvider>();
      // Must complete before the empty-check below, otherwise a returning
      // user's real Firestore data may not have loaded yet and this would
      // incorrectly seed demo subjects into their account.
      await subjectProvider.syncWithRemote();
      // TimetableProvider's constructor also fires a sync at app bootstrap,
      // but FirebaseAuth's persisted session may not have resolved yet at
      // that point (especially on a fresh install), so that first attempt
      // can silently no-op. Re-sync here, once auth is guaranteed ready.
      if (mounted) {
        await context.read<TimetableProvider>().syncWithRemote();
      }
      subjectProvider.startListening();
      await subjectProvider.seedDemoDataIfEmpty();
      if (mounted) {
        await context.read<AttendanceProvider>().init();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Subjects'),
          NavigationDestination(icon: Icon(Icons.schedule_outlined), selectedIcon: Icon(Icons.schedule_rounded), label: 'Timetable'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
