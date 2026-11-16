import 'dart:math' as math;

import 'saving_entry.dart';
import 'savings_goal.dart';
import 'savings_parsing.dart';

/// A goal plus what has been saved so far (computed in Dart from entries).
class GoalProgress {
  const GoalProgress(this.goal, this.saved);

  factory GoalProgress.of(SavingsGoal goal, Iterable<SavingEntry> entries) =>
      GoalProgress(
        goal,
        round2(entries.fold<double>(0, (sum, e) => sum + e.amount)),
      );

  final SavingsGoal goal;
  final double saved;

  double get target => goal.targetAmount;
  bool get reached => target > 0 && saved >= target;
  double get fraction => target > 0 ? saved / target : 0;

  /// Whole percent. Stays below 100 until the goal is actually reached;
  /// can go above 100 afterwards.
  int get percent {
    final p = fraction * 100;
    return reached ? p.round() : math.max(0, math.min(99, p.floor()));
  }

  /// 0..1 for the progress bar.
  double get barValue => fraction.clamp(0.0, 1.0);

  double get remaining => round2(math.max(0, target - saved));

  bool isPastDeadline(DateTime today) =>
      goal.deadline != null && !reached && goal.deadline!.isBefore(_day(today));

  /// Remaining ÷ months left (at least 1). Null if there is no deadline, it
  /// has passed, or the goal is reached.
  double? monthlyNeeded(DateTime today) {
    final deadline = goal.deadline;
    if (deadline == null || reached || isPastDeadline(today)) return null;
    final days = deadline.difference(_day(today)).inDays;
    final months = math.max(1, (days / 30.4375).ceil());
    return remaining / months;
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// In-progress goals first (closest deadline first, no deadline last),
/// reached goals at the bottom.
List<GoalProgress> sortGoals(Iterable<GoalProgress> goals) {
  int byName(GoalProgress a, GoalProgress b) =>
      a.goal.name.toLowerCase().compareTo(b.goal.name.toLowerCase());
  return goals.toList()..sort((a, b) {
    if (a.reached != b.reached) return a.reached ? 1 : -1;
    if (a.reached) return byName(a, b);
    final da = a.goal.deadline, db = b.goal.deadline;
    if (da != null && db != null) {
      final c = da.compareTo(db);
      return c != 0 ? c : byName(a, b);
    }
    if (da != null) return -1;
    if (db != null) return 1;
    return byName(a, b);
  });
}

class SavingsTotals {
  const SavingsTotals({required this.saved, required this.target});
  final double saved;
  final double target;

  double get fraction => target > 0 ? saved / target : 0;
  int get percent {
    final p = fraction * 100;
    return saved >= target && target > 0
        ? p.round()
        : math.max(0, math.min(99, p.floor()));
  }

  double get barValue => fraction.clamp(0.0, 1.0);

  static SavingsTotals of(Iterable<GoalProgress> goals) => SavingsTotals(
    saved: round2(goals.fold<double>(0, (s, g) => s + g.saved)),
    target: round2(goals.fold<double>(0, (s, g) => s + g.target)),
  );
}
