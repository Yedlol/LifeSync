import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/money.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../models/bill.dart';
import '../providers/bill_providers.dart';
import 'bill_form.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/skeletons.dart';

Future<void> showManageBills(BuildContext context) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => const ManageBillsScreen()));

/// Every bill (active or not): edit, activate/deactivate, delete.
class ManageBillsScreen extends ConsumerWidget {
  const ManageBillsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, Bill b) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(billsProvider.notifier);
    final ok = await confirmDialog(
      context,
      title: 'Delete "${b.name}"?',
      message:
          'This also deletes its payment history. '
          "If you just don't want to see it any more, deactivate it instead.",
    );
    if (!ok) return;
    try {
      await notifier.delete(b);
    } catch (e) {
      debugPrint('delete bill failed: $e');
      showSnack(messenger, 'Could not delete bill. It has been restored.');
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    Bill b,
    bool active,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(billsProvider.notifier).setActive(b, active);
    } catch (e) {
      debugPrint('toggle bill failed: $e');
      showSnack(messenger, 'Could not update bill.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(billsProvider);
    final bills = [...(async.value ?? const <Bill>[])]
      ..sort((a, b) {
        if (a.isActive != b.isActive) return a.isActive ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage bills'),
        actions: [
          IconButton(
            tooltip: 'Add bill',
            icon: const Icon(PhosphorIconsRegular.plus),
            onPressed: () => showBillForm(context),
          ),
        ],
      ),
      body: async.isLoading && bills.isEmpty
          ? const ListSkeleton()
          : bills.isEmpty
          ? EmptyState(
              icon: PhosphorIconsRegular.receipt,
              message: 'No bills yet. Add your first one to track it.',
              actionLabel: 'Add bill',
              onAction: () => showBillForm(context),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: bills.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final b = bills[i];
                    return _ManageTile(
                      bill: b,
                      onEdit: () => showBillForm(context, bill: b),
                      onToggle: (v) => _toggle(context, ref, b, v),
                      onDelete: () => _delete(context, ref, b),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _ManageTile extends StatelessWidget {
  const _ManageTile({
    required this.bill,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final Bill bill;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dim = !bill.isActive;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onEdit,
        title: Text(
          bill.name,
          style: TextStyle(color: dim ? Colors.black45 : null),
        ),
        subtitle: Text(
          '${bill.category} · ${formatRm(bill.amount)} · '
          '${bill.isOneTime ? 'One-time' : 'Monthly'}, day ${bill.dueDay}'
          '${dim ? ' · Inactive' : ''}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: bill.isActive, onChanged: onToggle),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(PhosphorIconsRegular.pencilSimple),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(PhosphorIconsRegular.trash),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
