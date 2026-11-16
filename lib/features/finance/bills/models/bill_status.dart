import 'bill.dart';
import 'bill_payment.dart';

enum BillStatus { overdue, dueSoon, unpaid, paid }

/// A bill as it appears in one month.
class BillEntry {
  const BillEntry({
    required this.bill,
    required this.dueDate,
    required this.status,
    required this.daysUntilDue,
    this.payment,
  });

  final Bill bill;
  final BillPayment? payment;
  final DateTime dueDate;
  final BillStatus status;

  /// Whole days from today to [dueDate] (negative = past).
  final int daysUntilDue;

  /// What was actually paid, else the expected amount.
  double get amount => payment?.amountPaid ?? bill.amount;
}

class MonthTotals {
  const MonthTotals({
    required this.total,
    required this.paid,
    required this.remaining,
  });
  final double total;
  final double paid;
  final double remaining;

  double get progress => total <= 0 ? 0 : (paid / total).clamp(0.0, 1.0);
}

const kDueSoonDays = 3;

int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// Due date in [month]; a dueDay beyond the month's length uses its last day.
DateTime dueDateIn(DateTime month, int dueDay) {
  final last = daysInMonth(month.year, month.month);
  return DateTime(month.year, month.month, dueDay > last ? last : dueDay);
}

/// A one-time bill is due on the first [dueDay] on/after the day it was added.
DateTime oneTimeDueDate(Bill bill) {
  final created = bill.createdAt;
  if (created == null) return dueDateIn(DateTime(2000), bill.dueDay);
  final day = DateTime(created.year, created.month, created.day);
  final candidate = dueDateIn(monthStart(day), bill.dueDay);
  return candidate.isBefore(day)
      ? dueDateIn(DateTime(day.year, day.month + 1, 1), bill.dueDay)
      : candidate;
}

BillStatus statusFor({required bool paid, required int daysUntilDue}) {
  if (paid) return BillStatus.paid;
  if (daysUntilDue < 0) return BillStatus.overdue;
  if (daysUntilDue <= kDueSoonDays) return BillStatus.dueSoon;
  return BillStatus.unpaid;
}

/// Bills to show for [month] (any day in it), sorted: overdue, due soon,
/// unpaid (by due day), then paid.
///
/// * Inactive bills are hidden.
/// * Monthly bills appear every month from the month they were created.
/// * One-time bills appear (from the month they were created) until paid; once
///   paid they appear only in the month they were paid for.
List<BillEntry> billsForMonth({
  required Iterable<Bill> bills,
  required Iterable<BillPayment> payments,
  required DateTime month,
  required DateTime today,
}) {
  final m = monthStart(month);
  final day = DateTime(today.year, today.month, today.day);
  final byBill = <String, List<BillPayment>>{};
  for (final p in payments) {
    (byBill[p.billId] ??= []).add(p);
  }

  final entries = <BillEntry>[];
  for (final bill in bills) {
    if (!bill.isActive) continue;
    final created = bill.createdAt == null
        ? DateTime(2000)
        : monthStart(bill.createdAt!);
    final mine = byBill[bill.id] ?? const <BillPayment>[];

    BillPayment? payment;
    DateTime due;
    if (bill.isOneTime) {
      payment = mine.isEmpty ? null : mine.first;
      if (payment != null) {
        if (payment.period != m) continue;
      } else if (m.isBefore(created)) {
        continue;
      }
      due = oneTimeDueDate(bill);
    } else {
      if (m.isBefore(created)) continue;
      for (final p in mine) {
        if (p.period == m) payment = p;
      }
      due = dueDateIn(m, bill.dueDay);
    }

    final days = due.difference(day).inDays;
    entries.add(
      BillEntry(
        bill: bill,
        payment: payment,
        dueDate: due,
        daysUntilDue: days,
        status: statusFor(paid: payment != null, daysUntilDue: days),
      ),
    );
  }

  entries.sort((a, b) {
    final r = a.status.index.compareTo(b.status.index);
    if (r != 0) return r;
    final d = a.dueDate.compareTo(b.dueDate);
    return d != 0
        ? d
        : a.bill.name.toLowerCase().compareTo(b.bill.name.toLowerCase());
  });
  return entries;
}

MonthTotals totalsOf(List<BillEntry> entries) {
  var total = 0.0, paid = 0.0, remaining = 0.0;
  for (final e in entries) {
    total += e.amount;
    if (e.status == BillStatus.paid) {
      paid += e.amount;
    } else {
      remaining += e.amount;
    }
  }
  return MonthTotals(total: total, paid: paid, remaining: remaining);
}
