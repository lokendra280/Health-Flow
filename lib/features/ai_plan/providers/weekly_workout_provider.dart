import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/data/repositories/journey_repository_provider.dart';
import 'package:habitflow/features/ai_plan/providers/ai_plan_provider.dart';

import '../../dashboard/providers/dashboard_providers.dart';

class WeeklyWorkoutSummary {
  final int completedCount;
  final int totalCount;

  const WeeklyWorkoutSummary({
    required this.completedCount,
    required this.totalCount,
  });

  int get remaining => (totalCount - completedCount).clamp(0, totalCount);
}

/// Sums exercises across the whole week's plan (Mon-Sun, non-rest days
/// only) for totalCount, and how many of those have been marked done so
/// far — only counting days up to and including today, since future days
/// obviously can't be "done" yet.
final weeklyWorkoutSummaryProvider =
    Provider.autoDispose<WeeklyWorkoutSummary>((ref) {
  final plan = ref.watch(aiPlanControllerProvider);
  final repo = ref.watch(journeyRepositoryProvider);

  if (plan == null) {
    return const WeeklyWorkoutSummary(completedCount: 0, totalCount: 0);
  }

  final today = DateTime.now();
  final weekStart = today.subtract(Duration(days: today.weekday - 1)); // Monday

  var total = 0;
  var completed = 0;

  for (int i = 0; i < 7; i++) {
    final date = weekStart.add(Duration(days: i));
    final workout = plan.workoutForWeekday(date);
    if (workout == null || workout.isRestDay) continue;

    total += workout.exercises.length;

    // Don't count completion for days that haven't happened yet.
    if (date.isAfter(today)) continue;

    final completedNames = repo.completedExercisesFor(date);
    completed +=
        workout.exercises.where((e) => completedNames.contains(e.name)).length;
  }

  return WeeklyWorkoutSummary(completedCount: completed, totalCount: total);
});

/// Only counts exercises for the selected day — used on the dashboard to show
/// "remaining" work for the chosen day specifically.
final todayWorkoutSummaryProvider =
    Provider.autoDispose<WeeklyWorkoutSummary>((ref) {
  final plan = ref.watch(aiPlanControllerProvider);
  final repo = ref.watch(journeyRepositoryProvider);
  final selectedDate = ref.watch(dashboardSelectedDateProvider);

  if (plan == null) {
    return const WeeklyWorkoutSummary(completedCount: 0, totalCount: 0);
  }

  final workout = plan.workoutForWeekday(selectedDate);

  if (workout == null || workout.isRestDay) {
    return const WeeklyWorkoutSummary(completedCount: 0, totalCount: 0);
  }

  final total = workout.exercises.length;
  final completedNames = repo.completedExercisesFor(selectedDate);
  final completed =
      workout.exercises.where((e) => completedNames.contains(e.name)).length;

  return WeeklyWorkoutSummary(completedCount: completed, totalCount: total);
});
