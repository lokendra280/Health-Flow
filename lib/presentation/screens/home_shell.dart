import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/screens/challenges_screen.dart';
import 'package:habitflow/presentation/screens/home_tab.dart';
import 'package:habitflow/presentation/screens/profile_screen.dart';
import 'package:habitflow/presentation/screens/reminders_screen.dart';
import 'package:habitflow/presentation/widgets/bottom_navigation.dart';
import 'package:habitflow/presentation/widgets/habit_sheet.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with TickerProviderStateMixin {
  int _navIdx = 0;
  String? _justDone;
  final _confettiKey = GlobalKey<_ConfettiLayerState>();

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
    ref.read(syncStateProvider.notifier).pushPending();
  }

  void _showHabitSheet({Habit? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitSheet(
        editing: editing,
        habitCount: (ref.read(habitListProvider).value ?? []).length,
        onSave: (name, icon, target, ci) async {
          editing != null
              ? await ref.read(habitListProvider.notifier).updateHabit(editing
                  .copyWith(name: name, icon: icon, targetPerDay: target))
              : await ref.read(habitListProvider.notifier).addHabit(
                  name: name, icon: icon, targetPerDay: target, colorIndex: ci);
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

    return Stack(children: [
      Scaffold(
        backgroundColor: context.bgColor,
        body: IndexedStack(index: _navIdx, children: [
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
                .map((h) => (id: h.id, name: h.name, icon: h.icon))
                .toList(),
          ),
          ChallengesScreen(
              habits: ref.watch(habitListProvider).value ?? const []),
          const ProfileScreen(),
        ]),
        // ── FAB + Bottom Nav ───────────────────────────────────
        bottomNavigationBar: BottomNav(
            index: _navIdx,
            user: user,
            onTap: (i) => setState(() => _navIdx = i)),
      ),
      _ConfettiLayer(key: _confettiKey),
    ]);
  }
}

// ── FAB ───────────────────────────────────────────────────────────
// class _AddFab extends StatelessWidget {
//   final VoidCallback onTap;
//   const _AddFab({required this.onTap});
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//         onTap: onTap,
//         child: Container(
//           width: 56,
//           height: 56,
//           decoration: const BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: LinearGradient(
//                   colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight)),
//           child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
//         ),
//       );
// }

// ── Bottom bar ────────────────────────────────────────────────────
// class _BottomBar extends StatelessWidget {
//   final int index;
//   final dynamic user;
//   final ValueChanged<int> onTap;
//   const _BottomBar(
//       {required this.index, required this.user, required this.onTap});

//   static const _items = [
//     (Icons.home_outlined, Icons.home_rounded, 'Home'),
//     (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
//     (null, null, ''), // FAB slot
//     (Icons.check_circle_outline, Icons.check_circle_rounded, 'Habits'),
//     (Icons.person_outline, Icons.person_rounded, 'Profile'),
//   ];

//   @override
//   Widget build(BuildContext context) => Container(
//         height: 70,
//         decoration: BoxDecoration(
//           color: context.surfaceColor,
//           border: Border(top: BorderSide(color: context.borderColor, width: 1)),
//         ),
//         child: Row(
//             children: List.generate(_items.length, (i) {
//           if (i == 2) return const SizedBox(width: 70); // FAB space
//           final item = _items[i];
//           final sel = index == (i > 2 ? i - 1 : i);
//           // remap: 0→0 1→1 3→2 4→3 (skip FAB slot)
//           final tabIdx = i > 2 ? i - 1 : i;
//           return Expanded(
//               child: GestureDetector(
//             onTap: () => onTap(tabIdx),
//             behavior: HitTestBehavior.opaque,
//             child:
//                 Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//               Icon(sel ? item.$2! : item.$1!,
//                   size: 22,
//                   color: sel ? const Color(0xFF52B788) : context.textTertiary),
//               const Gap(3),
//               Text(item.$3,
//                   style: TextStyle(
//                       fontSize: 10,
//                       fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
//                       color: sel
//                           ? const Color(0xFF52B788)
//                           : context.textTertiary)),
//             ]),
//           ));
//         })),
//       );
// }

// ── Stats Tab ─────────────────────────────────────────────────────
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
      final done = habits
          .where((h) =>
              repo.getTodayCheckins(habitId: h.id).length >= h.targetPerDay)
          .length;
      return (day: d, done: done, total: habits.length);
    });

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Gap(8),
          Text('Statistics', style: context.syne(26, FontWeight.w800)),
          const Gap(4),
          Text('Your habit performance at a glance.',
              style: context.dmSans(13, FontWeight.w400,
                  color: context.textSecondary)),
          const Gap(20),

          // ── Date range chip ──────────────────────────────────
          Row(children: [
            const Icon(Icons.chevron_left_rounded, size: 20),
            const Gap(6),
            Text(_weekRange(today), style: context.dmSans(13, FontWeight.w600)),
            const Gap(6),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ]),
          const Gap(16),

          // ── Overall progress card ────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Overall Progress',
                  style: context.dmSans(13, FontWeight.w500,
                      color: Colors.white70)),
              const Gap(6),
              Text('${p.total > 0 ? (p.done / p.total * 100).toInt() : 0}%',
                  style: context
                      .syne(40, FontWeight.w800)
                      .copyWith(color: Colors.white)),
              const Gap(10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                    value: p.total > 0 ? p.done / p.total : 0,
                    minHeight: 6,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white)),
              ),
              const Gap(8),
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                      .map((d) => Text(d,
                          style: context.dmSans(10, FontWeight.w400,
                              color: Colors.white60)))
                      .toList()),
            ]),
          ),
          const Gap(16),

          // ── Stat tiles ───────────────────────────────────────
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: [
              _StatTile('Completed', '${p.done}', Icons.check_circle_rounded,
                  const Color(0xFF52B788)),
              _StatTile('Best Streak', '${longest}d',
                  Icons.local_fire_department_rounded, const Color(0xFFFCD34D)),
              _StatTile('Active', '${habits.length}', Icons.grid_view_rounded,
                  const Color(0xFF93C5FD)),
            ],
          ),
          const Gap(24),

          // ── Habit Completion donut ───────────────────────────
          Text('Habit Completion', style: context.syne(17, FontWeight.w700)),
          const Gap(14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor, width: 1.5)),
            child: Row(children: [
              // Mini donut
              SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                      painter: _DonutPainter(
                          done: p.done.toDouble(), total: p.total.toDouble()))),
              const Gap(20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Legend(
                    const Color(0xFF52B788),
                    'Completed',
                    p.total > 0
                        ? '${(p.done / p.total * 100).toInt()}%'
                        : '0%'),
                const Gap(8),
                _Legend(
                    const Color(0xFFFCA5A5),
                    'Missed',
                    p.total > 0
                        ? '${((p.total - p.done) / p.total * 100).toInt()}%'
                        : '0%'),
                const Gap(8),
                _Legend(const Color(0xFFFCD34D), 'Pending', '7%'),
              ]),
            ]),
          ),
          const Gap(24),

          // ── Bar chart ────────────────────────────────────────
          Text('Last 7 Days', style: context.syne(17, FontWeight.w700)),
          const Gap(14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor, width: 1.5)),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: last7.map((e) {
                  final pct = e.total == 0 ? 0.0 : e.done / e.total;
                  final barH = (pct * 80).clamp(4.0, 80.0);
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
                                          ? const Color(0xFF52B788)
                                          : const Color(0xFF52B788)
                                              .withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                        const Gap(6),
                        Text(days[e.day.weekday % 7],
                            style: context.dmSans(11, FontWeight.w400,
                                color: isToday
                                    ? const Color(0xFF52B788)
                                    : context.textTertiary)),
                      ]);
                }).toList()),
          ),
          const Gap(40),
        ]),
      ),
    );
  }

  String _weekRange(DateTime now) {
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[start.month - 1]} ${start.day} - ${months[end.month - 1]} ${end.day}';
  }
}

