import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/responsive_dialog.dart';
import '../models/saving_entry.dart';
import '../providers/savings_providers.dart';
import 'entry_sheet.dart';
import 'goal_form.dart';
import 'widgets/entry_tile.dart';
import 'widgets/goal_card.dart';
import 'widgets/goal_info.dart';

Future<void> showGoalDetail(BuildContext context, String goalId) =>
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(builder: (_) => GoalDetailScreen(goalId: goalId)),
    );

final _monthLabel = DateFormat('MMMM yyyy');

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  Future<void> _deleteGoal(BuildContext context, WidgetRef ref) async {
    final progress = ref.read(goalProgressProvider(goalId));
    if (progress == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Delete "${progress.goal.name}"?',
      message:
          'This deletes the goal and ALL of its deposit and withdrawal '
          'history. This cannot be undone.',
      confirmLabel: 'Delete goal',
    );
    if (!ok || !context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(savingsGoalsProvider.notifier).delete(progress.goal);
      navigator.pop();
    } catch (e) {
      debugPrint('delete goal failed: $e');
      showSnack(messenger, 'Could not delete goal. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(goalProgressProvider(goalId));
    final loaded = ref.watch(savingsOverviewProvider).hasValue;
    final entries = ref.watch(goalEntriesProvider(goalId));

    if (progress == null) {
      // Deleted (here or on another device): leave once data has loaded.
      if (loaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.of(context).maybePop();
        });
      }
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(progress.goal.name),
        actions: [
          IconButton(
            tooltip: 'Edit goal',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showGoalForm(context, goal: progress.goal),
          ),
          IconButton(
            tooltip: 'Delete goal',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteGoal(context, ref),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: progress.goal.color, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      GoalInfo(progress: progress, large: true),
                      const SizedBox(height: 16),
                      AddWithdrawButtons(
                        onAdd: () => showEntrySheet(
                          context,
                          goalId: goalId,
                          withdraw: false,
                        ),
                        onWithdraw: () => showEntrySheet(
                          context,
                          goalId: goalId,
                          withdraw: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              if (entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No deposits yet. Tap "Add" to record one.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._history(context, ref, entries),
            ],
          ),
        ),
      ),
    );
  }

  /// Entries (already newest first) with a header per month.
  List<Widget> _history(
    BuildContext context,
    WidgetRef ref,
    List<SavingEntry> entries,
  ) {
    final out = <Widget>[];
    DateTime? current;
    for (final e in entries) {
      final month = DateTime(e.entryDate.year, e.entryDate.month);
      if (current != month) {
        current = month;
        out.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
            child: Text(
              _monthLabel.format(month),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.grey.shade700),
            ),
          ),
        );
      }
      out.add(
        EntryTile(
          entry: e,
          onEdit: () => showEntrySheet(
            context,
            goalId: goalId,
            withdraw: e.isWithdrawal,
            entry: e,
          ),
          onDelete: () async {
            final messenger = ScaffoldMessenger.of(context);
            final ok = await confirmDialog(
              context,
              title: 'Delete entry?',
              message: 'This removes the entry and updates the saved total.',
            );
            if (!ok) return;
            try {
              await ref.read(savingEntriesProvider.notifier).delete(e);
            } catch (err) {
              debugPrint('delete entry failed: $err');
              showSnack(messenger, 'Could not delete. Check your connection.');
            }
          },
        ),
      );
    }
    return out;
  }
}
