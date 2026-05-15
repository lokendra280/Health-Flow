// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:gap/gap.dart';
// import '../../core/theme/app_theme.dart';
// import '../../domain/entities/entities.dart';
// import '../providers/providers.dart';
// import 'animated_habit_card.dart';
// import 'animated_progress_card.dart';
// import 'advanced_confetti.dart';
// import '../screens/reminders_screen.dart';
// import '../screens/insights_screen.dart';
// import '../screens/challenges_screen.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// //  PHASE 2 HOME SHELL
// //  Bottom nav: Home | Insights | Challenges | Reminders | Settings
// // ─────────────────────────────────────────────────────────────────────────────
// class Phase2Shell extends ConsumerStatefulWidget {
//   final List<Habit>         habits;
//   final List<Checkin>       checkins;
//   final Map<String, Streak> streaks;
//   final Map<String, int>    todayCounts;
//   final int                 overallStreak;
//   final int                 longestStreak;

//   // Callbacks into Phase 1 layer
//   final Future<void> Function(String habitId) onCheckin;
//   final VoidCallback onAddHabit;
//   final void Function(String habitId) onEditHabit;
//   final VoidCallback onToggleTheme;

//   const Phase2Shell({
//     super.key,
//     required this.habits,
//     required this.checkins,
//     required this.streaks,
//     required this.todayCounts,
//     required this.overallStreak,
//     required this.longestStreak,
//     required this.onCheckin,
//     required this.onAddHabit,
//     required this.onEditHabit,
//     required this.onToggleTheme,
//   });

//   @override
//   ConsumerState<Phase2Shell> createState() => _Phase2ShellState();
// }

// class _Phase2ShellState extends ConsumerState<Phase2Shell>
//     with SingleTickerProviderStateMixin {
//   int     _navIdx = 0;
//   String? _lastCompleted;

//   final _confettiKey = GlobalKey<AdvancedConfettiState>();

//   // ── Nav actions ────────────────────────────────────────────────────────────
//   void _onNavTap(int i) => setState(() => _navIdx = i);

//   // ── Checkin with animation ─────────────────────────────────────────────────
//   Future<void> _handleCheckin(String habitId) async {
//     await widget.onCheckin(habitId);
//     final h     = widget.habits.firstWhere((h) => h.id == habitId);
//     final done  = (widget.todayCounts[habitId] ?? 0) + 1;
//     if (done >= h.targetPerDay) {
//       setState(() => _lastCompleted = habitId);
//       _confettiKey.currentState?.launch(count: 70, fullScreen: true);
//       Future.delayed(const Duration(seconds: 2),
//           () { if (mounted) setState(() => _lastCompleted = null); });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = ref.watch(themeModeProvider);
//     final done   = widget.habits.where((h) =>
//         (widget.todayCounts[h.id] ?? 0) >= h.targetPerDay).length;

//     // Build habit record for reminders/challenges screens
//     final habitRefs = widget.habits
//         .map((h) => (id: h.id, name: h.name, icon: h.icon))
//         .toList();

//     return Stack(
//       children: [
//         Scaffold(
//           backgroundColor: context.bgColor,
//           body: IndexedStack(
//             index: _navIdx,
//             children: [
//               // ── 0: Home ──────────────────────────────────────
//               _HomeTab(
//                 habits:        widget.habits,
//                 todayCounts:   widget.todayCounts,
//                 streaks:       widget.streaks,
//                 done:          done,
//                 overallStreak: widget.overallStreak,
//                 longestStreak: widget.longestStreak,
//                 lastCompleted: _lastCompleted,
//                 isDark:        isDark,
//                 onCheckin:     _handleCheckin,
//                 onAddHabit:    widget.onAddHabit,
//                 onEditHabit:   widget.onEditHabit,
//                 onToggleTheme: widget.onToggleTheme,
//               ),

//               // ── 1: Insights ───────────────────────────────────
//               InsightsScreen(
//                 habits:   widget.habits,
//                 checkins: widget.checkins,
//                 streaks:  widget.streaks,
//               ),

//               // ── 2: Challenges ─────────────────────────────────
//               ChallengesScreen(habits: widget.habits),

//               // ── 3: Reminders ──────────────────────────────────
//               RemindersScreen(habits: habitRefs),

