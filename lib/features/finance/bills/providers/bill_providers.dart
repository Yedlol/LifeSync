import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/live_list_notifier.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/bill_repository.dart';
import '../models/bill.dart';
import '../models/bill_payment.dart';
import '../models/bill_status.dart';

final billRepositoryProvider = Provider<BillRepository>(
  (_) => BillRepository(),
);

/// All bills (incl. inactive), live.
final billsProvider = NotifierProvider<BillsNotifier, AsyncValue<List<Bill>>>(
  BillsNotifier.new,
);

class BillsNotifier extends LiveListNotifier<Bill> {
  BillRepository get _repo => ref.read(billRepositoryProvider);

  @override
  AsyncValue<List<Bill>> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    return startLive();
  }

  @override
  Stream<List<Bill>> watchSource() => _repo.watchBills();

  @override
  String idOf(Bill item) => item.id;

  Future<void> create(Bill b) async {
    final saved = await _repo.create(b);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> save(Bill b) async {
    final saved = await _repo.update(b);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> setActive(Bill b, bool active) => optimistic(
    changed: [b.copyWith(isActive: active)],
    save: () => _repo.setActive(b.id, active),
  );

  Future<void> delete(Bill b) =>
      optimistic(removed: {b.id}, save: () => _repo.delete(b.id));
}

/// All payments, live.
final billPaymentsProvider =
    NotifierProvider<BillPaymentsNotifier, AsyncValue<List<BillPayment>>>(
      BillPaymentsNotifier.new,
    );

class BillPaymentsNotifier extends LiveListNotifier<BillPayment> {
  BillRepository get _repo => ref.read(billRepositoryProvider);

  @override
  AsyncValue<List<BillPayment>> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    return startLive();
  }

  @override
  Stream<List<BillPayment>> watchSource() => _repo.watchPayments();

  @override
  String idOf(BillPayment item) => item.id;

  Future<void> markPaid({
    required String billId,
    required DateTime period,
    required double amountPaid,
    required DateTime paidAt,
  }) async {
    final saved = await _repo.markPaid(
      billId: billId,
      period: period,
      amountPaid: amountPaid,
      paidAt: paidAt,
    );
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> markUnpaid(BillPayment p) => optimistic(
    removed: {p.id},
    save: () => _repo.markUnpaid(p.billId, p.period),
  );
}

/// The month shown on the Bills screen (always the 1st, local time).
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => monthStart(DateTime.now());

  void shift(int months) =>
      state = DateTime(state.year, state.month + months, 1);
  void reset() => state = monthStart(DateTime.now());
  bool get isCurrent => state == monthStart(DateTime.now());
}

class BillMonth {
  const BillMonth(this.entries, this.totals);
  final List<BillEntry> entries;
  final MonthTotals totals;
}

/// Bills for the selected month with paid/unpaid status computed in Dart.
final billMonthProvider = Provider<AsyncValue<BillMonth>>(
  (ref) => ref.watch(billMonthFor(ref.watch(selectedMonthProvider))),
);

/// Same for any month (first day of it).
final billMonthFor = Provider.family<AsyncValue<BillMonth>, DateTime>((
  ref,
  month,
) {
  final bills = ref.watch(billsProvider);
  final payments = ref.watch(billPaymentsProvider);

  if (bills.hasError && !bills.hasValue) {
    return AsyncError(bills.error!, bills.stackTrace ?? StackTrace.empty);
  }
  if (payments.hasError && !payments.hasValue) {
    return AsyncError(payments.error!, payments.stackTrace ?? StackTrace.empty);
  }
  if (!bills.hasValue || !payments.hasValue) return const AsyncLoading();

  final entries = billsForMonth(
    bills: bills.requireValue,
    payments: payments.requireValue,
    month: month,
    today: DateTime.now(),
  );
  return AsyncData(BillMonth(entries, totalsOf(entries)));
});

/// Custom categories used before (anything outside the presets), sorted.
final customCategoriesProvider = Provider<List<String>>((ref) {
  final bills = ref.watch(billsProvider).value ?? const <Bill>[];
  return {
    for (final b in bills)
      if (b.category.trim().isNotEmpty && !kBillCategories.contains(b.category))
        b.category,
  }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
});
