import '../../bills/models/bill_payment.dart' show dateOnly;
import '../../savings/models/savings_parsing.dart';

enum IncomeType {
  salary('Salary'),
  overtime('Overtime'),
  allowance('Allowance'),
  bonus('Bonus'),
  other('Other');

  const IncomeType(this.label);
  final String label;

  static IncomeType parse(Object? v) => IncomeType.values.firstWhere(
    (t) => t.name == v,
    orElse: () => IncomeType.other,
  );
}

enum DayType {
  normal('Normal', 'normal'),
  restDay('Rest day', 'rest_day'),
  publicHoliday('Public holiday', 'holiday');

  const DayType(this.label, this.dbValue);
  final String label;
  final String dbValue;

  static DayType parse(Object? v) => switch (v) {
    'rest_day' || 'restDay' || 'rest' => DayType.restDay,
    'holiday' || 'public_holiday' || 'publicHoliday' => DayType.publicHoliday,
    _ => DayType.normal,
  };
}

class IncomeEntry {
  const IncomeEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.entryDate,
    this.hours,
    this.dayType,
    this.rateMultiplier,
    this.note = '',
    this.createdAt,
  });

  final String id;
  final IncomeType type;
  final double amount;

  /// Local calendar date.
  final DateTime entryDate;

  /// Overtime only.
  final double? hours;
  final DayType? dayType;
  final double? rateMultiplier;
  final String note;
  final DateTime? createdAt;

  bool get isOvertime => type == IncomeType.overtime;

  factory IncomeEntry.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null;
    final type = IncomeType.parse(json['type']);
    return IncomeEntry(
      id: json['id'] as String,
      type: type,
      amount: toDouble(json['amount']),
      entryDate: parseDbDate(json['entry_date']) ?? created ?? DateTime(2000),
      hours: json['hours'] == null ? null : toDouble(json['hours']),
      dayType: type == IncomeType.overtime
          ? DayType.parse(json['day_type'])
          : null,
      rateMultiplier: json['rate_multiplier'] == null
          ? null
          : toDouble(json['rate_multiplier']),
      note: (json['note'] as String?) ?? '',
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'amount': amount,
    'entry_date': dateOnly(entryDate),
    'hours': isOvertime ? hours : null,
    'day_type': isOvertime ? dayType?.dbValue : null,
    'rate_multiplier': isOvertime ? rateMultiplier : null,
    'note': note.trim().isEmpty ? null : note.trim(),
  };

  IncomeEntry copyWith({
    IncomeType? type,
    double? amount,
    DateTime? entryDate,
    double? hours,
    DayType? dayType,
    double? rateMultiplier,
    String? note,
  }) => IncomeEntry(
    id: id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    entryDate: entryDate ?? this.entryDate,
    hours: hours ?? this.hours,
    dayType: dayType ?? this.dayType,
    rateMultiplier: rateMultiplier ?? this.rateMultiplier,
    note: note ?? this.note,
    createdAt: createdAt,
  );
}
