import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/widgets/responsive_dialog.dart';
import '../models/description_codec.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../providers/tasks_notifier.dart';
import 'widgets/due_date_field.dart';
import 'widgets/project_dropdown.dart';

/// Opens the task form: dialog on desktop, full-screen page on phone.
/// [task] null = create.
Future<void> showTaskForm(
  BuildContext context, {
  Task? task,
  TaskStatus? initialStatus,
  String? initialProjectId,
}) => showResponsiveDialog(
  context,
  title: task == null ? 'New task' : 'Edit task',
  builder: (_) => TaskForm(
    task: task,
    initialStatus: initialStatus,
    initialProjectId: initialProjectId,
  ),
);

class TaskForm extends ConsumerStatefulWidget {
  const TaskForm({
    super.key,
    this.task,
    this.initialStatus,
    this.initialProjectId,
  });
  final Task? task;
  final TaskStatus? initialStatus;
  final String? initialProjectId;

  @override
  ConsumerState<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<TaskForm> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title ?? '');
  late final _desc = TextEditingController(
    text: widget.task?.descriptionText ?? '',
  );
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late TaskStatus _status =
      widget.task?.status ?? widget.initialStatus ?? TaskStatus.open;
  late String? _projectId = widget.task?.projectId ?? widget.initialProjectId;
  late DateTime? _dueAt = widget.task?.dueAt?.toLocal();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(tasksProvider.notifier);
    final original = widget.task;
    final draft = (original ?? const Task(id: '', title: '')).copyWith(
      title: _title.text.trim(),
      description: plainTextToDelta(_desc.text),
      priority: _priority,
      status: _status,
      projectId: _projectId,
      dueAt: _dueAt == null ? null : endOfDay(_dueAt!),
    );
    try {
      if (original == null) {
        await notifier.create(draft);
      } else {
        await notifier.save(original, draft);
      }
      navigator.pop();
    } catch (e) {
      debugPrint('save task failed: $e');
      if (mounted) setState(() => _saving = false);
      showSnack(messenger, 'Could not save task. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Form(
      key: _form,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          TextFormField(
            controller: _title,
            autofocus: widget.task == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Title *'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          gap,
          TextFormField(
            controller: _desc,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          gap,
          Text('Priority', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<TaskPriority>(
            showSelectedIcon: false,
            segments: [
              for (final p in TaskPriority.values)
                ButtonSegment(value: p, label: Text(p.label)),
            ],
            selected: {_priority},
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          gap,
          ProjectDropdown(
            value: _projectId,
            onChanged: (id) => setState(() => _projectId = id),
          ),
          gap,
          DropdownButtonFormField<TaskStatus>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              for (final s in TaskStatus.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (s) => setState(() => _status = s ?? _status),
          ),
          gap,
          DueDateField(
            value: _dueAt,
            onChanged: (d) => setState(() => _dueAt = d),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.task == null ? 'Create task' : 'Save'),
          ),
        ],
      ),
    );
  }
}
