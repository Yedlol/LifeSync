import '../supabase/supabase_config.dart';
import 'local_store.dart';
import 'outbox.dart';

/// The server side of sync: replays outbox ops and fetches whole tables.
/// (Repository for the sync service; nothing else calls Supabase here.)
class SyncRemote {
  bool get ready => supabaseReady;

  Future<void> send(OutboxOp op) async {
    switch (op.op) {
      case OutboxOp.upsert:
        await supabaseClient
            .from(op.table)
            .upsert(op.payload ?? const {}, onConflict: op.onConflict);
      case OutboxOp.delete:
        final match =
            op.match ?? {Tables.keyOf(op.table): op.recordId};
        var q = supabaseClient.from(op.table).delete();
        for (final e in match.entries) {
          final v = e.value;
          q = v == null ? q.isFilter(e.key, null) : q.eq(e.key, v as Object);
        }
        await q;
      case OutboxOp.storageRemove:
        await _removeFiles(op.payload ?? const {});
      default:
        throw UnsupportedError('Unknown outbox op ${op.op}');
    }
  }

  Future<void> _removeFiles(Map<String, dynamic> p) async {
    final storage = supabaseClient.storage.from(p['bucket'] as String);
    final paths = <String>{...?(p['paths'] as List?)?.cast<String>()};
    final folder = p['folder'] as String?;
    if (folder != null) {
      for (final f in await storage.list(path: folder)) {
        if (f.id != null) paths.add('$folder/${f.name}');
      }
    }
    if (paths.isNotEmpty) await storage.remove(paths.toList());
  }

  /// Every row of [table] the user can see (RLS).
  Future<List<Map<String, dynamic>>> fetchAll(String table) =>
      supabaseClient.from(table).select();
}
