import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_tracker/features/auth/profile_screen.dart';
import 'package:health_tracker/features/dashboard/dashboard_screen.dart';
import 'package:health_tracker/features/fitness/fitness_screen.dart';
import 'package:health_tracker/features/nutrition/nutrition_screen.dart';
import 'package:health_tracker/features/sleep/sleep_screen.dart';
import 'package:health_tracker/features/steps/steps_screen.dart';
import 'package:health_tracker/features/vitals/vitals_screen.dart';
import 'package:health_tracker/features/wellness/wellness_screen.dart';

final _navIndex = StateProvider<int>((ref) => 0);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _screens = [
    DashboardScreen(),
    StepsScreen(),
    FitnessScreen(),
    NutritionScreen(),
    _MoreScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = ref.watch(_navIndex);
    return Scaffold(
      body: IndexedStack(index: idx, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: idx,
        onTap: (i) => ref.read(_navIndex.notifier).state = i,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk_outlined),
              activeIcon: Icon(Icons.directions_walk),
              label: 'Steps'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Fitness'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_outlined),
              activeIcon: Icon(Icons.restaurant),
              label: 'Nutrition'),
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'More'),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Sleep',
        Icons.bedtime_outlined,
        const Color(0xFF74B9FF),
        () => _go(context, const SleepScreen())
      ),
      (
        'Wellness',
        Icons.spa_outlined,
        const Color(0xFFA29BFE),
        () => _go(context, const WellnessScreen())
      ),
      (
        'Vitals',
        Icons.favorite_outline,
        const Color(0xFFFF6B6B),
        () => _go(context, const VitalsScreen())
      ),
      (
        'Profile',
        Icons.person_outline,
        const Color(0xFF00C896),
        () => _go(context, const ProfileScreen())
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.3,
          children: items
              .map((item) => GestureDetector(
                    onTap: item.$4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: item.$3.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: item.$3.withOpacity(0.3)),
                      ),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.$2, color: item.$3, size: 36),
                            const SizedBox(height: 12),
                            Text(item.$1,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                          ]),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
