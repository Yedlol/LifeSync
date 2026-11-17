import 'package:flutter/material.dart';

/// 8 preset colours for projects, stored as "#RRGGBB".
const kProjectColors = <String>[
  '#1E6FD9', // blue
  '#00897B', // teal
  '#43A047', // green
  '#F9A825', // amber
  '#FB8C00', // orange
  '#E53935', // red
  '#D81B60', // pink
  '#8E24AA', // purple
];

class Project {
  const Project({
    required this.id,
    required this.name,
    this.color = '#1E6FD9',
    this.isArchived = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String color;
  final bool isArchived;
  final DateTime? createdAt;

  Color get colorValue => parseHexColor(color);

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    color: (json['color'] as String?) ?? kProjectColors.first,
    isArchived: (json['is_archived'] as bool?) ?? false,
    createdAt: json['created_at'] is String
        ? DateTime.tryParse(json['created_at'] as String)
        : null,
  );

  /// Writable columns only.
  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color,
    'is_archived': isArchived,
  };

  /// Full row as cached offline.
  Map<String, dynamic> toRow() => {
    'id': id,
    ...toJson(),
    'created_at': createdAt?.toUtc().toIso8601String(),
  };

  Project copyWith({String? name, String? color, bool? isArchived}) => Project(
    id: id,
    name: name ?? this.name,
    color: color ?? this.color,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt,
  );
}

Color parseHexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? const Color(0xFF1E6FD9) : Color(v);
}
