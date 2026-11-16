import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Finance sub-tab indexes.
const kTabOverview = 0, kTabBills = 1, kTabSavings = 2, kTabIncome = 3;

/// Which Finance sub-tab is showing. Other screens (e.g. the dashboard) set
/// it to deep-link into a sub-tab.
final financeTabProvider = NotifierProvider<FinanceTabNotifier, int>(
  FinanceTabNotifier.new,
);

class FinanceTabNotifier extends Notifier<int> {
  @override
  int build() => kTabOverview;

  void set(int index) => state = index;
}
