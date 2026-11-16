import '../../../core/supabase/supabase_config.dart';
import '../models/task.dart';
import '../models/task_enums.dart';

class TaskRepository {
  static const _table = 'tasks';

  String _now() => DateTime.now().toUtc().toIso8601String();

  /// Live list (initial fetch + realtime changes from other devices).
  Stream<List<Task>> watch() => supabaseClient
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('position', ascending: true)
      .map((rows) => rows.map(Task.fromJson).toList());

  Future<List<Task>> list() async {
    final rows = await supabaseClient
        .from(_table)
        .select()
        .order('position', ascending: true);
    return rows.map(Task.fromJson).toList();
  }

  Future<Task> create(Task t) async {
    final row = await supabaseClient
        .from(_table)
        .insert({if (t.id.isNotEmpty) 'id': t.id, ...t.toJson()})
        .select()
        .single();
    return Task.fromJson(row);
  }

  Future<Task> update(Task t) async {
    final row = await supabaseClient
        .from(_table)
        .update({...t.toJson(), 'updated_at': _now()})
        .eq('id', t.id)
        .select()
        .single();
    return Task.fromJson(row);
  }

  Future<void> delete(String id) =>
      supabaseClient.from(_table).delete().eq('id', id);

  /// Moves a task to [newStatus] at [newPosition].
  /// [completedAt] should come from `Task.completedAtFor(newStatus)`.
  Future<void> move(
    String taskId,
    TaskStatus newStatus,
    double newPosition, {
    required DateTime? completedAt,
  }) => supabaseClient
      .from(_table)
      .update({
        'status': newStatus.db,
        'position': newPosition,
        'completed_at': completedAt?.toUtc().toIso8601String(),
        'updated_at': _now(),
      })
      .eq('id', taskId);

  /// Bulk position update used when a column is renumbered.
  Future<void> setPositions(Map<String, double> positions) => Future.wait([
    for (final e in positions.entries)
      supabaseClient.from(_table).update({'position': e.value}).eq('id', e.key),
  ]);
}
