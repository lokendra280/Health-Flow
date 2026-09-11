import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/constants/app_string.dart';
import 'package:habitflow/core/constants/app_topography.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/features/water_tracking/providers/water_tracking_provider.dart';
import 'package:habitflow/features/water_tracking/widgets/water_droplets_grid.dart';
import 'package:habitflow/features/water_tracking/widgets/water_glass.dart';
import 'package:habitflow/features/water_tracking/widgets/water_goal_card.dart';

class WaterTrackingScreen extends ConsumerStatefulWidget {
  const WaterTrackingScreen({super.key, this.userName = ''});

  /// TODO: wire to the real user-profile provider instead of a param.
  final String userName;

  @override
  ConsumerState<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends ConsumerState<WaterTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context, [WidgetRef? _]) {
    return _build(context, ref);
  }

  Widget _build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(waterProgressProvider);
    final targetMl = ref.watch(waterTargetProvider);
    final glassGoal = ref.watch(waterGlassGoalProvider);
    final consumedMl = ref.watch(waterControllerProvider);

    final consumedGlasses = (progress * glassGoal).round();
    final remainingGlasses = (glassGoal - consumedGlasses).clamp(0, glassGoal);
    final remainingMl = (targetMl - consumedMl).clamp(0, targetMl);
    final goalHit = remainingGlasses <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Placeholder — swap for the real AppTopography API once shared.
          Positioned.fill(
            child: CustomPaint(
              painter: _TopographyBackground(color: AppColors.water.withValues(alpha: 0.06)),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    _TopBar(
                      onClose: () => Navigator.of(context).maybePop(),
                      onConfirm: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: _PremiumGlassCard(
                        progress: progress,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => WaterGlass(
                            progress: value,
                            width: 140,
                            height: 180,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(AppString.waterToday, style: AppTypography.body),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: consumedMl),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Text(
                        '$value / $targetMl ml',
                        style: AppTypography.displayLarge,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$consumedGlasses ${AppString.glassesOf} $glassGoal ${AppString.glassesSuffix}',
                      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _StatusBanner(
                        key: ValueKey(goalHit),
                        goalHit: goalHit,
                        userName: widget.userName,
                        consumedMl: consumedMl,
                        targetMl: targetMl,
                        remainingMl: remainingMl,
                      ),
                    ),
                    const SizedBox(height: 24),
                    WaterDropletsGrid(
                      totalGlasses: glassGoal,
                      consumedGlasses: consumedGlasses,
                      onAddGlass: () => ref
                          .read(waterControllerProvider.notifier)
                          .quickAdd(kMlPerGlass),
                    ),
                    const SizedBox(height: 32),
                    WaterGoalCard(dailyGoalGlasses: glassGoal),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    super.key,
    required this.goalHit,
    required this.userName,
    required this.consumedMl,
    required this.targetMl,
    required this.remainingMl,
  });

  final bool goalHit;
  final String userName;
  final int consumedMl;
  final int targetMl;
  final int remainingMl;

  @override
  Widget build(BuildContext context) {
    final name = userName.isNotEmpty ? '$userName, y' : 'Y';
    final message = goalHit
        ? '${name}ou hit your water goal for today. Nice work!'
        : '${name}ou\'ve had $consumedMl of $targetMl ml today. '
        '${AppString.keepGoing} — $remainingMl ${AppString.mlLeftSuffix}.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: goalHit ? AppColors.stepsBg : AppColors.waterBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            goalHit ? Icons.emoji_events_rounded : Icons.water_drop_rounded,
            color: goalHit ? AppColors.steps : AppColors.water,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Soft glowing halo behind the glass, intensity tied to progress —
/// this is what makes the hero feel "premium" instead of flat.
class _PremiumGlassCard extends StatelessWidget {
  const _PremiumGlassCard({required this.progress, required this.child});

  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.water.withValues(alpha: 0.15 + value * 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.water.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

/// TEMP placeholder until the real AppTopography.dart is shared.
class _TopographyBackground extends CustomPainter {
  final Color color;
  _TopographyBackground({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (double i = -size.height; i < size.width; i += 40) {
      final path = Path()..moveTo(i, 0);
      path.quadraticBezierTo(
        i + size.height / 2, size.height / 2,
        i + size.height, size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TopographyBackground oldDelegate) =>
      oldDelegate.color != color;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onConfirm});

  final VoidCallback onClose;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.close, onTap: onClose, dashed: true),
        Expanded(
          child: Text(
            AppString.waterTracking,
            textAlign: TextAlign.center,
            style: AppTypography.h3,
          ),
        ),
        _CircleIconButton(icon: Icons.check, onTap: onConfirm, dashed: false),
      ],
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.dashed,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dashed;

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: widget.dashed ? Colors.transparent : AppColors.surfaceMuted,
          shape: CircleBorder(
            side: widget.dashed
                ? BorderSide(color: AppColors.textMuted.withValues(alpha: 0.4))
                : BorderSide.none,
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(widget.icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}