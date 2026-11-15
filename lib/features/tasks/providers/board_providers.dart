import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/task.dart';
import '../models/task_enums.dart';
import 'tasks_notifier.dart';

class TaskFilter {
  const TaskFilter({
    this.projectId,
    this.priorities = const {},
    this.query = '',
  });

  /// null = all projects.
  final String? projectId;

  /// Empty = all priorities.
  final Set<TaskPriority> priorities;
  final String query;

  bool matches(Task t) {
    if (projectId != null && t.projectId != projectId) return false;
    if (priorities.isNotEmpty && !priorities.contains(t.priority)) return false;
    final q = query.trim().toLowerCase();
    return q.isEmpty || t.title.toLowerCase().contains(q);
  }
}

final taskFilterProvider = NotifierProvider<TaskFilterNotifier, TaskFilter>(
  TaskFilterNotifier.new,
);

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => const TaskFilter();

  void setProject(String? id) => state = TaskFilter(
    projectId: id,
    priorities: state.priorities,
    query: state.query,
  );

  void togglePriority(TaskPriority p) {
    final set = {...state.priorities};
    set.contains(p) ? set.remove(p) : set.add(p);
    state = TaskFilter(
      projectId: state.projectId,
      priorities: set,
      query: state.query,
    );
  }

  void setQuery(String q) => state = TaskFilter(
    projectId: state.projectId,
    priorities: state.priorities,
    query: q,
  );
}

/// Done column shows only the last 30 days unless this is on.
final showAllDoneProvider = NotifierProvider<ShowAllDoneNotifier, bool>(
  ShowAllDoneNotifier.new,
);

class ShowAllDoneNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

const kDoneWindow = Duration(days: 30);

class BoardColumnData {
  const BoardColumnData(this.tasks, {this.hiddenOldDone = 0});
  final List<Task> tasks;

  /// Done tasks hidden by the 30-day window (0 for other columns).
  final int hiddenOldDone;
}

/// Filtered, sorted tasks per column.
final boardProvider = Provider<AsyncValue<Map<TaskStatus, BoardColumnData>>>((
  ref,
) {
  final async = ref.watch(tasksProvider);
  final filter = ref.watch(taskFilterProvider);
  final showAll = ref.watch(showAllDoneProvider);
  return async.whenData((all) {
    final cutoff = DateTime.now().subtract(kDoneWindow);
    final result = <TaskStatus, BoardColumnData>{};
    for (final status in TaskStatus.values) {
      final col =
          all.where((t) => t.status == status && filter.matches(t)).toList()
            ..sort((a, b) => a.position.compareTo(b.position));
      if (status != TaskStatus.done || showAll) {
        result[status] = BoardColumnData(col);
        continue;
      }
      final recent = col.where((t) {
        final when = t.completedAt ?? t.updatedAt;
        return when == null || when.isAfter(cutoff);
      }).toList();
      result[status] = BoardColumnData(
        recent,
        hiddenOldDone: col.length - recent.length,
      );
    }
    return result;
  });
});
