import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/providers/date_provider.dart';
import 'package:habitflow/core/utils/date_utils.dart';
import 'package:habitflow/features/activity_tracking/activity_tracking_screen.dart';
import 'package:habitflow/features/food_tracking/providers/food_tracking_provider.dart';
import 'package:habitflow/features/habit_tracking/habit_tracking_screen.dart';
import 'package:habitflow/features/habit_tracking/providers/habit_tracking_provider.dart';
import 'package:habitflow/features/water_tracking/providers/water_tracking_provider.dart';
import 'package:habitflow/features/water_tracking/water_tracking_screen.dart';
import '../../../data/models/dashboard_data.dart';
import '../../../data/repositories/journey_repository_provider.dart';
import '../../journey_setup/providers/journey_setup_provider.dart';
import '../../ai_plan/providers/ai_plan_provider.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);
final selectedDayIndexProvider = StateProvider<int>((ref) => 0);
final double _fallbackCalorieTarget = 2000;

final dashboardDataProvider = Provider<DashboardData>((ref) {
  final goal = ref.watch(journeySetupControllerProvider);
  final plan = ref.watch(aiPlanControllerProvider);
  final repo = ref.watch(journeyRepositoryProvider);
  final today = ref.watch(currentDateProvider);

  final weightLost = (goal.startingWeight != null && goal.currentWeight != null)
      ? goal.startingWeight! - goal.currentWeight!
      : null;
  final remaining = (goal.currentWeight != null && goal.targetWeight != null)
      ? goal.currentWeight! - goal.targetWeight!
      : null;

  final calorieTarget = (plan?.calorieTarget ?? _fallbackCalorieTarget).toDouble();

  final caloriesToday = ref
      .watch(foodLogProvider(today))
      .fold<double>(0, (s, e) => s + e.calories);

  return DashboardData(
    currentWeight: goal.currentWeight,
    targetWeight: goal.targetWeight,
    weightLost: weightLost,
    remainingWeight: remaining,
    progressPercentage: goal.progressPercentage,
    daysRemaining: repo.daysRemaining,
    waterTarget: plan?.waterTarget ?? 2000,
    stepTarget: plan?.stepTarget ?? 8000,
    journeyStreak: repo.streaks()['journey'] ?? 0,
    habitConsistency: ref.watch(habitConsistencyProvider),
    calorieProgress: (caloriesToday / calorieTarget).clamp(0, 1),
    waterProgress: ref.watch(waterProgressProvider),
    stepsProgress: ref.watch(stepsProgressProvider),
    sleepProgress: ((repo.sleepFor(today)?.hours ?? 0) / 8).clamp(0, 1),
  );
});

/// A "Manual" AI insight provider. It won't call Gemini until [refresh] is called.
/// This prevents high bills from auto-refreshing on every data change.
class AiInsightNotifier extends Notifier<AsyncValue<String>> {
  @override
  AsyncValue<String> build() {
    // Return a default "idle" state so no AI call happens on dashboard load
    return const AsyncValue.data('Tap to get your personalized AI insight for today! ✨');
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final data = ref.read(dashboardDataProvider);
      final gemini = ref.read(geminiServiceProvider);
      final today = DateTime.now().normalized;
      final food = ref.read(foodLogProvider(today));
      final caloriesToday = food.fold<double>(0, (s, e) => s + e.calories);

      String context = '';
      if (caloriesToday > 3000) context += 'User has logged $caloriesToday calories today. ';
      if (data.waterProgress * data.waterTarget > 4000) context += 'User has drunk over 4000ml of water. ';

      final result = await gemini.summarizeWeek({
        'progress': data.progressPercentage,
        'habitConsistency': data.habitConsistency,
        'waterProgress': data.waterProgress,
        'stepsProgress': data.stepsProgress,
        'todayAlerts': context,
      });
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final aiInsightProvider = NotifierProvider<AiInsightNotifier, AsyncValue<String>>(AiInsightNotifier.new);

/// Listens for date changes to invalidate today-specific data
final dashboardDateObserverProvider = Provider.autoDispose<void>((ref) {
  ref.listen(currentDateProvider, (previous, next) {
    if (previous != next) {
      ref.invalidate(dashboardDataProvider);
      ref.invalidate(aiInsightProvider);
    }
  });
});

class WeightLogController extends Notifier<void> {
  @override
  void build() {}
  Future<void> logWeight(double weight) async {
    await ref.read(journeyRepositoryProvider).logWeight(weight);
    ref.invalidateSelf();
    ref.invalidate(journeySetupControllerProvider);
  }
}
final weightLogControllerProvider = NotifierProvider<WeightLogController, void>(WeightLogController.new);
