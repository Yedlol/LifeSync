import 'dart:async';

import 'package:flutter/foundation.dart';

import 'kv_backend.dart';
import 'outbox.dart';

/// Cached Supabase tables (one box each).
abstract final class Tables {
  static const projects = 'projects';
  static const tasks = 'tasks';
  static const taskImages = 'task_images';
  static const bills = 'bills';
  static const billPayments = 'bill_payments';
  static const savingsGoals = 'savings_goals';
  static const savingEntries = 'saving_entries';
  static const incomeEntries = 'income_entries';
  static const userSettings = 'user_settings';

  static const all = [
    projects,
    tasks,
    taskImages,
    bills,
    billPayments,
    savingsGoals,
    savingEntries,
    incomeEntries,
    userSettings,
  ];

  /// Primary key column.
  static String keyOf(String table) => table == userSettings ? 'user_id' : 'id';
}

const _outbox = 'outbox';
const _failed = 'outbox_failed';
const _meta = 'meta';
const _boxNames = [...Tables.all, _outbox, _failed, _meta];

/// Offline cache: every table is a box of JSON rows keyed by primary key.
/// The UI reads only from here; Supabase streams and local writes feed it.
class LocalStore {
  LocalStore._(this._boxes);

  factory LocalStore.memory() =>
      LocalStore._({for (final n in _boxNames) n: MemoryKvBox()});

  static Future<LocalStore> openHive() async {
    await initHiveStorage();
    return LocalStore._({for (final n in _boxNames) n: await openHiveBox(n)});
  }

  /// Replaced by the Hive-backed store in `main()`; in-memory in tests.
  static LocalStore instance = LocalStore.memory();

  final Map<String, KvBox> _boxes;
  final _controllers = <String, StreamController<void>>{};
  late final Outbox outbox = Outbox(_boxes[_outbox]!, _boxes[_failed]!);

  KvBox _box(String table) =>
      _boxes[table] ?? (throw ArgumentError('Unknown table $table'));

  StreamController<void> _ctl(String table) =>
      _controllers[table] ??= StreamController<void>.broadcast(sync: true);

  /// Fires (synchronously) after any change to [table].
  Stream<void> changes(String table) => _ctl(table).stream;

  void _notify(String table) => _ctl(table).add(null);

  // ---- reads ----

  List<Map<String, dynamic>> rows(String table) {
    final box = _box(table);
    return [
      for (final k in box.keys)
        if (plainJson(box.get(k)) case final Map<String, dynamic> r) r,
    ];
  }

  Map<String, dynamic>? row(String table, String id) {
    final v = plainJson(_box(table).get(id));
    return v is Map<String, dynamic> ? v : null;
  }

  /// True once [table] has been filled from the server at least once.
  bool isLoaded(String table) => meta('loaded.$table') == true;

  // ---- local writes ----

  Future<void> put(String table, Map<String, dynamic> row) async {
    final id = '${row[Tables.keyOf(table)]}';
    final f = _box(table).put(id, row);
    _notify(table);
    await f;
  }

  Future<void> remove(String table, String id) async {
    final f = _box(table).delete(id);
    _notify(table);
    await f;
  }

  /// Removes rows whose columns equal every value in [match].
  Future<void> removeWhere(String table, Map<String, dynamic> match) async {
    final box = _box(table);
    final futures = <Future<void>>[];
    for (final k in box.keys) {
      final r = row(table, k);
      if (r != null && match.entries.every((e) => '${r[e.key]}' == '${e.value}')) {
        futures.add(box.delete(k));
      }
    }
    if (futures.isEmpty) return;
    _notify(table);
    await Future.wait(futures);
  }

  // ---- server data ----

  /// Replaces [table] with the server's [serverRows], except rows that still
  /// have unsynced local changes (pending outbox ops): those keep their local
  /// version (or stay deleted). Unchanged rows aren't rewritten.
  Future<void> applySnapshot(
    String table,
    List<Map<String, dynamic>> serverRows,
  ) async {
    final box = _box(table);
    final key = Tables.keyOf(table);
    final ops = outbox.opsFor(table);
    bool guarded(Map<String, dynamic>? r) =>
        r != null && ops.any((o) => o.protects(r, key));

    final futures = <Future<void>>[];
    final seen = <String>{};
    for (final r in serverRows) {
      final id = '${r[key]}';
      seen.add(id);
      final local = row(table, id);
      if (guarded(r) || guarded(local) || deepEquals(local, r)) continue;
      futures.add(box.put(id, r));
    }
    for (final id in box.keys) {
      if (seen.contains(id) || guarded(row(table, id))) continue;
      futures.add(box.delete(id));
    }
    final firstLoad = !isLoaded(table);
    if (firstLoad) futures.add(_boxes[_meta]!.put('loaded.$table', true));
    if (futures.isNotEmpty) _notify(table);
    await Future.wait(futures);
  }

  // ---- meta (per-device) ----

  Object? meta(String key) => _boxes[_meta]!.get(key);

  Future<void> setMeta(String key, Object? value) =>
      _boxes[_meta]!.put(key, value);

  /// Clears everything if the cache belongs to a different account.
  Future<void> ensureOwner(String? userId) async {
    if (userId == null) return;
    final owner = meta('owner');
    if (owner != null && owner != userId) {
      debugPrint('Cache belongs to another account; clearing it.');
      await clearAll();
    }
    if (owner != userId) await setMeta('owner', userId);
  }

  /// Logout: drop every cached table, the outbox and sync metadata.
  Future<void> clearAll() async {
    await Future.wait([for (final b in _boxes.values) b.clear()]);
    for (final t in Tables.all) {
      _notify(t);
    }
    await outbox.clear();
  }
}
