import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/providers/date_provider.dart';
import 'package:habitflow/features/ai_plan/providers/ai_plan_provider.dart';
import 'package:habitflow/features/steps/controller/step_count_controller.dart';
import 'package:habitflow/features/steps/models/step_counter_summery.dart';

final stepCountControllerProvider = Provider<StepCountController>((ref) {
  return StepCountController.instance;
});

final healthAccessProvider =
    AsyncNotifierProvider<HealthAccessNotifier, HealthAccessStatus>(
  HealthAccessNotifier.new,
);

class HealthAccessNotifier extends AsyncNotifier<HealthAccessStatus> {
  @override
  Future<HealthAccessStatus> build() {
    return ref.read(stepCountControllerProvider).requestAccess();
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(stepCountControllerProvider).requestAccess(),
    );
  }
}

final stepGoalProvider = Provider<int>((ref) {
  final plan = ref.watch(aiPlanControllerProvider);
  return plan?.stepTarget ?? 10000;
});

final stepsForDateProvider =
    FutureProvider.autoDispose.family<int, DateTime>((ref, date) async {
  final access = await ref.watch(healthAccessProvider.future);
  if (access != HealthAccessStatus.authorized) return 0;

  final controller = ref.watch(stepCountControllerProvider);
  final normalized = DateTime(date.year, date.month, date.day);
  final now = DateTime.now();
  final isToday = normalized.year == now.year &&
      normalized.month == now.month &&
      normalized.day == now.day;

  final steps = isToday
      ? await controller.fetchTodaySteps()
      : await controller.fetchStepsForDate(normalized);
  return steps ?? 0;
});

final todayStepsProvider = FutureProvider.autoDispose<int>((ref) {
  final today = ref.watch(currentDateProvider);
  return ref.watch(stepsForDateProvider(today).future);
});

final weeklyStepsProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final access = await ref.watch(healthAccessProvider.future);
  if (access != HealthAccessStatus.authorized) {
    return const {
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
      'Sun': 0
    };
  }
  final controller = ref.watch(stepCountControllerProvider);
  return controller.fetchWeeklySteps();
});

final stepsSummaryProvider = FutureProvider.autoDispose
    .family<StepsSummary, DateTime>((ref, date) async {
  final steps = await ref.watch(stepsForDateProvider(date).future);
  final weekly = await ref.watch(weeklyStepsProvider.future);
  final goal = ref.watch(stepGoalProvider);

  return StepsSummary(
    steps: steps,
    goal: goal,
    calories: (steps * 0.0645).round(),
    distanceKm: double.parse((steps * 0.00069).toStringAsFixed(1)),
    activeTime: Duration(minutes: (steps / 105).round()),
    weekly: weekly,
  );
});

DateTime _todayKey() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

final stepsProgressProvider = Provider<double>((ref) {
  final steps = ref.watch(todayStepsProvider).valueOrNull ?? 0;
  final goal = ref.watch(stepGoalProvider);
  if (goal <= 0) return 0.0;
  return (steps / goal).clamp(0.0, 1.0);
});
