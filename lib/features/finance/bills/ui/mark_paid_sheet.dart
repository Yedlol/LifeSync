import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../models/bill_status.dart';
import '../providers/bill_providers.dart';

/// "Mark as paid" (unpaid bill) or edit payment / "Mark as unpaid" (paid bill).
Future<void> showMarkPaidSheet(
  BuildContext context, {
  required BillEntry entry,
  required DateTime period,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 480),
  builder: (_) => _MarkPaidSheet(entry: entry, period: period),
);

class _MarkPaidSheet extends ConsumerStatefulWidget {
  const _MarkPaidSheet({required this.entry, required this.period});
  final BillEntry entry;
  final DateTime period;

  @override
  ConsumerState<_MarkPaidSheet> createState() => _MarkPaidSheetState();
}

class _MarkPaidSheetState extends ConsumerState<_MarkPaidSheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.entry.amount.toStringAsFixed(2),
  );
  late DateTime _paidAt = widget.entry.payment?.paidAt ?? DateTime.now();
  bool _busy = false;

  bool get _editing => widget.entry.payment != null;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d != null) setState(() => _paidAt = d);
  }

  Future<void> _run(Future<void> Function() action, String error) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      navigator.pop();
    } catch (e) {
      debugPrint('bill payment failed: $e');
      if (mounted) setState(() => _busy = false);
      showSnack(messenger, error);
    }
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final amount = double.parse(_amount.text.trim());
    _run(
      () => ref
          .read(billPaymentsProvider.notifier)
          .markPaid(
            billId: widget.entry.bill.id,
            period: widget.period,
            amountPaid: amount,
            paidAt: _paidAt,
          ),
      'Could not save payment. Check your connection.',
    );
  }

  void _unpaid() => _run(
    () => ref
        .read(billPaymentsProvider.notifier)
        .markUnpaid(widget.entry.payment!),
    'Could not mark as unpaid. Check your connection.',
  );

  @override
  Widget build(BuildContext context) {
    final bill = widget.entry.bill;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _editing ? 'Edit payment' : 'Mark as paid',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${bill.name} · due ${formatDate(widget.entry.dueDate)}'
              '${_editing ? '' : ' · ${formatRm(bill.amount)}'}',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              autofocus: !_editing,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount paid',
                prefixText: 'RM ',
              ),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return (n == null || n <= 0) ? 'Enter an amount above 0' : null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date paid',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(formatDate(_paidAt)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_editing ? 'Save changes' : 'Mark as paid'),
            ),
            if (_editing)
              TextButton(
                onPressed: _busy ? null : _unpaid,
                child: const Text('Mark as unpaid'),
              ),
          ],
        ),
      ),
    );
  }
}
