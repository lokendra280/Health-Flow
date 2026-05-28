import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/presentation/screens/challenges_screen.dart';
import 'package:habitflow/presentation/screens/home_tab.dart';
import 'package:habitflow/presentation/screens/reminders_screen.dart';
import 'package:habitflow/presentation/widgets/bottom_navigation.dart';
import 'package:habitflow/presentation/widgets/habit_sheet.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';
import 'profile_screen.dart';

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
      builder: (_) => HabitSheet(
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
              HomeTab(
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
              RemindersScreen(
                habits: (ref.watch(habitListProvider).value ?? [])
                    .map((h) => (
                          id: h.id,
                          name: h.name,
                          icon: h.icon,
                        ))
                    .toList(),
                // habits: ref.watch(habitListProvider).value ?? const [],
              ),
              ChallengesScreen(
                habits: ref.watch(habitListProvider).value ?? const [],
              ),
              const ProfileScreen(),
            ],
          ),
          bottomNavigationBar: BottomNav(
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

// ─── Add / Edit Habit Sheet ───────────────────────────────────────────────────

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
