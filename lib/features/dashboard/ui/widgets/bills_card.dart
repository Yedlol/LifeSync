import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/motion.dart';
import '../../../finance/bills/models/bill_payment.dart' show monthStart;
import '../../../finance/bills/models/bill_status.dart';
import '../../../finance/bills/providers/bill_providers.dart';
import '../../../finance/bills/ui/bill_form.dart';
import '../../../finance/bills/ui/mark_paid_sheet.dart';
import '../../../finance/bills/ui/widgets/bill_tile.dart';
import '../../../finance/providers/finance_tab_provider.dart';
import 'dash_card.dart';

const kBillsOnDashboard = 4;

/// This month's bills: unpaid summary, progress, the next few to pay.
class BillsCard extends ConsumerWidget {
  const BillsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = monthStart(DateTime.now());
    final async = ref.watch(billMonthFor(month));
    return DashCard(
      title: 'Bills this month',
      icon: PhosphorIconsRegular.receipt,
      footerLabel: 'View bills',
      onFooter: () {
        ref.read(financeTabProvider.notifier).set(kTabBills);
        context.go('/finance');
      },
      child: async.when(
        skipLoadingOnReload: true,
        loading: () => const CardSkeleton(lines: 4),
        error: (_, _) => const CardMessage("Couldn't load bills."),
        data: (data) => _Body(data: data, month: month),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, required this.month});
  final BillMonth data;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    if (data.entries.isEmpty) {
      return EmptyState(
        compact: true,
        icon: PhosphorIconsRegular.receipt,
        message: 'No bills this month. Enjoy the quiet!',
        actionLabel: 'Add bill',
        onAction: () => showBillForm(context),
      );
    }
    // Entries come sorted: overdue, due soon, unpaid, then paid.
    final unpaid = data.entries
        .where((e) => e.status != BillStatus.paid)
        .toList();
    if (unpaid.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Sp.lg),
        decoration: BoxDecoration(
          color: kPaidGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: const Row(
          children: [
            Icon(PhosphorIconsFill.checkCircle, color: kPaidGreen),
            SizedBox(width: Sp.md),
            Text(
              'All bills paid this month',
              style: TextStyle(fontWeight: FontWeight.w700, color: kPaidGreen),
            ),
          ],
        ),
      );
    }
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${unpaid.length} unpaid · ${formatRm(data.totals.remaining)} remaining',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: Sp.sm),
        AnimatedBar(
          value: data.totals.progress,
          color: kPaidGreen,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        const SizedBox(height: Sp.md),
        for (final e in unpaid.take(kBillsOnDashboard))
          Padding(
            padding: const EdgeInsets.only(bottom: Sp.sm),
            child: _BillRow(entry: e, month: month),
          ),
        if (unpaid.length > kBillsOnDashboard)
          Text(
            '+${unpaid.length - kBillsOnDashboard} more',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.entry, required this.month});
  final BillEntry entry;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(entry.status);
    final text = entry.status == BillStatus.dueSoon
        ? const Color(0xFF9A6200)
        : color;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      padding: const EdgeInsets.only(left: Sp.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.bill.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${formatRm(entry.amount)} · ${statusLabel(entry)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: Sp.md),
              foregroundColor: kPaidGreen,
              side: const BorderSide(color: kPaidGreen),
            ),
            onPressed: () =>
                showMarkPaidSheet(context, entry: entry, period: month),
            child: const Text('Paid'),
          ),
        ],
      ),
    );
  }
}
