import 'package:intl/intl.dart';

final _dMMMy = DateFormat('d MMM yyyy');
final _dMMM = DateFormat('d MMM');

/// "16 Nov 2026" (local time).
String formatDate(DateTime d) => _dMMMy.format(d.toLocal());

/// "16 Nov" if this year, else "16 Nov 2026".
String formatShortDate(DateTime d) {
  final local = d.toLocal();
  return local.year == DateTime.now().year
      ? _dMMM.format(local)
      : _dMMMy.format(local);
}

/// End of the picked calendar day (local), so a due date means "by end of day".
DateTime endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);
