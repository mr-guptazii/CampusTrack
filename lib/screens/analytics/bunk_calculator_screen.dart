import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../models/subject.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/bunk_calculator.dart';
import '../../widgets/percentage_indicator.dart';

class BunkCalculatorScreen extends StatefulWidget {
  const BunkCalculatorScreen({super.key});

  @override
  State<BunkCalculatorScreen> createState() => _BunkCalculatorScreenState();
}

class _BunkCalculatorScreenState extends State<BunkCalculatorScreen> {
  String? _subjectId;
  double _target = AppDefaults.targetPercentage;

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectProvider>().subjects;
    Subject? subject;
    if (_subjectId != null) {
      subject = subjects.where((s) => s.id == _subjectId).firstOrNull;
    } else if (subjects.isNotEmpty) {
      subject = subjects.first;
      _subjectId = subject.id;
    }
    if (subject != null && subject.targetPercentage != _target && _subjectId == subject.id && !_userChangedTarget) {
      _target = subject.targetPercentage;
    }

    final canMiss = subject == null ? 0 : BunkCalculator.classesCanMiss(subject.attended, subject.total, _target);
    final needed = subject == null ? 0 : BunkCalculator.classesNeededToReach(subject.attended, subject.total, _target);
    final currentPct = subject == null ? 0.0 : subject.percentage;
    final isBelow = currentPct < _target;

    return Scaffold(
      appBar: AppBar(title: const Text('Bunk Calculator')),
      body: subjects.isEmpty
          ? const Center(child: Text('Add a subject first to use the calculator'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _subjectId,
                    decoration: const InputDecoration(labelText: 'Select subject', prefixIcon: Icon(Icons.menu_book_outlined)),
                    items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) => setState(() {
                      _subjectId = v;
                      _userChangedTarget = false;
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text('Target attendance: ${_target.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _target,
                    min: 50,
                    max: 100,
                    divisions: 50,
                    label: '${_target.toStringAsFixed(0)}%',
                    onChanged: (v) => setState(() {
                      _target = v;
                      _userChangedTarget = true;
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (subject != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            PercentageIndicator(percentage: currentPct, target: _target, size: 96, strokeWidth: 8),
                            const SizedBox(height: 12),
                            Text('${subject.attended} attended out of ${subject.total} classes', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (currentPct / 100).clamp(0, 1),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(8),
                              backgroundColor: (isBelow ? AppColors.warning : AppColors.success).withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(isBelow ? AppColors.warning : AppColors.success),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text('Target: ${_target.toStringAsFixed(0)}%', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: (isBelow ? AppColors.warning : AppColors.success).withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Icon(isBelow ? Icons.warning_amber_rounded : Icons.emoji_events_outlined, color: isBelow ? AppColors.warning : AppColors.success, size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                isBelow
                                    ? (needed > 0
                                        ? 'Attend $needed consecutive class${needed == 1 ? '' : 'es'} to reach ${_target.toStringAsFixed(0)}%'
                                        : 'You are right at your target!')
                                    : 'You can miss $canMiss more class${canMiss == 1 ? '' : 'es'} and stay at or above ${_target.toStringAsFixed(0)}%',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  bool _userChangedTarget = false;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
