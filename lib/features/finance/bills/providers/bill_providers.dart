import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/live_list_notifier.dart';
import '../../../../core/offline/cached_table.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/bill_repository.dart';
import '../models/bill.dart';
import '../models/bill_payment.dart';
import '../models/bill_status.dart';

final billRepositoryProvider = Provider<BillRepository>(
  (_) => BillRepository(),
);

/// All bills (incl. inactive), from the offline cache.
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
  CachedTable<Bill> get table => BillRepository.billCache;

  @override
  Stream<List<Map<String, dynamic>>> watchRows() => _repo.watchBillRows();

  Future<void> create(Bill b) => _repo.create(b);

  Future<void> save(Bill b) => _repo.update(b);

  Future<void> setActive(Bill b, bool active) => _repo.setActive(b.id, active);

  Future<void> delete(Bill b) => _repo.delete(b.id);
}

/// All payments, from the offline cache.
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
  CachedTable<BillPayment> get table => BillRepository.paymentCache;

  @override
  Stream<List<Map<String, dynamic>>> watchRows() => _repo.watchPaymentRows();

  Future<void> markPaid({
    required String billId,
    required DateTime period,
    required double amountPaid,
    required DateTime paidAt,
  }) => _repo.markPaid(
    billId: billId,
    period: period,
    amountPaid: amountPaid,
    paidAt: paidAt,
  );

  Future<void> markUnpaid(BillPayment p) =>
      _repo.markUnpaid(p.billId, p.period);
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
  void set(DateTime month) => state = monthStart(month);
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
