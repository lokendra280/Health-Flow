import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habitflow/core/router/daily_workout_schedule_route.dart';
import 'package:habitflow/core/utils/date_utils.dart';
import 'package:habitflow/data/models/daily_workout.dart';
import 'package:habitflow/features/ai_plan/screens/daily_exercise_card.dart';
import 'package:habitflow/features/personal_profile/screens/widgets/edit_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:habitflow/features/auth/ui/sign_in_screen.dart';
import 'package:habitflow/features/auth/ui/sign_up_screen.dart';
import 'package:habitflow/features/auth/ui/verify_otp_screen.dart';
import 'package:habitflow/features/bottom_navigation/ui/bottom_page.dart';

import 'package:habitflow/features/food_tracking/bar_code_scanner.dart';
import 'package:habitflow/features/onboarding/pages/onboarding_screen.dart';
import 'package:habitflow/features/onboarding/services/onboarding_prefs.dart';
import 'package:habitflow/features/reports/pages/statistics_screen.dart';
import 'package:habitflow/features/splash/splash_screen.dart';
import 'package:habitflow/features/steps/ui/step_count_screen.dart';
import 'package:habitflow/features/journey_setup/screens/journey_setup_screen.dart';
import 'package:habitflow/features/personal_profile/screens/personal_profile_screen.dart';
import 'package:habitflow/features/ai_plan/screens/ai_plan_screen.dart';
import 'package:habitflow/features/dashboard/screens/dashboard_screen.dart';
import 'package:habitflow/features/food_tracking/food_tracking_screen.dart';
import 'package:habitflow/features/water_tracking/water_tracking_screen.dart';
import 'package:habitflow/features/activity_tracking/activity_tracking_screen.dart';
import 'package:habitflow/features/sleep_tracking/sleep_tracking_screen.dart';
import 'package:habitflow/features/body_progress/body_progress_screen.dart';
import 'package:habitflow/features/habit_tracking/habit_tracking_screen.dart';
import 'package:habitflow/features/daily_check_in/daily_check_in_screen.dart';
import 'package:habitflow/features/ai_daily_review/ai_daily_review_screen.dart';
import 'package:habitflow/features/ai_coach/ai_coach_screen.dart';
import 'package:habitflow/features/weekly_review/report_screens.dart';
import 'package:habitflow/features/milestones/milestones_screen.dart';
import 'package:habitflow/features/reports/journey_completion_screen.dart';
import 'package:habitflow/core/privacy/consent_provider.dart';
import 'package:habitflow/data/repositories/journey_repository_provider.dart';

/// Route path constants — reference these instead of hardcoded strings
/// (context.push('/food') etc.) wherever possible, so a typo'd path
/// fails at compile time rather than silently 404-ing at runtime.
abstract class AppRoutes {
  AppRoutes._();

  static const journeySetup = '/journey-setup';
  static const personalProfile = '/personal-profile';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const aiPlan = '/ai-plan';
  static const splash = '/splash';
  static const dashboard = '/dashboard';
  static const food = '/food';
  static const water = '/water';
  static const activity = '/activity';
  static const sleep = '/sleep';
  static const bodyProgress = '/body-progress';
  static const habits = '/habits';
  static const checkIn = '/check-in';
  static const aiReview = '/ai-review';
  static const aiCoach = '/ai-coach';
  static const weeklyReview = '/weekly-review';
  static const monthlyReview = '/monthly-review';
  static const milestones = '/milestones';
  static const reports = '/reports';
  static const journeyCompletion = '/journey-completion';
  static const stepCounter = '/step-counter';
  static const barcode = '/barcode';
  static const privacy = '/privacy';
  static const bottomNavbar = '/botoomNav';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const verifyOtp = '/verify-otp';
  static const oneBoarding = '/onBoarding';
  static const dailyWorkout = '/daily-workout';
}

/// Bridges a Stream (Supabase's auth state changes) into a Listenable so
/// GoRouter's `refreshListenable` re-runs `redirect` the moment auth state
/// changes — without this, signing in wouldn't trigger a re-check until the
/// next manual navigation.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

