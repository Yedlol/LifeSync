import 'description_codec.dart';
import 'task_enums.dart';

const _unset = Object();

class Task {
  const Task({
    required this.id,
    required this.title,
    this.projectId,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.open,
    this.position = 1000,
    this.dueAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? projectId;
  final String title;

  /// Raw Quill Delta ops (jsonb). Use [descriptionText] for plain text.
  final List<dynamic>? description;
  final TaskPriority priority;
  final TaskStatus status;
  final double position;
  final DateTime? dueAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get descriptionText => deltaToPlainText(description);

  /// First two non-empty description lines (task card).
  String get descriptionPreview => descriptionPreviewOf(description);

  /// Number of images embedded in the description.
  int get imageCount => imagePathsFromDelta(description).length;

  bool get isDone => status == TaskStatus.done;

  /// Overdue = due day is before today (local time) and not done.
  bool get isOverdue {
    if (dueAt == null || isDone) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = dueAt!.toLocal();
    return DateTime(due.year, due.month, due.day).isBefore(today);
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final desc = json['description'];
    return Task(
      id: json['id'] as String,
      projectId: json['project_id'] as String?,
      title: (json['title'] as String?) ?? '',
      description: desc is List
          ? desc
          : desc is Map && desc['ops'] is List
          ? desc['ops'] as List
          : null,
      priority: TaskPriority.fromDb(json['priority'] as String?),
      status: TaskStatus.fromDb(json['status'] as String?),
      position: _toDouble(json['position']),
      dueAt: _toDate(json['due_at']),
      completedAt: _toDate(json['completed_at']),
      createdAt: _toDate(json['created_at']),
      updatedAt: _toDate(json['updated_at']),
    );
  }

  /// Writable columns only (id, user_id and timestamps are set by the DB).
  Map<String, dynamic> toJson() => {
    'project_id': projectId,
    'title': title,
    'description': description ?? plainTextToDelta(''),
    'priority': priority.db,
    'status': status.db,
    'position': position,
    'due_at': dueAt?.toUtc().toIso8601String(),
    'completed_at': completedAt?.toUtc().toIso8601String(),
  };

  Task copyWith({
    Object? projectId = _unset,
    String? title,
    Object? description = _unset,
    TaskPriority? priority,
    TaskStatus? status,
    double? position,
    Object? dueAt = _unset,
    Object? completedAt = _unset,
  }) => Task(
    id: id,
    projectId: identical(projectId, _unset)
        ? this.projectId
        : projectId as String?,
    title: title ?? this.title,
    description: identical(description, _unset)
        ? this.description
        : description as List<dynamic>?,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    position: position ?? this.position,
    dueAt: identical(dueAt, _unset) ? this.dueAt : dueAt as DateTime?,
    completedAt: identical(completedAt, _unset)
        ? this.completedAt
        : completedAt as DateTime?,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// completed_at rule: entering 'done' stamps now, leaving 'done' clears it,
  /// staying in 'done' keeps the original stamp.
  DateTime? completedAtFor(TaskStatus newStatus) {
    if (newStatus != TaskStatus.done) return null;
    return isDone ? (completedAt ?? DateTime.now()) : DateTime.now();
  }
}

double _toDouble(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? 1000,
  _ => 1000,
};

DateTime? _toDate(Object? v) => v is String ? DateTime.tryParse(v) : null;
