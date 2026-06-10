import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/core/utils/notification_service.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';

class RemindersScreen extends ConsumerWidget {
  final List<({String id, String name, String icon})> habits;
  const RemindersScreen({super.key, required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(reminderListProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reminders', style: context.syne(28, FontWeight.w800)),
                    const Gap(4),
                    Text('Never miss a check-in again.',
                        style: context.dmSans(14, FontWeight.w400,
                            color: context.textSecondary)),
                    const Gap(20),
                    // Permission banner
                    _PermissionBanner(),
                    const Gap(16),
                    // Add button
                    GestureDetector(
                      onTap: () => _showAddSheet(context, ref),
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
                                  Text('Add Reminder',
                                      style: context.syne(15, FontWeight.w700,
                                          color: context.accent)),
                                  Text('Set a daily nudge for any habit',
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

            const SliverToBoxAdapter(child: Gap(24)),

            // Reminder list
            remindersAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (reminders) {
                if (reminders.isEmpty) {
                  return SliverToBoxAdapter(child: _EmptyReminders());
                }

                // Group by habit
                final byHabit = <String, List<Reminder>>{};
                for (final r in reminders) {
                  byHabit.putIfAbsent(r.habitId, () => []).add(r);
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: byHabit.length,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemBuilder: (ctx, i) {
                      final habitId = byHabit.keys.elementAt(i);
                      final rems = byHabit[habitId]!;
                      final habit =
                          habits.where((h) => h.id == habitId).firstOrNull;
                      return _HabitReminderGroup(
                        habitId: habitId,
                        habitName: habit?.name ?? 'Unknown',
                        habitIcon: habit?.icon ?? '📋',
                        reminders: rems,
                        ref: ref,
                      );
                    },
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: Gap(32)),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddReminderSheet(habits: habits, ref: ref),
    );
  }
}

// ─── Permission Banner ────────────────────────────────────────────────────────
class _PermissionBanner extends StatefulWidget {
  @override
  State<_PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<_PermissionBanner> {
  bool _granted = true;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final pending = await NotificationService.getPending();
    if (mounted)
      setState(() {
        _checked = true;
        _granted = true;
      });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || _granted) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber700.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 20)),
          const Gap(10),
          Expanded(
            child: Text(
              'Enable notifications to receive habit reminders.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppColors.amber700,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              await NotificationService.requestPermission();
              _check();
            },
            child: Text('Enable',
                style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber700)),
          ),
        ],
      ),
    );
  }
}

// ─── Habit Reminder Group ─────────────────────────────────────────────────────
class _HabitReminderGroup extends StatelessWidget {
  final String habitId, habitName, habitIcon;
  final List<Reminder> reminders;
  final WidgetRef ref;

