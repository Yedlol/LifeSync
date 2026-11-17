import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import 'salary_settings_form.dart';
import '../../../core/theme/theme_mode_provider.dart';
import 'reminders_section.dart';
import 'sync_section.dart';
import '../../../core/offline/sync_service.dart';
import '../../../core/offline/ui/sync_indicator.dart';
import '../../../core/notifications/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(currentEmailProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: const [SyncIndicator(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(PhosphorIconsRegular.user),
              title: const Text('Logged in as'),
              subtitle: Text(email ?? '—'),
            ),
          ),
          const SizedBox(height: 16),
          const _AppearanceCard(),
          const SizedBox(height: 16),
          const SyncSection(),
          const SizedBox(height: 16),
          const RemindersSection(),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Salary & overtime',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SalarySettingsForm(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context, ref),
            icon: const Icon(PhosphorIconsRegular.signOut),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

Future<void> _logout(BuildContext context, WidgetRef ref) async {
  final s = ref.read(syncServiceProvider);
  final unsynced = s.pending + s.failed.length;
  if (unsynced > 0) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: Text(
          "${changesText(unsynced)} haven't synced and will be lost.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
  }
  // Don't leave this account's reminders on the device.
  try {
    await ref.read(notificationServiceProvider).cancelAll();
  } catch (_) {}
  // Also clears the offline cache and outbox.
  await ref.read(authRepositoryProvider).signOut();
}

class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(PhosphorIconsRegular.sun, size: 18),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(PhosphorIconsRegular.moon, size: 18),
                    label: Text('Dark'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(PhosphorIconsRegular.circleHalf, size: 18),
                    label: Text('System'),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (s) =>
                    ref.read(themeModeProvider.notifier).set(s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
