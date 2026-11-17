import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../theme/app_theme.dart';
import '../sync_service.dart';

/// Strip shown under the content while offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  static String message(int pending) => pending == 0
      ? "You're offline — changes will sync when you're back online."
      : "You're offline — ${changesText(pending)} will sync when "
            "you're back online.";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(syncServiceProvider);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: s.online
          ? const SizedBox(width: double.infinity)
          : Material(
              color: scheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sp.lg,
                  vertical: Sp.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.cloudSlash,
                      size: 18,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: Sp.md),
                    Expanded(
                      child: Text(
                        message(s.pending),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
