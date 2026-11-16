import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../projects/providers/project_providers.dart';
import '../../models/task_enums.dart';
import '../../providers/board_providers.dart';
import 'project_dropdown.dart';

/// Search by title + project dropdown + priority chips.
class TaskFilterBar extends ConsumerStatefulWidget {
  const TaskFilterBar({super.key, required this.desktop});
  final bool desktop;

  @override
  ConsumerState<TaskFilterBar> createState() => _TaskFilterBarState();
}

class _TaskFilterBarState extends ConsumerState<TaskFilterBar> {
  late final _search = TextEditingController(
    text: ref.read(taskFilterProvider).query,
  );

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(taskFilterProvider);
    final notifier = ref.read(taskFilterProvider.notifier);

    final search = SizedBox(
      width: widget.desktop ? 240 : double.infinity,
      child: TextField(
        controller: _search,
        onChanged: notifier.setQuery,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search tasks',
          prefixIcon: const Icon(
            PhosphorIconsRegular.magnifyingGlass,
            size: 20,
          ),
          suffixIcon: filter.query.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(PhosphorIconsRegular.x, size: 18),
                  onPressed: () {
                    _search.clear();
                    notifier.setQuery('');
                  },
                ),
        ),
      ),
    );

    final controls = <Widget>[
      _ProjectFilter(value: filter.projectId, onChanged: notifier.setProject),
      for (final p in TaskPriority.values)
        FilterChip(
          label: Text(p.label),
          selected: filter.priorities.contains(p),
          onSelected: (_) => notifier.togglePriority(p),
          selectedColor: p.color.withValues(alpha: 0.18),
          checkmarkColor: p.color,
          visualDensity: VisualDensity.compact,
        ),
    ];

    if (widget.desktop) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [search, ...controls],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        children: [
          search,
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in controls)
                  Padding(padding: const EdgeInsets.only(right: 6), child: c),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectFilter extends ConsumerWidget {
  const _ProjectFilter({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeProjectsProvider);
    final current = ref.watch(projectMapProvider)[value];
    final options = [
      ...active,
      if (current != null && current.isArchived) current,
    ];
    final safeValue = options.any((p) => p.id == value) ? value : null;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: safeValue,
          isDense: true,
          onChanged: onChanged,
          items: [
            const DropdownMenuItem(value: null, child: Text('All projects')),
            for (final p in options)
              DropdownMenuItem(
                value: p.id,
                child: ProjectLabel(project: p),
              ),
          ],
        ),
      ),
    );
  }
}
