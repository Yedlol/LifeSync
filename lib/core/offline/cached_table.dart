import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'local_store.dart';
import 'outbox.dart';

/// How one cached table maps to a model, and its display order.
class CachedTable<T> {
  const CachedTable(this.name, this.fromRow, {this.compare});

  final String name;
  final T Function(Map<String, dynamic> row) fromRow;

  /// Same order the Supabase query used (null = any).
  final int Function(T a, T b)? compare;

  List<T> read(LocalStore store) {
    final out = <T>[];
    for (final r in store.rows(name)) {
      try {
        out.add(fromRow(r));
      } catch (e) {
        debugPrint('skipping bad cached $name row: $e');
      }
    }
    final c = compare;
    if (c != null) out.sort(c);
    return out;
  }
}

/// Sort helper: nulls last.
int compareNullable<C extends Comparable<C>>(C? a, C? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Writes for one table: applied to the cache immediately (UI updates
/// instantly) and queued in the outbox for the server.
class OfflineWriter {
  const OfflineWriter(this.table);
  final String table;

  LocalStore get _store => LocalStore.instance;
  String get _key => Tables.keyOf(table);

  Map<String, dynamic>? cached(String id) => _store.row(table, id);

  /// Inserts or replaces the row [id] with the writable columns [values].
  /// The server gets an upsert, so replaying it is safe.
  Future<Map<String, dynamic>> upsert(
    String id,
    Map<String, dynamic> values, {
    String? onConflict,
  }) async {
    final existing = cached(id);
    final row = <String, dynamic>{
      ...?existing,
      if (existing == null)
        'created_at': DateTime.now().toUtc().toIso8601String(),
      ...values,
      _key: id,
    };
    // Both take effect synchronously (UI + queue order); then persist.
    await Future.wait([
      _store.put(table, row),
      _store.outbox.add(
        table: table,
        op: OutboxOp.upsert,
        recordId: id,
        payload: {_key: id, ...values},
        onConflict: onConflict,
      ),
    ]);
    return row;
  }

  Future<void> delete(String id) => Future.wait([
    _store.remove(table, id),
    _store.outbox.add(table: table, op: OutboxOp.delete, recordId: id),
  ]);

  /// Deletes every row matching [match] (column -> value).
  Future<void> deleteWhere(Map<String, dynamic> match) => Future.wait([
    _store.removeWhere(table, match),
    _store.outbox.add(table: table, op: OutboxOp.delete, match: match),
  ]);
}

/// [id] if set, else a new client-side UUID (so replaying an insert is safe).
String clientId([String? id]) =>
    (id == null || id.isEmpty) ? const Uuid().v4() : id;

/// Queues removal of Storage files (needs internet; runs during sync).
Future<void> queueStorageRemove({
  required String bucket,
  List<String> paths = const [],
  String? folder,
}) => LocalStore.instance.outbox.add(
  table: 'storage',
  op: OutboxOp.storageRemove,
  payload: {'bucket': bucket, 'paths': paths, 'folder': folder},
);
