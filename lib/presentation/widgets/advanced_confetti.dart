import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  ADVANCED CONFETTI OVERLAY  — physics-based, multi-shape
// ─────────────────────────────────────────────────────────────────────────────
class AdvancedConfetti extends StatefulWidget {
  const AdvancedConfetti({super.key});
  @override
  AdvancedConfettiState createState() => AdvancedConfettiState();
}

class AdvancedConfettiState extends State<AdvancedConfetti>
    with TickerProviderStateMixin {
  AnimationController? _ctrl;
  final _particles = <_Confetto>[];
  final _rng       = Random();

  static const _colors = [
    Color(0xFF52B788), Color(0xFFFCD34D), Color(0xFFFCA5A5),
    Color(0xFF93C5FD), Color(0xFFC4B5FD), Color(0xFFFB923C),
    Color(0xFF34D399), Color(0xFFF472B6), Color(0xFFE879F9),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────
  void launch({int count = 60, bool fullScreen = true}) {
    _ctrl?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: fullScreen ? 2200 : 1600),
    )..addListener(() => setState(() {}))
     ..addStatusListener((s) {
       if (s == AnimationStatus.completed && mounted) {
         setState(() => _particles.clear());
       }
     });
    _ctrl = ctrl;

    setState(() {
      _particles
        ..clear()
        ..addAll(List.generate(count, (_) => _Confetto(
          x:     fullScreen ? _rng.nextDouble() : 0.3 + _rng.nextDouble() * 0.4,
          color: _colors[_rng.nextInt(_colors.length)],
          size:  5 + _rng.nextDouble() * 8,
          delay: _rng.nextDouble() * 0.5,
          speed: 0.5 + _rng.nextDouble() * 0.6,
          drift: (_rng.nextDouble() - 0.5) * 0.4,
          rot:   _rng.nextDouble() * pi * 2,
          rotV:  (_rng.nextDouble() - 0.5) * 14,
          shape: _ConfShape.values[_rng.nextInt(_ConfShape.values.length)],
          wobble:    _rng.nextDouble() * pi * 2,
          wobbleAmp: 0.02 + _rng.nextDouble() * 0.04,
          wobbleFreq: 2 + _rng.nextDouble() * 4,
        )));
    });
    ctrl.forward();
  }

  @override void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (_particles.isEmpty || _ctrl == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(_particles, _ctrl!.value),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATA + PAINTER
// ─────────────────────────────────────────────────────────────────────────────
enum _ConfShape { circle, rect, triangle, star }

class _Confetto {
  final double      x, size, delay, speed, drift, rot, rotV;
  final double      wobble, wobbleAmp, wobbleFreq;
  final Color       color;
  final _ConfShape  shape;

  const _Confetto({
    required this.x, required this.color, required this.size,
    required this.delay, required this.speed, required this.drift,
    required this.rot, required this.rotV, required this.shape,
    required this.wobble, required this.wobbleAmp, required this.wobbleFreq,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetto> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size sz) {
    for (final p in particles) {
      final prog = ((t - p.delay) / p.speed).clamp(0.0, 1.0);
      if (prog <= 0) continue;

      // physics
      final gravity = prog * prog;
      final yPos    = prog * sz.height * 1.15 - 20;
      final wobbleX = sin(p.wobble + prog * p.wobbleFreq * pi * 2) * p.wobbleAmp * sz.width;
      final xPos    = p.x * sz.width + p.drift * sz.width * prog + wobbleX;
      final opacity = (1.0 - prog * 0.8).clamp(0.0, 1.0);
      final angle   = p.rot + p.rotV * prog;

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(xPos, yPos + gravity * 40);
      canvas.rotate(angle);

      switch (p.shape) {
        case _ConfShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
        case _ConfShape.rect:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
              const Radius.circular(2)),
            paint,
          );
        case _ConfShape.triangle:
          final path = Path()
            ..moveTo(0, -p.size / 2)
            ..lineTo(p.size / 2, p.size / 2)
            ..lineTo(-p.size / 2, p.size / 2)
            ..close();
          canvas.drawPath(path, paint);
        case _ConfShape.star:
          canvas.drawPath(_starPath(p.size / 2, 5), paint);
      }
      canvas.restore();
    }
  }

  Path _starPath(double r, int points) {
    final path = Path();
    final inner = r * 0.45;
    for (int i = 0; i < points * 2; i++) {
      final angle  = (i * pi) / points - pi / 2;
      final radius = i.isEven ? r : inner;
      final x      = cos(angle) * radius;
      final y      = sin(angle) * radius;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    return path..close();
  }

  @override bool shouldRepaint(_ConfettiPainter o) => o.t != t;
}
