import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/data/repositories/challenge_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';
import '../providers/providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CHALLENGES SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChallengesScreen extends ConsumerWidget {
  final List<Habit> habits;
  const ChallengesScreen({super.key, required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeChallengesProvider);
    final completed = ref.watch(completedChallengesProvider);
    final all = ref.watch(challengeListProvider).value ?? [];
    final failed =
        all.where((c) => c.status == ChallengeStatus.failed).toList();
    final repo = ChallengeRepository();
    final challenges = repo.getAll();
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Challenges',
                        style: context.syne(28, FontWeight.w500)),
                    const Gap(4),
                    Text('Set a streak goal and crush it.',
                        style: context.dmSans(14, FontWeight.w400,
                            color: context.textSecondary)),
                    const Gap(20),

                    // Stats row
                    Row(
                      children: [
                        _StatPill('🏆 ${completed.length}', 'Won',
                            AppColors.amber100, AppColors.amber700),
                        const Gap(8),
                        _StatPill('🔥 ${active.length}', 'Active',
                            context.accentSurf, context.accent),
                        const Gap(8),
                        _StatPill('💀 ${failed.length}', 'Failed',
                            AppColors.coral100, AppColors.coral700),
                      ],
                    ),
                    const Gap(20),

                    // Create button
                    GestureDetector(
                      onTap: () => _showCreateSheet(context, ref),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.accentSurf,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: context.accent.withOpacity(0.3),
                              width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: context.accent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white, size: 22),
                            ),
                            const Gap(14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('New Challenge',
                                      style: context.syne(15, FontWeight.w700,
                                          color: context.accent)),
                                  Text('Pick a template or custom goal',
                                      style: context.dmSans(12, FontWeight.w400,
                                          color: context.accentText)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 14, color: context.accent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Active Challenges ────────────────────────
            if (active.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child:
                      Text('Active', style: context.syne(18, FontWeight.w700)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: active.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (ctx, i) => _ChallengeCard(
                    challenge: active[i],
                    habits: habits,
                    ref: ref,
                  ),
                ),
              ),
            ],

            // ── Templates ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child:
                    Text('Templates', style: context.syne(18, FontWeight.w700)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: challenges.length,
                separatorBuilder: (_, __) => const Gap(10),
                itemBuilder: (ctx, i) {
                  final t = challenges[i];

                  return _TemplateCard(
                    template: t,
                    onStart: () => _showCreateSheet(
                      context,
                      ref,
                    ),
                  );
                },
              ),
            ),

            // ── Completed ───────────────────────────────
            if (completed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text('Completed 🏆',
                      style: context.syne(18, FontWeight.w700)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: completed.length,
                  separatorBuilder: (_, __) => const Gap(10),
                  itemBuilder: (ctx, i) =>
                      _CompletedCard(challenge: completed[i], ref: ref),
                ),
              ),
            ],

            // ── Empty ────────────────────────────────────
            if (active.isEmpty && completed.isEmpty)
              const SliverToBoxAdapter(child: _EmptyChallenges()),

            const SliverToBoxAdapter(child: Gap(40)),
          ],
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref,
      {Map<String, dynamic>? template}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateChallengeSheet(
        habits: habits,
        ref: ref,
        template: template,
      ),
    );
  }
}

