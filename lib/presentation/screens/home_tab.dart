import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/widgets/empty_habit.dart';
import 'package:habitflow/presentation/widgets/habit_card.dart';
import 'package:habitflow/presentation/widgets/progress_card.dart';
import 'package:habitflow/presentation/widgets/sync_status_widget.dart';

class HomeTab extends ConsumerWidget {
  final Future<void> Function(String habitId, int target) onCheckin;
  final VoidCallback onAddHabit;
  final void Function(Habit) onEditHabit;
  final String? justDone;
  final bool isDark;
  final AppUser? user;
  final VoidCallback onToggleTheme;

  const HomeTab({
    required this.onCheckin,
    required this.onAddHabit,
    required this.onEditHabit,
    required this.justDone,
    required this.isDark,
    required this.user,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitListProvider);
    final progress = ref.watch(progressProvider);
    final streak = ref.watch(overallStreakProvider);
    final longest = ref.watch(longestEverProvider);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(children: [
                // Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: context.dmSans(13, FontWeight.w400,
                              color: context.textSecondary)),
                      Text(user?.displayName ?? 'Habit Builder',
                          style: context.syne(22, FontWeight.w800)),
                    ],
                  ),
                ),
                // Sync badge
                const SyncStatusWidget(compact: true),
                const Gap(10),
                // Theme toggle
                _IconBtn(
                  child: Text(isDark ? '☀️' : '🌙',
                      style: const TextStyle(fontSize: 18)),
                  onTap: onToggleTheme,
                ),
                const Gap(10),
                // Add
                GestureDetector(
                  onTap: onAddHabit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: context.accent.withOpacity(0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ]),
            ),
          ),

          // ── Progress card ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: ProgressCard(
                done: progress.done,
                total: progress.total,
                streak: streak,
                longest: longest,
              ),
            ),
          ),

          // ── Section header ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
              child: Row(children: [
                Text("Today's Habits",
                    style: context.syne(19, FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: onAddHabit,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.pillBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 15, color: context.pillFg),
                      const Gap(4),
                      Text('Add',
                          style: context.dmSans(13, FontWeight.w600,
                              color: context.pillFg)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),

          // ── Habit list ────────────────────────────────
          habitsAsync.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('$e'))),
            data: (habits) {
              if (habits.isEmpty) {
                return SliverToBoxAdapter(
                    child: EmptyHabits(onAdd: onAddHabit));
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (ctx, i) {
                    final h = habits[i];
                    final done = ref.watch(todayCountProvider(h.id));
                    final s = ref.watch(streakProvider(h.id));
                    return HabitCard(
                      habit: h,
                      done: done,
                      streak: s,
                      justCompleted: justDone == h.id,
                      onCheckin: () => onCheckin(h.id, h.targetPerDay),
                      onEdit: () => onEditHabit(h),
                    );
                  },
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: Gap(100)),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning! 🌅';
    if (h < 17) return 'Good afternoon! ⚡';
    return 'Good evening! 🌙';
  }
}

class _IconBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _IconBtn({required this.child, required this.onTap});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ctx.surfaceColor,
            shape: BoxShape.circle,
            border: Border.all(color: ctx.border2, width: 1.5),
          ),
          child: Center(child: child),
        ),
      );
}
