import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/responsive_dialog.dart';
import '../models/bill.dart';
import '../providers/bill_providers.dart';

const _custom = '__custom__';

/// Add ([bill] null) or edit a bill: dialog on desktop, full page on phone.
Future<void> showBillForm(BuildContext context, {Bill? bill}) =>
    showResponsiveDialog(
      context,
      title: bill == null ? 'Add bill' : 'Edit bill',
      maxWidth: 480,
      builder: (_) => BillForm(bill: bill),
    );

class BillForm extends ConsumerStatefulWidget {
  const BillForm({super.key, this.bill});
  final Bill? bill;

  @override
  ConsumerState<BillForm> createState() => _BillFormState();
}

class _BillFormState extends ConsumerState<BillForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.bill?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.bill == null ? '' : widget.bill!.amount.toStringAsFixed(2),
  );
  late final _dueDay = TextEditingController(
    text: '${widget.bill?.dueDay ?? 1}',
  );
  final _customCategory = TextEditingController();
  late BillFrequency _frequency =
      widget.bill?.frequency ?? BillFrequency.monthly;
  late String _category = widget.bill?.category ?? kBillCategories.first;
  bool _typingCustom = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _dueDay.dispose();
    _customCategory.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(billsProvider.notifier);
    final category = _typingCustom ? _customCategory.text.trim() : _category;
    setState(() => _saving = true);
    try {
      final draft =
          (widget.bill ?? const Bill(id: '', name: '', amount: 0, dueDay: 1))
              .copyWith(
                name: _name.text.trim(),
                category: category,
                amount: double.parse(_amount.text.trim()),
                dueDay: int.parse(_dueDay.text.trim()),
                frequency: _frequency,
              );
      widget.bill == null
          ? await notifier.create(draft)
          : await notifier.save(draft);
      navigator.pop();
    } catch (e) {
      debugPrint('save bill failed: $e');
      if (mounted) setState(() => _saving = false);
      showSnack(messenger, 'Could not save bill. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customs = ref.watch(customCategoriesProvider);
    final options = [...kBillCategories, ...customs];
    if (!_typingCustom && !options.contains(_category)) options.add(_category);
    const gap = SizedBox(height: 16);

    return Form(
      key: _form,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          TextFormField(
            controller: _name,
            autofocus: widget.bill == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name *'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Name is required' : null,
          ),
          gap,
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Amount *',
              prefixText: 'RM ',
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').trim());
              return (n == null || n <= 0) ? 'Enter an amount above 0' : null;
            },
          ),
          gap,
          TextFormField(
            controller: _dueDay,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Due day of month (1–31) *',
              helperText: 'Shorter months use their last day',
            ),
            validator: (v) {
              final n = int.tryParse((v ?? '').trim());
              return (n == null || n < 1 || n > 31)
                  ? 'Enter a day from 1 to 31'
                  : null;
            },
          ),
          gap,
          Text('Frequency', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<BillFrequency>(
            showSelectedIcon: false,
            segments: [
              for (final f in BillFrequency.values)
                ButtonSegment(value: f, label: Text(f.label)),
            ],
            selected: {_frequency},
            onSelectionChanged: (s) => setState(() => _frequency = s.first),
          ),
          gap,
          DropdownButtonFormField<String>(
            key: ValueKey(_typingCustom ? _custom : _category),
            initialValue: _typingCustom ? _custom : _category,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Category'),
            items: [
              for (final c in options)
                DropdownMenuItem(value: c, child: Text(c)),
              const DropdownMenuItem(value: _custom, child: Text('Custom…')),
            ],
            onChanged: (v) => setState(() {
              if (v == _custom) {
                _typingCustom = true;
              } else if (v != null) {
                _typingCustom = false;
                _category = v;
              }
            }),
          ),
          if (_typingCustom) ...[
            gap,
            TextFormField(
              controller: _customCategory,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Custom category'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a category name' : null,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.bill == null ? 'Add bill' : 'Save'),
          ),
        ],
      ),
    );
  }
}
