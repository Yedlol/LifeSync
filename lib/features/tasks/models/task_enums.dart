import 'package:flutter/material.dart';

/// Mirrors the Postgres enum `task_status`.
enum TaskStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  onHold('on_hold', 'On Hold'),
  done('done', 'Done');

  const TaskStatus(this.db, this.label);
  final String db;
  final String label;

  static TaskStatus fromDb(String? v) =>
      values.firstWhere((s) => s.db == v, orElse: () => TaskStatus.open);
}

/// Mirrors the Postgres enum `task_priority`.
enum TaskPriority {
  low('low', 'Low', Color(0xFF9E9E9E)),
  medium('medium', 'Medium', Color(0xFFFB8C00)),
  high('high', 'High', Color(0xFFE64A19)),
  urgent('urgent', 'Urgent', Color(0xFFD32F2F));

  const TaskPriority(this.db, this.label, this.color);
  final String db;
  final String label;
  final Color color;

  static TaskPriority fromDb(String? v) =>
      values.firstWhere((p) => p.db == v, orElse: () => TaskPriority.medium);
}
