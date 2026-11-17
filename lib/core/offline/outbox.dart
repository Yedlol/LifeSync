import 'dart:async';
import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import 'kv_backend.dart';

/// One pending change for the server.
class OutboxOp {
  const OutboxOp({
    required this.id,
    required this.seq,
    required this.table,
    required this.op,
    required this.createdAt,
    this.recordId,
    this.payload,
    this.match,
    this.onConflict,
    this.error,
  });

  static const upsert = 'upsert';
  static const delete = 'delete';

  /// Removes Storage files; payload: {bucket, paths?, folder?}.
  static const storageRemove = 'storage_remove';

  final String id;

  /// Replay order (monotonic, survives restarts).
  final int seq;
  final String table;
  final String op;
  final String? recordId;
  final Map<String, dynamic>? payload;

  /// Delete filter (column -> value) instead of the record id.
  final Map<String, dynamic>? match;
  final String? onConflict;
  final DateTime createdAt;

  /// Set when the server rejected it (failed list).
  final String? error;

  /// True if this op is about [row], so server data must not overwrite the
  /// local version of it yet.
  bool protects(Map<String, dynamic> row, String keyColumn) {
    if (recordId != null && '${row[keyColumn]}' == recordId) return true;
    final m = match;
    if (m == null || m.isEmpty) return false;
    return m.entries.every((e) => '${row[e.key]}' == '${e.value}');
  }

  OutboxOp copyWith({int? seq, String? error, bool clearError = false}) =>
      OutboxOp(
        id: id,
        seq: seq ?? this.seq,
        table: table,
        op: op,
        createdAt: createdAt,
        recordId: recordId,
        payload: payload,
        match: match,
        onConflict: onConflict,
        error: clearError ? null : (error ?? this.error),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'seq': seq,
    'table': table,
    'op': op,
    'recordId': recordId,
    'payload': payload,
    'match': match,
    'onConflict': onConflict,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'error': error,
  };

  factory OutboxOp.fromMap(Map<String, dynamic> m) => OutboxOp(
    id: m['id'] as String,
    seq: (m['seq'] as num).toInt(),
    table: m['table'] as String,
    op: m['op'] as String,
    recordId: m['recordId'] as String?,
    payload: (m['payload'] as Map?)?.cast<String, dynamic>(),
    match: (m['match'] as Map?)?.cast<String, dynamic>(),
    onConflict: m['onConflict'] as String?,
    createdAt:
        DateTime.tryParse(m['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    error: m['error'] as String?,
  );
}

/// Ordered queue of pending changes plus the list the server rejected.
class Outbox {
  Outbox(this._pending, this._failed);

  final KvBox _pending;
  final KvBox _failed;
  final _changes = StreamController<void>.broadcast(sync: true);
  final _added = StreamController<void>.broadcast(sync: true);
  int _lastSeq = 0;

  /// Any change to the pending or failed list.
  Stream<void> get changes => _changes.stream;

  /// A new change was queued (triggers a sync).
  Stream<void> get added => _added.stream;

  List<OutboxOp> _read(KvBox box) {
    final ops = <OutboxOp>[];
    for (final k in box.keys) {
      final v = plainJson(box.get(k));
      if (v is Map<String, dynamic>) ops.add(OutboxOp.fromMap(v));
    }
    return ops..sort((a, b) => a.seq.compareTo(b.seq));
  }

  List<OutboxOp> get pending => _read(_pending);
  List<OutboxOp> get failed => _read(_failed);
  int get pendingCount => _pending.keys.length;
  int get failedCount => _failed.keys.length;

  /// Pending ops for [table] (used to protect unsynced local rows).
  List<OutboxOp> opsFor(String table) =>
      pending.where((o) => o.table == table).toList();

  int _nextSeq() {
    if (_lastSeq == 0) {
      for (final o in [...pending, ...failed]) {
        _lastSeq = math.max(_lastSeq, o.seq);
      }
    }
    _lastSeq = math.max(_lastSeq + 1, DateTime.now().microsecondsSinceEpoch);
    return _lastSeq;
  }

  Future<OutboxOp> add({
    required String table,
    required String op,
    String? recordId,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? match,
    String? onConflict,
  }) async {
    final o = OutboxOp(
      id: const Uuid().v4(),
      seq: _nextSeq(),
      table: table,
      op: op,
      recordId: recordId,
      payload: payload,
      match: match,
      onConflict: onConflict,
      createdAt: DateTime.now(),
    );
    final f = _pending.put(o.id, o.toMap());
    _changes.add(null);
    _added.add(null);
    await f;
    return o;
  }

  /// Sent successfully.
  Future<void> complete(OutboxOp o) => _write(() => _pending.delete(o.id));

  /// Rejected by the server: park it in the failed list.
  Future<void> fail(OutboxOp o, String error) => _write(() async {
    await _failed.put(o.id, o.copyWith(error: error).toMap());
    await _pending.delete(o.id);
  });

  /// Failed op goes back to the end of the queue.
  Future<void> retry(OutboxOp o) async {
    final again = o.copyWith(seq: _nextSeq(), clearError: true);
    await _write(() async {
      await _pending.put(again.id, again.toMap());
      await _failed.delete(o.id);
    });
    _added.add(null);
  }

  Future<void> discard(OutboxOp o) => _write(() => _failed.delete(o.id));

  Future<void> clear() => _write(() async {
    await _pending.clear();
    await _failed.clear();
  });

  Future<void> _write(Future<void> Function() body) async {
    final f = body();
    _changes.add(null);
    await f;
    _changes.add(null);
  }
}
