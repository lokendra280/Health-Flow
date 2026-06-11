import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/common_widget/common_svg.dart';
import 'package:habitflow/core/constants/constant_assets.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/widgets/habit_icon.dart';
import 'package:habitflow/presentation/widgets/habit_sheet.dart';
import 'package:habitflow/presentation/widgets/habit_sheet_state.dart';

// ─── Models (adjust imports to match your project) ────────────────────────────
// import 'package:yourapp/features/habits/domain/models/habit.dart';
// import 'package:yourapp/features/habits/presentation/providers/habit_list_provider.dart';
// import 'package:yourapp/features/sync/presentation/providers/sync_state_provider.dart';

// ─── Category model ───────────────────────────────────────────────────────────
List<HabitIcon> icons = [
  const HabitIcon.asset(
    label: 'Gym',
    assetPath: Assets.gym,
  )
];

const _habitColors = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFF9C27B0),
  Color(0xFFFF9800),
  Color(0xFFE91E63),
  Color(0xFF00BCD4),
];

const _frequencies = [
  'Everyday',
  'Weekdays',
  'Weekends',
  'Custom',
];

// ─── Page ─────────────────────────────────────────────────────────────────────

class AddHabitPage extends ConsumerStatefulWidget {
  /// Pass an existing habit to enter edit mode.
  const AddHabitPage({super.key, this.editing});

  final HabitSheet? editing; // replace Object? with your Habit model type

