import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ─────────────────────────────────────────────────────────────────────────────
//  NOTIFICATION SERVICE
//  Wraps flutter_local_notifications for exact-time habit reminders.
//  Supports: daily / weekdays / weekends / custom day-of-week schedules.
// ─────────────────────────────────────────────────────────────────────────────

// ReminderFrequency is defined in domain entities; use the imported type to
// avoid duplicate definitions and the resulting type mismatch.

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  // ── Notification channel config ───────────────────────────────────────────
  static const _channelId = 'habitflow_reminders';
  static const _channelName = 'Habit Reminders';
  static const _channelDesc = 'Daily habit check-in reminders';

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Create Android channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ));

    _ready = true;
  }

  static void _onTap(NotificationResponse r) {
    // Deep-link: r.payload contains habitId for routing if needed
    debugPrint('Notification tapped — payload: ${r.payload}');
  }

  // ── Permission ────────────────────────────────────────────────────────────
  static Future<bool> requestPermission() async {
    bool granted = false;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    final iosResult = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    if (iosResult == true) granted = true;

    final androidResult = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    if (androidResult == true) granted = true;

    return granted;
  }

  static Future<bool> arePermissionsGranted() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await android?.areNotificationsEnabled();

    return granted ?? false;
  }

  // ── Schedule a reminder ───────────────────────────────────────────────────
  static Future<void> scheduleReminder(
    Reminder reminder, {
    required String habitName,
    required String habitIcon,
  }) async {
    // Cancel existing notifications for this reminder first
    await cancelReminder(reminder.id);
    if (!reminder.isEnabled) return;

    final body = reminder.message.isNotEmpty
        ? reminder.message
        : '$habitIcon Time to check in: $habitName!';

    final details = NotificationDetails(
      android: const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF2D6A4F),
        ticker: 'HabitFlow reminder',
        enableVibration: true,
        playSound: true,

        // payload: reminder.habitId,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: habitName,
        threadIdentifier: reminder.habitId,
      ),
    );

    final days = _daysForFrequency(reminder.frequency, reminder.customDays);

    for (int i = 0; i < days.length; i++) {
      final notifId = _stableId(reminder.id, i);
      final scheduled = _nextOccurrence(reminder.time, days[i]);

      await _plugin.zonedSchedule(
        notifId,
        '🌿 HabitFlow',
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: reminder.frequency == ReminderFrequency.once
            ? null
            : DateTimeComponents.dayOfWeekAndTime,
        payload: reminder.habitId,
      );
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────
  static Future<void> cancelReminder(String reminderId) async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(_stableId(reminderId, i));
    }
  }

  static Future<void> cancelAllForHabit(String habitId) async {
    // Get all pending and cancel those whose payload matches habitId
    final pending = await _plugin.pendingNotificationRequests();
    for (final n in pending) {
      if (n.payload == habitId) {
        await _plugin.cancel(n.id);
      }
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Test notification ─────────────────────────────────────────────────────
  static Future<void> showTest(String habitName, String habitIcon) async {
    await _plugin.show(
      Random().nextInt(9000) + 1000,
      '🌿 HabitFlow — Reminder Set!',
      '$habitIcon $habitName reminder is active.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  // ── Pending list ──────────────────────────────────────────────────────────
  static Future<List<PendingNotificationRequest>> getPending() =>
      _plugin.pendingNotificationRequests();

  static Future<int> getPendingCount() async => (await getPending()).length;

  // ── Re-schedule all (call on boot / app resume) ───────────────────────────
  static Future<void> rescheduleAll(
    List<Reminder> reminders,
    Map<String, String> habitNames, // habitId → name
    Map<String, String> habitIcons, // habitId → icon
  ) async {
    await cancelAll();
    for (final r in reminders.where((r) => r.isEnabled)) {
      await scheduleReminder(
        r,
        habitName: habitNames[r.habitId] ?? 'Habit',
        habitIcon: habitIcons[r.habitId] ?? '🏃',
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static int _stableId(String reminderId, int dayIndex) =>
      (reminderId.hashCode.abs() % 1000000) * 10 + dayIndex;

  static List<int> _daysForFrequency(ReminderFrequency freq, List<int> custom) {
    switch (freq) {
      case ReminderFrequency.once:
        return [DateTime.now().weekday];
      case ReminderFrequency.daily:
        return [1, 2, 3, 4, 5, 6, 7];
      case ReminderFrequency.weekdays:
        return [1, 2, 3, 4, 5];
      case ReminderFrequency.weekends:
        return [6, 7];
      case ReminderFrequency.custom:
        return custom.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : custom;
    }
  }

  static tz.TZDateTime _nextOccurrence(TimeOfDay time, int weekday) {
    final now = tz.TZDateTime.now(tz.local);

    // Start from NOW (not today base time)
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time already passed today → move to next day first
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Then adjust weekday safely
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
