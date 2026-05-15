import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ANIMATED PROGRESS CARD
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedProgressCard extends StatefulWidget {
  final int  done;
  final int  total;
  final int  streak;
  final int  longestStreak;

  const AnimatedProgressCard({
    super.key,
    required this.done,
    required this.total,
    required this.streak,
    required this.longestStreak,
  });

  @override
  State<AnimatedProgressCard> createState() => _AnimatedProgressCardState();
}

class _AnimatedProgressCardState extends State<AnimatedProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _ringProgress;
  late Animation<double>   _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _ringProgress = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _fadeIn       = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressCard old) {
    super.didUpdateWidget(old);
    if (old.done != widget.done || old.total != widget.total) {
      _ctrl.forward(from: 0.4);
    }
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  double get _pct =>
      widget.total == 0 ? 0 : (widget.done / widget.total).clamp(0.0, 1.0);

  static const _msgs = [
    'Start checking in your habits!',
    'Keep going — you\'ve got this! 💪',
    'Great momentum today!',
    'Almost there — don\'t stop!',
    'Perfect day! You crushed it! 🎉',
  ];

  @override
  Widget build(BuildContext context) {
    final msgIdx = widget.total == 0
        ? 0
        : (_pct * 4).floor().clamp(0, 4);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) => FadeTransition(
        opacity: _fadeIn,
        child: Container(
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
                blurRadius: 28, offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Decorative blobs
              Positioned(top: -28, right: -28,
                child: Container(width: 120, height: 120,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0x0AFFFFFF)),
                ),
              ),
              Positioned(bottom: -24, right: 50,
                child: Container(width: 90, height: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: Color(0x07FFFFFF)),
                ),
              ),

              Row(
                children: [
                  // ── Ring + count ──────────────────────────
                  SizedBox(
                    width: 100, height: 100,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _ringProgress.value * _pct,
                        trackColor: Colors.white.withOpacity(0.15),
                        fillColor: Colors.white,
                        strokeWidth: 7,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${widget.done}',
                              style: GoogleFonts.syne(
                                fontSize: 30, fontWeight: FontWeight.w800,
                                color: Colors.white, height: 1,
                              ),
                            ),
                            Text('of ${widget.total}',
                              style: GoogleFonts.dmSans(
                                fontSize: 12, color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Gap(20),

                  // ── Stats column ──────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Today's Progress",
                          style: GoogleFonts.dmSans(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: Colors.white60, letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(6),
                        // Animated pct text
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _pct),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => Text(
                            '${(v * 100).round()}%',
                            style: GoogleFonts.syne(
                              fontSize: 36, fontWeight: FontWeight.w800,
                              color: Colors.white, height: 1,
                            ),
                          ),
                        ),
                        const Gap(10),
                        // Streak chips
                        Row(
                          children: [
                            _MiniChip(
                              icon: '🔥',
                              label: '${widget.streak}d streak',
                            ),
                            const Gap(6),
                            if (widget.longestStreak > 0)
                              _MiniChip(
                                icon: '🏆',
                                label: 'Best ${widget.longestStreak}d',
                              ),
                          ],
                        ),
                        const Gap(10),
                        Text(_msgs[msgIdx],
                          style: GoogleFonts.dmSans(
                            fontSize: 12, color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double progress, strokeWidth;
  final Color  trackColor, fillColor;
  _RingPainter({
    required this.progress, required this.trackColor,
    required this.fillColor, required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (min(size.width, size.height) - strokeWidth) / 2;

    // Track
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Fill arc
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override bool shouldRepaint(_RingPainter o) =>
      o.progress != progress;
}

// ─── Mini chip ────────────────────────────────────────────────────────────────
class _MiniChip extends StatelessWidget {
  final String icon, label;
  const _MiniChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white.withOpacity(0.18)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const Gap(4),
        Text(label,
          style: GoogleFonts.dmSans(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
