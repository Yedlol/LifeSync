import '../../savings/models/savings_parsing.dart' show round2;
import 'income_entry.dart';

bool sameMonth(DateTime d, DateTime month) =>
    d.year == month.year && d.month == month.month;

class IncomeSummary {
  const IncomeSummary({
    required this.basic,
    required this.otHours,
    required this.otAmount,
    required this.other,
  });

  /// Salary entries.
  final double basic;
  final double otHours;
  final double otAmount;

  /// Allowance + bonus + other.
  final double other;

  double get total => round2(basic + otAmount + other);
}

/// One month's income entries, split for display.
class IncomeMonth {
  const IncomeMonth({
    required this.overtime,
    required this.others,
    required this.summary,
  });

  /// Overtime entries, newest first.
  final List<IncomeEntry> overtime;

  /// Salary / allowance / bonus / other, newest first.
  final List<IncomeEntry> others;
  final IncomeSummary summary;

  bool get hasSalary => others.any((e) => e.type == IncomeType.salary);

  factory IncomeMonth.of(Iterable<IncomeEntry> all, DateTime month) {
    int newestFirst(IncomeEntry a, IncomeEntry b) {
      final c = b.entryDate.compareTo(a.entryDate);
      if (c != 0) return c;
      return (b.createdAt ?? b.entryDate).compareTo(a.createdAt ?? a.entryDate);
    }

    final mine = all.where((e) => sameMonth(e.entryDate, month));
    final ot = mine.where((e) => e.isOvertime).toList()..sort(newestFirst);
    final others = mine.where((e) => !e.isOvertime).toList()..sort(newestFirst);

    var basic = 0.0, other = 0.0, hours = 0.0, otAmount = 0.0;
    for (final e in others) {
      e.type == IncomeType.salary ? basic += e.amount : other += e.amount;
    }
    for (final e in ot) {
      hours += e.hours ?? 0;
      otAmount += e.amount;
    }
    return IncomeMonth(
      overtime: ot,
      others: others,
      summary: IncomeSummary(
        basic: round2(basic),
        otHours: hours,
        otAmount: round2(otAmount),
        other: round2(other),
      ),
    );
  }
}
