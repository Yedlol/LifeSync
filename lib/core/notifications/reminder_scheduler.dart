import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/finance/bills/providers/bill_providers.dart';
import '../../features/tasks/providers/tasks_notifier.dart';
import 'notification_service.dart';
import 'reminder_planner.dart';
import 'reminder_settings.dart';

const kRescheduleDebounce = Duration(seconds: 2);

/// Re-plans and reschedules all reminders shortly after tasks, bills,
/// payments or the reminder settings change (and once at start-up).
final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) {
  final s = ReminderScheduler(ref);
  ref.onDispose(s.dispose);
  ref.listen(tasksProvider, (_, _) => s.request());
  ref.listen(billsProvider, (_, _) => s.request());
  ref.listen(billPaymentsProvider, (_, _) => s.request());
  ref.listen(reminderSettingsProvider, (_, _) => s.request());
  s.request();
  return s;
});

class ReminderScheduler {
  ReminderScheduler(this._ref);
  final Ref _ref;
  Timer? _timer;
  bool _disposed = false;

  /// Debounced: bursts of changes collapse into one reschedule.
  void request() {
    _timer?.cancel();
    _timer = Timer(kRescheduleDebounce, run);
  }

  Future<void> run() async {
    if (_disposed) return;
    try {
      final service = _ref.read(notificationServiceProvider);
      if (!service.supported) return;
      final settings = _ref.read(reminderSettingsProvider).value;
      if (settings == null) return;
      if (!settings.masterOn) {
        await service.cancelAll();
        return;
      }
      final tasks = _ref.read(tasksProvider).value;
      final bills = _ref.read(billsProvider).value;
      final payments = _ref.read(billPaymentsProvider).value;
      // Not loaded yet: the load itself triggers another request().
      if (tasks == null || bills == null || payments == null) return;
      final plan = planReminders(
        tasks: tasks,
        bills: bills,
        payments: payments,
        settings: settings,
        now: service.now(),
      );
      await service.reschedule(plan);
    } catch (e) {
      debugPrint('reminder reschedule failed: $e');
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }
}
