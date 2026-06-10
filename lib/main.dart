import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/constants/supabase_config.dart';
import 'package:habitflow/data/repositories/challenge_repository.dart';
import 'package:habitflow/data/repositories/habit_repository.dart';
import 'package:habitflow/data/repositories/reminder_repository.dart';
import 'package:habitflow/presentation/providers/providers.dart';
import 'package:habitflow/presentation/screens/auth_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/timezone.dart' as tz;
import 'core/theme/app_theme.dart';
import 'core/utils/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

// ─────────────────────────────────────────────────────────────────────────────
//  ENTRY POINT
// ─────────────────────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: false, // flip to true during development
  );
  // Init storage
  await HabitRepository.init(); // Hive + Phase1 adapters
  await ReminderRepository.init(); // Phase2 adapters
  await ChallengeRepository.init();
  tz.initializeTimeZones();

  // Init notifications
  await NotificationService.init();
  await NotificationService.arePermissionsGranted();
  // System chrome
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const ProviderScope(child: HabitFlowApp()));
}

class HabitFlowApp extends ConsumerWidget {
  const HabitFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'HabitFlow',
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // AuthGuard handles routing: splash → sign in / home
      home: const AuthGuard(),
    );
  }
}
