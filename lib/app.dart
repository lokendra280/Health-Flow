import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habitflow/core/providers/date_provider.dart';
import 'package:habitflow/core/router/app_router.dart';
import 'package:habitflow/core/theme/app_theme.dart';
import 'package:habitflow/features/notifications/notification_service.dart';

import 'features/dashboard/providers/dashboard_providers.dart';

class WeightLossJourneyApp extends ConsumerStatefulWidget {
  const WeightLossJourneyApp({super.key});

  @override
  ConsumerState<WeightLossJourneyApp> createState() => _WeightLossJourneyAppState();
}

class _WeightLossJourneyAppState extends ConsumerState<WeightLossJourneyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force refresh the current date when app resumes
      ref.read(currentDateProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    
    // Start the notification sync listener
    ref.watch(notificationSyncProvider);
    // Observe date changes for dashboard
    ref.watch(dashboardDateObserverProvider);

    return MaterialApp.router(
      title: 'Weight Loss Journey',
      theme: AppTheme.light,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