List<RouteBase> buildAppRoutes() {
  return [
    GoRoute(
      path: AppRoutes.oneBoarding,
      builder: (context, __) => OnboardingScreen(
        onFinished: () async {
          await OnboardingPrefs.markCompleted();
          if (context.mounted) {
            context.go(AppRoutes.bottomNavbar);
          }
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.signIn,
      builder: (_, __) => const SignInScreen(),
    ),
    // GoRoute(
    //   path: AppRoutes.signUp,
    //   builder: (_, __) => const SignUpScreen(),
    // ),
    GoRoute(
      path: AppRoutes.verifyOtp,
      builder: (_, __) => const VerifyOtpScreen(),
    ),
    GoRoute(
      path: AppRoutes.journeySetup,
      builder: (_, __) => const JourneySetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.bottomNavbar,
      builder: (_, __) => const RootScaffold(),
    ),
    GoRoute(
      path: AppRoutes.personalProfile,
      builder: (_, __) => const PersonalProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (_, __) => const PersonalProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (_, __) => const EditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiPlan,
      builder: (_, __) => const AiPlanScreen(),
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (_, __) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.food,
      builder: (_, __) => const FoodTrackingScreen(),
    ),
    GoRoute(
      path: AppRoutes.water,
      builder: (_, __) => const WaterTrackingScreen(),
    ),
    GoRoute(
      path: AppRoutes.activity,
      builder: (_, __) => const ActivityTrackingScreen(),
    ),
    GoRoute(
      path: AppRoutes.sleep,
      builder: (_, __) => const SleepTrackingScreen(),
    ),
    GoRoute(
      path: AppRoutes.bodyProgress,
      builder: (_, __) => const BodyProgressScreen(),
    ),
    GoRoute(
      path: AppRoutes.habits,
      builder: (_, __) => const HabitTrackingScreen(),
    ),
    GoRoute(
      path: AppRoutes.checkIn,
      builder: (_, __) => const DailyCheckInScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiReview,
      builder: (_, __) => const AiDailyReviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiCoach,
      builder: (_, __) => const AiCoachScreen(),
    ),
    // GoRoute(
    //   path: AppRoutes.weeklyReview,
    //   builder: (_, __) => const WeeklyReviewScreen(),
    // ),
    GoRoute(
      path: AppRoutes.dailyWorkout,
      builder: (_, __) => const DailyWorkoutScheduleRoute(),
    ),
    GoRoute(
      path: AppRoutes.milestones,
      builder: (_, __) => const MilestonesScreen(),
    ),
    GoRoute(
      path: AppRoutes.reports,
      builder: (_, __) => const StatisticsScreen(),
    ),
    GoRoute(
      path: AppRoutes.journeyCompletion,
      builder: (_, __) => const JourneyCompletionScreen(),
    ),
    GoRoute(
      path: AppRoutes.stepCounter,
      builder: (_, __) => const StepCounterScreen(),
    ),
    GoRoute(
      path: AppRoutes.barcode,
      builder: (_, __) => BarcodeScannerScreen(day: DateTime.now().normalized),
    ),
    GoRoute(
      path: AppRoutes.privacy,
      builder: (_, __) => const PrivacySettingsScreen(),
    ),
  ];
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final initialLocation = ref.watch(initialLocationProvider);
  final journeyRepository = ref.watch(journeyRepositoryProvider);

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) async {
      final location = state.matchedLocation;
      final isOnSplash = location == AppRoutes.splash;

      // Splash owns its own navigation decision (with a brief visible
      // delay) — don't fight it here, or it'll never actually be seen.
      if (isOnSplash) return null;

      final hasCompletedOnboarding =
          await OnboardingPrefs.hasCompletedOnboarding();
      final isSignedIn = Supabase.instance.client.auth.currentSession != null;

      if (isSignedIn) {
        // Cheap no-op after the first successful hydration per session —
        // hasCompletedSetup/hasGeneratedPlan short-circuit inside it.
        final userId = Supabase.instance.client.auth.currentUser!.id;
        await journeyRepository.hydrateFromRemoteIfNeeded();
      }

      final hasCompletedSetup = journeyRepository.hasCompletedSetup;
      final hasGeneratedPlan = journeyRepository.hasGeneratedPlan;

      final isOnOnboarding = location == AppRoutes.oneBoarding;
      final isOnSignIn = location == AppRoutes.signIn;
      final isOnSignUp = location == AppRoutes.signUp;
      final isOnVerifyOtp = location == AppRoutes.verifyOtp;

      const setupFlowRoutes = {
        AppRoutes.journeySetup,
        AppRoutes.personalProfile,
        AppRoutes.aiPlan,
      };
      final isOnSetupFlow = setupFlowRoutes.contains(location);
      final isOnPersonalProfileOrEarlier = location == AppRoutes.journeySetup ||
          location == AppRoutes.personalProfile;

      // Gate 1: onboarding, always first.
      if (!hasCompletedOnboarding) {
        return isOnOnboarding ? null : AppRoutes.oneBoarding;
      }

      // Gate 2: must be signed in. Sign-up and OTP verification are allowed
      // through un-authenticated, since that's the whole point of them.
      if (!isSignedIn) {
        return (isOnSignIn || isOnSignUp || isOnVerifyOtp)
            ? null
            : AppRoutes.signIn;
      }

      // Gate 3a: profile/goal setup not done yet — send to journey setup,
      // but a returning user who already finished this shouldn't be sent
      // back through it (that's Gate 3b below).
      if (!hasCompletedSetup) {
        return isOnPersonalProfileOrEarlier ? null : AppRoutes.journeySetup;
      }

      // Gate 3b: profile is done, but no AI plan exists yet — send straight
      // to plan generation, skipping profile creation entirely since it's
      // already saved. This stops an incomplete user (profile done, plan
      // not generated) from ever reaching the dashboard with no plan.
      if (!hasGeneratedPlan) {
        return location == AppRoutes.aiPlan ? null : AppRoutes.aiPlan;
      }

      // All gates passed: don't let the user land back on an intro screen.
      if (isOnOnboarding ||
          isOnSignIn ||
          isOnSignUp ||
          isOnVerifyOtp ||
          isOnSetupFlow) {
        return AppRoutes.bottomNavbar;
      }

      return null;
    },
    routes: buildAppRoutes(),
  );
});

final initialLocationProvider = Provider<String>((ref) {
  throw UnimplementedError(
    'initialLocationProvider must be overridden in main.dart',
  );
});