// ─── Active Challenge Card ────────────────────────────────────────────────────
class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final List<Habit> habits;
  final WidgetRef ref;
  const _ChallengeCard({
    required this.challenge,
    required this.habits,
    required this.ref,
  });

  @override
  Widget build(BuildContext ctx) {
    final pct = challenge.progressPct();
    final elapsed = challenge.daysElapsed();
    final remain = challenge.daysRemaining();
    final chalHabits =
        habits.where((h) => challenge.habitIds.contains(h.id)).toList();

    return Container(
      decoration: BoxDecoration(
        color: ctx.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: challenge.color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: challenge.color.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // ── Top gradient banner ────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    challenge.color.withOpacity(0.15),
                    challenge.color.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(challenge.emoji,
                          style: const TextStyle(fontSize: 28)),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(challenge.title,
                                style: ctx.syne(17, FontWeight.w500)),
                            Text(challenge.description,
                                style: ctx.dmSans(13, FontWeight.w400,
                                    color: ctx.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _delete(ctx),
                        child: Icon(Icons.close_rounded,
                            size: 20, color: ctx.textTertiary),
                      ),
                    ],
                  ),
                  const Gap(14),
                  // Progress bar
                  Row(
                    children: [
                      Text('Day $elapsed of ${challenge.targetDays}',
                          style: ctx.dmSans(12, FontWeight.w500,
                              color: ctx.textTertiary)),
                      const Spacer(),
                      Text('$remain days left',
                          style: ctx.dmSans(12, FontWeight.w500,
                              color: challenge.color)),
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
                        backgroundColor: challenge.color.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation(challenge.color),
                      ),
                    ),
                  ),
                  const Gap(4),
                  Text('${(pct * 100).round()}% complete',
                      style: ctx.dmSans(11, FontWeight.w500,
                          color: ctx.textTertiary)),
                ],
              ),
            ),
            // ── Habits involved ────────────────────────
            if (chalHabits.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Row(
                  children: [
                    Text('Tracking: ',
                        style: ctx.dmSans(12, FontWeight.w400,
                            color: ctx.textTertiary)),
                    ...chalHabits.take(4).map((h) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Text(h.icon,
                              style: const TextStyle(fontSize: 18)),
                        )),
                    if (chalHabits.length > 4)
                      Text('+${chalHabits.length - 4}',
                          style: ctx.dmSans(12, FontWeight.w500,
                              color: ctx.textTertiary)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _delete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        backgroundColor: ctx.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Quit Challenge',
            style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ctx.textPrimary)),
        content: Text('Give up "${challenge.title}"?',
            style: GoogleFonts.dmSans(color: ctx.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: ctx.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              ref.read(challengeListProvider.notifier).delete(challenge.id);
            },
            child: Text('Quit',
                style: GoogleFonts.dmSans(
                    color: AppColors.coral700, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Template Card ────────────────────────────────────────────────────────────
class _TemplateCard extends StatelessWidget {
  final Challenge template;
  final VoidCallback onStart;

  const _TemplateCard({
    required this.template,
    required this.onStart,
  });

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ctx.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ctx.borderColor,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              template.emoji,
              style: const TextStyle(fontSize: 26),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.title,
                    style: ctx.syne(14, FontWeight.w700),
                  ),
                  Text(
                    template.description,
                    style: ctx.dmSans(
                      12,
                      FontWeight.w400,
                      color: ctx.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: ctx.accentSurf,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${template.targetDays}d',
                style: ctx.syne(
                  13,
                  FontWeight.w700,
                  color: ctx.accent,
                ),
              ),
            ),
            const Gap(8),
            GestureDetector(
              onTap: onStart,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ctx.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );
}

// ─── Completed Card ───────────────────────────────────────────────────────────
class _CompletedCard extends StatelessWidget {
  final Challenge challenge;
  final WidgetRef ref;
  const _CompletedCard({required this.challenge, required this.ref});

  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.amber100.withOpacity(ctx.isDark ? 0.15 : 1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.amber700.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 28)),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(challenge.title, style: ctx.syne(14, FontWeight.w700)),
                  Text('${challenge.targetDays}-day challenge completed!',
                      style: ctx.dmSans(12, FontWeight.w400,
                          color: AppColors.amber700)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () =>
                  ref.read(challengeListProvider.notifier).delete(challenge.id),
              child: Icon(Icons.delete_outline_rounded,
                  size: 20, color: ctx.textTertiary),
            ),
          ],
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyChallenges extends StatelessWidget {
  const _EmptyChallenges();
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ctx.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ctx.borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 48)),
              const Gap(14),
              Text('No challenges yet',
                  style:
                      ctx.syne(20, FontWeight.w700, color: ctx.textSecondary)),
              const Gap(8),
              Text('Start a challenge to push yourself further.',
                  textAlign: TextAlign.center,
                  style:
                      ctx.dmSans(14, FontWeight.w400, color: ctx.textTertiary)),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  CREATE CHALLENGE SHEET
// ─────────────────────────────────────────────────────────────────────────────
class CreateChallengeSheet extends ConsumerStatefulWidget {
  final List<Habit> habits;
  final WidgetRef ref;
  final Map<String, dynamic>? template;
  const CreateChallengeSheet({
    super.key,
    required this.habits,
    required this.ref,
    this.template,
  });

  @override
  ConsumerState<CreateChallengeSheet> createState() =>
      _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends ConsumerState<CreateChallengeSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _emoji = '🎯';
  int _days = 7;
  final _selectedHabitIds = <String>{};
  bool _saving = false;

  static const _emojis = [
    '🎯',
    '🏆',
    '🚀',
    '🔥',
    '⚡',
    '💪',
    '🌟',
    '👑',
    '🦸',
    '🔒'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.template != null) {
      _titleCtrl.text = widget.template!['title'] as String;
      _descCtrl.text = widget.template!['description'] as String;
      _emoji = widget.template!['emoji'] as String;
      _days = widget.template!['targetDays'] as int;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final count = (ref.read(challengeListProvider).value ?? []).length;
      await ref.read(challengeListProvider.notifier).create(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            emoji: _emoji,
            habitIds: _selectedHabitIds.toList(),
            targetDays: _days,
            colorIndex: count % 8,
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        left: 24,
        right: 24,
        top: 14,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: context.border2,
                    borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const Gap(22),
            Text('New Challenge', style: context.syne(24, FontWeight.w400)),
            Text('Set your goal and go all in.',
                style: context.dmSans(13, FontWeight.w400,
                    color: context.textSecondary)),
            const Gap(22),

            // Emoji picker
            _Label('Choose Emoji'),
            const Gap(8),
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _emojis.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final e = _emojis[i];
                  final sel = e == _emoji;
                  return GestureDetector(
                    onTap: () => setState(() => _emoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: sel ? context.accentSurf : context.surface2,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: sel ? context.accent : context.borderColor,
                          width: sel ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                          child: Text(e, style: const TextStyle(fontSize: 22))),
                    ),
                  );
                },
              ),
            ),
            const Gap(16),

            // Title
            _Label('Title'),
            const Gap(8),
            TextField(
              controller: _titleCtrl,
              style: context.dmSans(15, FontWeight.w400),
              decoration: const InputDecoration(hintText: 'e.g. 30-Day Streak'),
            ),
            const Gap(16),

            // Description
            _Label('Description (optional)'),
            const Gap(8),
            TextField(
              controller: _descCtrl,
              style: context.dmSans(14, FontWeight.w400),
              decoration: const InputDecoration(hintText: 'What\'s the goal?'),
            ),
            const Gap(16),

            // Target days
            _Label('Target Days: $_days'),
            Slider(
              value: _days.toDouble(),
              min: 3,
              max: 100,
              divisions: 97,
              label: '$_days days',
              onChanged: (v) => setState(() => _days = v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [7, 21, 30, 66, 100].map((d) {
                final sel = d == _days;
                return GestureDetector(
                  onTap: () => setState(() => _days = d),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? context.accentSurf : context.surface2,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: sel ? context.accent : context.borderColor,
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Text('${d}d',
                        style: context.dmSans(11, FontWeight.w600,
                            color:
                                sel ? context.accent : context.textTertiary)),
                  ),
                );
              }).toList(),
            ),
            const Gap(20),

            // Habit selection
            _Label('Track These Habits'),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.habits.map((h) {
                final sel = _selectedHabitIds.contains(h.id);
                return GestureDetector(
                  onTap: () => setState(() => sel
                      ? _selectedHabitIds.remove(h.id)
                      : _selectedHabitIds.add(h.id)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? context.accentSurf : context.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel ? context.accent : context.borderColor,
                        width: sel ? 2 : 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(h.icon,
                            width: 20, height: 20, fit: BoxFit.contain),
                        const Gap(6),
                        Text(h.name,
                            style: context.dmSans(13, FontWeight.w500,
                                color: sel
                                    ? context.accent
                                    : context.textPrimary)),
                        if (sel) ...[
                          const Gap(4),
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: context.accent),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Gap(28),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Start Challenge',
                        style: context.syne(17, FontWeight.w500,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
      style: ctx.dmSans(13, FontWeight.w600, color: ctx.textSecondary));
}

class _StatPill extends StatelessWidget {
  final String label, sub;
  final Color bg, fg;
  const _StatPill(this.label, this.sub, this.bg, this.fg);
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Column(
          children: [
            Text(label,
                style: GoogleFonts.syne(
                    fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
            Text(sub,
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: fg.withOpacity(0.7))),
          ],
        ),
      );
}
