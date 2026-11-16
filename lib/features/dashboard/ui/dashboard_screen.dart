import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/breakpoints.dart';
import '../../../core/widgets/motion.dart';
import '../../finance/bills/providers/bill_providers.dart';
import '../../finance/income/providers/income_providers.dart';
import '../../finance/savings/providers/savings_providers.dart';
import '../../projects/providers/project_providers.dart';
import '../../tasks/providers/tasks_notifier.dart';
import 'widgets/bills_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/money_card.dart';
import 'widgets/quick_actions.dart';
import 'widgets/savings_card.dart';
import 'widgets/tasks_card.dart';

/// Dashboard tab: greeting, quick actions and the four summary cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Pull-to-refresh: restart every live stream the cards read.
  Future<void> _refresh(WidgetRef ref) async {
    ref
      ..invalidate(tasksProvider)
      ..invalidate(projectsProvider)
      ..invalidate(billsProvider)
      ..invalidate(billPaymentsProvider)
      ..invalidate(incomeProvider)
      ..invalidate(savingsGoalsProvider)
      ..invalidate(savingEntriesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 700));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktop(context);
    const gap = SizedBox(height: Sp.lg);

    final Widget body;
    if (desktop) {
      body = ListView(
        padding: const EdgeInsets.all(Sp.xl),
        children: [
          const DashboardHeader(),
          gap,
          const QuickActions(),
          const SizedBox(height: Sp.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    const TasksCard().fadeSlideIn(index: 0),
                    gap,
                    const SavingsCard().fadeSlideIn(index: 2),
                  ],
                ),
              ),
              const SizedBox(width: Sp.lg),
              Expanded(
                child: Column(
                  children: [
                    const MoneyCard().fadeSlideIn(index: 1),
                    gap,
                    const BillsCard().fadeSlideIn(index: 3),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Sp.lg),
          children: [
            const DashboardHeader(),
            gap,
            const QuickActions(),
            const SizedBox(height: Sp.xl),
            const TasksCard().fadeSlideIn(index: 0),
            gap,
            const BillsCard().fadeSlideIn(index: 1),
            gap,
            const MoneyCard().fadeSlideIn(index: 2),
            gap,
            const SavingsCard().fadeSlideIn(index: 3),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: body,
        ),
      ),
    );
  }
}
