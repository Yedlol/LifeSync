import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations, QuillEditor, QuillSimpleToolbar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifesync/core/theme/app_theme.dart';
import 'package:lifesync/features/auth/providers/auth_providers.dart';
import 'package:lifesync/features/projects/data/project_repository.dart';
import 'package:lifesync/features/projects/models/project.dart';
import 'package:lifesync/features/projects/providers/project_providers.dart';
import 'package:lifesync/features/tasks/data/task_image_repository.dart';
import 'package:lifesync/features/tasks/data/task_repository.dart';
import 'package:lifesync/features/tasks/models/task.dart';
import 'package:lifesync/features/tasks/models/task_enums.dart';
import 'package:lifesync/features/tasks/providers/tasks_notifier.dart';
import 'package:lifesync/features/tasks/ui/tasks_screen.dart';

final _now = DateTime.now();
final _richDelta = [
  {'insert': 'First line\n'},
  {'insert': 'Second line\n'},
  {'insert': 'Third line\n'},
  {
    'insert': {'image': 'uid/6/a.jpg'},
  },
  {'insert': '\n'},
  {
    'insert': {'image': 'uid/6/b.jpg'},
  },
  {'insert': '\n'},
];
final _tasks = [
  Task(
    id: '6',
    title: 'Rich task',
    position: 3000,
    description: _richDelta,
    createdAt: _now,
  ),
  Task(
    id: '7',
    title: 'Legacy plain task',
    position: 4000,
    description: const [
      {'insert': 'old plain text\n'},
    ],
    createdAt: _now,
  ),
  Task(
    id: '1',
    title: 'Pay electricity bill',
    projectId: 'p1',
    priority: TaskPriority.urgent,
    position: 1000,
    dueAt: _now.subtract(const Duration(days: 2)),
    createdAt: _now,
  ),
  Task(
    id: '2',
    title:
        'A long title that should wrap onto a second line '
        'and then be cut off with an ellipsis at the end',
    position: 2000,
    createdAt: _now,
  ),
  Task(
    id: '3',
    title: 'Refactor',
    status: TaskStatus.inProgress,
    priority: TaskPriority.high,
    position: 1000,
    createdAt: _now,
  ),
  Task(
    id: '4',
    title: 'Old done',
    status: TaskStatus.done,
    position: 1000,
    completedAt: _now.subtract(const Duration(days: 60)),
    createdAt: _now,
  ),
  Task(
    id: '5',
    title: 'Recent done',
    status: TaskStatus.done,
    position: 2000,
    completedAt: _now,
    createdAt: _now,
  ),
];

bool _failSaves = false;
final _moves = <String>[];

class _FakeTasks extends TaskRepository {
  @override
  Stream<List<Task>> watch() => Stream.value(_tasks);

  @override
  Future<void> move(
    String taskId,
    TaskStatus newStatus,
    double newPosition, {
    required DateTime? completedAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_failSaves) throw Exception('offline');
    _moves.add('$taskId->${newStatus.db}@$newPosition');
  }
}

class _FakeImages extends TaskImageRepository {
  @override
  Future<String> signedUrl(String path) => Future.error('no network in tests');
}

class _FakeProjects extends ProjectRepository {
  @override
  Stream<List<Project>> watch() => Stream.value(const [
    Project(id: 'p1', name: 'Home', color: '#43A047'),
    Project(id: 'p2', name: 'Old', isArchived: true),
  ]);
}