  const _HabitReminderGroup({
    required this.habitId,
    required this.habitName,
    required this.habitIcon,
    required this.reminders,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          // Group header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Text(habitIcon, style: const TextStyle(fontSize: 22)),
                const Gap(10),
                Text(habitName, style: context.syne(15, FontWeight.w700)),
                const Spacer(),
                Text(
                    '${reminders.length} reminder${reminders.length > 1 ? "s" : ""}',
                    style: context.dmSans(12, FontWeight.w400,
                        color: context.textTertiary)),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),
          // Reminder rows
          ...reminders.asMap().entries.map((e) {
            final i = e.key;
            final r = e.value;
            return Column(
              children: [
                _ReminderRow(reminder: r, ref: ref),
                if (i < reminders.length - 1)
                  Divider(height: 1, color: context.borderColor, indent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Reminder Row ─────────────────────────────────────────────────────────────
class _ReminderRow extends StatelessWidget {
  final Reminder reminder;
  final WidgetRef ref;
  const _ReminderRow({required this.reminder, required this.ref});

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: reminder.isEnabled ? context.accentSurf : context.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.alarm_rounded,
              color: reminder.isEnabled ? context.accent : context.textTertiary,
              size: 22,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatTime(reminder.time),
                    style: context.syne(16, FontWeight.w700)),
                const Gap(2),
                Text(reminder.frequencyLabel,
                    style: context.dmSans(12, FontWeight.w400,
                        color: context.textTertiary)),
              ],
            ),
          ),
          // Toggle
          Switch.adaptive(
            value: reminder.isEnabled,
            onChanged: (_) =>
                ref.read(reminderListProvider.notifier).toggle(reminder.id),
            activeColor: context.accent,
          ),
          // Delete
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.delete_outline_rounded,
                  size: 20, color: context.textTertiary),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Reminder',
            style: GoogleFonts.syne(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary)),
        content: Text('Remove this reminder?',
            style: GoogleFonts.dmSans(color: context.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.dmSans(color: context.textSecondary))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(reminderListProvider.notifier).delete(reminder.id);
            },
            child: Text('Delete',
                style: GoogleFonts.dmSans(
                    color: AppColors.coral700, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Reminders ──────────────────────────────────────────────────────────
class _EmptyReminders extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.borderColor, width: 1.5),
          ),
          child: Column(
            children: [
              const Text('🔔', style: TextStyle(fontSize: 48)),
              const Gap(14),
              Text('No reminders yet',
                  style: context.syne(20, FontWeight.w700,
                      color: context.textSecondary)),
              const Gap(8),
              Text(
                'Add a reminder above to get notified when it\'s time to check in.',
                textAlign: TextAlign.center,
                style: context.dmSans(14, FontWeight.w400,
                    color: context.textTertiary),
              ),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADD REMINDER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class AddReminderSheet extends ConsumerStatefulWidget {
  final List<({String id, String name, String icon})> habits;
  final WidgetRef ref;
  const AddReminderSheet({super.key, required this.habits, required this.ref});

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  String? _selectedHabitId;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  ReminderFrequency _frequency = ReminderFrequency.daily;
  final _customDays = <int>{};
  final _msgCtrl = TextEditingController();
  bool _saving = false;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  Future<void> _save() async {
    if (_selectedHabitId == null) return;
    setState(() => _saving = true);
    try {
      final reminder = await ref.read(reminderListProvider.notifier).add(
            habitId: _selectedHabitId!,
            time: _time,
            frequency: _frequency,
            customDays: _customDays.toList(),
            message: _msgCtrl.text.trim(),
            habitName: widget.habits
                .firstWhere((h) => h.id == _selectedHabitId!)
                .name, // Pass habit name for notification scheduling
            habitIcon: widget.habits
                .firstWhere((h) => h.id == _selectedHabitId!)
                .icon, // Pass habit icon for notification scheduling
          );
      final habit = widget.habits.firstWhere((h) => h.id == _selectedHabitId,
          orElse: () => (id: _selectedHabitId!, name: 'Habit', icon: '📋'));
      // Show a test notification for confirmation (scheduling assumed handled by provider)
      await NotificationService.scheduleReminder(
        reminder,
        habitName: habit.name,
        habitIcon: habit.icon,
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
            Text('New Reminder', style: context.syne(24, FontWeight.w800)),
            Text('Schedule a nudge for your habit.',
                style: context.dmSans(13, FontWeight.w400,
                    color: context.textSecondary)),
            const Gap(22),

            // ── Habit picker ──────────────────────────────
            _SheetLabel('Select Habit'),
            const Gap(8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.habits.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final h = widget.habits[i];
                  final sel = h.id == _selectedHabitId;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedHabitId = h.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? context.accentSurf : context.surface2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel ? context.accent : context.borderColor,
                          width: sel ? 2 : 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(h.icon, style: const TextStyle(fontSize: 18)),
                          const Gap(6),
                          Text(h.name,
                              style: context.dmSans(13, FontWeight.w500,
                                  color: sel
                                      ? context.accent
                                      : context.textPrimary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(20),

            // ── Time picker ───────────────────────────────
            _SheetLabel('Time'),
            const Gap(8),
            GestureDetector(
              onTap: () async {
                final t =
                    await showTimePicker(context: context, initialTime: _time);
                if (t != null) setState(() => _time = t);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.surface2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.borderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: context.accent, size: 22),
                    const Gap(12),
                    Text(_formatTime(_time),
                        style: context.syne(18, FontWeight.w700)),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: context.textTertiary),
                  ],
                ),
              ),
            ),

            const Gap(20),

            // ── Frequency ─────────────────────────────────
            _SheetLabel('Frequency'),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ReminderFrequency.values.map((f) {
                final labels = [
                  'Once',
                  'Daily',
                  'Weekdays',
                  'Weekends',
                  'Custom'
                ];
                final sel = f == _frequency;
                return GestureDetector(
                  onTap: () => setState(() => _frequency = f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? context.accentSurf : context.surface2,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: sel ? context.accent : context.borderColor,
                        width: sel ? 2 : 1.5,
                      ),
                    ),
                    child: Text(labels[f.index],
                        style: context.dmSans(13, FontWeight.w600,
                            color:
                                sel ? context.accent : context.textSecondary)),
                  ),
                );
              }).toList(),
            ),

            // Custom day picker
            if (_frequency == ReminderFrequency.custom) ...[
              const Gap(14),
              Row(
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final sel = _customDays.contains(day);
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() =>
                          sel ? _customDays.remove(day) : _customDays.add(day)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: const EdgeInsets.only(right: 4),
                        height: 40,
                        decoration: BoxDecoration(
                          color: sel ? context.accent : context.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(_dayNames[i],
                              style: context.dmSans(10, FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : context.textTertiary)),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],

            const Gap(20),

            // ── Custom message (optional) ─────────────────
            _SheetLabel('Message (optional)'),
            const Gap(8),
            TextField(
              controller: _msgCtrl,
              style: context.dmSans(14, FontWeight.w400),
              decoration: const InputDecoration(
                hintText: 'e.g. Time to run! 🏃',
              ),
            ),
            const Gap(28),

            // ── CTA ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saving || _selectedHabitId == null ? null : _save,
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
                    : Text('Set Reminder',
                        style: context.syne(17, FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
      style: ctx.dmSans(13, FontWeight.w600, color: ctx.textSecondary));
}
