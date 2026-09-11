import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:habitflow/app.dart';
import 'package:habitflow/core/constants/supabase_config.dart';
import 'package:habitflow/core/router/app_router.dart';
import 'package:habitflow/core/services/push_notification_service.dart';
import 'package:habitflow/core/services/update_service.dart';
import 'package:habitflow/data/repositories/journey_repository.dart';
import 'package:habitflow/data/repositories/journey_repository_provider.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  final repository = await JourneyRepository.open();
  await dotenv.load(fileName: ".env");
  await Hive.openBox('feedback_box');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    debug: false, // flip to true during development
  );

  // Initialize Push Notification Service
  final container = ProviderContainer(
    overrides: [
      journeyRepositoryProvider.overrideWithValue(repository),
      initialLocationProvider.overrideWithValue(AppRoutes.splash),
    ],
  );
  
  // Initialize both notification services
  await container.read(pushNotificationServiceProvider).init();
  await container.read(notificationServiceProvider).init();

  // Check for in-app updates (Android only)
  InAppUpdateService.checkForUpdate();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const WeightLossJourneyApp(),
    ),
  );
}
