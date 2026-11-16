import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/task.dart';
import '../../models/task_enums.dart';
import '../../providers/board_providers.dart';
import '../task_form.dart';
import 'column_header.dart';
import 'task_actions.dart';
import 'task_card.dart';
import '../../../../core/widgets/empty_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// One board column on desktop. The whole column is a DragTarget; the drop
/// index is worked out from the pointer position vs. each card's midpoint.
class DesktopColumn extends ConsumerStatefulWidget {
  const DesktopColumn({super.key, required this.status, required this.data});
  final TaskStatus status;
  final BoardColumnData data;

  @override
  ConsumerState<DesktopColumn> createState() => _DesktopColumnState();
}

class _DesktopColumnState extends ConsumerState<DesktopColumn> {
  final _scroll = ScrollController();
  final _viewportKey = GlobalKey();
  final _cardKeys = <String, GlobalKey>{};
  String? _draggingId;
  int? _dropIndex;

  List<Task> get _tasks => widget.data.tasks;
  List<Task> _others(String id) => _tasks.where((t) => t.id != id).toList();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(String id) => _cardKeys.putIfAbsent(id, GlobalKey.new);

  void _onMove(Task dragging, Offset pointer) {
    var idx = 0;
    for (final t in _others(dragging.id)) {
      final box = _cardKeys[t.id]?.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final mid = box.localToGlobal(Offset.zero).dy + box.size.height / 2;
      if (pointer.dy > mid) idx++;
    }
    if (idx != _dropIndex || dragging.id != _draggingId) {
      setState(() {
        _dropIndex = idx;
        _draggingId = dragging.id;
      });
    }
    _autoScroll(pointer);
  }

  void _autoScroll(Offset pointer) {
    final box = _viewportKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !_scroll.hasClients) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    const edge = 48.0, step = 14.0;
    double? to;
    if (pointer.dy < top + edge) to = _scroll.offset - step;
    if (pointer.dy > bottom - edge) to = _scroll.offset + step;
    if (to != null) {
      _scroll.jumpTo(to.clamp(0, _scroll.position.maxScrollExtent));
    }
  }

  void _clear() => setState(() {
    _dropIndex = null;
    _draggingId = null;
  });

  void _onDrop(Task task) {
    final others = _others(task.id);
    final idx = (_dropIndex ?? others.length).clamp(0, others.length);
    _clear();
    // Dropped back where it was -> nothing to do.
    if (task.status == widget.status &&
        _tasks.indexWhere((t) => t.id == task.id) == idx) {
      return;
    }
    moveTask(
      context,
      ref,
      task,
      widget.status,
      aboveId: idx > 0 ? others[idx - 1].id : null,
      belowId: idx < others.length ? others[idx].id : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<Task>(
      onWillAcceptWithDetails: (_) => true,
      onMove: (d) => _onMove(d.data, d.offset),
      onLeave: (_) => _clear(),
      onAcceptWithDetails: (d) => _onDrop(d.data),
      builder: (context, candidates, _) {
        final hovering = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: hovering
                ? scheme.primary.withValues(alpha: 0.06)
                : const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovering
                  ? scheme.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColumnHeader(status: widget.status, count: _tasks.length),
              Expanded(
                child: SingleChildScrollView(
                  key: _viewportKey,
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _buildCards(hovering),
                  ),
                ),
              ),
              if (widget.status == TaskStatus.done)
                ShowAllDoneToggle(hiddenCount: widget.data.hiddenOldDone),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCards(bool hovering) {
    final dropIndex = hovering ? _dropIndex : null;
    final others = _draggingId == null ? _tasks : _others(_draggingId!);
    final lineBefore = dropIndex != null && dropIndex < others.length
        ? others[dropIndex].id
        : null;
    final children = <Widget>[];
    for (final t in _tasks) {
      if (t.id == lineBefore) children.add(const _DropLine());
      children.add(
        Padding(
          key: _keyFor(t.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: _DraggableCard(task: t),
        ),
      );
    }
    if (dropIndex != null && dropIndex >= others.length) {
      children.add(const _DropLine());
    }
    if (_tasks.isEmpty && dropIndex == null) {
      children.add(
        EmptyState(
          compact: true,
          icon: PhosphorIconsRegular.checkSquareOffset,
          message: 'Nothing in ${widget.status.label} yet.',
          actionLabel: 'Add task',
          onAction: () => showTaskForm(context, initialStatus: widget.status),
        ),
      );
    }
    return children;
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final card = TaskCard(
      task: task,
      onTap: () => showTaskForm(context, task: task),
      trailing: DeleteTaskButton(task: task),
    );
    return LayoutBuilder(
      builder: (context, constraints) => Draggable<Task>(
        data: task,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Transform.translate(
          offset: const Offset(-24, -16),
          child: SizedBox(
            width: constraints.maxWidth,
            child: Opacity(
              opacity: 0.95,
              child: TaskCard(task: task, elevated: true),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: card),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: card),
      ),
    );
  }
}

class _DropLine extends StatelessWidget {
  const _DropLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
