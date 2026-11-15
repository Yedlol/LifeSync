import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task_enums.dart';
import '../../providers/board_providers.dart';
import 'task_tags.dart';

const kDoneGreen = Color(0xFF2E7D32);

Color badgeColorFor(BuildContext context, TaskStatus s) =>
    s == TaskStatus.done ? kDoneGreen : Theme.of(context).colorScheme.primary;

/// Column title + count badge.
class ColumnHeader extends StatelessWidget {
  const ColumnHeader({super.key, required this.status, required this.count});
  final TaskStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Text(
            status.label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          CountBadge(count: count, color: badgeColorFor(context, status)),
        ],
      ),
    );
  }
}

/// Footer of the Done column: toggles the 30-day window.
class ShowAllDoneToggle extends ConsumerWidget {
  const ShowAllDoneToggle({super.key, required this.hiddenCount});
  final int hiddenCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAll = ref.watch(showAllDoneProvider);
    if (!showAll && hiddenCount == 0) return const SizedBox.shrink();
    return Center(
      child: TextButton(
        onPressed: () => ref.read(showAllDoneProvider.notifier).toggle(),
        child: Text(
          showAll ? 'Show last 30 days only' : 'Show all ($hiddenCount older)',
        ),
      ),
    );
  }
}