  @override
  ConsumerState<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends ConsumerState<AddHabitPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  int _selectedCategory = 0;
  int _selectedColor = 0;
  int _selectedFrequency = 0;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _reminderEnabled = true;
  int _target = 1;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _target = widget.editing?.editing?.targetPerDay ?? 1;

    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reminderTime = picked);
    print("🟢 Selected reminder time: $_reminderTime");
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;
    final reminderTimeStr = '${_reminderTime.hour.toString().padLeft(2, '0')}:'
        '${_reminderTime.minute.toString().padLeft(2, '0')}';
    final frequency = _frequencies[_selectedFrequency];
    final selectedIcon = icons[_selectedCategory];
    final icon = selectedIcon.emoji ?? selectedIcon.assetPath ?? '';
    // Wire up your providers here:
    _isEditing
        ? ref.read(habitListProvider.notifier).updateHabit
        : ref.read(habitListProvider.notifier).addHabit(
              name: _nameController.text.trim(),
              icon: icon,
              targetPerDay: _target,
              colorIndex: _selectedColor,
              reminderEnabled: _reminderEnabled,
              reminderTime: reminderTimeStr,
              frequency: frequency,
            );

    print(_selectedColor);
    ref.read(syncStateProvider.notifier).pushPending();

    Navigator.of(context).pop();
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Habit',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to delete "${_nameController.text}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(habitListProvider.notifier)
                  .deleteHabit(widget.editing!.editing!.id);
              ref.read(syncStateProvider.notifier).pushPending();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedColor = _habitColors[_selectedColor];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isEditing ? 'Edit Habit' : 'Add Habit',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _handleSave,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              children: [
                // ── Category Picker ──────────────────────────────────────
                _SectionLabel(label: 'Category'),
                const SizedBox(height: 12),
                _CategoryGrid(
                  selected: _selectedCategory,
                  onSelect: (i) => setState(() => _selectedCategory = i),
                  icons: [],
                ),
                const SizedBox(height: 28),

                // ── Habit Name ───────────────────────────────────────────
                _SectionLabel(label: 'Habit Name'),
                const SizedBox(height: 10),
                _HabitTextField(
                  controller: _nameController,
                  hint: 'e.g., Drink Water',
                  maxLines: 1,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Habit name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // ── Description ──────────────────────────────────────────
                _SectionLabel(label: 'Description (Optional)'),
                const SizedBox(height: 10),
                _HabitTextField(
                  controller: _descController,
                  hint: 'e.g., Drink 8 glasses of water daily',
                  maxLines: 2,
                ),
                const Gap(10),
                Text('Daily Target',
                    style: context.dmSans(13, FontWeight.w600,
                        color: context.textSecondary)),
                const Gap(8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    StepBtn(
                        Icons.remove_rounded,
                        () => setState(
                            () => _target = (_target - 1).clamp(1, 20))),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('$_target',
                            style: context.syne(24, FontWeight.w500))),
                    StepBtn(
                        Icons.add_rounded,
                        () => setState(
                            () => _target = (_target + 1).clamp(1, 20))),
                  ]),
                ),
                const Gap(9),
                // ── Frequency & Reminder ─────────────────────────────────
                _SettingsCard(
                  children: [
                    _SettingsRow(
                      label: 'Frequency',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _frequencies[_selectedFrequency],
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.calendar_today_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.4)),
                        ],
                      ),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (_) => _FrequencyPicker(
                            frequencies: _frequencies,
                            selected: _selectedFrequency,
                            onSelect: (i) {
                              setState(() => _selectedFrequency = i);
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                    ),
                    Divider(
                        height: 1,
                        color: colorScheme.outline.withOpacity(0.12)),
                    _SettingsRow(
                      label: 'Reminder',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _reminderTime.format(context),
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.access_time_rounded,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.4)),
                        ],
                      ),
                      onTap: _pickReminderTime,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Color Picker ─────────────────────────────────────────
                const _SectionLabel(label: 'Color'),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(_habitColors.length, (i) {
                    final isSelected = _selectedColor == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        width: isSelected ? 36 : 32,
                        height: isSelected ? 36 : 32,
                        decoration: BoxDecoration(
                          color: _habitColors[i],
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _habitColors[i].withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 36),

                // ── Delete (edit mode only) ──────────────────────────────
                if (_isEditing) ...[
                  GestureDetector(
                    onTap: _handleDelete,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              color: Color(0xFFE53935), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete Habit',
                            style: TextStyle(
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Save Button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _handleSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _isEditing ? 'Save Changes' : 'Add Habit',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Category Grid ────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.icons,
    required this.selected,
    required this.onSelect,
  });

  final List<HabitIcon> icons;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: icons.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final icon = icons[index];
        final isSelected = selected == index;

        return GestureDetector(
          onTap: () => onSelect(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF4CAF50).withOpacity(0.12)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Transform.scale(
              scale: isSelected ? 1.15 : 1.0,
              child: Center(
                child: icon.isAsset
                    ? (icon.isSvg
                        ? CommonSvgWidget(svgName: icon.assetPath!)
                        : Image.asset(icon.assetPath!, width: 24, height: 24))
                    : Text(
                        icon.emoji ?? '',
                        style: TextStyle(
                          fontSize: isSelected ? 26 : 22,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _buildIcon(HabitIcon icon) {
  //   if (icon.isEmoji) {
  //     return Text(
  //       icon.emoji!,
  //       style: const TextStyle(fontSize: 22),
  //     );
  //   }

  //   if (icon.isAsset) {
  //     return Image.asset(
  //       icon.assetPath!,
  //       width: 26,
  //       height: 26,
  //     );
  //   }

  //   if (icon.isSvg) {
  //     return CommonSvgWidget(
  //       svgName: icon.svgPath!,
  //     );
  //   }

  //   return const SizedBox();
  // }
}
// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _HabitTextField extends StatelessWidget {
  const _HabitTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.35),
          fontSize: 14,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.trailing,
    this.onTap,
  });

  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ─── Frequency Picker Sheet ───────────────────────────────────────────────────

class _FrequencyPicker extends StatelessWidget {
  const _FrequencyPicker({
    required this.frequencies,
    required this.selected,
    required this.onSelect,
  });

  final List<String> frequencies;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Frequency',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(frequencies.length, (i) {
            final isSelected = selected == i;
            return ListTile(
              title: Text(
                frequencies[i],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : colorScheme.onSurface,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF4CAF50))
                  : Icon(Icons.circle_outlined,
                      color: colorScheme.outline.withOpacity(0.4)),
              onTap: () => onSelect(i),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
