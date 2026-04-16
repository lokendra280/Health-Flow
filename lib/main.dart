import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/local/local_storage.dart';
import 'features/auth/profile_screen.dart';
import 'features/home_shell.dart';
import 'features/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage.init();
  runApp(const ProviderScope(child: HealthApp()));
}

class HealthApp extends ConsumerWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return MaterialApp(
      title: 'HealthTracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routes: {
        '/home': (_) => const HomeShell(),
      },
      home: user == null
        ? const ProfileScreen(isSetup: true)
        : const HomeShell(),
    );
  }
}
