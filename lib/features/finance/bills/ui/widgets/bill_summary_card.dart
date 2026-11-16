import 'package:flutter/material.dart';

import '../../../../../core/utils/money.dart';
import '../../models/bill_status.dart';
import 'bill_tile.dart';
import '../../../../../core/widgets/motion.dart';

/// Total / Paid / Remaining for the month + progress bar.
class BillSummaryCard extends StatelessWidget {
  const BillSummaryCard({super.key, required this.totals});
  final MonthTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primary.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total this month',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 2),
            Text(
              formatRm(totals.total),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            AnimatedBar(
              value: totals.progress,
              minHeight: 8,
              backgroundColor: scheme.surface,
              color: kPaidGreen,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: 'Paid',
                    value: totals.paid,
                    color: kPaidGreen,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: 'Remaining',
                    value: totals.remaining,
                    color: totals.remaining > 0 ? kOverdueRed : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      Text(
        formatRm(value),
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
    ],
  );
}
