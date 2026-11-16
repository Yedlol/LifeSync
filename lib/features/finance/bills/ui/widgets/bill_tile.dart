import 'package:flutter/material.dart';

import '../../../../../core/utils/date_format.dart';
import '../../../../../core/utils/money.dart';
import '../../models/bill_status.dart';

const kPaidGreen = Color(0xFF2E7D32);
const kOverdueRed = Color(0xFFD32F2F);
const kSoonAmber = Color(0xFFF2A100);
// Darker amber for text on a light chip (contrast).
const _kSoonAmberText = Color(0xFF9A6200);

Color statusColor(BillStatus s) => switch (s) {
  BillStatus.paid => kPaidGreen,
  BillStatus.dueSoon => kSoonAmber,
  BillStatus.overdue || BillStatus.unpaid => kOverdueRed,
};

/// Chip text, e.g. "Paid 5 Nov", "Overdue", "Due in 2 days", "Due 28 Nov".
String statusLabel(BillEntry e) => switch (e.status) {
  BillStatus.paid => 'Paid ${_dMMM(e.payment!.paidAt)}',
  BillStatus.overdue => 'Overdue',
  BillStatus.dueSoon => switch (e.daysUntilDue) {
    0 => 'Due today',
    1 => 'Due in 1 day',
    final n => 'Due in $n days',
  },
  BillStatus.unpaid => 'Due ${_dMMM(e.dueDate)}',
};

String _dMMM(DateTime d) => formatShortDate(d);

class BillTile extends StatelessWidget {
  const BillTile({super.key, required this.entry, required this.onTap});
  final BillEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = statusColor(entry.status);
    final chipText = entry.status == BillStatus.dueSoon
        ? _kSoonAmberText
        : color;
    final grey = Colors.grey.shade600;
    final bill = entry.bill;
    final showDue =
        entry.status == BillStatus.overdue ||
        entry.status == BillStatus.dueSoon;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      showDue
                          ? '${bill.category} · due ${_dMMM(entry.dueDate)}'
                          : bill.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRm(entry.amount),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel(entry),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: chipText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
