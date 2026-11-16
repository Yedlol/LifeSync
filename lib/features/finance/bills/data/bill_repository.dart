import '../../../../core/supabase/supabase_config.dart';
import '../models/bill.dart';
import '../models/bill_payment.dart';

class BillRepository {
  static const _bills = 'bills';
  static const _payments = 'bill_payments';

  /// Live lists (initial fetch + realtime changes from other devices).
  Stream<List<Bill>> watchBills() => supabaseClient
      .from(_bills)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: true)
      .map((rows) => rows.map(Bill.fromJson).toList());

  Stream<List<BillPayment>> watchPayments() => supabaseClient
      .from(_payments)
      .stream(primaryKey: ['id'])
      .map((rows) => rows.map(BillPayment.fromJson).toList());

  Future<List<Bill>> list() async {
    final rows = await supabaseClient
        .from(_bills)
        .select()
        .order('created_at', ascending: true);
    return rows.map(Bill.fromJson).toList();
  }

  Future<Bill> create(Bill b) async {
    final row = await supabaseClient
        .from(_bills)
        .insert(b.toJson())
        .select()
        .single();
    return Bill.fromJson(row);
  }

  Future<Bill> update(Bill b) async {
    final row = await supabaseClient
        .from(_bills)
        .update(b.toJson())
        .eq('id', b.id)
        .select()
        .single();
    return Bill.fromJson(row);
  }

  /// Deletes the bill and, explicitly, its payment history.
  Future<void> delete(String id) async {
    await supabaseClient.from(_payments).delete().eq('bill_id', id);
    await supabaseClient.from(_bills).delete().eq('id', id);
  }

  Future<void> setActive(String id, bool active) =>
      supabaseClient.from(_bills).update({'is_active': active}).eq('id', id);

  /// Records (or corrects) the payment for [period] (first day of a month).
  Future<BillPayment> markPaid({
    required String billId,
    required DateTime period,
    required double amountPaid,
    required DateTime paidAt,
  }) async {
    final key = dateOnly(monthStart(period));
    final values = {'amount_paid': amountPaid, 'paid_at': paidAtValue(paidAt)};
    final existing = await supabaseClient
        .from(_payments)
        .select('id')
        .eq('bill_id', billId)
        .eq('period', key)
        .limit(1);
    final row = existing.isEmpty
        ? await supabaseClient
              .from(_payments)
              .insert({'bill_id': billId, 'period': key, ...values})
              .select()
              .single()
        : await supabaseClient
              .from(_payments)
              .update(values)
              .eq('id', existing.first['id'] as String)
              .select()
              .single();
    return BillPayment.fromJson(row);
  }

  Future<void> markUnpaid(String billId, DateTime period) => supabaseClient
      .from(_payments)
      .delete()
      .eq('bill_id', billId)
      .eq('period', dateOnly(monthStart(period)));
}
