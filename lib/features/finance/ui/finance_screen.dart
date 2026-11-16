import 'package:flutter/material.dart';

import '../bills/ui/bills_screen.dart';
import '../income/ui/income_screen.dart';
import '../overview/ui/overview_screen.dart';
import '../savings/ui/savings_screen.dart';

/// Finance tab: Overview / Bills / Savings / Income sub-tabs.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Bills'),
              Tab(text: 'Savings'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OverviewScreen(),
            BillsScreen(),
            SavingsScreen(),
            IncomeScreen(),
          ],
        ),
      ),
    );
  }
}
