import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/live_list_notifier.dart';
import '../../../auth/providers/auth_providers.dart';
import '../data/savings_repository.dart';
import '../models/goal_progress.dart';
import '../models/saving_entry.dart';
import '../models/savings_goal.dart';

final savingsRepositoryProvider = Provider<SavingsRepository>(
  (_) => SavingsRepository(),
);

/// All goals, live.
final savingsGoalsProvider =
    NotifierProvider<GoalsNotifier, AsyncValue<List<SavingsGoal>>>(
      GoalsNotifier.new,
    );

class GoalsNotifier extends LiveListNotifier<SavingsGoal> {
  SavingsRepository get _repo => ref.read(savingsRepositoryProvider);

  @override
  AsyncValue<List<SavingsGoal>> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    return startLive();
  }

  @override
  Stream<List<SavingsGoal>> watchSource() => _repo.watchGoals();

  @override
  String idOf(SavingsGoal item) => item.id;

  Future<void> create(SavingsGoal g) async {
    final saved = await _repo.createGoal(g);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> save(SavingsGoal g) async {
    final saved = await _repo.updateGoal(g);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> delete(SavingsGoal g) =>
      optimistic(removed: {g.id}, save: () => _repo.deleteGoal(g.id));
}

/// All entries (every goal), live.
final savingEntriesProvider =
    NotifierProvider<EntriesNotifier, AsyncValue<List<SavingEntry>>>(
      EntriesNotifier.new,
    );

class EntriesNotifier extends LiveListNotifier<SavingEntry> {
  SavingsRepository get _repo => ref.read(savingsRepositoryProvider);

  @override
  AsyncValue<List<SavingEntry>> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    return startLive();
  }

  @override
  Stream<List<SavingEntry>> watchSource() => _repo.watchEntries();

  @override
  String idOf(SavingEntry item) => item.id;

  /// Returns the saved row (with its real id) so callers can offer Undo.
  Future<SavingEntry> add(SavingEntry e) async {
    final saved = await _repo.addEntry(e);
    if (ref.mounted) upsertLocal(saved);
    return saved;
  }

  Future<void> save(SavingEntry e) async {
    final saved = await _repo.updateEntry(e);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> delete(SavingEntry e) =>
      optimistic(removed: {e.id}, save: () => _repo.deleteEntry(e.id));
}

class SavingsOverview {
  const SavingsOverview(this.goals, this.totals);
  final List<GoalProgress> goals;
  final SavingsTotals totals;
}

/// Goals with saved/percent computed in Dart, sorted for display.
final savingsOverviewProvider = Provider<AsyncValue<SavingsOverview>>((ref) {
  final goals = ref.watch(savingsGoalsProvider);
  final entries = ref.watch(savingEntriesProvider);

  if (goals.hasError && !goals.hasValue) {
    return AsyncError(goals.error!, goals.stackTrace ?? StackTrace.empty);
  }
  if (entries.hasError && !entries.hasValue) {
    return AsyncError(entries.error!, entries.stackTrace ?? StackTrace.empty);
  }
  if (!goals.hasValue || !entries.hasValue) return const AsyncLoading();

  final byGoal = <String, List<SavingEntry>>{};
  for (final e in entries.requireValue) {
    (byGoal[e.goalId] ??= []).add(e);
  }
  final progress = sortGoals([
    for (final g in goals.requireValue)
      GoalProgress.of(g, byGoal[g.id] ?? const []),
  ]);
  return AsyncData(SavingsOverview(progress, SavingsTotals.of(progress)));
});

/// One goal's progress, or null if it doesn't exist (e.g. just deleted).
final goalProgressProvider = Provider.family<GoalProgress?, String>((ref, id) {
  final overview = ref.watch(savingsOverviewProvider).value;
  if (overview == null) return null;
  for (final g in overview.goals) {
    if (g.goal.id == id) return g;
  }
  return null;
});

/// A goal's entries, newest first.
final goalEntriesProvider = Provider.family<List<SavingEntry>, String>((
  ref,
  id,
) {
  final all = ref.watch(savingEntriesProvider).value ?? const <SavingEntry>[];
  return all.where((e) => e.goalId == id).toList()..sort((a, b) {
    final c = b.entryDate.compareTo(a.entryDate);
    if (c != 0) return c;
    return (b.createdAt ?? b.entryDate).compareTo(a.createdAt ?? a.entryDate);
  });
});
