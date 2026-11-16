import 'package:intl/intl.dart';

final _amount = NumberFormat('#,##0.00', 'en_US');

/// "RM 1,234.50"
String formatRm(num value) => 'RM ${_amount.format(value)}';
