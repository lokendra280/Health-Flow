import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/presentation/screens/challenges_screen.dart';
import 'package:habitflow/presentation/screens/reminders_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';
import 'profile_screen.dart';
import '../widgets/sync_status_widget.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with TickerProviderStateMixin {
  int _navIdx = 0;
  String? _justDone; // habitId that just completed → confetti target

  final _confettiKey = GlobalKey<_ConfettiLayerState>();

  // ── Checkin ────────────────────────────────────────────────────────────────
  Future<void> _handleCheckin(String habitId, int target) async {
    HapticFeedback.mediumImpact();
    final completed =
        await ref.read(checkinProvider.notifier).checkIn(habitId, target);

    if (completed && mounted) {
      setState(() => _justDone = habitId);
      _confettiKey.currentState?.launch();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _justDone = null);
      });
    }

    // Push to cloud immediately
    ref.read(syncStateProvider.notifier).pushPending();
  }

  // ── Add / edit habit sheet ─────────────────────────────────────────────────
  void _showHabitSheet({Habit? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitSheet(
        editing: editing,
        habitCount: (ref.read(habitListProvider).value ?? []).length,
        onSave: (name, icon, target, ci) async {
          if (editing != null) {
            await ref.read(habitListProvider.notifier).updateHabit(
                  editing.copyWith(
                      name: name, icon: icon, targetPerDay: target),
                );
          } else {
            await ref.read(habitListProvider.notifier).addHabit(
                  name: name,
                  icon: icon,
                  targetPerDay: target,
                  colorIndex: ci,
                );
          }
          ref.read(syncStateProvider.notifier).pushPending();
        },
        onDelete: editing != null
            ? () async {
                await ref
                    .read(habitListProvider.notifier)
                    .deleteHabit(editing.id);
                ref.read(syncStateProvider.notifier).pushPending();
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider);
    final user = ref.watch(authStateProvider).user;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: context.bgColor,
          body: IndexedStack(
            index: _navIdx,
            children: [
              _HomeTab(
                onCheckin: _handleCheckin,
                onAddHabit: _showHabitSheet,
                onEditHabit: (h) => _showHabitSheet(editing: h),
                justDone: _justDone,
                isDark: isDark,
                user: user,
                onToggleTheme: () =>
                    ref.read(themeModeProvider.notifier).update((s) => !s),
              ),
              const _StatsTab(),
              const RemindersScreen(
                habits: [],
              ),
              const ChallengesScreen(
                habits: [],
              ),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _BottomNav(
            index: _navIdx,
            onTap: (i) => setState(() => _navIdx = i),
            user: user,
          ),
        ),
        _ConfettiLayer(key: _confettiKey),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HOME TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends ConsumerWidget {
  final Future<void> Function(String habitId, int target) onCheckin;
  final VoidCallback onAddHabit;
  final void Function(Habit) onEditHabit;
  final String? justDone;
  final bool isDark;
  final AppUser? user;
  final VoidCallback onToggleTheme;

  const _HomeTab({
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
              child: _ProgressCard(
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
                    child: _EmptyHabits(onAdd: onAddHabit));
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
                    return _HabitCard(
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

// ─── Progress Card ────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final int done, total, streak, longest;
  const _ProgressCard({
    required this.done,
    required this.total,
    required this.streak,
    required this.longest,
  });

  @override
  Widget build(BuildContext ctx) {
    final pct = total == 0 ? 0.0 : done / total;
    final msgs = [
      'Start checking in! 💪',
      'Keep the momentum! ⚡',
      'Great work today!',
      'Almost there! Push!',
      'Perfect day! 🎉',
    ];
    final mi = total == 0 ? 0 : (pct * 4).floor().clamp(0, 4);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF52B788)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2D6A4F).withOpacity(0.4),
            blurRadius: 28,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
            top: -28,
            right: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0x0AFFFFFF)),
            )),
        Row(children: [
          // Ring
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _RingPainter(pct),
              child: Center(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct),
                    duration: const Duration(milliseconds: 700),
                    builder: (_, v, __) => Text('${(v * 100).round()}%',
                        style: GoogleFonts.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                  Text('$done/$total',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: Colors.white60)),
                ],
              )),
            ),
          ),
          const Gap(20),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Progress",
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: Colors.white60, letterSpacing: 0.4)),
              const Gap(8),
              Row(children: [
                _MiniChip('🔥', '${streak}d'),
                const Gap(6),
                _MiniChip('🏆', 'Best ${longest}d'),
              ]),
              const Gap(10),
              Text(msgs[mi],
                  style:
                      GoogleFonts.dmSans(fontSize: 12, color: Colors.white54)),
            ],
          )),
        ]),
      ]),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String emoji, label;
  const _MiniChip(this.emoji, this.label);
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const Gap(4),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
      );
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);
  @override
  void paint(Canvas c, Size sz) {
    final cx = sz.width / 2, cy = sz.height / 2;
    final r = (min(sz.width, sz.height) - 8) / 2;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    c.drawCircle(Offset(cx, cy), r, p..color = Colors.white.withOpacity(0.18));
    c.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -pi / 2,
        2 * pi * progress, false, p..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ─── Habit Card ───────────────────────────────────────────────────────────────
class _HabitCard extends StatefulWidget {
  final Habit habit;
  final int done;
  final Streak streak;
  final bool justCompleted;
  final VoidCallback onCheckin;
  final VoidCallback onEdit;
  const _HabitCard({
    required this.habit,
    required this.done,
    required this.streak,
    required this.justCompleted,
    required this.onCheckin,
    required this.onEdit,
  });
  @override
  State<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<_HabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  late final Animation<double> _scale;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.mediumImpact();
    _bounce.forward(from: 0);
    widget.onCheckin();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.habit;
    final done = widget.done;
    final completed = done >= h.targetPerDay;
    final colorBg = h.color.withOpacity(context.isDark ? 0.16 : 0.10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: completed ? h.color.withOpacity(0.5) : context.borderColor,
          width: completed ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: completed
                ? h.color.withOpacity(0.12)
                : Colors.black.withOpacity(context.isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(children: [
          if (completed)
            Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: h.color)),
          Padding(
            padding: EdgeInsets.fromLTRB(completed ? 18 : 14, 14, 14, 14),
            child: Row(children: [
              // Icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: colorBg, borderRadius: BorderRadius.circular(14)),
                child: Center(
                    child: Text(h.icon, style: const TextStyle(fontSize: 26))),
              ),
              const Gap(14),

              // Info
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(h.name,
                            style: context.syne(15, FontWeight.w700),
                            overflow: TextOverflow.ellipsis)),
                    // Sync dot
                    if (!h.isSynced)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                            color: AppColors.amber700, shape: BoxShape.circle),
                      ),
                  ]),
                  const Gap(5),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    if (widget.streak.currentStreak > 0)
                      _Badge('🔥 ${widget.streak.currentStreak}d',
                          AppColors.amber100, AppColors.amber700),
                    _Badge('$done/${h.targetPerDay}', context.surface2,
                        context.textTertiary),
                    if (completed)
                      _Badge('✓ Done', context.accentSurf, context.accent),
                  ]),
                  const Gap(8),
                  Row(
                      children: List.generate(
                    h.targetPerDay.clamp(1, 10),
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200 + i * 40),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < done ? h.color : context.surface3,
                        ),
                      ),
                    ),
                  )),
                ],
              )),
              const Gap(10),

              // Checkin + edit
              Column(mainAxisSize: MainAxisSize.min, children: [
                ScaleTransition(
                  scale: _scale,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _pressing = true),
                    onTapUp: (_) {
                      setState(() => _pressing = false);
                      _tap();
                    },
                    onTapCancel: () => setState(() => _pressing = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed ? h.color : Colors.transparent,
                        border: Border.all(
                          color: completed
                              ? h.color
                              : _pressing
                                  ? h.color
                                  : context.border2,
                          width: 2,
                        ),
                        boxShadow: completed
                            ? [
                                BoxShadow(
                                  color: h.color.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        completed ? Icons.check_rounded : Icons.add_rounded,
                        size: 22,
                        color: completed
                            ? Colors.white
                            : _pressing
                                ? h.color
                                : context.textTertiary,
                      ),
                    ),
                  ),
                ),
                const Gap(8),
                GestureDetector(
                  onTap: widget.onEdit,
                  child: Text('edit',
                      style: context.dmSans(11, FontWeight.w400,
                          color: context.textTertiary)),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _Badge(this.text, this.bg, this.fg);
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: ctx.dmSans(11, FontWeight.w600, color: fg)),
      );
}

