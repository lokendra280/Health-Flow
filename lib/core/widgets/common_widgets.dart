import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title, value, unit;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.title, required this.value,
    required this.unit, required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (color ?? AppTheme.primary).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color ?? AppTheme.primary, size: 22),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        RichText(text: TextSpan(children: [
          TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          TextSpan(text: ' $unit', style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ])),
      ]),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionHeader({super.key, required this.title, this.action});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (action != null) action!,
    ]),
  );
}

class ProgressRing extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final String label, sublabel;
  final Color color;
  final double size;
  const ProgressRing({super.key, required this.value, required this.label,
    required this.sublabel, this.color = AppTheme.primary, this.size = 120});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size, height: size,
    child: Stack(alignment: Alignment.center, children: [
      SizedBox(width: size, height: size,
        child: CircularProgressIndicator(
          value: value.clamp(0.0, 1.0),
          strokeWidth: 8,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation(color),
          strokeCap: StrokeCap.round,
        ),
      ),
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
        Text(sublabel, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ]),
    ]),
  );
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color>? colors;
  const GradientButton({super.key, required this.text, required this.onPressed, this.colors});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors ?? [AppTheme.primary, AppTheme.secondary]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );
}

class InputField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? suffixText;
  const InputField({super.key, required this.label, required this.hint,
    required this.controller, this.keyboardType, this.suffixText});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
    const SizedBox(height: 6),
    TextField(
      controller: controller, keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(hint: suffixText != null ? null : null,
        hintText: hint,
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: Colors.white38),
      ),
    ),
    const SizedBox(height: 14),
  ]);
}
