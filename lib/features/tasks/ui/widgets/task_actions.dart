import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/responsive_dialog.dart';
import '../../models/task.dart';
import '../../models/task_enums.dart';
import '../../providers/tasks_notifier.dart';
import '../../../../core/utils/haptics.dart';

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
}) {
  hapticSuccess();
  return _run(
    context,
    () => ref
        .read(tasksProvider.notifier)
        .move(task, to, aboveId: aboveId, belowId: belowId),
  );
}

/// Menu "Move to …" (top of the target column).
Future<void> moveTaskToTop(
  BuildContext context,
  WidgetRef ref,
  Task task,
  TaskStatus to,
) => _run(context, () => ref.read(tasksProvider.notifier).moveToTop(task, to));

/// Swipe action "Move to": pick a column from a bottom sheet.
Future<void> showMoveToSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final to = await showModalBottomSheet<TaskStatus>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Move to',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
          ),
          for (final s in TaskStatus.values)
            ListTile(
              enabled: s != task.status,
              leading: Icon(
                s == task.status
                    ? PhosphorIconsRegular.check
                    : PhosphorIconsRegular.arrowRight,
              ),
              title: Text(s.label),
              onTap: () => Navigator.of(ctx).pop(s),
            ),
        ],
      ),
    ),
  );
  if (to != null && context.mounted) moveTaskToTop(context, ref, task, to);
}

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
    icon: const Icon(PhosphorIconsRegular.trash),
    onPressed: () => confirmDeleteTask(context, ref, task),
  );
}
