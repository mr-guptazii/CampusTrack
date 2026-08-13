import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_record.dart';
import '../models/subject.dart';
import '../models/timetable_entry.dart';
import '../core/utils/date_utils.dart';
import 'attendance_button.dart';

/// Bottom sheet for marking attendance on a specific [date]: one row per
/// scheduled class (from the timetable) with inline Present/Absent/
/// Cancelled/Extra buttons, a "substitute" action per class that marks the
/// original as cancelled and lets you add whichever class was actually
/// held instead, and a standalone "add an extra class" action for classes
/// held outside the normal schedule. Used by both the Dashboard's quick
/// "Mark Attendance" action (date = today) and the Calendar screen
/// (date = whichever day was tapped).
class MarkAttendanceSheet extends StatefulWidget {
  final DateTime date;
  final List<TimetableEntry> entries;
  final List<Subject> allSubjects;

  const MarkAttendanceSheet({
    super.key,
    required this.date,
    required this.entries,
    required this.allSubjects,
  });

  @override
  State<MarkAttendanceSheet> createState() => _MarkAttendanceSheetState();
}

class _MarkAttendanceSheetState extends State<MarkAttendanceSheet> {
  final Map<String, AttendanceStatus> _selections = {};
  final List<String> _extraSubjectIds = [];

  @override
  void initState() {
    super.initState();
    // Pre-fill selections with anything already marked for this date so
    // reopening the sheet shows the current state instead of resetting it.
    final records = context.read<AttendanceProvider>().forDate(widget.date);
    for (final r in records) {
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
        const SnackBar(
            content: Text('All your subjects are already listed for this day')),
      );
      return Future.value(null);
    }
    return showModalBottomSheet<Subject>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (pickerContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final scheduledIds = widget.entries.map((e) => e.subjectId).toSet();
    return widget.allSubjects
        .where((s) =>
            !scheduledIds.contains(s.id) &&
            !_extraSubjectIds.contains(s.id) &&
            s.id != excludeSubjectId)
        .toList();
  }

  Future<void> _addExtraClass() async {
    final picked = await _pickSubject(
        _substitutionCandidates(), 'Which class was actually held?');
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
          date: widget.date,
          status: AttendanceStatus.cancelled,
        );
  }

  Widget _buildRow(
      {required String subjectId,
      required String? subtitle,
      VoidCallback? onSubstitute}) {
    final subject = _subjectById(subjectId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(subject?.name ?? 'Unknown subject',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (onSubstitute != null)
                TextButton.icon(
                  onPressed: onSubstitute,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('Substitute'),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact),
                ),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 6),
              child: Text(subtitle,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            const SizedBox(height: 8),
          AttendanceButtonGroup(
            selected: _selections[subjectId],
            onSelect: (status) async {
              setState(() => _selections[subjectId] = status);
              await context.read<AttendanceProvider>().markAttendance(
                    subjectId: subjectId,
                    date: widget.date,
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
    final hasAnyClasses =
        widget.entries.isNotEmpty || _extraSubjectIds.isNotEmpty;
    final isToday = AppDateUtils.isSameDay(widget.date, DateTime.now());
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
          Text(
            isToday ? 'Mark today\'s attendance' : 'Mark attendance',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(AppDateUtils.dayMonthYear(widget.date),
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (!hasAnyClasses)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No classes scheduled this day.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final entry in widget.entries) ...[
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
                    _buildRow(
                        subjectId: id, subtitle: 'Added to this day\'s list'),
                    const Divider(),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _addExtraClass,
            icon: const Icon(Icons.add),
            label: Text(isToday
                ? 'Add an extra class held today'
                : 'Add an extra class held this day'),
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
