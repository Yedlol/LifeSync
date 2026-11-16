import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/core/theme/app_theme.dart';
import 'package:lifesync/features/auth/providers/auth_providers.dart';
import 'package:lifesync/features/dashboard/models/attention.dart';
import 'package:lifesync/features/dashboard/ui/dashboard_screen.dart';
import 'package:lifesync/features/finance/bills/data/bill_repository.dart';
import 'package:lifesync/features/finance/bills/models/bill.dart';
import 'package:lifesync/features/finance/bills/models/bill_payment.dart';
import 'package:lifesync/features/finance/bills/providers/bill_providers.dart';
import 'package:lifesync/features/finance/income/data/income_repository.dart';
import 'package:lifesync/features/finance/income/models/income_entry.dart';
import 'package:lifesync/features/finance/income/providers/income_providers.dart';
import 'package:lifesync/features/finance/savings/data/savings_repository.dart';
import 'package:lifesync/features/finance/savings/models/saving_entry.dart';
import 'package:lifesync/features/finance/savings/models/savings_goal.dart';
import 'package:lifesync/features/finance/savings/providers/savings_providers.dart';
import 'package:lifesync/features/projects/data/project_repository.dart';
import 'package:lifesync/features/projects/models/project.dart';
import 'package:lifesync/features/projects/providers/project_providers.dart';
import 'package:lifesync/features/tasks/data/task_repository.dart';
import 'package:lifesync/features/tasks/models/task.dart';
import 'package:lifesync/features/tasks/models/task_enums.dart';
import 'package:lifesync/features/tasks/providers/tasks_notifier.dart';

final _now = DateTime(2026, 11, 17, 10);

Task _t(
  String id, {
  DateTime? due,
  TaskStatus status = TaskStatus.open,
  TaskPriority priority = TaskPriority.medium,
}) => Task(
  id: id,
  title: 'Task $id',
  status: status,
  priority: priority,
  dueAt: due,
);

void main() {
  group('attentionTasks', () {
    test('orders overdue, today, soon, then priority; skips done/far', () {
      final items = attentionTasks(
        [
          _t('far', due: DateTime(2026, 12, 25)),
          _t('soon3', due: DateTime(2026, 11, 20)),
          _t(
            'hot',
            status: TaskStatus.inProgress,
            priority: TaskPriority.urgent,
          ),
          _t('today', due: DateTime(2026, 11, 17, 23)),
          _t('late2', due: DateTime(2026, 11, 15)),
          _t('late5', due: DateTime(2026, 11, 12)),
          _t('done', due: DateTime(2026, 11, 1), status: TaskStatus.done),
          _t('calm', status: TaskStatus.inProgress),
          _t('soon1', due: DateTime(2026, 11, 18)),
        ],
        _now,
        max: 20,
      );
      expect(items.map((i) => i.task.id), [
        'late5',
        'late2',
        'today',
        'soon1',
        'soon3',
        'hot',
      ]);
      expect(items.first.dueText, 'Overdue 5 days');
      expect(items[3].dueText, 'Due tomorrow');
      expect(items[4].dueText, 'Due in 3 days');
    });

    test('is capped at 5', () {
      final many = [
        for (var i = 0; i < 9; i++) _t('$i', due: DateTime(2026, 11, 1 + i)),
      ];
      expect(attentionTasks(many, _now), hasLength(5));
    });
  });

  group('dashboard screen', () {
    Future<void> pump(
      WidgetTester tester,
      Size size, {
      bool empty = false,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentEmailProvider.overrideWith((_) => Stream.value('me@test')),
            taskRepositoryProvider.overrideWithValue(
              _FakeTasks(
                empty
                    ? const []
                    : [
                        _t(
                          'a',
                          due: DateTime.now().subtract(const Duration(days: 1)),
                        ),
                      ],
              ),
            ),
            projectRepositoryProvider.overrideWithValue(_FakeProjects()),
            billRepositoryProvider.overrideWithValue(_FakeBills(empty)),
            incomeRepositoryProvider.overrideWithValue(_FakeIncome()),
            savingsRepositoryProvider.overrideWithValue(_FakeSavings()),
          ],
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('phone shows all four cards with data', (tester) async {
      await pump(tester, const Size(400, 2000));
      expect(find.textContaining('Good '), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.text('Task a'), findsOneWidget);
      expect(find.text('Overdue 1 day'), findsOneWidget);
      expect(find.text('Bills this month'), findsOneWidget);
      expect(find.textContaining('1 unpaid'), findsOneWidget);
      expect(find.text('Money this month'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Pay a bill'), findsOneWidget);
    });

    testWidgets('desktop lays out two columns without overflow', (
      tester,
    ) async {
      await pump(tester, const Size(1200, 1400));
      final tasks = tester.getTopLeft(find.text('Tasks'));
      final money = tester.getTopLeft(find.text('Money this month'));
      expect(money.dx, greaterThan(tasks.dx + 300));
    });

    testWidgets('empty states everywhere', (tester) async {
      await pump(tester, const Size(400, 2400), empty: true);
      expect(find.textContaining('No active tasks'), findsOneWidget);
      expect(find.textContaining('No bills this month'), findsOneWidget);
      expect(find.textContaining('Nothing recorded'), findsOneWidget);
      expect(find.textContaining('No savings goals'), findsOneWidget);
    });
  });
}

class _FakeTasks extends TaskRepository {
  _FakeTasks(this.tasks);
  final List<Task> tasks;
  @override
  Stream<List<Task>> watch() => Stream.value(tasks);
}

class _FakeProjects extends ProjectRepository {
  @override
  Stream<List<Project>> watch() => Stream.value(const []);
}

class _FakeBills extends BillRepository {
  _FakeBills(this.empty);
  final bool empty;
  @override
  Stream<List<Bill>> watchBills() => Stream.value(
    empty
        ? const []
        : [
            Bill(
              id: 'rent',
              name: 'Rent',
              amount: 1200,
              dueDay: 1,
              createdAt: DateTime(2020),
            ),
          ],
  );
  @override
  Stream<List<BillPayment>> watchPayments() => Stream.value(const []);
}

class _FakeIncome extends IncomeRepository {
  @override
  Stream<List<IncomeEntry>> watchEntries() => Stream.value(const []);
}

class _FakeSavings extends SavingsRepository {
  @override
  Stream<List<SavingsGoal>> watchGoals() => Stream.value(const []);
  @override
  Stream<List<SavingEntry>> watchEntries() => Stream.value(const []);
}
