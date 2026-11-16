import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bills/ui/bills_screen.dart';
import '../income/ui/income_screen.dart';
import '../overview/ui/overview_screen.dart';
import '../providers/finance_tab_provider.dart';
import '../savings/ui/savings_screen.dart';

/// Finance tab: Overview / Bills / Savings / Income sub-tabs.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 4,
    vsync: this,
    initialIndex: ref.read(financeTabProvider),
  );

  @override
  void initState() {
    super.initState();
    // Keep the provider in step with swipes/taps so a later deep link to the
    // same tab still counts as a change.
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(financeTabProvider.notifier).set(_tabs.index);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(financeTabProvider, (_, i) {
      if (i != _tabs.index) _tabs.animateTo(i);
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Bills'),
            Tab(text: 'Savings'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          OverviewScreen(),
          BillsScreen(),
          SavingsScreen(),
          IncomeScreen(),
        ],
      ),
    );
  }
}
