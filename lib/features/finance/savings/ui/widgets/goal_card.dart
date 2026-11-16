import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

import '../../models/goal_progress.dart';
import 'goal_info.dart';

/// Goal card: info + "+ Add" / "Withdraw". Tap the card for the detail page.
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.progress,
    required this.onTap,
    required this.onAdd,
    required this.onWithdraw,
  });
  final GoalProgress progress;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final color = progress.goal.color;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 5)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GoalInfo(progress: progress),
              const SizedBox(height: 12),
              AddWithdrawButtons(onAdd: onAdd, onWithdraw: onWithdraw),
            ],
          ),
        ),
      ),
    );
  }
}

class AddWithdrawButtons extends StatelessWidget {
  const AddWithdrawButtons({
    super.key,
    required this.onAdd,
    required this.onWithdraw,
  });
  final VoidCallback onAdd;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: onAdd,
          icon: const Icon(PhosphorIconsRegular.plus, size: 18),
          label: const Text('Add'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
          onPressed: onWithdraw,
          icon: const Icon(PhosphorIconsRegular.minus, size: 18),
          label: const Text('Withdraw'),
        ),
      ),
    ],
  );
}
