import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/core/theme/app_theme.dart';
import 'package:lifesync/features/auth/providers/auth_providers.dart';
import 'package:lifesync/features/finance/bills/data/bill_repository.dart';
import 'package:lifesync/features/finance/bills/models/bill.dart';
import 'package:lifesync/features/finance/bills/models/bill_payment.dart';
import 'package:lifesync/features/finance/bills/providers/bill_providers.dart';
import 'package:lifesync/features/finance/ui/finance_screen.dart';

final _now = DateTime.now();
final _thisMonth = DateTime(_now.year, _now.month, 1);

final _bills = [
  Bill(
    id: 'rent',
    name: 'Rent',
    category: 'Rent',
    amount: 1200,
    dueDay: 1,
    createdAt: DateTime(2020, 1, 1),
  ),
  Bill(
    id: 'tnb',
    name: 'Electricity',
    category: 'Utilities',
    amount: 100,
    dueDay: 28,
    createdAt: DateTime(2020, 1, 1),
  ),
  Bill(
    id: 'old',
    name: 'Hidden bill',
    amount: 5,
    dueDay: 5,
    isActive: false,
    createdAt: DateTime(2020, 1, 1),
  ),
  Bill(
    id: 'gym',
    name: 'Gym',
    category: 'My gym stuff',
    amount: 80,
    dueDay: 15,
    createdAt: DateTime(2020, 1, 1),
  ),
];

final _paid = <BillPayment>[
  BillPayment(
    id: 'p1',
    billId: 'rent',
    period: _thisMonth,
    amountPaid: 1200,
    paidAt: DateTime(_now.year, _now.month, 1),
  ),
];

final _calls = <String>[];

class _FakeBills extends BillRepository {
  @override
  Stream<List<Bill>> watchBills() => Stream.value(_bills);

  @override
  Stream<List<BillPayment>> watchPayments() => Stream.value(_paid);

  @override
  Future<BillPayment> markPaid({
    required String billId,
    required DateTime period,
    required double amountPaid,
    required DateTime paidAt,
  }) async {
    _calls.add('paid $billId ${dateOnly(period)} $amountPaid');
    return BillPayment(
      id: 'new',
      billId: billId,
      period: period,
      amountPaid: amountPaid,
      paidAt: paidAt,
    );
  }

  @override
  Future<void> markUnpaid(String billId, DateTime period) async {
    _calls.add('unpaid $billId ${dateOnly(period)}');
  }
}

Future<void> _pump(WidgetTester tester, Size size) async {
  _calls.clear();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentEmailProvider.overrideWith((_) => Stream.value('me@test')),
        billRepositoryProvider.overrideWithValue(_FakeBills()),
      ],
      child: MaterialApp(theme: buildAppTheme(), home: const FinanceScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('finance has Bills / Savings / Income tabs', (tester) async {
    await _pump(tester, const Size(1000, 800));
    expect(find.text('Bills'), findsOneWidget);
    await tester.tap(find.text('Savings'));
    await tester.pumpAndSettle();
    expect(find.text('Savings — coming soon'), findsOneWidget);
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(find.text('Income — coming soon'), findsOneWidget);
  });

  testWidgets('month list, summary and statuses', (tester) async {
    await _pump(tester, const Size(1000, 900));
    expect(find.text('Rent'), findsWidgets);
    expect(find.text('Electricity'), findsOneWidget);
    expect(find.text('Hidden bill'), findsNothing);
    expect(find.text('Total this month'), findsOneWidget);
    expect(find.text('RM 1,380.00'), findsOneWidget); // 1200 + 100 + 80
    expect(find.text('RM 1,200.00'), findsWidgets); // paid
    expect(find.textContaining('Paid '), findsOneWidget);
    expect(find.text('This month'), findsNothing);
  });

  testWidgets('month switcher shows This month when away', (tester) async {
    await _pump(tester, const Size(1000, 900));
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('This month'), findsOneWidget);
    // Rent is not paid in the next month.
    expect(find.textContaining('Paid '), findsNothing);
    await tester.tap(find.text('This month'));
    await tester.pumpAndSettle();
    expect(find.text('This month'), findsNothing);
  });

  testWidgets('tap unpaid bill -> mark as paid with edited amount', (
    tester,
  ) async {
    await _pump(tester, const Size(1000, 900));
    await tester.tap(find.text('Electricity'));
    await tester.pumpAndSettle();
    expect(find.text('Mark as paid'), findsWidgets);
    await tester.enterText(find.byType(TextFormField), '123.456');
    // Input is limited to 2 decimals.
    expect(find.text('123.45'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Mark as paid'));
    await tester.pumpAndSettle();
    expect(_calls, ['paid tnb ${dateOnly(_thisMonth)} 123.45']);
  });

  testWidgets('tap paid bill -> edit or mark as unpaid', (tester) async {
    await _pump(tester, const Size(1000, 900));
    await tester.tap(find.text('Rent').first);
    await tester.pumpAndSettle();
    expect(find.text('Edit payment'), findsOneWidget);
    await tester.tap(find.text('Mark as unpaid'));
    await tester.pumpAndSettle();
    expect(_calls, ['unpaid rent ${dateOnly(_thisMonth)}']);
  });

  testWidgets('amount must be above 0', (tester) async {
    await _pump(tester, const Size(1000, 900));
    await tester.tap(find.text('Electricity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '0');
    await tester.tap(find.widgetWithText(FilledButton, 'Mark as paid'));
    await tester.pumpAndSettle();
    expect(find.text('Enter an amount above 0'), findsOneWidget);
    expect(_calls, isEmpty);
  });

  testWidgets('add bill form (desktop dialog) validates + custom category', (
    tester,
  ) async {
    await _pump(tester, const Size(1000, 900));
    await tester.tap(find.text('Add bill'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add bill'));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Enter an amount above 0'), findsOneWidget);

    // Dropdown lists presets, previously used custom categories and "Custom…".
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Phone & Internet'), findsWidgets);
    expect(find.text('My gym stuff'), findsWidgets);
    await tester.tap(find.text('Custom…').last);
    await tester.pumpAndSettle();
    expect(find.text('Custom category'), findsOneWidget);
  });

  testWidgets('add bill is a full page on phone; manage bills lists all', (
    tester,
  ) async {
    await _pump(tester, const Size(400, 800));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Add bill'));
    await tester.pumpAndSettle();
    expect(find.text('Name *'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage bills'));
    await tester.pumpAndSettle();
    expect(find.text('Hidden bill'), findsOneWidget); // inactive kept here
    expect(find.textContaining('Inactive'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('payment history'), findsOneWidget);
    expect(find.textContaining('deactivate'), findsOneWidget);
  });
}
