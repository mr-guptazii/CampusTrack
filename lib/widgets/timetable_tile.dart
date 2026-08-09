import 'package:flutter/material.dart';
import '../models/timetable_entry.dart';
import '../models/subject.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/date_utils.dart';

class TimetableTile extends StatelessWidget {
  final TimetableEntry entry;
  final Subject? subject;
  final bool isOngoing;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TimetableTile({
    super.key,
    required this.entry,
    required this.subject,
    this.isOngoing = false,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(subject?.colorValue ?? 0xFF2563EB);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: isOngoing ? color.withValues(alpha: 0.12) : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isOngoing ? BorderSide(color: color, width: 1.5) : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(
            SubjectIcons.options[subject?.icon] ?? Icons.menu_book_rounded,
            color: color,
          ),
        ),
        title: Text(
          subject?.name ?? 'Unknown subject',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${AppDateUtils.formatHHmm(entry.startTime)} - ${AppDateUtils.formatHHmm(entry.endTime)}'
          '${entry.room.isNotEmpty ? ' • Room ${entry.room}' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOngoing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
