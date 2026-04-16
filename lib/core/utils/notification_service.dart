import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios));
  }

  static Future<void> showStepGoalReached(int steps) => _show(
    id: 1, title: '🎉 Step Goal Reached!',
    body: 'Amazing! You\'ve walked $steps steps today. Keep it up!',
    channel: 'steps');

  static Future<void> showDailyReminder() => _show(
    id: 2, title: '💪 Time to Move!',
    body: 'Don\'t forget to log your health data today.',
    channel: 'reminders');

  static Future<void> showWaterReminder() => _show(
    id: 3, title: '💧 Stay Hydrated',
    body: 'Remember to drink water — aim for 8 glasses a day.',
    channel: 'reminders');

  static Future<void> _show({
    required int id, required String title,
    required String body, required String channel,
  }) async {
    final android = AndroidNotificationDetails(
      channel, channel,
      importance: Importance.high, priority: Priority.high,
      styleInformation: const BigTextStyleInformation(''),
    );
    await _plugin.show(id, title, body,
      NotificationDetails(android: android, iOS: const DarwinNotificationDetails()));
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