//               // ── 4: Settings ───────────────────────────────────
//               _SettingsTab(
//                 isDark:        isDark,
//                 habits:        widget.habits,
//                 streaks:       widget.streaks,
//                 onToggle:      widget.onToggleTheme,
//               ),
//             ],
//           ),

//           // ── Bottom Nav ────────────────────────────────────────
//           bottomNavigationBar: _BottomNav(
//             index: _navIdx,
//             onTap:  _onNavTap,
//             activeChallengeCount:
//                 ref.watch(activeChallengesProvider).length,
//             reminderCount:
//                 (ref.watch(reminderListProvider).value ?? [])
//                     .where((r) => r.isEnabled).length,
//           ),
//         ),

//         // ── Confetti overlay ──────────────────────────────────
//         AdvancedConfetti(key: _confettiKey),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  HOME TAB
// // ─────────────────────────────────────────────────────────────────────────────
// class _HomeTab extends StatelessWidget {
//   final List<Habit>         habits;
//   final Map<String, int>    todayCounts;
//   final Map<String, Streak> streaks;
//   final int                 done;
//   final int                 overallStreak;
//   final int                 longestStreak;
//   final String?             lastCompleted;
//   final bool                isDark;
//   final Future<void> Function(String) onCheckin;
//   final VoidCallback         onAddHabit;
//   final void Function(String) onEditHabit;
//   final VoidCallback         onToggleTheme;

//   const _HomeTab({
//     required this.habits, required this.todayCounts, required this.streaks,
//     required this.done, required this.overallStreak, required this.longestStreak,
//     required this.lastCompleted, required this.isDark, required this.onCheckin,
//     required this.onAddHabit, required this.onEditHabit,
//     required this.onToggleTheme,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: CustomScrollView(
//         physics: const BouncingScrollPhysics(),
//         slivers: [
//           // ── App bar ──────────────────────────────────────
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
//               child: Row(
//                 children: [
//                   RichText(text: TextSpan(children: [
//                     TextSpan(
//                       text: 'Habit',
//                       style: GoogleFonts.syne(
//                         fontSize: 26, fontWeight: FontWeight.w800,
//                         color: context.textPrimary,
//                       ),
//                     ),
//                     TextSpan(
//                       text: 'Flow',
//                       style: GoogleFonts.syne(
//                         fontSize: 26, fontWeight: FontWeight.w800,
//                         color: context.accent,
//                       ),
//                     ),
//                     TextSpan(
//                       text: ' 2',
//                       style: GoogleFonts.syne(
//                         fontSize: 16, fontWeight: FontWeight.w700,
//                         color: context.textTertiary,
//                       ),
//                     ),
//                   ])),
//                   const Spacer(),
//                   _AppBarBtn(
//                     child: Text(isDark ? '☀️' : '🌙',
//                         style: const TextStyle(fontSize: 18)),
//                     onTap: onToggleTheme,
//                   ),
//                   const Gap(10),
//                   GestureDetector(
//                     onTap: onAddHabit,
//                     child: Container(
//                       width: 40, height: 40,
//                       decoration: BoxDecoration(
//                         color: context.accent,
//                         shape: BoxShape.circle,
//                         boxShadow: [BoxShadow(
//                           color: context.accent.withOpacity(0.35),
//                           blurRadius: 10, offset: const Offset(0, 4),
//                         )],
//                       ),
//                       child: const Icon(Icons.add, color: Colors.white, size: 22),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // ── Greeting ─────────────────────────────────────
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
//               child: Text(
//                 _greeting(),
//                 style: GoogleFonts.dmSans(
//                   fontSize: 14, color: context.textSecondary,
//                 ),
//               ),
//             ),
//           ),

//           // ── Progress card ────────────────────────────────
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
//               child: AnimatedProgressCard(
//                 done:          done,
//                 total:         habits.length,
//                 streak:        overallStreak,
//                 longestStreak: longestStreak,
//               ),
//             ),
//           ),

