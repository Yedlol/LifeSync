import '../../../../core/offline/cached_table.dart';
import '../../../../core/offline/local_store.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../models/saving_entry.dart';
import '../models/savings_goal.dart';

/// Savings goals + entries: cache-first reads, writes via cache + outbox.
class SavingsRepository {
  static const _goals = Tables.savingsGoals;
  static const _entries = Tables.savingEntries;
  static const _wg = OfflineWriter(_goals);
  static const _we = OfflineWriter(_entries);

  static final goalCache = CachedTable<SavingsGoal>(
    _goals,
    SavingsGoal.fromJson,
    compare: (a, b) {
      final c = compareNullable(a.createdAt, b.createdAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    },
  );
  static final entryCache = CachedTable<SavingEntry>(
    _entries,
    SavingEntry.fromJson,
  );

  /// Raw rows: initial fetch + realtime changes (written into the cache).
  Stream<List<Map<String, dynamic>>> watchGoalRows() => supabaseClient
      .from(_goals)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true);

  Stream<List<Map<String, dynamic>>> watchEntryRows() =>
      supabaseClient.from(_entries).stream(primaryKey: ['id']);

  Future<SavingsGoal> createGoal(SavingsGoal g) async =>
      SavingsGoal.fromJson(await _wg.upsert(clientId(g.id), g.toJson()));

  Future<SavingsGoal> updateGoal(SavingsGoal g) async =>
      SavingsGoal.fromJson(await _wg.upsert(g.id, g.toJson()));

  /// Deletes the goal and, explicitly, its entry history.
  Future<void> deleteGoal(String id) async {
    await _we.deleteWhere({'goal_id': id});
    await _wg.delete(id);
  }

  Future<SavingEntry> addEntry(SavingEntry e) async =>
      SavingEntry.fromJson(await _we.upsert(clientId(e.id), e.toJson()));

  Future<SavingEntry> updateEntry(SavingEntry e) async =>
      SavingEntry.fromJson(await _we.upsert(e.id, e.toJson()));

  Future<void> deleteEntry(String id) => _we.delete(id);
}
