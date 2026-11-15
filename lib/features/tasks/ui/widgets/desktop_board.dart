import 'package:flutter/material.dart';

import '../../models/task_enums.dart';
import '../../providers/board_providers.dart';
import 'desktop_column.dart';

const _minColumnWidth = 240.0;
const _gap = 12.0;

/// 4 columns side by side; scrolls horizontally if the window is too narrow.
class DesktopBoard extends StatelessWidget {
  const DesktopBoard({super.key, required this.columns});
  final Map<TaskStatus, BoardColumnData> columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const n = 4;
        final needed = n * _minColumnWidth + (n + 1) * _gap;
        final fits = constraints.maxWidth >= needed;
        final width = fits
            ? (constraints.maxWidth - (n + 1) * _gap) / n
            : _minColumnWidth;

        final row = Padding(
          padding: const EdgeInsets.fromLTRB(_gap, 4, 0, _gap),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final s in TaskStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: _gap),
                  child: SizedBox(
                    width: width,
                    child: DesktopColumn(
                      status: s,
                      data: columns[s] ?? const BoardColumnData([]),
                    ),
                  ),
                ),
            ],
          ),
        );
        if (fits) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(height: constraints.maxHeight, child: row),
        );
      },
    );
  }
}
