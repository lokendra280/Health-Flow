import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/constants/app_string.dart';
import 'package:habitflow/core/utils/date_utils.dart';
import 'package:habitflow/features/ai_plan/providers/ai_plan_provider.dart';
import 'package:habitflow/features/food_tracking/providers/food_tracking_provider.dart';
import 'package:habitflow/features/food_tracking/widgets/calories_card.dart';
import 'package:habitflow/features/food_tracking/widgets/food_scan_result.dart';
import 'package:habitflow/data/models/tracking_models.dart';
import 'package:habitflow/features/food_tracking/widgets/macros_card.dart';
import 'package:habitflow/features/food_tracking/widgets/meal_row.dart';
import 'package:habitflow/features/food_tracking/widgets/quic_scan_row.dart';
import 'package:habitflow/features/food_tracking/widgets/week_strip.dart';
import 'widgets/add_food_sheet.dart';

class FoodTrackingScreen extends ConsumerWidget {
  const FoodTrackingScreen({super.key});

  static const double _fallbackCalorieTarget = 2000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = DateTime.now().normalized;
    final entries = ref.watch(foodLogProvider(day));
    final text = Theme.of(context).textTheme;

    final totalCal = entries.fold<double>(0, (s, e) => s + (e.calories ?? 0));
    final totalCarbs = entries.fold<double>(0, (s, e) => s + (e.carbs ?? 0));
    final totalFat = entries.fold<double>(0, (s, e) => s + (e.fat ?? 0));
    final totalProtein =
        entries.fold<double>(0, (s, e) => s + (e.protein ?? 0));

    final plan = ref.watch(aiPlanControllerProvider);
    final calorieTarget =
        (plan?.calorieTarget ?? _fallbackCalorieTarget).toDouble();
    final carbTarget = calorieTarget * 0.40 / 4; // 4 kcal/g
    final proteinTarget = calorieTarget * 0.30 / 4;
    final fatTarget = calorieTarget * 0.30 / 9; // 9 kcal/g
    final byMeal = <String, List<FoodEntry>>{
      'breakfast': [],
      'lunch': [],
      'dinner': [],
      'snack': [],
    };
    for (final e in entries) {
      (byMeal[e.mealType] ??= []).add(e);
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _TodayHeader(
                  date: day,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: WeekStrip(selectedDate: day),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: CalorieCard(
                  eaten: totalCal,
                  target: calorieTarget,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: MacrosCard(
                  carbs: totalCarbs,
                  carbTarget: carbTarget,
                  fat: totalFat,
                  fatTarget: fatTarget,
                  protein: totalProtein,
                  proteinTarget: proteinTarget,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: QuickScanRow(day: day),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Diary', style: text.titleLarge),
                    TextButton(
                      onPressed:
                          () {}, // TODO: wire to a full diary/history screen
                      child: const Text('View all'),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList.list(children: [
                MealRow(
                  icon: Icons.free_breakfast_rounded,
                  iconColor: Colors.blue,
                  title: 'Breakfast',
                  entries: byMeal['breakfast']!,
                  onLog: () => showAddFoodSheet(context, ref, day),
                ),
                const SizedBox(height: 12),
                MealRow(
                  icon: Icons.lunch_dining_rounded,
                  iconColor: Colors.blue,
                  title: 'Lunch',
                  entries: byMeal['lunch']!,
                  onLog: () => showAddFoodSheet(context, ref, day),
                ),
                const SizedBox(height: 12),
                MealRow(
                  icon: Icons.dinner_dining_rounded,
                  iconColor: Colors.blue,
                  title: 'Dinner',
                  entries: byMeal['dinner']!,
                  onLog: () => showAddFoodSheet(context, ref, day),
                ),
                const SizedBox(height: 12),
                MealRow(
                  icon: Icons.cookie_outlined,
                  iconColor: Colors.blue,
                  title: 'Snack',
                  entries: byMeal['snack']!,
                  onLog: () => showAddFoodSheet(context, ref, day),
                ),
              ]),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddFoodSheet(context, ref, day),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// "Today ▾" header + streak badge
// ---------------------------------------------------------------------------

class _TodayHeader extends StatelessWidget {
  final DateTime date;
  const _TodayHeader({
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              AppString.caloriesTracking,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}
