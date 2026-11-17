import '../../../../core/offline/cached_table.dart';
import '../../../../core/offline/local_store.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../models/income_entry.dart';

/// Income entries: cache-first reads, writes via cache + outbox.
class IncomeRepository {
  static const _table = Tables.incomeEntries;
  static const _w = OfflineWriter(_table);

  /// Newest entry date first (same as the old server query).
  static final cache = CachedTable<IncomeEntry>(
    _table,
    IncomeEntry.fromJson,
    compare: (a, b) {
      final c = b.entryDate.compareTo(a.entryDate);
      return c != 0 ? c : a.id.compareTo(b.id);
    },
  );

  /// Raw rows: initial fetch + realtime changes (written into the cache).
  Stream<List<Map<String, dynamic>>> watchRows() => supabaseClient
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('entry_date', ascending: false);

  Future<IncomeEntry> create(IncomeEntry e) async =>
      IncomeEntry.fromJson(await _w.upsert(clientId(e.id), e.toJson()));

  Future<IncomeEntry> update(IncomeEntry e) async =>
      IncomeEntry.fromJson(await _w.upsert(e.id, e.toJson()));

  Future<void> delete(String id) => _w.delete(id);
}
