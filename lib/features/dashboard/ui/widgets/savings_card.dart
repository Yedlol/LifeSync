import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/motion.dart';
import '../../../finance/providers/finance_tab_provider.dart';
import '../../../finance/savings/models/goal_progress.dart';
import '../../../finance/savings/providers/savings_providers.dart';
import '../../../finance/savings/ui/goal_detail_screen.dart';
import '../../../finance/savings/ui/goal_form.dart';
import 'dash_card.dart';

const kGoalsOnDashboard = 3;

/// Total saved + the top goals (closest deadline first, reached last).
class SavingsCard extends ConsumerWidget {
  const SavingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savingsOverviewProvider);
    return DashCard(
      title: 'Savings',
      icon: PhosphorIconsRegular.piggyBank,
      footerLabel: 'View savings',
      onFooter: () {
        ref.read(financeTabProvider.notifier).set(kTabSavings);
        context.go('/finance');
      },
      child: async.when(
        skipLoadingOnReload: true,
        loading: () => const CardSkeleton(lines: 4),
        error: (_, _) => const CardMessage("Couldn't load savings."),
        data: (data) => data.goals.isEmpty
            ? EmptyState(
                compact: true,
                icon: PhosphorIconsRegular.piggyBank,
                message: 'No savings goals yet. Start with one you love.',
                actionLabel: 'New goal',
                onAction: () => showGoalForm(context),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total saved',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    formatRm(data.totals.saved),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: Sp.md),
                  for (final p in data.goals.take(kGoalsOnDashboard))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Sp.md),
                      child: _GoalRow(progress: p),
                    ),
                ],
              ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.progress});
  final GoalProgress progress;

  @override
  Widget build(BuildContext context) {
    final g = progress.goal;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => showGoalDetail(context, g.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  g.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${progress.percent}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: progress.reached ? const Color(0xFF2E7D32) : g.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: Sp.xs + 2),
          AnimatedBar(
            value: progress.barValue,
            color: g.color,
            backgroundColor: g.color.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}
