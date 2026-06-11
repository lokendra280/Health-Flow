import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/widgets/empty_habit.dart';
import 'package:habitflow/presentation/widgets/habit_card.dart';
import 'package:habitflow/presentation/widgets/sync_status_widget.dart';

class HomeTab extends ConsumerWidget {
  final Future<void> Function(String, int) onCheckin;
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
    super.key,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '🌅 Good Morning,';
    if (h < 17) return '⚡ Good Afternoon,';
    return '🌙 Good Evening,';
  }

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
          // ── Header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(_greeting(),
                          style: context.dmSans(14, FontWeight.w500,
                              color: context.textSecondary)),
                      const Gap(2),
                      Text(user?.displayName ?? 'Alex!'.toUpperCase(),
                          style: context.syne(24, FontWeight.w500)),
                    ])),
                const SyncStatusWidget(compact: true),
                const Gap(8),
                _IconBtn(
                    onTap: onToggleTheme,
                    child: Text(isDark ? '☀️' : '🌙',
                        style: const TextStyle(fontSize: 16))),
                const Gap(8),
                // Calendar icon (matches design)
                _IconBtn(
                    onTap: () {},
                    child: Icon(Icons.calendar_today_outlined,
                        size: 18, color: context.textSecondary)),
              ]),
            ),
          ),

          // ── Streak card ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _StreakCard(
                  streak: streak,
                  longest: longest,
                  done: progress.done,
                  total: progress.total),
            ),
          ),

          // ── Today's habits header ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
              child: Row(children: [
                Text("Today's Habits",
                    style: context.syne(18, FontWeight.w700)),
                const Spacer(),
                Text(
                  '${progress.done}/${progress.total} completed',
                  style: context.dmSans(12, FontWeight.w500,
                      color: const Color(0xFF52B788)),
                ),
              ]),
            ),
          ),

          // ── Progress bar ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                    value:
                        progress.total > 0 ? progress.done / progress.total : 0,
                    minHeight: 6,
                    backgroundColor: context.surface3,
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFF52B788))),
              ),
            ),
          ),

          // ── Habit list ────────────────────────────────────────
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
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (_, i) {
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
}

// ── Streak card ───────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int streak, longest, done, total;
  const _StreakCard(
      {required this.streak,
      required this.longest,
      required this.done,
      required this.total});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF52B788).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Row(children: [
          // Current streak
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Current Streak',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(.75),
                        fontWeight: FontWeight.w500)),
                const Gap(6),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$streak',
                      style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1)),
                  const Gap(4),
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('days',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(.75),
                              fontWeight: FontWeight.w500))),
                ]),
              ])),

          // Fire emoji
          Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15), shape: BoxShape.circle),
              child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 32)))),

          const Gap(16),

          // Best streak
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Best Streak',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(.75),
                    fontWeight: FontWeight.w500)),
            const Gap(4),
            Text('$longest',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1)),
            Text('days',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(.75))),
          ]),
        ]),
      );
}

// ── Icon button ───────────────────────────────────────────────────
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
                border: Border.all(color: ctx.border2, width: 1.5)),
            child: Center(child: child)),
      );
}
