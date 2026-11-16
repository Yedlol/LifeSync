import '../../bills/models/bill_payment.dart' show dateOnly;
import 'savings_parsing.dart';

/// One deposit (amount > 0) or withdrawal (amount < 0) on a goal.
class SavingEntry {
  const SavingEntry({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.entryDate,
    this.note = '',
    this.createdAt,
  });

  final String id;
  final String goalId;
  final double amount;
  final String note;

  /// Local calendar date of the deposit / withdrawal.
  final DateTime entryDate;
  final DateTime? createdAt;

  bool get isWithdrawal => amount < 0;

  factory SavingEntry.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null;
    return SavingEntry(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      amount: toDouble(json['amount']),
      note: (json['note'] as String?) ?? '',
      entryDate: parseDbDate(json['entry_date']) ?? created ?? DateTime(2000),
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() => {
    'goal_id': goalId,
    'amount': amount,
    'note': note.trim().isEmpty ? null : note.trim(),
    'entry_date': dateOnly(entryDate),
  };

  SavingEntry copyWith({double? amount, String? note, DateTime? entryDate}) =>
      SavingEntry(
        id: id,
        goalId: goalId,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        entryDate: entryDate ?? this.entryDate,
        createdAt: createdAt,
      );
}