// ─── Stats Tab (minimal placeholder showing key stats) ───────────────────────
class _StatsTab extends ConsumerWidget {
  const _StatsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitListProvider).value ?? [];
    final longest = ref.watch(longestEverProvider);
    final overall = ref.watch(overallStreakProvider);
    final p = ref.watch(progressProvider);
    final repo = ref.watch(habitRepoProvider);

    final today = DateTime.now();
    final last7 = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));

      final done = habits.where((h) {
        return repo.getTodayCheckins(habitId: h.id).length >= h.targetPerDay;
      }).length;
      return (day: d, done: done, total: habits.length);
    });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Gap(8),
            Text('Stats', style: context.syne(28, FontWeight.w800)),
            const Gap(4),
            Text('Your habit performance at a glance.',
                style: context.dmSans(14, FontWeight.w400,
                    color: context.textSecondary)),
            const Gap(28),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.55,
              children: [
                _StatTile('🏆', 'Longest Streak', '${longest}d'),
                _StatTile('⚡', 'Current Streak', '${overall}d'),
                _StatTile('📋', 'Total Habits', '${habits.length}'),
                _StatTile('✅', 'Done Today', '${p.done}/${p.total}'),
              ],
            ),
            const Gap(28),
            Text('Last 7 Days', style: context.syne(18, FontWeight.w700)),
            const Gap(14),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: last7.map((e) {
                  final pct = e.total == 0 ? 0.0 : e.done / e.total;
                  const maxH = 80.0;
                  final barH = (pct * maxH).clamp(4.0, maxH);
                  final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  final isToday = e.day.day == today.day;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${e.done}',
                          style: context.dmSans(10, FontWeight.w600,
                              color: context.textTertiary)),
                      const Gap(4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: barH),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, h, __) => Container(
                          width: 28,
                          height: h,
                          decoration: BoxDecoration(
                            color: pct == 0
                                ? context.surface3
                                : isToday
                                    ? context.accent
                                    : context.accent.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const Gap(6),
                      Text(days[e.day.weekday % 7],
                          style: context.dmSans(11, FontWeight.w400,
                              color: isToday
                                  ? context.accent
                                  : context.textTertiary)),
                    ],
                  );
                }).toList(),
              ),
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String emoji, label, value;
  const _StatTile(this.emoji, this.label, this.value);

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: ctx.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ctx.borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
            const Gap(3),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ctx.syne(20, FontWeight.w800),
              ),
            ),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ctx.dmSans(
                  11,
                  FontWeight.w400,
                  color: ctx.textTertiary,
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── Placeholder Tab ─────────────────────────────────────────────────────────
class _PlaceholderTab extends StatelessWidget {
  final String emoji, title, sub;
  const _PlaceholderTab(
      {required this.emoji, required this.title, required this.sub});
  @override
  Widget build(BuildContext ctx) => SafeArea(
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const Gap(16),
          Text(title, style: ctx.syne(22, FontWeight.w700)),
          const Gap(8),
          Text(sub,
              style: ctx.dmSans(14, FontWeight.w400, color: ctx.textSecondary),
              textAlign: TextAlign.center),
        ])),
      );
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final AppUser? user;
  const _BottomNav({required this.index, required this.onTap, this.user});

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Stats'),
    (Icons.notifications_rounded, Icons.notifications_outlined, 'Remind'),
    (Icons.emoji_events_rounded, Icons.emoji_events_outlined, 'Goals'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _items.asMap().entries.map((e) {
                final i = e.key;
                final (ai, ii, label) = e.value;
                final active = i == index;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? context.accentSurf : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Profile tab shows initials avatar
                      i == 4 && user != null
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    active ? context.accent : context.surface3,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                  child: Text(
                                user!.initials.substring(0, 1),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: active
                                      ? Colors.white
                                      : context.textTertiary,
                                ),
                              )),
                            )
                          : Icon(active ? ai : ii,
                              size: 24,
                              color: active
                                  ? context.accent
                                  : context.textTertiary),
                      const Gap(3),
                      Text(label,
                          style: context.dmSans(10, FontWeight.w500,
                              color: active
                                  ? context.accent
                                  : context.textTertiary)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyHabits extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHabits({required this.onAdd});
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ctx.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ctx.borderColor, width: 1.5),
          ),
          child: Column(children: [
            const Text('🌱', style: TextStyle(fontSize: 52)),
            const Gap(14),
            Text('No habits yet',
                style: ctx.syne(20, FontWeight.w700, color: ctx.textSecondary)),
            const Gap(8),
            Text('Add your first habit and start a streak!',
                textAlign: TextAlign.center,
                style:
                    ctx.dmSans(14, FontWeight.w400, color: ctx.textTertiary)),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Habit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ctx.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ]),
        ),
      );
}

