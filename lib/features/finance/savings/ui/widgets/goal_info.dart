import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';

import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money.dart';
import '../../models/goal_progress.dart';
import '../../../../../core/widgets/motion.dart';

const kSavedGreen = Color(0xFF2E7D32);
const kLateRed = Color(0xFFD32F2F);

/// Name, progress bar, amounts, remaining, deadline. Shared by the goal card
/// and the goal detail header ([large] = bigger type).
class GoalInfo extends StatelessWidget {
  const GoalInfo({super.key, required this.progress, this.large = false});
  final GoalProgress progress;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = progress.goal;
    final today = DateTime.now();
    final late = progress.isPastDeadline(today);
    final need = progress.monthlyNeeded(today);
    final muted = TextStyle(color: Colors.grey.shade700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: g.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                g.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    (large
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (progress.reached) const _ReachedBadge(),
          ],
        ),
        SizedBox(height: large ? 16 : 12),
        AnimatedBar(
          value: progress.barValue,
          minHeight: large ? 12 : 8,
          backgroundColor: g.color.withValues(alpha: 0.15),
          color: g.color,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${formatRm(progress.saved)} / ${formatRm(progress.target)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: large ? 16 : null,
                ),
              ),
            ),
            Text(
              '${progress.percent}%',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: progress.reached ? kSavedGreen : g.color,
              ),
            ),
          ],
        ),
        if (!progress.reached) ...[
          const SizedBox(height: 4),
          Text('Remaining ${formatRm(progress.remaining)}', style: muted),
        ],
        if (g.deadline != null) ...[
          const SizedBox(height: 4),
          Text(
            late
                ? 'by ${formatDate(g.deadline!)} · past deadline'
                : 'by ${formatDate(g.deadline!)}',
            style: late
                ? const TextStyle(color: kLateRed, fontWeight: FontWeight.w600)
                : muted,
          ),
          if (need != null) Text('Need ${formatRm(need)}/month', style: muted),
        ],
      ],
    );
  }
}

class _ReachedBadge extends StatelessWidget {
  const _ReachedBadge();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(left: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: kSavedGreen.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIconsFill.checkCircle, size: 14, color: kSavedGreen),
        SizedBox(width: 4),
        Text(
          'Goal reached',
          style: TextStyle(
            color: kSavedGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
