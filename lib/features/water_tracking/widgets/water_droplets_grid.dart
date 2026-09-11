import 'package:flutter/material.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/features/water_tracking/widgets/water_glass.dart';

/// The glass grid from the reference design: one filled glass icon per
/// glass already drunk, and an outline "+" glass for each remaining
/// glass — tapping an empty glass logs one. Filled glasses pop in with
/// a spring-scale animation when they cross from empty -> filled.
class WaterDropletsGrid extends StatelessWidget {
  const WaterDropletsGrid({
    super.key,
    required this.totalGlasses,
    required this.consumedGlasses,
    required this.onAddGlass,
    this.columns = 7,
  });

  final int totalGlasses;
  final int consumedGlasses;
  final VoidCallback onAddGlass;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(totalGlasses, (i) {
        final filled = i < consumedGlasses;
        return _WaterGlass(
          key: ValueKey('glass_$i'),
          filled: filled,
          onTap: filled ? null : onAddGlass,
        );
      }),
    );
  }
}

class _WaterGlass extends StatelessWidget {
  const _WaterGlass({super.key, required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: filled ? 0 : 1, end: filled ? 1 : 0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                builder: (context, t, child) => Transform.scale(
                  scale: filled ? 0.9 + (t * 0.1) : 1,
                  child: WaterGlass(
                    progress: filled ? 1.0 : 0.0,
                    width: 30,
                    height: 40,
                  ),
                ),
              ),
              if (!filled)
                Positioned(
                  bottom: 4,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.water,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.water.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 10, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}