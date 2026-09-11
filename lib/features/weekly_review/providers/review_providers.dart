import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/utils/date_utils.dart';
import 'package:habitflow/data/models/tracking_models.dart';
import 'package:habitflow/data/repositories/journey_repository_provider.dart';
import 'package:habitflow/features/ai_plan/providers/ai_plan_provider.dart';
import 'package:habitflow/features/steps/ui/step_count_provider.dart';
import 'package:habitflow/features/weekly_review/models/daily_headline.dart';
import 'package:habitflow/features/weekly_review/models/perodic_meters.dart';

/// Steps now come from the real step-counter pipeline (health data),
/// everything else still comes from the Hive-backed JourneyRepository.
/// Async because stepsForDateProvider is async (health API calls).
Future<PeriodMetrics> _computeMetrics(
  Ref ref,
  dynamic repo,
  DateTime start,
  int days,
) async {
  final water = <double>[], sleep = <double>[], calories = <double>[];
  int workouts = 0;

  final stepsFutures = <Future<int>>[];
  for (var i = 0; i < days; i++) {
    final day = start.add(Duration(days: i)).normalized;
    stepsFutures.add(ref.watch(stepsForDateProvider(day).future));
    water.add((repo.waterFor(day) as int).toDouble());
    sleep.add((repo.sleepFor(day)?.hours as double?) ?? 0);
    workouts += (repo.workoutsFor(day) as List).length;

    final List<FoodEntry> foodEntries = repo.foodEntriesFor(day);
    final dayCalories = foodEntries.fold<double>(
      0,
      (sum, e) => sum + e.calories,
    );
    calories.add(dayCalories);
  }

  final stepsInt = await Future.wait(stepsFutures);
  final steps = stepsInt.map((s) => s.toDouble()).toList();

  final habits = repo.habits() as List;
  final consistency = habits.isEmpty
      ? 0.0
      : habits.where((h) => h.streak > 0).length / habits.length;

  return PeriodMetrics(
    stepsPerDay: steps,
    waterPerDay: water,
    sleepPerDay: sleep,
    caloriesPerDay: calories,
    workoutCount: workouts,
    habitConsistency: consistency,
  );
}

/// Daily metrics use a 7-day trailing window for the trend chart.
final dailyMetricsProvider =
    FutureProvider.autoDispose.family<PeriodMetrics, DateTime>((ref, day) {
  final repo = ref.watch(journeyRepositoryProvider);
  final windowStart = day.subtract(const Duration(days: 6));
  return _computeMetrics(ref, repo, windowStart, 7);
});

final weeklyMetricsProvider = FutureProvider.autoDispose
    .family<PeriodMetrics, DateTime>((ref, weekStart) {
  final repo = ref.watch(journeyRepositoryProvider);
  return _computeMetrics(ref, repo, weekStart, 7);
});

final monthlyMetricsProvider = FutureProvider.autoDispose
    .family<PeriodMetrics, DateTime>((ref, monthStart) {
  final repo = ref.watch(journeyRepositoryProvider);
  return _computeMetrics(ref, repo, monthStart, 30);
});

/// Today's actual figures for the hero header — includes step goal +
/// progress, and calorie target + progress, so the UI can show "X / goal"
/// for both instead of bare numbers.

final dailyHeadlineMetricsProvider = FutureProvider.autoDispose
    .family<DailyHeadline, DateTime>((ref, day) async {
  final normalizedDay = day.normalized;
  final repo = ref.watch(journeyRepositoryProvider);
  final steps = await ref.watch(stepsForDateProvider(normalizedDay).future);
  final stepGoal = ref.watch(stepGoalProvider);

  final plan = ref.watch(aiPlanControllerProvider);
  final calorieTarget = plan?.calorieTarget ?? 2000;

  final List<FoodEntry> foodEntries = repo.foodEntriesFor(normalizedDay);
  final calories = foodEntries.fold<double>(
    0,
    (sum, e) => sum + e.calories,
  );

  return DailyHeadline(
    steps: steps,
    stepGoal: stepGoal,
    stepProgress: stepGoal > 0 ? (steps / stepGoal).clamp(0.0, 1.0) : 0.0,
    calories: calories,
    calorieTarget: calorieTarget,
    calorieProgress:
        calorieTarget > 0 ? (calories / calorieTarget).clamp(0.0, 1.0) : 0.0,
    water: repo.waterFor(normalizedDay),
    sleepHours: (repo.sleepFor(normalizedDay)?.hours as double?) ?? 0,
    workoutCount: (repo.workoutsFor(normalizedDay) as List).length,
  );
});

/// Daily AI review — steps now come from the real step counter too, not
/// the manually-logged Hive value.
final dailyReviewProvider =
    FutureProvider.autoDispose.family<String, DateTime>((ref, day) async {
  final normalizedDay = day.normalized;
  final repo = ref.watch(journeyRepositoryProvider);
  final gemini = ref.watch(geminiServiceProvider);
  final steps = await ref.watch(stepsForDateProvider(normalizedDay).future);

  final goal = repo.loadGoal();
  final habits = repo.habits();

  return gemini.reviewDay(
    weight: goal.currentWeight,
    food: repo.foodEntriesFor(normalizedDay),
    water: repo.waterFor(normalizedDay),
    steps: steps,
    workouts: repo.workoutsFor(normalizedDay),
    sleep: repo.sleepFor(normalizedDay),
    habits: habits,
    checkIn: repo.checkInFor(normalizedDay),
  );
});

final weeklyReviewProvider =
    FutureProvider.autoDispose.family<String, DateTime>((ref, weekStart) async {
  final metrics = await ref.watch(weeklyMetricsProvider(weekStart).future);
  final gemini = ref.watch(geminiServiceProvider);
  return gemini.summarizeWeek(metrics.toPromptMap());
});

final monthlyReviewProvider = FutureProvider.autoDispose
    .family<String, DateTime>((ref, monthStart) async {
  final metrics = await ref.watch(monthlyMetricsProvider(monthStart).future);
  final gemini = ref.watch(geminiServiceProvider);
  return gemini.summarizeMonth(metrics.toPromptMap());
});
