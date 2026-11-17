import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/core/offline/local_store.dart';
import 'package:lifesync/core/notifications/notification_service.dart';
import 'package:lifesync/core/notifications/reminder_planner.dart';
import 'package:lifesync/core/notifications/reminder_settings.dart';
import 'package:lifesync/core/theme/app_theme.dart';
import 'package:lifesync/features/auth/providers/auth_providers.dart';
import 'package:lifesync/features/finance/bills/models/bill.dart';
import 'package:lifesync/features/finance/bills/models/bill_payment.dart';
import 'package:lifesync/features/settings/data/settings_repository.dart';
import 'package:lifesync/features/settings/ui/settings_screen.dart';
import 'package:lifesync/features/tasks/models/task.dart';
import 'package:lifesync/features/tasks/models/task_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tuesday 17 Nov 2026, 08:00 (Kuala Lumpur wall clock).
final _now = DateTime(2026, 11, 17, 8);
const _on = ReminderSettings(masterOn: true, summaryOn: true);

Task _task(String id, DateTime due, {TaskStatus status = TaskStatus.open}) =>
    Task(id: id, title: 'Task $id', dueAt: due, status: status);

Bill _bill(String id, int dueDay, {double amount = 120}) => Bill(
  id: id,
  name: 'Bill $id',
  amount: amount,
  dueDay: dueDay,
  createdAt: DateTime(2020),
);

List<PlannedReminder> _plan({
  List<Task> tasks = const [],
  List<Bill> bills = const [],
  List<BillPayment> payments = const [],
  ReminderSettings settings = _on,
  DateTime? now,
}) => planReminders(
  tasks: tasks,
  bills: bills,
  payments: payments,
  settings: settings,
  now: now ?? _now,
);

