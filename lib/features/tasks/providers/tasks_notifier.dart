import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/live_list_notifier.dart';
import '../../../core/offline/cached_table.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/task_image_repository.dart';
import '../data/task_repository.dart';
import '../models/task.dart';
import '../models/task_enums.dart';
import '../models/task_ordering.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (_) => TaskRepository(),
);

final taskImageRepositoryProvider = Provider<TaskImageRepository>(
  (_) => TaskImageRepository(),
);

/// All tasks from the offline cache (kept live by Supabase realtime).
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
  CachedTable<Task> get table => TaskRepository.cache;

  @override
  Stream<List<Map<String, dynamic>>> watchRows() => _repo.watchRows();

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
    await _repo.create(t);
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
    await _repo.update(t);
  }

  /// Queues removal of the task's Storage images first, then the task itself.
  Future<void> delete(Task t) async {
    await ref.read(taskImageRepositoryProvider).deleteAllForTask(t.id);
    await _repo.delete(t.id);
  }

  /// Drag & drop: move [task] into [to], between [aboveId] and [belowId]
  /// (ids of the visible neighbours; null = top/bottom).
  Future<void> move(
    Task task,
    TaskStatus to, {
    String? aboveId,
    String? belowId,
  }) async {
    final target = column(to, excludeId: task.id);
    final plan = planMove(
      column: [for (final t in target) (t.id, t.position)],
      movingId: task.id,
      aboveId: aboveId,
      belowId: belowId,
    );
    // Started together so the whole move lands in one frame.
    await Future.wait([
      if (plan.renumbered.isNotEmpty) _repo.setPositions(plan.renumbered),
      _repo.move(
        task.id,
        to,
        plan.position,
        completedAt: task.completedAtFor(to),
      ),
    ]);
  }

  /// Menu "Move to": top of the target column.
  Future<void> moveToTop(Task task, TaskStatus to) {
    if (task.status == to) return Future.value();
    final first = column(to, excludeId: task.id).firstOrNull;
    return move(task, to, belowId: first?.id);
  }
}
