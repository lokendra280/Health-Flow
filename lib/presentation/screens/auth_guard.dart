import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/screens/home_shell.dart';
import 'package:habitflow/presentation/screens/otp_verfication_page.dart';
import 'package:habitflow/presentation/screens/sign_in_screen.dart';
import 'package:habitflow/presentation/screens/splash_page.dart';

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
        AuthStatus.loading => const LoadingSplash(),
        AuthStatus.authenticated => const HomeShell(),
        AuthStatus.unauthenticated => const SignInScreen(),
        AuthStatus.otpSent => const VerifyOtpPage(
            email: '',
          )
      },
    );
  }
}
