import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/subject_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../repositories/firebase_repository.dart';
import '../../repositories/local_repository.dart';
import '../../models/attendance_record.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBusy = false;

  Future<void> _exportCsv(BuildContext context) async {
    setState(() => _isBusy = true);
    try {
      final subjectProvider = context.read<SubjectProvider>();
      final attendanceProvider = context.read<AttendanceProvider>();

      final rows = <List<dynamic>>[
        ['Subject', 'Date', 'Status', 'Percentage'],
      ];
      for (final record in attendanceProvider.records) {
        final subject = subjectProvider.byId(record.subjectId);
        rows.add([
          subject?.name ?? 'Unknown',
          AppDateUtils.iso(record.date),
          record.status.label,
          subject != null ? '${subject.percentage.toStringAsFixed(1)}%' : '-',
        ]);
      }
      final csv = const ListToCsvConverter().convert(rows);

      Directory dir;
      try {
        dir = (await getExternalStorageDirectory())!;
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final file = File('${dir.path}/campustrack_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _backupToFirebase(BuildContext context) async {
    setState(() => _isBusy = true);
    try {
      final auth = context.read<AuthProvider>();
      final uid = auth.currentUser?.uid;
      if (uid == null) return;
      await FirebaseRepository.instance.backupAll(
        uid: uid,
        subjects: context.read<SubjectProvider>().subjects,
        attendance: context.read<AttendanceProvider>().records,
        timetable: context.read<TimetableProvider>().entries,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup complete')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset all attendance data?'),
        content: const Text('This permanently deletes all attendance records on this device. Subjects and timetable are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalRepository.instance.clearAttendance();
              if (!context.mounted) return;
              await context.read<AttendanceProvider>().init();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance data reset')));
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
              ),
              title: Text(user?.displayName ?? 'Student'),
              subtitle: Text(user?.email ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profile'),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Default target attendance'),
                  subtitle: Text('${user?.defaultTargetPercentage.toStringAsFixed(0) ?? '75'}%'),
                  trailing: SizedBox(
                    width: 160,
                    child: Slider(
                      value: user?.defaultTargetPercentage ?? AppDefaults.targetPercentage,
                      min: 50,
                      max: 100,
                      divisions: 50,
                      onChanged: (v) => context.read<AuthProvider>().updateTargetPercentage(v),
                    ),
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  subtitle: const Text('Class reminders, daily nudge & low-attendance warnings'),
                  value: user?.notificationsEnabled ?? true,
                  onChanged: (v) async {
                    await context.read<AuthProvider>().updateNotificationsEnabled(v);
                    if (v) {
                      await NotificationService.instance.scheduleDailyReminder();
                    } else {
                      await NotificationService.instance.cancelAllReminders();
                    }
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: user?.darkModeEnabled ?? false,
                  onChanged: (v) => context.read<AuthProvider>().updateDarkMode(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Data'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined),
                  title: const Text('Backup to Firebase'),
                  trailing: _isBusy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
                  onTap: _isBusy ? null : () => _backupToFirebase(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export data (CSV)'),
                  trailing: _isBusy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right),
                  onTap: _isBusy ? null : () => _exportCsv(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_outlined, color: AppColors.danger),
                  title: const Text('Reset all attendance data', style: TextStyle(color: AppColors.danger)),
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
              onTap: () => context.read<AuthProvider>().signOut(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
