import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/analytics_chart.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final attendanceProvider = context.watch<AttendanceProvider>();

    final best = subjectProvider.bestSubject();
    final worst = subjectProvider.worstSubject();
    final totalAttended = subjectProvider.subjects.fold<int>(0, (a, s) => a + s.attended);
    final streak = attendanceProvider.currentStreak();
    final breakdown = attendanceProvider.statusBreakdown();
    final trend = attendanceProvider.lastNDaysTrend(30);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Bunk Calculator',
            onPressed: () => context.push('/bunk-calculator'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stat grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _StatCard(label: 'Average Attendance', value: '${subjectProvider.overallPercentage.toStringAsFixed(1)}%', icon: Icons.pie_chart_outline, color: AppColors.primary),
              _StatCard(label: 'Total Classes Attended', value: '$totalAttended', icon: Icons.check_circle_outline, color: AppColors.success),
              _StatCard(label: 'Best Subject', value: best?.name ?? '-', icon: Icons.emoji_events_outlined, color: AppColors.accent, sub: best != null ? '${best.percentage.toStringAsFixed(1)}%' : null),
              _StatCard(label: 'Needs Attention', value: worst?.name ?? '-', icon: Icons.trending_down, color: AppColors.warning, sub: worst != null ? '${worst.percentage.toStringAsFixed(1)}%' : null),
            ],
          ),
          const SizedBox(height: 8),
          _StatCard(label: 'Attendance Streak', value: '$streak day${streak == 1 ? '' : 's'}', icon: Icons.local_fire_department_outlined, color: AppColors.danger, wide: true),
          const SizedBox(height: 24),

          Text('Status Breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(height: 180, child: AttendancePieChart(breakdown: breakdown)),
            ),
          ),
          const SizedBox(height: 24),

          Text('Subject-wise Percentage', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              child: SizedBox(height: 220, child: SubjectPercentageBarChart(subjects: subjectProvider.subjects)),
            ),
          ),
          const SizedBox(height: 24),

          Text('Last 30 Days Trend', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(height: 200, child: AttendanceTrendLineChart(trend: trend)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;
  final bool wide;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, this.sub, this.wide = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (sub != null) Text(sub!, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
