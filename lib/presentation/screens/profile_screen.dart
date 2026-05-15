import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/widgets/sync_status_widget.dart';
import 'package:intl/intl.dart';

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
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final habits = ref.watch(habitListProvider).value ?? [];
    final longest = ref.watch(longestEverProvider);
    final overall = ref.watch(overallStreakProvider);
    final progress = ref.watch(progressProvider);

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Text('Profile', style: context.syne(28, FontWeight.w800)),
                      const Spacer(),
                      // Sync indicator
                      const SyncStatusWidget(compact: true),
                      const Gap(10),
                      // Edit button
                      GestureDetector(
                        onTap: () => _showEditSheet(context, user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.surface2,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                                color: context.borderColor, width: 1.5),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.edit_outlined,
                                size: 15, color: context.textSecondary),
                            const Gap(5),
                            Text('Edit',
                                style: context.dmSans(13, FontWeight.w500,
                                    color: context.textSecondary)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Avatar + name ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  context.accent,
                                  context.accent.withOpacity(0.6),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: context.accent.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user.initials,
                                style: GoogleFonts.syne(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: context.surfaceColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: context.borderColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_outlined,
                                  size: 14, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),
                      Text(user.displayName,
                          style: context.syne(22, FontWeight.w800)),
                      const Gap(4),
                      Text(user.email,
                          style: context.dmSans(14, FontWeight.w400,
                              color: context.textSecondary)),
                      const Gap(6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: context.accentSurf,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'Member since ${DateFormat('MMM yyyy').format(user.createdAt)}',
                          style: context.dmSans(12, FontWeight.w500,
                              color: context.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats grid ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Stats',
                          style: context.syne(18, FontWeight.w700)),
                      const Gap(14),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.6,
                        children: [
                          _StatCard(
                              emoji: '📋',
                              label: 'Total Habits',
                              value: '${habits.length}'),
                          _StatCard(
                              emoji: '🔥',
                              label: 'Current Streak',
                              value: '${overall}d'),
                          _StatCard(
                              emoji: '🏆',
                              label: 'Longest Streak',
                              value: '${longest}d'),
                          _StatCard(
                              emoji: '✅',
                              label: 'Done Today',
                              value: '${progress.done}/${progress.total}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sync section ──────────────────────────
              const SliverToBoxAdapter(child: Gap(28)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cloud Sync',
                          style: context.syne(18, FontWeight.w700)),
                      const Gap(14),
                      const SyncStatusWidget(compact: false),
                    ],
                  ),
                ),
              ),

              // ── Account actions ───────────────────────
              const SliverToBoxAdapter(child: Gap(28)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account', style: context.syne(18, FontWeight.w700)),
                      const Gap(14),
                      _ActionTile(
                        icon: Icons.lock_reset_rounded,
                        label: 'Change Password',
                        sub: 'Send a reset link to your email',
                        onTap: () => _changePassword(context, user.email),
                      ),
                      const Gap(10),
                      _ActionTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notification Preferences',
                        sub: 'Manage reminder settings',
                        onTap: () {},
                      ),
                      const Gap(10),
                      _ActionTile(
                        icon: Icons.delete_outline_rounded,
                        label: 'Delete Account',
                        sub: 'Permanently remove all your data',
                        color: AppColors.coral700,
                        onTap: () => _confirmDelete(context),
                      ),
                      const Gap(20),

                      // Sign out
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => _signOut(context),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text('Sign Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.textSecondary,
                            side: BorderSide(
                                color: context.borderColor, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Gap(48)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit sheet ─────────────────────────────────────────────────────────────
  void _showEditSheet(BuildContext context, AppUser user) {
    final userCtrl = TextEditingController(text: user.username ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            left: 24,
            right: 24,
            top: 14,
          ),
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
              Text('Edit Profile', style: context.syne(22, FontWeight.w800)),
              const Gap(6),
              Text('Update your display name.',
                  style: context.dmSans(13, FontWeight.w400,
                      color: context.textSecondary)),
              const Gap(22),
              Text('Username',
                  style: context.dmSans(13, FontWeight.w600,
                      color: context.textSecondary)),
              const Gap(8),
              TextField(
                controller: userCtrl,
                autofocus: true,
                style: context.dmSans(15, FontWeight.w400),
                decoration: InputDecoration(
                  hintText: 'e.g. johndoe',
                  prefixIcon: Icon(Icons.person_outline_rounded,
                      size: 20, color: context.textTertiary),
                ),
              ),
              const Gap(28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(authStateProvider.notifier)
                        .updateProfile(username: userCtrl.text.trim());
                    if (context.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Save Changes',
                      style: context.syne(16, FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Change password ────────────────────────────────────────────────────────
  void _changePassword(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            Text('Change Password', style: context.syne(18, FontWeight.w700)),
        content: Text(
          'We\'ll send a password reset link to\n$email',
          style:
              context.dmSans(14, FontWeight.w400, color: context.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: context.dmSans(14, FontWeight.w400,
                      color: context.textSecondary))),
          TextButton(
            onPressed: () async {
              await ref
                  .read(authStateProvider.notifier)
                  .sendPasswordReset(email);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Reset link sent!',
                      style: GoogleFonts.dmSans(color: Colors.white)),
                  backgroundColor: context.accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: Text('Send Link',
                style:
                    context.dmSans(14, FontWeight.w700, color: context.accent)),
          ),
        ],
      ),
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  void _signOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: context.syne(18, FontWeight.w700)),
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
                    color: AppColors.coral700)),
          ),
        ],
      ),
    );
  }

  // ── Delete account ─────────────────────────────────────────────────────────
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account',
            style:
                context.syne(18, FontWeight.w700, color: AppColors.coral700)),
        content: Text(
          'This will permanently delete your account and ALL habit data. '
          'This action cannot be undone.',
          style:
              context.dmSans(14, FontWeight.w400, color: context.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: context.dmSans(14, FontWeight.w400,
                      color: context.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx), // placeholder
            child: Text('Delete Forever',
                style: context.dmSans(14, FontWeight.w700,
                    color: AppColors.coral700)),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String emoji, label, value;
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ctx.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ctx.borderColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const Gap(6),
            Text(value, style: ctx.syne(20, FontWeight.w800)),
            Text(label,
                style:
                    ctx.dmSans(11, FontWeight.w400, color: ctx.textTertiary)),
          ],
        ),
      );
}

// ─── Action Tile ──────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final Color? color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sub,
    required this.onTap,
    this.color,
  });
  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: ctx.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ctx.borderColor, width: 1.5),
          ),
          child: Row(children: [
            Icon(icon, size: 22, color: color ?? ctx.accent),
            const Gap(14),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: ctx.dmSans(14, FontWeight.w500,
                        color: color ?? ctx.textPrimary)),
                Text(sub,
                    style: ctx.dmSans(12, FontWeight.w400,
                        color: ctx.textTertiary)),
              ],
            )),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: ctx.textTertiary),
          ]),
        ),
      );
}
