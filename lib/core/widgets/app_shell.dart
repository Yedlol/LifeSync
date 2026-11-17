import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/breakpoints.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notifications/notification_router.dart';
import '../offline/sync_service.dart';
import '../offline/ui/offline_banner.dart';
import '../notifications/reminder_scheduler.dart';
import '../../features/tasks/providers/tasks_notifier.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _Tab(
    'Dashboard',
    PhosphorIconsRegular.squaresFour,
    PhosphorIconsFill.squaresFour,
  ),
  _Tab('Tasks', PhosphorIconsRegular.kanban, PhosphorIconsFill.kanban),
  _Tab('Finance', PhosphorIconsRegular.wallet, PhosphorIconsFill.wallet),
  _Tab('Settings', PhosphorIconsRegular.gear, PhosphorIconsFill.gear),
];

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StatefulNavigationShell get shell => widget.shell;

  void _go(int i) =>
      shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  void initState() {
    super.initState();
    // A notification may have launched the app.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
    // Signed in / app opened: send pending changes and refresh the cache.
    ref.read(syncServiceProvider.notifier).refreshSoon();
  }

  void _openPending() {
    if (!mounted) return;
    final payload = ref.read(pendingReminderProvider);
    if (payload == null) return;
    if (handleReminderPayload(context, ref, payload)) {
      ref.read(pendingReminderProvider.notifier).clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSchedulerProvider); // reschedules reminders on changes
    ref.listen(pendingReminderProvider, (_, _) => _openPending());
    // A tapped task reminder may be waiting for tasks to load.
    ref.listen(tasksProvider, (_, _) => _openPending());
    if (isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final t in _tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.selectedIcon),
                    label: Text(t.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: shell),
                  const OfflineBanner(),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: shell),
          const OfflineBanner(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
