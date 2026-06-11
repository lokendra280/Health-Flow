import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/screens/add_habit_screen.dart';
import 'package:habitflow/presentation/screens/add_habits_sheet.dart';
import 'package:habitflow/presentation/screens/challenges_screen.dart';
import 'package:habitflow/presentation/screens/home_tab.dart';
import 'package:habitflow/presentation/screens/profile_screen.dart';
import 'package:habitflow/presentation/screens/reminders_screen.dart';
import 'package:habitflow/presentation/screens/stastics_page.dart';
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
                  name: name,
                  icon: icon,
                  targetPerDay: target,
                  colorIndex: ci,
                  reminderTime: '',
                  reminderEnabled: false,
                  frequency: '');
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
          const StatsTab(),
          RemindersScreen(
            habits: (ref.watch(habitListProvider).value ?? [])
                .map((h) => (id: h.id, name: h.name, icon: h.icon))
                .toList(),
          ),
          ChallengesScreen(
              habits: ref.watch(habitListProvider).value ?? const []),
          // const ProfileScreen(),
        ]),
        // ── FAB + Bottom Nav ───────────────────────────────────
        bottomNavigationBar: BottomNav(
          index: _navIdx,
          user: user,
          onTap: (i) => setState(() => _navIdx = i),
          onFabTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddHabitPage(),
              ),
            );
          },
        ),
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
