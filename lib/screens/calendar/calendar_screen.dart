import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/mark_attendance_sheet.dart';

/// Month-grid calendar. Each day is tinted red→yellow→green based on that
/// day's attendance percentage (grey/uncolored if nothing was marked that
/// day). Tapping a day opens [MarkAttendanceSheet] for it.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Color _colorForPercentage(double p) {
    if (p <= 0.5) {
      return Color.lerp(AppColors.danger, AppColors.warning, p / 0.5)!;
    }
    return Color.lerp(AppColors.warning, AppColors.success, (p - 0.5) / 0.5)!;
  }

  void _openDay(BuildContext context, DateTime day) {
    final timetableProvider = context.read<TimetableProvider>();
    final allSubjects = context.read<SubjectProvider>().subjects;
    final entries = timetableProvider.forDay(WeekdayX.fromDateTime(day));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => MarkAttendanceSheet(
          date: day, entries: entries, allSubjects: allSubjects),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attendanceProvider = context.watch<AttendanceProvider>();
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1; // Monday-start grid
    final totalCells = ((leadingBlanks + daysInMonth) / 7).ceil() * 7;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1)),
                    Text(
                      '${_monthName(_month.month)} ${_month.year}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: Weekday.values
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(
                                d.short,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final dayNum = index - leadingBlanks + 1;
                    if (dayNum < 1 || dayNum > daysInMonth) {
                      return const SizedBox.shrink();
                    }
                    final day = DateTime(_month.year, _month.month, dayNum);
                    final isToday = AppDateUtils.isSameDay(day, now);
                    final percentage =
                        attendanceProvider.percentageForDate(day);

                    return Padding(
                      padding: const EdgeInsets.all(3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openDay(context, day),
                        child: Container(
                          decoration: BoxDecoration(
                            color: percentage != null
                                ? _colorForPercentage(percentage)
                                    .withValues(alpha: 0.22)
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday
                                ? Border.all(color: scheme.primary, width: 1.5)
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                              fontWeight:
                                  isToday ? FontWeight.w800 : FontWeight.w500,
                              color: percentage != null
                                  ? _colorForPercentage(percentage)
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _Legend(colorFor: _colorForPercentage),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ][month - 1];
}

class _Legend extends StatelessWidget {
  final Color Function(double) colorFor;
  const _Legend({required this.colorFor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget dot(Color c) => Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        );
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(c),
            Text(label,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
          ],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          item(colorFor(0), '0% attended'),
          item(colorFor(0.5), 'Partial'),
          item(colorFor(1), '100% attended'),
          item(scheme.surfaceContainerHigh, 'Not marked'),
        ],
      ),
    );
  }
}
