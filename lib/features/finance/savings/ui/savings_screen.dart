import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/savings_providers.dart';
import 'entry_sheet.dart';
import 'goal_detail_screen.dart';
import 'goal_form.dart';
import 'widgets/goal_card.dart';
import 'widgets/savings_summary_card.dart';

/// Savings tab: summary, goal cards, "+ New goal".
class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(savingsOverviewProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Error(
            onRetry: () {
              ref.invalidate(savingsGoalsProvider);
              ref.invalidate(savingEntriesProvider);
            },
          ),
          data: (data) => ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              if (data.goals.isNotEmpty) ...[
                SavingsSummaryCard(totals: data.totals),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => showGoalForm(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New goal'),
                ),
              ),
              const SizedBox(height: 12),
              if (data.goals.isEmpty)
                const _EmptyState()
              else
                LayoutBuilder(
                  builder: (context, box) {
                    final cols = box.maxWidth >= 1000
                        ? 3
                        : box.maxWidth >= 700
                        ? 2
                        : 1;
                    const gap = 12.0;
                    final w = (box.maxWidth - gap * (cols - 1)) / cols;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final p in data.goals)
                          SizedBox(
                            width: w,
                            child: GoalCard(
                              progress: p,
                              onTap: () => showGoalDetail(context, p.goal.id),
                              onAdd: () => showEntrySheet(
                                context,
                                goalId: p.goal.id,
                                withdraw: false,
                              ),
                              onWithdraw: () => showEntrySheet(
                                context,
                                goalId: p.goal.id,
                                withdraw: true,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        Icon(
          Icons.savings_outlined,
          size: 56,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        const Text(
          'No savings goals yet.\nTap "New goal" to start saving for something.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
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
        const Text("Couldn't load savings."),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
