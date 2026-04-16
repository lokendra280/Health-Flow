import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/health_calc.dart';
import '../providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final steps = ref.watch(stepsProvider);
    final workouts = ref.watch(workoutsProvider);
    final nutrition = ref.watch(nutritionProvider);
    final vitals = ref.watch(vitalsProvider);
    final sleepLogs = ref.watch(sleepProvider);

    final bmi = user != null ? HealthCalc.bmi(user.weightKg, user.heightCm) : 22.0;
    final goalSteps = steps?.goal ?? HealthCalc.dailyStepGoal(bmi);
    final todaySteps = steps?.steps ?? 0;
    final todayCals = nutrition.fold(0, (s, n) => s + n.calories);
    final bmr = user != null ? HealthCalc.bmrCalories(user.weightKg, user.heightCm, user.age, user.isMale) : 2000;
    final latestSleep = sleepLogs.isNotEmpty ? sleepLogs.first : null;
    final latestVital = vitals.isNotEmpty ? vitals.first : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Good ${_greeting()}! 👋', style: Theme.of(context).textTheme.headlineMedium),
                Text(user?.name ?? 'Set up profile',
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
              ]),
              Text(DateFormat('EEE, MMM d').format(DateTime.now()),
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
            ]),
            const SizedBox(height: 24),

            // Step ring hero
            Center(
              child: ProgressRing(
                value: todaySteps / goalSteps,
                label: '$todaySteps',
                sublabel: 'of $goalSteps steps',
                size: 140,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('${HealthCalc.stepsToKm(todaySteps).toStringAsFixed(2)} km  ·  '
                '${steps?.caloriesBurned.toStringAsFixed(0) ?? 0} cal burned',
                style: const TextStyle(color: Colors.white38, fontSize: 13)),
            ),
            const SizedBox(height: 24),

            // Stats grid
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(title: 'Calories in', value: '$todayCals',
                  unit: '/ $bmr kcal', icon: Icons.restaurant_outlined,
                  color: const Color(0xFFFF9F43)),
                StatCard(title: 'Workouts', value: '${workouts.where((w) {
                    final now = DateTime.now();
                    return w.date.year == now.year && w.date.month == now.month && w.date.day == now.day;
                  }).length}',
                  unit: 'today', icon: Icons.fitness_center, color: const Color(0xFF6C63FF)),
                StatCard(
                  title: 'Sleep',
                  value: latestSleep != null ? latestSleep.hours.toStringAsFixed(1) : '-',
                  unit: 'hrs', icon: Icons.bedtime_outlined, color: const Color(0xFF74B9FF)),
                StatCard(
                  title: 'Heart rate',
                  value: latestVital != null ? '${latestVital.heartRate}' : '-',
                  unit: 'bpm', icon: Icons.favorite_outline, color: const Color(0xFFFF6B6B)),
              ],
            ),
            const SizedBox(height: 24),

            // BMI card
            if (user != null) ...[
              const SectionHeader(title: 'Health overview'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D26),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _infoTile('BMI', bmi.toStringAsFixed(1), HealthCalc.bmiCategory(bmi)),
                  _divider(),
                  _infoTile('Goal', '${HealthCalc.dailyStepGoal(bmi)}', 'steps/day'),
                  _divider(),
                  _infoTile('Walk', '${HealthCalc.dailyWalkingKm(bmi).toStringAsFixed(1)} km', 'recommended'),
                ]),
              ),
            ],

            // Recent workouts
            if (workouts.isNotEmpty) ...[
              const SectionHeader(title: 'Recent workouts'),
              ...workouts.take(3).map((w) => _workoutTile(w)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value, String sub) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
    Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
  ]);

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white10);

  Widget _workoutTile(w) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF1A1D26), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.fitness_center, color: Color(0xFF6C63FF), size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(w.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        Text('${w.durationMin} min · ${w.calories} cal', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ])),
      Text(w.type, style: const TextStyle(color: Color(0xFF00C896), fontSize: 12)),
    ]),
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }
}
