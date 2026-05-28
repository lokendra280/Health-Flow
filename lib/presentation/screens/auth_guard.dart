import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/screens/home_shell.dart';
import 'package:habitflow/presentation/screens/sign_in_screen.dart';

class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: child,
      ),
      child: switch (auth.status) {
        AuthStatus.loading => const _LoadingSplash(),
        AuthStatus.authenticated => const HomeShell(),
        AuthStatus.unauthenticated => const SignInScreen(),
      },
    );
  }
}

// ─── Loading Splash ───────────────────────────────────────────────────────────
class _LoadingSplash extends StatefulWidget {
  const _LoadingSplash();
  @override
  State<_LoadingSplash> createState() => _LoadingSplashState();
}

class _LoadingSplashState extends State<_LoadingSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulse = Tween(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 48)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('HabitFlow',
                style: context.syne(34, FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 8),
            Text('Phase 3 · Cloud Sync',
                style:
                    context.dmSans(14, FontWeight.w400, color: Colors.white60)),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
