import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/health_calc.dart';
import '../providers.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(sleepProvider);
    final avgHours = logs.isNotEmpty ? logs.map((s) => s.hours).reduce((a, b) => a + b) / logs.length : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracker')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF74B9FF),
        onPressed: () => _showAdd(context, ref),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          if (logs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _sleepStat('Avg sleep', '${avgHours.toStringAsFixed(1)}h',
                  HealthCalc.sleepQuality(avgHours), const Color(0xFF74B9FF)),
                _sleepStat('Last night', '${logs.first.hours.toStringAsFixed(1)}h',
                  HealthCalc.sleepQuality(logs.first.hours), const Color(0xFFA29BFE)),
                _sleepStat('Quality', '${logs.first.qualityRating}/5',
                  '⭐' * logs.first.qualityRating, const Color(0xFFFFD93D)),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          ...logs.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF74B9FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bedtime, color: Color(0xFF74B9FF), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('EEE, MMM d').format(s.bedTime),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text('${DateFormat('h:mm a').format(s.bedTime)} → ${DateFormat('h:mm a').format(s.wakeTime)}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
                if (s.notes.isNotEmpty) Text(s.notes,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${s.hours.toStringAsFixed(1)}h',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(HealthCalc.sleepQuality(s.hours),
                  style: TextStyle(
                    color: s.hours >= 7 ? const Color(0xFF00C896) : const Color(0xFFFF9F43),
                    fontSize: 12)),
              ]),
            ]),
          )),

          if (logs.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.only(top: 60),
              child: Text('No sleep logs yet.\nTap + to log last night!',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
            )),
        ]),
      ),
    );
  }

  Widget _sleepStat(String label, String val, String sub, Color color) => Column(children: [
    Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 20)),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
    Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
  ]);

  void _showAdd(BuildContext context, WidgetRef ref) {
    TimeOfDay bedTime = const TimeOfDay(hour: 23, minute: 0);
    TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);
    int quality = 4;
    final notes = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.cardAlt,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Log Sleep', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _timePicker(ctx, 'Bed time', bedTime, (t) {
              if (t != null) setState(() => bedTime = t);
            })),
            const SizedBox(width: 12),
            Expanded(child: _timePicker(ctx, 'Wake time', wakeTime, (t) {
              if (t != null) setState(() => wakeTime = t);
            })),
          ]),
          const SizedBox(height: 16),
          const Text('Quality', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => quality = i + 1),
              child: Icon(Icons.star, size: 32,
                color: i < quality ? const Color(0xFFFFD93D) : Colors.white12),
            )),
          ),
          const SizedBox(height: 14),
          InputField(label: 'Notes (optional)', hint: 'How did you sleep?', controller: notes),
          GradientButton(
            text: 'Save Sleep',
            colors: [const Color(0xFF74B9FF), const Color(0xFFA29BFE)],
            onPressed: () {
              final now = DateTime.now();
              final bed = DateTime(now.year, now.month, now.day - 1, bedTime.hour, bedTime.minute);
              final wake = DateTime(now.year, now.month, now.day, wakeTime.hour, wakeTime.minute);
              ref.read(sleepProvider.notifier).add(bed, wake, quality, notes.text);
              Navigator.pop(ctx);
            },
          ),
        ]),
      )),
    );
  }

  Widget _timePicker(BuildContext ctx, String label, TimeOfDay time, Function(TimeOfDay?) onPick) =>
    GestureDetector(
      onTap: () async => onPick(await showTimePicker(context: ctx, initialTime: time)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 4),
          Text(time.format(ctx), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        ]),
      ),
    );
}
