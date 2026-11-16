import 'package:flutter/material.dart';

import '../../../../../core/utils/money.dart';
import '../../models/income_month.dart';

/// Basic salary / Overtime / Allowance·Bonus·Other / TOTAL INCOME.
class IncomeSummaryCard extends StatelessWidget {
  const IncomeSummaryCard({super.key, required this.summary});
  final IncomeSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hours = summary.otHours == summary.otHours.roundToDouble()
        ? summary.otHours.toStringAsFixed(0)
        : summary.otHours.toStringAsFixed(1);
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
          children: [
            _Row('Basic salary', formatRm(summary.basic)),
            _Row('Overtime ($hours h)', formatRm(summary.otAmount)),
            _Row('Allowance / Bonus / Other', formatRm(summary.other)),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL INCOME',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  formatRm(summary.total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.grey.shade800)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
