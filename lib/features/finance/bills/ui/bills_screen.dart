import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bill_providers.dart';
import 'bill_form.dart';
import 'manage_bills_screen.dart';
import 'mark_paid_sheet.dart';
import 'widgets/bill_summary_card.dart';
import 'widgets/bill_tile.dart';
import 'widgets/month_switcher.dart';

/// Bills tab: month switcher, summary, sorted list.
class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final async = ref.watch(billMonthProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            const SizedBox(height: 4),
            const MonthSwitcher(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                    ),
                    onPressed: () => showBillForm(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add bill'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showManageBills(context),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Manage bills'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _Error(
                  onRetry: () {
                    ref.invalidate(billsProvider);
                    ref.invalidate(billPaymentsProvider);
                  },
                ),
                data: (data) => ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: [
                    BillSummaryCard(totals: data.totals),
                    const SizedBox(height: 12),
                    if (data.entries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No bills for this month.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    for (final e in data.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: BillTile(
                          entry: e,
                          onTap: () => showMarkPaidSheet(
                            context,
                            entry: e,
                            period: month,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        const Text("Couldn't load bills."),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
