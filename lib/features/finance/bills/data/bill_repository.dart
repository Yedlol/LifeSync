import '../../../../core/offline/cached_table.dart';
import '../../../../core/offline/local_store.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../models/bill.dart';
import '../models/bill_payment.dart';

/// Bills + payments: cache-first reads, writes via cache + outbox.
class BillRepository {
  static const _bills = Tables.bills;
  static const _payments = Tables.billPayments;
  static const _wb = OfflineWriter(_bills);
  static const _wp = OfflineWriter(_payments);

  static final billCache = CachedTable<Bill>(
    _bills,
    Bill.fromJson,
    compare: (a, b) {
      final c = compareNullable(a.createdAt, b.createdAt);
      return c != 0 ? c : a.id.compareTo(b.id);
    },
  );
  static final paymentCache = CachedTable<BillPayment>(
    _payments,
    BillPayment.fromJson,
  );

  /// Raw rows: initial fetch + realtime changes (written into the cache).
  Stream<List<Map<String, dynamic>>> watchBillRows() => supabaseClient
      .from(_bills)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true);

  Stream<List<Map<String, dynamic>>> watchPaymentRows() =>
      supabaseClient.from(_payments).stream(primaryKey: ['id']);

  Bill _cachedBill(String id) {
    final row = _wb.cached(id);
    if (row == null) throw StateError('Bill $id is not cached');
    return Bill.fromJson(row);
  }

  Future<Bill> create(Bill b) async =>
      Bill.fromJson(await _wb.upsert(clientId(b.id), b.toJson()));

  Future<Bill> update(Bill b) async =>
      Bill.fromJson(await _wb.upsert(b.id, b.toJson()));

  /// Deletes the bill and, explicitly, its payment history.
  Future<void> delete(String id) async {
    await _wp.deleteWhere({'bill_id': id});
    await _wb.delete(id);
  }

  Future<void> setActive(String id, bool active) async {
    final b = _cachedBill(id).copyWith(isActive: active);
    await _wb.upsert(id, b.toJson());
  }

  /// Records (or corrects) the payment for [period] (first day of a month).
  /// Upserted on (bill_id, period); an existing payment keeps its id.
  Future<BillPayment> markPaid({
    required String billId,
    required DateTime period,
    required double amountPaid,
    required DateTime paidAt,
  }) async {
    final key = dateOnly(monthStart(period));
    String? existingId;
    for (final r in LocalStore.instance.rows(_payments)) {
      if (r['bill_id'] == billId && '${r['period']}'.startsWith(key)) {
        existingId = r['id'] as String?;
        break;
      }
    }
    final p = BillPayment(
      id: clientId(existingId),
      billId: billId,
      period: monthStart(period),
      amountPaid: amountPaid,
      paidAt: paidAt,
    );
    final row = await _wp.upsert(
      p.id,
      p.toJson(),
      onConflict: 'bill_id,period',
    );
    return BillPayment.fromJson(row);
  }

  Future<void> markUnpaid(String billId, DateTime period) => _wp.deleteWhere({
    'bill_id': billId,
    'period': dateOnly(monthStart(period)),
  });
}
