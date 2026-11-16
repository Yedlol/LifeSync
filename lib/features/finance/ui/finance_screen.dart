import 'package:flutter/material.dart';

import '../bills/ui/bills_screen.dart';

/// Finance tab: Bills / Savings / Income sub-tabs.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bills'),
              Tab(text: 'Savings'),
              Tab(text: 'Income'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BillsScreen(),
            _ComingSoon(icon: Icons.savings_outlined, label: 'Savings'),
            _ComingSoon(icon: Icons.payments_outlined, label: 'Income'),
          ],
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text('$label — coming soon'),
      ],
    ),
  );
}