// ── Stat tile ─────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
            color: ctx.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ctx.borderColor, width: 1.5)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const Gap(4),
              Text(value,
                  style: ctx.syne(18, FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(label,
                  style:
                      ctx.dmSans(10, FontWeight.w400, color: ctx.textTertiary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ]),
      );
}

// ── Legend row ────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  final Color color;
  final String label, value;
  const _Legend(this.color, this.label, this.value);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(8),
        Text('$label  ',
            style: context.dmSans(12, FontWeight.w400,
                color: context.textSecondary)),
        Text(value, style: context.dmSans(12, FontWeight.w700)),
      ]);
}

// ── Donut painter ─────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double done, total;
  const _DonutPainter({required this.done, required this.total});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Background
    canvas.drawCircle(
        Offset(cx, cy), r, paint..color = const Color(0xFFE8F5E9));

    if (total > 0) {
      final sweep = (done / total) * 2 * pi;
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
          -pi / 2, sweep, false, paint..color = const Color(0xFF52B788));
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.done != done || o.total != total;
}

// ── Confetti (unchanged) ──────────────────────────────────────────
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
            child:
                CustomPaint(painter: _ConfPainter(_particles, _ctrl!.value))));
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
      c.save();
      c.translate(x, y);
      c.rotate(conf.rot + conf.rotV * prog);
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero,
                  width: conf.size,
                  height: conf.size * 0.5),
              const Radius.circular(2)),
          Paint()
            ..color = conf.color.withOpacity((1.0 - prog * 0.85).clamp(0, 1)));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfPainter o) => o.t != t;
}
