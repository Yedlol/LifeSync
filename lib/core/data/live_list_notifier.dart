import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a list that is kept in sync with a Supabase realtime stream, plus
/// local (optimistic) changes.
///
/// While an item has a save in flight, the local copy wins over whatever the
/// stream sends, so the UI doesn't flicker back to the old value. Stream
/// errors (e.g. phone sleeping) keep the last data and resubscribe.
abstract class LiveListNotifier<T> extends Notifier<AsyncValue<List<T>>> {
  StreamSubscription<List<T>>? _sub;
  Timer? _retry;
  final _pending = <String, int>{};

  Stream<List<T>> watchSource();
  String idOf(T item);

  /// Call from `build()` after watching any dependencies.
  AsyncValue<List<T>> startLive() {
    _pending.clear();
    ref.onDispose(() {
      _retry?.cancel();
      _sub?.cancel();
    });
    _listen();
    return const AsyncLoading();
  }

  List<T> get items => state.value ?? const [];

  void _listen() {
    _sub?.cancel();
    _sub = watchSource().listen(
      _onServer,
      onError: (Object e, StackTrace st) {
        debugPrint('$runtimeType stream error: $e');
        if (!ref.mounted) return;
        if (!state.hasValue) state = AsyncError(e, st);
        _retry?.cancel();
        _retry = Timer(const Duration(seconds: 5), () {
          if (ref.mounted) _listen();
        });
      },
    );
  }

  void _onServer(List<T> server) {
    if (!ref.mounted) return;
    if (_pending.isEmpty) {
      state = AsyncData(server);
      return;
    }
    final local = {for (final t in items) idOf(t): t};
    final merged = <T>[];
    for (final s in server) {
      final id = idOf(s);
      if (!_pending.containsKey(id)) {
        merged.add(s);
      } else if (local[id] != null) {
        merged.add(local[id] as T);
      } // pending + missing locally = optimistic delete; keep it hidden.
    }
    state = AsyncData(merged);
  }

  /// Insert or replace one item locally (e.g. the row returned by an insert),
  /// so the UI updates even before the realtime event arrives.
  void upsertLocal(T item) {
    final id = idOf(item);
    final list = [...items];
    final i = list.indexWhere((t) => idOf(t) == id);
    i >= 0 ? list[i] = item : list.add(item);
    state = AsyncData(list);
  }

  /// Applies [changed] (replacements) and [removed] ids instantly, then runs
  /// [save]. On failure the affected items are restored and the error rethrown.
  Future<void> optimistic({
    List<T> changed = const [],
    Set<String> removed = const {},
    required Future<void> Function() save,
  }) async {
    final ids = {...changed.map(idOf), ...removed};
    final before = {
      for (final t in items)
        if (ids.contains(idOf(t))) idOf(t): t,
    };
    final byId = {for (final t in changed) idOf(t): t};
    state = AsyncData([
      for (final t in items)
        if (!removed.contains(idOf(t))) byId[idOf(t)] ?? t,
    ]);
    for (final id in ids) {
      _pending[id] = (_pending[id] ?? 0) + 1;
    }
    try {
      await save();
    } catch (_) {
      if (ref.mounted) {
        final present = <String>{};
        final reverted = <T>[];
        for (final t in items) {
          final id = idOf(t);
          present.add(id);
          reverted.add(before[id] ?? t);
        }
        reverted.addAll(
          before.entries
              .where((e) => !present.contains(e.key))
              .map((e) => e.value),
        );
        state = AsyncData(reverted);
      }
      rethrow;
    } finally {
      for (final id in ids) {
        final n = (_pending[id] ?? 1) - 1;
        n <= 0 ? _pending.remove(id) : _pending[id] = n;
      }
    }
  }
}
