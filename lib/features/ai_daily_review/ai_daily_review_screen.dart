import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/features/food_tracking/providers/food_tracking_provider.dart';
import 'package:habitflow/features/habit_tracking/providers/habit_tracking_provider.dart';
import 'package:habitflow/features/sleep_tracking/providers/sleep_provider.dart';
import 'package:habitflow/features/water_tracking/providers/water_tracking_provider.dart';
import '../ai_plan/providers/ai_plan_provider.dart';
import '../journey_setup/providers/journey_setup_provider.dart';
import '../water_tracking/water_tracking_screen.dart';
import '../activity_tracking/activity_tracking_screen.dart';
import '../sleep_tracking/sleep_tracking_screen.dart';
import '../habit_tracking/habit_tracking_screen.dart';
import '../daily_check_in/daily_check_in_screen.dart';

/// Generates today's AI review once per screen visit.
///
/// Deliberately uses ref.read (not ref.watch) for every dependency: this is
/// a one-shot snapshot of "how did today go", not a live view. Watching all
/// eight trackers would re-run the AI call — and force this whole screen
/// through mount/dispose — every time the user logs water, checks a habit,
/// etc. anywhere else in the app, which is what was causing the rapid
/// rebuild churn behind the Tooltip ticker crash.
final aiDailyReviewProvider = FutureProvider.autoDispose<String>((ref) async {
  final day = DateTime.now();
  final gemini = ref.read(geminiServiceProvider);
  return gemini.reviewDay(
    weight: ref.read(journeySetupControllerProvider).currentWeight,
    food: ref.read(foodLogProvider(day)),
    water: ref.read(waterControllerProvider),
    steps: ref.read(stepsControllerProvider),
    workouts: ref.read(workoutLogControllerProvider),
    sleep: ref.read(sleepControllerProvider),
    habits: ref.read(habitControllerProvider),
    checkIn: ref.read(dailyCheckInControllerProvider),
  );
});

class AiDailyReviewScreen extends ConsumerWidget {
  const AiDailyReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(aiDailyReviewProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("Today's AI review", style: text.headlineMedium),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: review.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Could not generate review: $e',
                  style: text.bodyMedium, textAlign: TextAlign.center),
            ),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      child: Text(data, style: text.bodyLarge),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('Not medical advice.', style: text.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
