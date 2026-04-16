import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/utils/health_calc.dart';
import '../../core/theme/app_theme.dart';
import '../providers.dart';

class StepsScreen extends ConsumerStatefulWidget {
  const StepsScreen({super.key});
  @override
  ConsumerState<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends ConsumerState<StepsScreen> {
  Stream<StepCount>? _stepStream;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _initPedometer();
    final today = ref.read(stepsProvider);
    if (today != null) _steps = today.steps;
  }

  void _initPedometer() {
    _stepStream = Pedometer.stepCountStream;
    _stepStream?.listen((e) {
      setState(() => _steps = e.steps);
      ref.read(stepsProvider.notifier).update(e.steps);
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final bmi = user != null ? HealthCalc.bmi(user.weightKg, user.heightCm) : 22.0;
    final goal = HealthCalc.dailyStepGoal(bmi);
    final weekSteps = ref.watch(weekStepsProvider);
    final progress = (_steps / goal).clamp(0.0, 1.0);
    final km = HealthCalc.stepsToKm(_steps);
    final cal = user != null ? HealthCalc.stepsToCalories(_steps, user.weightKg) : _steps * 0.04;

    return Scaffold(
      appBar: AppBar(title: const Text('Step Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Big ring
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              ProgressRing(value: progress, label: '$_steps', sublabel: 'steps', size: 160),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat('Distance', '${km.toStringAsFixed(2)} km', Icons.route),
                _stat('Calories', '${cal.toStringAsFixed(0)} kcal', Icons.local_fire_department),
                _stat('Goal', '$goal steps', Icons.flag),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // BMI goal info
          if (user != null) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.2), AppTheme.secondary.withOpacity(0.2)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(
                'Your BMI is ${HealthCalc.bmi(user.weightKg, user.heightCm).toStringAsFixed(1)} '
                '(${HealthCalc.bmiCategory(bmi)}). Recommended: $goal steps '
                '(${HealthCalc.dailyWalkingKm(bmi).toStringAsFixed(1)} km/day)',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // Weekly chart
          if (weekSteps.isNotEmpty) ...[
            const SectionHeader(title: 'This week'),
            Container(
              height: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
              child: BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: goal.toDouble() * 1.2,
                barGroups: List.generate(weekSteps.length, (i) {
                  final s = weekSteps[i];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: s.steps.toDouble(),
                      color: s.steps >= s.goal ? AppTheme.primary : AppTheme.secondary.withOpacity(0.6),
                      width: 20, borderRadius: BorderRadius.circular(6),
                    ),
                  ]);
                }),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 24,
                    getTitlesWidget: (v, _) {
                      final days = ['M','T','W','T','F','S','S'];
                      return Text(v.toInt() < weekSteps.length
                        ? days[weekSteps[v.toInt()].date.weekday - 1] : '',
                        style: const TextStyle(color: Colors.white38, fontSize: 11));
                    },
                  )),
                ),
              )),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Column(children: [
    Icon(icon, color: AppTheme.primary, size: 20),
    const SizedBox(height: 6),
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
  ]);
}
