/// Fractional ordering for tasks inside a board column.
library;

const kPositionStep = 1000.0;
const kMinGap = 0.001;

class MovePlan {
  const MovePlan(this.position, [this.renumbered = const {}]);

  /// New position of the moved task.
  final double position;

  /// Other tasks in the column whose position changed (only on renumber).
  final Map<String, double> renumbered;
}

/// Where a moved item should land.
///
/// [column] is the FULL target column sorted by position, excluding the moved
/// item, as (id, position) pairs. [aboveId]/[belowId] are the neighbours the
/// user dropped between (from the visible, possibly filtered list); null means
/// "top" / "bottom".
MovePlan planMove({
  required List<(String, double)> column,
  required String movingId,
  String? aboveId,
  String? belowId,
}) {
  if (column.isEmpty) return const MovePlan(kPositionStep);

  double? posOf(String? id) {
    if (id == null) return null;
    for (final (cid, p) in column) {
      if (cid == id) return p;
    }
    return null;
  }

  final above = posOf(aboveId);
  final below = posOf(belowId);

  if (above == null && below == null) {
    // Nothing visible to drop next to (e.g. filtered) -> append at bottom.
    return MovePlan(column.last.$2 + kPositionStep);
  }
  if (above == null) return MovePlan(below! - kPositionStep);
  if (below == null) return MovePlan(above + kPositionStep);

  if ((below - above).abs() >= kMinGap) return MovePlan((above + below) / 2);

  // Gap too small -> renumber the whole column 1000, 2000, 3000...
  final ids = [for (final (id, _) in column) id];
  ids.insert(ids.indexOf(aboveId!) + 1, movingId);
  final renumbered = <String, double>{};
  double? moved;
  for (var i = 0; i < ids.length; i++) {
    final p = (i + 1) * kPositionStep;
    if (ids[i] == movingId) {
      moved = p;
    } else if (posOf(ids[i]) != p) {
      renumbered[ids[i]] = p;
    }
  }
  return MovePlan(moved!, renumbered);
}

/// Position for a task added to the top of [column] (sorted, any order).
double topPosition(Iterable<double> column) {
  if (column.isEmpty) return kPositionStep;
  return column.reduce((a, b) => a < b ? a : b) - kPositionStep;
}
