import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../journey_setup/providers/journey_setup_provider.dart';

class JourneyAboutSection extends ConsumerStatefulWidget {
  const JourneyAboutSection({super.key});

  @override
  ConsumerState<JourneyAboutSection> createState() =>
      _JourneyAboutSectionState();
}

class _JourneyAboutSectionState extends ConsumerState<JourneyAboutSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Staggers each child's fade+slide-in based on its index, all driven by
  /// one controller so nothing gets out of sync on rebuild.
  Animation<double> _fadeFor(int index, int total) {
    final start = index / (total + 1);
    final end = start + 0.5;
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0),
          curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slideFor(int index, int total) {
    final fade = _fadeFor(index, total);
    return Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(fade);
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(journeyProfileAboutProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return dataAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text("Couldn't load your profile",
            style: text.bodyMedium?.copyWith(color: scheme.error)),
      ),
      data: (data) {
        final goal = data.goal;
        final profile = data.profile;
        final unit = goal.weightUnit;

        final journeyRows = <(IconData, Color, String, String)>[
          (
            Icons.flag_rounded,
            const Color(0xFF6C5CE7),
            'Goal',
            goal.type.replaceAll('_', ' ')
          ),
          if (goal.startingWeight != null)
            (
              Icons.scale_rounded,
              const Color(0xFF00B894),
              'Starting weight',
              '${goal.startingWeight!.toStringAsFixed(1)} $unit'
            ),
          if (goal.currentWeight != null)
            (
              Icons.monitor_weight_rounded,
              const Color(0xFF0984E3),
              'Current weight',
              '${goal.currentWeight!.toStringAsFixed(1)} $unit'
            ),
          if (goal.targetWeight != null)
            (
              Icons.track_changes_rounded,
              const Color(0xFFE17055),
              'Target weight',
              '${goal.targetWeight!.toStringAsFixed(1)} $unit'
            ),
          if (goal.targetDate != null)
            (
              Icons.event_rounded,
              const Color(0xFFFDCB6E),
              'Target date',
              '${goal.targetDate!.month}/${goal.targetDate!.day}/${goal.targetDate!.year}'
            ),
          if (goal.daysRemaining != null)
            (
              Icons.timer_rounded,
              const Color(0xFFD63031),
              'Days remaining',
              '${goal.daysRemaining}'
            ),
        ];

        final aboutRows = <(IconData, Color, String, String)>[
          if (profile.age != null)
            (
              Icons.cake_rounded,
              const Color(0xFFE84393),
              'Age',
              '${profile.age}'
            ),
          if (profile.gender != null)
            (
              Icons.person_rounded,
              const Color(0xFF00B894),
              'Gender',
              profile.gender!
            ),
          if (profile.height != null)
            (
              Icons.height_rounded,
              const Color(0xFF0984E3),
              'Height',
              profile.heightUnit == 'ft'
                  ? "${(profile.height! / 12).floor()}'${(profile.height! % 12).round()}\""
                  : '${profile.height!.toStringAsFixed(0)} cm'
            ),
          if (profile.activityLevel != null)
            (
              Icons.directions_run_rounded,
              const Color(0xFFE17055),
              'Activity level',
              profile.activityLevel!.replaceAll('_', ' ')
            ),
          if (profile.fitnessLevel != null)
            (
              Icons.fitness_center_rounded,
              const Color(0xFF6C5CE7),
              'Fitness level',
              profile.fitnessLevel!
            ),
          if (profile.dietPreference != null)
            (
              Icons.restaurant_rounded,
              const Color(0xFFFDCB6E),
              'Diet',
              profile.dietPreference!
            ),
          if (profile.foodAllergies.isNotEmpty)
            (
              Icons.warning_amber_rounded,
              const Color(0xFFD63031),
              'Allergies',
              profile.foodAllergies.join(', ')
            ),
        ];

        // guards against re-triggering on every provider rebuild.
        if (_controller.status == AnimationStatus.dismissed) {
          _controller.forward();
        }

        final totalItems = 1 + journeyRows.length + aboutRows.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AnimatedIn(
                fade: _fadeFor(0, totalItems),
                slide: _slideFor(0, totalItems),
                child: _ProgressHero(goal: goal),
              ),
              const SizedBox(height: 16),
              _AnimatedIn(
                fade: _fadeFor(1, totalItems),
                slide: _slideFor(1, totalItems),
                child: _Card(
                  title: 'Your journey',
                  accent: const Color(0xFF6C5CE7),
                  rows: journeyRows,
                  animateRows: (i) => _fadeFor(2 + i, totalItems),
                ),
              ),
              const SizedBox(height: 16),
              _AnimatedIn(
                fade: _fadeFor(2 + journeyRows.length, totalItems),
                slide: _slideFor(2 + journeyRows.length, totalItems),
                child: _Card(
                  title: 'About you',
                  accent: const Color(0xFF00B894),
                  rows: aboutRows,
                  animateRows: (i) =>
                      _fadeFor(3 + journeyRows.length + i, totalItems),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Wraps any child in a fade+slide entrance driven by the given animations.
class _AnimatedIn extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  const _AnimatedIn({
    required this.fade,
    required this.slide,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fade,
      builder: (context, _) => Opacity(
        opacity: fade.value,
        child: Transform.translate(
          offset:
              slide.value.scale(40, 40), // Offset is fractional; scale to px
          child: child,
        ),
      ),
    );
  }
}

/// Hero card: large animated circular progress ring showing goal completion,
/// the kind of centerpiece stat fitness apps lead with.
class _ProgressHero extends StatelessWidget {
  final dynamic
      goal; // JourneyGoal — typed as dynamic to avoid an extra import here

  const _ProgressHero({required this.goal});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final progress = (goal.progressPercentage as double?) ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: CircularProgressIndicator(
                        value: value.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journey progress',
                  style: text.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (goal.type as String).replaceAll('_', ' ').toUpperCase(),
                  style: text.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (goal.daysRemaining != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${goal.daysRemaining} days remaining',
                        style: text.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Color accent;
  final List<(IconData, Color, String, String)> rows;
  final Animation<double> Function(int index) animateRows;

  const _Card({
    required this.title,
    required this.accent,
    required this.rows,
    required this.animateRows,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 18,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < rows.length; i++) ...[
            AnimatedBuilder(
              animation: animateRows(i),
              builder: (context, _) {
                final fade = animateRows(i).value;
                return Opacity(
                  opacity: fade,
                  child: Transform.translate(
                    offset: Offset((1 - fade) * 24, 0),
                    child: _RowItem(
                      icon: rows[i].$1,
                      color: rows[i].$2,
                      label: rows[i].$3,
                      value: rows[i].$4,
                    ),
                  ),
                );
              },
            ),
            if (i != rows.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _RowItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
