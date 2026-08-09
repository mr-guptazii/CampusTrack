import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/subject_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../models/timetable_entry.dart';

class AddTimetableEntryScreen extends StatefulWidget {
  final String? entryId;
  const AddTimetableEntryScreen({super.key, this.entryId});

  @override
  State<AddTimetableEntryScreen> createState() => _AddTimetableEntryScreenState();
}

class _AddTimetableEntryScreenState extends State<AddTimetableEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();
  Weekday _day = WeekdayX.fromDateTime(DateTime.now());
  String? _subjectId;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  TimetableEntry? _existing;

  bool get isEditing => widget.entryId != null;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      _existing = context.read<TimetableProvider>().entries.where((e) => e.id == widget.entryId).firstOrNull;
      if (_existing != null) {
        _day = _existing!.day;
        _subjectId = _existing!.subjectId;
        _roomController.text = _existing!.room;
        _start = _parseTime(_existing!.startTime);
        _end = _parseTime(_existing!.endTime);
      }
    }
  }

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _subjectId == null) {
      if (_subjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a subject')));
      }
      return;
    }
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time must be after start time')));
      return;
    }

    final provider = context.read<TimetableProvider>();
    if (isEditing && _existing != null) {
      await provider.updateEntry(_existing!.copyWith(
        day: _day,
        subjectId: _subjectId,
        startTime: _formatTime(_start),
        endTime: _formatTime(_end),
        room: _roomController.text.trim(),
      ));
    } else {
      await provider.addEntry(
        day: _day,
        subjectId: _subjectId!,
        startTime: _formatTime(_start),
        endTime: _formatTime(_end),
        room: _roomController.text.trim(),
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Class' : 'Add Class')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  decoration: const InputDecoration(labelText: 'Subject', prefixIcon: Icon(Icons.menu_book_outlined)),
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<Weekday>(
                  initialValue: _day,
                  decoration: const InputDecoration(labelText: 'Day', prefixIcon: Icon(Icons.calendar_view_week_outlined)),
                  items: Weekday.values.map((d) => DropdownMenuItem(value: d, child: Text(d.label))).toList(),
                  onChanged: (v) => setState(() => _day = v!),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start time'),
                        subtitle: Text(_start.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: _start);
                          if (picked != null) setState(() => _start = picked);
                        },
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('End time'),
                        subtitle: Text(_end.format(context)),
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: _end);
                          if (picked != null) setState(() => _end = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(labelText: 'Room number (optional)', prefixIcon: Icon(Icons.room_outlined)),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _save, child: Text(isEditing ? 'Save changes' : 'Add class')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
