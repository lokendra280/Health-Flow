import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/constants/habits_icons.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/presentation/widgets/habit_sheet.dart';

class HabitSheetState extends State<HabitSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '🏃';
  int _target = 1;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _icon = widget.editing!.icon;
      _target = widget.editing!.targetPerDay;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _nameCtrl.text.trim(),
        _icon,
        _target,
        widget.habitCount % 8,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
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
            )),
            const Gap(22),
            Row(children: [
              Text(widget.editing != null ? 'Edit Habit' : 'New Habit',
                  style: context.syne(24, FontWeight.w500)),
              const Spacer(),
              if (widget.onDelete != null)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onDelete!();
                  },
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.coral700),
                ),
            ]),
            Text('Build a streak, one day at a time.',
                style: context.dmSans(13, FontWeight.w400,
                    color: context.textSecondary)),
            const Gap(22),

            // Name
            Text('Name',
                style: context.dmSans(13, FontWeight.w600,
                    color: context.textSecondary)),
            const Gap(8),
            TextField(
              controller: _nameCtrl,
              autofocus: widget.editing == null,
              style: context.dmSans(15, FontWeight.w400),
              decoration: const InputDecoration(
                hintText: 'e.g. Morning Run…',
              ),
            ),
            const Gap(16),

            // Icons
            Text('Icon',
                style: context.dmSans(13, FontWeight.w600,
                    color: context.textSecondary)),
            const Gap(8),
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: habitIcons.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final ic = habitIcons[i];
                  final sel = ic.assetPath.toString() == _icon;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _icon = ic.assetPath.toString()),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: sel ? context.accentSurf : context.surface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: sel ? context.accent : context.borderColor,
                            width: sel ? 2 : 1.5),
                      ),
                      child: Center(
                          child: Image.asset(
                        height: 20,
                        ic.assetPath ?? "",
                      )),
                    ),
                  );
                },
              ),
            ),
            const Gap(16),

            // Target
            Text('Daily Target',
                style: context.dmSans(13, FontWeight.w600,
                    color: context.textSecondary)),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: context.surface2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor, width: 1.5),
              ),
              child: Row(children: [
                Expanded(
                    child: Text(
                  _target == 1 ? 'Once per day' : '$_target times per day',
                  style: context.dmSans(14, FontWeight.w400),
                )),
                StepBtn(Icons.remove_rounded,
                    () => setState(() => _target = (_target - 1).clamp(1, 20))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_target',
                        style: context.syne(24, FontWeight.w500))),
                StepBtn(Icons.add_rounded,
                    () => setState(() => _target = (_target + 1).clamp(1, 20))),
              ]),
            ),
            const Gap(28),

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
                    : Text(
                        widget.editing != null ? 'Save Changes' : 'Add Habit',
                        style: context.syne(17, FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ],
        )),
      );
}

class StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const StepBtn(this.icon, this.onTap, {super.key});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: ctx.surface3,
            shape: BoxShape.circle,
            border: Border.all(color: ctx.border2, width: 1.5),
          ),
          child: Icon(icon, size: 20, color: ctx.textPrimary),
        ),
      );
}
