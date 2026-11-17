import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/data/live_list_notifier.dart';
import '../../../../core/offline/cached_table.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../bills/providers/bill_providers.dart' show selectedMonthProvider;
import '../data/income_repository.dart';
import '../models/income_entry.dart';
import '../models/income_month.dart';

final incomeRepositoryProvider = Provider<IncomeRepository>(
  (_) => IncomeRepository(),
);

/// All income entries, from the offline cache.
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
  CachedTable<IncomeEntry> get table => IncomeRepository.cache;

  @override
  Stream<List<Map<String, dynamic>>> watchRows() => _repo.watchRows();

  Future<void> create(IncomeEntry e) => _repo.create(e);

  Future<void> save(IncomeEntry e) => _repo.update(e);

  Future<void> delete(IncomeEntry e) => _repo.delete(e.id);
}

/// Entries of the selected month, split + totalled.
final incomeMonthProvider = Provider<AsyncValue<IncomeMonth>>(
  (ref) => ref.watch(incomeMonthFor(ref.watch(selectedMonthProvider))),
);

/// Same for any month (first day of it).
final incomeMonthFor = Provider.family<AsyncValue<IncomeMonth>, DateTime>((
  ref,
  month,
) {
  final all = ref.watch(incomeProvider);
  if (all.hasError && !all.hasValue) {
    return AsyncError(all.error!, all.stackTrace ?? StackTrace.empty);
  }
  if (!all.hasValue) return const AsyncLoading();
  return AsyncData(IncomeMonth.of(all.requireValue, month));
});