// ─── Icon Button ─────────────────────────────────────────────────────────────
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

// ─── Add / Edit Habit Sheet ───────────────────────────────────────────────────
class _HabitSheet extends StatefulWidget {
  final Habit? editing;
  final int habitCount;
  final Future<void> Function(String, String, int, int) onSave;
  final VoidCallback? onDelete;
  const _HabitSheet({
    required this.editing,
    required this.habitCount,
    required this.onSave,
    this.onDelete,
  });
  @override
  State<_HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<_HabitSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '🏃';
  int _target = 1;
  bool _saving = false;

  static const _icons = [
    '🏃',
    '💪',
    '📚',
    '🧘',
    '💧',
    '🥗',
    '🎨',
    '✍️',
    '🎵',
    '🌿',
    '💤',
    '🧹',
    '🤸',
    '🧠',
    '☀️',
    '🫁',
    '🎯',
    '🏊',
    '🚴',
    '🧗',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _icon = widget.editing!.icon;
      _target = widget.editing!.targetPerDay;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _nameCtrl.text.trim(),
        _icon,
        _target,
        widget.habitCount % 8,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          left: 24,
          right: 24,
          top: 14,
        ),
        child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: context.border2,
                  borderRadius: BorderRadius.circular(99)),
            )),
            const Gap(22),
            Row(children: [
              Text(widget.editing != null ? 'Edit Habit' : 'New Habit',
                  style: context.syne(24, FontWeight.w800)),
              const Spacer(),
              if (widget.onDelete != null)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDelete!();
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.coral700),
                ),
            ]),
            Text('Build a streak, one day at a time.',
                style: context.dmSans(13, FontWeight.w400,
                    color: context.textSecondary)),
            const Gap(22),

            // Name
            Text('Name',
                style: context.dmSans(13, FontWeight.w600,
                    color: context.textSecondary)),
            const Gap(8),
            TextField(
              controller: _nameCtrl,
              autofocus: widget.editing == null,
              style: context.dmSans(15, FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'e.g. Morning Run…',
                prefixIcon: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Text(_icon, style: const TextStyle(fontSize: 22))),
              ),
            ),
            const Gap(16),

            // Icons
            Text('Icon',
                style: context.dmSans(13, FontWeight.w600,
                    color: context.textSecondary)),
            const Gap(8),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final ic = _icons[i];
                  final sel = ic == _icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = ic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: sel ? context.accentSurf : context.surface2,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                            color: sel ? context.accent : context.borderColor,
                            width: sel ? 2 : 1.5),
                      ),
                      child: Center(
                          child:
                              Text(ic, style: const TextStyle(fontSize: 22))),
                    ),
                  );
                },
              ),
            ),
            const Gap(16),

            // Target
            Text('Daily Target',
                style: context.dmSans(13, FontWeight.w600,
                    color: context.textSecondary)),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: Row(children: [
                Expanded(
                    child: Text(
                  _target == 1 ? 'Once per day' : '$_target times per day',
                  style: context.dmSans(14, FontWeight.w400),
                )),
                _StepBtn(Icons.remove_rounded,
                    () => setState(() => _target = (_target - 1).clamp(1, 20))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_target',
                        style: context.syne(24, FontWeight.w800))),
                _StepBtn(Icons.add_rounded,
                    () => setState(() => _target = (_target + 1).clamp(1, 20))),
              ]),
            ),
            const Gap(28),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        widget.editing != null ? 'Save Changes' : 'Add Habit',
                        style: context.syne(17, FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ],
        )),
      );
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ctx.surface3,
            shape: BoxShape.circle,
            border: Border.all(color: ctx.border2, width: 1.5),
          ),
          child: Icon(icon, size: 20, color: ctx.textPrimary),
        ),
      );
}

