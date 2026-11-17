import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Minimal key/value box holding JSON-like values (maps, lists, strings,
/// numbers, bools, null). Hive in the app, in-memory in tests.
abstract class KvBox {
  Iterable<String> get keys;
  Object? get(String key);

  /// The in-memory value changes synchronously; the future completes once it
  /// is persisted.
  Future<void> put(String key, Object? value);
  Future<void> delete(String key);
  Future<void> clear();
}

class MemoryKvBox implements KvBox {
  final _map = SplayTreeMap<String, Object?>();

  @override
  Iterable<String> get keys => _map.keys.toList();

  @override
  Object? get(String key) => _map[key];

  @override
  Future<void> put(String key, Object? value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);

  @override
  Future<void> clear() async => _map.clear();
}

class HiveKvBox implements KvBox {
  HiveKvBox(this._box);
  final Box<dynamic> _box;

  @override
  Iterable<String> get keys => _box.keys.map((k) => '$k').toList();

  @override
  Object? get(String key) => _box.get(key);

  @override
  Future<void> put(String key, Object? value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() => _box.clear().then((_) {});
}

/// Hive lives in the app-support folder (AppData on Windows), never in
/// Documents, which may be synced by OneDrive.
Future<void> initHiveStorage() async {
  if (kIsWeb) {
    await Hive.initFlutter(); // IndexedDB
    return;
  }
  final dir = await getApplicationSupportDirectory();
  Hive.init('${dir.path}/hive');
}

/// Opens [name]; a corrupt box is deleted and recreated (it is only a cache,
/// except the outbox, which we'd rather lose than crash on).
Future<KvBox> openHiveBox(String name) async {
  try {
    return HiveKvBox(await Hive.openBox<dynamic>(name));
  } catch (e) {
    debugPrint('Hive box "$name" unreadable, recreating: $e');
    await Hive.deleteBoxFromDisk(name);
    return HiveKvBox(await Hive.openBox<dynamic>(name));
  }
}

/// Hive returns `Map<dynamic, dynamic>`; turn it back into JSON shapes.
Object? plainJson(Object? v) => switch (v) {
  Map m => <String, dynamic>{
    for (final e in m.entries) '${e.key}': plainJson(e.value),
  },
  List l => <dynamic>[for (final x in l) plainJson(x)],
  _ => v,
};

bool deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (!b.containsKey(e.key) || !deepEquals(e.value, b[e.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
