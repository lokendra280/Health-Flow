import 'package:flutter/material.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/presentation/screens/home_shell.dart';

class LoadingSplash extends StatefulWidget {
  const LoadingSplash();
  @override
  State<LoadingSplash> createState() => LoadingSplashState();
}

class LoadingSplashState extends State<LoadingSplash>
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
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeShell(),
        ),
      );
    });
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
            // const SizedBox(height: 8),
            // Text('Phase 3 · Cloud Sync',
            //     style:
            //         context.dmSans(14, FontWeight.w400, color: Colors.white60)),
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
