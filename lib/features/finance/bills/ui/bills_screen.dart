import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/bill_providers.dart';
import 'bill_form.dart';
import 'manage_bills_screen.dart';
import 'mark_paid_sheet.dart';
import 'widgets/bill_summary_card.dart';
import 'widgets/bill_tile.dart';
import 'widgets/month_switcher.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../core/widgets/skeletons.dart';
import '../../../../core/widgets/swipe_actions.dart';

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
                    icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                    label: const Text('Add bill'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showManageBills(context),
                    icon: const Icon(PhosphorIconsRegular.sliders, size: 18),
                    label: const Text('Manage bills'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () => const ListSkeleton(),
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
                      EmptyState(
                        icon: PhosphorIconsRegular.receipt,
                        message: 'No bills this month. Enjoy the quiet!',
                        actionLabel: 'Add bill',
                        onAction: () => showBillForm(context),
                      ),
                    for (final (i, e) in data.entries.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SwipeActions(
                          actions: [
                            SwipeAction(
                              label: e.payment == null
                                  ? 'Mark paid'
                                  : 'Payment',
                              icon: PhosphorIconsRegular.checkCircle,
                              color: kPaidGreen,
                              onPressed: () => showMarkPaidSheet(
                                context,
                                entry: e,
                                period: month,
                              ),
                            ),
                            SwipeAction(
                              label: 'Edit',
                              icon: PhosphorIconsRegular.pencilSimple,
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () =>
                                  showBillForm(context, bill: e.bill),
                            ),
                          ],
                          child: BillTile(
                            entry: e,
                            onTap: () => showMarkPaidSheet(
                              context,
                              entry: e,
                              period: month,
                            ),
                          ),
                        ).fadeSlideIn(index: i),
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
        const Icon(
          PhosphorIconsRegular.cloudSlash,
          size: 48,
          color: Colors.grey,
        ),
        const SizedBox(height: 12),
        const Text("Couldn't load bills."),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
