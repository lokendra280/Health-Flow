import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/core/common_widget/common_svg.dart';
import 'package:habitflow/core/constants/constant_assets.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';

class BottomNav extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  final AppUser? user;
  final VoidCallback onFabTap;
  final ScrollController? scrollController;

  const BottomNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.onFabTap,
    this.user,
    this.scrollController,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  bool _hidden = false;
  double _lastOffset = 0;

  static const _items = [
    (Assets.home, Assets.home, 'Home'),
    (Assets.state, Assets.state, 'Stats'),
    (Assets.notification, Assets.notification, 'Remind'),
    (Assets.trophy, Assets.trophy, 'Goals'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, 1.5))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic));
    _fade = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));

    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(BottomNav old) {
    super.didUpdateWidget(old);
    if (old.scrollController != widget.scrollController) {
      old.scrollController?.removeListener(_onScroll);
      widget.scrollController?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final sc = widget.scrollController;
    if (sc == null || !sc.hasClients) return;

    final offset = sc.offset;
    final delta = offset - _lastOffset;

    if (delta > 8 && !_hidden && offset > 60) {
      // Scrolling down → hide
      _hidden = true;
      _ctrl.forward();
    } else if (delta < -8 && _hidden) {
      // Scrolling up → show
      _hidden = false;
      _ctrl.reverse();
    }
    _lastOffset = offset;
  }

  void _onTap(int i) {
    // Always show nav when user taps a tab
    if (_hidden) {
      _hidden = false;
      _ctrl.reverse();
    }
    widget.onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: child,
        ),
      ),
      child: SizedBox(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Nav bar ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: context.surfaceColor,
                border: Border(top: BorderSide(color: context.borderColor)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _items.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      final active = i == widget.index;

                      // Leave space for FAB
                      // if (i == 2) {
                      //   return const SizedBox(width: 64);
                      // }

                      return GestureDetector(
                        onTap: () => _onTap(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? context.accentSurf
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CommonSvgWidget(
                                svgName: active ? item.$1 : item.$2,
                                color: active
                                    ? context.accent
                                    : context.textTertiary,
                              ),
                              const Gap(3),
                              Text(item.$3,
                                  style: context.dmSans(10, FontWeight.w500,
                                      color: active
                                          ? context.accent
                                          : context.textTertiary)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // ── FAB ─────────────────────────────────────────────
            Positioned(
              top: -22,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_hidden) {
                      _hidden = false;
                      _ctrl.reverse();
                    }
                    widget.onFabTap();
                  },
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
                            offset: const Offset(0, 8))
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
