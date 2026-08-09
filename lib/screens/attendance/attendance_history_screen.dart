import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance_record.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/bunk_calculator.dart';
import '../../widgets/attendance_button.dart';
import '../../widgets/percentage_indicator.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final String subjectId;
  const AttendanceHistoryScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context) {
    final subject = context.watch<SubjectProvider>().byId(subjectId);
    final attendanceProvider = context.watch<AttendanceProvider>();
    final records = attendanceProvider.forSubject(subjectId);

    if (subject == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subject')),
        body: const Center(child: Text('Subject not found')),
      );
    }

    final canMiss = BunkCalculator.classesCanMiss(subject.attended, subject.total, subject.targetPercentage);
    final needed = BunkCalculator.classesNeededToReach(subject.attended, subject.total, subject.targetPercentage);

    return Scaffold(
      appBar: AppBar(title: Text(subject.name)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMarkDialog(context, subjectId),
        icon: const Icon(Icons.add),
        label: const Text('Mark class'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  PercentageIndicator(percentage: subject.percentage, target: subject.targetPercentage, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${subject.attended} attended / ${subject.total} classes', style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          subject.isBelowTarget
                              ? (needed > 0 ? 'Attend $needed more class${needed == 1 ? '' : 'es'} in a row to reach ${subject.targetPercentage.toStringAsFixed(0)}%' : 'On track')
                              : (canMiss > (1 << 20) ? 'Set a target to see how many you can miss' : 'You can miss $canMiss more class${canMiss == 1 ? '' : 'es'}'),
                          style: TextStyle(color: subject.isBelowTarget ? AppColors.warning : AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No records yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
            )
          else
            ...records.map((r) => _RecordTile(record: r)),
        ],
      ),
    );
  }

  void _showMarkDialog(BuildContext context, String subjectId) {
    DateTime selectedDate = DateTime.now();
    AttendanceStatus? status;
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mark class', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(AppDateUtils.dayMonthYear(selectedDate)),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  AttendanceButtonGroup(selected: status, onSelect: (s) => setState(() => status = s)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note (optional)'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: status == null
                          ? null
                          : () async {
                              await context.read<AttendanceProvider>().markAttendance(
                                    subjectId: subjectId,
                                    date: selectedDate,
                                    status: status!,
                                    note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                                  );
                              if (context.mounted) Navigator.pop(context);
                            },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _RecordTile extends StatelessWidget {
  final AttendanceRecord record;
  const _RecordTile({required this.record});

  Color _color(AttendanceStatus s) {
    switch (s) {
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
    final color = _color(record.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.circle, color: color, size: 12)),
        title: Text(AppDateUtils.dayMonthYear(record.date)),
        subtitle: record.note != null ? Text(record.note!) : null,
        trailing: Chip(
          label: Text(record.status.label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide.none,
        ),
        onLongPress: () => context.read<AttendanceProvider>().deleteRecord(record.id),
      ),
    );
  }
}
