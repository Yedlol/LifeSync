import '../../../core/offline/cached_table.dart';
import '../../../core/offline/local_store.dart';
import '../../../core/supabase/supabase_config.dart';
import '../models/project.dart';

/// Projects: cache-first reads, writes via cache + outbox.
class ProjectRepository {
  static const _table = Tables.projects;
  static const _w = OfflineWriter(_table);

  static final cache = CachedTable<Project>(
    _table,
    Project.fromJson,
    compare: (a, b) {
      final c = compareNullable(a.createdAt, b.createdAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    },
  );

  /// Raw rows: initial fetch + realtime changes (written into the cache).
  Stream<List<Map<String, dynamic>>> watchRows() => supabaseClient
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true);

  Future<Project> create({required String name, required String color}) async {
    final p = Project(id: clientId(), name: name, color: color);
    return Project.fromJson(await _w.upsert(p.id, p.toJson()));
  }

  Future<Project> update(Project p) async =>
      Project.fromJson(await _w.upsert(p.id, p.toJson()));

  Future<Project> archive(String id, {bool archived = true}) async {
    final row = _w.cached(id);
    if (row == null) throw StateError('Project $id is not cached');
    final p = Project.fromJson(row).copyWith(isArchived: archived);
    return Project.fromJson(await _w.upsert(id, p.toJson()));
  }
}
