import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../data/models/tracking_models.dart';
import '../ai_plan/providers/ai_plan_provider.dart';
import '../food_tracking/providers/food_tracking_provider.dart';
import '../steps/ui/step_count_provider.dart';
import '../water_tracking/providers/water_tracking_provider.dart';
import '../activity_tracking/activity_tracking_screen.dart';
import '../../core/utils/date_utils.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const String _channelId = 'motivational_nudges';
  static const String _channelName = 'Daily Motivation';
  static const String _channelDesc = 'Smart reminders to help you reach your goals';

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    final dynamic timeZone = await FlutterTimezone.getLocalTimezone();
    // Support both older (String) and newer (TimezoneInfo) versions of the package
    final String timeZoneName = timeZone is String ? timeZone : (timeZone as dynamic).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 2. Android Settings
    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    // 3. iOS Settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // 4. Initialize Plugin
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // 5. Create Channel for Android
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
          ),
        );

    _isInitialized = true;
    debugPrint('NotificationService initialized with timezone: $timeZoneName');
  }

  /// Schedules afternoon and evening nudges based on current progress.
  Future<void> scheduleMotivationalNudges({
    required int currentSteps,
    required int stepGoal,
    required int currentWater,
    required int waterGoal,
    required List<FoodEntry> foodEntries,
  }) async {
    if (!_isInitialized) await init();

    // Cancel existing nudges first to avoid duplicates
    await _plugin.cancel(id: 100); // Water Nudge ID
    await _plugin.cancel(id: 101); // Steps Nudge ID
    await _plugin.cancel(id: 102); // Food Nudge ID

    final now = tz.TZDateTime.now(tz.local);

    // --- 1. Water Nudge (2 PM) ---
    if (currentWater < (waterGoal * 0.5)) {
      final scheduledDate = _nextInstanceOfTime(14, 0);
      await _plugin.zonedSchedule(
        id: 100,
        title: 'Stay Hydrated! 💧',
        body: 'You\'ve had $currentWater ml so far. A few more glasses to hit your midpoint goal!',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // --- 2. Steps Nudge (6 PM) ---
    if (currentSteps < (stepGoal * 0.8)) {
      final remaining = stepGoal - currentSteps;
      final scheduledDate = _nextInstanceOfTime(18, 0);
      await _plugin.zonedSchedule(
        id: 101,
        title: 'Evening Walk? 🏃‍♂️',
        body: 'You\'re $remaining steps away from your daily goal. Let\'s get moving!',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    // --- 3. Food Log Nudge (9 PM) ---
    final hasLoggedDinner = foodEntries.any((e) => e.mealType == 'dinner');
    if (!hasLoggedDinner) {
      final scheduledDate = _nextInstanceOfTime(21, 0);
      await _plugin.zonedSchedule(
        id: 102,
        title: 'Log Your Dinner 🍎',
        body: 'Don\'t forget to track your last meal to keep your health journey accurate!',
        scheduledDate: scheduledDate,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Shows an immediate notification. Used for over-limit alerts generated by AI.
  Future<void> showInstantNudge(String title, String body) async {
    if (!_isInitialized) await init();
    await _plugin.show(
      id: DateTime.now().millisecond + 1000,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }
  
  Future<void> testNudge() async {
    await _plugin.show(
      id: 999,
      title: 'Test Nudge! 🚀',
      body: 'This is how your motivational messages will look.',
      notificationDetails: _notificationDetails(),
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// A controller that listens to all health metrics and triggers 
/// a notification reschedule whenever something changes.
class NotificationSyncController extends AutoDisposeNotifier<void> {
  // Simple in-memory tracker to avoid spamming instant nudges in the same session
  static final Set<String> _sentInstantNudges = {};

  @override
  void build() {
    // 1. Watch all relevant data
    final steps = ref.watch(todayStepsProvider).valueOrNull ?? 0;
    final stepGoal = ref.watch(stepGoalProvider);
    final water = ref.watch(waterControllerProvider);
    final waterGoal = ref.watch(waterTargetProvider);
    final foodEntries = ref.watch(foodLogProvider(DateTime.now().normalized));
    final workouts = ref.watch(workoutLogControllerProvider);

    // 2. Trigger reschedule for timed nudges
    _reschedule(steps, stepGoal, water, waterGoal, foodEntries);

    // 3. Check for over-limits (Instant Nudges)
    _checkOverLimits(water, foodEntries, workouts);
  }

  Future<void> _reschedule(
    int steps,
    int stepGoal,
    int water,
    int waterGoal,
    List<FoodEntry> foodEntries,
  ) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!ref.exists(notificationServiceProvider)) return;
    
    await ref.read(notificationServiceProvider).scheduleMotivationalNudges(
      currentSteps: steps,
      stepGoal: stepGoal,
      currentWater: water,
      waterGoal: waterGoal,
      foodEntries: foodEntries,
    );
  }

  Future<void> _checkOverLimits(int water, List<FoodEntry> foodEntries, List<WorkoutEntry> workouts) async {
    final calories = foodEntries.fold<double>(0, (sum, item) => sum + (item.calories));
    
    final gemini = ref.read(geminiServiceProvider);
    final notifier = ref.read(notificationServiceProvider);

    // Calorie Nudge (> 3000)
    if (calories > 3000 && !_sentInstantNudges.contains('cal_over')) {
      final msg = await gemini.generateNudgeMessage('calories', calories);
      await notifier.showInstantNudge('Energy Surplus! 🍎', msg);
      _sentInstantNudges.add('cal_over');
    }

    // Water Nudge (> 4000)
    if (water > 4000 && !_sentInstantNudges.contains('water_over')) {
      final msg = await gemini.generateNudgeMessage('water', water.toDouble());
      await notifier.showInstantNudge('Hydration Pro! 💧', msg);
      _sentInstantNudges.add('water_over');
    }

    // Workout Nudge (> 2)
    if (workouts.length > 2 && !_sentInstantNudges.contains('workout_over')) {
      final msg = await gemini.generateNudgeMessage('workout', workouts.length.toDouble());
      await notifier.showInstantNudge('Amazing Dedication! 🏃‍♂️', msg);
      _sentInstantNudges.add('workout_over');
    }
  }
}

final notificationSyncProvider = NotifierProvider.autoDispose<NotificationSyncController, void>(
  NotificationSyncController.new,
);
