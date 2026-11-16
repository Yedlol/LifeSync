import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_dialog.dart';
import '../models/user_settings.dart';
import '../providers/settings_providers.dart';

/// Salary settings in a dialog (desktop) / full page (phone).
Future<void> showSalarySettings(BuildContext context) => showResponsiveDialog(
  context,
  title: 'Salary settings',
  maxWidth: 480,
  builder: (ctx) => SalarySettingsForm(onSaved: () => Navigator.of(ctx).pop()),
);

/// Basic salary, OT rates, hours per day, pay day. Loads the live settings.
class SalarySettingsForm extends ConsumerWidget {
  const SalarySettingsForm({super.key, this.onSaved});
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userSettingsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text("Couldn't load settings. Check your connection."),
      ),
      data: (s) => _Fields(initial: s, onSaved: onSaved),
    );
  }
}

final _moneyInput = FilteringTextInputFormatter.allow(
  RegExp(r'^\d*\.?\d{0,2}'),
);
const _decimal = TextInputType.numberWithOptions(decimal: true);

class _Fields extends ConsumerStatefulWidget {
  const _Fields({required this.initial, this.onSaved});
  final UserSettings initial;
  final VoidCallback? onSaved;

  @override
  ConsumerState<_Fields> createState() => _FieldsState();
}

class _FieldsState extends ConsumerState<_Fields> {
  final _form = GlobalKey<FormState>();
  late final _basic = TextEditingController(
    text: _fmt(widget.initial.basicSalary),
  );
  late final _rate = TextEditingController(
    text: _fmt(widget.initial.otHourlyRate),
  );
  late final _hours = TextEditingController(
    text: _fmt(widget.initial.normalHoursPerDay),
  );
  late final _normal = TextEditingController(
    text: _fmt(widget.initial.otRateNormal),
  );
  late final _rest = TextEditingController(
    text: _fmt(widget.initial.otRateRestDay),
  );
  late final _holiday = TextEditingController(
    text: _fmt(widget.initial.otRateHoliday),
  );
  late final _payDay = TextEditingController(
    text: widget.initial.payDay?.toString() ?? '',
  );
  bool _busy = false;

  /// "3000" -> "3000.00"; whole-number settings like 8 stay compact.
  static String _fmt(double v) => v == v.roundToDouble() && v < 100
      ? v.toStringAsFixed(1)
      : v.toStringAsFixed(2);

  @override
  void dispose() {
    for (final c in [
      _basic,
      _rate,
      _hours,
      _normal,
      _rest,
      _holiday,
      _payDay,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _n(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _calculate() {
    final basic = _n(_basic), hours = _n(_hours);
    if (basic <= 0 || hours <= 0) {
      showSnack(
        ScaffoldMessenger.of(context),
        'Enter basic salary and normal hours per day first.',
      );
      return;
    }
    setState(() => _rate.text = (basic / 26 / hours).toStringAsFixed(2));
  }

  String? _positive(String? v) {
    final n = double.tryParse((v ?? '').trim());
    return (n == null || n <= 0) ? 'Enter a number above 0' : null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final onSaved = widget.onSaved;
    setState(() => _busy = true);
    try {
      await ref
          .read(userSettingsProvider.notifier)
          .save(
            UserSettings(
              basicSalary: _n(_basic),
              otHourlyRate: _n(_rate),
              otRateNormal: _n(_normal),
              otRateRestDay: _n(_rest),
              otRateHoliday: _n(_holiday),
              normalHoursPerDay: _n(_hours),
              payDay: int.tryParse(_payDay.text.trim()),
            ),
          );
      if (mounted) setState(() => _busy = false);
      showSnack(messenger, 'Salary settings saved');
      onSaved?.call();
    } catch (e) {
      debugPrint('save settings failed: $e');
      if (mounted) setState(() => _busy = false);
      showSnack(messenger, 'Could not save. Check your connection.');
    }
  }

  Widget _money(
    TextEditingController c,
    String label, {
    String? prefix = 'RM ',
    String? helper,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
  }) => TextFormField(
    controller: c,
    keyboardType: _decimal,
    inputFormatters: formatters ?? [_moneyInput],
    decoration: InputDecoration(
      labelText: label,
      prefixText: prefix,
      helperText: helper,
    ),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Form(
      key: _form,
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          _money(
            _basic,
            'Basic salary (monthly)',
            validator: (v) => double.tryParse((v ?? '').trim()) == null
                ? 'Enter an amount'
                : null,
          ),
          gap,
          _money(
            _hours,
            'Normal hours per day',
            prefix: null,
            validator: (v) {
              final n = double.tryParse((v ?? '').trim());
              return (n == null || n <= 0 || n > 24)
                  ? 'Enter 0–24 hours'
                  : null;
            },
          ),
          gap,
          _money(
            _rate,
            'OT hourly rate',
            helper: 'Editable — or calculate from basic salary',
            validator: (v) => double.tryParse((v ?? '').trim()) == null
                ? 'Enter an amount'
                : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Calculate hourly rate'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Basic salary ÷ 26 days ÷ normal hours per day',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          gap,
          Text('OT multipliers', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _money(
                  _normal,
                  'Normal',
                  prefix: '×',
                  validator: _positive,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _money(
                  _rest,
                  'Rest day',
                  prefix: '×',
                  validator: _positive,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _money(
                  _holiday,
                  'Holiday',
                  prefix: '×',
                  validator: _positive,
                ),
              ),
            ],
          ),
          gap,
          TextFormField(
            controller: _payDay,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Pay day (optional)',
              helperText:
                  'Day of month 1–31; used as the date for salary entries',
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return null;
              final n = int.tryParse(t);
              return (n == null || n < 1 || n > 31)
                  ? 'Enter a day from 1 to 31'
                  : null;
            },
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
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
