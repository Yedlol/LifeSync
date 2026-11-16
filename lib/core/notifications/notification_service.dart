import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_planner.dart';

const kTimeZoneName = 'Asia/Kuala_Lumpur';

/// Id of the "Send test notification" notification (planner ids are >= 100).
const kTestNotificationId = 1;

/// What the rest of the app needs from local notifications. The real
/// implementation is [LocalNotificationService]; tests use a fake.
abstract class NotificationService {
  /// False on web and other unsupported platforms (everything then no-ops).
  bool get supported;

  /// Payloads of notifications tapped while the app is running.
  Stream<String> get taps;

  /// Payload of the notification that launched the app (once), if any.
  String? takeLaunchPayload();

  /// Asks for the Android 13+ notification permission. True when allowed
  /// (always true on Windows).
  Future<bool> requestPermission();

  /// Current wall-clock time in Asia/Kuala_Lumpur.
  DateTime now();

  /// Cancels everything, then schedules [plan].
  Future<void> reschedule(List<PlannedReminder> plan);

  Future<void> cancelAll();

  /// Schedules a one-off test notification.
  Future<void> scheduleTest(Duration after);
}

final notificationServiceProvider = Provider<NotificationService>(
  (_) => LocalNotificationService.instance,
);

class LocalNotificationService implements NotificationService {
  LocalNotificationService._();
  static final instance = LocalNotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();
  bool _ready = false;
  String? _launchPayload;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Task and bill reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    windows: WindowsNotificationDetails(),
  );

  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.windows);

  @override
  Stream<String> get taps => _taps.stream;

  @override
  String? takeLaunchPayload() {
    final p = _launchPayload;
    _launchPayload = null;
    return p;
  }

  /// Call once at startup. Never throws: reminders just stay off on failure.
  Future<void> init() async {
    if (!supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(kTimeZoneName));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          windows: WindowsInitializationSettings(
            appName: 'LifeSync',
            appUserModelId: 'com.example.lifesync',
            guid: 'b3f2c1a8-6d4e-4f5a-9c7b-2e1d8a0f3c56',
          ),
        ),
        onDidReceiveNotificationResponse: (r) {
          final p = r.payload;
          if (p != null && p.isNotEmpty) _taps.add(p);
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchPayload = launch!.notificationResponse?.payload;
      }
      _ready = true;
    } catch (e) {
      debugPrint('notification init failed: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  DateTime now() => tz.TZDateTime.now(tz.getLocation(kTimeZoneName));

  Future<void> _schedule(
    int id,
    DateTime when,
    String title,
    String body,
    String payload,
  ) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    payload: payload,
    scheduledDate: tz.TZDateTime(
      tz.getLocation(kTimeZoneName),
      when.year,
      when.month,
      when.day,
      when.hour,
      when.minute,
      when.second,
    ),
    notificationDetails: _details,
    // Inexact: no exact-alarm permission needed (may fire a little late).
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<void> reschedule(List<PlannedReminder> plan) async {
    if (!_ready) return;
    await _plugin.cancelAll();
    final now = this.now();
    for (final r in plan) {
      if (!r.when.isAfter(now)) continue; // never schedule the past
      try {
        await _schedule(r.id, r.when, r.title, r.body, r.payload);
      } catch (e) {
        debugPrint('schedule ${r.id} failed: $e');
      }
    }
  }

  @override
  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }

  @override
  Future<void> scheduleTest(Duration after) async {
    if (!_ready) return;
    await _schedule(
      kTestNotificationId,
      now().add(after),
      'LifeSync reminders',
      'Test notification — reminders are working.',
      'summary',
    );
  }
}
