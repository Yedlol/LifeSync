import '../../../core/supabase/supabase_config.dart';
import '../models/project.dart';

class ProjectRepository {
  static const _table = 'projects';

  /// Live list (initial fetch + realtime changes from other devices).
  Stream<List<Project>> watch() => supabaseClient
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((rows) => rows.map(Project.fromJson).toList());

  Future<List<Project>> list() async {
    final rows = await supabaseClient
        .from(_table)
        .select()
        .order('created_at', ascending: true);
    return rows.map(Project.fromJson).toList();
  }

  Future<Project> create({required String name, required String color}) async {
    final row = await supabaseClient
        .from(_table)
        .insert({'name': name, 'color': color})
        .select()
        .single();
    return Project.fromJson(row);
  }

  Future<Project> update(Project p) async {
    final row = await supabaseClient
        .from(_table)
        .update(p.toJson())
        .eq('id', p.id)
        .select()
        .single();
    return Project.fromJson(row);
  }

  Future<Project> archive(String id, {bool archived = true}) async {
    final row = await supabaseClient
        .from(_table)
        .update({'is_archived': archived})
        .eq('id', id)
        .select()
        .single();
    return Project.fromJson(row);
  }
}
