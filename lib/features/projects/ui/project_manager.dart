import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/responsive_dialog.dart';
import '../models/project.dart';
import '../providers/project_providers.dart';
import 'project_edit_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeletons.dart';

Future<void> showProjectManager(BuildContext context) => showResponsiveDialog(
  context,
  title: 'Projects',
  maxWidth: 480,
  builder: (_) => const ProjectManager(),
);

class ProjectManager extends ConsumerStatefulWidget {
  const ProjectManager({super.key});

  @override
  ConsumerState<ProjectManager> createState() => _ProjectManagerState();
}

class _ProjectManagerState extends ConsumerState<ProjectManager> {
  bool _showArchived = false;

  Future<void> _setArchived(Project p, bool archived) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(projectsProvider.notifier).setArchived(p, archived);
    } catch (_) {
      showSnack(messenger, 'Could not update "${p.name}".');
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(projectsProvider);
    final all = async.value ?? const <Project>[];
    final active = all.where((p) => !p.isArchived).toList();
    final archived = all.where((p) => p.isArchived).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: OutlinedButton.icon(
            onPressed: () => showProjectEditDialog(context),
            icon: const Icon(PhosphorIconsRegular.plus),
            label: const Text('New project'),
          ),
        ),
        Flexible(
          child: async.isLoading && all.isEmpty
              ? const ListSkeleton(itemCount: 3, shrink: true)
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    if (active.isEmpty)
                      EmptyState(
                        compact: true,
                        icon: PhosphorIconsRegular.folderSimple,
                        message: 'No projects yet. Group your tasks into one.',
                        actionLabel: 'New project',
                        onAction: () => showProjectEditDialog(context),
                      ),
                    for (final p in active)
                      _ProjectTile(
                        project: p,
                        onEdit: () =>
                            showProjectEditDialog(context, project: p),
                        onArchive: () => _setArchived(p, true),
                      ),
                    if (archived.isNotEmpty)
                      ListTile(
                        dense: true,
                        title: Text('Archived (${archived.length})'),
                        trailing: Icon(
                          _showArchived
                              ? PhosphorIconsRegular.caretUp
                              : PhosphorIconsRegular.caretDown,
                        ),
                        onTap: () =>
                            setState(() => _showArchived = !_showArchived),
                      ),
                    if (_showArchived)
                      for (final p in archived)
                        _ProjectTile(
                          project: p,
                          onEdit: () =>
                              showProjectEditDialog(context, project: p),
                          onArchive: () => _setArchived(p, false),
                        ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({
    required this.project,
    required this.onEdit,
    required this.onArchive,
  });
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final archived = project.isArchived;
    return ListTile(
      leading: CircleAvatar(radius: 8, backgroundColor: project.colorValue),
      title: Text(
        project.name,
        style: archived ? const TextStyle(color: Colors.black45) : null,
      ),
      onTap: onEdit,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(PhosphorIconsRegular.pencilSimple),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: archived ? 'Unarchive' : 'Archive',
            icon: Icon(
              archived
                  ? PhosphorIconsRegular.arrowCounterClockwise
                  : PhosphorIconsRegular.archive,
            ),
            onPressed: onArchive,
          ),
        ],
      ),
    );
  }
}
