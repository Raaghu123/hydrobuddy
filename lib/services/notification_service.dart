import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  /// Fired for notification taps / action buttons.
  /// Values: 'open' | 'drank_250' | 'snooze_15'
  static Future<void> Function(String action)? onAction;

  static const int reminderId = 1001;

  static Future<void> init() async {
    if (_init) return;
    // No device-timezone plugin needed: we schedule one-shot alarms as
    // absolute instants (tz.UTC), so wall-clock zones can't skew intervals.
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (resp) {
        final action = resp.actionId ?? 'open';
        debugPrint('🔔 tap: $action');
        onAction?.call(action);
      },
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(
        const AndroidNotificationChannel(
      'hydration_reminders',
      'Hydration Reminders',
      description: 'Gentle nudges to drink water',
      importance: Importance.high,
    ));
    // Android 13+ runtime permission + exact-alarm permission (best effort).
    try {
      await androidImpl?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('notif permission request failed: $e');
    }
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('exact alarm request failed: $e');
    }
    _init = true;
  }

  /// Schedule the NEXT single reminder at [fireAt] with the live cup phrase.
  /// Chain-of-one: every app open / drink / tap re-schedules the next one,
  /// so intervals like 30/45/60 min and quiet hours are always honoured.
  static Future<void> scheduleNext({
    required DateTime fireAt,
    required String phrase,
  }) async {
    var when = fireAt;
    if (when.isBefore(DateTime.now().add(const Duration(seconds: 10)))) {
      when = DateTime.now().add(const Duration(minutes: 30));
    }
    final android = AndroidNotificationDetails(
      'hydration_reminders',
      'Hydration Reminders',
      channelDescription: 'Gentle nudges to drink water',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: const [
        AndroidNotificationAction('drank_250', 'Log 250ml'),
        AndroidNotificationAction('snooze_15', 'Snooze 15m'),
      ],
    );
    try {
      await _plugin.zonedSchedule(
        reminderId,
        'Time to hydrate!',
        '$phrase — tap to log your drink',
        // Same instant as the local wall-clock time (one-shot, no repeats).
        tz.TZDateTime.from(when, tz.UTC),
        NotificationDetails(
            android: android, iOS: const DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'reminder',
      );
      debugPrint('🔔 next reminder at $when : $phrase');
    } catch (e) {
      debugPrint('schedule failed: $e');
    }
  }

  /// Backwards-compatible alias used by older provider code.
  static Future<void> scheduleRepeating(int intervalMinutes) async {
    final when =
        DateTime.now().add(Duration(minutes: intervalMinutes.clamp(15, 240)));
    await scheduleNext(fireAt: when, phrase: 'Time for a glass of water');
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
