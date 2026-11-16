import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../../core/widgets/responsive_dialog.dart';
import '../models/savings_goal.dart';
import '../models/savings_parsing.dart';
import '../providers/savings_providers.dart';

/// New ([goal] null) or edit goal: dialog on desktop, full page on phone.
Future<void> showGoalForm(BuildContext context, {SavingsGoal? goal}) =>
    showResponsiveDialog(
      context,
      title: goal == null ? 'New goal' : 'Edit goal',
      maxWidth: 480,
      builder: (_) => GoalForm(goal: goal),
    );

class GoalForm extends ConsumerStatefulWidget {
  const GoalForm({super.key, this.goal});
  final SavingsGoal? goal;

  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late final _target = TextEditingController(
    text: widget.goal == null
        ? ''
        : widget.goal!.targetAmount.toStringAsFixed(2),
  );
  late Color _color = widget.goal?.color ?? kGoalColors.first;
  late DateTime? _deadline = widget.goal?.deadline;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime(now.year, now.month + 1, now.day),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30, 12, 31),
    );
    if (d != null) setState(() => _deadline = d);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(savingsGoalsProvider.notifier);
    setState(() => _saving = true);
    try {
      final draft =
          (widget.goal ??
                  const SavingsGoal(
                    id: '',
                    name: '',
                    targetAmount: 0,
                    color: Color(0xFF1E6FD9),
                  ))
              .copyWith(
                name: _name.text.trim(),
                targetAmount: double.parse(_target.text.trim()),
                color: _color,
                deadline: _deadline,
              );
      widget.goal == null
          ? await notifier.create(draft)
          : await notifier.save(draft);
      navigator.pop();
    } catch (e) {
      debugPrint('save goal failed: $e');
      if (mounted) setState(() => _saving = false);
      showSnack(messenger, 'Could not save goal. Check your connection.');
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
          TextFormField(
            controller: _name,
            autofocus: widget.goal == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Name *'),
            validator: (v) =>
                (v ?? '').trim().isEmpty ? 'Name is required' : null,
          ),
          gap,
          TextFormField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: const InputDecoration(
              labelText: 'Target amount *',
              prefixText: 'RM ',
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').trim());
              return (n == null || n <= 0) ? 'Enter an amount above 0' : null;
            },
          ),
          gap,
          Text('Colour', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in kGoalColors)
                _Swatch(
                  color: c,
                  selected: c == _color,
                  onTap: () => setState(() => _color = c),
                ),
            ],
          ),
          gap,
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: _pickDeadline,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Deadline (optional)',
                prefixIcon: const Icon(Icons.event_outlined),
                suffixIcon: _deadline == null
                    ? null
                    : IconButton(
                        tooltip: 'Clear deadline',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _deadline = null),
                      ),
              ),
              child: Text(
                _deadline == null ? 'No deadline' : formatDate(_deadline!),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.goal == null ? 'Create goal' : 'Save'),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
    onTap: onTap,
    radius: 22,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: 3,
              )
            : null,
      ),
      child: selected
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : null,
    ),
  );
}
