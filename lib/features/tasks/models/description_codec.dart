/// Task descriptions are stored as a Quill Delta (jsonb) so Phase 2B can
/// switch to rich text without a migration. For now we only write plain text.
library;

/// Plain text -> Quill Delta ops. Quill documents always end with "\n".
List<Map<String, dynamic>> plainTextToDelta(String text) {
  final body = text.trimRight();
  return [
    {'insert': '$body\n'},
  ];
}

/// Quill Delta (ops list, or `{"ops": [...]}`) -> plain text.
/// Non-text inserts (images, embeds) are skipped.
String deltaToPlainText(Object? delta) {
  final ops = switch (delta) {
    List<dynamic> l => l,
    Map<String, dynamic> m when m['ops'] is List => m['ops'] as List<dynamic>,
    String s => [
      {'insert': s},
    ],
    _ => const <dynamic>[],
  };
  final buf = StringBuffer();
  for (final op in ops) {
    if (op is Map && op['insert'] is String) buf.write(op['insert']);
  }
  return buf.toString().trimRight();
}

List<dynamic> _opsOf(Object? delta) => switch (delta) {
  List<dynamic> l => l,
  Map<String, dynamic> m when m['ops'] is List => m['ops'] as List<dynamic>,
  _ => const <dynamic>[],
};

/// Storage paths of all image embeds in a Quill Delta, in document order.
List<String> imagePathsFromDelta(Object? delta) => [
  for (final op in _opsOf(delta))
    if (op is Map &&
        op['insert'] is Map &&
        (op['insert'] as Map)['image'] is String)
      (op['insert'] as Map)['image'] as String,
];

/// First [maxLines] non-empty lines of the description, for task cards.
String descriptionPreviewOf(Object? delta, {int maxLines = 2}) =>
    deltaToPlainText(delta)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(maxLines)
        .join('\n');
