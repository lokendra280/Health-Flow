import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../providers.dart';

class WellnessScreen extends ConsumerWidget {
  const WellnessScreen({super.key});

  static const moods = [
    ('😊', 'Happy'), ('😌', 'Calm'), ('😔', 'Sad'),
    ('😤', 'Stressed'), ('😤', 'Angry'), ('😴', 'Tired'),
    ('🤩', 'Excited'), ('😐', 'Neutral'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(moodProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mental Wellness')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFA29BFE),
        onPressed: () => _showAdd(context, ref),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Mood quick log
          const SectionHeader(title: 'How are you feeling?'),
          SizedBox(
            height: 80,
            child: ListView(scrollDirection: Axis.horizontal, children: moods.map((m) =>
              GestureDetector(
                onTap: () => ref.read(moodProvider.notifier).add(m.$2, '', 5),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(m.$1, style: const TextStyle(fontSize: 24)),
                    Text(m.$2, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
                ),
              ),
            ).toList()),
          ),
          const SizedBox(height: 24),

          // Tips
          const SectionHeader(title: 'Daily wellness tips'),
          ..._tips.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.card, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA29BFE).withOpacity(0.2)),
            ),
            child: Row(children: [
              Text(t.$1, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(child: Text(t.$2, style: const TextStyle(color: Colors.white70, fontSize: 13))),
            ]),
          )),
          const SizedBox(height: 24),

          // Mood history
          if (logs.isNotEmpty) ...[
            const SectionHeader(title: 'Mood history'),
            ...logs.take(10).map((m) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Text(_moodEmoji(m.mood), style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.mood, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  if (m.note.isNotEmpty) Text(m.note, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(DateFormat('MMM d').format(m.date), style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('Stress: ${m.stressLevel}/10', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                ]),
              ]),
            )),
          ],
        ]),
      ),
    );
  }

  static const _tips = [
    ('🧘', 'Take 5 deep breaths when feeling overwhelmed'),
    ('🚶', 'A 10-minute walk can boost your mood by 20%'),
    ('💧', 'Stay hydrated — dehydration affects mood and focus'),
    ('📱', 'Try a 30-min digital detox before bed tonight'),
    ('🙏', 'Write 3 things you\'re grateful for today'),
  ];

  String _moodEmoji(String mood) {
    final found = moods.where((m) => m.$2 == mood).firstOrNull;
    return found?.$1 ?? '😐';
  }

  void _showAdd(BuildContext context, WidgetRef ref) {
    String selected = 'Happy';
    int stress = 5;
    final note = TextEditingController();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppTheme.cardAlt,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Log Mood', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: moods.map((m) => GestureDetector(
            onTap: () => setState(() => selected = m.$2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected == m.$2 ? const Color(0xFFA29BFE).withOpacity(0.3) : AppTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selected == m.$2 ? const Color(0xFFA29BFE) : Colors.transparent),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(m.$1, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(m.$2, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            ),
          )).toList()),
          const SizedBox(height: 16),
          Text('Stress level: $stress/10', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Slider(
            value: stress.toDouble(), min: 1, max: 10, divisions: 9,
            activeColor: const Color(0xFFA29BFE),
            onChanged: (v) => setState(() => stress = v.round()),
          ),
          InputField(label: 'Note (optional)', hint: 'How was your day?', controller: note),
          GradientButton(
            text: 'Save Mood',
            colors: [const Color(0xFFA29BFE), const Color(0xFF74B9FF)],
            onPressed: () {
              ref.read(moodProvider.notifier).add(selected, note.text, stress);
              Navigator.pop(ctx);
            },
          ),
        ]),
      )),
    );
  }
}
