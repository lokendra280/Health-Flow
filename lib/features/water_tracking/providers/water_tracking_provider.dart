import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/providers/date_provider.dart';
import '../../../data/repositories/journey_repository_provider.dart';
import '../../ai_plan/providers/ai_plan_provider.dart';

/// ml added per tap of a glass in the UI. Kept as a fixed constant
/// (not plan-driven) since this represents "one glass," a physical
/// unit — the AI plan only dictates the *daily total* in ml, not how
/// big a single glass is assumed to be.
const int kMlPerGlass = 250;

class WaterController extends Notifier<int> {
  @override
  int build() {
    final today = ref.watch(currentDateProvider);
    return ref.read(journeyRepositoryProvider).waterFor(today);
  }

  Future<void> quickAdd(int ml) async {
    final today = ref.read(currentDateProvider);
    state += ml;
    await ref.read(journeyRepositoryProvider).saveWater(today, state);
    final target = ref.read(aiPlanControllerProvider)?.waterTarget ?? 2000;
    if (state >= target) {
      await ref.read(journeyRepositoryProvider).recordActivity('water');
    }
  }
}

final waterControllerProvider =
    NotifierProvider<WaterController, int>(WaterController.new);

/// Real ml target from the accepted AI plan — 2000ml fallback only
/// applies pre-onboarding, before a plan has been generated/accepted.
final waterTargetProvider = Provider<int>(
    (ref) => ref.watch(aiPlanControllerProvider)?.waterTarget ?? 2000);

/// Glass-count equivalent of waterTargetProvider, for UI that shows
/// discrete glasses (the droplet grid, "X of Y glasses" text) rather
/// than a raw ml number. Rounds up so hitting the ml target always
/// means the glass grid reads as fully filled, never "14.5/15."
final waterGlassGoalProvider = Provider<int>((ref) {
  final targetMl = ref.watch(waterTargetProvider);
  return (targetMl / kMlPerGlass).ceil();
});

final waterProgressProvider = Provider<double>((ref) {
  final target = ref.watch(waterTargetProvider);
  if (target <= 0) return 0.0;
  return (ref.watch(waterControllerProvider) / target).clamp(0.0, 1.0);
});

final weeklyWaterHistoryProvider = Provider<List<int>>((ref) {
  final repo = ref.watch(journeyRepositoryProvider);
  final today = DateTime.now();
  return [
    for (var i = 6; i >= 0; i--)
      repo.waterFor(today.subtract(Duration(days: i)))
  ];
});
