import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/subject_provider.dart';
import '../../models/subject.dart';
import '../../core/constants/app_constants.dart';

class AddEditSubjectScreen extends StatefulWidget {
  final String? subjectId;
  const AddEditSubjectScreen({super.key, this.subjectId});

  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _facultyController;
  double _target = AppDefaults.targetPercentage;
  int _colorValue = SubjectColors.options.first;
  String _icon = 'book';
  Subject? _existing;

  bool get isEditing => widget.subjectId != null;

  @override
  void initState() {
    super.initState();
    _existing = widget.subjectId == null
        ? null
        : context.read<SubjectProvider>().byId(widget.subjectId!);
    _nameController = TextEditingController(text: _existing?.name ?? '');
    _codeController = TextEditingController(text: _existing?.code ?? '');
    _facultyController = TextEditingController(text: _existing?.faculty ?? '');
    _target = _existing?.targetPercentage ?? AppDefaults.targetPercentage;
    _colorValue = _existing?.colorValue ?? SubjectColors.options.first;
    _icon = _existing?.icon ?? 'book';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<SubjectProvider>();
    if (isEditing && _existing != null) {
      await provider.updateSubject(_existing!.copyWith(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        faculty: _facultyController.text.trim(),
        targetPercentage: _target,
        colorValue: _colorValue,
        icon: _icon,
      ));
    } else {
      await provider.addSubject(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        faculty: _facultyController.text.trim(),
        targetPercentage: _target,
        colorValue: _colorValue,
        icon: _icon,
      );
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Subject' : 'Add Subject')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Subject name', prefixIcon: Icon(Icons.menu_book_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(labelText: 'Subject code (optional)', prefixIcon: Icon(Icons.tag)),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _facultyController,
                  decoration: const InputDecoration(labelText: 'Faculty name (optional)', prefixIcon: Icon(Icons.person_outline)),
                ),
                const SizedBox(height: 20),
                Text('Target attendance: ${_target.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                Slider(
                  value: _target,
                  min: 50,
                  max: 100,
                  divisions: 50,
                  label: '${_target.toStringAsFixed(0)}%',
                  onChanged: (v) => setState(() => _target = v),
                ),
                const SizedBox(height: 12),
                const Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: SubjectColors.options.map((c) {
                    final selected = c == _colorValue;
                    return GestureDetector(
                      onTap: () => setState(() => _colorValue = c),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: selected ? Border.all(color: Colors.black87, width: 2) : null,
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: SubjectIcons.options.entries.map((entry) {
                    final selected = entry.key == _icon;
                    return GestureDetector(
                      onTap: () => setState(() => _icon = entry.key),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? Color(_colorValue).withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: selected ? Border.all(color: Color(_colorValue), width: 1.5) : null,
                        ),
                        child: Icon(entry.value, color: selected ? Color(_colorValue) : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Save changes' : 'Add subject'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
