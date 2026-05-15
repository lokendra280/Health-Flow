import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  INSIGHTS SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class InsightsScreen extends StatefulWidget {
  final List<Habit> habits;
  final List<Checkin> checkins;
  final Map<String, Streak> streaks;

  const InsightsScreen({
    super.key,
    required this.habits,
    required this.checkins,
    required this.streaks,
  });

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _selectedRange = 7; // 7 or 30 days

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Computed helpers ────────────────────────────────────────────────────────
  String _dk(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<DayStat> _buildDayStats() {
    final today = DateTime.now();
    return List.generate(_selectedRange, (i) {
      final d = today.subtract(Duration(days: _selectedRange - 1 - i));
      final dk = _dk(d);
      final done = widget.habits.where((h) {
        final count = widget.checkins
            .where((c) => c.habitId == h.id && c.dateKey == dk)
            .length;
        return count >= h.targetPerDay;
      }).length;
      return DayStat(date: d, done: done, total: widget.habits.length);
    });
  }

  Map<String, int> _buildHabitTotals() {
    final result = <String, int>{};
    for (final h in widget.habits) {
      result[h.id] = widget.checkins.where((c) => c.habitId == h.id).length;
    }
    return result;
  }

  double _avgCompletion() {
    final stats = _buildDayStats();
    if (stats.isEmpty || stats.first.total == 0) return 0;
    return stats.map((s) => s.rate).reduce((a, b) => a + b) / stats.length;
  }

  int _perfectDays() =>
      _buildDayStats().where((s) => s.total > 0 && s.done == s.total).length;

  @override
  Widget build(BuildContext context) {
    final stats = _buildDayStats();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Insights', style: context.syne(28, FontWeight.w800)),
                  const Gap(4),
                  Text('Track your habit performance over time.',
                      style: context.dmSans(14, FontWeight.w400,
                          color: context.textSecondary)),
                  const Gap(16),
                  // Range toggle
                  Row(
                    children: [7, 30].map((days) {
                      final sel = days == _selectedRange;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRange = days),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? context.pillBg : context.surface2,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${days}d',
                              style: context.dmSans(13, FontWeight.w600,
                                  color: sel
                                      ? context.pillFg
                                      : context.textSecondary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(16),
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tab,
                      labelStyle: GoogleFonts.syne(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      unselectedLabelStyle: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w400),
                      labelColor: context.accent,
                      unselectedLabelColor: context.textTertiary,
                      indicator: BoxDecoration(
                        color: context.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Habits'),
                        Tab(text: 'Heatmap'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab views ─────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _OverviewTab(
                      stats: stats,
                      avgRate: _avgCompletion(),
                      perfectDays: _perfectDays(),
                      context: context),
                  _HabitsTab(
                      habits: widget.habits,
                      totals: _buildHabitTotals(),
                      streaks: widget.streaks,
                      context: context),
                  _HeatmapTab(
                      habits: widget.habits,
                      checkins: widget.checkins,
                      context: context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OVERVIEW TAB
// ─────────────────────────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final List<DayStat> stats;
  final double avgRate;
  final int perfectDays;
  final BuildContext context;

  const _OverviewTab({
    required this.stats,
    required this.avgRate,
    required this.perfectDays,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI chips ─────────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _KpiCard(
                label: 'Avg Rate',
                value: '${(avgRate * 100).round()}%',
                emoji: '📈',
                color: AppColors.green700,
              )),
              const Gap(10),
              Expanded(
                  child: _KpiCard(
                label: 'Perfect Days',
                value: '$perfectDays',
                emoji: '⭐',
                color: AppColors.amber700,
              )),
              const Gap(10),
              Expanded(
                  child: _KpiCard(
                label: 'Total Done',
                value: '${stats.fold(0, (s, d) => s + d.done)}',
                emoji: '✅',
                color: AppColors.blue700,
              )),
            ],
          ),
          const Gap(24),

          // ── Bar chart ─────────────────────────────────
          Text('Completion Per Day', style: ctx.syne(16, FontWeight.w700)),
          const Gap(14),
          Container(
            height: 220,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: ctx.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ctx.borderColor, width: 1.5),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: stats.isEmpty
                    ? 1
                    : stats
                        .map((s) => s.total.toDouble())
                        .reduce((a, b) => a > b ? a : b),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    // tooltipBgColor: ctx.surfaceColor,
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${rod.toY.round()} done',
                      GoogleFonts.dmSans(
                          color: ctx.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i >= stats.length) return const SizedBox();
                        final d = stats[i].date;
                        final days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(days[d.weekday % 7],
                              style: GoogleFonts.dmSans(
                                  color: ctx.textTertiary, fontSize: 11)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: ctx.borderColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: stats.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  final isToday = i == stats.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: s.done.toDouble(),
                        width: stats.length > 14 ? 8 : 14,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: s.done == 0
                              ? [ctx.surface3, ctx.surface3]
                              : isToday
                                  ? [AppColors.green700, AppColors.green500]
                                  : [
                                      AppColors.green700.withOpacity(0.7),
                                      AppColors.green500.withOpacity(0.7)
                                    ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const Gap(24),

          // ── Line trend ────────────────────────────────
          Text('Completion Rate Trend', style: ctx.syne(16, FontWeight.w700)),
          const Gap(14),
          Container(
            height: 180,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
            decoration: BoxDecoration(
              color: ctx.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ctx.borderColor, width: 1.5),
            ),
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 1,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            '${(s.y * 100).round()}%',
                            GoogleFonts.syne(
                                color: ctx.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: ctx.borderColor,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text('${(v * 100).round()}%',
                          style: GoogleFonts.dmSans(
                              color: ctx.textTertiary, fontSize: 10)),
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.rate))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: ctx.accent,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 3.5,
                        color: ctx.accent,
                        strokeColor: ctx.surfaceColor,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ctx.accent.withOpacity(0.2),
                          ctx.accent.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HABITS TAB
// ─────────────────────────────────────────────────────────────────────────────
class _HabitsTab extends StatelessWidget {
  final List<Habit> habits;
  final Map<String, int> totals;
  final Map<String, Streak> streaks;
  final BuildContext context;

  const _HabitsTab({
    required this.habits,
    required this.totals,
    required this.streaks,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    if (habits.isEmpty) {
      return Center(
        child: Text('No habits yet.',
            style: ctx.dmSans(14, FontWeight.w400, color: ctx.textTertiary)),
      );
    }
    final maxTotal = totals.values.isEmpty
        ? 1
        : totals.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('All-Time Checkins per Habit',
              style: ctx.syne(16, FontWeight.w700)),
          const Gap(14),
          // Horizontal bar chart
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ctx.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ctx.borderColor, width: 1.5),
            ),
            child: Column(
              children: habits.map((h) {
                final count = totals[h.id] ?? 0;
                final pct = maxTotal == 0 ? 0.0 : count / maxTotal;
                final s = streaks[h.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(h.icon, style: const TextStyle(fontSize: 18)),
                          const Gap(8),
                          Expanded(
                              child: Text(h.name,
                                  style: ctx.dmSans(13, FontWeight.w500),
                                  overflow: TextOverflow.ellipsis)),
                          const Gap(8),
                          Text('$count ×',
                              style: ctx.syne(13, FontWeight.w700)),
                        ],
                      ),
                      const Gap(8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: pct),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            minHeight: 8,
                            backgroundColor: ctx.surface3,
                            valueColor: AlwaysStoppedAnimation(h.color),
                          ),
                        ),
                      ),
                      const Gap(6),
                      Row(
                        children: [
                          _SmallBadge(
                            '🔥 ${s?.currentStreak ?? 0}d streak',
                            AppColors.amber100,
                            AppColors.amber700,
                          ),
                          const Gap(6),
                          _SmallBadge(
                            'Best: ${s?.longestStreak ?? 0}d',
                            ctx.accentSurf,
                            ctx.accent,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(24),
          // Pie chart
          Text('Check-in Distribution', style: ctx.syne(16, FontWeight.w700)),
          const Gap(14),
          Container(
            height: 240,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ctx.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ctx.borderColor, width: 1.5),
            ),
            child: habits.every((h) => (totals[h.id] ?? 0) == 0)
                ? Center(
                    child: Text('No data yet.',
                        style: ctx.dmSans(14, FontWeight.w400,
                            color: ctx.textTertiary)))
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            sections: habits
                                .where((h) => (totals[h.id] ?? 0) > 0)
                                .map((h) {
                              final v = totals[h.id]!.toDouble();
                              return PieChartSectionData(
                                value: v,
                                color: h.color,
                                radius: 40,
                                showTitle: false,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const Gap(16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: habits
                            .map((h) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: h.color,
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                      const Gap(6),
                                      Text(
                                        h.name.length > 12
                                            ? '${h.name.substring(0, 12)}…'
                                            : h.name,
                                        style: ctx.dmSans(12, FontWeight.w400,
                                            color: ctx.textSecondary),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEATMAP TAB (calendar grid)
// ─────────────────────────────────────────────────────────────────────────────
class _HeatmapTab extends StatelessWidget {
  final List<Habit> habits;
  final List<Checkin> checkins;
  final BuildContext context;

  const _HeatmapTab({
    required this.habits,
    required this.checkins,
    required this.context,
  });

  String _dk(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext ctx) {
    final today = DateTime.now();
    final numWeeks = 13; // ~3 months
    final numDays = numWeeks * 7;

    // build completion rate per date
    final rates = <String, double>{};
    for (int i = 0; i < numDays; i++) {
      final d = today.subtract(Duration(days: numDays - 1 - i));
      final dk = _dk(d);
      if (habits.isEmpty) {
        rates[dk] = 0;
        continue;
      }
      final done = habits.where((h) {
        final c =
            checkins.where((c) => c.habitId == h.id && c.dateKey == dk).length;
        return c >= h.targetPerDay;
      }).length;
      rates[dk] = done / habits.length;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activity Heatmap', style: ctx.syne(16, FontWeight.w700)),
          const Gap(4),
          Text('Last $numWeeks weeks — darker = more complete',
              style: ctx.dmSans(13, FontWeight.w400, color: ctx.textSecondary)),
          const Gap(16),
          // Day labels
          Row(
            children: const [
              SizedBox(width: 24),
              Expanded(child: SizedBox()),
            ],
          ),
          // Grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ctx.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ctx.borderColor, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: day labels
                Row(
                  children: [
                    const SizedBox(width: 28),
                    ...['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: ctx.dmSans(10, FontWeight.w500,
                                    color: ctx.textTertiary)),
                          ),
                        )),
                  ],
                ),
                const Gap(6),
                // Weeks
                ...List.generate(numWeeks, (week) {
                  final weekStart =
                      today.subtract(Duration(days: numDays - 1 - week * 7));
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '${weekStart.month}/${weekStart.day}',
                            style: ctx.dmSans(8, FontWeight.w400,
                                color: ctx.textTertiary),
                          ),
                        ),
                        ...List.generate(7, (day) {
                          final d = weekStart.add(Duration(days: day));
                          final dk = _dk(d);
                          final r = rates[dk] ?? 0.0;
                          final isFuture = d.isAfter(today);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isFuture
                                        ? Colors.transparent
                                        : r == 0
                                            ? ctx.surface3
                                            : ctx.accent
                                                .withOpacity(0.2 + r * 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                    border: _dk(d) == _dk(today)
                                        ? Border.all(
                                            color: ctx.accent, width: 1.5)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
                const Gap(10),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Less',
                        style: ctx.dmSans(10, FontWeight.w400,
                            color: ctx.textTertiary)),
                    const Gap(6),
                    ...List.generate(
                        5,
                        (i) => Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: i == 0
                                      ? ctx.surface3
                                      : ctx.accent.withOpacity(0.2 + i * 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            )),
                    const Gap(6),
                    Text('More',
                        style: ctx.dmSans(10, FontWeight.w400,
                            color: ctx.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String label, value, emoji;
  final Color color;
  const _KpiCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: ctx.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ctx.borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const Gap(8),
            Text(value,
                style: GoogleFonts.syne(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style:
                    GoogleFonts.dmSans(fontSize: 11, color: ctx.textTertiary)),
          ],
        ),
      );
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _SmallBadge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(text,
            style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      );
}
