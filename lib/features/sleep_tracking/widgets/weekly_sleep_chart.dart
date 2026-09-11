import 'package:flutter/material.dart';
import 'package:habitflow/core/constants/app_topography.dart';
import 'package:habitflow/core/theme/app_theme.dart';

class WeeklySleepChart extends StatelessWidget {
  final List<double> history;
  const WeeklySleepChart({super.key, required this.history});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final maxVal = 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep History', style: AppTypography.h4),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.goalCardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(history.length, (i) {
                final v = history[i];
                final heightFraction = (v / maxVal).clamp(0.05, 1.0);

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (v > 0)
                        Text(
                          '${v.toStringAsFixed(0)}h',
                          style: AppTypography.caption,
                        ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: heightFraction),
                        duration: Duration(milliseconds: 600 + i * 60),
                        curve: Curves.easeOutCubic,
                        builder: (_, t, __) => Container(
                          height: 80 * t,
                          width: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.sleep,
                                AppColors.sleep.withValues(alpha: 0.4),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_dayLabels[i], style: AppTypography.labelSmall),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}