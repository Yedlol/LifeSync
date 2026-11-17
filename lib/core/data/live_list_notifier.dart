import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/cached_table.dart';
import '../offline/local_store.dart';

/// A list read from the offline cache (the UI's single source of truth).
///
/// The Supabase realtime stream ([watchRows]) only writes into the cache;
/// local changes go through the repositories (cache + outbox), so the UI
/// updates instantly online or offline. Stream errors (offline, phone
/// sleeping) keep the cached data and resubscribe.
abstract class LiveListNotifier<T> extends Notifier<AsyncValue<List<T>>> {
  StreamSubscription<void>? _local;
  StreamSubscription<List<Map<String, dynamic>>>? _remote;
  Timer? _retry;

  CachedTable<T> get table;

  /// Raw server rows: initial fetch + realtime changes from other devices.
  Stream<List<Map<String, dynamic>>> watchRows();

  LocalStore get store => LocalStore.instance;

  /// Call from `build()` after watching any dependencies.
  AsyncValue<List<T>> startLive() {
    final store = this.store;
    final name = table.name;
    ref.onDispose(() {
      _retry?.cancel();
      _remote?.cancel();
      _local?.cancel();
    });
    _local = store.changes(name).listen((_) {
      if (ref.mounted && store.isLoaded(name)) {
        state = AsyncData(table.read(store));
      }
    });
    _listen();
    return store.isLoaded(name)
        ? AsyncData(table.read(store))
        : const AsyncLoading();
  }

  List<T> get items => state.value ?? const [];

  void _listen() {
    _remote?.cancel();
    _remote = watchRows().listen(
      (rows) => store.applySnapshot(table.name, rows),
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
}
