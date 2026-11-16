import 'dart:ui' show Color;

/// 8 preset goal colours (first one is the app primary blue).
const kGoalColors = <Color>[
  Color(0xFF1E6FD9), // blue
  Color(0xFF2E7D32), // green
  Color(0xFFF57C00), // orange
  Color(0xFF8E24AA), // purple
  Color(0xFFD81B60), // pink
  Color(0xFF00897B), // teal
  Color(0xFFE53935), // red
  Color(0xFF546E7A), // slate
];

double toDouble(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? 0,
  _ => 0,
};

/// Date column ("2026-11-16", extra time part ignored) -> local date.
DateTime? parseDbDate(Object? v) {
  if (v is! String || v.length < 10) return null;
  final y = int.tryParse(v.substring(0, 4));
  final m = int.tryParse(v.substring(5, 7));
  final d = int.tryParse(v.substring(8, 10));
  return (y == null || m == null || d == null) ? null : DateTime(y, m, d);
}

/// "#RRGGBB"
String colorToHex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Accepts "#RRGGBB" / "RRGGBB" / "#AARRGGBB" or a numeric value.
Color colorFromDb(Object? v) {
  if (v is num) return Color(0xFF000000 | (v.toInt() & 0xFFFFFF));
  if (v is String) {
    final hex = v.trim().replaceFirst('#', '');
    final n = int.tryParse(hex, radix: 16);
    if (n != null && (hex.length == 6 || hex.length == 8)) {
      return Color(0xFF000000 | (n & 0xFFFFFF));
    }
  }
  return kGoalColors.first;
}

/// Round to cents so sums of 2-decimal amounts don't drift.
double round2(double v) => (v * 100).roundToDouble() / 100;
