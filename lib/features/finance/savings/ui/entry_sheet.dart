import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../models/saving_entry.dart';
import '../providers/savings_providers.dart';
import '../../../../core/utils/haptics.dart';

/// Bottom sheet to add a deposit / withdrawal, or edit [entry] (its sign
/// decides whether it is shown as a deposit or a withdrawal).
Future<void> showEntrySheet(
  BuildContext context, {
  required String goalId,
  required bool withdraw,
  SavingEntry? entry,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 480),
  builder: (_) => _EntrySheet(goalId: goalId, withdraw: withdraw, entry: entry),
);

class _EntrySheet extends ConsumerStatefulWidget {
  const _EntrySheet({required this.goalId, required this.withdraw, this.entry});
  final String goalId;
  final bool withdraw;
  final SavingEntry? entry;

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  final _form = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: widget.entry == null
        ? ''
        : widget.entry!.amount.abs().toStringAsFixed(2),
  );
  late final _note = TextEditingController(text: widget.entry?.note ?? '');
  late DateTime _date = widget.entry?.entryDate ?? DateTime.now();
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
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (d != null) setState(() => _date = d);
  }

  /// Balance after this change must not go below zero.
  String? _validate(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return 'Enter an amount above 0';
    final saved = ref.read(goalProgressProvider(widget.goalId))?.saved ?? 0;
    final available = saved - (widget.entry?.amount ?? 0);
    final signed = widget.withdraw ? -n : n;
    if (available + signed < -0.004) {
      return widget.withdraw
          ? 'Can\'t withdraw more than ${formatRm(available.clamp(0, double.infinity))} saved'
          : 'This would make the saved balance negative';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(savingEntriesProvider.notifier);
    final n = double.parse(_amount.text.trim());
    final signed = widget.withdraw ? -n : n;
    setState(() => _busy = true);
    try {
      if (_editing) {
        await notifier.save(
          widget.entry!.copyWith(
            amount: signed,
            note: _note.text.trim(),
            entryDate: _date,
          ),
        );
        navigator.pop();
        return;
      }
      final saved = await notifier.add(
        SavingEntry(
          id: '',
          goalId: widget.goalId,
          amount: signed,
          note: _note.text.trim(),
          entryDate: _date,
        ),
      );
      if (!widget.withdraw) hapticSuccess();
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '${widget.withdraw ? 'Withdrew' : 'Added'} ${formatRm(n)}',
            ),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => notifier.delete(saved).catchError((Object e) {
                debugPrint('undo entry failed: $e');
                showSnack(messenger, 'Could not undo. Check your connection.');
              }),
            ),
          ),
        );
    } catch (e) {
      debugPrint('save entry failed: $e');
      if (mounted) setState(() => _busy = false);
      showSnack(messenger, 'Could not save. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(goalProgressProvider(widget.goalId));
    final verb = widget.withdraw ? 'Withdraw' : 'Add';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        0,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editing
                    ? 'Edit ${widget.withdraw ? 'withdrawal' : 'deposit'}'
                    : widget.withdraw
                    ? 'Withdraw from goal'
                    : 'Add to goal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (progress != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${progress.goal.name} · saved ${formatRm(progress.saved)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount *',
                  prefixText: 'RM ',
                ),
                validator: _validate,
              ),
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(PhosphorIconsRegular.calendarBlank),
                  ),
                  child: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_editing ? 'Save changes' : verb),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
