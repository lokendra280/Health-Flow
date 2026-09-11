import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/features/dashboard/providers/dashboard_providers.dart';

class AiInsightCard extends ConsumerStatefulWidget {
  final VoidCallback? onTap;
  const AiInsightCard({super.key, this.onTap});

  @override
  ConsumerState<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends ConsumerState<AiInsightCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insightState = ref.watch(aiInsightProvider);
    final textTheme = Theme.of(context).textTheme;
    final isIdle = insightState.value == 'Tap to get your personalized AI insight for today! ✨';

    return Material(
      color: AppColors.insightBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (isIdle) {
            ref.read(aiInsightProvider.notifier).refresh();
          } else if (widget.onTap != null) {
            widget.onTap!();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: insightState.isLoading
                    ? Tween(begin: 0.4, end: 1.0).animate(_pulseController)
                    : const AlwaysStoppedAnimation(1.0),
                child: Icon(Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('AI Coach Suggestion', style: textTheme.titleMedium),
                        const SizedBox(width: 8),
                        if (!insightState.isLoading && !isIdle)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Live',
                                style: textTheme.labelMedium?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: insightState.when(
                        loading: () => const _ShimmerLines(key: ValueKey('l')),
                        error: (_, __) => Text(
                          'AI insight unavailable — tap to retry',
                          key: const ValueKey('e'),
                          style: textTheme.bodyMedium,
                        ),
                        data: (text) => Text(
                          text,
                          key: const ValueKey('d'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(isIdle ? 'Tap to generate' : 'View full review',
                            style: textTheme.labelMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(width: 4),
                        Icon(isIdle ? Icons.touch_app : Icons.arrow_forward,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerLines extends StatelessWidget {
  const _ShimmerLines({super.key});
  @override
  Widget build(BuildContext context) {
    Widget bar(double width) => Container(
          margin: const EdgeInsets.only(bottom: 6),
          height: 10,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(220), bar(180), bar(120)],
    );
  }
}
