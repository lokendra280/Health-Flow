import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/data/models/daily_workout.dart';
import 'package:habitflow/data/repositories/journey_repository_provider.dart';
import 'package:habitflow/features/ai_plan/providers/ai_plan_provider.dart';
import 'package:habitflow/features/ai_plan/providers/weekly_workout_provider.dart';

class DailyExerciseState {
  final DailyWorkout? workout; // null if plan has no entry for today
  final Set<String> completedExerciseNames;

  const DailyExerciseState({
    required this.workout,
    required this.completedExerciseNames,
  });

  bool get hasWorkoutToday => workout != null && !workout!.isRestDay;

  int get totalCount => workout?.exercises.length ?? 0;

  int get doneCount => workout == null
      ? 0
      : workout!.exercises
          .where((e) => completedExerciseNames.contains(e.name))
          .length;

  double get progress => totalCount == 0 ? 0.0 : doneCount / totalCount;

  bool get isFullyDone => totalCount > 0 && doneCount == totalCount;
}

final dailyExerciseProvider = Provider.autoDispose<DailyExerciseState>((ref) {
  final plan = ref.watch(aiPlanControllerProvider);
  final repo = ref.watch(journeyRepositoryProvider);
  final today = DateTime.now();

  final workout = plan?.workoutForWeekday(today);
  final completed = repo.completedExercisesFor(today);

  return DailyExerciseState(
    workout: workout,
    completedExerciseNames: completed,
  );
});
final completedExercisesForDateProvider =
    Provider.autoDispose.family<Set<String>, String>((ref, dateKey) {
  final repo = ref.watch(journeyRepositoryProvider);
  final date = DateTime.parse(dateKey);
  return repo.completedExercisesFor(date);
});

String dateKeyFor(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Call this to check/uncheck one exercise — invalidates dailyExerciseProvider
/// so the UI updates immediately.
final toggleExerciseProvider = Provider<Future<void> Function(String)>((ref) {
  return (String exerciseName) async {
    final repo = ref.read(journeyRepositoryProvider);
    await repo.toggleExerciseDone(DateTime.now(), exerciseName);
    ref.invalidate(dailyExerciseProvider);
    ref.invalidate(todayWorkoutSummaryProvider);
  };
});
