import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';

class EmptyHabits extends StatelessWidget {
  final VoidCallback onAdd;
  const EmptyHabits({required this.onAdd});
  @override
  Widget build(BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ctx.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ctx.borderColor, width: 1.5),
          ),
          child: Column(children: [
            Text('No habits yet',
                style: ctx.syne(20, FontWeight.w700, color: ctx.textSecondary)),
            const Gap(8),
            Text('Add your first habit and start a streak!',
                textAlign: TextAlign.center,
                style:
                    ctx.dmSans(14, FontWeight.w400, color: ctx.textTertiary)),
            const Gap(24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add First Habit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ctx.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ]),
        ),
      );
}
