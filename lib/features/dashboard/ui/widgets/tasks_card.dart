import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../projects/providers/project_providers.dart';
import '../../../tasks/models/task.dart';
import '../../../tasks/models/task_enums.dart';
import '../../../tasks/providers/tasks_notifier.dart';
import '../../../tasks/ui/task_form.dart';
import '../../../tasks/ui/widgets/task_tags.dart';
import '../../models/attention.dart';
import 'dash_card.dart';

/// Open / In Progress / On Hold counts + the tasks that need attention.
class TasksCard extends ConsumerWidget {
  const TasksCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksProvider);
    return DashCard(
      title: 'Tasks',
      icon: PhosphorIconsRegular.kanban,
      footerLabel: 'View board',
      onFooter: () => context.go('/tasks'),
      child: async.when(
        skipLoadingOnReload: true,
        loading: () => const CardSkeleton(lines: 4),
        error: (_, _) => const CardMessage("Couldn't load tasks."),
        data: (tasks) => _Body(tasks: tasks),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.tasks});
  final List<Task> tasks;

  int _count(TaskStatus s) => tasks.where((t) => t.status == s).length;

  @override
  Widget build(BuildContext context) {
    final open = _count(TaskStatus.open);
    final doing = _count(TaskStatus.inProgress);
    final hold = _count(TaskStatus.onHold);
    if (open + doing + hold == 0) {
      return EmptyState(
        compact: true,
        icon: PhosphorIconsRegular.checkSquareOffset,
        message: 'No active tasks. A clear desk!',
        actionLabel: 'New task',
        onAction: () => showTaskForm(context),
      );
    }
    final items = attentionTasks(tasks, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: Sp.sm,
          runSpacing: Sp.sm,
          children: [
            _CountChip('Open', open),
            _CountChip('In Progress', doing),
            _CountChip('On Hold', hold),
          ],
        ),
        const SizedBox(height: Sp.lg),
        Text('Needs attention', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Sp.sm),
        if (items.isEmpty)
          const CardMessage('Nothing urgent right now. Nice and calm.')
        else
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: Sp.sm),
              child: _AttentionRow(item: item),
            ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.label, this.count);
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Sp.md, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$count ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
            TextSpan(text: label),
          ],
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _AttentionRow extends ConsumerWidget {
  const _AttentionRow({required this.item});
  final AttentionItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = item.task;
    final project = task.projectId == null
        ? null
        : ref.watch(projectMapProvider)[task.projectId];
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => showTaskForm(context, task: task),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: task.priority.color, width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(Sp.md, Sp.xs, Sp.xs, Sp.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Wrap(
                spacing: 6,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (project != null)
                    TaskTag(label: project.name, color: project.colorValue),
                  Text(
                    item.dueText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.kind == AttentionKind.soon
                          ? scheme.onSurfaceVariant
                          : item.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
