import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/task_enums.dart';
import '../task_form.dart';
import 'task_actions.dart';

/// ⋮ menu on phone cards: Move to → (other columns), Edit, Delete.
class TaskCardMenu extends ConsumerWidget {
  const TaskCardMenu({super.key, required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<Object>(
      tooltip: 'Task actions',
      icon: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade700),
      padding: EdgeInsets.zero,
      onSelected: (v) {
        if (v is TaskStatus) {
          moveTaskToTop(context, ref, task, v);
        } else if (v == 'edit') {
          showTaskForm(context, task: task);
        } else if (v == 'delete') {
          confirmDeleteTask(context, ref, task);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          enabled: false,
          height: 32,
          child: Text('Move to', style: TextStyle(fontSize: 12)),
        ),
        for (final s in TaskStatus.values)
          PopupMenuItem(
            value: s,
            enabled: s != task.status,
            child: Row(
              children: [
                Icon(
                  s == task.status ? Icons.check : Icons.arrow_forward,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(s.label),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
