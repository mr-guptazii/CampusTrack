import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../core/constants/app_constants.dart';

/// Row of 4 quick-mark buttons: Present / Absent / Cancelled / Extra.
class AttendanceButtonGroup extends StatelessWidget {
  final AttendanceStatus? selected;
  final ValueChanged<AttendanceStatus> onSelect;

  const AttendanceButtonGroup({super.key, this.selected, required this.onSelect});

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

  IconData _iconFor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.absent:
        return Icons.cancel_rounded;
      case AttendanceStatus.cancelled:
        return Icons.block_rounded;
      case AttendanceStatus.extra:
        return Icons.add_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AttendanceStatus.values.map((status) {
        final isSelected = selected == status;
        final color = _colorFor(status);
        return ChoiceChip(
          label: Text(status.label),
          avatar: Icon(_iconFor(status), size: 18, color: isSelected ? Colors.white : color),
          selected: isSelected,
          onSelected: (_) => onSelect(status),
          selectedColor: color,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.4)),
        );
      }).toList(),
    );
  }
}
