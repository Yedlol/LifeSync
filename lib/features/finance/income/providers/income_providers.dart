import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/live_list_notifier.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../bills/providers/bill_providers.dart' show selectedMonthProvider;
import '../data/income_repository.dart';
import '../models/income_entry.dart';
import '../models/income_month.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>(
  (_) => IncomeRepository(),
);

/// All income entries, live.
final incomeProvider =
    NotifierProvider<IncomeNotifier, AsyncValue<List<IncomeEntry>>>(
      IncomeNotifier.new,
    );

class IncomeNotifier extends LiveListNotifier<IncomeEntry> {
  IncomeRepository get _repo => ref.read(incomeRepositoryProvider);

  @override
  AsyncValue<List<IncomeEntry>> build() {
    ref.watch(currentEmailProvider.select((v) => v.value));
    return startLive();
  }

  @override
  Stream<List<IncomeEntry>> watchSource() => _repo.watchEntries();

  @override
  String idOf(IncomeEntry item) => item.id;

  Future<void> create(IncomeEntry e) async {
    final saved = await _repo.create(e);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> save(IncomeEntry e) async {
    final saved = await _repo.update(e);
    if (ref.mounted) upsertLocal(saved);
  }

  Future<void> delete(IncomeEntry e) =>
      optimistic(removed: {e.id}, save: () => _repo.delete(e.id));
}

/// Entries of the selected month, split + totalled.
final incomeMonthProvider = Provider<AsyncValue<IncomeMonth>>((ref) {
  final all = ref.watch(incomeProvider);
  final month = ref.watch(selectedMonthProvider);
  if (all.hasError && !all.hasValue) {
    return AsyncError(all.error!, all.stackTrace ?? StackTrace.empty);
  }
  if (!all.hasValue) return const AsyncLoading();
  return AsyncData(IncomeMonth.of(all.requireValue, month));
});
