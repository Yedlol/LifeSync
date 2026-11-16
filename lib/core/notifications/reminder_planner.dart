import '../../features/finance/bills/models/bill.dart';
import '../../features/finance/bills/models/bill_payment.dart';
import '../../features/finance/bills/models/bill_status.dart';
import '../../features/tasks/models/task.dart';
import '../utils/money.dart';
import 'reminder_settings.dart';

/// How far ahead reminders are scheduled.
const kReminderHorizonDays = 45;

/// A notification to schedule. [when] is wall-clock time in the app's time
/// zone (Asia/Kuala_Lumpur).
class PlannedReminder {
  const PlannedReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
  });
  final int id;
  final DateTime when;
  final String title;
  final String body;

  /// `task:ID`, `bill:YYYY-MM` or `summary` (see notification_router).
  final String payload;
}

/// Stable positive 31-bit id from (type, record id, kind), FNV-1a. Ids below
/// 100 are reserved (the test notification uses 1).
int reminderId(String type, String recordId, String kind) {
  var h = 0x811c9dc5;
  for (final c in '$type|$recordId|$kind'.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  final id = h & 0x7FFFFFFF;
  return id < 100 ? id + 100 : id;
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String _ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

String summaryBody(int tasks, int bills, double billTotal) {
  final parts = [
    if (tasks > 0) '$tasks ${tasks == 1 ? 'task' : 'tasks'} due',
    if (bills > 0)
      '$bills ${bills == 1 ? 'bill' : 'bills'} due (${formatRm(billTotal)})',
  ];
  return 'Today: ${parts.join(', ')}';
}

/// Everything to schedule for the next [kReminderHorizonDays] days. Pure: the
/// caller supplies [now] (wall-clock in the app time zone). Never returns a
/// time in the past; paid bills and done tasks produce nothing.
List<PlannedReminder> planReminders({
  required Iterable<Task> tasks,
  required Iterable<Bill> bills,
  required Iterable<BillPayment> payments,
  required ReminderSettings settings,
  required DateTime now,
}) {
  if (!settings.masterOn) return const [];
  final end = now.add(const Duration(days: kReminderHorizonDays));
  final today = _day(now);
  final out = <int, PlannedReminder>{};

  DateTime at(DateTime day, int minutes) =>
      DateTime(day.year, day.month, day.day, minutes ~/ 60, minutes % 60);

  void add(PlannedReminder r) {
    if (r.when.isAfter(now) && !r.when.isAfter(end)) out[r.id] = r;
  }

  final tasksOnDay = <DateTime, int>{};
  final billsOnDay = <DateTime, int>{};
  final billTotalOnDay = <DateTime, double>{};

  // ---- Tasks: not done, with a due date.
  for (final t in tasks) {
    if (t.isDone || t.dueAt == null) continue;
    final due = _day(t.dueAt!.toLocal());
    tasksOnDay[due] = (tasksOnDay[due] ?? 0) + 1;
    if (!settings.tasksOn) continue;
    final before = DateTime(due.year, due.month, due.day - 1);
    add(
      PlannedReminder(
        id: reminderId('task', t.id, 'before'),
        when: at(before, settings.reminderMinutes),
        title: 'Task due tomorrow',
        body: t.title,
        payload: 'task:${t.id}',
      ),
    );
    add(
      PlannedReminder(
        id: reminderId('task', t.id, 'due'),
        when: at(due, settings.reminderMinutes),
        title: 'Task due today',
        body: t.title,
        payload: 'task:${t.id}',
      ),
    );
  }

  // ---- Bills: unpaid ones this month and next (existing Bills logic).
  final m0 = monthStart(today);
  final seen = <int>{};
  for (final m in [m0, DateTime(m0.year, m0.month + 1, 1)]) {
    final entries = billsForMonth(
      bills: bills,
      payments: payments,
      month: m,
      today: now,
    );
    for (final e in entries) {
      if (e.payment != null) continue;
      final due = _day(e.dueDate);
      // A one-time bill shows up in both months; count it once.
      if (!seen.add(reminderId('bill', e.bill.id, dateOnly(due)))) continue;
      billsOnDay[due] = (billsOnDay[due] ?? 0) + 1;
      billTotalOnDay[due] = (billTotalOnDay[due] ?? 0) + e.amount;
      if (!settings.billsOn) continue;
      final body = '${e.bill.name} · ${formatRm(e.amount)}';
      final payload = 'bill:${_ym(due)}';
      add(
        PlannedReminder(
          id: reminderId('bill', e.bill.id, '${dateOnly(due)}:3d'),
          when: at(
            DateTime(due.year, due.month, due.day - 3),
            settings.reminderMinutes,
          ),
          title: 'Bill due in 3 days',
          body: body,
          payload: payload,
        ),
      );
      add(
        PlannedReminder(
          id: reminderId('bill', e.bill.id, '${dateOnly(due)}:0d'),
          when: at(due, settings.reminderMinutes),
          title: 'Bill due today',
          body: body,
          payload: payload,
        ),
      );
    }
  }

  // ---- Daily summary: only on days that have something due.
  if (settings.summaryOn) {
    for (var i = 0; i <= kReminderHorizonDays; i++) {
      final day = DateTime(today.year, today.month, today.day + i);
      final nTasks = tasksOnDay[day] ?? 0;
      final nBills = billsOnDay[day] ?? 0;
      if (nTasks == 0 && nBills == 0) continue;
      add(
        PlannedReminder(
          id: reminderId('summary', dateOnly(day), 'daily'),
          when: at(day, settings.summaryMinutes),
          title: 'Daily summary',
          body: summaryBody(nTasks, nBills, billTotalOnDay[day] ?? 0),
          payload: 'summary',
        ),
      );
    }
  }

  return out.values.toList()..sort((a, b) => a.when.compareTo(b.when));
}
