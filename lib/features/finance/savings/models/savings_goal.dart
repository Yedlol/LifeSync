import 'dart:ui' show Color;

import '../../bills/models/bill_payment.dart' show dateOnly;
import 'savings_parsing.dart';

const _unset = Object();

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.color,
    this.deadline,
    this.createdAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final Color color;

  /// Local calendar date, or null for no deadline.
  final DateTime? deadline;
  final DateTime? createdAt;

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    targetAmount: toDouble(json['target_amount']),
    color: colorFromDb(json['color']),
    deadline: parseDbDate(json['deadline']),
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null,
  );

  /// Writable columns only (id, user_id, created_at are set by the DB).
  Map<String, dynamic> toJson() => {
    'name': name,
    'target_amount': targetAmount,
    'color': colorToHex(color),
    'deadline': deadline == null ? null : dateOnly(deadline!),
  };

  /// Full row as cached offline.
  Map<String, dynamic> toRow() => {
    'id': id,
    ...toJson(),
    'created_at': createdAt?.toUtc().toIso8601String(),
  };

  SavingsGoal copyWith({
    String? name,
    double? targetAmount,
    Color? color,
    Object? deadline = _unset,
  }) => SavingsGoal(
    id: id,
    name: name ?? this.name,
    targetAmount: targetAmount ?? this.targetAmount,
    color: color ?? this.color,
    deadline: identical(deadline, _unset)
        ? this.deadline
        : deadline as DateTime?,
    createdAt: createdAt,
  );
}
