import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';

class AddHabitSheet extends StatefulWidget {
  final Habit? editing;
  final int habitCount;
  final Future<void> Function(String name, String icon, int target, int ci)
      onSave;
  final VoidCallback? onDelete;
  const AddHabitSheet({
    required this.editing,
    required this.habitCount,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AddHabitSheet> createState() => AddHabitSheetState();
}

class AddHabitSheetState extends State<AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '🏃';
  int _target = 1;
  bool _saving = false;

  static const _icons = [
    '🏃',
    '💪',
    '📚',
    '🧘',
    '💧',
    '🥗',
    '🎨',
    '✍️',
    '🎵',
    '🌿',
    '💤',
    '🧹',
    '🤸',
    '🧠',
    '☀️',
    '🫁',
    '🎯',
    '🏊',
    '🚴',
    '🧗',
  ];

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
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(name, _icon, _target, widget.habitCount % 8);
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
            )),
            const Gap(22),
            Row(
              children: [
                Text(
                  widget.editing != null ? 'Edit Habit' : 'New Habit',
                  style: context.syne(24, FontWeight.w800),
                ),
                const Spacer(),
                if (widget.onDelete != null)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onDelete!();
                    },
                    icon: Icon(Icons.delete_outline_rounded,
                        color: AppColors.coral700),
                  ),
              ],
            ),
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
              decoration: InputDecoration(
                hintText: 'e.g. Morning Run…',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Text(_icon, style: const TextStyle(fontSize: 22)),
                ),
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
                itemCount: _icons.length,
                separatorBuilder: (_, __) => const Gap(8),
                itemBuilder: (ctx, i) {
                  final ic = _icons[i];
                  final sel = ic == _icon;
                  return GestureDetector(
                    onTap: () => setState(() => _icon = ic),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: sel ? context.accentSurf : context.surface2,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: sel ? context.accent : context.borderColor,
                          width: sel ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                          child:
                              Text(ic, style: const TextStyle(fontSize: 22))),
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
              child: Row(
                children: [
                  Expanded(
                      child: Text(
                    _target == 1 ? 'Once per day' : '$_target times per day',
                    style: context.dmSans(14, FontWeight.w400),
                  )),
                  _StepBtn(
                      Icons.remove_rounded,
                      () =>
                          setState(() => _target = (_target - 1).clamp(1, 20))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('$_target',
                        style: context.syne(24, FontWeight.w800)),
                  ),
                  _StepBtn(
                      Icons.add_rounded,
                      () =>
                          setState(() => _target = (_target + 1).clamp(1, 20))),
                ],
              ),
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
                            color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn(this.icon, this.onTap);
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
