import 'package:flutter/material.dart';

import '../../../../../core/utils/money.dart';
import '../../models/goal_progress.dart';

/// Total saved / total target / overall % across all goals.
class SavingsSummaryCard extends StatelessWidget {
  const SavingsSummaryCard({super.key, required this.totals});
  final SavingsTotals totals;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
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
            Text('Total saved', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(
              formatRm(totals.saved),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: totals.barValue,
                minHeight: 8,
                backgroundColor: Colors.white,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: 'Total target',
                    value: formatRm(totals.target),
                  ),
                ),
                Expanded(
                  child: _Figure(label: 'Overall', value: '${totals.percent}%'),
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
  const _Figure({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}
