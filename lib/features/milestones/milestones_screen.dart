import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/features/habit_tracking/providers/habit_tracking_provider.dart';
import '../../data/models/tracking_models.dart';
import '../../data/repositories/journey_repository_provider.dart';
import '../journey_setup/providers/journey_setup_provider.dart';
import '../habit_tracking/habit_tracking_screen.dart';
import '../notifications/notification_service.dart';

class MilestoneController extends Notifier<List<Milestone>> {
  @override
  List<Milestone> build() =>
      ref.read(journeyRepositoryProvider).achievedMilestones();

  Future<void> _achieve(String type, String label, {int? percent}) async {
    if (state.any((m) => m.type == type && m.label == label)) return;
    final m = Milestone(
        type: type, label: label, percent: percent, achievedAt: DateTime.now());
    await ref.read(journeyRepositoryProvider).addMilestone(m);
    state = [...state, m];
    // await ref.read(notificationServiceProvider).celebrate(percent ?? 0);
  }

  /// weight_loss progress milestones (25/50/75/100%).
  Future<void> checkWeightProgress(double progressPercentage) async {
    final pct = (progressPercentage * 100).round();
    for (final threshold in [25, 50, 75, 100]) {
      if (pct >= threshold)
        await _achieve('weight_loss', '$threshold% of goal reached',
            percent: threshold);
    }
  }

  /// habit_streak, workout_count, step_count, water_consistency, meal_tracking,
  /// journey_consistency — checked against current streak/count data.
  Future<void> checkOtherTypes({
    required int journeyStreak,
    required int habitStreak,
    required int workoutCount,
    required int stepCount,
    required int waterStreak,
    required int mealTrackingStreak,
  }) async {
    for (final n in [7, 30, 100]) {
      if (journeyStreak >= n)
        await _achieve('journey_consistency', '$n-day journey streak');
      if (habitStreak >= n)
        await _achieve('habit_streak', '$n-day habit streak');
      if (waterStreak >= n)
        await _achieve('water_consistency', '$n-day water streak');
      if (mealTrackingStreak >= n)
        await _achieve('meal_tracking', '$n-day meal tracking streak');
    }
    for (final n in [10, 50, 100]) {
      if (workoutCount >= n)
        await _achieve('workout_count', '$n workouts logged');
    }
    for (final n in [10000, 50000, 100000]) {
      if (stepCount >= n)
        await _achieve('step_count', '$stepCount total steps');
    }
  }

  Future<void> addCustom(String label) => _achieve('custom', label);
}

final milestoneControllerProvider =
    NotifierProvider<MilestoneController, List<Milestone>>(
        MilestoneController.new);

class StreakController extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => ref.read(journeyRepositoryProvider).streaks();
}

final streakControllerProvider =
    NotifierProvider<StreakController, Map<String, int>>(StreakController.new);

class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(journeySetupControllerProvider);
    final pct = goal.progressPercentage;
    final streaks = ref.watch(streakControllerProvider);
    final habits = ref.watch(habitControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(milestoneControllerProvider.notifier);
      if (pct != null) controller.checkWeightProgress(pct);
      controller.checkOtherTypes(
        journeyStreak: streaks['journey'] ?? 0,
        habitStreak: habits.isEmpty
            ? 0
            : habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b),
        workoutCount: 0, // wire to a real cumulative counter when available
        stepCount: 0,
        waterStreak: streaks['water'] ?? 0,
        mealTrackingStreak: streaks['meal_tracking'] ?? 0,
      );
    });
    final milestones = ref.watch(milestoneControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Milestones')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('🔥 Journey streak: ${streaks['journey'] ?? 0} days',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        ...milestones.reversed.map((m) => ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.amber),
              title: Text(m.label),
              subtitle: Text(
                  '${m.type} · ${m.achievedAt.toLocal().toString().split(' ').first}'),
            )),
        if (milestones.isEmpty)
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No milestones reached yet — keep going!')),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final ctrl = TextEditingController();
          showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                    title: const Text('Custom milestone'),
                    content: TextField(controller: ctrl, autofocus: true),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () {
                            if (ctrl.text.isNotEmpty)
                              ref
                                  .read(milestoneControllerProvider.notifier)
                                  .addCustom(ctrl.text);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Add')),
                    ],
                  ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
