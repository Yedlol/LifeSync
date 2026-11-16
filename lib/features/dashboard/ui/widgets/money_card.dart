import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../finance/bills/models/bill_payment.dart' show monthStart;
import '../../../finance/income/ui/income_form.dart';
import '../../../finance/overview/providers/overview_providers.dart';
import '../../../finance/providers/finance_tab_provider.dart';
import 'dash_card.dart';

const _green = Color(0xFF2E7D32);
const _red = Color(0xFFD32F2F);

/// This month's income / left / after unpaid bills (same numbers as the
/// Finance Overview). Tap to open that tab.
class MoneyCard extends ConsumerWidget {
  const MoneyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(monthOverviewFor(monthStart(DateTime.now())));
    final empty = async.value?.isEmpty ?? false;
    return DashCard(
      title: 'Money this month',
      icon: PhosphorIconsRegular.wallet,
      onTap: empty
          ? null
          : () {
              ref.read(financeTabProvider.notifier).set(kTabOverview);
              context.go('/finance');
            },
      child: async.when(
        skipLoadingOnReload: true,
        loading: () => const CardSkeleton(lines: 3),
        error: (_, _) => const CardMessage("Couldn't load your numbers."),
        data: (o) => o.isEmpty
            ? EmptyState(
                compact: true,
                icon: PhosphorIconsRegular.money,
                message: 'Nothing recorded this month yet.',
                actionLabel: 'Add income',
                onAction: () => showIncomeForm(context),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Line('Income', o.income, null),
                  const SizedBox(height: Sp.md),
                  Text(
                    'LEFT THIS MONTH',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    formatRm(o.left),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: o.left >= 0 ? _green : _red,
                    ),
                  ),
                  const SizedBox(height: Sp.sm),
                  _Line(
                    'After unpaid bills',
                    o.afterUnpaid,
                    o.afterUnpaid >= 0 ? _green : _red,
                  ),
                ],
              ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.amount, this.color);
  final String label;
  final double amount;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      Text(
        formatRm(amount),
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
    ],
  );
}
