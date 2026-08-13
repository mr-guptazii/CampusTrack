import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/percentage_indicator.dart';
import '../../widgets/timetable_tile.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/mark_attendance_sheet.dart';
import '../../widgets/analytics_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    final subjectProvider = context.read<SubjectProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final timetableProvider = context.read<TimetableProvider>();
    await subjectProvider.syncWithRemote();
    await attendanceProvider.syncWithRemote();
    await timetableProvider.syncWithRemote();
  }

  void _openQuickMark(BuildContext context) {
    final todayEntries = context.read<TimetableProvider>().todayEntries();
    final allSubjects = context.read<SubjectProvider>().subjects;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return MarkAttendanceSheet(
            date: DateTime.now(),
            entries: todayEntries,
            allSubjects: allSubjects);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final subjectProvider = context.watch<SubjectProvider>();
    final timetableProvider = context.watch<TimetableProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();
    final scheme = Theme.of(context).colorScheme;

    final todayClasses = timetableProvider.todayEntries();
    final belowTarget = subjectProvider.belowTargetSubjects;
    final trend = attendanceProvider.lastNDaysTrend(7);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Hi, ${auth.currentUser?.displayName.split(' ').first ?? 'there'} 👋'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.heroGradient(scheme),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overall Attendance',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          '${subjectProvider.overallPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subjectProvider.overallPercentage >=
                                  AppDefaults.targetPercentage
                              ? 'Great job staying on track!'
                              : 'Below your ${AppDefaults.targetPercentage.toStringAsFixed(0)}% target',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  PercentageIndicator(
                    percentage: subjectProvider.overallPercentage,
                    size: 76,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.check_circle_outline,
                    label: 'Mark\nAttendance',
                    onTap: () => _openQuickMark(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Add\nSubject',
                    onTap: () => context.push('/subjects/add'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.calculate_outlined,
                    label: 'Bunk\nCalculator',
                    onTap: () => context.push('/bunk-calculator'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's classes
            Text("Today's Classes",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (todayClasses.isEmpty)
              const _EmptyHint(
                  icon: Icons.event_available_outlined,
                  message: 'No classes scheduled today')
            else
              ...todayClasses.map((entry) {
                final subject = subjectProvider.byId(entry.subjectId);
                final ongoing =
                    timetableProvider.currentOngoing()?.id == entry.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TimetableTile(
                      entry: entry, subject: subject, isOngoing: ongoing),
                );
              }),
            const SizedBox(height: 24),

            // Weekly summary chart
            Text('Weekly Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                    height: 160, child: AttendanceTrendLineChart(trend: trend)),
              ),
            ),
            const SizedBox(height: 24),

            // Subjects below target
            Text('Subjects Below Target',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (belowTarget.isEmpty)
              const _EmptyHint(
                  icon: Icons.emoji_events_outlined,
                  message: 'All subjects are on target!')
            else
              ...belowTarget.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SubjectCard(
                      subject: s,
                      onTap: () => context.push('/attendance-history/${s.id}'),
                    ),
                  )),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 36, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
