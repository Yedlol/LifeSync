import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/breakpoints.dart';
import '../../projects/ui/project_manager.dart';
import '../providers/board_providers.dart';
import '../providers/tasks_notifier.dart';
import 'task_form.dart';
import 'widgets/desktop_board.dart';
import 'widgets/phone_board.dart';
import 'widgets/task_filter_bar.dart';
import '../../../core/widgets/skeletons.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  void _newTask(BuildContext context, WidgetRef ref) => showTaskForm(
    context,
    initialProjectId: ref.read(taskFilterProvider).projectId,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktop(context);
    final board = ref.watch(boardProvider);

    final actions = desktop
        ? [
            OutlinedButton.icon(
              onPressed: () => showProjectManager(context),
              icon: const Icon(PhosphorIconsRegular.folder, size: 18),
              label: const Text('Projects'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: () => _newTask(context, ref),
              icon: const Icon(PhosphorIconsRegular.plus, size: 18),
              label: const Text('New task'),
            ),
            const SizedBox(width: 12),
          ]
        : [
            IconButton(
              tooltip: 'Projects',
              icon: const Icon(PhosphorIconsRegular.folder),
              onPressed: () => showProjectManager(context),
            ),
            IconButton(
              tooltip: 'New task',
              icon: const Icon(PhosphorIconsRegular.plus),
              onPressed: () => _newTask(context, ref),
            ),
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks'), actions: actions),
      body: Column(
        children: [
          TaskFilterBar(desktop: desktop),
          Expanded(
            child: board.when(
              skipLoadingOnReload: true,
              loading: () => const ListSkeleton(),
              error: (e, _) =>
                  _ErrorView(onRetry: () => ref.invalidate(tasksProvider)),
              data: (columns) => desktop
                  ? DesktopBoard(columns: columns)
                  : PhoneBoard(columns: columns),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            PhosphorIconsRegular.cloudSlash,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          const Text("Couldn't load tasks."),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
