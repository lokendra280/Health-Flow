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
  const BottomNav({required this.index, required this.onTap, this.user});

  static const _items = [
    (Assets.home, Assets.home, 'Home'),
    (Assets.state, Assets.state, 'Stats'),
    (Assets.notification, Assets.notification, 'Remind'),
    (Assets.trophy, Assets.trophy, 'Goals'),
    (Assets.profile, Assets.profile, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? context.accentSurf : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Profile tab shows initials avatar
                      i == 4 && user != null
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color:
                                    active ? context.accent : context.surface3,
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
                              )),
                            )
                          : CommonSvgWidget(
                              svgName: active ? ai : ii,
                              color: active
                                  ? context.accent
                                  : context.textTertiary),
                      const Gap(3),
                      Text(label,
                          style: context.dmSans(10, FontWeight.w500,
                              color: active
                                  ? context.accent
                                  : context.textTertiary)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      );
}
