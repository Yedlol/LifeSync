import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/money.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../../../settings/ui/salary_settings_form.dart';
import '../../bills/providers/bill_providers.dart' show selectedMonthProvider;
import '../../bills/ui/widgets/month_switcher.dart';
import '../models/income_entry.dart';
import '../providers/income_providers.dart';
import 'income_form.dart';
import 'overtime_form.dart';
import 'widgets/income_summary_card.dart';
import 'widgets/income_tiles.dart';
import 'widgets/salary_banner.dart';

/// Income tab: month switcher, salary banner, summary, overtime + other lists.
class IncomeScreen extends ConsumerWidget {
  const IncomeScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    IncomeEntry e,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDialog(
      context,
      title:
          'Delete ${e.isOvertime ? 'overtime' : e.type.label.toLowerCase()}?',
      message: '${formatRm(e.amount)} will be removed from income.',
    );
    if (!ok) return;
    try {
      await ref.read(incomeProvider.notifier).delete(e);
    } catch (err) {
      debugPrint('delete income failed: $err');
      showSnack(messenger, 'Could not delete. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final async = ref.watch(incomeMonthProvider);
    // Default new-entry date to today, or the 1st of a month that isn't now.
    final defaultDate = ref.read(selectedMonthProvider.notifier).isCurrent
        ? DateTime.now()
        : month;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            const SizedBox(height: 4),
            const MonthSwitcher(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                          ),
                          onPressed: () => showOvertimeForm(
                            context,
                            defaultDate: defaultDate,
                          ),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Overtime'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              showIncomeForm(context, defaultDate: defaultDate),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Income'),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Salary settings',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => showSalarySettings(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text("Couldn't load income."),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(incomeProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (data) => ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  children: [
                    const SalaryBanner(),
                    IncomeSummaryCard(summary: data.summary),
                    _Heading('Overtime'),
                    if (data.overtime.isEmpty)
                      const _Empty('No overtime this month.'),
                    for (final e in data.overtime)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: OvertimeTile(
                          entry: e,
                          onEdit: () => showOvertimeForm(context, entry: e),
                          onDelete: () => _delete(context, ref, e),
                        ),
                      ),
                    _Heading('Other income'),
                    if (data.others.isEmpty)
                      const _Empty('No other income this month.'),
                    for (final e in data.others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: IncomeTile(
                          entry: e,
                          onEdit: () => showIncomeForm(context, entry: e),
                          onDelete: () => _delete(context, ref, e),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
  );
}
