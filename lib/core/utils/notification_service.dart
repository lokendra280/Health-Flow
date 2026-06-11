import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const _channelId = 'habitflow_reminders';
  static const _channelName = 'Habit Reminders';
  static const _channelDesc = 'Daily habit check-in reminders';
  static List<TimezoneInfo> _availableTimezones = [];

  // ── Init ──────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_ready) return;
    tz.initializeTimeZones();

    // ✅ FIX 1: Set local timezone — without this all schedules use UTC
    final String timeZoneName = await _getDeviceTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

    _ready = true;
  }

  static Future<String> _getDeviceTimezone() async {
    try {
      final TimezoneInfo tzResult = await FlutterTimezone.getLocalTimezone();

      _availableTimezones = await FlutterTimezone.getAvailableTimezones();

      _availableTimezones.sort(
        (a, b) => a.identifier.compareTo(b.identifier),
      );

      return tzResult.identifier;
    } catch (e) {
      return 'UTC';
    }
  }

  static Future<bool> requestPermission() async {
    bool granted = false;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    // ───── Android ─────
    if (androidPlugin != null) {
      final result = await androidPlugin.requestNotificationsPermission();
      granted = result ?? false;

      // Android 12+ exact alarm permission (important for exact scheduling)
      if (granted) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    }

    // ───── iOS ─────
    final iosResult = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (iosResult == true) {
      granted = true;
    }

    return granted;
  }

  // ── Schedule ──────────────────────────────────────────────────────
  // static Future<void> scheduleReminder(
  //   Reminder reminder, {
  //   required String habitName,
  //   required String habitIcon,
  // }) async {
  //   if (!_ready) await init();
  //   await cancelReminder(reminder.id);
  //   if (!reminder.isEnabled) return;

  //   final body = reminder.message.isNotEmpty
  //       ? reminder.message
  //       : '$habitIcon Time to check in: $habitName!';

  //   final details = NotificationDetails(
  //     android: const AndroidNotificationDetails(
  //       _channelId,
  //       _channelName,
  //       channelDescription: _channelDesc,
  //       importance: Importance.max,
  //       priority: Priority.max,
  //       icon: '@mipmap/ic_launcher',
  //       color: Color(0xFF52B788),
  //       enableVibration: true,
  //       playSound: true,
  //       ticker: 'HabitFlow reminder',
  //     ),
  //     iOS: DarwinNotificationDetails(
  //       presentAlert: true,
  //       presentBadge: true,
  //       presentSound: true,
  //       subtitle: habitName,
  //       threadIdentifier: reminder.habitId,
  //     ),
  //   );

  //   final days = _daysForFrequency(reminder.frequency, reminder.customDays);
  //   if (days.isEmpty) {
  //     debugPrint('[Notif] No valid days for reminder ${reminder.id}');
  //     return;
  //   }

  //   for (int i = 0; i < days.length; i++) {
  //     final notifId = _stableId(reminder.id, i);
  //     final scheduled = _nextOccurrence(reminder.time, days[i]);

  //     debugPrint('[Notif] Scheduling id=$notifId at $scheduled');

  //     // ✅ FIX 4: Use exactAllowWhileIdle for reliable delivery.
  //     // inexact can be delayed by 15+ minutes by the OS battery optimizer.
  //     // Requires SCHEDULE_EXACT_ALARM permission (requested above).
  //     await _plugin.zonedSchedule(
  //       id: notifId,
  //       title: 'HabitFlow',
  //       body: body,
  //       scheduledDate: scheduled,
  //       notificationDetails: details,
  //       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //       // ✅ FIX 5: correct match component — dayOfWeekAndTime repeats weekly
  //       matchDateTimeComponents: reminder.frequency == ReminderFrequency.once
  //           ? null
  //           : DateTimeComponents.dayOfWeekAndTime,
  //       payload: reminder.habitId,
  //     );
  //   }
  // }
  static Future<void> scheduleReminder(
    Reminder reminder, {
    required String habitName,
    required String habitIcon,
  }) async {
    if (!_ready) await init();
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
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF52B788),
        enableVibration: true,
        playSound: true,
        ticker: 'HabitFlow reminder',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        subtitle: habitName,
        threadIdentifier: reminder.habitId,
      ),
    );

    final scheduled = _nextOccurrence(
      reminder.time,
      DateTime.now().weekday,
    );

    debugPrint('[Notif] Scheduling SINGLE id=${reminder.id} at $scheduled');

    await _plugin.zonedSchedule(
      id: _stableId(reminder.id, 0),
      title: 'HabitFlow',
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: reminder.habitId,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────
  static Future<void> cancelReminder(String reminderId) async {
    for (int i = 0; i < 7; i++) {
      await _plugin.cancel(id: _stableId(reminderId, i));
    }
  }

  static Future<void> cancelAllForHabit(String habitId) async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final n in pending) {
      if (n.payload == habitId) await _plugin.cancel(id: n.id);
    }
  }

  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Test (fires in 3 seconds) ─────────────────────────────────────
  // static Future<void> showTest(String habitName, String habitIcon) async {
  //   if (!_ready) await init();
  //   final id        = Random().nextInt(9000) + 1000;
  //   final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 3));

  //   await _plugin.zonedSchedule(
  //     id, 'HabitFlow — Test!',
  //     '$habitIcon $habitName reminder works!',
  //     scheduled,
  //     const NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         _channelId, _channelName,
  //         importance: Importance.max, priority: Priority.max,
  //         icon: '@mipmap/ic_launcher', playSound: true),
  //       iOS: DarwinNotificationDetails(presentAlert: true),
  //     ),
  //     // ✅ exactAllowWhileIdle so test fires exactly on time
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //   );
  //   debugPrint('[Notif] Test scheduled for $scheduled');
  // }

  // ── Reschedule all on boot / app resume ───────────────────────────
  static Future<void> rescheduleAll(
    List<Reminder> reminders,
    Map<String, String> habitNames,
    Map<String, String> habitIcons,
  ) async {
    await cancelAll();
    for (final r in reminders.where((r) => r.isEnabled)) {
      await scheduleReminder(r,
          habitName: habitNames[r.habitId] ?? 'Habit',
          habitIcon: habitIcons[r.habitId] ?? '🏃');
    }
  }

  static Future<List<PendingNotificationRequest>> getPending() =>
      _plugin.pendingNotificationRequests();

  static Future<int> getPendingCount() async => (await getPending()).length;

  // ── Helpers ───────────────────────────────────────────────────────
  static int _stableId(String reminderId, int dayIndex) =>
      (reminderId.hashCode.abs() % 1000000) * 10 + dayIndex;

  static List<int> _daysForFrequency(
          ReminderFrequency freq, List<int> custom) =>
      switch (freq) {
        ReminderFrequency.once => [DateTime.now().weekday],
        ReminderFrequency.daily => [1, 2, 3, 4, 5, 6, 7],
        ReminderFrequency.weekdays => [1, 2, 3, 4, 5],
        ReminderFrequency.weekends => [6, 7],
        ReminderFrequency.custom =>
          custom.isEmpty ? [1, 2, 3, 4, 5, 6, 7] : custom,
      };

  static tz.TZDateTime _nextOccurrence(TimeOfDay time, int weekday) {
    final now = tz.TZDateTime.now(tz.local);

    // Start from today at the given time
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);

    // Advance to the correct weekday
    // ✅ FIX 6: cap at 7 iterations to prevent infinite loop
    int attempts = 0;
    while (scheduled.weekday != weekday && attempts++ < 7) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // If time already passed, push to next week's occurrence
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }

  static void _onTap(NotificationResponse r) {
    debugPrint('[Notif] Tapped — payload: ${r.payload}');
  }
}
