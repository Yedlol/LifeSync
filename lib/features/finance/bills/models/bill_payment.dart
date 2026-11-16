/// First day of [d]'s month (local time) — the key a payment is filed under.
DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

/// "yyyy-MM-dd" for a date column (no time zone involved).
String dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class BillPayment {
  const BillPayment({
    required this.id,
    required this.billId,
    required this.period,
    required this.amountPaid,
    required this.paidAt,
  });

  final String id;
  final String billId;

  /// First day of the month this payment covers (local date).
  final DateTime period;
  final double amountPaid;

  /// Day the payment was made (local).
  final DateTime paidAt;

  factory BillPayment.fromJson(Map<String, dynamic> json) {
    final period = _parseDate(json['period']) ?? DateTime(2000);
    return BillPayment(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      period: monthStart(period),
      amountPaid: switch (json['amount_paid']) {
        num n => n.toDouble(),
        String s => double.tryParse(s) ?? 0,
        _ => 0,
      },
      paidAt: _parseTimestamp(json['paid_at']) ?? period,
    );
  }
}

/// Date-only value ("2026-11-01") -> local DateTime, ignoring any time part.
DateTime? _parseDate(Object? v) {
  if (v is! String || v.length < 10) return null;
  final y = int.tryParse(v.substring(0, 4));
  final m = int.tryParse(v.substring(5, 7));
  final d = int.tryParse(v.substring(8, 10));
  return (y == null || m == null || d == null) ? null : DateTime(y, m, d);
}

/// Works for both a date and a timestamptz column.
DateTime? _parseTimestamp(Object? v) {
  if (v is! String) return null;
  // Plain date: keep as that local day.
  if (v.length == 10) return _parseDate(v);
  final t = DateTime.tryParse(v);
  if (t == null) return null;
  final local = t.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// Value sent to `paid_at`: noon local time on the paid day, so the calendar
/// day survives UTC conversion (and a date column) in any time zone.
String paidAtValue(DateTime day) =>
    DateTime(day.year, day.month, day.day, 12).toUtc().toIso8601String();
