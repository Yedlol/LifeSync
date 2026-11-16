import '../../finance/savings/models/savings_parsing.dart' show toDouble;

/// Salary / overtime preferences (one row per user in `user_settings`).
class UserSettings {
  const UserSettings({
    this.basicSalary = 0,
    this.otHourlyRate = 0,
    this.otRateNormal = 1.5,
    this.otRateRestDay = 2.0,
    this.otRateHoliday = 3.0,
    this.normalHoursPerDay = 8,
    this.payDay,
  });

  final double basicSalary;
  final double otHourlyRate;
  final double otRateNormal;
  final double otRateRestDay;
  final double otRateHoliday;
  final double normalHoursPerDay;

  /// Day of month salary arrives (1–31), if set.
  final int? payDay;

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    double num_(String key, double fallback) =>
        json[key] == null ? fallback : toDouble(json[key]);
    final pay = json['pay_day'];
    return UserSettings(
      basicSalary: num_('basic_salary', 0),
      otHourlyRate: num_('ot_hourly_rate', 0),
      otRateNormal: num_('ot_rate_normal', 1.5),
      otRateRestDay: num_('ot_rate_rest_day', 2.0),
      otRateHoliday: num_('ot_rate_holiday', 3.0),
      normalHoursPerDay: num_('normal_hours_per_day', 8),
      payDay: pay is num ? pay.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'basic_salary': basicSalary,
    'ot_hourly_rate': otHourlyRate,
    'ot_rate_normal': otRateNormal,
    'ot_rate_rest_day': otRateRestDay,
    'ot_rate_holiday': otRateHoliday,
    'normal_hours_per_day': normalHoursPerDay,
    'pay_day': payDay,
  };
}
