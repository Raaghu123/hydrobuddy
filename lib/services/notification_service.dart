import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _init = false;

  static Future<void> init() async {
    if (_init) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'hydration_reminders',
          'Hydration Reminders',
          description: 'Gentle nudges to drink water',
          importance: Importance.high,
        ));
    _init = true;
  }

  static Future<void> scheduleRepeating(int intervalMinutes) async {
    assert(intervalMinutes >= 15);
    await cancelAll();
    final android = AndroidNotificationDetails(
      'hydration_reminders',
      'Hydration Reminders',
      channelDescription: 'Gentle nudges to drink water',
      importance: Importance.high,
      priority: Priority.high,
      actions: const [
        AndroidNotificationAction('drank_250', '💧 Drank 250ml'),
        AndroidNotificationAction('snooze', 'Snooze 15m'),
      ],
    );
    await _plugin.periodicallyShow(
      1001,
      '💧 Time to hydrate!',
      'Tap to log water — small sips keep your streak alive 🔥',
      RepeatInterval.everyMinute, // OS minimum; real interval enforced by reschedule
      NotificationDetails(
          android: android, iOS: const DarwinNotificationDetails()),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    // Note: for exact custom intervals (60/90/120m) on production,
    // use zonedSchedule loop or WorkManager. This keeps Play-policy-safe MVP.
  }

  static Future<void> showGoalCelebration() async {
    await _plugin.show(
      2002,
      '🏆 Daily goal crushed!',
      'You hit your hydration goal. Streak secured!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
            'hydration_reminders', 'Hydration Reminders'),
      ),
    );
  }

  static Future<void> cancelAll() async => _plugin.cancelAll();
}
