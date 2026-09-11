import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/utils/date_utils.dart';
import 'package:habitflow/features/habit_tracking/providers/habit_tracking_provider.dart';
import 'package:habitflow/features/steps/ui/step_count_provider.dart';
import '../../data/models/tracking_models.dart';
import '../../data/repositories/journey_repository_provider.dart';
import '../ai_plan/providers/ai_plan_provider.dart';
import '../journey_setup/providers/journey_setup_provider.dart';
import '../personal_profile/providers/personal_profile_provider.dart';

class AiCoachController extends Notifier<List<ChatMessage>> {
  @override
  List<ChatMessage> build() =>
      ref.read(journeyRepositoryProvider).chatHistory();

  /// Phase 6 data_context: pulls real profile/goal/habits/logs/weight
  /// history/measurements/check-ins instead of a placeholder string.
  Future<String> _buildContext() async {
    final repo = ref.read(journeyRepositoryProvider);
    final goal = ref.read(journeySetupControllerProvider);
    final profile = ref.read(personalProfileControllerProvider);
    final habits = ref.read(habitControllerProvider);
    final today = DateTime.now().normalized;

    // Fetch real-time steps from health provider
    final steps = await ref.read(todayStepsProvider.future);

    return '''
Goal: ${goal.type}, ${goal.currentWeight}->${goal.targetWeight} ${goal.weightUnit}, target date ${goal.targetDate?.normalized}.
Profile: age ${profile.age}, ${profile.gender}, activity ${profile.activityLevel}, diet ${profile.dietPreference}, allergies ${profile.foodAllergies}.
Habits: ${habits.map((h) => '${h.name} (streak ${h.streak})').join(', ')}.
Today: water ${repo.waterFor(today)}ml, steps $steps, food ${repo.foodEntriesFor(today).map((f) => f.name).join(', ')}.
Body measurements logged: ${repo.measurements().length}. Recent check-in: ${repo.checkInFor(today)?.mood}.
''';
  }

  Future<void> send(String text) async {
    state = [...state, ChatMessage(role: 'user', content: text)];
    await ref.read(journeyRepositoryProvider).saveChatHistory(state);
    final gemini = ref.read(geminiServiceProvider);
    final contextSummary = await _buildContext();
    final reply =
        await gemini.chat(history: state, contextSummary: contextSummary);
    state = [...state, ChatMessage(role: 'assistant', content: reply)];
    await ref.read(journeyRepositoryProvider).saveChatHistory(state);
  }
}

final aiCoachControllerProvider =
    NotifierProvider<AiCoachController, List<ChatMessage>>(
        AiCoachController.new);

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});
  @override
  ConsumerState<AiCoachScreen> createState() => _State();
}

class _State extends ConsumerState<AiCoachScreen> {
  final inputCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiCoachControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (_, i) {
              final m = messages[i];
              final mine = m.role == 'user';
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: mine ? Colors.teal[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(m.content),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
                child: TextField(
                    controller: inputCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Ask your coach…',
                        border: OutlineInputBorder()))),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                if (inputCtrl.text.isEmpty) return;
                ref
                    .read(aiCoachControllerProvider.notifier)
                    .send(inputCtrl.text);
                inputCtrl.clear();
              },
            ),
          ]),
        ),
      ]),
    );
  }
}
