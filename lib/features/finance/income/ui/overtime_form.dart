import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../../../settings/models/user_settings.dart';
import '../../../settings/providers/settings_providers.dart';
import '../../../settings/ui/salary_settings_form.dart';
import '../../savings/models/savings_parsing.dart' show round2;
import '../models/income_entry.dart';
import '../providers/income_providers.dart';

/// Add ([entry] null) or edit an overtime entry.
Future<void> showOvertimeForm(
  BuildContext context, {
  IncomeEntry? entry,
  DateTime? defaultDate,
}) => showResponsiveDialog(
  context,
  title: entry == null ? 'Add overtime' : 'Edit overtime',
  maxWidth: 480,
  builder: (_) => OvertimeForm(entry: entry, defaultDate: defaultDate),
);

double _multiplierFor(UserSettings s, DayType t) => switch (t) {
  DayType.normal => s.otRateNormal,
  DayType.restDay => s.otRateRestDay,
  DayType.publicHoliday => s.otRateHoliday,
};

String _trim(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class OvertimeForm extends ConsumerStatefulWidget {
  const OvertimeForm({super.key, this.entry, this.defaultDate});
  final IncomeEntry? entry;
  final DateTime? defaultDate;

  @override
  ConsumerState<OvertimeForm> createState() => _OvertimeFormState();
}

class _OvertimeFormState extends ConsumerState<OvertimeForm> {
  final _form = GlobalKey<FormState>();
  late final _hours = TextEditingController(
    text: widget.entry?.hours == null ? '' : _trim(widget.entry!.hours!),
  );
  late final _mult = TextEditingController(
    text: widget.entry?.rateMultiplier == null
        ? ''
        : _trim(widget.entry!.rateMultiplier!),
  );
  late final _note = TextEditingController(text: widget.entry?.note ?? '');
  late DateTime _date = widget.entry?.entryDate ?? _initialDate();
  late DayType _dayType = widget.entry?.dayType ?? DayType.normal;
  bool _busy = false;

  bool get _editing => widget.entry != null;

  DateTime _initialDate() {
    final now = DateTime.now();
    final d = widget.defaultDate;
    return (d != null && !d.isAfter(now)) ? d : now;
  }

  UserSettings get _settings =>
      ref.read(userSettingsProvider).value ?? const UserSettings();

  @override
  void initState() {
    super.initState();
    // New entry: multiplier starts from the day type's setting.
    if (!_editing) _mult.text = _trim(_multiplierFor(_settings, _dayType));
  }

  @override
  void dispose() {
    _hours.dispose();
    _mult.dispose();
    _note.dispose();
    super.dispose();
  }

  double get _h => double.tryParse(_hours.text.trim()) ?? 0;
  double get _m => double.tryParse(_mult.text.trim()) ?? 0;

  /// When editing without touching hours/multiplier, keep the entry's own
  /// rate so changing the note doesn't re-price old overtime.
  double get _rate {
    final e = widget.entry;
    if (e != null && e.hours == _h && e.rateMultiplier == _m && _h * _m > 0) {
      return e.amount / (_h * _m);
    }
    return _settings.otHourlyRate;
  }

  double get _amount => round2(_h * _rate * _m);

  void _setDayType(DayType t) => setState(() {
    _dayType = t;
    _mult.text = _trim(_multiplierFor(_settings, t));
  });

  void _step(double delta) {
    final next = ((_h + delta) * 2).round() / 2;
    setState(() => _hours.text = next < 0.5 ? '0.5' : _trim(next));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year, now.month, now.day),
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
        type: IncomeType.overtime,
        amount: _amount,
        entryDate: _date,
        hours: _h,
        dayType: _dayType,
        rateMultiplier: _m,
        note: _note.text.trim(),
        createdAt: widget.entry?.createdAt,
      );
      _editing ? await notifier.save(draft) : await notifier.create(draft);
      navigator.pop();
    } catch (e) {
      debugPrint('save overtime failed: $e');
      if (mounted) setState(() => _busy = false);
      showSnack(messenger, 'Could not save. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userSettingsProvider); // refresh rate if settings change
    const gap = SizedBox(height: 16);
    final noRate = _rate <= 0;
    return Form(
      key: _form,
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          if (noRate) ...[
            _RateWarning(onOpen: () => showSalarySettings(context)),
            gap,
          ],
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
            controller: _hours,
            autofocus: !_editing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}\.?\d{0,1}')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Hours *',
              suffixText: 'h',
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: '−0.5 h',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => _step(-0.5),
                  ),
                  IconButton(
                    tooltip: '+0.5 h',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => _step(0.5),
                  ),
                ],
              ),
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').trim());
              if (n == null || n <= 0) return 'Enter hours above 0';
              return (n * 2) != (n * 2).roundToDouble()
                  ? 'Use 0.5 hour steps'
                  : null;
            },
          ),
          gap,
          Text('Day type', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in DayType.values)
                ChoiceChip(
                  label: Text(t.label),
                  selected: _dayType == t,
                  onSelected: (_) => _setDayType(t),
                ),
            ],
          ),
          gap,
          TextFormField(
            controller: _mult,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Rate multiplier',
              prefixText: '× ',
              helperText: 'Filled from your settings — editable',
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').trim());
              return (n == null || n <= 0)
                  ? 'Enter a multiplier above 0'
                  : null;
            },
          ),
          gap,
          _Preview(hours: _h, rate: _rate, multiplier: _m, amount: _amount),
          gap,
          TextFormField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_busy || noRate) ? null : _save,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_editing ? 'Save changes' : 'Add overtime'),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.hours,
    required this.rate,
    required this.multiplier,
    required this.amount,
  });
  final double hours, rate, multiplier, amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${_trim(hours)} h × ${formatRm(rate)} × ${_trim(multiplier)} = ${formatRm(amount)}',
        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
      ),
    );
  }
}

class _RateWarning extends StatelessWidget {
  const _RateWarning({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.orange.shade300),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'OT hourly rate is RM 0.00, so overtime would be worth nothing.',
          ),
        ),
        TextButton(onPressed: onOpen, child: const Text('Set rate')),
      ],
    ),
  );
}
