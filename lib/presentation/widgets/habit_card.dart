import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final int done;
  final Streak streak;
  final bool justCompleted;
  final VoidCallback onCheckin;
  final VoidCallback onEdit;
  const HabitCard({
    required this.habit,
    required this.done,
    required this.streak,
    required this.justCompleted,
    required this.onCheckin,
    required this.onEdit,
  });
  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
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
