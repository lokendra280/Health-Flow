import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../providers.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(nutritionProvider);
    final user = ref.watch(userProvider);
    final totalCal = logs.fold(0, (s, n) => s + n.calories);
    final totalP = logs.fold(0, (s, n) => s + n.protein);
    final totalC = logs.fold(0, (s, n) => s + n.carbs);
    final totalF = logs.fold(0, (s, n) => s + n.fat);
    final meals = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF9F43),
        onPressed: () => _showAdd(context, ref),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Macro summary
          if (logs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _macroStat('Calories', '$totalCal', 'kcal', const Color(0xFFFF9F43)),
                  _macroStat('Protein', '${totalP}g', '', const Color(0xFF6C63FF)),
                  _macroStat('Carbs', '${totalC}g', '', const Color(0xFF00C896)),
                  _macroStat('Fat', '${totalF}g', '', const Color(0xFFFF6B6B)),
                ]),
                const SizedBox(height: 16),
                if (totalP + totalC + totalF > 0) SizedBox(
                  height: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Row(children: [
                      _macroBar(totalP, totalP + totalC + totalF, const Color(0xFF6C63FF)),
                      _macroBar(totalC, totalP + totalC + totalF, const Color(0xFF00C896)),
                      _macroBar(totalF, totalP + totalC + totalF, const Color(0xFFFF6B6B)),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // By meal group
          ...meals.map((meal) {
            final items = logs.where((n) => n.meal == meal).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionHeader(title: meal),
              ...items.map((n) => Dismissible(
                key: Key(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                onDismissed: (_) => ref.read(nutritionProvider.notifier).delete(n.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(n.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text('${n.calories} kcal · P${n.protein} C${n.carbs} F${n.fat}',
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ]),
                ),
              )),
            ]);
          }),

          if (logs.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 60),
              child: Text('No meals logged today.\nTap + to add food!',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
            )),
        ]),
      ),
    );
  }

  Widget _macroStat(String label, String val, String unit, Color color) => Column(children: [
    Text(val + unit, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
  ]);

  Widget _macroBar(int val, int total, Color color) => Expanded(
    flex: val, child: Container(color: color));

  void _showAdd(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final cal = TextEditingController();
    final prot = TextEditingController();
    final carb = TextEditingController();
    final fat = TextEditingController();
    String meal = 'Breakfast';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.cardAlt,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Add Food', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          InputField(label: 'Food name', hint: 'e.g. Oatmeal', controller: name),
          InputField(label: 'Calories', hint: '350', controller: cal,
            keyboardType: TextInputType.number, suffixText: 'kcal'),
          Row(children: [
            Expanded(child: InputField(label: 'Protein', hint: '12', controller: prot,
              keyboardType: TextInputType.number, suffixText: 'g')),
            const SizedBox(width: 12),
            Expanded(child: InputField(label: 'Carbs', hint: '45', controller: carb,
              keyboardType: TextInputType.number, suffixText: 'g')),
            const SizedBox(width: 12),
            Expanded(child: InputField(label: 'Fat', hint: '8', controller: fat,
              keyboardType: TextInputType.number, suffixText: 'g')),
          ]),
          const Text('Meal', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: ['Breakfast','Lunch','Dinner','Snack'].map((m) => ChoiceChip(
            label: Text(m), selected: meal == m,
            onSelected: (_) => setState(() => meal = m),
            selectedColor: const Color(0xFFFF9F43), backgroundColor: AppTheme.card,
            labelStyle: TextStyle(color: meal == m ? Colors.black : Colors.white),
          )).toList()),
          const SizedBox(height: 20),
          GradientButton(
            text: 'Add Food',
            colors: [const Color(0xFFFF9F43), const Color(0xFFFF6B6B)],
            onPressed: () {
              if (name.text.isEmpty) return;
              ref.read(nutritionProvider.notifier).add(
                name.text, meal,
                int.tryParse(cal.text) ?? 0, int.tryParse(prot.text) ?? 0,
                int.tryParse(carb.text) ?? 0, int.tryParse(fat.text) ?? 0,
              );
              Navigator.pop(ctx);
            },
          ),
        ])),
      )),
    );
  }
}
