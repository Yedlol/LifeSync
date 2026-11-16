import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../../../finance/bills/models/bill_payment.dart' show monthStart;
import '../../../finance/bills/models/bill_status.dart';
import '../../../finance/bills/providers/bill_providers.dart';
import '../../../finance/bills/ui/mark_paid_sheet.dart';
import '../../../finance/bills/ui/widgets/bill_tile.dart';
import '../../../finance/income/ui/overtime_form.dart';
import '../../../finance/savings/models/goal_progress.dart';
import '../../../finance/savings/providers/savings_providers.dart';
import '../../../finance/savings/ui/entry_sheet.dart';
import '../../../finance/savings/ui/goal_form.dart';
import '../../../tasks/providers/board_providers.dart';
import '../../../tasks/ui/task_form.dart';

/// + Task, + Overtime, + Saving, Pay a bill — straight into the existing forms.
class QuickActions extends ConsumerWidget {
  const QuickActions({super.key});

  Future<void> _saving(BuildContext context, WidgetRef ref) async {
    final goals = ref.read(savingsOverviewProvider).value?.goals;
    if (goals == null) return;
    if (goals.isEmpty) {
      showSnack(
        ScaffoldMessenger.of(context),
        'Create a savings goal first, then you can add to it.',
      );
      await showGoalForm(context);
      return;
    }
    var goal = goals.first;
    if (goals.length > 1) {
      final picked = await _pick<GoalProgress>(
        context,
        title: 'Add to which goal?',
        items: goals,
        label: (g) => g.goal.name,
        subtitle: (g) => '${formatRm(g.saved)} / ${formatRm(g.target)}',
      );
      if (picked == null || !context.mounted) return;
      goal = picked;
    }
    if (context.mounted) {
      await showEntrySheet(context, goalId: goal.goal.id, withdraw: false);
    }
  }

  Future<void> _payBill(BuildContext context, WidgetRef ref) async {
    final month = monthStart(DateTime.now());
    final entries = ref.read(billMonthFor(month)).value?.entries;
    if (entries == null) return;
    final unpaid = entries.where((e) => e.status != BillStatus.paid).toList();
    if (unpaid.isEmpty) {
      showSnack(ScaffoldMessenger.of(context), 'All bills paid this month.');
      return;
    }
    final picked = await _pick<BillEntry>(
      context,
      title: 'Pay which bill?',
      items: unpaid,
      label: (e) => e.bill.name,
      subtitle: (e) => '${formatRm(e.amount)} · ${statusLabel(e)}',
      color: (e) => statusColor(e.status),
    );
    if (picked != null && context.mounted) {
      await showMarkPaidSheet(context, entry: picked, period: month);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget button(IconData icon, String label, VoidCallback onTap) =>
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: Sp.lg),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
        );

    return Wrap(
      spacing: Sp.sm,
      runSpacing: Sp.sm,
      children: [
        button(
          PhosphorIconsRegular.plus,
          'Task',
          () => showTaskForm(
            context,
            initialProjectId: ref.read(taskFilterProvider).projectId,
          ),
        ),
        button(
          PhosphorIconsRegular.plus,
          'Overtime',
          () => showOvertimeForm(context, defaultDate: DateTime.now()),
        ),
        button(
          PhosphorIconsRegular.plus,
          'Saving',
          () => _saving(context, ref),
        ),
        button(
          PhosphorIconsRegular.checkCircle,
          'Pay a bill',
          () => _payBill(context, ref),
        ),
      ],
    );
  }
}

/// Bottom-sheet list; returns the tapped item.
Future<T?> _pick<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
  required String Function(T) subtitle,
  Color Function(T)? color,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  constraints: const BoxConstraints(maxWidth: 480),
  builder: (ctx) => SafeArea(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Sp.xl, 0, Sp.xl, Sp.sm),
            child: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in items)
                  ListTile(
                    leading: color == null
                        ? null
                        : Icon(
                            PhosphorIconsFill.circle,
                            size: 12,
                            color: color(item),
                          ),
                    title: Text(label(item)),
                    subtitle: Text(subtitle(item)),
                    onTap: () => Navigator.of(ctx).pop(item),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
