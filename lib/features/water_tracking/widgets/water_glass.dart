import 'package:flutter/material.dart';
import 'package:habitflow/core/theme/app_theme.dart';

class WaterGlass extends StatelessWidget {
  final double progress;
  final double width;
  final double height;

  const WaterGlass({
    super.key,
    required this.progress,
    this.width = 120,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _GlassPainter(progress: progress.clamp(0.0, 1.0)),
      ),
    );
  }
}

class _GlassPainter extends CustomPainter {
  final double progress;

  _GlassPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = AppColors.water.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.9, 0)
      ..lineTo(size.width * 0.8, size.height)
      ..lineTo(size.width * 0.2, size.height)
      ..close();

    canvas.drawPath(path, outlinePaint);

    if (progress > 0) {
      final fillHeight = size.height * progress;
      final topY = size.height - fillHeight;
      final lerpTopX = 0.2 - (0.2 - 0.1) * progress;
      final lerpTopWidth = 0.8 + (0.9 - 0.8) * progress;

      final fillPath = Path()
        ..moveTo(size.width * lerpTopX, topY)
        ..lineTo(size.width * lerpTopWidth, topY)
        ..lineTo(size.width * 0.8, size.height)
        ..lineTo(size.width * 0.2, size.height)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.water.withValues(alpha: 0.75),
            AppColors.water,
          ],
        ).createShader(Rect.fromLTWH(0, topY, size.width, fillHeight));

      canvas.drawPath(fillPath, fillPaint);

      // Surface shimmer line at the water top.
      final shimmerPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(size.width * lerpTopX, topY),
        Offset(size.width * lerpTopWidth, topY),
        shimmerPaint,
      );
    }

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.1),
      Offset(size.width * 0.22, size.height * 0.8),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassPainter oldDelegate) =>
      oldDelegate.progress != progress;
}