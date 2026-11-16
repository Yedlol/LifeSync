import '../../../../core/supabase/supabase_config.dart';
import '../models/saving_entry.dart';
import '../models/savings_goal.dart';

class SavingsRepository {
  static const _goals = 'savings_goals';
  static const _entries = 'saving_entries';

  /// Live lists (initial fetch + realtime changes from other devices).
  Stream<List<SavingsGoal>> watchGoals() => supabaseClient
      .from(_goals)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((rows) => rows.map(SavingsGoal.fromJson).toList());

  Stream<List<SavingEntry>> watchEntries() => supabaseClient
      .from(_entries)
      .stream(primaryKey: ['id'])
      .map((rows) => rows.map(SavingEntry.fromJson).toList());

  Future<SavingsGoal> createGoal(SavingsGoal g) async {
    final row = await supabaseClient
        .from(_goals)
        .insert(g.toJson())
        .select()
        .single();
    return SavingsGoal.fromJson(row);
  }

  Future<SavingsGoal> updateGoal(SavingsGoal g) async {
    final row = await supabaseClient
        .from(_goals)
        .update(g.toJson())
        .eq('id', g.id)
        .select()
        .single();
    return SavingsGoal.fromJson(row);
  }

  /// Deletes the goal and, explicitly, its entry history.
  Future<void> deleteGoal(String id) async {
    await supabaseClient.from(_entries).delete().eq('goal_id', id);
    await supabaseClient.from(_goals).delete().eq('id', id);
  }

  Future<SavingEntry> addEntry(SavingEntry e) async {
    final row = await supabaseClient
        .from(_entries)
        .insert(e.toJson())
        .select()
        .single();
    return SavingEntry.fromJson(row);
  }

  Future<SavingEntry> updateEntry(SavingEntry e) async {
    final row = await supabaseClient
        .from(_entries)
        .update(e.toJson())
        .eq('id', e.id)
        .select()
        .single();
    return SavingEntry.fromJson(row);
  }

  Future<void> deleteEntry(String id) =>
      supabaseClient.from(_entries).delete().eq('id', id);
}
