import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitflow/core/theme/app_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.green700,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌿', style: TextStyle(fontSize: 72)),
              const Gap(20),
              Text('HabitFlow',
                  style: GoogleFonts.syne(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const Gap(8),
              Text('Phase 2',
                  style:
                      GoogleFonts.dmSans(fontSize: 16, color: Colors.white60)),
              const Gap(48),
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5)),
            ],
          ),
        ),
      );
}
