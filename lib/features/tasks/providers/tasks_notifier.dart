import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/live_list_notifier.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/task_ordering.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (_) => TaskRepository(),
);

/// All tasks, live, with optimistic moves/deletes.
final tasksProvider = NotifierProvider<TasksNotifier, AsyncValue<List<Task>>>(
  TasksNotifier.new,
);

class TasksNotifier extends LiveListNotifier<Task> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  AsyncValue<List<Task>> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    return startLive();
  }

  @override
  Stream<List<Task>> watchSource() => _repo.watch();

  @override
  String idOf(Task item) => item.id;

  /// Full column sorted by position, optionally excluding one task.
  List<Task> column(TaskStatus status, {String? excludeId}) =>
      items.where((t) => t.status == status && t.id != excludeId).toList()
        ..sort((a, b) => a.position.compareTo(b.position));

  double _topOf(TaskStatus status, {String? excludeId}) =>
      topPosition(column(status, excludeId: excludeId).map((t) => t.position));

  /// Creates a task at the top of its column.
  Future<void> create(Task draft) async {
    final t = draft.copyWith(
      position: _topOf(draft.status),
      completedAt: draft.isDone ? DateTime.now() : null,
    );
    final saved = await _repo.create(t);
    if (ref.mounted) upsertLocal(saved);
  }

  /// Saves edits. If the status changed, the task goes to the top of the
  /// new column and completed_at follows the done rule.
  Future<void> save(Task original, Task edited) async {
    var t = edited;
    if (edited.status != original.status) {
      t = t.copyWith(
        position: _topOf(edited.status, excludeId: edited.id),
        completedAt: original.completedAtFor(edited.status),
      );
    }
    final saved = await _repo.update(t);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> delete(Task t) =>
      optimistic(removed: {t.id}, save: () => _repo.delete(t.id));

  /// Drag & drop: move [task] into [to], between [aboveId] and [belowId]
  /// (ids of the visible neighbours; null = top/bottom).
  Future<void> move(
    Task task,
    TaskStatus to, {
    String? aboveId,
    String? belowId,
  }) {
    final target = column(to, excludeId: task.id);
    final plan = planMove(
      column: [for (final t in target) (t.id, t.position)],
      movingId: task.id,
      aboveId: aboveId,
      belowId: belowId,
    );
    final moved = task.copyWith(
      status: to,
      position: plan.position,
      completedAt: task.completedAtFor(to),
    );
    final renumbered = [
      for (final t in target)
        if (plan.renumbered.containsKey(t.id))
          t.copyWith(position: plan.renumbered[t.id]),
    ];
    return optimistic(
      changed: [moved, ...renumbered],
      save: () async {
        if (plan.renumbered.isNotEmpty) {
          await _repo.setPositions(plan.renumbered);
        }
        await _repo.move(
          task.id,
          to,
          plan.position,
          completedAt: moved.completedAt,
        );
      },
    );
  }

  /// Menu "Move to": top of the target column.
  Future<void> moveToTop(Task task, TaskStatus to) {
    if (task.status == to) return Future.value();
    final first = column(to, excludeId: task.id).firstOrNull;
    return move(task, to, belowId: first?.id);
  }
}