//           // ── Section header ───────────────────────────────
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
//               child: Row(
//                 children: [
//                   Text("Today's Habits",
//                     style: GoogleFonts.syne(
//                       fontSize: 19, fontWeight: FontWeight.w700,
//                       color: context.textPrimary,
//                     ),
//                   ),
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: onAddHabit,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: context.pillBg,
//                         borderRadius: BorderRadius.circular(99),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.add, size: 16, color: context.pillFg),
//                           const Gap(4),
//                           Text('Add',
//                             style: GoogleFonts.dmSans(
//                               fontSize: 13, fontWeight: FontWeight.w600,
//                               color: context.pillFg,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // ── Habit list ───────────────────────────────────
//           habits.isEmpty
//               ? SliverToBoxAdapter(child: _EmptyHabits(onAdd: onAddHabit))
//               : SliverPadding(
//                   padding: const EdgeInsets.symmetric(horizontal: 20),
//                   sliver: SliverList.separated(
//                     itemCount: habits.length,
//                     separatorBuilder: (_, __) => const Gap(12),
//                     itemBuilder: (ctx, i) {
//                       final h = habits[i];
//                       return AnimatedHabitCard(
//                         habit:         h,
//                         todayCount:    todayCounts[h.id] ?? 0,
//                         streak:        streaks[h.id] ??
//                             const Streak(
//                               habitId: '', currentStreak: 0,
//                               longestStreak: 0,
//                             ),
//                         onCheckin:     () => onCheckin(h.id),
//                         onEdit:        () => onEditHabit(h.id),
//                         justCompleted: lastCompleted == h.id,
//                       );
//                     },
//                   ),
//                 ),

//           const SliverToBoxAdapter(child: Gap(100)),
//         ],
//       ),
//     );
//   }

//   String _greeting() {
//     final hour = DateTime.now().hour;
//     if (hour < 12) return 'Good morning! Ready to build today? 🌅';
//     if (hour < 17) return 'Good afternoon! Keep the streak alive! ⚡';
//     return 'Good evening! Don\'t break the chain! 🌙';
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  SETTINGS TAB
// // ─────────────────────────────────────────────────────────────────────────────
// class _SettingsTab extends StatelessWidget {
//   final bool                isDark;
//   final List<Habit>         habits;
//   final Map<String, Streak> streaks;
//   final VoidCallback        onToggle;

//   const _SettingsTab({
//     required this.isDark, required this.habits,
//     required this.streaks, required this.onToggle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Gap(8),
//             Text('Settings', style: context.syne(28, FontWeight.w800)),
//             const Gap(28),

//             _SLabel('Appearance'),
//             const Gap(10),
//             _STile(
//               icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
//               title: 'Dark Mode',
//               subtitle: isDark ? 'Currently dark' : 'Currently light',
//               trailing: Switch.adaptive(
//                 value: isDark, onChanged: (_) => onToggle(),
//                 activeColor: context.accent,
//               ),
//             ),
//             const Gap(24),

//             _SLabel('Phase 2 Features'),
//             const Gap(10),
//             ...[
//               (Icons.notifications_rounded, 'Smart Reminders',
//                   'Local push notifications'),
//               (Icons.bar_chart_rounded, 'Insights & Analytics',
//                   'Charts, heatmaps, trends'),
//               (Icons.emoji_events_rounded, 'Challenges',
//                   'Streak goals & templates'),
//               (Icons.auto_awesome_rounded, 'Advanced Animations',
//                   'Spring physics & particles'),
//             ].map((item) {
//               final (icon, title, sub) = item;
//               return Padding(
//                 padding: const EdgeInsets.only(bottom: 10),
//                 child: _STile(
//                   icon: icon, title: title, subtitle: sub,
//                   trailing: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 10, vertical: 4),
//                     decoration: BoxDecoration(
//                       color: context.accentSurf,
//                       borderRadius: BorderRadius.circular(99),
//                     ),
//                     child: Text('ON',
//                       style: context.dmSans(11, FontWeight.w700,
//                           color: context.accent)),
//                   ),
//                 ),
//               );
//             }),

