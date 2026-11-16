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

  double get left => round2(income - billsPaid - saved);
  double get afterUnpaid => round2(left - billsUnpaid);
}

/// Everything the Overview tab shows for the selected month.
final monthOverviewProvider = Provider<AsyncValue<MonthOverview>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final income = ref.watch(incomeMonthProvider);
  final payments = ref.watch(billPaymentsProvider);
  final bills = ref.watch(billMonthProvider);
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
