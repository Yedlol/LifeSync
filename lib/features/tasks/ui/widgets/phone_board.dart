import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/task_enums.dart';
import '../../providers/board_providers.dart';
import '../task_form.dart';
import 'column_header.dart';
import 'task_actions.dart';
import 'task_card.dart';
import 'task_card_menu.dart';
import 'task_tags.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/swipe_actions.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Phone: tab bar with counts + one swipeable page per column.
class PhoneBoard extends StatelessWidget {
  const PhoneBoard({super.key, required this.columns});
  final Map<TaskStatus, BoardColumnData> columns;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: TaskStatus.values.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final s in TaskStatus.values)
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.label),
                      const SizedBox(width: 6),
                      CountBadge(
                        count: columns[s]?.tasks.length ?? 0,
                        color: badgeColorFor(context, s),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final s in TaskStatus.values)
                  PhoneColumn(
                    status: s,
                    data: columns[s] ?? const BoardColumnData([]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Long-press + drag to reorder within the column.
class PhoneColumn extends ConsumerWidget {
  const PhoneColumn({super.key, required this.status, required this.data});
  final TaskStatus status;
  final BoardColumnData data;

  void _onReorder(BuildContext context, WidgetRef ref, int from, int to) {
    if (to > from) to -= 1;
    if (from == to) return;
    final task = data.tasks[from];
    final others = [...data.tasks]..removeAt(from);
    moveTask(
      context,
      ref,
      task,
      status,
      aboveId: to > 0 ? others[to - 1].id : null,
      belowId: to < others.length ? others[to].id : null,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = data.tasks;
    final footer = status == TaskStatus.done
        ? ShowAllDoneToggle(hiddenCount: data.hiddenOldDone)
        : null;

    if (tasks.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          EmptyState(
            icon: PhosphorIconsRegular.checkSquareOffset,
            message: 'Nothing in ${status.label} yet.',
            actionLabel: 'Add task',
            onAction: () => showTaskForm(
              context,
              initialStatus: status,
              initialProjectId: ref.read(taskFilterProvider).projectId,
            ),
          ),
          ?footer,
        ],
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      buildDefaultDragHandles: false,
      onReorderStart: (_) => hapticLight(),
      itemCount: tasks.length,
      footer: footer,
      onReorder: (from, to) => _onReorder(context, ref, from, to),
      itemBuilder: (context, i) =>
          _PhoneCard(key: ValueKey(tasks[i].id), index: i, task: tasks[i]),
    );
  }
}

class _PhoneCard extends ConsumerWidget {
  const _PhoneCard({super.key, required this.index, required this.task});
  final int index;
  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SwipeActions(
          actions: [
            SwipeAction(
              label: 'Move to',
              icon: PhosphorIconsRegular.arrowsLeftRight,
              color: Theme.of(context).colorScheme.primary,
              onPressed: () => showMoveToSheet(context, ref, task),
            ),
            SwipeAction(
              label: 'Delete',
              icon: PhosphorIconsRegular.trash,
              color: Theme.of(context).colorScheme.error,
              onPressed: () => confirmDeleteTask(context, ref, task),
            ),
          ],
          child: TaskCard(
            task: task,
            onTap: () => showTaskForm(context, task: task),
            trailing: TaskCardMenu(task: task),
          ),
        ),
      ),
    );
  }
}
