import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/offline/outbox.dart';
import '../../../core/offline/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';

/// Settings card: status, last synced time, "Sync now" and the list of
/// changes the server rejected (retry or discard each).
class SyncSection extends ConsumerStatefulWidget {
  const SyncSection({super.key});

  @override
  ConsumerState<SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends ConsumerState<SyncSection> {
  bool _busy = false;

  Future<void> _syncNow() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(syncServiceProvider.notifier).syncNow();
      final s = ref.read(syncServiceProvider);
      if (!s.online) {
        messenger.showSnackBar(
          const SnackBar(content: Text("You're offline. Try again later.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(syncServiceProvider);
    final text = Theme.of(context).textTheme;
    final status = switch (s.phase) {
      SyncPhase.synced => 'All changes synced',
      SyncPhase.syncing =>
        s.pending > 0 ? '${changesText(s.pending)} to sync' : 'Syncing…',
      SyncPhase.offline =>
        s.pending > 0
            ? 'Offline · ${changesText(s.pending)} waiting'
            : 'Offline',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Sp.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sync', style: text.titleMedium),
            const SizedBox(height: Sp.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status, style: text.bodyMedium),
                      Text(
                        lastSyncedText(s.lastSyncedAt, DateTime.now()),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: _busy || s.syncing ? null : _syncNow,
                  icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                  label: const Text('Sync now'),
                ),
              ],
            ),
            if (s.failed.isNotEmpty) ...[
              const SizedBox(height: Sp.lg),
              Text(
                'Failed changes (${s.failed.length})',
                style: text.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: Sp.xs),
              for (final op in s.failed) _FailedTile(op: op),
            ],
          ],
        ),
      ),
    );
  }
}

class _FailedTile extends ConsumerWidget {
  const _FailedTile({required this.op});
  final OutboxOp op;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.read(syncServiceProvider.notifier);
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: Sp.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            PhosphorIconsRegular.warningCircle,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: Sp.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(describeOp(op), style: text.bodyMedium),
                Text(
                  '${op.error ?? 'Rejected by the server'} · '
                  '${formatShortDate(op.createdAt)}',
                  style: text.bodySmall,
                ),
                Wrap(
                  spacing: Sp.sm,
                  children: [
                    TextButton(
                      onPressed: () => sync.retryFailed(op),
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () => sync.discardFailed(op),
                      child: const Text('Discard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
