const _unset = Object();

/// Stored in `bills.frequency` as 'monthly' / 'one_time'.
enum BillFrequency {
  monthly('monthly', 'Monthly'),
  oneTime('one_time', 'One-time');

  const BillFrequency(this.db, this.label);
  final String db;
  final String label;

  static BillFrequency fromDb(String? v) {
    final s = (v ?? '').toLowerCase().replaceAll(RegExp(r'[\s-]'), '_');
    return s == 'one_time' || s == 'onetime' || s == 'once'
        ? BillFrequency.oneTime
        : BillFrequency.monthly;
  }
}

/// Category presets for the bill form dropdown.
const kBillCategories = <String>[
  'Utilities',
  'Rent',
  'Loan',
  'Phone & Internet',
  'Subscription',
  'Insurance',
  'Credit card',
  'Other',
];

class Bill {
  const Bill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.category = 'Other',
    this.frequency = BillFrequency.monthly,
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final double amount;

  /// 1-31. Clamped to the month's last day when the month is shorter.
  final int dueDay;
  final BillFrequency frequency;
  final bool isActive;
  final DateTime? createdAt;

  bool get isOneTime => frequency == BillFrequency.oneTime;

  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    category: (json['category'] as String?) ?? 'Other',
    amount: _toDouble(json['amount']),
    dueDay: ((json['due_day'] as num?)?.toInt() ?? 1).clamp(1, 31),
    frequency: BillFrequency.fromDb(json['frequency'] as String?),
    isActive: (json['is_active'] as bool?) ?? true,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
        : null,
  );

  /// Writable columns only (id, user_id, created_at are set by the DB).
  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'amount': amount,
    'due_day': dueDay,
    'frequency': frequency.db,
    'is_active': isActive,
  };

  /// Full row as cached offline.
  Map<String, dynamic> toRow() => {
    'id': id,
    ...toJson(),
    'created_at': createdAt?.toUtc().toIso8601String(),
  };

  Bill copyWith({
    String? name,
    String? category,
    double? amount,
    int? dueDay,
    BillFrequency? frequency,
    bool? isActive,
    Object? createdAt = _unset,
  }) => Bill(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    dueDay: dueDay ?? this.dueDay,
    frequency: frequency ?? this.frequency,
    isActive: isActive ?? this.isActive,
    createdAt: identical(createdAt, _unset)
        ? this.createdAt
        : createdAt as DateTime?,
  );
}

double _toDouble(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? 0,
  _ => 0,
};
