import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bills/ui/widgets/month_switcher.dart';
import '../providers/overview_providers.dart';
import 'widgets/overview_card.dart';

const _green = Color(0xFF2E7D32);
const _red = Color(0xFFD32F2F);

/// Finance tab indexes (see FinanceScreen).
const kTabBills = 1, kTabSavings = 2, kTabIncome = 3;

/// Monthly overview: income, bills, savings and what is left.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthOverviewProvider);
    final tabs = DefaultTabController.maybeOf(context);
    VoidCallback? open(int i) => tabs == null ? null : () => tabs.animateTo(i);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            const SizedBox(height: 4),
            const MonthSwitcher(),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text("Couldn't load the overview."),
                    ],
                  ),
                ),
                data: (o) {
                  final leftColor = o.left >= 0 ? _green : _red;
                  final afterColor = o.afterUnpaid >= 0 ? _green : _red;
                  const gap = SizedBox(height: 12);
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    children: [
                      OverviewCard(
                        label: 'Income',
                        amount: o.income,
                        color: Theme.of(context).colorScheme.primary,
                        icon: Icons.payments_outlined,
                        onTap: open(kTabIncome),
                      ),
                      gap,
                      OverviewCard(
                        label: 'Bills paid',
                        amount: o.billsPaid,
                        color: _green,
                        icon: Icons.check_circle_outline,
                        onTap: open(kTabBills),
                      ),
                      gap,
                      OverviewCard(
                        label: 'Bills still unpaid',
                        amount: o.billsUnpaid,
                        color: o.billsUnpaid > 0 ? _red : Colors.grey,
                        icon: Icons.receipt_long_outlined,
                        onTap: open(kTabBills),
                      ),
                      gap,
                      OverviewCard(
                        label: 'Saved this month',
                        amount: o.saved,
                        color: o.saved < 0 ? _red : _green,
                        icon: Icons.savings_outlined,
                        caption: 'Deposits minus withdrawals',
                        onTap: open(kTabSavings),
                      ),
                      gap,
                      OverviewCard(
                        label: 'LEFT THIS MONTH',
                        amount: o.left,
                        color: leftColor,
                        large: true,
                        caption: 'Income − bills paid − saved',
                      ),
                      gap,
                      OverviewCard(
                        label: 'After unpaid bills',
                        amount: o.afterUnpaid,
                        color: afterColor,
                        caption: 'Left − bills still unpaid',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
