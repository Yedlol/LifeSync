import 'package:flutter/material.dart';

import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money.dart';
import '../../models/income_entry.dart';

String _trim(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

class _TileShell extends StatelessWidget {
  const _TileShell({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onEdit,
    required this.onDelete,
  });
  final Widget title;
  final String subtitle;
  final String amount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.only(left: 16, right: 4),
      title: title,
      subtitle: Text(subtitle),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
          PopupMenuButton<String>(
            tooltip: 'Entry actions',
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Overtime row: date, day type chip, hours × multiplier, RM amount.
class OvertimeTile extends StatelessWidget {
  const OvertimeTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final IncomeEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parts = [
      '${_trim(entry.hours ?? 0)} h × ${_trim(entry.rateMultiplier ?? 0)}',
      if (entry.note.isNotEmpty) entry.note,
    ];
    return _TileShell(
      title: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            formatShortDate(entry.entryDate),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              entry.dayType?.label ?? DayType.normal.label,
              style: TextStyle(fontSize: 12, color: scheme.primary),
            ),
          ),
        ],
      ),
      subtitle: parts.join(' · '),
      amount: formatRm(entry.amount),
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }
}

/// Salary / allowance / bonus / other row.
class IncomeTile extends StatelessWidget {
  const IncomeTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final IncomeEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => _TileShell(
    title: Text(
      entry.type.label,
      style: const TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: entry.note.isEmpty
        ? formatShortDate(entry.entryDate)
        : '${formatShortDate(entry.entryDate)} · ${entry.note}',
    amount: formatRm(entry.amount),
    onEdit: onEdit,
    onDelete: onDelete,
  );
}