//             const Gap(24),
//             _SLabel('Habits (${habits.length})'),
//             const Gap(10),
//             if (habits.isNotEmpty)
//               Container(
//                 decoration: BoxDecoration(
//                   color: context.surfaceColor,
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(color: context.borderColor, width: 1.5),
//                 ),
//                 child: Column(
//                   children: habits.asMap().entries.map((e) {
//                     final i = e.key;
//                     final h = e.value;
//                     final s = streaks[h.id];
//                     return Column(
//                       children: [
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 16, vertical: 13),
//                           child: Row(
//                             children: [
//                               Text(h.icon,
//                                   style: const TextStyle(fontSize: 20)),
//                               const Gap(12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(h.name,
//                                       style: context.dmSans(
//                                           14, FontWeight.w500)),
//                                     Text('${h.targetPerDay}× / day',
//                                       style: context.dmSans(12,
//                                           FontWeight.w400,
//                                           color: context.textTertiary)),
//                                   ],
//                                 ),
//                               ),
//                               if ((s?.currentStreak ?? 0) > 0)
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(
//                                       horizontal: 8, vertical: 3),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.amber100,
//                                     borderRadius: BorderRadius.circular(99),
//                                   ),
//                                   child: Text(
//                                     '🔥 ${s!.currentStreak}d',
//                                     style: GoogleFonts.dmSans(
//                                       fontSize: 11,
//                                       fontWeight: FontWeight.w600,
//                                       color: AppColors.amber700,
//                                     ),
//                                   ),
//                                 ),
//                             ],
//                           ),
//                         ),
//                         if (i < habits.length - 1)
//                           Divider(
//                               height: 1, color: context.borderColor,
//                               indent: 50),
//                       ],
//                     );
//                   }).toList(),
//                 ),
//               ),

//             const Gap(24),
//             _SLabel('About'),
//             const Gap(10),
//             Container(
//               padding: const EdgeInsets.all(18),
//               decoration: BoxDecoration(
//                 color: context.surfaceColor,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: context.borderColor, width: 1.5),
//               ),
//               child: Column(
//                 children: [
//                   _AboutRow('App', 'HabitFlow'),
//                   const Gap(10), _AboutRow('Phase', '2.0'),
//                   const Gap(10), _AboutRow('State', 'Riverpod'),
//                   const Gap(10), _AboutRow('Storage', 'Hive'),
//                   const Gap(10), _AboutRow('Charts', 'fl_chart'),
//                   const Gap(10), _AboutRow('Notifications', 'flutter_local_notifications'),
//                 ],
//               ),
//             ),
//             const Gap(40),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SLabel extends StatelessWidget {
//   final String text;
//   const _SLabel(this.text);
//   @override
//   Widget build(BuildContext ctx) => Text(text,
//     style: ctx.dmSans(12, FontWeight.w700,
//         color: ctx.textTertiary),
//   );
// }

// class _STile extends StatelessWidget {
//   final IconData icon;
//   final String   title, subtitle;
//   final Widget?  trailing;
//   const _STile({
//     required this.icon, required this.title,
//     required this.subtitle, this.trailing,
//   });
//   @override
//   Widget build(BuildContext ctx) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//     decoration: BoxDecoration(
//       color: ctx.surfaceColor,
//       borderRadius: BorderRadius.circular(14),
//       border: Border.all(color: ctx.borderColor, width: 1.5),
//     ),
//     child: Row(
//       children: [
//         Icon(icon, size: 22, color: ctx.accent),
//         const Gap(14),
//         Expanded(child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title,
//                 style: ctx.dmSans(14, FontWeight.w500)),
//             Text(subtitle,
//                 style: ctx.dmSans(12, FontWeight.w400,
//                     color: ctx.textTertiary)),
//           ],
//         )),
//         if (trailing != null) trailing!,
//       ],
//     ),
//   );
// }

// class _AboutRow extends StatelessWidget {
//   final String k, v;
//   const _AboutRow(this.k, this.v);
//   @override
//   Widget build(BuildContext ctx) => Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Text(k, style: ctx.dmSans(13, FontWeight.w400,
//           color: ctx.textSecondary)),
//       Text(v, style: ctx.dmSans(13, FontWeight.w600)),
//     ],
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  BOTTOM NAV
// // ─────────────────────────────────────────────────────────────────────────────
// class _BottomNav extends StatelessWidget {
//   final int      index;
//   final ValueChanged<int> onTap;
//   final int      activeChallengeCount;
//   final int      reminderCount;
//   const _BottomNav({
//     required this.index, required this.onTap,
//     required this.activeChallengeCount, required this.reminderCount,
//   });

//   static const _items = [
//     (Icons.home_rounded,          Icons.home_outlined,          'Home',       null),
//     (Icons.bar_chart_rounded,     Icons.bar_chart_outlined,     'Insights',   null),
//     (Icons.emoji_events_rounded,  Icons.emoji_events_outlined,  'Challenges', 'challenges'),
//     (Icons.notifications_rounded, Icons.notifications_outlined, 'Reminders',  'reminders'),
//     (Icons.settings_rounded,      Icons.settings_outlined,      'Settings',   null),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: context.surfaceColor,
//         border: Border(top: BorderSide(color: context.borderColor)),
//       ),
//       child: SafeArea(
//         top: false,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: _items.asMap().entries.map((e) {
//               final i = e.key;
//               final (activeIco, inactiveIco, label, badge) = e.value;
//               final active = i == index;
//               final badgeCount = badge == 'challenges'
//                   ? activeChallengeCount
//                   : badge == 'reminders'
//                       ? reminderCount
//                       : 0;

//               return GestureDetector(
//                 onTap: () => onTap(i),
//                 behavior: HitTestBehavior.opaque,
//                 child: AnimatedContainer(
//                   duration: const Duration(milliseconds: 200),
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: active
//                         ? context.accentSurf
//                         : Colors.transparent,
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Stack(
//                     clipBehavior: Clip.none,
//                     children: [
//                       Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             active ? activeIco : inactiveIco,
//                             size: 24,
//                             color: active
//                                 ? context.accent
//                                 : context.textTertiary,
//                           ),
//                           const Gap(3),
//                           Text(label,
//                             style: GoogleFonts.dmSans(
//                               fontSize: 10, fontWeight: FontWeight.w500,
//                               color: active
//                                   ? context.accent
//                                   : context.textTertiary,
//                             ),
//                           ),
//                         ],
//                       ),
//                       if (badgeCount > 0)
//                         Positioned(
//                           top: -4, right: -4,
//                           child: Container(
//                             width: 16, height: 16,
//                             decoration: BoxDecoration(
//                               color: context.accent,
//                               shape: BoxShape.circle,
//                               border: Border.all(
//                                   color: context.surfaceColor, width: 1.5),
//                             ),
//                             child: Center(
//                               child: Text('$badgeCount',
//                                 style: const TextStyle(
//                                     fontSize: 9, color: Colors.white,
//                                     fontWeight: FontWeight.w700),
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// //  SHARED SMALL WIDGETS
// // ─────────────────────────────────────────────────────────────────────────────
// class _AppBarBtn extends StatelessWidget {
//   final Widget child;
//   final VoidCallback onTap;
//   const _AppBarBtn({required this.child, required this.onTap});
//   @override
//   Widget build(BuildContext ctx) => GestureDetector(
//     onTap: onTap,
//     child: Container(
//       width: 40, height: 40,
//       decoration: BoxDecoration(
//         color: ctx.surfaceColor,
//         shape: BoxShape.circle,
//         border: Border.all(color: ctx.border2, width: 1.5),
//       ),
//       child: Center(child: child),
//     ),
//   );
// }

// class _EmptyHabits extends StatelessWidget {
//   final VoidCallback onAdd;
//   const _EmptyHabits({required this.onAdd});
//   @override
//   Widget build(BuildContext ctx) => Padding(
//     padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
//     child: Container(
//       padding: const EdgeInsets.all(32),
//       decoration: BoxDecoration(
//         color: ctx.surfaceColor,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: ctx.borderColor, width: 1.5),
//       ),
//       child: Column(
//         children: [
//           const Text('🌱', style: TextStyle(fontSize: 52)),
//           const Gap(14),
//           Text('No habits yet',
//               style: ctx.syne(20, FontWeight.w700, color: ctx.textSecondary)),
//           const Gap(8),
//           Text('Tap + to build your first habit and start a streak!',
//               textAlign: TextAlign.center,
//               style: ctx.dmSans(14, FontWeight.w400, color: ctx.textTertiary)),
//           const Gap(24),
//           ElevatedButton.icon(
//             onPressed: onAdd,
//             icon: const Icon(Icons.add_rounded, size: 18),
//             label: const Text('Add Your First Habit'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: ctx.accent, foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14)),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
