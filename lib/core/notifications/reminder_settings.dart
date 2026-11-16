import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-device reminder preferences (stored with shared_preferences).
class ReminderSettings {
  const ReminderSettings({
    this.masterOn = false,
    this.tasksOn = true,
    this.billsOn = true,
    this.summaryOn = false,
    this.reminderMinutes = 9 * 60,
    this.summaryMinutes = 8 * 60,
  });

  final bool masterOn;
  final bool tasksOn;
  final bool billsOn;
  final bool summaryOn;

  /// Minutes after midnight (9:00 AM = 540).
  final int reminderMinutes;
  final int summaryMinutes;

  ReminderSettings copyWith({
    bool? masterOn,
    bool? tasksOn,
    bool? billsOn,
    bool? summaryOn,
    int? reminderMinutes,
    int? summaryMinutes,
  }) => ReminderSettings(
    masterOn: masterOn ?? this.masterOn,
    tasksOn: tasksOn ?? this.tasksOn,
    billsOn: billsOn ?? this.billsOn,
    summaryOn: summaryOn ?? this.summaryOn,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    summaryMinutes: summaryMinutes ?? this.summaryMinutes,
  );
}

const _k = 'reminders.';

final reminderSettingsProvider =
    AsyncNotifierProvider<ReminderSettingsNotifier, ReminderSettings>(
      ReminderSettingsNotifier.new,
    );

class ReminderSettingsNotifier extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() async {
    const d = ReminderSettings();
    final p = await SharedPreferences.getInstance();
    return ReminderSettings(
      masterOn: p.getBool('${_k}master') ?? d.masterOn,
      tasksOn: p.getBool('${_k}tasks') ?? d.tasksOn,
      billsOn: p.getBool('${_k}bills') ?? d.billsOn,
      summaryOn: p.getBool('${_k}summary') ?? d.summaryOn,
      reminderMinutes: p.getInt('${_k}reminderMinutes') ?? d.reminderMinutes,
      summaryMinutes: p.getInt('${_k}summaryMinutes') ?? d.summaryMinutes,
    );
  }

  Future<void> save(ReminderSettings s) async {
    state = AsyncData(s);
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setBool('${_k}master', s.masterOn),
      p.setBool('${_k}tasks', s.tasksOn),
      p.setBool('${_k}bills', s.billsOn),
      p.setBool('${_k}summary', s.summaryOn),
      p.setInt('${_k}reminderMinutes', s.reminderMinutes),
      p.setInt('${_k}summaryMinutes', s.summaryMinutes),
    ]);
  }
}
