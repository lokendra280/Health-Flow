import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/local_storage.dart';
import '../../data/models/models.dart';
import '../../core/utils/health_calc.dart';

const _uuid = Uuid();

// ─── User ───────────────────────────────────────────────
final userProvider = StateNotifierProvider<UserNotifier, UserProfile?>((ref) => UserNotifier());
class UserNotifier extends StateNotifier<UserProfile?> {
  UserNotifier() : super(null) { state = LocalStorage.getUser(); }
  Future<void> save(UserProfile u) async { await LocalStorage.saveUser(u); state = u; }
}

// ─── Steps ──────────────────────────────────────────────
final stepsProvider = StateNotifierProvider<StepsNotifier, StepLog?>((ref) => StepsNotifier(ref));
class StepsNotifier extends StateNotifier<StepLog?> {
  final Ref _ref;
  StepsNotifier(this._ref) : super(null) { state = LocalStorage.getTodaySteps(); }

  void update(int steps) {
    final user = _ref.read(userProvider);
    final bmi = user != null ? HealthCalc.bmi(user.weightKg, user.heightCm) : 22.0;
    final goal = HealthCalc.dailyStepGoal(bmi);
    final log = StepLog(
      id: 'steps_${DateTime.now().toIso8601String().substring(0, 10)}',
      steps: steps, goal: goal,
      distanceKm: HealthCalc.stepsToKm(steps),
      caloriesBurned: user != null ? HealthCalc.stepsToCalories(steps, user.weightKg) : steps * 0.04,
      date: DateTime.now(),
    );
    LocalStorage.saveSteps(log);
    state = log;
  }
}

final weekStepsProvider = Provider<List<StepLog>>((ref) {
  ref.watch(stepsProvider);
  return LocalStorage.getWeekSteps();
});

// ─── Workouts ────────────────────────────────────────────
final workoutsProvider = StateNotifierProvider<WorkoutsNotifier, List<WorkoutLog>>((ref) => WorkoutsNotifier());
class WorkoutsNotifier extends StateNotifier<List<WorkoutLog>> {
  WorkoutsNotifier() : super([]) { state = LocalStorage.getWorkouts(); }
  Future<void> add(String name, String type, int mins, int cal) async {
    final w = WorkoutLog(id: _uuid.v4(), name: name, type: type,
      durationMin: mins, calories: cal, date: DateTime.now());
    await LocalStorage.addWorkout(w);
    state = LocalStorage.getWorkouts();
  }
  Future<void> delete(String id) async {
    await LocalStorage.deleteWorkout(id);
    state = LocalStorage.getWorkouts();
  }
}

// ─── Nutrition ────────────────────────────────────────────
final nutritionDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final nutritionProvider = StateNotifierProvider<NutritionNotifier, List<NutritionLog>>((ref) {
  final date = ref.watch(nutritionDateProvider);
  return NutritionNotifier(date);
});
class NutritionNotifier extends StateNotifier<List<NutritionLog>> {
  final DateTime _date;
  NutritionNotifier(this._date) : super([]) { state = LocalStorage.getNutritionByDate(_date); }
  Future<void> add(String name, String meal, int cal, int p, int c, int f) async {
    final n = NutritionLog(id: _uuid.v4(), name: name, meal: meal,
      calories: cal, protein: p, carbs: c, fat: f, date: _date);
    await LocalStorage.addNutrition(n);
    state = LocalStorage.getNutritionByDate(_date);
  }
  Future<void> delete(String id) async {
    await LocalStorage.deleteNutrition(id);
    state = LocalStorage.getNutritionByDate(_date);
  }
}

// ─── Sleep ────────────────────────────────────────────────
final sleepProvider = StateNotifierProvider<SleepNotifier, List<SleepLog>>((ref) => SleepNotifier());
class SleepNotifier extends StateNotifier<List<SleepLog>> {
  SleepNotifier() : super([]) { state = LocalStorage.getSleepLogs(); }
  Future<void> add(DateTime bed, DateTime wake, int quality, String notes) async {
    final s = SleepLog(id: _uuid.v4(), bedTime: bed, wakeTime: wake,
      qualityRating: quality, notes: notes);
    await LocalStorage.addSleep(s);
    state = LocalStorage.getSleepLogs();
  }
}

// ─── Mood ────────────────────────────────────────────────
final moodProvider = StateNotifierProvider<MoodNotifier, List<MoodLog>>((ref) => MoodNotifier());
class MoodNotifier extends StateNotifier<List<MoodLog>> {
  MoodNotifier() : super([]) { state = LocalStorage.getMoodLogs(); }
  Future<void> add(String mood, String note, int stress) async {
    final m = MoodLog(id: _uuid.v4(), mood: mood, note: note,
      date: DateTime.now(), stressLevel: stress);
    await LocalStorage.addMood(m);
    state = LocalStorage.getMoodLogs();
  }
}

// ─── Vitals ────────────────────────────────────────────────
final vitalsProvider = StateNotifierProvider<VitalsNotifier, List<VitalLog>>((ref) => VitalsNotifier());
class VitalsNotifier extends StateNotifier<List<VitalLog>> {
  VitalsNotifier() : super([]) { state = LocalStorage.getVitals(); }
  Future<void> add(int hr, int sys, int dia, double spo2, double temp) async {
    final v = VitalLog(id: _uuid.v4(), heartRate: hr, systolic: sys,
      diastolic: dia, spO2: spo2, temperature: temp, date: DateTime.now());
    await LocalStorage.addVital(v);
    state = LocalStorage.getVitals();
  }
}
