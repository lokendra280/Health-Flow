import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class LocalStorage {
  static late Box<UserProfile> _user;
  static late Box<WorkoutLog> _workouts;
  static late Box<NutritionLog> _nutrition;
  static late Box<SleepLog> _sleep;
  static late Box<MoodLog> _mood;
  static late Box<VitalLog> _vitals;
  static late Box<StepLog> _steps;

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserProfileAdapter());
    Hive.registerAdapter(WorkoutLogAdapter());
    Hive.registerAdapter(NutritionLogAdapter());
    Hive.registerAdapter(SleepLogAdapter());
    Hive.registerAdapter(MoodLogAdapter());
    Hive.registerAdapter(VitalLogAdapter());
    Hive.registerAdapter(StepLogAdapter());

    _user = await Hive.openBox<UserProfile>('user');
    _workouts = await Hive.openBox<WorkoutLog>('workouts');
    _nutrition = await Hive.openBox<NutritionLog>('nutrition');
    _sleep = await Hive.openBox<SleepLog>('sleep');
    _mood = await Hive.openBox<MoodLog>('mood');
    _vitals = await Hive.openBox<VitalLog>('vitals');
    _steps = await Hive.openBox<StepLog>('steps');
  }

  // User
  static UserProfile? getUser() => _user.get('profile');
  static Future<void> saveUser(UserProfile u) => _user.put('profile', u);

  // Workouts
  static List<WorkoutLog> getWorkouts() => _workouts.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  static Future<void> addWorkout(WorkoutLog w) => _workouts.put(w.id, w);
  static Future<void> deleteWorkout(String id) => _workouts.delete(id);

  // Nutrition
  static List<NutritionLog> getNutritionByDate(DateTime d) => _nutrition.values
    .where((n) => _sameDay(n.date, d)).toList();
  static Future<void> addNutrition(NutritionLog n) => _nutrition.put(n.id, n);
  static Future<void> deleteNutrition(String id) => _nutrition.delete(id);

  // Sleep
  static List<SleepLog> getSleepLogs() => _sleep.values.toList()
    ..sort((a, b) => b.bedTime.compareTo(a.bedTime));
  static Future<void> addSleep(SleepLog s) => _sleep.put(s.id, s);

  // Mood
  static List<MoodLog> getMoodLogs() => _mood.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  static Future<void> addMood(MoodLog m) => _mood.put(m.id, m);

  // Vitals
  static List<VitalLog> getVitals() => _vitals.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  static Future<void> addVital(VitalLog v) => _vitals.put(v.id, v);

  // Steps
  static StepLog? getTodaySteps() {
    final today = DateTime.now();
    try { return _steps.values.firstWhere((s) => _sameDay(s.date, today)); }
    catch (_) { return null; }
  }
  static Future<void> saveSteps(StepLog s) => _steps.put(s.id, s);
  static List<StepLog> getWeekSteps() {
    final now = DateTime.now();
    return _steps.values.where((s) => now.difference(s.date).inDays < 7).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
}
