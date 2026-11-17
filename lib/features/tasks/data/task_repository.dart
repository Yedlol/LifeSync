import '../../../core/offline/cached_table.dart';
import '../../../core/offline/local_store.dart';
import '../../../core/supabase/supabase_config.dart';
import '../models/task.dart';
import '../models/task_enums.dart';

/// Tasks: reads come from the offline cache; writes go to the cache and the
/// outbox (synced by SyncService). Ids are generated on the client.
class TaskRepository {
  static const _table = Tables.tasks;
  static const _w = OfflineWriter(_table);

  static final cache = CachedTable<Task>(
    _table,
    Task.fromJson,
    compare: (a, b) {
      final c = a.position.compareTo(b.position);
      return c != 0 ? c : a.id.compareTo(b.id);
    },
  );

  String _now() => DateTime.now().toUtc().toIso8601String();

  /// Raw rows: initial fetch + realtime changes (written into the cache).
  Stream<List<Map<String, dynamic>>> watchRows() => supabaseClient
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('position', ascending: true);

  Task? cached(String id) {
    final r = _w.cached(id);
    return r == null ? null : Task.fromJson(r);
  }

  /// Uses [t.id] (TaskForm generates it up front for image uploads) or a
  /// new UUID.
  Future<Task> create(Task t) async => Task.fromJson(
    await _w.upsert(clientId(t.id), {...t.toJson(), 'updated_at': _now()}),
  );

  Future<Task> update(Task t) async =>
      Task.fromJson(await _w.upsert(t.id, {...t.toJson(), 'updated_at': _now()}));

  Future<void> delete(String id) => _w.delete(id);

  /// Moves a task to [newStatus] at [newPosition].
  /// [completedAt] should come from `Task.completedAtFor(newStatus)`.
  Future<void> move(
    String taskId,
    TaskStatus newStatus,
    double newPosition, {
    required DateTime? completedAt,
  }) async {
    final t = cached(taskId);
    if (t == null) throw StateError('Task $taskId is not cached');
    final moved = t.copyWith(
      status: newStatus,
      position: newPosition,
      completedAt: completedAt,
    );
    await _w.upsert(taskId, {...moved.toJson(), 'updated_at': _now()});
  }

  /// Bulk position update used when a column is renumbered.
  Future<void> setPositions(Map<String, double> positions) => Future.wait([
    for (final e in positions.entries)
      if (cached(e.key) case final t?)
        _w.upsert(e.key, t.copyWith(position: e.value).toJson()),
  ]);
}
