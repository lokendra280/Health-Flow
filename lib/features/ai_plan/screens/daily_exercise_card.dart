import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/constants/app_topography.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/data/models/daily_workout.dart';
import 'package:habitflow/data/models/exercise_item.dart';
import 'package:habitflow/data/repositories/journey_repository_provider.dart';
import 'package:habitflow/features/ai_plan/providers/daily_exercise_provider.dart';
import 'package:habitflow/features/ai_plan/providers/weekly_workout_provider.dart';

class AiSuggestedScheduleList extends ConsumerWidget {
  final List<DailyWorkout> weeklySchedule;

  const AiSuggestedScheduleList({super.key, required this.weeklySchedule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final weekStart =
        today.subtract(Duration(days: today.weekday - 1)); // Monday

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: weeklySchedule.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final date = weekStart.add(Duration(days: i));
        return _DaySection(day: weeklySchedule[i], date: date);
      },
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DailyWorkout day;
  final DateTime date;
  const _DaySection({required this.day, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final isToday = _isSameDate(date, today);
    final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
    final isPast = !isToday && !isFuture;

    final completedNames = day.isRestDay
        ? const <String>{}
        : ref.watch(completedExercisesForDateProvider(dateKeyFor(date)));

    final doneCount =
        day.exercises.where((e) => completedNames.contains(e.name)).length;
    final remaining = day.exercises.length - doneCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.textMuted.withValues(alpha: 0.15),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(day.day, style: AppTypography.h3),
              const SizedBox(width: 8),
              if (day.isRestDay)
                _Pill(text: 'Rest day', color: AppColors.textMuted)
              else if (day.focus != null)
                _Pill(text: day.focus!, color: AppColors.primary),
              // const Spacer(),
              // if (!day.isRestDay && day.exercises.isNotEmpty)
              //   Text(
              //     isFuture
              //         ? '${day.exercises.length} planned'
              //         : isPast
              //             ? '$doneCount of ${day.exercises.length} done'
              //             : '$doneCount done · $remaining remaining',
              //     style: AppTypography.bodySmall,
              //   ),
            ],
          ),
          if (!day.isRestDay) ...[
            const SizedBox(height: 12),
            for (final exercise in day.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _ExerciseLine(
                  exercise: exercise,
                  isDone: completedNames.contains(exercise.name),
                  // Only today is checkable — past days are a locked
                  // record of what happened, future days have nothing
                  // to log yet.
                  onToggle: !isToday
                      ? null
                      : () async {
                          final repo = ref.read(journeyRepositoryProvider);
                          await repo.toggleExerciseDone(date, exercise.name);
                          ref.invalidate(completedExercisesForDateProvider(
                              dateKeyFor(date)));
                          ref.invalidate(weeklyWorkoutSummaryProvider);
                          ref.invalidate(todayWorkoutSummaryProvider);
                        },
                ),
              ),
          ],
        ],
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ExerciseLine extends StatelessWidget {
  final ExerciseItem exercise;
  final bool isDone;
  final VoidCallback? onToggle;

  const _ExerciseLine({
    required this.exercise,
    required this.isDone,
    required this.onToggle,
  });

  Color _categoryColor() {
    switch (exercise.category) {
      case ExerciseCategory.cardio:
        return const Color(0xFFE8555A);
      case ExerciseCategory.mobility:
        return const Color(0xFF8C6FE0);
      case ExerciseCategory.strength:
        return const Color(0xFF3B9EDB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onToggle == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? AppColors.primary
                        : AppColors.textMuted.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _categoryColor(),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exercise.name,
                  style: AppTypography.body.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: disabled && !isDone
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(exercise.sets, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
