import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_format.dart';
import '../../../projects/providers/project_providers.dart';
import '../../models/task.dart';
import 'task_tags.dart';

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.trailing,
    this.elevated = false,
  });

  final Task task;
  final VoidCallback? onTap;

  /// Delete icon (desktop) or ⋮ menu (phone).
  final Widget? trailing;

  /// True for the drag feedback.
  final bool elevated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = task.projectId == null
        ? null
        : ref.watch(projectMapProvider)[task.projectId];
    final grey = Colors.grey.shade600;

    return Card(
      margin: EdgeInsets.zero,
      elevation: elevated ? 6 : 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: task.priority.color, width: 4),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(10, 8, 4, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isDone ? grey : null,
                        ),
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              if (task.descriptionPreview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task.descriptionPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: grey),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  TaskTag(
                    label: task.priority.label,
                    color: task.priority.color,
                  ),
                  if (project != null)
                    TaskTag(label: project.name, color: project.colorValue),
                  if (task.imageCount > 0)
                    TaskTag(
                      icon: Icons.image_outlined,
                      label: '${task.imageCount}',
                      color: grey,
                    ),
                  if (task.dueAt != null)
                    TaskTag(
                      icon: Icons.event,
                      label: formatShortDate(task.dueAt!),
                      color: task.isOverdue ? Colors.red.shade700 : grey,
                    ),
                ],
              ),
              if (task.createdAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'created ${formatDate(task.createdAt!)}',
                  style: TextStyle(fontSize: 11, color: grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
