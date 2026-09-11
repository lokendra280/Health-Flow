import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/constants/app_topography.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/core/widgets/animated_common.dart';
import 'package:habitflow/features/sleep_tracking/widgets/weekly_sleep_chart.dart';
import 'package:intl/intl.dart';
import '../../data/models/tracking_models.dart';
import 'providers/sleep_provider.dart';

class SleepTrackingScreen extends ConsumerStatefulWidget {
  const SleepTrackingScreen({super.key});

  @override
  ConsumerState<SleepTrackingScreen> createState() => _SleepTrackingScreenState();
}

class _SleepTrackingScreenState extends ConsumerState<SleepTrackingScreen>
    with SingleTickerProviderStateMixin {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  String _quality = 'good';

  late final AnimationController _entryController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    final sleep = ref.read(sleepControllerProvider);
    if (sleep != null) {
      if (sleep.bedtime != null) {
        _bedtime = _parseTime(sleep.bedtime!);
      }
      if (sleep.wakeTime != null) {
        _wakeTime = _parseTime(sleep.wakeTime!);
      }
      _quality = sleep.quality ?? 'good';
    }

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

  TimeOfDay _parseTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2) {
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
      }
      final normalized =
      time.replaceAll('\u202F', ' ').replaceAll('\u00A0', ' ');
      return TimeOfDay.fromDateTime(DateFormat.jm().parse(normalized));
    } catch (e) {
      debugPrint('Sleep tracking parse error: $e');
      return const TimeOfDay(hour: 22, minute: 30);
    }
  }

  String _stableFormat(TimeOfDay time) => '${time.hour}:${time.minute}';

  double _calculateDuration() {
    final now = DateTime.now();
    final bed = DateTime(now.year, now.month, now.day, _bedtime.hour, _bedtime.minute);
    var wake = DateTime(now.year, now.month, now.day, _wakeTime.hour, _wakeTime.minute);

    if (wake.isBefore(bed)) {
      wake = wake.add(const Duration(days: 1));
    }

    return wake.difference(bed).inMinutes / 60.0;
  }

  @override
  Widget build(BuildContext context) {
    final duration = _calculateDuration();
    final goal = ref.watch(sleepGoalProvider);
    final progress = (duration / goal).clamp(0.0, 1.0);
    final history = ref.watch(sleepHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Placeholder — swap for your real AppTopography API once shared.
          Positioned.fill(
            child: CustomPaint(
              painter: _TopographyBackground(color: AppColors.sleep.withValues(alpha: 0.04)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          const SizedBox(height: 20),
                          Center(
                            child: _SleepVisual(
                              progress: progress,
                              duration: duration,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _TimeSelectionCard(
                            bedtime: _bedtime,
                            wakeTime: _wakeTime,
                            onBedtimeTap: () async {
                              final t = await showTimePicker(context: context, initialTime: _bedtime);
                              if (t != null) setState(() => _bedtime = t);
                            },
                            onWakeTimeTap: () async {
                              final t = await showTimePicker(context: context, initialTime: _wakeTime);
                              if (t != null) setState(() => _wakeTime = t);
                            },
                          ),
                          const SizedBox(height: 24),
                          _QualitySelector(
                            selected: _quality,
                            onChanged: (q) => setState(() => _quality = q),
                          ),
                          const SizedBox(height: 24),
                          WeeklySleepChart(history: history),
                          const SizedBox(height: 40),
                          _SaveButton(
                            onTap: () {
                              ref.read(sleepControllerProvider.notifier).logSleep(
                                SleepEntry(
                                  hours: duration,
                                  quality: _quality,
                                  bedtime: _stableFormat(_bedtime),
                                  wakeTime: _stableFormat(_wakeTime),
                                ),
                              );
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              'Sleep Tracker',
              textAlign: TextAlign.center,
              style: AppTypography.h2,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _SleepVisual extends StatelessWidget {
  final double progress;
  final double duration;

  const _SleepVisual({required this.progress, required this.duration});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => CustomPaint(
              size: const Size(240, 240),
              painter: _SleepPainter(progress: value),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.nights_stay_rounded, color: AppColors.sleep, size: 32),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: duration),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Text(
                  '${value.toStringAsFixed(1)}h',
                  style: AppTypography.displayMedium,
                ),
              ),
              Text(
                'Sleep Duration',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepPainter extends CustomPainter {
  final double progress;
  _SleepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 16.0;

    final bgPaint = Paint()
      ..color = AppColors.sleepBg
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.sleep, AppColors.sleep.withValues(alpha: 0.6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final angle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -3.14159 / 2,
      angle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SleepPainter oldDelegate) => oldDelegate.progress != progress;
}

class _TimeSelectionCard extends StatelessWidget {
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;
  final VoidCallback onBedtimeTap;
  final VoidCallback onWakeTimeTap;

  const _TimeSelectionCard({
    required this.bedtime,
    required this.wakeTime,
    required this.onBedtimeTap,
    required this.onWakeTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.goalCardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TimeTile(
            label: 'Bedtime',
            time: bedtime,
            icon: Icons.bedtime_outlined,
            onTap: onBedtimeTap,
          ),
          Container(height: 40, width: 1, color: AppColors.chartGridline),
          _TimeTile(
            label: 'Wake Up',
            time: wakeTime,
            icon: Icons.wb_sunny_outlined,
            onTap: onWakeTimeTap,
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeTile({required this.label, required this.time, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(label, style: AppTypography.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                time.format(context),
                key: ValueKey(time.format(context)),
                style: AppTypography.h3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QualitySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _QualitySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final qualities = {
      'poor': '😴',
      'fair': '😐',
      'good': '😊',
      'excellent': '🌟',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sleep Quality', style: AppTypography.h4),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: qualities.entries.map((e) {
            final isSelected = selected == e.key;
            return GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.sleep : AppColors.sleepBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.sleep : Colors.transparent,
                  ),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: AppColors.sleep.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : [],
                ),
                child: Column(
                  children: [
                    AnimatedScale(
                      scale: isSelected ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(e.value, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      e.key[0].toUpperCase() + e.key.substring(1),
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SaveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [AppColors.sleep, AppColors.sleep.withValues(alpha: 0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sleep.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Save Sleep Data',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}