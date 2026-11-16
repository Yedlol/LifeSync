import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/finance/bills/providers/bill_providers.dart';
import '../../features/finance/providers/finance_tab_provider.dart';
import '../../features/tasks/providers/tasks_notifier.dart';
import '../../features/tasks/ui/task_form.dart';
import 'notification_service.dart';

/// The payload of a tapped notification waiting to be opened (null = none).
/// Starts with the payload that launched the app, if any.
final pendingReminderProvider =
    NotifierProvider<PendingReminderNotifier, String?>(
      PendingReminderNotifier.new,
    );

class PendingReminderNotifier extends Notifier<String?> {
  @override
  String? build() {
    final service = ref.read(notificationServiceProvider);
    final sub = service.taps.listen((p) => state = p);
    ref.onDispose(sub.cancel);
    return service.takeLaunchPayload();
  }

  void clear() => state = null;
}

/// Opens what a notification is about. Returns false if it must wait (e.g.
/// tasks haven't loaded yet), true once handled.
///
/// * `task:ID`      -> Tasks tab + that task's edit form
/// * `bill:YYYY-MM` -> Finance > Bills on that month
/// * `summary`      -> Dashboard
bool handleReminderPayload(
  BuildContext context,
  WidgetRef ref,
  String payload,
) {
  final router = GoRouter.of(context);
  if (payload.startsWith('task:')) {
    final tasks = ref.read(tasksProvider);
    if (!tasks.hasValue) return false;
    final id = payload.substring(5);
    router.go('/tasks');
    final matches = tasks.requireValue.where((t) => t.id == id);
    if (matches.isNotEmpty) {
      // After the route change, so the form opens over the Tasks tab.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showTaskForm(context, task: matches.first);
      });
    }
  } else if (payload.startsWith('bill:')) {
    final month = DateTime.tryParse('${payload.substring(5)}-01');
    if (month != null) ref.read(selectedMonthProvider.notifier).set(month);
    ref.read(financeTabProvider.notifier).set(kTabBills);
    router.go('/finance');
  } else {
    router.go('/dashboard');
  }
  return true;
}
