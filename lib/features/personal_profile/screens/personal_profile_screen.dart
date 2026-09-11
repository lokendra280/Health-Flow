import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/constants/app_topography.dart';
import 'package:habitflow/core/constants/constant_assets.dart';
import 'package:habitflow/core/constants/size_constant.dart';
import 'package:habitflow/core/widgets/app_textfield.dart';
import 'package:habitflow/features/personal_profile/screens/widgets/group_chip_card.dart';
import '../providers/personal_profile_provider.dart';

const _activityLevels = [
  'sedentary',
  'light',
  'moderate',
  'active',
  'very_active'
];
const _fitnessLevels = ['beginner', 'intermediate', 'advanced'];
const _diets = [
  'omnivore',
  'vegetarian',
  'vegan',
  'pescatarian',
  'keto',
  'other'
];
const _commonAllergies = [
  'peanuts',
  'tree nuts',
  'dairy',
  'gluten',
  'shellfish',
  'eggs',
  'soy'
];

class PersonalProfileScreen extends ConsumerStatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  ConsumerState<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends ConsumerState<PersonalProfileScreen> {
  late final TextEditingController _ageCtrl;
  late final TextEditingController _cmHeightCtrl;
  late final TextEditingController _ftHeightCtrl;
  late final TextEditingController _inHeightCtrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(personalProfileControllerProvider);
    _ageCtrl = TextEditingController(text: profile.age?.toString() ?? '');
    