// ─── Confetti Layer ───────────────────────────────────────────────────────────
class _ConfettiLayer extends StatefulWidget {
  const _ConfettiLayer({super.key});
  @override
  State<_ConfettiLayer> createState() => _ConfettiLayerState();
}

class _ConfettiLayerState extends State<_ConfettiLayer>
    with TickerProviderStateMixin {
  AnimationController? _ctrl;
  List<_Conf> _particles = [];
  final _rng = Random();

  static const _colors = [
    Color(0xFF52B788),
    Color(0xFFFCD34D),
    Color(0xFFFCA5A5),
    Color(0xFF93C5FD),
    Color(0xFFC4B5FD),
    Color(0xFFFB923C),
  ];

  void launch() {
    _ctrl?.dispose();
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..addListener(() => setState(() {}))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted)
          setState(() => _particles = []);
      });
    _ctrl = ctrl;
    setState(() {
      _particles = List.generate(
          50,
          (_) => _Conf(
                x: _rng.nextDouble(),
                color: _colors[_rng.nextInt(_colors.length)],
                size: 5 + _rng.nextDouble() * 8,
                delay: _rng.nextDouble() * 0.5,
                speed: 0.5 + _rng.nextDouble() * 0.6,
                drift: (_rng.nextDouble() - 0.5) * 0.4,
                rot: _rng.nextDouble() * pi * 2,
                rotV: (_rng.nextDouble() - 0.5) * 14,
              ));
    });
    ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty || _ctrl == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfPainter(_particles, _ctrl!.value),
        ),
      ),
    );
  }
}

class _Conf {
  final double x, size, delay, speed, drift, rot, rotV;
  final Color color;
  const _Conf(
      {required this.x,
      required this.color,
      required this.size,
      required this.delay,
      required this.speed,
      required this.drift,
      required this.rot,
      required this.rotV});
}

class _ConfPainter extends CustomPainter {
  final List<_Conf> p;
  final double t;
  _ConfPainter(this.p, this.t);
  @override
  void paint(Canvas c, Size sz) {
    for (final conf in p) {
      final prog = ((t - conf.delay) / conf.speed).clamp(0.0, 1.0);
      if (prog <= 0) continue;
      final y = prog * sz.height * 1.15 - 20;
      final x = conf.x * sz.width + conf.drift * sz.width * prog;
      final op = (1.0 - prog * 0.85).clamp(0.0, 1.0);
      final ang = conf.rot + conf.rotV * prog;
      c.save();
      c.translate(x, y);
      c.rotate(ang);
      c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero, width: conf.size, height: conf.size * 0.5),
            const Radius.circular(2)),
        Paint()..color = conf.color.withOpacity(op),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfPainter o) => o.t != t;
}
