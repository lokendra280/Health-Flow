import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:habitflow/presentation/screens/otp_verfication_page.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _agreed = false;

  // Password strength
  double get _strength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    double s = 0;
    if (p.length >= 8) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[0-9]').hasMatch(p)) s += 0.25;
    if (RegExp(r'[!@#\$%^&*(),.?]').hasMatch(p)) s += 0.25;
    return s;
  }

  String get _strengthLabel {
    final s = _strength;
    if (s == 0) return '';
    if (s <= 0.25) return 'Weak';
    if (s <= 0.5) return 'Fair';
    if (s <= 0.75) return 'Good';
    return 'Strong';
  }

  Color _strengthColor(BuildContext ctx) {
    final s = _strength;
    if (s <= 0.25) return AppColors.coral700;
    if (s <= 0.5) return AppColors.amber700;
    if (s <= 0.75) return AppColors.blue700;
    return ctx.accent;
  }

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));
    _fadeCtrl.forward();
    _passCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Future<void> _signUp() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   if (!_agreed) {
  //     ScaffoldMessenger.of(context).showSnackBar(_warnSnack(
  //         'Please accept the Terms & Privacy Policy to continue.'));
  //     return;
  //   }
  //   setState(() => _loading = true);
  //   ref.read(authStateProvider.notifier).clearError();
  //   await ref.read(authStateProvider.notifier).signUp(
  //     email:    _emailCtrl.text.trim(),
  //     password: _passCtrl.text,
  //     username: _userCtrl.text.trim(),
  //   );
  //   if (mounted) setState(() => _loading = false);
  // }
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        _warnSnack('Please accept the Terms & Privacy Policy to continue.'),
      );
      return;
    }

    setState(() => _loading = true);
    ref.read(authStateProvider.notifier).clearError();

    try {
      await ref.read(authStateProvider.notifier).signUp(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            username: _userCtrl.text.trim(),
          );

      if (!mounted) return;

      // ✅ Navigate to OTP screen after successful signup
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpPage(
            email: _emailCtrl.text.trim(),
          ),
        ),
      );
    } catch (e) {
      // optional: show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    if (authState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_errorSnack(authState.error!));
          ref.read(authStateProvider.notifier).clearError();
        }
      });
    }

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(8),
                  Text('Create Account',
                      style: context.syne(30, FontWeight.w800)),
                  const Gap(6),
                  Text(
                      'Start tracking habits that stick — across all your devices.',
                      style: context.dmSans(15, FontWeight.w400,
                          color: context.textSecondary)),
                  const Gap(32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Username ─────────────────────────
                        _Label('Username'),
                        const Gap(8),
                        TextFormField(
                          controller: _userCtrl,
                          textInputAction: TextInputAction.next,
                          style: context.dmSans(15, FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: 'e.g. johndoe',
                            prefixIcon: Icon(Icons.person_outline_rounded,
                                size: 20, color: context.textTertiary),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Username is required';
                            if (v.trim().length < 3)
                              return 'At least 3 characters';
                            return null;
                          },
                        ),
                        const Gap(20),

                        // ── Email ────────────────────────────
                        _Label('Email'),
                        const Gap(8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: context.dmSans(15, FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: 'you@example.com',
                            prefixIcon: Icon(Icons.email_outlined,
                                size: 20, color: context.textTertiary),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty)
                              return 'Email is required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim()))
                              return 'Enter a valid email address';
                            return null;
                          },
                        ),
                        const Gap(20),

                        // ── Password ─────────────────────────
                        _Label('Password'),
                        const Gap(8),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.next,
                          style: context.dmSans(15, FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                size: 20, color: context.textTertiary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: context.textTertiary,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePass = !_obscurePass),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Password is required';
                            if (v.length < 6) return 'At least 6 characters';
                            return null;
                          },
                        ),

                        // Password strength bar
                        if (_passCtrl.text.isNotEmpty) ...[
                          const Gap(10),
                          Row(children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: _strength),
                                  duration: const Duration(milliseconds: 300),
                                  builder: (_, v, __) =>
                                      LinearProgressIndicator(
                                    value: v,
                                    minHeight: 5,
                                    backgroundColor: context.surface3,
                                    valueColor: AlwaysStoppedAnimation(
                                        _strengthColor(context)),
                                  ),
                                ),
                              ),
                            ),
                            const Gap(10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _strengthLabel,
                                key: ValueKey(_strengthLabel),
                                style: context.dmSans(12, FontWeight.w600,
                                    color: _strengthColor(context)),
                              ),
                            ),
                          ]),
                        ],
                        const Gap(20),

                        // ── Confirm Password ─────────────────
                        _Label('Confirm Password'),
                        const Gap(8),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscureConfirm,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signUp(),
                          style: context.dmSans(15, FontWeight.w400),
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            prefixIcon: Icon(Icons.lock_outline_rounded,
                                size: 20, color: context.textTertiary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: context.textTertiary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty)
                              return 'Please confirm your password';
                            if (v != _passCtrl.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const Gap(24),

                        // ── Terms checkbox ───────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _agreed,
                                activeColor: context.accent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                onChanged: (v) =>
                                    setState(() => _agreed = v ?? false),
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(children: [
                                  TextSpan(
                                    text: 'I agree to the ',
                                    style: context.dmSans(13, FontWeight.w400,
                                        color: context.textSecondary),
                                  ),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: context.dmSans(13, FontWeight.w600,
                                        color: context.accent),
                                  ),
                                  TextSpan(
                                    text: ' and ',
                                    style: context.dmSans(13, FontWeight.w400,
                                        color: context.textSecondary),
                                  ),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: context.dmSans(13, FontWeight.w600,
                                        color: context.accent),
                                  ),
                                ]),
                              ),
                            ),
                          ],
                        ),
                        const Gap(28),

                        // ── Submit ───────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signUp,
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
                                : Text('Create Account',
                                    style: context.syne(16, FontWeight.w700,
                                        color: Colors.white)),
                          ),
                        ),
                        const Gap(24),

                        // Sign in link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: context.dmSans(14, FontWeight.w400,
                                    color: context.textSecondary)),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text('Sign In',
                                  style: context.dmSans(14, FontWeight.w700,
                                      color: context.accent)),
                            ),
                          ],
                        ),
                        const Gap(40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  SnackBar _errorSnack(String msg) => SnackBar(
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

  SnackBar _warnSnack(String msg) => SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.amber700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext ctx) => Text(text,
      style: ctx.dmSans(13, FontWeight.w600, color: ctx.textSecondary));
}
