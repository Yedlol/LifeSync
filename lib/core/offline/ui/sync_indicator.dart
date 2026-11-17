import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../sync_service.dart';

/// App bar status: synced ✓ / syncing ↻ / offline, with the number of
/// pending changes. Tap opens Settings (Sync section).
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(syncServiceProvider);
    final scheme = Theme.of(context).colorScheme;
    final failed = s.failed.length;
    final (icon, color, text) = switch (s.phase) {
      SyncPhase.synced => (
        PhosphorIconsRegular.checkCircle,
        scheme.primary,
        'All changes synced',
      ),
      SyncPhase.syncing => (
        PhosphorIconsRegular.arrowsClockwise,
        scheme.primary,
        s.pending > 0 ? 'Syncing ${changesText(s.pending)}…' : 'Syncing…',
      ),
      SyncPhase.offline => (
        PhosphorIconsRegular.cloudSlash,
        scheme.onSurfaceVariant,
        s.pending > 0
            ? 'Offline · ${changesText(s.pending)} waiting to sync'
            : 'Offline',
      ),
    };
    final tooltip = failed > 0
        ? '$text · ${changesText(failed)} failed'
        : text;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => GoRouter.maybeOf(context)?.go('/settings'),
      icon: Badge(
        isLabelVisible: s.pending > 0 || failed > 0,
        backgroundColor: failed > 0 ? scheme.error : scheme.primary,
        label: Text('${failed > 0 ? failed : s.pending}'),
        child: Icon(icon, color: failed > 0 ? scheme.error : color),
      ),
    );
  }
}