void main() {
  setUp(() => LocalStore.instance = LocalStore.memory());

  group('planReminders', () {
    test('nothing when the master toggle is off', () {
      expect(
        _plan(
          tasks: [_task('a', DateTime(2026, 11, 20))],
          settings: const ReminderSettings(),
        ),
        isEmpty,
      );
    });

    test('task: day before + due day at reminder time; skips past', () {
      final r = _plan(
        tasks: [_task('a', DateTime(2026, 11, 20, 23, 59))],
        settings: const ReminderSettings(masterOn: true),
      );
      expect(r.map((e) => e.when), [
        DateTime(2026, 11, 19, 9),
        DateTime(2026, 11, 20, 9),
      ]);
      expect(r.first.title, 'Task due tomorrow');
      expect(r.last.title, 'Task due today');
      expect(r.first.payload, 'task:a');

      // Due tomorrow: the "day before" slot (today 09:00) is still ahead.
      // Due today at 09:00 but it's already 10:00: nothing left.
      final late = _plan(
        tasks: [_task('b', DateTime(2026, 11, 17, 23, 59))],
        settings: const ReminderSettings(masterOn: true),
        now: DateTime(2026, 11, 17, 10),
      );
      expect(late, isEmpty);
    });

    test('done tasks and tasks without a due date are ignored', () {
      final r = _plan(
        tasks: [
          _task('done', DateTime(2026, 11, 20), status: TaskStatus.done),
          const Task(id: 'nodue', title: 'x'),
        ],
        settings: const ReminderSettings(masterOn: true),
      );
      expect(r, isEmpty);
    });

    test('bill: 3 days before and on due date; paid bills skipped', () {
      final bills = [_bill('rent', 25), _bill('wifi', 28)];
      final paid = [
        BillPayment(
          id: 'p',
          billId: 'wifi',
          period: DateTime(2026, 11),
          amountPaid: 120,
          paidAt: DateTime(2026, 11, 10),
        ),
      ];
      final r = _plan(
        bills: bills,
        payments: paid,
        settings: const ReminderSettings(masterOn: true),
      ).where((e) => e.payload == 'bill:2026-11').toList();
      expect(r.map((e) => e.when), [
        DateTime(2026, 11, 22, 9),
        DateTime(2026, 11, 25, 9),
      ]);
      expect(r.first.title, 'Bill due in 3 days');
      expect(r.first.body, 'Bill rent · RM 120.00');
    });

    test('covers next month inside the 45-day horizon only', () {
      final r = _plan(
        bills: [_bill('rent', 1)],
        settings: const ReminderSettings(masterOn: true),
      );
      // 1 Dec is in range; nothing is planned beyond 45 days.
      expect(
        r.map((e) => e.when),
        containsAll([DateTime(2026, 11, 28, 9), DateTime(2026, 12, 1, 9)]),
      );
      expect(
        r.every((e) => !e.when.isAfter(_now.add(const Duration(days: 45)))),
        isTrue,
      );
    });

    test('summary text and skipping empty days', () {
      final r = _plan(
        tasks: [
          _task('a', DateTime(2026, 11, 20)),
          _task('b', DateTime(2026, 11, 20)),
        ],
        bills: [_bill('rent', 20, amount: 120)],
        settings: const ReminderSettings(
          masterOn: true,
          tasksOn: false,
          billsOn: false,
          summaryOn: true,
        ),
      );
      // Only 20 Nov (2 tasks + the bill) and 20 Dec (monthly bill) have
      // anything due; every other day is skipped.
      expect(r.map((e) => e.when), [
        DateTime(2026, 11, 20, 8),
        DateTime(2026, 12, 20, 8),
      ]);
      expect(r.first.body, 'Today: 2 tasks due, 1 bill due (RM 120.00)');
      expect(r.last.body, 'Today: 1 bill due (RM 120.00)');
      expect(r.first.payload, 'summary');
    });

    test('ids are stable and distinct per kind', () {
      expect(reminderId('task', 'a', 'due'), reminderId('task', 'a', 'due'));
      expect(
        reminderId('task', 'a', 'due') == reminderId('task', 'a', 'before'),
        isFalse,
      );
      final a = _plan(tasks: [_task('a', DateTime(2026, 11, 20))]);
      final b = _plan(tasks: [_task('a', DateTime(2026, 11, 20))]);
      expect(a.map((e) => e.id), b.map((e) => e.id));
      expect(a.every((e) => e.id >= 100), isTrue);
    });
  });

  group('settings section', () {
    testWidgets('master toggle asks permission, saves, test button schedules', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final fake = _FakeService();
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(fake),
            currentEmailProvider.overrideWith((_) => Stream.value('me@test')),
            settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepo()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Task reminders'), findsOneWidget);
      // Sub-options are disabled until the master toggle is on.
      expect(
        tester
            .widget<SwitchListTile>(
              find.widgetWithText(SwitchListTile, 'Task reminders'),
            )
            .onChanged,
        isNull,
      );

      await tester.tap(find.widgetWithText(SwitchListTile, 'Reminders'));
      await tester.pumpAndSettle();
      expect(fake.permissionRequests, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reminders.master'), isTrue);

      await tester.ensureVisible(find.text('Send test notification'));
      await tester.tap(find.text('Send test notification'));
      await tester.pumpAndSettle();
      expect(fake.tests, [const Duration(seconds: 5)]);
    });

    testWidgets('denied permission keeps reminders off', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final fake = _FakeService(grant: false);
      tester.view.physicalSize = const Size(500, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(fake),
            currentEmailProvider.overrideWith((_) => Stream.value('me@test')),
            settingsRepositoryProvider.overrideWithValue(_FakeSettingsRepo()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, 'Reminders'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Notifications are blocked'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reminders.master'), isNull);
    });
  });
}

class _FakeSettingsRepo extends SettingsRepository {
  @override
  Stream<List<Map<String, dynamic>>> watchRows() => Stream.value(const []);
}

class _FakeService implements NotificationService {
  _FakeService({this.grant = true});
  final bool grant;
  int permissionRequests = 0;
  final tests = <Duration>[];

  @override
  bool get supported => true;
  @override
  Stream<String> get taps => const Stream.empty();
  @override
  String? takeLaunchPayload() => null;
  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return grant;
  }

  @override
  DateTime now() => _now;
  @override
  Future<void> reschedule(List<PlannedReminder> plan) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> scheduleTest(Duration after) async => tests.add(after);
}
