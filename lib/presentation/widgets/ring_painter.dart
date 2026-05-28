import 'dart:math';

import 'package:flutter/material.dart';

class RingPainter extends CustomPainter {
  final double progress;
  RingPainter(this.progress);
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
  bool shouldRepaint(RingPainter o) => o.progress != progress;
}
