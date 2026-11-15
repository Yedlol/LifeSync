import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/features/tasks/models/description_codec.dart';
import 'package:lifesync/features/tasks/models/task.dart';
import 'package:lifesync/features/tasks/models/task_enums.dart';
import 'package:lifesync/features/tasks/models/task_ordering.dart';

void main() {
  const col = [('a', 1000.0), ('b', 2000.0), ('c', 3000.0)];

  group('planMove', () {
    test('empty column -> 1000', () {
      expect(planMove(column: const [], movingId: 'x').position, 1000);
    });
    test('top -> first - 1000', () {
      expect(planMove(column: col, movingId: 'x', belowId: 'a').position, 0);
    });
    test('bottom -> last + 1000', () {
      expect(planMove(column: col, movingId: 'x', aboveId: 'c').position, 4000);
    });
    test('between -> midpoint', () {
      final p = planMove(
        column: col,
        movingId: 'x',
        aboveId: 'a',
        belowId: 'b',
      );
      expect(p.position, 1500);
      expect(p.renumbered, isEmpty);
    });
    test('tiny gap -> renumber column', () {
      const tight = [('a', 1000.0), ('b', 1000.0005), ('c', 3000.0)];
      final p = planMove(
        column: tight,
        movingId: 'x',
        aboveId: 'a',
        belowId: 'b',
      );
      expect(p.position, 2000);
      expect(p.renumbered, {'b': 3000.0, 'c': 4000.0});
    });
    test('no visible neighbours but non-empty column -> append', () {
      expect(planMove(column: col, movingId: 'x').position, 4000);
    });
  });

  test('topPosition', () {
    expect(topPosition(const []), 1000);
    expect(topPosition(const [500, 200, 900]), -800);
  });

  group('description codec', () {
    test('round trip', () {
      final d = plainTextToDelta('hello\nworld\n\n');
      expect(d, [
        {'insert': 'hello\nworld\n'},
      ]);
      expect(deltaToPlainText(d), 'hello\nworld');
    });
    test('skips embeds, accepts {ops}', () {
      expect(
        deltaToPlainText({
          'ops': [
            {'insert': 'a'},
            {
              'insert': {'image': 'x'},
            },
            {'insert': 'b\n'},
          ],
        }),
        'ab',
      );
      expect(deltaToPlainText(null), '');
    });
  });

  group('Task', () {
    test('fromJson parses numeric strings, enums, delta', () {
      final t = Task.fromJson({
        'id': '1',
        'title': 'T',
        'status': 'in_progress',
        'priority': 'urgent',
        'position': '1500.5',
        'description': [
          {'insert': 'note\n'},
        ],
        'due_at': '2026-01-01T15:59:59Z',
      });
      expect(t.status, TaskStatus.inProgress);
      expect(t.priority, TaskPriority.urgent);
      expect(t.position, 1500.5);
      expect(t.descriptionText, 'note');
      expect(t.isOverdue, isTrue);
    });
    test('completed_at rule', () {
      final open = const Task(id: '1', title: 't');
      expect(open.completedAtFor(TaskStatus.done), isNotNull);
      expect(open.completedAtFor(TaskStatus.onHold), isNull);
      final stamp = DateTime.utc(2026, 1, 1);
      final done = open.copyWith(status: TaskStatus.done, completedAt: stamp);
      expect(done.completedAtFor(TaskStatus.done), stamp);
      expect(done.completedAtFor(TaskStatus.open), isNull);
    });
  });
}
