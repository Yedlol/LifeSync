import '../../../../core/supabase/supabase_config.dart';
import '../models/income_entry.dart';

class IncomeRepository {
  static const _table = 'income_entries';

  /// Live list (initial fetch + realtime changes from other devices).
  Stream<List<IncomeEntry>> watchEntries() => supabaseClient
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('entry_date', ascending: false)
      .map((rows) => rows.map(IncomeEntry.fromJson).toList());

  Future<IncomeEntry> create(IncomeEntry e) async {
    final row = await supabaseClient
        .from(_table)
        .insert(e.toJson())
        .select()
        .single();
    return IncomeEntry.fromJson(row);
  }

  Future<IncomeEntry> update(IncomeEntry e) async {
    final row = await supabaseClient
        .from(_table)
        .update(e.toJson())
        .eq('id', e.id)
        .select()
        .single();
    return IncomeEntry.fromJson(row);
  }

  Future<void> delete(String id) =>
      supabaseClient.from(_table).delete().eq('id', id);
}