Future<void> _pump(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentEmailProvider.overrideWith((_) => Stream.value('me@test')),
        taskRepositoryProvider.overrideWithValue(_FakeTasks()),
        projectRepositoryProvider.overrideWithValue(_FakeProjects()),
        taskImageRepositoryProvider.overrideWithValue(_FakeImages()),
      ],
      child: MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates:
            FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: const TasksScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('desktop board renders 4 columns, hides old done', (
    tester,
  ) async {
    await _pump(tester, const Size(1400, 900));
    for (final s in ['Open', 'In Progress', 'On Hold', 'Done']) {
      expect(find.text(s), findsWidgets);
    }
    expect(find.text('Recent done'), findsOneWidget);
    expect(find.text('Old done'), findsNothing);
    await tester.tap(find.text('Show all (1 older)'));
    await tester.pumpAndSettle();
    expect(find.text('Old done'), findsOneWidget);
    expect(find.text('Home'), findsWidgets); // project tag
  });

  testWidgets('narrow desktop scrolls horizontally without overflow', (
    tester,
  ) async {
    await _pump(tester, const Size(800, 600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone board shows tabs + menu', (tester) async {
    await _pump(tester, const Size(400, 800));
    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Pay electricity bill'), findsOneWidget);
    await tester.tap(find.byTooltip('Task actions').first);
    await tester.pumpAndSettle();
    expect(find.text('Move to'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('new task form opens on desktop and phone', (tester) async {
    await _pump(tester, const Size(1400, 900));
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();
    // The (taller) rich-text editor pushes the button below the fold.
    await tester.scrollUntilVisible(
      find.text('Create task'),
      200,
      scrollable: find
          .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
          .first,
    );
    await tester.tap(find.text('Create task'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
  });

  testWidgets('new task form opens full screen on phone', (tester) async {
    await _pump(tester, const Size(400, 800));
    await tester.tap(find.byTooltip('New task'));
    await tester.pumpAndSettle();
    expect(find.text('Create task'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('desktop drag & drop', () {
    setUp(() {
      _moves.clear();
      _failSaves = false;
    });

    Future<void> drag(WidgetTester tester) async {
      final from = tester.getCenter(find.text('Pay electricity bill'));
      final to = tester.getCenter(find.text('Refactor')) + const Offset(0, 40);
      final g = await tester.startGesture(from);
      await g.moveBy(const Offset(20, 0));
      await tester.pump();
      await g.moveTo(to);
      await tester.pump();
      await g.up();
      await tester.pump();
    }

    double colX(WidgetTester t, String title) =>
        t.getCenter(find.text(title).last).dx;

    testWidgets('moves card to In Progress below Refactor', (tester) async {
      await _pump(tester, const Size(1400, 900));
      await drag(tester);
      await tester.pumpAndSettle();
      expect(_moves, ['1->in_progress@2000.0']);
      expect(
        (colX(tester, 'Pay electricity bill') - colX(tester, 'Refactor')).abs(),
        lessThan(5),
      );
    });

    testWidgets('failed save reverts and shows SnackBar', (tester) async {
      _failSaves = true;
      await _pump(tester, const Size(1400, 900));
      final openX = colX(tester, 'Pay electricity bill');
      await drag(tester);
      // Optimistic: already in the new column before the save finishes.
      expect(
        (colX(tester, 'Pay electricity bill') - colX(tester, 'Refactor')).abs(),
        lessThan(5),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining("Couldn't move task"), findsOneWidget);
      expect(colX(tester, 'Pay electricity bill'), openX);
    });
  });

  group('rich text description', () {
    testWidgets('card shows 2-line preview and image count', (tester) async {
      await _pump(tester, const Size(1400, 900));
      expect(find.text('First line\nSecond line'), findsOneWidget);
      expect(find.text('Third line'), findsNothing);
      expect(find.byIcon(PhosphorIconsRegular.image), findsOneWidget);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('edit form opens rich task: toolbar, text, broken images', (
      tester,
    ) async {
      await _pump(tester, const Size(1400, 900));
      await tester.tap(find.text('Rich task'));
      await tester.pumpAndSettle();
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(find.textContaining('First line'), findsWidgets);
      expect(find.byTooltip('Insert image'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.imageBroken), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('legacy plain-text task opens with its text', (tester) async {
      await _pump(tester, const Size(1400, 900));
      await tester.tap(find.text('Legacy plain task'));
      await tester.pumpAndSettle();
      expect(find.textContaining('old plain text'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('phone: edit form fits with single-row toolbar', (
      tester,
    ) async {
      await _pump(tester, const Size(400, 800));
      await tester.tap(find.byTooltip('New task'));
      await tester.pumpAndSettle();
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
      expect(find.byType(QuillEditor), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
