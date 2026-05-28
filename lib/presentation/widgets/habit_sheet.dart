import 'package:flutter/material.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/widgets/habit_sheet_state.dart';

class HabitSheet extends StatefulWidget {
  final Habit? editing;
  final int habitCount;
  final Future<void> Function(String, String, int, int) onSave;
  final VoidCallback? onDelete;
  const HabitSheet({
    required this.editing,
    required this.habitCount,
    required this.onSave,
    this.onDelete,
  });
  @override
  State<HabitSheet> createState() => HabitSheetState();
}
