import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/features/finance/bills/models/bill.dart';
import 'package:lifesync/features/finance/bills/models/bill_payment.dart';
import 'package:lifesync/features/finance/bills/models/bill_status.dart';

final _today = DateTime(2026, 11, 16);
final _nov = DateTime(2026, 11, 1);

Bill _bill(
  String id,
  int dueDay, {
  BillFrequency f = BillFrequency.monthly,
  bool active = true,
  DateTime? created,
  double amount = 100,
}) => Bill(
  id: id,
  name: id,
  amount: amount,
  dueDay: dueDay,
  frequency: f,
  isActive: active,
  createdAt: created ?? DateTime(2026, 1, 5),
);

BillPayment _pay(String billId, DateTime period, {double amount = 100}) =>
    BillPayment(
      id: 'p-$billId-${period.month}',
      billId: billId,
      period: period,
      amountPaid: amount,
      paidAt: DateTime(2026, 11, 3),
    );

List<BillEntry> _month(
  List<Bill> bills,
  List<BillPayment> pays, [
  DateTime? month,
]) => billsForMonth(
  bills: bills,
  payments: pays,
  month: month ?? _nov,
  today: _today,
);

void main() {
  group('status rules', () {
    BillStatus s(int dueDay) => _month([_bill('a', dueDay)], []).single.status;

    test('past due -> overdue', () => expect(s(10), BillStatus.overdue));
    test('due today -> due soon', () => expect(s(16), BillStatus.dueSoon));
    test('3 days out -> due soon', () => expect(s(19), BillStatus.dueSoon));
    test('4 days out -> unpaid', () => expect(s(20), BillStatus.unpaid));
    test('days until due is reported', () {
      expect(_month([_bill('a', 18)], []).single.daysUntilDue, 2);
    });
    test('paid wins over a past due date', () {
      final e = _month([_bill('a', 10)], [_pay('a', _nov)]).single;
      expect(e.status, BillStatus.paid);
    });
    test('paid amount replaces expected amount', () {
      final e = _month(
        [_bill('a', 10, amount: 100)],
        [_pay('a', _nov, amount: 87.5)],
      ).single;
      expect(e.amount, 87.5);
    });
    test('a payment for another month does not count', () {
      final e = _month([_bill('a', 10)], [_pay('a', DateTime(2026, 10, 1))]);
      expect(e.single.status, BillStatus.overdue);
    });
  });

  group('other months', () {
    test('past month unpaid -> overdue', () {
      final e = _month([_bill('a', 20)], [], DateTime(2026, 9, 1)).single;
      expect(e.status, BillStatus.overdue);
    });
    test('future month unpaid -> unpaid', () {
      final e = _month([_bill('a', 20)], [], DateTime(2027, 2, 1)).single;
      expect(e.status, BillStatus.unpaid);
    });
  });

  group('due day clamping', () {
    test('31 in February -> last day', () {
      expect(dueDateIn(DateTime(2027, 2, 1), 31), DateTime(2027, 2, 28));
      expect(dueDateIn(DateTime(2028, 2, 1), 31), DateTime(2028, 2, 29));
      expect(dueDateIn(DateTime(2026, 4, 1), 31), DateTime(2026, 4, 30));
      expect(dueDateIn(DateTime(2026, 1, 1), 31), DateTime(2026, 1, 31));
    });
  });

  group('which bills show', () {
    test('monthly bills start in the month they were created', () {
      final b = _bill('a', 20, created: DateTime(2026, 11, 10));
      expect(_month([b], [], DateTime(2026, 10, 1)), isEmpty);
      expect(_month([b], [], DateTime(2026, 11, 1)), hasLength(1));
      expect(_month([b], [], DateTime(2027, 6, 1)), hasLength(1));
    });

    test('inactive bills are hidden', () {
      expect(_month([_bill('a', 20, active: false)], []), isEmpty);
    });

    test('one-time: shown until paid, afterwards only in the paid month', () {
      final b = _bill('o', 10, f: BillFrequency.oneTime);
      final dec = DateTime(2026, 12, 1);
      expect(_month([b], [], dec), hasLength(1));
      expect(_month([b], [], dec).single.status, BillStatus.overdue);
      final p = [_pay('o', _nov)];
      expect(_month([b], p, _nov).single.status, BillStatus.paid);
      expect(_month([b], p, dec), isEmpty);
      expect(_month([b], p, DateTime(2026, 10, 1)), isEmpty);
    });

    test('one-time before its creation month is hidden', () {
      final b = _bill(
        'o',
        10,
        f: BillFrequency.oneTime,
        created: DateTime(2026, 11, 2),
      );
      expect(_month([b], [], DateTime(2026, 10, 1)), isEmpty);
    });

    test('one-time due date is the first matching day after creation', () {
      final b = _bill(
        'o',
        10,
        f: BillFrequency.oneTime,
        created: DateTime(2026, 11, 25),
      );
      expect(oneTimeDueDate(b), DateTime(2026, 12, 10));
      final c = _bill(
        'o',
        28,
        f: BillFrequency.oneTime,
        created: DateTime(2026, 11, 25),
      );
      expect(oneTimeDueDate(c), DateTime(2026, 11, 28));
    });
  });

  test('sorted: overdue, due soon, unpaid (by day), paid', () {
    final bills = [
      _bill('paid', 1),
      _bill('later-b', 28),
      _bill('later-a', 22),
      _bill('soon', 18),
      _bill('overdue', 5),
    ];
    final order = _month(bills, [_pay('paid', _nov)]).map((e) => e.bill.id);
    expect(order, ['overdue', 'soon', 'later-a', 'later-b', 'paid']);
  });

  test('totals', () {
    final bills = [
      _bill('a', 5, amount: 100),
      _bill('b', 25, amount: 200),
      _bill('c', 10, amount: 300),
    ];
    final t = totalsOf(_month(bills, [_pay('c', _nov, amount: 250)]));
    expect(t.paid, 250);
    expect(t.remaining, 300);
    expect(t.total, 550);
    expect(t.progress, closeTo(250 / 550, 1e-9));
    expect(totalsOf(const []).progress, 0);
  });

  group('JSON', () {
    test('Bill.fromJson', () {
      final b = Bill.fromJson({
        'id': '1',
        'name': 'TNB',
        'category': 'Utilities',
        'amount': '123.40',
        'due_day': 31,
        'frequency': 'one_time',
        'is_active': false,
        'created_at': '2026-01-05T00:00:00Z',
      });
      expect(b.amount, 123.4);
      expect(b.isOneTime, isTrue);
      expect(b.isActive, isFalse);
      expect(b.toJson()['frequency'], 'one_time');
    });

    test('BillPayment parses date and timestamp columns', () {
      final a = BillPayment.fromJson({
        'id': '1',
        'bill_id': 'b',
        'period': '2026-11-01',
        'amount_paid': 55,
        'paid_at': '2026-11-03',
      });
      expect(a.period, DateTime(2026, 11, 1));
      expect(a.paidAt, DateTime(2026, 11, 3));
      final b = BillPayment.fromJson({
        'id': '2',
        'bill_id': 'b',
        'period': '2026-11-15',
        'amount_paid': '9.5',
        'paid_at': paidAtValue(DateTime(2026, 11, 20)),
      });
      expect(b.period, DateTime(2026, 11, 1));
      expect(b.paidAt, DateTime(2026, 11, 20));
      expect(b.amountPaid, 9.5);
    });

    test(
      'dateOnly',
      () => expect(dateOnly(DateTime(2026, 3, 5)), '2026-03-05'),
    );
  });
}
