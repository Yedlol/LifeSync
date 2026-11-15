import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/models/project.dart';
import '../../../projects/providers/project_providers.dart';
import '../../../projects/ui/project_edit_dialog.dart';

const _newProject = '__new__';

/// Project picker for the task form: "No project", active projects,
/// the current (possibly archived) project, and "+ New project".
class ProjectDropdown extends ConsumerStatefulWidget {
  const ProjectDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<ProjectDropdown> createState() => _ProjectDropdownState();
}

class _ProjectDropdownState extends ConsumerState<ProjectDropdown> {
  /// Bumped to reset the field after the "+ New project" flow.
  int _gen = 0;

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final active = ref.watch(activeProjectsProvider);
    final current = ref.watch(projectMapProvider)[value];
    final options = [
      ...active,
      if (current != null && current.isArchived) current,
    ];
    // If the value isn't loaded yet, show "No project" rather than asserting.
    final safeValue = options.any((p) => p.id == value) ? value : null;

    return DropdownButtonFormField<String?>(
      key: ValueKey('$safeValue#$_gen'),
      initialValue: safeValue,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Project'),
      items: [
        const DropdownMenuItem(value: null, child: Text('No project')),
        for (final p in options)
          DropdownMenuItem(
            value: p.id,
            child: ProjectLabel(project: p),
          ),
        const DropdownMenuItem(
          value: _newProject,
          child: Row(
            children: [
              Icon(Icons.add, size: 18),
              SizedBox(width: 8),
              Text('New project'),
            ],
          ),
        ),
      ],
      onChanged: (id) async {
        if (id != _newProject) return widget.onChanged(id);
        final created = await showProjectEditDialog(context);
        if (!mounted) return;
        setState(() => _gen++);
        widget.onChanged(created?.id ?? value);
      },
    );
  }
}

class ProjectLabel extends StatelessWidget {
  const ProjectLabel({super.key, required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 6, backgroundColor: project.colorValue),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(
            project.isArchived ? '${project.name} (archived)' : project.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
