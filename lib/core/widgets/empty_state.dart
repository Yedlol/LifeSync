import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../theme/app_theme.dart';
import 'motion.dart';

/// Icon + one friendly line + an action button. [compact] is the small
/// version used inside lists that sit under other content.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final body = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Sp.xl,
        vertical: compact ? Sp.lg : 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? Sp.md : Sp.lg),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: compact ? 24 : 36, color: scheme.primary),
          ),
          const SizedBox(height: Sp.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: Sp.md),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: onAction,
              icon: const Icon(PhosphorIconsRegular.plus, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
    return Center(child: body).fadeSlideIn();
  }
}
