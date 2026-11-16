import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/responsive_dialog.dart';
import '../../../bills/models/bill_status.dart' show daysInMonth;
import '../../../bills/providers/bill_providers.dart'
    show selectedMonthProvider;
import '../../../../settings/providers/settings_providers.dart';
import '../../models/income_entry.dart';
import '../../providers/income_providers.dart';

/// "Salary for November not added — Add RM X": one tap inserts the entry.
class SalaryBanner extends ConsumerStatefulWidget {
  const SalaryBanner({super.key});

  @override
  ConsumerState<SalaryBanner> createState() => _SalaryBannerState();
}

class _SalaryBannerState extends ConsumerState<SalaryBanner> {
  bool _busy = false;

  /// Pay day if set, else today. A month other than the current one has no
  /// "today", so those use the 1st — keeps the entry inside the month shown.
  DateTime _dateFor(DateTime month, int? payDay) {
    if (payDay != null) {
      final last = daysInMonth(month.year, month.month);
      return DateTime(month.year, month.month, payDay > last ? last : payDay);
    }
    final now = DateTime.now();
    return (now.year == month.year && now.month == month.month)
        ? DateTime(now.year, now.month, now.day)
        : month;
  }

  Future<void> _add(double amount, DateTime month, int? payDay) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref
          .read(incomeProvider.notifier)
          .create(
            IncomeEntry(
              id: '',
              type: IncomeType.salary,
              amount: amount,
              entryDate: _dateFor(month, payDay),
            ),
          );
    } catch (e) {
      debugPrint('add salary failed: $e');
      showSnack(messenger, 'Could not add salary. Check your connection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider).value;
    final month = ref.watch(selectedMonthProvider);
    final data = ref.watch(incomeMonthProvider).value;
    if (settings == null ||
        data == null ||
        data.hasSalary ||
        settings.basicSalary <= 0) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Salary for ${DateFormat('MMMM').format(month)} not added',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: scheme.primary,
              ),
              onPressed: _busy
                  ? null
                  : () => _add(settings.basicSalary, month, settings.payDay),
              child: Text('Add ${formatRm(settings.basicSalary)}'),
            ),
          ],
        ),
      ),
    );
  }
}
