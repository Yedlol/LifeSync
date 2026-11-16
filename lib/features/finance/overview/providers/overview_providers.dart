import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bills/providers/bill_providers.dart';
import '../../income/models/income_month.dart' show sameMonth;
import '../../income/providers/income_providers.dart';
import '../../savings/models/savings_parsing.dart' show round2;
import '../../savings/providers/savings_providers.dart';

class MonthOverview {
  const MonthOverview({
    required this.income,
    required this.billsPaid,
    required this.billsUnpaid,
    required this.saved,
  });

  final double income;
  final double billsPaid;
  final double billsUnpaid;

  /// Net of deposits and withdrawals dated in the month.
  final double saved;

  /// Nothing recorded for the month at all.
  bool get isEmpty =>
      income == 0 && billsPaid == 0 && billsUnpaid == 0 && saved == 0;

  double get left => round2(income - billsPaid - saved);
  double get afterUnpaid => round2(left - billsUnpaid);
}

/// Everything the Overview tab shows for the selected month.
final monthOverviewProvider = Provider<AsyncValue<MonthOverview>>(
  (ref) => ref.watch(monthOverviewFor(ref.watch(selectedMonthProvider))),
);

/// Same for any month (first day of it).
final monthOverviewFor = Provider.family<AsyncValue<MonthOverview>, DateTime>((
  ref,
  month,
) {
  final income = ref.watch(incomeMonthFor(month));
  final payments = ref.watch(billPaymentsProvider);
  final bills = ref.watch(billMonthFor(month));
  final entries = ref.watch(savingEntriesProvider);

  for (final a in <AsyncValue<Object?>>[income, payments, bills, entries]) {
    if (a.hasError && !a.hasValue) {
      return AsyncError(a.error!, a.stackTrace ?? StackTrace.empty);
    }
    if (!a.hasValue) return const AsyncLoading();
  }

  var paid = 0.0, saved = 0.0;
  for (final p in payments.requireValue) {
    if (p.period == month) paid += p.amountPaid;
  }
  for (final e in entries.requireValue) {
    if (sameMonth(e.entryDate, month)) saved += e.amount;
  }
  return AsyncData(
    MonthOverview(
      income: income.requireValue.summary.total,
      billsPaid: round2(paid),
      billsUnpaid: round2(bills.requireValue.totals.remaining),
      saved: round2(saved),
    ),
  );
});

class MonthPoint {
  const MonthPoint(this.month, this.income, this.billsPaid);
  final DateTime month;
  final double income;
  final double billsPaid;
}

/// Income vs bills paid for the 6 months ending at the selected month
/// (oldest first). Empty until both lists have loaded.
final sixMonthTrendProvider = Provider<List<MonthPoint>>((ref) {
  final end = ref.watch(selectedMonthProvider);
  final income = ref.watch(incomeProvider).value;
  final payments = ref.watch(billPaymentsProvider).value;
  if (income == null || payments == null) return const [];
  return [
    for (var i = 5; i >= 0; i--)
      () {
        final m = DateTime(end.year, end.month - i, 1);
        var inc = 0.0, paid = 0.0;
        for (final e in income) {
          if (sameMonth(e.entryDate, m)) inc += e.amount;
        }
        for (final p in payments) {
          if (p.period == m) paid += p.amountPaid;
        }
        return MonthPoint(m, round2(inc), round2(paid));
      }(),
  ];
});
