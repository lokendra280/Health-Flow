import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/presentation/providers/providers.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  final String email;

  const VerifyOtpPage({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  void _verifyOtp() async {
    if (_otp.length < 6) return;

    setState(() => _loading = true);

    await ref.read(authStateProvider.notifier).verifyOtp(widget.email, _otp);

    if (mounted) setState(() => _loading = false);
  }

  Widget _otpBox(int index) {
    return SizedBox(
      width: 45,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
          if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 70),
                const SizedBox(height: 20),
                Text(
                  "Verify OTP",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  "We sent a 6-digit code to\n${widget.email}",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, _otpBox),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyOtp,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Verify OTP"),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // resend logic
                  },
                  child: const Text("Resend Code"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
