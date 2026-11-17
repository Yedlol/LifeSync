import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/core/offline/local_store.dart';
import 'package:lifesync/core/offline/op_errors.dart';
import 'package:lifesync/core/offline/outbox.dart';
import 'package:lifesync/core/offline/sync_engine.dart';
import 'package:lifesync/core/offline/sync_remote.dart';
import 'package:lifesync/core/offline/sync_service.dart';
import 'package:lifesync/features/finance/bills/data/bill_repository.dart';
import 'package:lifesync/features/finance/bills/models/bill.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

LocalStore get _store => LocalStore.instance;
Outbox get _outbox => _store.outbox;

Map<String, dynamic> _task(String id, String title) => {
  'id': id,
  'title': title,
  'status': 'open',
  'position': 1000,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => LocalStore.instance = LocalStore.memory());

  group('outbox', () {
    test('keeps insertion order; complete / fail / retry / discard', () async {
      final a = await _outbox.add(table: 'tasks', op: 'upsert', recordId: 'a');
      final b = await _outbox.add(table: 'tasks', op: 'delete', recordId: 'b');
      final c = await _outbox.add(table: 'bills', op: 'upsert', recordId: 'c');
      expect(_outbox.pending.map((o) => o.recordId), ['a', 'b', 'c']);

      await _outbox.complete(a);
      await _outbox.fail(b, 'duplicate key');
      expect(_outbox.pending.map((o) => o.recordId), ['c']);
      expect(_outbox.failed.single.error, 'duplicate key');

      await _outbox.retry(_outbox.failed.single);
      expect(_outbox.pending.map((o) => o.recordId), ['c', 'b']);
      expect(_outbox.failed, isEmpty);
      expect(_outbox.pending.last.error, isNull);

      await _outbox.fail(_outbox.pending.last, 'again');
      await _outbox.discard(_outbox.failed.single);
      expect(_outbox.failed, isEmpty);
      expect(c.recordId, 'c');
    });

    test('match ops protect the rows they filter', () {
      final op = OutboxOp(
        id: 'x',
        seq: 1,
        table: 'bill_payments',
        op: OutboxOp.delete,
        match: const {'bill_id': 'b1', 'period': '2026-11-01'},
        createdAt: DateTime(2026),
      );
      expect(op.protects({'bill_id': 'b1', 'period': '2026-11-01'}, 'id'), true);
      expect(op.protects({'bill_id': 'b1', 'period': '2026-10-01'}, 'id'), false);
    });
  });

  group('cache snapshot', () {
    test('server wins, except rows with pending changes', () async {
      await _store.applySnapshot('tasks', [_task('1', 'one'), _task('2', 'two')]);
      expect(_store.isLoaded('tasks'), true);

      // Local edit of 1 and local delete of 2, both unsynced.
      await _store.put('tasks', _task('1', 'one (edited offline)'));
      await _outbox.add(table: 'tasks', op: 'upsert', recordId: '1');
      await _store.remove('tasks', '2');
      await _outbox.add(table: 'tasks', op: 'delete', recordId: '2');

      // Stale server data + a row created on another device.
      await _store.applySnapshot('tasks', [
        _task('1', 'one'),
        _task('2', 'two'),
        _task('3', 'three'),
      ]);
      expect(_store.row('tasks', '1')?['title'], 'one (edited offline)');
      expect(_store.row('tasks', '2'), isNull);
      expect(_store.row('tasks', '3')?['title'], 'three');

      // Once synced, the server's version is used again.
      for (final o in _outbox.pending) {
        await _outbox.complete(o);
      }
      await _store.applySnapshot('tasks', [_task('3', 'three')]);
      expect(_store.rows('tasks').map((r) => r['id']), ['3']);
    });

    test('unchanged snapshot does not notify', () async {
      await _store.applySnapshot('tasks', [_task('1', 'one')]);
      var n = 0;
      final sub = _store.changes('tasks').listen((_) => n++);
      await _store.applySnapshot('tasks', [_task('1', 'one')]);
      expect(n, 0);
      await sub.cancel();
    });

    test('ensureOwner clears another account\'s cache', () async {
      await _store.ensureOwner('u1');
      await _store.applySnapshot('tasks', [_task('1', 'one')]);
      await _outbox.add(table: 'tasks', op: 'upsert', recordId: '1');
      await _store.ensureOwner('u1');
      expect(_store.rows('tasks'), hasLength(1));
      await _store.ensureOwner('u2');
      expect(_store.rows('tasks'), isEmpty);
      expect(_outbox.pendingCount, 0);
      expect(_store.isLoaded('tasks'), false);
    });
  });

  group('repositories write to cache + outbox', () {
    test('bills: client ids, markPaid upsert on (bill_id, period)', () async {
      final repo = BillRepository();
      final bill = await repo.create(
        const Bill(id: '', name: 'Rent', amount: 1000, dueDay: 1),
      );
      expect(bill.id, hasLength(36)); // uuid
      expect(_store.row('bills', bill.id)?['name'], 'Rent');

      final p1 = await repo.markPaid(
        billId: bill.id,
        period: DateTime(2026, 11, 20),
        amountPaid: 1000,
        paidAt: DateTime(2026, 11, 2),
      );
      final p2 = await repo.markPaid(
        billId: bill.id,
        period: DateTime(2026, 11, 1),
        amountPaid: 900,
        paidAt: DateTime(2026, 11, 3),
      );
      expect(p2.id, p1.id); // same month keeps its row
      final pay = _outbox.pending.last;
      expect(pay.onConflict, 'bill_id,period');
      expect(pay.payload?['period'], '2026-11-01');

      await repo.markUnpaid(bill.id, DateTime(2026, 11, 5));
      expect(_store.rows('bill_payments'), isEmpty);
      expect(_outbox.pending.last.match, {
        'bill_id': bill.id,
        'period': '2026-11-01',
      });

      await repo.delete(bill.id);
      final last2 = _outbox.pending.reversed.take(2).toList().reversed;
      expect(last2.map((o) => '${o.table}:${o.op}'), [
        'bill_payments:delete',
        'bills:delete',
      ]);
    });
  });

  group('flush', () {
    test('success removes, rejection parks + continues, network stops', () async {
      for (final id in ['ok', 'bad', 'ok2', 'net', 'later']) {
        await _outbox.add(table: 'tasks', op: 'upsert', recordId: id);
      }
      final sent = <String>[];
      final r = await flushOutbox(_outbox, (op) async {
        if (op.recordId == 'bad') {
          throw const PostgrestException(message: 'violates', code: '23505');
        }
        if (op.recordId == 'net') throw TimeoutException('no route');
        sent.add(op.recordId!);
      });
      expect(sent, ['ok', 'ok2']);
      expect(r.sent, 2);
      expect(r.failed, 1);
      expect(r.networkError, isA<TimeoutException>());
      expect(_outbox.pending.map((o) => o.recordId), ['net', 'later']);
      expect(_outbox.failed.single.error, contains('23505'));
    });

    test('error classification', () {
      expect(
        classifyError(const PostgrestException(message: 'x', code: '23503')),
        OpErrorKind.rejected,
      );
      expect(
        classifyError(const PostgrestException(message: 'x', code: '503')),
        OpErrorKind.network,
      );
      expect(
        classifyError(const PostgrestException(message: 'x', code: 'PGRST301')),
        OpErrorKind.network,
      );
      expect(classifyError(Exception('SocketException')), OpErrorKind.network);
      expect(classifyError(StateError('bug')), OpErrorKind.rejected);
    });

    test('backoff 2s, 4s … capped at 60s', () {
      expect([1, 2, 3, 4, 5, 6, 9].map((a) => backoffFor(a).inSeconds), [
        2,
        4,
        8,
        16,
        32,
        60,
        60,
      ]);
    });
  });

  group('sync service', () {
    ProviderContainer make(_FakeRemote remote) {
      final c = ProviderContainer(
        overrides: [
          syncRemoteProvider.overrideWithValue(remote),
          connectivitySourceProvider.overrideWithValue(_FakeConnectivity()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('sends the queue, then refreshes every table', () async {
      final remote = _FakeRemote();
      final c = make(remote);
      c.read(syncServiceProvider);
      await _store.put('tasks', _task('1', 'local'));
      await _outbox.add(table: 'tasks', op: 'upsert', recordId: '1');

      await c.read(syncServiceProvider.notifier).syncNow();
      final s = c.read(syncServiceProvider);
      expect(remote.sent, ['1']);
      expect(remote.fetched, Tables.all);
      expect(s.pending, 0);
      expect(s.phase, SyncPhase.synced);
      expect(s.lastSyncedAt, isNotNull);
      // Server snapshot (empty) replaced the cache once nothing was pending.
      expect(_store.rows('tasks'), isEmpty);
    });

    test('network error -> offline, changes stay queued', () async {
      final remote = _FakeRemote()..offline = true;
      final c = make(remote);
      c.read(syncServiceProvider);
      await _outbox.add(table: 'tasks', op: 'upsert', recordId: '1');
      await c.read(syncServiceProvider.notifier).syncNow();
      final s = c.read(syncServiceProvider);
      expect(s.online, false);
      expect(s.phase, SyncPhase.offline);
      expect(s.pending, 1);
    });
  });
}

class _FakeRemote extends SyncRemote {
  bool offline = false;
  final sent = <String>[];
  final fetched = <String>[];

  @override
  bool get ready => true;

  @override
  Future<void> send(OutboxOp op) async {
    if (offline) throw TimeoutException('offline');
    sent.add(op.recordId ?? op.op);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll(String table) async {
    fetched.add(table);
    return const [];
  }
}

class _FakeConnectivity extends ConnectivitySource {
  @override
  Future<bool> isConnected() async => true;

  @override
  Stream<bool> changes() => const Stream.empty();
}
