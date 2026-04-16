import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../providers.dart';

class FitnessScreen extends ConsumerWidget {
  const FitnessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        onPressed: () => _showAddWorkout(context, ref),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: workouts.isEmpty
        ? const Center(child: Text('No workouts yet.\nTap + to add one!',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)))
        : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: workouts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final w = workouts[i];
            return Dismissible(
              key: Key(w.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              onDismissed: (_) => ref.read(workoutsProvider.notifier).delete(w.id),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _typeColor(w.type).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_typeIcon(w.type), color: _typeColor(w.type), size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(w.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                    Text('${w.durationMin} min · ${w.calories} kcal · ${w.type}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ])),
                  Text(DateFormat('MMM d').format(w.date),
                    style: const TextStyle(color: Colors.white30, fontSize: 12)),
                ]),
              ),
            );
          },
        ),
    );
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'Cardio': return const Color(0xFFFF6B6B);
      case 'Strength': return const Color(0xFF6C63FF);
      case 'Yoga': return const Color(0xFF00C896);
      default: return const Color(0xFFFF9F43);
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'Cardio': return Icons.directions_run;
      case 'Strength': return Icons.fitness_center;
      case 'Yoga': return Icons.self_improvement;
      default: return Icons.sports;
    }
  }

  void _showAddWorkout(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final mins = TextEditingController();
    final cal = TextEditingController();
    String type = 'Cardio';
    final types = ['Cardio', 'Strength', 'Yoga', 'Sports', 'Other'];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.cardAlt,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Workout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          InputField(label: 'Exercise name', hint: 'e.g. Morning run', controller: name),
          Row(children: [
            Expanded(child: InputField(label: 'Duration', hint: '30', controller: mins,
              keyboardType: TextInputType.number, suffixText: 'min')),
            const SizedBox(width: 12),
            Expanded(child: InputField(label: 'Calories', hint: '200', controller: cal,
              keyboardType: TextInputType.number, suffixText: 'kcal')),
          ]),
          const Text('Type', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: types.map((t) => ChoiceChip(
            label: Text(t),
            selected: type == t,
            onSelected: (_) => setState(() => type = t),
            selectedColor: AppTheme.primary,
            backgroundColor: AppTheme.card,
            labelStyle: TextStyle(color: type == t ? Colors.black : Colors.white),
          )).toList()),
          const SizedBox(height: 20),
          GradientButton(text: 'Add Workout', onPressed: () {
            if (name.text.isEmpty) return;
            ref.read(workoutsProvider.notifier).add(
              name.text, type,
              int.tryParse(mins.text) ?? 30,
              int.tryParse(cal.text) ?? 200,
            );
            Navigator.pop(ctx);
          }),
        ]),
      )),
    );
  }
}
