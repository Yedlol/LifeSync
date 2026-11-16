import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../theme/app_theme.dart';
import '../utils/breakpoints.dart';

class SwipeAction {
  const SwipeAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
}

/// Swipe-left actions on phones. On desktop (>= 700px) returns [child] as is.
class SwipeActions extends StatelessWidget {
  const SwipeActions({super.key, required this.child, required this.actions});
  final Widget child;
  final List<SwipeAction> actions;

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) return child;
    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.28 * actions.length,
        children: [
          for (final a in actions)
            CustomSlidableAction(
              onPressed: (_) => a.onPressed(),
              backgroundColor: a.color,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(kRadius),
              padding: const EdgeInsets.symmetric(horizontal: Sp.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a.icon, size: 22),
                  const SizedBox(height: Sp.xs),
                  Text(
                    a.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}
