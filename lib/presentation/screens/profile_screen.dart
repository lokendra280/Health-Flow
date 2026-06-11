import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/common_widget/common_svg.dart';
import 'package:habitflow/core/constants/constant_assets.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/screens/login_required_card.dart';
import 'package:habitflow/presentation/screens/sign_in_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;

    final habits = ref.watch(habitListProvider).value ?? [];
    final longest = ref.watch(longestEverProvider);
    final overall = ref.watch(overallStreakProvider);
    final progress = ref.watch(progressProvider);

    if (user == null) {
      return LoginRequiredCard(
        onLogin: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SignInScreen(),
            ),
          );
        },
      );
    }

    // Total completed = all done checkins across habits (use progress as proxy)
    final totalCompleted = progress.done * 13; // placeholder multiplier
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── AppBar row ────────────────────────────
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                child: Row(children: [
                  Text('Profile', style: context.syne(22, FontWeight.w800)),
                  const Spacer(),
                  GestureDetector(
                      onTap: () => _showEditSheet(context, user),
                      child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: context.surface2,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: context.borderColor, width: 1.5)),
                          child: Icon(Icons.settings_outlined,
                              size: 18, color: context.textSecondary))),
                ]),
              )),

              // ── Avatar + name + motivational text ─────
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(children: [
                  // Avatar
                  Stack(alignment: Alignment.bottomRight, children: [
                    Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF52B788), width: 3),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFF52B788).withOpacity(.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4))
                            ]),
                        child: ClipOval(
                            child: Container(
                                color: const Color(0xFFE8F5E9),
                                child: Center(
                                    child: Text(user.initials.toUpperCase(),
                                        style: GoogleFonts.syne(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                const Color(0xFF52B788))))))),
                    Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                            color: context.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: context.borderColor, width: 2)),
                        child: const Icon(Icons.edit_rounded,
                            size: 13, color: Colors.grey)),
                  ]),
                  const Gap(14),
                  Text(user.displayName,
                      style: context.syne(22, FontWeight.w800)),
                  const Gap(4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Keep going, you\'re doing great!',
                        style: context.dmSans(13, FontWeight.w400,
                            color: context.textSecondary)),
                    const Gap(4),
                    const Text('✏️', style: TextStyle(fontSize: 13)),
                  ]),
                  const Gap(16),

                  // ── Total Habits + Total Completed card ──
                  Container(
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [
                              Color(0xFF4CAF50),
                              Color(0xFF66BB6A),
                              Color(0xFF81C784),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Habits',
                                        style: context.dmSans(
                                            11, FontWeight.w500,
                                            color: Colors.white70)),
                                    const Gap(4),
                                    Text('${habits.length}',
                                        style: context
                                            .syne(26, FontWeight.w800)
                                            .copyWith(color: Colors.white)),
                                  ]))),
                      Container(width: 1, height: 50, color: Colors.white24),
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Total Completed',
                                        style: context.dmSans(
                                            11, FontWeight.w500,
                                            color: Colors.white70)),
                                    const Gap(4),
                                    Text('$totalCompleted',
                                        style: context
                                            .syne(26, FontWeight.w800)
                                            .copyWith(color: Colors.white)),
                                  ]))),
                    ]),
                  ),
                ]),
              )),

              // ── Menu items (matches design) ───────────
              const SliverToBoxAdapter(child: Gap(24)),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: [
                  _MenuItem(
                    icon: Assets.about,
                    label: 'Achievements',
                    onTap: () {},
                  ),
                  _MenuItem(icon: Assets.habit, label: 'History', onTap: () {}),
                  _MenuItem(
                      icon: Assets.notification,
                      label: 'Themes',
                      onTap: () => _toggleTheme()),
                  // _MenuItem(
                  //     Icons.notifications_outlined, '🔔', 'Reminders', () {}),
                  // _MenuItem(
                  //     Icons.help_outline_rounded, '❓', 'Help & Support', () {}),
                  // _MenuItem(Icons.info_outline_rounded, 'ℹ️', 'About HabitFlow',
                  //     () {}),
                ]),
              )),

              // ── Log Out ───────────────────────────────
              const SliverToBoxAdapter(child: Gap(20)),
              SliverToBoxAdapter(
                  child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                    onTap: () => _signOut(context),
                    child: Center(
                        child: Text('Log Out',
                            style: context.dmSans(15, FontWeight.w700,
                                color: AppColors.coral700)))),
              )),

              const SliverToBoxAdapter(child: Gap(48)),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTheme() => ref.read(themeModeProvider.notifier).update((s) => !s);

  void _showEditSheet(BuildContext context, AppUser user) {
    final ctrl = TextEditingController(text: user.username ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28))),
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            left: 24,
            right: 24,
            top: 14),
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
                        borderRadius: BorderRadius.circular(99)))),
            const Gap(22),
            Text('Edit Profile', style: context.syne(22, FontWeight.w800)),
            const Gap(20),
            TextField(
                controller: ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: 'Display name',
                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20))),
            const Gap(24),
            SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(authStateProvider.notifier)
                        .updateProfile(username: ctrl.text.trim());
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF52B788),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: Text('Save Changes',
                      style: context.syne(16, FontWeight.w700,
                          color: Colors.white)),
                )),
          ],
        ),
      ),
    );
  }

  void _signOut(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: context.surfaceColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title:
                    Text('Sign Out', style: context.syne(18, FontWeight.w700)),
                content: Text('Your habits are safely synced to the cloud.',
                    style: context.dmSans(14, FontWeight.w400,
                        color: context.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel',
                          style: context.dmSans(14, FontWeight.w400,
                              color: context.textSecondary))),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authStateProvider.notifier).signOut();
                      },
                      child: Text('Sign Out',
                          style: context.dmSans(14, FontWeight.w700,
                              color: AppColors.coral700))),
                ]));
  }
}

// ── Menu item (matches design: icon left, arrow right) ────────────
class _MenuItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
              color: ctx.surfaceColor,
              border: Border(
                  bottom: BorderSide(
                      color: ctx.borderColor.withOpacity(.5), width: .5))),
          child: Row(children: [
            // Colored icon box
            Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: ctx.accentSurf,
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: CommonSvgWidget(
                    svgName: icon,
                  ),
                )),
            const Gap(14),
            Text(label, style: ctx.dmSans(14, FontWeight.w500)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: ctx.textTertiary),
          ]),
        ),
      );
}
