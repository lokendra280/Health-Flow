import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ANIMATED HABIT CARD  (Phase 2 — full animation suite)
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedHabitCard extends StatefulWidget {
  final Habit        habit;
  final int          todayCount;
  final Streak       streak;
  final VoidCallback onCheckin;   // caller fires after tap
  final VoidCallback onEdit;
  final bool         justCompleted;

  const AnimatedHabitCard({
    super.key,
    required this.habit,
    required this.todayCount,
    required this.streak,
    required this.onCheckin,
    required this.onEdit,
    this.justCompleted = false,
  });

  @override
  State<AnimatedHabitCard> createState() => _AnimatedHabitCardState();
}

class _AnimatedHabitCardState extends State<AnimatedHabitCard>
    with TickerProviderStateMixin {
  // ── Controllers ───────────────────────────────────────────────────────────
  late final AnimationController _entryCtrl;
  late final AnimationController _bounceCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _celebCtrl;

  // ── Animations ────────────────────────────────────────────────────────────
  late final Animation<double>  _entrySlide;
  late final Animation<double>  _entryFade;
  late final Animation<double>  _bounceScale;
  late final Animation<double>  _shimmerPos;
  late final Animation<double>  _pulse;
  late final Animation<double>  _celebScale;
  late final Animation<double>  _celebFade;

  // ── Particle system ───────────────────────────────────────────────────────
  final _particles = <_MiniParticle>[];
  final _rng       = Random();
  bool  _pressing  = false;

  @override
  void initState() {
    super.initState();

    // Entry slide-up + fade
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _entrySlide = Tween(begin: 30.0, end: 0.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryFade  = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));

    // Bounce for checkin button
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _bounceScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.32), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.32, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.00), weight: 35),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOut));

    // Shimmer sweep
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _shimmerPos = Tween(begin: -1.5, end: 2.5).animate(
        CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    // Subtle icon pulse (idle)
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Celebration overlay
    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _celebScale = Tween(begin: 0.5, end: 1.15).animate(
        CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut));
    _celebFade  = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _celebCtrl,
            curve: const Interval(0, 0.4, curve: Curves.easeOut)));

    _entryCtrl.forward();

    if (widget.justCompleted) _playCelebration();
  }

  @override
  void didUpdateWidget(AnimatedHabitCard old) {
    super.didUpdateWidget(old);
    if (widget.justCompleted && !old.justCompleted) _playCelebration();
  }

  void _playCelebration() {
    _shimmerCtrl.forward(from: 0).then((_) => _shimmerCtrl.reset());
    _celebCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _celebCtrl.reverse();
      });
    });
    _spawnParticles();
  }

  void _spawnParticles() {
    const colors = [
      Color(0xFF52B788), Color(0xFFFCD34D), Color(0xFFFCA5A5),
      Color(0xFF93C5FD), Color(0xFFC4B5FD),
    ];
    setState(() {
      _particles.addAll(List.generate(12, (_) => _MiniParticle(
        x:     0.3 + _rng.nextDouble() * 0.4,
        color: colors[_rng.nextInt(colors.length)],
        size:  4 + _rng.nextDouble() * 5,
        vx:    (_rng.nextDouble() - 0.5) * 120,
        vy:    -60 - _rng.nextDouble() * 80,
        life:  0.8 + _rng.nextDouble() * 0.4,
      )));
    });
    Future.delayed(const Duration(milliseconds: 1200),
        () { if (mounted) setState(() => _particles.clear()); });
  }

  Future<void> _handleTap() async {
    if (widget.todayCount >= widget.habit.targetPerDay) return;
    HapticFeedback.mediumImpact();
    _bounceCtrl.forward(from: 0);
    widget.onCheckin();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _bounceCtrl.dispose();
    _shimmerCtrl.dispose();
    _pulseCtrl.dispose();
    _celebCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done      = widget.todayCount;
    final h         = widget.habit;
    final completed = done >= h.targetPerDay;
    final pct       = (done / h.targetPerDay).clamp(0.0, 1.0);
    final colorBg   = h.color.withOpacity(context.isDark ? 0.18 : 0.12);

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_entryCtrl, _bounceCtrl, _shimmerCtrl, _pulseCtrl, _celebCtrl]),
      builder: (ctx, _) {
        return Transform.translate(
          offset: Offset(0, _entrySlide.value),
          child: Opacity(
            opacity: _entryFade.value,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Main card ──────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: completed
                          ? h.color.withOpacity(0.55)
                          : context.borderColor,
                      width: completed ? 2 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: completed
                            ? h.color.withOpacity(0.15)
                            : Colors.black
                                .withOpacity(context.isDark ? 0.22 : 0.05),
                        blurRadius: completed ? 20 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Shimmer overlay (on completion)
                        if (_shimmerCtrl.isAnimating)
                          Positioned.fill(
                            child: ShaderMask(
                              shaderCallback: (rect) => LinearGradient(
                                begin: Alignment(_shimmerPos.value - 1, 0),
                                end:   Alignment(_shimmerPos.value, 0),
                                colors: [
                                  Colors.white.withOpacity(0),
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0),
                                ],
                              ).createShader(rect),
                              child: Container(color: Colors.white),
                            ),
                          ),

                        // Left accent
                        if (completed)
                          Positioned(
                            left: 0, top: 0, bottom: 0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 4,
                              decoration: BoxDecoration(
                                color: h.color,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),

                        // Card content
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                              completed ? 18 : 14, 14, 14, 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Icon with pulse
                              ScaleTransition(
                                scale: completed ? kAlwaysCompleteAnimation : _pulse,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 54, height: 54,
                                  decoration: BoxDecoration(
                                    color: colorBg,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(h.icon,
                                        style: const TextStyle(fontSize: 26)),
                                  ),
                                ),
                              ),
                              const Gap(14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(h.name,
                                      style: GoogleFonts.syne(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: context.textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Gap(5),
                                    // Badges
                                    Wrap(
                                      spacing: 6, runSpacing: 4,
                                      children: [
                                        if (widget.streak.currentStreak > 0)
                                          _Badge(
                                            '🔥 ${widget.streak.currentStreak}d',
                                            AppColors.amber100, AppColors.amber700,
                                          ),
                                        _Badge(
                                          '$done/${h.targetPerDay}',
                                          context.surface2, context.textTertiary,
                                        ),
                                        if (completed)
                                          _Badge(
                                            '✓ Done',
                                            context.accentSurf, context.accent,
                                          ),
                                      ],
                                    ),
                                    const Gap(10),

                                    // Dot progress with animated fill
                                    Row(
                                      children: List.generate(
                                        h.targetPerDay.clamp(1, 10),
                                        (i) => Padding(
                                          padding: const EdgeInsets.only(right: 5),
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(
                                              begin: 0,
                                              end: i < done ? 1.0 : 0.0,
                                            ),
                                            duration: Duration(
                                                milliseconds: 250 + i * 50),
                                            curve: Curves.easeOut,
                                            builder: (_, v, __) => Container(
                                              width: 8, height: 8,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color.lerp(
                                                    context.surface3,
                                                    h.color, v),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Gap(10),

                              // Checkin + edit
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ScaleTransition(
                                    scale: _bounceScale,
                                    child: GestureDetector(
                                      onTapDown: (_) =>
                                          setState(() => _pressing = true),
                                      onTapUp: (_) {
                                        setState(() => _pressing = false);
                                        _handleTap();
                                      },
                                      onTapCancel: () =>
                                          setState(() => _pressing = false),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 220),
                                        width: 46, height: 46,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: completed
                                              ? h.color
                                              : _pressing
                                                  ? h.color.withOpacity(0.12)
                                                  : Colors.transparent,
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
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ]
                                              : null,
                                        ),
                                        child: Icon(
                                          completed
                                              ? Icons.check_rounded
                                              : Icons.add_rounded,
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
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        color: context.textTertiary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Completion glow overlay
                        if (completed)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      h.color.withOpacity(0.05),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Celebration stamp ─────────────────────────
                if (_celebCtrl.value > 0)
                  Positioned(
                    right: 10, top: -10,
                    child: ScaleTransition(
                      scale: _celebScale,
                      child: FadeTransition(
                        opacity: _celebFade,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: h.color,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: h.color.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text('🎉 Done!',
                            style: GoogleFonts.syne(
                              fontSize: 12, fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Mini particle burst ───────────────────────
                if (_particles.isNotEmpty)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ParticlePainter(_particles, 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color  bg, fg;
  const _Badge(this.label, this.bg, this.fg);
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(99)),
    child: Text(label,
        style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
  );
}

class _MiniParticle {
  double x, y, vx, vy, life, age;
  final Color  color;
  final double size;
  _MiniParticle({
    required this.x, required this.color, required this.size,
    required this.vx, required this.vy, required this.life,
  }) : y = 0.5, age = 0;
}

class _ParticlePainter extends CustomPainter {
  final List<_MiniParticle> particles;
  final double dt;
  _ParticlePainter(this.particles, this.dt);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      p.age += dt * 0.016;
      final t  = (p.age / p.life).clamp(0.0, 1.0);
      final op = (1.0 - t).clamp(0.0, 1.0);
      final x  = p.x * size.width  + p.vx * p.age;
      final y  = p.y * size.height + p.vy * p.age + 60 * p.age * p.age;
      canvas.drawCircle(
        Offset(x, y),
        p.size * (1 - t * 0.5),
        Paint()..color = p.color.withOpacity(op),
      );
    }
  }

  @override bool shouldRepaint(_ParticlePainter o) => true;
}

// Trick: non-animated scale for completed state so pulse stops
final kAlwaysCompleteAnimation = AlwaysStoppedAnimation(1.0);
