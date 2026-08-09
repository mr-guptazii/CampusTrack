import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/timetable_provider.dart';
import '../../providers/subject_provider.dart';
import '../../core/utils/date_utils.dart';
import '../../widgets/timetable_tile.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final todayIndex = WeekdayX.fromDateTime(DateTime.now()).index;
    _tabController = TabController(length: 7, vsync: this, initialIndex: todayIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetableProvider = context.watch<TimetableProvider>();
    final subjectProvider = context.watch<SubjectProvider>();
    final ongoing = timetableProvider.currentOngoing();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: Weekday.values.map((d) => Tab(text: d.short)).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/timetable/add'),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: Weekday.values.map((day) {
          final entries = timetableProvider.forDay(day);
          if (entries.isEmpty) {
            return Center(
              child: Text('No classes on ${day.label}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return TimetableTile(
                entry: entry,
                subject: subjectProvider.byId(entry.subjectId),
                isOngoing: ongoing?.id == entry.id,
                onTap: () => context.push('/timetable/edit/${entry.id}'),
                onDelete: () => context.read<TimetableProvider>().deleteEntry(entry.id),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
