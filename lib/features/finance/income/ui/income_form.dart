import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../models/income_entry.dart';
import '../providers/income_providers.dart';

const _types = [
  IncomeType.salary,
  IncomeType.allowance,
  IncomeType.bonus,
  IncomeType.other,
];

/// Add ([entry] null) or edit a non-overtime income entry.
Future<void> showIncomeForm(
  BuildContext context, {
  IncomeEntry? entry,
  DateTime? defaultDate,
}) => showResponsiveDialog(
  context,
  title: entry == null ? 'Add income' : 'Edit income',
  maxWidth: 480,
  builder: (_) => IncomeForm(entry: entry, defaultDate: defaultDate),
);

class IncomeForm extends ConsumerStatefulWidget {
  const IncomeForm({super.key, this.entry, this.defaultDate});
  final IncomeEntry? entry;
  final DateTime? defaultDate;

  @override
  ConsumerState<IncomeForm> createState() => _IncomeFormState();
}

class _IncomeFormState extends ConsumerState<IncomeForm> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.entry == null ? '' : widget.entry!.amount.toStringAsFixed(2),
  );
  late final _note = TextEditingController(text: widget.entry?.note ?? '');
  late IncomeType _type = widget.entry?.type ?? IncomeType.allowance;
  late DateTime _date =
      widget.entry?.entryDate ?? widget.defaultDate ?? DateTime.now();
  bool _busy = false;

  bool get _editing => widget.entry != null;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(incomeProvider.notifier);
    setState(() => _busy = true);
    try {
      final draft = IncomeEntry(
        id: widget.entry?.id ?? '',
        type: _type,
        amount: double.parse(_amount.text.trim()),
        entryDate: _date,
        note: _note.text.trim(),
        createdAt: widget.entry?.createdAt,
      );
      _editing ? await notifier.save(draft) : await notifier.create(draft);
      navigator.pop();
    } catch (e) {
      debugPrint('save income failed: $e');
      if (mounted) setState(() => _busy = false);
      showSnack(messenger, 'Could not save. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Form(
      key: _form,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          DropdownButtonFormField<IncomeType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: [
              for (final t in _types)
                DropdownMenuItem(value: t, child: Text(t.label)),
            ],
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          gap,
          TextFormField(
            controller: _amount,
            autofocus: !_editing,
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
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              child: Text(formatDate(_date)),
            ),
          ),
          gap,
          TextFormField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_editing ? 'Save changes' : 'Add income'),
          ),
        ],
      ),
    );
  }
}
