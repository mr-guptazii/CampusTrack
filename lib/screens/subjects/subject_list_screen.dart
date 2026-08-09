import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../widgets/subject_card.dart';

class SubjectListScreen extends StatelessWidget {
  const SubjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectProvider = context.watch<SubjectProvider>();
    final subjects = subjectProvider.subjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search subjects, code or faculty',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => context.read<SubjectProvider>().setSearchQuery(v),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/subjects/add'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<SubjectProvider>().syncWithRemote(),
        child: subjects.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  Icon(Icons.menu_book_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      subjectProvider.searchQuery.isEmpty ? 'No subjects yet.\nTap + to add your first subject.' : 'No matches found',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return SubjectCard(
                    subject: subject,
                    onTap: () => context.push('/attendance-history/${subject.id}'),
                    onEdit: () => context.push('/subjects/edit/${subject.id}'),
                    onDelete: () => _confirmDelete(context, subject.id, subject.name),
                  );
                },
              ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text('This will permanently remove "$name" and its attendance history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<SubjectProvider>().deleteSubject(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
