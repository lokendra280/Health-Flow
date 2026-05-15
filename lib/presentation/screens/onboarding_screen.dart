import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitflow/core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  final void Function(List<int> selected) onComplete;
  const OnboardingPage({required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _selected = <int>{};
  bool _loading = false;
  late final AnimationController _fade;

  static const _seeds = [
    ('Morning Run', '🏃'),
    ('Read 20 Pages', '📚'),
    ('Drink Water', '💧'),
    ('Meditate', '🧘'),
    ('Workout', '💪'),
    ('Sleep 8h', '💤'),
    ('Healthy Eating', '🥗'),
    ('Journal', '✍️'),
  ];

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(40),
                Text('Welcome to',
                    style: context.dmSans(16, FontWeight.w400,
                        color: context.textSecondary)),
                const Gap(2),
                RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: 'Habit',
                      style: GoogleFonts.syne(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          height: 1)),
                  TextSpan(
                      text: 'Flow',
                      style: GoogleFonts.syne(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: context.accent,
                          height: 1)),
                  TextSpan(
                      text: ' 2',
                      style: GoogleFonts.syne(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: context.textTertiary,
                          height: 1)),
                ])),
                const Gap(10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.accentSurf,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '🔔 Reminders  📊 Insights  🏆 Challenges  ✨ Animations',
                    style: context.dmSans(12, FontWeight.w500,
                        color: context.accent),
                  ),
                ),
                const Gap(32),
                Text('Pick your habits',
                    style: context.syne(20, FontWeight.w700)),
                const Gap(4),
                Text('Select what you want to track every day.',
                    style: context.dmSans(14, FontWeight.w400,
                        color: context.textSecondary)),
                const Gap(20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: _seeds.length,
                    itemBuilder: (ctx, i) {
                      final (name, icon) = _seeds[i];
                      final sel = _selected.contains(i);
                      return GestureDetector(
                        onTap: () => setState(
                            () => sel ? _selected.remove(i) : _selected.add(i)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color:
                                sel ? context.accentSurf : context.surfaceColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: sel ? context.accent : context.borderColor,
                              width: sel ? 2 : 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 22)),
                              const Gap(10),
                              Expanded(
                                  child: Text(name,
                                      style: context.dmSans(13, FontWeight.w500,
                                          color: sel
                                              ? context.accent
                                              : context.textPrimary),
                                      overflow: TextOverflow.ellipsis)),
                              if (sel)
                                Icon(Icons.check_circle_rounded,
                                    size: 18, color: context.accent),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() => _loading = true);
                            widget.onComplete(_selected.toList());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            _selected.isEmpty
                                ? 'Get Started (use defaults)'
                                : 'Start with ${_selected.length} habit${_selected.length > 1 ? "s" : ""}',
                            style: context.syne(16, FontWeight.w700,
                                color: Colors.white),
                          ),
                  ),
                ),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
