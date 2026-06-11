import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/common_widget/common_svg.dart';
import 'package:habitflow/core/constants/constant_assets.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';

class BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final AppUser? user;
  final VoidCallback onFabTap;

  const BottomNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.onFabTap,
    this.user,
  });

  static const _items = [
    (Assets.home, Assets.home, 'Home'),
    (Assets.state, Assets.state, 'Stats'),
    (Assets.notification, Assets.notification, 'Remind'),
    (Assets.trophy, Assets.trophy, 'Goals'),
    // (Assets.profile, Assets.profile, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ================= BOTTOM BAR =================
          Container(
            decoration: BoxDecoration(
              color: context.surfaceColor,
              border: Border(top: BorderSide(color: context.borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _items.asMap().entries.map((e) {
                    final i = e.key;
                    final (ai, ii, label) = e.value;

                    final active = i == index;

                    return GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              active ? context.accentSurf : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Profile tab avatar
                            i == 4 && user != null
                                ? Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? context.accent
                                          : context.surface3,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        user!.initials.substring(0, 1),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: active
                                              ? Colors.white
                                              : context.textTertiary,
                                        ),
                                      ),
                                    ),
                                  )
                                : CommonSvgWidget(
                                    svgName: active ? ai : ii,
                                    color: active
                                        ? context.accent
                                        : context.textTertiary,
                                  ),

                            const Gap(3),

                            Text(
                              label,
                              style: context.dmSans(
                                10,
                                FontWeight.w500,
                                color: active
                                    ? context.accent
                                    : context.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ================= CENTER FLOATING BUTTON =================
          Positioned(
            top: -22,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: onFabTap,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.accent.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
