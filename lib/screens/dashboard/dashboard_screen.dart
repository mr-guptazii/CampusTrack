import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_record.dart';
import '../../models/subject.dart';
import '../../models/timetable_entry.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/percentage_indicator.dart';
import '../../widgets/timetable_tile.dart';
import '../../widgets/subject_card.dart';
import '../../widgets/attendance_button.dart';
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return _QuickMarkSheet(todayEntries: todayEntries, allSubjects: allSubjects);
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
        title: Text('Hi, ${auth.currentUser?.displayName.split(' ').first ?? 'there'} 👋'),
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
                        const Text('Overall Attendance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          '${subjectProvider.overallPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subjectProvider.overallPercentage >= AppDefaults.targetPercentage
                              ? 'Great job staying on track!'
                              : 'Below your ${AppDefaults.targetPercentage.toStringAsFixed(0)}% target',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            Text("Today's Classes", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (todayClasses.isEmpty)
              const _EmptyHint(icon: Icons.event_available_outlined, message: 'No classes scheduled today')
            else
              ...todayClasses.map((entry) {
                final subject = subjectProvider.byId(entry.subjectId);
                final ongoing = timetableProvider.currentOngoing()?.id == entry.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TimetableTile(entry: entry, subject: subject, isOngoing: ongoing),
                );
              }),
            const SizedBox(height: 24),

            // Weekly summary chart
            Text('Weekly Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(height: 160, child: AttendanceTrendLineChart(trend: trend)),
              ),
            ),
            const SizedBox(height: 24),

            // Subjects below target
            Text('Subjects Below Target', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (belowTarget.isEmpty)
              const _EmptyHint(icon: Icons.emoji_events_outlined, message: 'All subjects are on target!')
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

  const _QuickAction({required this.icon, required this.label, required this.onTap});

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
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
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

class _QuickMarkSheet extends StatefulWidget {
  final List<TimetableEntry> todayEntries;
  final List<Subject> allSubjects;

  const _QuickMarkSheet({required this.todayEntries, required this.allSubjects});

  @override
  State<_QuickMarkSheet> createState() => _QuickMarkSheetState();
}

class _QuickMarkSheetState extends State<_QuickMarkSheet> {
  final Map<String, AttendanceStatus> _selections = {};
  final List<String> _extraSubjectIds = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill selections with anything already marked for today so
    // reopening the sheet shows the current state instead of resetting it.
    final todayRecords = context.read<AttendanceProvider>().forDate(DateTime.now());
    for (final r in todayRecords) {
      _selections[r.subjectId] = r.status;
    }
  }

  Subject? _subjectById(String id) {
    for (final s in widget.allSubjects) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<Subject?> _pickSubject(List<Subject> available, String title) {
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All your subjects are already listed for today')),
      );
      return Future.value(null);
    }
    return showModalBottomSheet<Subject>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (pickerContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              ...available.map((s) => ListTile(
                    title: Text(s.name),
                    subtitle: Text(s.code),
                    onTap: () => Navigator.pop(pickerContext, s),
                  )),
            ],
          ),
        );
      },
    );
  }

  List<Subject> _substitutionCandidates({String? excludeSubjectId}) {
    final scheduledIds = widget.todayEntries.map((e) => e.subjectId).toSet();
    return widget.allSubjects
        .where((s) =>
            !scheduledIds.contains(s.id) &&
            !_extraSubjectIds.contains(s.id) &&
            s.id != excludeSubjectId)
        .toList();
  }

  Future<void> _addExtraClass() async {
    final picked = await _pickSubject(_substitutionCandidates(), 'Which class was actually held?');
    if (picked != null) {
      setState(() => _extraSubjectIds.add(picked.id));
    }
  }

  Future<void> _substituteClass(String originalSubjectId) async {
    final picked = await _pickSubject(
      _substitutionCandidates(excludeSubjectId: originalSubjectId),
      'Which class was held instead?',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selections[originalSubjectId] = AttendanceStatus.cancelled;
      _extraSubjectIds.add(picked.id);
    });
    await context.read<AttendanceProvider>().markAttendance(
          subjectId: originalSubjectId,
          date: DateTime.now(),
          status: AttendanceStatus.cancelled,
        );
  }

  Widget _buildRow({required String subjectId, required String? subtitle, VoidCallback? onSubstitute}) {
    final subject = _subjectById(subjectId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(subject?.name ?? 'Unknown subject', style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (onSubstitute != null)
                TextButton.icon(
                  onPressed: onSubstitute,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Substitute'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            const SizedBox(height: 8),
          AttendanceButtonGroup(
            selected: _selections[subjectId],
            onSelect: (status) async {
              setState(() => _selections[subjectId] = status);
              await context.read<AttendanceProvider>().markAttendance(
                    subjectId: subjectId,
                    date: DateTime.now(),
                    status: status,
                  );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyClasses = widget.todayEntries.isNotEmpty || _extraSubjectIds.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mark today\'s attendance', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          Text(AppDateUtils.dayMonthYear(DateTime.now()), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (!hasAnyClasses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No classes scheduled today.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in widget.todayEntries) ...[
                    _buildRow(
                      subjectId: entry.subjectId,
                      subtitle:
                          '${AppDateUtils.formatHHmm(entry.startTime)} - ${AppDateUtils.formatHHmm(entry.endTime)}'
                          '${entry.room.isNotEmpty ? ' · ${entry.room}' : ''}',
                      onSubstitute: () => _substituteClass(entry.subjectId),
                    ),
                    const Divider(),
                  ],
                  for (final id in _extraSubjectIds) ...[
                    _buildRow(subjectId: id, subtitle: 'Added to today\'s list'),
                    const Divider(),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _addExtraClass,
            icon: const Icon(Icons.add),
            label: const Text('Add an extra class held today'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
