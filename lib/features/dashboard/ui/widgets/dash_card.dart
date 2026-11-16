import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_theme.dart';

/// Shell shared by the dashboard cards: icon + title, body, "View …" footer.
class DashCard extends StatelessWidget {
  const DashCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.footerLabel,
    this.onFooter,
    this.onTap,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final String? footerLabel;
  final VoidCallback? onFooter;

  /// Makes the whole card tappable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Sp.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Sp.sm),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: scheme.primary),
                  ),
                  const SizedBox(width: Sp.md),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: Sp.md),
              child,
              if (footerLabel != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onFooter,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(PhosphorIconsRegular.arrowRight, size: 16),
                    label: Text(footerLabel!),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmering placeholder for a card body while its data loads.
class CardSkeleton extends StatelessWidget {
  const CardSkeleton({super.key, this.lines = 3});
  final int lines;

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: Sp.sm),
            child: Text('Loading placeholder text for this row'),
          ),
      ],
    ),
  );
}

/// Shown when a card's data failed to load.
class CardMessage extends StatelessWidget {
  const CardMessage(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Sp.sm),
    child: Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
}
