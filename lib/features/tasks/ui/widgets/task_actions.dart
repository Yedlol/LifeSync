import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/responsive_dialog.dart';
import '../../models/task.dart';
import '../../models/task_enums.dart';
import '../../providers/tasks_notifier.dart';

/// UI-side task actions: confirm dialogs + error SnackBars.

Future<void> confirmDeleteTask(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final notifier = ref.read(tasksProvider.notifier);
  final ok = await confirmDialog(
    context,
    title: 'Delete task?',
    message: '"${task.title}" will be permanently deleted.',
  );
  if (!ok) return;
  try {
    await notifier.delete(task);
  } catch (e) {
    debugPrint('delete failed: $e');
    showSnack(messenger, 'Could not delete task. It has been restored.');
  }
}

/// Drag & drop move (optimistic; reverts + SnackBar on failure).
Future<void> moveTask(
  BuildContext context,
  WidgetRef ref,
  Task task,
  TaskStatus to, {
  String? aboveId,
  String? belowId,
}) => _run(
  context,
  () => ref
      .read(tasksProvider.notifier)
      .move(task, to, aboveId: aboveId, belowId: belowId),
);

/// Menu "Move to …" (top of the target column).
Future<void> moveTaskToTop(
  BuildContext context,
  WidgetRef ref,
  Task task,
  TaskStatus to,
) => _run(context, () => ref.read(tasksProvider.notifier).moveToTop(task, to));

Future<void> _run(BuildContext context, Future<void> Function() action) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
  } catch (e) {
    debugPrint('move failed: $e');
    showSnack(messenger, "Couldn't move task — change reverted.");
  }
}

/// Delete icon used on desktop cards.
class DeleteTaskButton extends ConsumerWidget {
  const DeleteTaskButton({super.key, required this.task});
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: 'Delete',
    visualDensity: VisualDensity.compact,
    iconSize: 18,
    color: Colors.grey.shade600,
    icon: const Icon(Icons.delete_outline),
    onPressed: () => confirmDeleteTask(context, ref, task),
  );
}
