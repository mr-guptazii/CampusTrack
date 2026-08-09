import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/attendance_record.dart';
import '../models/subject.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';

/// Pie chart showing Present / Absent / Cancelled / Extra breakdown.
class AttendancePieChart extends StatelessWidget {
  final Map<AttendanceStatus, int> breakdown;

  const AttendancePieChart({super.key, required this.breakdown});

  Color _colorFor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.success;
      case AttendanceStatus.absent:
        return AppColors.danger;
      case AttendanceStatus.cancelled:
        return Colors.grey;
      case AttendanceStatus.extra:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const Center(child: Text('No attendance data yet'));
    }
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: breakdown.entries.where((e) => e.value > 0).map((e) {
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    color: _colorFor(e.key),
                    title: '${((e.value / total) * 100).toStringAsFixed(0)}%',
                    radius: 46,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: breakdown.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: _colorFor(e.key), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${e.key.label} (${e.value})', style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Bar chart of subject-wise attendance percentage.
class SubjectPercentageBarChart extends StatelessWidget {
  final List<Subject> subjects;

  const SubjectPercentageBarChart({super.key, required this.subjects});

  @override
  Widget build(BuildContext context) {
    final withClasses = subjects.where((s) => s.total > 0).toList();
    if (withClasses.isEmpty) {
      return const Center(child: Text('No subject data yet'));
    }
    return BarChart(
      BarChartData(
        maxY: 100,
        minY: 0,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= withClasses.length) return const SizedBox.shrink();
                final code = withClasses[index].code.isNotEmpty
                    ? withClasses[index].code
                    : withClasses[index].name.substring(0, withClasses[index].name.length.clamp(0, 4));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(code, style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(withClasses.length, (i) {
          final s = withClasses[i];
          final color = Color(s.colorValue);
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(
              toY: s.percentage,
              color: color,
              width: 18,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(show: true, toY: 100, color: color.withValues(alpha: 0.08)),
            ),
          ]);
        }),
      ),
    );
  }
}

/// Line chart of attendance percentage trend over the last N days.
class AttendanceTrendLineChart extends StatelessWidget {
  final Map<DateTime, double> trend;

  const AttendanceTrendLineChart({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) {
      return const Center(child: Text('No trend data yet'));
    }
    final dates = trend.keys.toList();
    final spots = List.generate(dates.length, (i) => FlSpot(i.toDouble(), trend[dates[i]]!));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (dates.length / 5).clamp(1, dates.length).toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(AppDateUtils.dayMonth(dates[index]), style: const TextStyle(fontSize: 9)),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
