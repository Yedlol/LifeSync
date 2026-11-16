import 'package:flutter/material.dart';

import '../../tasks/models/task.dart';
import '../../tasks/models/task_enums.dart';

/// Why a task is on the dashboard's "Needs attention" list, in list order.
enum AttentionKind { overdue, today, soon, priority }

const kAttentionMax = 5;
const kSoonDays = 7;

class AttentionItem {
  const AttentionItem(this.task, this.kind, this.daysUntilDue);
  final Task task;
  final AttentionKind kind;

  /// Whole calendar days from today to the due date (null = no due date).
  final int? daysUntilDue;

  String get dueText => switch (kind) {
    AttentionKind.overdue =>
      'Overdue ${-daysUntilDue!} ${daysUntilDue == -1 ? 'day' : 'days'}',
    AttentionKind.today => 'Due today',
    AttentionKind.soon =>
      daysUntilDue == 1 ? 'Due tomorrow' : 'Due in $daysUntilDue days',
    AttentionKind.priority => '${task.priority.label} priority',
  };

  Color get color => switch (kind) {
    AttentionKind.overdue => const Color(0xFFD32F2F),
    AttentionKind.today => const Color(0xFF9A6200),
    AttentionKind.soon => const Color(0xFF546E7A),
    AttentionKind.priority => task.priority.color,
  };
}

int? _daysUntil(DateTime? due, DateTime now) {
  if (due == null) return null;
  final d = due.toLocal();
  // UTC date-only math so daylight-saving shifts can't skew the day count.
  final a = DateTime.utc(d.year, d.month, d.day);
  final b = DateTime.utc(now.year, now.month, now.day);
  return a.difference(b).inDays;
}

/// Not-done tasks worth a look: overdue (oldest first), due today, due in the
/// next [kSoonDays] days (soonest first), then High/Urgent tasks in progress
/// (most severe first). Each task appears once; at most [max] returned.
List<AttentionItem> attentionTasks(
  Iterable<Task> tasks,
  DateTime now, {
  int max = kAttentionMax,
}) {
  final groups = {for (final k in AttentionKind.values) k: <AttentionItem>[]};
  for (final t in tasks) {
    if (t.isDone) continue;
    final days = _daysUntil(t.dueAt, now);
    final AttentionKind? kind;
    if (days != null && days < 0) {
      kind = AttentionKind.overdue;
    } else if (days == 0) {
      kind = AttentionKind.today;
    } else if (days != null && days <= kSoonDays) {
      kind = AttentionKind.soon;
    } else if (t.status == TaskStatus.inProgress &&
        (t.priority == TaskPriority.high ||
            t.priority == TaskPriority.urgent)) {
      kind = AttentionKind.priority;
    } else {
      kind = null;
    }
    if (kind != null) groups[kind]!.add(AttentionItem(t, kind, days));
  }

  int byDue(AttentionItem a, AttentionItem b) {
    final c = (a.daysUntilDue ?? 0).compareTo(b.daysUntilDue ?? 0);
    return c != 0 ? c : b.task.priority.index.compareTo(a.task.priority.index);
  }

  groups[AttentionKind.overdue]!.sort(byDue);
  groups[AttentionKind.today]!.sort(byDue);
  groups[AttentionKind.soon]!.sort(byDue);
  groups[AttentionKind.priority]!.sort(
    (a, b) => b.task.priority.index.compareTo(a.task.priority.index),
  );
  return [
    for (final k in AttentionKind.values) ...groups[k]!,
  ].take(max).toList();
}
