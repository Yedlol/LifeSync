import 'package:flutter/material.dart';

import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money.dart';
import '../../models/saving_entry.dart';
import 'goal_info.dart';

/// One history row: date, +RM / −RM, note, edit/delete menu.
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });
  final SavingEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final out = entry.isWithdrawal;
    final color = out ? kLateRed : kSavedGreen;
    return Card(
      margin: const EdgeInsets.only(top: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),
        title: Text(
          '${out ? '−' : '+'}${formatRm(entry.amount.abs())}',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          entry.note.isEmpty
              ? formatDate(entry.entryDate)
              : '${formatDate(entry.entryDate)} · ${entry.note}',
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Entry actions',
          onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