    if (profile.heightUnit == 'cm') {
      _cmHeightCtrl = TextEditingController(text: profile.height?.toStringAsFixed(0) ?? '');
      _ftHeightCtrl = TextEditingController();
      _inHeightCtrl = TextEditingController();
    } else {
      _cmHeightCtrl = TextEditingController();
      if (profile.height != null) {
        final totalInches = profile.height!;
        _ftHeightCtrl = TextEditingController(text: (totalInches / 12).floor().toString());
        _inHeightCtrl = TextEditingController(text: (totalInches % 12).toStringAsFixed(0));
      } else {
        _ftHeightCtrl = TextEditingController();
        _inHeightCtrl = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _cmHeightCtrl.dispose();
    _ftHeightCtrl.dispose();
    _inHeightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(personalProfileControllerProvider.notifier);
    final profile = ref.watch(personalProfileControllerProvider);
    final isValid = ref.watch(personalProfileValidProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _TopographyBackground(
                  color: colorScheme.primary.withValues(alpha: 0.04)),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: _StepHeader(
                    step: 2,
                    totalSteps: 3,
                    title: 'About you',
                    subtitle: 'A few details so we can personalize your plan.',
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _PremiumTextField(
                        controller: _ageCtrl,
                        label: "Age",
                        keyboardType: TextInputType.number,
                        icon: Icons.cake_rounded,
                        onChanged: (v) {
                          final age = int.tryParse(v);
                          if (age != null) controller.setAge(age);
                        },
                      ),
                      SBC.lHM,
                      DropdownButtonFormField<String>(
                        decoration: _fieldDecoration(context,
                            label: 'Gender', icon: Icons.person_rounded),
                        value: profile.gender,
                        items: const [
                          'female',
                          'male',
                          'non-binary',
                          'prefer not to say'
                        ]
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.setGender(v);
                        },
                      ),
                      SBC.lHM,
                      _SectionCard(
                        icon: Icons.height_rounded,
                        title: 'Height',
                        child: Column(
                          children: [
                            SegmentedButton<String>(
                              style: SegmentedButton.styleFrom(
                                selectedBackgroundColor: colorScheme.primary,
                                selectedForegroundColor: colorScheme.onPrimary,
                                side: BorderSide(
                                    color: colorScheme.outlineVariant),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              segments: const [
                                ButtonSegment(value: 'cm', label: Text('cm')),
                                ButtonSegment(value: 'ft', label: Text('ft/in')),
                              ],
                              selected: {profile.heightUnit},
                              onSelectionChanged: (s) {
                                final newUnit = s.first;
                                controller.setHeight(profile.height ?? 0,
                                    unit: newUnit);
                              },
                            ),
                            SBC.mH,
                            if (profile.heightUnit == 'cm')
                              _PremiumTextField(
                                controller: _cmHeightCtrl,
                                label: 'Height (cm)',
                                keyboardType: TextInputType.number,
                                icon: Icons.straighten_rounded,
                                onChanged: (v) {
                                  final h = double.tryParse(v);
                                  if (h != null) controller.setHeight(h);
                                },
                              )
                            else
                              Row(
                                children: [
                                  Expanded(
                                    child: _PremiumTextField(
                                      controller: _ftHeightCtrl,
                                      label: 'Feet',
                                      keyboardType: TextInputType.number,
                                      icon: Icons.height_rounded,
                                      onChanged: (v) {
                                        final ft = int.tryParse(v) ?? 0;
                                        final inch =
                                            double.tryParse(_inHeightCtrl.text) ??
                                                0;
                                        controller.setHeight(ft * 12.0 + inch);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PremiumTextField(
                                      controller: _inHeightCtrl,
                                      label: 'Inches',
                                      keyboardType: TextInputType.number,
                                      icon: Icons.height_rounded,
                                      onChanged: (v) {
                                        final ft =
                                            int.tryParse(_ftHeightCtrl.text) ?? 0;
                                        final inch = double.tryParse(v) ?? 0;
                                        controller.setHeight(ft * 12.0 + inch);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      SBC.lHM,
                      const TextWidget(
                        title: "Activity Level",
                      ),
                      SBC.lHM,
                      ChipGroupCard(
                        options: _activityLevels,
                        isSelected: (level) => profile.activityLevel == level,
                        onSelected: (level) =>
                            controller.setActivityLevel(level),
                        labelBuilder: (level) => level.replaceAll('_', ' '),
                      ),
                      SBC.lHM,
                      const TextWidget(
                        title: "Fitness level",
                      ),
                      SBC.lHM,
                      ChipGroupCard(
                        options: _fitnessLevels,
                        isSelected: (level) => profile.fitnessLevel == level,
                        onSelected: (level) => controller.setFitnessLevel(level),
                      ),
                      SBC.lHM,
                      const TextWidget(
                        title: "Diet preference",
                      ),
                      SBC.lHM,
                      ChipGroupCard(
                        options: _diets,
                        isSelected: (d) => profile.dietPreference == d,
                        onSelected: (d) => controller.setDietPreference(d),
                      ),
                      SBC.lHM,
                      const TextWidget(
                        title: "Food allergies",
                      ),
                      SBC.lHM,
                      ChipGroupCard(
                        options: _commonAllergies,
                        isSelected: (a) => profile.foodAllergies.contains(a),
                        onSelected: (a) => controller.toggleAllergy(a),
                        filter: true,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: isValid
                            ? () async {
                                await controller.submit();
                                if (context.mounted) context.go('/ai-plan');
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Continue', style: theme.textTheme.labelLarge),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                      ),
                    ]),
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
        i + size.height / 2,
        size.height / 2,
        i + size.height,
        size.height,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TopographyBackground oldDelegate) =>
      oldDelegate.color != color;
}

class TextWidget extends StatelessWidget {
  final String title;
  const TextWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.h3,
    );
  }
}

InputDecoration _fieldDecoration(BuildContext context,
    {required String label, required IconData icon, String? suffix}) {
  final colorScheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    suffixText: suffix,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
    ),
  );
}

class _StepHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.82),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $step of $totalSteps',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary.withOpacity(0.85),
                ),
              ),
              Row(
                children: List.generate(totalSteps, (i) {
                  final active = i < step;
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 20,
                    height: 4,
                    decoration: BoxDecoration(
                      color: active
                          ? colorScheme.onPrimary
                          : colorScheme.onPrimary.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineLarge?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final ValueChanged<String> onChanged;

  const _PremiumTextField({
    this.controller,
    required this.label,
    required this.icon,
    required this.keyboardType,
    required this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration:
          _fieldDecoration(context, label: label, icon: icon, suffix: suffix),
    );
  }
}
