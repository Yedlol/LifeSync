import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/notifications/reminder_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_dialog.dart';

/// Settings > Reminders (stored on this device only).
class RemindersSection extends ConsumerWidget {
  const RemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(notificationServiceProvider);
    if (!service.supported) {
      return const Card(
        child: ListTile(
          leading: Icon(PhosphorIconsRegular.bellSlash),
          title: Text('Reminders'),
          subtitle: Text('Reminders are available on Android and Windows.'),
        ),
      );
    }
    final s = ref.watch(reminderSettingsProvider).value;
    if (s == null) return const SizedBox.shrink();
    final notifier = ref.read(reminderSettingsProvider.notifier);
    final on = s.masterOn;

    Future<void> setMaster(bool v) async {
      final messenger = ScaffoldMessenger.of(context);
      if (v && !await service.requestPermission()) {
        showSnack(
          messenger,
          'Notifications are blocked. Allow them for LifeSync in system settings.',
        );
        return;
      }
      await notifier.save(s.copyWith(masterOn: v));
    }

    Future<void> pickTime(
      int minutes,
      ReminderSettings Function(int) apply,
    ) async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
      if (t != null) await notifier.save(apply(t.hour * 60 + t.minute));
    }

    String fmt(int m) =>
        TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context);

    Future<void> sendTest() async {
      final messenger = ScaffoldMessenger.of(context);
      if (!await service.requestPermission()) {
        showSnack(messenger, 'Notifications are blocked in system settings.');
        return;
      }
      await service.scheduleTest(const Duration(seconds: 5));
      showSnack(messenger, 'Test notification coming in about 5 seconds…');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sp.sm),
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(PhosphorIconsRegular.bell),
              title: const Text('Reminders'),
              subtitle: const Text('Task and bill reminders on this device'),
              value: on,
              onChanged: setMaster,
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Task reminders'),
              subtitle: const Text('A day before and on the due day'),
              value: s.tasksOn,
              onChanged: on
                  ? (v) => notifier.save(s.copyWith(tasksOn: v))
                  : null,
            ),
            SwitchListTile(
              title: const Text('Bill reminders'),
              subtitle: const Text('3 days before and on the due date'),
              value: s.billsOn,
              onChanged: on
                  ? (v) => notifier.save(s.copyWith(billsOn: v))
                  : null,
            ),
            SwitchListTile(
              title: const Text('Daily summary'),
              subtitle: const Text('Only on days something is due'),
              value: s.summaryOn,
              onChanged: on
                  ? (v) => notifier.save(s.copyWith(summaryOn: v))
                  : null,
            ),
            ListTile(
              enabled: on,
              title: const Text('Reminder time'),
              trailing: Text(fmt(s.reminderMinutes)),
              onTap: on
                  ? () => pickTime(
                      s.reminderMinutes,
                      (m) => s.copyWith(reminderMinutes: m),
                    )
                  : null,
            ),
            ListTile(
              enabled: on && s.summaryOn,
              title: const Text('Summary time'),
              trailing: Text(fmt(s.summaryMinutes)),
              onTap: on && s.summaryOn
                  ? () => pickTime(
                      s.summaryMinutes,
                      (m) => s.copyWith(summaryMinutes: m),
                    )
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Sp.lg, Sp.sm, Sp.lg, Sp.sm),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: sendTest,
                  icon: const Icon(
                    PhosphorIconsRegular.paperPlaneTilt,
                    size: 18,
                  ),
                  label: const Text('Send test notification'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
