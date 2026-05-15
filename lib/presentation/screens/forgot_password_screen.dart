import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey  = GlobalKey<FormState>();
  final _emailCtrl= TextEditingController();
  bool  _loading  = false;
  bool  _sent     = false;

  late final AnimationController _ctrl;
  late final Animation<double>   _fade;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(authStateProvider.notifier)
          .sendPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() { _loading = false; _sent = true; });
      // Re-animate to sent state
      _ctrl.forward(from: 0);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString(),
              style: GoogleFonts.dmSans(color: Colors.white)),
          backgroundColor: AppColors.coral700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: context.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _sent ? _SentState(
                email: _emailCtrl.text.trim(),
                onResend: () {
                  setState(() => _sent = false);
                  _ctrl.forward(from: 0);
                },
                onBack: () => Navigator.of(context).pop(),
              ) : _FormState(
                formKey:   _formKey,
                emailCtrl: _emailCtrl,
                loading:   _loading,
                onSubmit:  _send,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form State ───────────────────────────────────────────────────────────────
class _FormState extends StatelessWidget {
  final GlobalKey<FormState>   formKey;
  final TextEditingController  emailCtrl;
  final bool                   loading;
  final VoidCallback           onSubmit;

  const _FormState({
    required this.formKey, required this.emailCtrl,
    required this.loading, required this.onSubmit,
  });

  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Gap(16),
      // Icon
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: ctx.accentSurf,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text('🔑', style: TextStyle(fontSize: 34)),
        ),
      ),
      const Gap(24),
      Text('Forgot Password?', style: ctx.syne(28, FontWeight.w800)),
      const Gap(8),
      Text(
        'No worries! Enter your email and we\'ll send you a secure reset link.',
        style: ctx.dmSans(15, FontWeight.w400, color: ctx.textSecondary),
      ),
      const Gap(36),

      Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email Address',
                style: ctx.dmSans(13, FontWeight.w600,
                    color: ctx.textSecondary)),
            const Gap(8),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              style: ctx.dmSans(15, FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined,
                    size: 20, color: ctx.textTertiary),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty)
                  return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim()))
                  return 'Enter a valid email address';
                return null;
              },
            ),
            const Gap(28),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctx.accent,
                  foregroundColor: Colors.white, elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text('Send Reset Link',
                        style: ctx.syne(16, FontWeight.w700,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
      const Gap(32),

      // Security note
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ctx.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ctx.borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.security_rounded, size: 20, color: ctx.textTertiary),
            const Gap(12),
            Expanded(
              child: Text(
                'The reset link expires in 24 hours. '
                'Check your spam folder if you don\'t see it.',
                style: ctx.dmSans(13, FontWeight.w400,
                    color: ctx.textSecondary),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ─── Sent State ───────────────────────────────────────────────────────────────
class _SentState extends StatelessWidget {
  final String       email;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _SentState({
    required this.email, required this.onResend, required this.onBack,
  });

  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Gap(48),
      // Success animation
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            color: ctx.accentSurf,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text('📧', style: TextStyle(fontSize: 46)),
          ),
        ),
      ),
      const Gap(32),
      Text('Check Your Email!',
          style: ctx.syne(26, FontWeight.w800),
          textAlign: TextAlign.center),
      const Gap(12),
      Text(
        'We\'ve sent a password reset link to',
        style: ctx.dmSans(15, FontWeight.w400, color: ctx.textSecondary),
        textAlign: TextAlign.center,
      ),
      const Gap(6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: ctx.accentSurf,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(email,
            style: ctx.dmSans(15, FontWeight.w700, color: ctx.accent)),
      ),
      const Gap(48),

      // Steps
      ...[
        (Icons.email_outlined,     'Open your email app'),
        (Icons.link_rounded,       'Click the reset link'),
        (Icons.lock_reset_rounded, 'Set your new password'),
      ].map((item) {
        final (icon, label) = item;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: ctx.surface2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: ctx.accent),
            ),
            const Gap(14),
            Text(label,
                style: ctx.dmSans(15, FontWeight.w500)),
          ]),
        );
      }),

      const Gap(36),
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton(
          onPressed: onBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: ctx.accent,
            foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('Back to Sign In',
              style: ctx.syne(16, FontWeight.w700, color: Colors.white)),
        ),
      ),
      const Gap(16),
      TextButton(
        onPressed: onResend,
        child: Text('Didn\'t receive it? Resend',
            style: ctx.dmSans(14, FontWeight.w500,
                color: ctx.textSecondary)),
      ),
      const Gap(32),
    ],
  );
}
