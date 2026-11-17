import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_store.dart';
import 'op_errors.dart';
import 'outbox.dart';
import 'sync_engine.dart';
import 'sync_remote.dart';
import 'sync_status.dart';

export 'sync_status.dart';

final syncRemoteProvider = Provider<SyncRemote>((_) => SyncRemote());
final connectivitySourceProvider = Provider<ConnectivitySource>(
  (_) => ConnectivitySource(),
);

/// Sync state for the UI (indicator, banner, settings).
final syncServiceProvider = NotifierProvider<SyncService, SyncStatus>(
  SyncService.new,
);

/// False while offline (no network, or the server is unreachable).
final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(syncServiceProvider.select((s) => s.online)),
);

/// Replays the outbox. Runs on reconnect, on app resume, shortly after each
/// new change, every 60s while changes are pending, and with backoff after a
/// network error. Once the outbox is empty it re-fetches every table.
class SyncService extends Notifier<SyncStatus> {
  static const _debounce = Duration(milliseconds: 300);
  static const _periodic = Duration(seconds: 60);
  static const _lastSyncedKey = 'lastSyncedAt';

  final _subs = <StreamSubscription<Object?>>[];
  Timer? _kick;
  Timer? _backoff;
  Timer? _tick;
  AppLifecycleListener? _life;
  bool _connected = true;
  bool _reachable = true;
  bool _running = false;
  bool _again = false;
  bool _refreshWanted = false;
  int _attempt = 0;

  LocalStore get _store => LocalStore.instance;
  Outbox get _outbox => _store.outbox;
  SyncRemote get _remote => ref.read(syncRemoteProvider);

  @override
  SyncStatus build() {
    ref.onDispose(_dispose);
    _subs.add(_outbox.changes.listen((_) => _publish()));
    _subs.add(_outbox.added.listen((_) => _request(delay: _debounce)));
    _tick = Timer.periodic(_periodic, (_) {
      if (_outbox.pendingCount > 0) _request();
    });
    if (_remote.ready) {
      final conn = ref.read(connectivitySourceProvider);
      _subs.add(
        conn.changes().listen(
          _onConnectivity,
          onError: (Object e) => debugPrint('connectivity stream: $e'),
        ),
      );
      _life = AppLifecycleListener(onResume: () => _request(refresh: true));
      conn.isConnected().then((c) {
        _connected = c;
        _request(refresh: true);
      });
    }
    return _snapshot();
  }

  /// Manual "Sync now" (also re-fetches everything).
  Future<void> syncNow() async {
    if (_remote.ready) {
      _connected = await ref.read(connectivitySourceProvider).isConnected();
    }
    _reachable = true;
    _attempt = 0;
    _refreshWanted = true;
    await _run();
  }

  /// Sync + full re-fetch shortly (e.g. right after logging in).
  void refreshSoon() => _request(refresh: true, delay: _debounce);

  /// Put a failed change back in the queue.
  Future<void> retryFailed(OutboxOp op) => _outbox.retry(op);

  /// Drop a failed change and reload that table from the server so the
  /// cache stops showing the rejected local version.
  Future<void> discardFailed(OutboxOp op) async {
    await _outbox.discard(op);
    if (!Tables.all.contains(op.table) || !_remote.ready) return;
    try {
      await _store.applySnapshot(op.table, await _remote.fetchAll(op.table));
    } catch (e) {
      debugPrint('reload ${op.table} after discard failed: $e');
      _refreshWanted = true; // picked up by the next successful sync
    }
  }

  void _onConnectivity(bool connected) {
    final was = _connected;
    _connected = connected;
    if (connected && !was) {
      _reachable = true;
      _attempt = 0;
      _backoff?.cancel();
      _request(refresh: true);
    }
    _publish();
  }

  void _request({bool refresh = false, Duration delay = Duration.zero}) {
    if (refresh) _refreshWanted = true;
    _kick?.cancel();
    _kick = Timer(delay, _run);
  }

  Future<void> _run() async {
    if (!ref.mounted) return;
    if (_running) {
      _again = true;
      return;
    }
    final remote = _remote;
    if (!remote.ready || !_connected) {
      _publish();
      return;
    }
    _running = true;
    final refresh = _refreshWanted;
    _refreshWanted = false;
    _publish();
    var ok = false;
    try {
      final r = await flushOutbox(_outbox, remote.send);
      if (r.networkError != null) {
        debugPrint('sync paused (network): ${r.networkError}');
        if (refresh) _refreshWanted = true;
      } else {
        if (_outbox.pendingCount == 0 && (refresh || r.sent > 0)) {
          for (final t in Tables.all) {
            await _store.applySnapshot(t, await remote.fetchAll(t));
          }
        }
        ok = true;
      }
    } catch (e) {
      debugPrint('sync failed: $e');
      if (classifyError(e) == OpErrorKind.rejected) ok = true;
      if (refresh && !ok) _refreshWanted = true;
    } finally {
      _running = false;
    }
    if (!ref.mounted) return;
    if (ok) {
      _reachable = true;
      _attempt = 0;
      _backoff?.cancel();
      if (_outbox.pendingCount == 0) {
        await _store.setMeta(
          _lastSyncedKey,
          DateTime.now().toUtc().toIso8601String(),
        );
      }
    } else {
      _reachable = false;
      _attempt++;
      _backoff?.cancel();
      _backoff = Timer(backoffFor(_attempt), () => _request(refresh: true));
    }
    _publish();
    if (_again) {
      _again = false;
      _request();
    }
  }

  SyncStatus _snapshot() {
    final last = _store.meta(_lastSyncedKey);
    return SyncStatus(
      online: _connected && _reachable,
      syncing: _running,
      pending: _outbox.pendingCount,
      failed: _outbox.failed,
      lastSyncedAt: last is String ? DateTime.tryParse(last)?.toLocal() : null,
    );
  }

  void _publish() {
    if (ref.mounted) state = _snapshot();
  }

  void _dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _kick?.cancel();
    _backoff?.cancel();
    _tick?.cancel();
    _life?.dispose();
  }
}
