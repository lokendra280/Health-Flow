import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    ref.read(authStateProvider.notifier).clearError();
    await ref
        .read(authStateProvider.notifier)
        .signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    if (auth.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(_errSnack(auth.error!));
        ref.read(authStateProvider.notifier).clearError();
      });
    }

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(52),
                    // Logo
                    Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.accent,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: context.accent.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6))
                          ],
                        ),
                        child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 26))),
                      ),
                      const Gap(12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HabitFlow',
                                style: context.syne(22, FontWeight.w800)),
                            Text('Phase 3 · Cloud Sync',
                                style: context.dmSans(12, FontWeight.w400,
                                    color: context.textTertiary)),
                          ]),
                    ]),
                    const Gap(48),
                    Text('Welcome back',
                        style: context.syne(30, FontWeight.w800)),
                    const Gap(6),
                    Text('Sign in to sync your habits across all devices.',
                        style: context.dmSans(15, FontWeight.w400,
                            color: context.textSecondary)),
                    const Gap(36),

                    // Email
                    _FieldLabel('Email'),
                    const Gap(8),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: context.dmSans(15, FontWeight.w400),
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.email_outlined,
                            size: 20, color: context.textTertiary),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const Gap(16),

                    // Password
                    _FieldLabel('Password'),
                    const Gap(8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: context.dmSans(15, FontWeight.w400),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock_outline_rounded,
                            size: 20, color: context.textTertiary),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: context.textTertiary),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password is required';
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                    ),
                    const Gap(8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen())),
                        child: Text('Forgot password?',
                            style: context.dmSans(13, FontWeight.w500,
                                color: context.accent)),
                      ),
                    ),
                    const Gap(12),

                    // Sign in CTA
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signIn,
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
                            : Text('Sign In',
                                style: context.syne(16, FontWeight.w700,
                                    color: Colors.white)),
                      ),
                    ),
                    const Gap(20),

                    // Divider
                    Row(children: [
                      Expanded(child: Divider(color: context.borderColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or',
                            style: context.dmSans(13, FontWeight.w400,
                                color: context.textTertiary)),
                      ),
                      Expanded(child: Divider(color: context.borderColor)),
                    ]),
                    const Gap(20),

                    // // Google
                    // _SocialBtn(
                    //   label: 'Continue with Google', emoji: '🔵',
                    //   onTap: () => ref.read(authStateProvider.notifier).signInWithGoogle(),
                    // ),
                    // const Gap(12),

                    // // Magic Link
                    // _SocialBtn(
                    //   label: 'Send Magic Link ✨', emoji: '',
                    //   onTap: () => _magicLinkDialog(context),
                    // ),
                    // const Gap(36),

                    // Sign up link
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text("Don't have an account? ",
                          style: context.dmSans(14, FontWeight.w400,
                              color: context.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpScreen())),
                        child: Text('Sign Up',
                            style: context.dmSans(14, FontWeight.w700,
                                color: context.accent)),
                      ),
                    ]),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _magicLinkDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Magic Link', style: context.syne(18, FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('We\'ll email you a one-click sign-in link.',
              style: context.dmSans(13, FontWeight.w400,
                  color: context.textSecondary)),
          const Gap(16),
          TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              style: context.dmSans(14, FontWeight.w400),
              decoration: const InputDecoration(hintText: 'you@example.com')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: context.dmSans(14, FontWeight.w400,
                      color: context.textSecondary))),
          TextButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ref
                  .read(authStateProvider.notifier)
                  .sendMagicLink(ctrl.text.trim());
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Magic link sent! Check your inbox.',
                      style: GoogleFonts.dmSans()),
                  backgroundColor: context.accent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: Text('Send',
                style:
                    context.dmSans(14, FontWeight.w700, color: context.accent)),
          ),
        ],
      ),
    );
  }

  SnackBar _errSnack(String msg) => SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const Gap(8),
          Expanded(
              child: Text(msg, style: GoogleFonts.dmSans(color: Colors.white))),
        ]),
        backgroundColor: AppColors.coral700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
      style: ctx.dmSans(13, FontWeight.w600, color: ctx.textSecondary));
}

class _SocialBtn extends StatelessWidget {
  final String label, emoji;
  final VoidCallback onTap;
  const _SocialBtn(
      {required this.label, required this.emoji, required this.onTap});

  @override
  Widget build(BuildContext ctx) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: ctx.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ctx.border2, width: 1.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (emoji.isNotEmpty) ...[
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const Gap(10)
            ],
            Text(label, style: ctx.dmSans(15, FontWeight.w600)),
          ]),
        ),
      );
}
