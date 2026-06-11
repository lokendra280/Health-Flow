import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/presentation/providers/providers.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habits = ref.watch(habitListProvider).value ?? [];
    final longest = ref.watch(longestEverProvider);
    final overall = ref.watch(overallStreakProvider);
    final p = ref.watch(progressProvider);
    final repo = ref.watch(habitRepoProvider);
    final today = DateTime.now();

    final last7 = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      final done = habits
          .where((h) =>
              repo.getTodayCheckins(habitId: h.id).length >= h.targetPerDay)
          .length;
      return (day: d, done: done, total: habits.length);
    });

    final pct = p.total > 0 ? p.done / p.total : 0.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ────────────────────────────────────────────
          Text('Statistics', style: context.syne(26, FontWeight.w600)),
          const Gap(2),
          Text('Your habit performance at a glance.',
              style: context.dmSans(13, FontWeight.w400,
                  color: context.textSecondary)),
          const Gap(20),

          // ── Week selector ─────────────────────────────────────
          Row(children: [
            _CircleBtn(Icons.chevron_left_rounded, () {}),
            const Gap(10),
            Text(_weekRange(today), style: context.dmSans(13, FontWeight.w600)),
            const Gap(10),
            _CircleBtn(Icons.chevron_right_rounded, () {}),
          ]),
          const Gap(20),

          // ── Overall progress card ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.23,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00A86B),
                  Color(0xFF2ECC71),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A86B).withOpacity(.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Overall Progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(pct * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];

                              if (value < 0 || value > 6) {
                                return const SizedBox();
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  days[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          color: Colors.white,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(
                            show: false,
                          ),
                          belowBarData: BarAreaData(
                            show: false,
                          ),
                          spots: const [
                            FlSpot(0, 20),
                            FlSpot(1, 48),
                            FlSpot(2, 38),
                            FlSpot(3, 65),
                            FlSpot(4, 58),
                            FlSpot(5, 88),
                            FlSpot(6, 78),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),

          // ── 3 stat tiles ──────────────────────────────────────
          Row(children: [
            Expanded(
                child: _StatTile(
                    'Completed',
                    '${p.done}',
                    Icons.check_circle_rounded,
                    const Color(0xFF52B788),
                    context)),
            const Gap(10),
            Expanded(
                child: _StatTile(
                    'Best Streak',
                    '${longest}d',
                    Icons.local_fire_department_rounded,
                    const Color(0xFFFCD34D),
                    context)),
            const Gap(10),
            Expanded(
                child: _StatTile('Active', '${habits.length}',
                    Icons.grid_view_rounded, const Color(0xFF93C5FD), context)),
          ]),
          const Gap(24),

          // ── Habit completion ──────────────────────────────────
          Text('Habit Completion', style: context.syne(17, FontWeight.w700)),
          const Gap(14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor, width: 1.5)),
            child: Row(children: [
              SizedBox(
                  width: 90,
                  height: 90,
                  child: CustomPaint(
                      painter: _DonutPainter(
                          done: p.done.toDouble(), total: p.total.toDouble()))),
              const Gap(20),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _Legend(const Color(0xFF52B788), 'Completed',
                    '${(pct * 100).toInt()}%', context),
                const Gap(8),
                _Legend(const Color(0xFFFCA5A5), 'Missed',
                    '${((1 - pct) * 100).toInt()}%', context),
                const Gap(8),
                _Legend(const Color(0xFFFCD34D), 'Pending', '7%', context),
              ]),
            ]),
          ),
          const Gap(24),

          // ── Bar chart ─────────────────────────────────────────
          Text('Last 7 Days', style: context.syne(17, FontWeight.w700)),
          const Gap(14),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.borderColor, width: 1.5)),
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: last7.map((e) {
                  final p = e.total == 0 ? 0.0 : e.done / e.total;
                  final isT = e.day.day == today.day;
                  const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${e.done}',
                            style: context.dmSans(10, FontWeight.w600,
                                color: context.textTertiary)),
                        const Gap(4),
                        TweenAnimationBuilder<double>(
                          tween:
                              Tween(begin: 0, end: (p * 80).clamp(4.0, 80.0)),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (_, h, __) => Container(
                              width: 28,
                              height: h,
                              decoration: BoxDecoration(
                                  color: p == 0
                                      ? context.surface3
                                      : isT
                                          ? const Color(0xFF52B788)
                                          : const Color(0xFF52B788)
                                              .withOpacity(.45),
                                  borderRadius: BorderRadius.circular(8))),
                        ),
                        const Gap(6),
                        Text(days[e.day.weekday % 7],
                            style: context.dmSans(11, FontWeight.w400,
                                color: isT
                                    ? const Color(0xFF52B788)
                                    : context.textTertiary)),
                      ]);
                }).toList()),
          ),
        ]),
      ),
    );
  }

  String _weekRange(DateTime now) {
    final s = now.subtract(Duration(days: now.weekday - 1));
    final e = s.add(const Duration(days: 6));
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${m[s.month - 1]} ${s.day} – ${m[e.month - 1]} ${e.day}';
  }
}

// ── Helpers ───────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext ctx) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: ctx.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(color: ctx.borderColor, width: 1.5)),
          child: Icon(icon, size: 18, color: ctx.textSecondary)));
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final BuildContext ctx;
  const _StatTile(this.label, this.value, this.icon, this.color, this.ctx);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
          color: ctx.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ctx.borderColor, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: ctx.dmSans(
              15,
              FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        Text(value,
            style: ctx.syne(18, FontWeight.w500, color: AppColors.green700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ]));
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label, value;
  final BuildContext ctx;
  const _Legend(this.color, this.label, this.value, this.ctx);
  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(8),
        Text(label,
            style: ctx.dmSans(12, FontWeight.w400, color: ctx.textSecondary)),
        const Gap(4),
        Text(value, style: ctx.dmSans(12, FontWeight.w700)),
      ]);
}

class _DonutPainter extends CustomPainter {
  final double done, total;
  const _DonutPainter({required this.done, required this.total});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p..color = const Color(0xFFE8F5E9));
    if (total > 0) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2,
          done / total * 2 * pi, false, p..color = const Color(0xFF52B788));
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.done != done || o.total != total;
}
