import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/tracking_models.dart';
import '../../../data/repositories/journey_repository_provider.dart';

class SleepController extends Notifier<SleepEntry?> {
  @override
  SleepEntry? build() {
    return ref.watch(journeyRepositoryProvider).sleepFor(DateTime.now().normalized);
  }

  Future<void> logSleep(SleepEntry e) async {
    final today = DateTime.now().normalized;
    await ref.read(journeyRepositoryProvider).saveSleep(today, e);
    state = e;
    // Record activity for streak tracking
    await ref.read(journeyRepositoryProvider).recordActivity('sleep');
  }
}

final sleepControllerProvider = NotifierProvider<SleepController, SleepEntry?>(
  SleepController.new,
);

final sleepGoalProvider = Provider<double>((ref) => 8.0);

final sleepHistoryProvider = Provider<List<double>>((ref) {
  final repo = ref.watch(journeyRepositoryProvider);
  final today = DateTime.now();
  // Get Mon-Sun of current week
  final monday = today.subtract(Duration(days: today.weekday - 1));
  
  return List.generate(7, (i) {
    final date = monday.add(Duration(days: i));
    return repo.sleepFor(date)?.hours ?? 0.0;
  });
});
