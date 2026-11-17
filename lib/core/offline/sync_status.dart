import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'outbox.dart';

enum SyncPhase { synced, syncing, offline }

class SyncStatus {
  const SyncStatus({
    this.online = true,
    this.syncing = false,
    this.pending = 0,
    this.failed = const [],
    this.lastSyncedAt,
  });

  final bool online;
  final bool syncing;
  final int pending;
  final List<OutboxOp> failed;
  final DateTime? lastSyncedAt;

  SyncPhase get phase {
    if (!online) return SyncPhase.offline;
    if (syncing || pending > 0) return SyncPhase.syncing;
    return SyncPhase.synced;
  }

  SyncStatus copyWith({
    bool? online,
    bool? syncing,
    int? pending,
    List<OutboxOp>? failed,
    DateTime? lastSyncedAt,
  }) => SyncStatus(
    online: online ?? this.online,
    syncing: syncing ?? this.syncing,
    pending: pending ?? this.pending,
    failed: failed ?? this.failed,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );
}

/// Network reachability from connectivity_plus. Plugin errors count as
/// "connected" (a failed request will tell us otherwise).
class ConnectivitySource {
  final _c = Connectivity();

  static bool _isOn(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);

  Future<bool> isConnected() async {
    try {
      return _isOn(await _c.checkConnectivity());
    } catch (e) {
      debugPrint('connectivity check failed: $e');
      return true;
    }
  }

  Stream<bool> changes() => _c.onConnectivityChanged.map(_isOn);
}

/// "Last synced 5 min ago" style text.
String lastSyncedText(DateTime? at, DateTime now) {
  if (at == null) return 'Not synced yet';
  final d = now.difference(at);
  if (d.inSeconds < 60) return 'Last synced just now';
  if (d.inMinutes < 60) return 'Last synced ${d.inMinutes} min ago';
  if (d.inHours < 24) {
    return 'Last synced ${d.inHours} hour${d.inHours == 1 ? '' : 's'} ago';
  }
  return 'Last synced ${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
}

/// "1 change" / "3 changes".
String changesText(int n) => '$n change${n == 1 ? '' : 's'}';

const _tableLabels = {
  'tasks': 'task',
  'projects': 'project',
  'task_images': 'task image',
  'bills': 'bill',
  'bill_payments': 'bill payment',
  'savings_goals': 'savings goal',
  'saving_entries': 'savings entry',
  'income_entries': 'income entry',
  'user_settings': 'salary settings',
  'storage': 'image files',
};

/// Human label for a queued change, e.g. 'Save task "Pay rent"'.
String describeOp(OutboxOp op) {
  final what = _tableLabels[op.table] ?? op.table;
  final verb = op.op == OutboxOp.upsert ? 'Save' : 'Delete';
  final p = op.payload;
  final name = p?['title'] ?? p?['name'];
  return name is String && name.trim().isNotEmpty
      ? '$verb $what "${name.trim()}"'
      : '$verb $what';
}
